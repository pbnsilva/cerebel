package pkg

import (
	"bytes"
	"context"
	"errors"
	"image/color"
	"image/jpeg"
	"io"
	"io/ioutil"
	"net/http"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/feed"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/metadata"
	product "github.com/petard/cerebel/shared/product.v3"
)

const (
	storeID        = "faer"
	insertBulkSize = 50

	feedCatalogSourceName = "catalog"

	// limit number of catalog products we add each time
	maxCatalogProducts         = 25
	maxCatalogProductsPerBrand = 3
)

var (
	errUnknownFeedSourceType = errors.New("Unknown feed source type")
)

type FeedIndexer struct {
	cfg *IndexerJobConfig
}

func NewFeedIndexer(cfg *IndexerJobConfig) *FeedIndexer {
	return &FeedIndexer{cfg}
}

func (s *FeedIndexer) Run() error {
	feedConfig, err := s.getConfig()
	if err != nil {
		return err
	}

	log.Info("Removing dead links")

	affected, err := s.removeDeadLinks()
	if err != nil {
		return err
	}

	if affected > 0 {
		log.Info("Cleaned dead links", "affected", affected)
	}

	log.Info("Started indexing feed", "last_date", feedConfig.LastIndexedDate)

	affectedCatalog, lastDate, err := s.indexCatalog(feedConfig.LastIndexedDate)
	if err != nil {
		return err
	}

	feedConfig.LastIndexedDate = lastDate
	if err := s.updateConfig(feedConfig); err != nil {
		log.Error(err)
	}

	if err != nil {
		log.Info("Indexing feed failed", "error", err.Error())
	} else {
		log.Info("Finished indexing feed", "affected", affectedCatalog, "last_date", feedConfig.LastIndexedDate)
	}

	return err
}

func (s *FeedIndexer) indexCatalog(fromDate uint64) (int, uint64, error) {
	ctx := context.TODO()

	// load detector
	det, err := NewMtcnnDetector("mtcnn.pb")
	if err != nil {
		log.Fatal(err)
	}
	defer det.Close()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return 0, 0, err
	}

	productStore, err := product.NewESStore(storeID, esClient)
	if err != nil {
		return 0, 0, err
	}

	store := feed.NewStore(storeID, esClient)
	indexer := feed.NewIndexer(store)

	q := elastic.NewBoolQuery().Filter(elastic.NewRangeQuery("created_at").From(fromDate))
	it, err := productStore.ScrollWithQuery(ctx, q)
	if err != nil {
		return 0, 0, err
	}

	var lastDate uint64
	totalAffected := 0
	insertItems := []feed.Item{}
	brandInserted := map[string]int{}
	for {
		items, err := it.Next(ctx)
		if err == io.EOF {
			break
		}

		if err != nil {
			return 0, 0, err
		}

		for _, item := range items {
			if len(insertItems) == maxCatalogProducts {
				break
			}

			if _, found := brandInserted[item.Brand]; !found {
				brandInserted[item.Brand] = 0
			}

			if brandInserted[item.Brand] == maxCatalogProductsPerBrand {
				continue
			}

			// ignore unisex items
			if len(item.Gender) > 1 {
				continue
			}

			if len(item.ImageURL) < 2 {
				continue
			}

			// pick fresh looks image
			// if none, ignore this item
			idx, err := s.getCoverImage(det, item.ImageURL)
			if err != nil {
				return 0, 0, err
			}

			if idx == -1 {
				continue
			}

			// the image used in freshlooks is shown in the product detail page
			// remove it to avoid duplicates
			//item.ImageURL = item.ImageURL[1:]

			newItem := &feed.CatalogItem{
				ID:       item.ID,
				Title:    item.Name,
				Date:     item.CreatedAt,
				ImageURL: item.ImageURL[idx],
				Items:    []*product.Item{item},
				Source: &feed.ItemSource{
					Name:     feedCatalogSourceName,
					Username: "",
				},
			}

			insertItems = append(insertItems, newItem)
			if len(insertItems) == insertBulkSize {
				affected, err := indexer.Bulk(ctx, insertItems)
				if err != nil {
					return totalAffected, lastDate, err
				}

				totalAffected += affected
				insertItems = []feed.Item{}
			}

			brandInserted[item.Brand] += 1

			if item.CreatedAt > lastDate {
				lastDate = item.CreatedAt
			}
		}
	}

	if len(insertItems) > 0 {
		affected, err := indexer.Bulk(ctx, insertItems)
		if err != nil {
			return totalAffected, lastDate, err
		}

		totalAffected += affected
	}

	return totalAffected, lastDate, nil
}

// Prefer cover images that don't have white borders
// Prefer cover images that have a face
func (s *FeedIndexer) getCoverImage(det *MtcnnDetector, imgs []string) (int, error) {
	bestBorders := []int{}
	hasFace := map[int]bool{}
	for i := range imgs {
		response, err := http.Get(imgs[i])
		defer response.Body.Close()
		if err != nil {
			continue
		}
		bodyBytes, err := ioutil.ReadAll(response.Body)
		if err != nil {
			log.Error(err)
			continue
		}
		borders := getWhiteBorderSizes(bytes.NewReader(bodyBytes))
		if borders[0] < 20 {
			bestBorders = append(bestBorders, i)
		}
		img, err := TensorFromJpeg(bodyBytes)
		if err != nil {
			log.Error(err)
			continue
		}
		bbox, err := det.DetectFaces(img)
		if err != nil {
			log.Error(err)
			continue
		}
		if len(bbox) > 0 {
			hasFace[i] = true
		}
	}

	if len(bestBorders) == 0 {
		return -1, nil
	}

	for _, i := range bestBorders {
		if hasFace[i] {
			return i, nil
		}
	}

	return bestBorders[0], nil
}

func (s *FeedIndexer) indexSources(sources []*metadata.FeedSource, lastIndexedDate uint64) (int, uint64, error) {
	ctx := context.TODO()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return 0, 0, err
	}

	store := feed.NewStore(storeID, esClient)
	indexer := feed.NewIndexer(store)

	totalAffected := 0
	var lastDate uint64 = 0
	for _, source := range sources {
		reader, err := s.getReaderForSource(source, lastIndexedDate)
		if err != nil {
			return 0, 0, err
		}

		affected, bulkLastDate, err := indexer.BulkFromReader(ctx, reader, insertBulkSize)
		if err != nil {
			return affected, lastDate, err
		}

		if bulkLastDate > lastDate {
			lastDate = bulkLastDate
		}

		totalAffected += affected
	}

	return totalAffected, lastDate, nil
}

func (s *FeedIndexer) getConfig() (*metadata.FeedConfig, error) {
	ctx := context.TODO()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	metadataStore := metadata.NewStore(esClient)
	metadata, err := metadataStore.Get(ctx, storeID)
	if err != nil {
		return nil, err
	}

	return metadata.FeedConfig, nil
}

func (s *FeedIndexer) updateConfig(config *metadata.FeedConfig) error {
	ctx := context.TODO()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return err
	}

	metadataStore := metadata.NewStore(esClient)
	metadata, err := metadataStore.Get(ctx, storeID)
	if err != nil {
		return err
	}

	metadata.FeedConfig = config
	if err := metadataStore.Update(ctx, metadata); err != nil {
		return err
	}

	return nil
}

func (s *FeedIndexer) getReaderForSource(source *metadata.FeedSource, fromDate uint64) (feed.Reader, error) {
	if source.Type == metadata.FeedSourceTypeInstagram {
		reader, err := feed.NewInstagramReaderFromDate(source.URL, fromDate)
		return reader, err
	}
	return nil, errUnknownFeedSourceType
}

func (s *FeedIndexer) removeDeadLinks() (int, error) {
	affected := 0

	ctx := context.TODO()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return 0, err
	}

	store := feed.NewStore(storeID, esClient)

	q := elastic.NewBoolQuery()

	it, _ := store.ScrollWithQuery(ctx, q)
	for {
		items, err := it.Next(ctx)
		if err == io.EOF {
			break
		}

		if err != nil {
			return 0, err
		}

		for _, item := range items {
			if len(item.Items) == 0 {
				continue
			}

			resp, err := http.Get(item.Items[0].URL)
			if err != nil {
				log.Error(err)
				continue
			}

			if resp.StatusCode != 200 {
				if err := store.DeleteByID(ctx, item.ID); err != nil {
					log.Error(err)
					continue
				}
				affected += 1
			}
		}
	}

	return affected, nil
}

func getWhiteBorderSizes(reader io.Reader) []int {
	img, _ := jpeg.Decode(reader)

	rect := img.Bounds()

	whiteColor := color.RGBA{255, 255, 255, 255}

	// top
	topPx := 0
	for y := rect.Min.Y; y < rect.Max.Y; y++ {
		for x := rect.Min.X; x < rect.Max.X; x++ {
			if comparator(img.At(x, y), whiteColor) < 0.05 {
				topPx += 1
			}
		}
	}
	topPx = topPx / (rect.Max.X - rect.Min.X)

	// bottom
	bottomPx := 0
	for y := rect.Max.Y - 1; y >= rect.Min.Y; y-- {
		for x := rect.Min.X; x < rect.Max.X; x++ {
			if comparator(img.At(x, y), whiteColor) < 0.05 {
				bottomPx += 1
			}
		}
	}
	bottomPx = bottomPx / (rect.Max.X - rect.Min.X)

	// left
	leftPx := 0
	for x := rect.Min.X; x < rect.Max.X; x++ {
		for y := rect.Min.Y; y < rect.Max.Y; y++ {
			if comparator(img.At(x, y), whiteColor) < 0.05 {
				leftPx += 1
			}
		}
	}
	leftPx = leftPx / (rect.Max.Y - rect.Min.Y)

	// right
	rightPx := 0
	for x := rect.Max.X - 1; x >= rect.Min.X; x-- {
		for y := rect.Min.Y; y < rect.Max.Y; y++ {
			if comparator(img.At(x, y), whiteColor) < 0.05 {
				rightPx += 1
			}
		}
	}
	rightPx = rightPx / (rect.Max.Y - rect.Min.Y)

	return []int{topPx, rightPx, bottomPx, leftPx}
}

func comparator(color1 color.Color, color2 color.Color) float64 {
	const maxDiff = 765.0 // Difference between black and white colors

	r1, g1, b1, _ := color1.RGBA()
	r2, g2, b2, _ := color2.RGBA()

	r1, g1, b1 = r1>>8, g1>>8, b1>>8
	r2, g2, b2 = r2>>8, g2>>8, b2>>8

	return float64((max(r1, r2)-min(r1, r2))+
		(max(g1, g2)-min(g1, g2))+
		(max(b1, b2)-min(b1, b2))) / maxDiff
}

func max(a, b uint32) uint32 {
	if a > b {
		return a
	}
	return b
}

func min(a, b uint32) uint32 {
	if a < b {
		return a
	}
	return b
}
