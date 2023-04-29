package feed

import (
	"context"

	elastic "gopkg.in/olivere/elastic.v5"
)

const (
	ItemType      = "item"
	PromotionType = "promotion"
)

type Indexer struct {
	store *Store
}

func NewIndexer(store *Store) *Indexer {
	return &Indexer{store}
}

func (in *Indexer) BulkFromReader(ctx context.Context, reader Reader, bulkSize int) (int, uint64, error) {
	totalAffected := 0
	var lastDate uint64 = 0
	bulk := []Item{}

	for reader.Read() {
		item, err := reader.Item()
		if err != nil {
			return totalAffected, lastDate, err
		}

		if item.GetCreationDate() > lastDate {
			lastDate = item.GetCreationDate()
		}

		bulk = append(bulk, item)
		if len(bulk) == bulkSize {
			affected, err := in.Bulk(ctx, bulk)
			if err != nil {
				return totalAffected, lastDate, err
			}
			totalAffected += affected
			bulk = []Item{}
		}
	}

	if len(bulk) > 0 {
		affected, err := in.Bulk(ctx, bulk)
		if err != nil {
			return totalAffected, lastDate, err
		}
		totalAffected += affected
		bulk = []Item{}
	}

	return totalAffected, lastDate, nil
}

func (in *Indexer) Bulk(ctx context.Context, items []Item) (int, error) {
	client := in.store.GetClient()
	index := in.store.GetIndex()
	bulkRequest := client.Bulk()
	for _, item := range items {
		request := elastic.NewBulkIndexRequest().
			Index(index.Name()).
			Type(ItemType).
			Id(item.GetID()).
			OpType("create").
			Doc(item)
		bulkRequest = bulkRequest.Add(request)
	}

	// TODO proper error handling
	bulkResponse, err := bulkRequest.Do(ctx)
	if err != nil {
		return 0, err
	}

	return len(bulkResponse.Created()), err
}
