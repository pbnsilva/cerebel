package pkg

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"sort"
	"strings"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/feed"
	product "github.com/petard/cerebel/shared/product.v3"
	"github.com/petard/cerebel/shared/search"
	"github.com/petard/cerebel/shared/stats"
)

const (
	maxNbPopularCategories = 12
	maxNbPopularBrands     = 8
)

var fixedCategories = map[int]string{
	0: "vintage",
}

type ValueCount struct {
	Value string
	Count int
}

type SearchTeasersJob struct {
	cfg          *SearchTeasersJobConfig
	esClient     *elastic.Client
	productStore *product.ESStore
	feedStore    *feed.Store
	statsStore   *stats.Store
}

func NewSearchTeasersJob(cfg *SearchTeasersJobConfig) (*SearchTeasersJob, error) {
	esClient, err := es.NewSimpleClient(cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore("faer", esClient)
	if err != nil {
		return nil, err
	}

	feedStore := feed.NewStore("faer", esClient)

	statsStore, err := stats.NewStore(cfg.GetRedisHost())
	if err != nil {
		return nil, err
	}

	return &SearchTeasersJob{cfg, esClient, productStore, feedStore, statsStore}, nil
}

func (s *SearchTeasersJob) Run() error {
	ctx := context.Background()

	for _, gender := range []string{"women", "men"} {
		teasers, err := s.getTeasersForGender(ctx, gender, maxNbPopularCategories, maxNbPopularBrands)
		if err != nil {
			return err
		}

		if err := s.statsStore.SetSearchTeasers(gender, teasers); err != nil {
			return err
		}
	}

	return nil
}

func (s *SearchTeasersJob) getTeasersForGender(ctx context.Context, gender string, categoryCount, brandCount int) (interface{}, error) {
	popularCategories, err := s.getPopularCategories(ctx, gender, categoryCount)
	if err != nil {
		return nil, err
	}

	feedBrands, err := s.getFeedBrands(ctx, gender, brandCount)
	if err != nil {
		return nil, err
	}

	if len(popularCategories)%2 != 0 {
		popularCategories = popularCategories[:len(popularCategories)-2]
	}

	if len(feedBrands)%2 != 0 {
		feedBrands = feedBrands[:len(feedBrands)-2]
	}

	teasers := []*search.TeaserGroup{
		&search.TeaserGroup{Type: search.CategoriesTeaserType, Name: "Popular Categories", Items: popularCategories[:6]},
		&search.TeaserGroup{Type: search.MapTeaserType, Name: "Shops Around You"},
		&search.TeaserGroup{Type: search.BrandsTeaserType, Name: "Brand Spotlight", Items: feedBrands[:4]},
		&search.TeaserGroup{Type: search.CategoriesTeaserType, Name: "Popular Categories", Items: popularCategories[6:len(popularCategories)]},
		&search.TeaserGroup{Type: search.BrandsTeaserType, Name: "Brand Spotlight", Items: feedBrands[4:len(feedBrands)]},
	}

	return json.Marshal(teasers)
}

func (s *SearchTeasersJob) getPopularCategories(ctx context.Context, gender string, count int) ([]search.Teaser, error) {
	keys, err := s.statsStore.GetKeys(fmt.Sprintf("category:%s:*", gender))
	if err != nil {
		return nil, err
	}

	categoryCounts := []*ValueCount{}
	for _, key := range keys {
		keySplit := strings.Split(key, ":")
		category := keySplit[len(keySplit)-1]
		likeCount, err := s.statsStore.GetLikesForCategory(category, gender)
		if err != nil {
			return nil, err
		}
		category = strings.Replace(category, "_", " ", -1)
		categoryCounts = append(categoryCounts, &ValueCount{category, likeCount})
	}

	sort.Slice(categoryCounts[:], func(i, j int) bool {
		return categoryCounts[i].Count > categoryCounts[j].Count
	})

	teasers := []search.Teaser{}
	usedImages := map[string]struct{}{}
	for _, cat := range categoryCounts {
		if len(teasers) == count {
			break
		}

		feedQuery := elastic.NewBoolQuery().Filter(elastic.NewTermQuery("items.annotations.category", cat.Value)).Filter(elastic.NewTermQuery("items.gender", gender))
		items, err := s.feedStore.GetByQuery(ctx, feedQuery, 20)
		if err != nil {
			return nil, err
		}

		if len(items) == 0 {
			continue
		}

		for _, item := range items {
			if _, found := usedImages[item.ImageURL]; found {
				continue
			}

			teasers = append(teasers, &search.CategoryTeaser{
				Title:    strings.Title(cat.Value),
				ImageURL: item.ImageURL,
			})

			usedImages[item.ImageURL] = struct{}{}

			break
		}
	}

	// add fixed categories
	for k, v := range fixedCategories {
		if k >= len(teasers) {
			continue
		}

		products, err := s.productStore.GetByField(ctx, "annotations.category", v, 1)
		if err != nil {
			return nil, err
		}

		if len(products) == 0 {
			continue
		}

		teaser := &search.CategoryTeaser{
			Title:    strings.Title(v),
			ImageURL: products[0].ImageURL[0],
		}

		newTeasers := []search.Teaser{}
		newTeasers = append(newTeasers, teasers[:k]...)
		newTeasers = append(newTeasers, teaser)
		newTeasers = append(newTeasers, teasers[k:len(teasers)-1]...)
		teasers = newTeasers
	}

	return teasers, nil
}

func (s *SearchTeasersJob) getFeedBrands(ctx context.Context, gender string, count int) ([]search.Teaser, error) {
	q := elastic.NewBoolQuery().Filter(elastic.NewTermQuery("items.gender", gender))
	it, err := s.feedStore.ScrollWithQuery(ctx, q)
	if err != nil {
		return nil, err
	}

	brands := map[string]struct{}{}
	for {
		items, err := it.Next(ctx)
		if err == io.EOF {
			break
		}

		if err != nil {
			return nil, err
		}

		for _, item := range items {
			product := item.Items[0]
			if _, found := brands[product.BrandID]; found {
				continue
			}

			brands[product.BrandID] = struct{}{}

			if len(brands) == count {
				break
			}
		}

		if len(brands) == count {
			break
		}
	}

	teasers := []search.Teaser{}
	for br := range brands {
		q := elastic.NewBoolQuery().Filter(elastic.NewTermQuery("brand_id", br))
		it, err := s.productStore.ScrollWithQuery(ctx, q)
		if err != nil {
			return nil, err
		}

		products := []*product.Item{}
		for {
			items, err := it.Next(ctx)
			if err == io.EOF {
				break
			}

			if err != nil {
				return nil, err
			}

			for _, item := range items {
				if item.Gender[0] != gender {
					continue
				}

				if item.Price.EUR < 1 {
					continue
				}

				products = append(products, item)
				if len(products) == 10 {
					break
				}
			}

			if len(products) == 10 {
				break
			}
		}

		if len(products) == 0 {
			continue
		}

		teasers = append(teasers, &search.BrandTeaser{
			Title:    products[0].Brand,
			ID:       br,
			Products: products,
		})
	}

	return teasers, nil

}

func (s *SearchTeasersJob) getPopularBrands(ctx context.Context, gender string, count int) ([]search.Teaser, error) {
	keys, err := s.statsStore.GetKeys(fmt.Sprintf("brand:%s:*", gender))
	if err != nil {
		return nil, err
	}

	brandCounts := []*ValueCount{}
	for _, key := range keys {
		keySplit := strings.Split(key, ":")
		if len(keySplit) > 3 {
			continue
		}
		brand := keySplit[2]
		likeCount, err := s.statsStore.GetLikesForBrand(brand, gender)
		if err != nil {
			return nil, err
		}
		brandCounts = append(brandCounts, &ValueCount{brand, likeCount})
	}

	sort.Slice(brandCounts[:], func(i, j int) bool {
		return brandCounts[i].Count > brandCounts[j].Count
	})

	teasers := []search.Teaser{}
	for _, br := range brandCounts {
		if len(teasers) == count {
			break
		}

		products, err := s.productStore.GetByField(ctx, "brand_id", br.Value, 10)
		if err != nil {
			return nil, err
		}

		if len(products) == 0 {
			continue
		}

		teasers = append(teasers, &search.BrandTeaser{
			Title:    products[0].Brand,
			ID:       br.Value,
			Products: products,
		})
	}

	return teasers, nil
}
