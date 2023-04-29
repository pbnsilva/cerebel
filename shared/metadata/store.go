package metadata

import (
	"context"
	"encoding/json"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
)

type Store struct {
	index *Index

	client *elastic.Client
}

func NewStore(client *elastic.Client) *Store {
	return &Store{
		client: client,
		index:  NewIndex(),
	}
}

func (s *Store) Create(ctx context.Context) error {
	return es.CreateIndex(ctx, s.index, s.client)
}

func (s *Store) Put(ctx context.Context, item *Item) error {
	_, err := s.client.Index().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(item.StoreID).
		OpType("create"). // do not allow to overwrite existing store
		BodyJson(item).
		Do(ctx)

	// handle concurrency errors nicely
	if err != nil {
		return err
	}

	return nil
}

func (s *Store) Update(ctx context.Context, item *Item) error {
	_, err := s.client.Update().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(item.StoreID).
		Doc(item).
		Do(ctx)
	return err
}

func (s *Store) Get(ctx context.Context, storeID string) (*Item, error) {
	result, err := s.client.Get().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(storeID).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	item := &Item{}
	if err := json.Unmarshal(*result.Source, item); err != nil {
		return nil, err
	}

	return item, nil
}

func (s *Store) GetAll(ctx context.Context) ([]*Item, error) {
	result, err := s.client.Search().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	items := []*Item{}
	if result.Hits.TotalHits > 0 {
		for _, hit := range result.Hits.Hits {
			d := &Item{}
			err := json.Unmarshal(*hit.Source, &d)
			if err != nil {
				// TODO log
				continue
			}
			items = append(items, d)
		}
	}

	return items, nil
}

func (s *Store) Delete(ctx context.Context, storeID string) error {
	_, err := s.client.Delete().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(storeID).
		Do(ctx)
	if err != nil {
		return err
	}

	// TODO proper response
	return nil
}
