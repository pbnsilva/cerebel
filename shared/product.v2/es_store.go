package product

import (
	"context"
	"encoding/json"

	"github.com/petard/cerebel/shared/es"

	elastic "gopkg.in/olivere/elastic.v5"
)

type ESStore struct {
	id       string
	index    *Index
	esClient *elastic.Client
}

func NewESStore(id string, client *elastic.Client) (*ESStore, error) {
	return &ESStore{id, NewIndex(id), client}, nil
}

func (s *ESStore) Create(ctx context.Context) error {
	return es.CreateIndex(ctx, s.index, s.esClient)
}

func (s *ESStore) Delete(ctx context.Context) error {
	return es.DeleteIndex(ctx, s.index.Name(), s.esClient)
}

func (s *ESStore) GetID() string {
	return s.id
}

func (s *ESStore) GetESClient() *elastic.Client {
	return s.esClient
}

func (s *ESStore) GetIndex() *Index {
	return s.index
}

func (s *ESStore) GetItemByID(ctx context.Context, id string) (*Item, error) {
	res, err := s.esClient.Get().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(id).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	if !res.Found {
		return nil, nil
	}

	item := &Item{}
	if err := json.Unmarshal(*res.Source, item); err != nil {
		return nil, err
	}

	return item, nil
}

func (s *ESStore) BulkGetItemsByID(ctx context.Context, ids []string) ([]*Item, error) {
	svc := s.esClient.MultiGet()
	for _, id := range ids {
		svc.Add(elastic.NewMultiGetItem().Index(s.index.Name()).Id(id))
	}

	res, err := svc.Do(ctx)
	if err != nil {
		return nil, err
	}

	items := []*Item{}
	for _, hit := range res.Docs {
		if !hit.Found {
			continue
		}

		item := &Item{}
		if err := json.Unmarshal(*hit.Source, item); err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (s *ESStore) UpsertItem(ctx context.Context, item *Item) error {
	_, err := elastic.NewUpdateService(s.esClient).
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(item.GetID()).
		DocAsUpsert(true).
		Doc(item).
		Do(ctx)
	if err != nil {
		return err
	}

	return nil
}

func (s *ESStore) BulkUpsertItems(ctx context.Context, items []*Item) error {
	bulkRequest := s.esClient.Bulk()
	for _, item := range items {
		request := elastic.NewBulkUpdateRequest().
			Index(s.index.Name()).
			Type(s.index.Type()).
			Id(item.GetID()).
			DocAsUpsert(true).
			Doc(item)
		bulkRequest = bulkRequest.Add(request)
	}

	_, err := bulkRequest.Do(ctx)
	if err != nil {
		return err
	}

	return nil
}

func (s *ESStore) DeleteItemByID(ctx context.Context, id string) error {
	_, err := s.esClient.Delete().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(id).
		Do(ctx)
	if err != nil {
		return err
	}

	return nil
}

func (s *ESStore) BulkDeleteItemsByID(ctx context.Context, ids []string) error {
	bulkRequest := s.esClient.Bulk()
	for _, id := range ids {
		request := elastic.NewBulkDeleteRequest().
			Index(s.index.Name()).
			Type(s.index.Type()).
			Id(id)
		bulkRequest = bulkRequest.Add(request)
	}

	_, err := bulkRequest.Do(ctx)
	if err != nil {
		return err
	}

	return nil
}

type ESItemIterable struct {
	svc *elastic.ScrollService
}

func (it *ESItemIterable) Next(ctx context.Context) ([]*Item, error) {
	res, err := it.svc.Do(ctx)
	if err != nil {
		return nil, err
	}

	var items []*Item
	for _, hit := range res.Hits.Hits {
		var item *Item
		err := json.Unmarshal(*hit.Source, &item)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (s *ESStore) Scroll(ctx context.Context) (*ESItemIterable, error) {
	svc := elastic.NewScrollService(s.esClient).Index(s.index.Name()).Type(s.index.Type()).Size(10)
	return &ESItemIterable{svc}, nil
}

func (s *ESStore) ScrollWithQuery(ctx context.Context, q elastic.Query) (*ESItemIterable, error) {
	svc := elastic.NewScrollService(s.esClient).Index(s.index.Name()).Type(s.index.Type()).Query(q).Size(10)
	return &ESItemIterable{svc}, nil
}
