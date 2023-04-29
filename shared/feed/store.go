package feed

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/petard/cerebel/shared/es"
	elastic "gopkg.in/olivere/elastic.v5"
)

type Store struct {
	ID    string
	index *Index

	esClient *elastic.Client
}

func NewStore(id string, esClient *elastic.Client) *Store {
	return &Store{
		ID:    id,
		index: NewIndex(id),

		esClient: esClient,
	}
}

func (s *Store) Create(ctx context.Context) error {
	return es.CreateIndex(ctx, s.index, s.esClient)
}

func (s *Store) Delete(ctx context.Context) error {
	return es.DeleteIndex(ctx, s.index.Name(), s.esClient)
}

func (s *Store) GetClient() *elastic.Client {
	return s.esClient
}

func (s *Store) GetIndex() *Index {
	return s.index
}

// TODO this is the wrong place for this...
func (s *Store) GetIndexNameForAlias(ctx context.Context, alias string) (string, error) {
	res, err := s.esClient.Aliases().Do(ctx)
	if err != nil {
		return "", err
	}
	return res.IndicesByAlias(fmt.Sprintf("%s_%s", cerebelFeedPrefix, alias))[0], nil
}

func (s *Store) DeleteByID(ctx context.Context, id string) error {
	_, err := s.esClient.Delete().
		Index(s.index.Alias()).
		Type(s.index.Type()).
		Id(id).
		Do(ctx)
	if err != nil {
		return err
	}

	return nil
}

func (s *Store) Update(ctx context.Context, item Item) error {
	_, err := s.esClient.Update().
		Index(s.index.Alias()).
		Type(s.index.Type()).
		Id(item.GetID()).
		Doc(item).
		Do(ctx)
	return err
}

func (s *Store) Get(ctx context.Context, id string) (*InstagramItem, error) {
	result, err := s.esClient.Get().
		Index(s.index.Alias()).
		Type(s.index.Type()).
		Id(id).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	item := &InstagramItem{}
	if err := json.Unmarshal(*result.Source, item); err != nil {
		return nil, err
	}

	return item, nil
}

func (s *Store) GetByField(ctx context.Context, key, value string, size int) ([]*InstagramItem, error) {
	res, err := s.esClient.Search().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Query(elastic.NewBoolQuery().Filter(elastic.NewTermQuery(key, value))).
		Sort("date", false).
		Size(size).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	items := []*InstagramItem{}
	for _, hit := range res.Hits.Hits {
		item := &InstagramItem{}
		if err := json.Unmarshal(*hit.Source, item); err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (s *Store) GetByQuery(ctx context.Context, q elastic.Query, size int) ([]*InstagramItem, error) {
	res, err := s.esClient.Search().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Query(q).
		Sort("date", false).
		Size(size).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	items := []*InstagramItem{}
	for _, hit := range res.Hits.Hits {
		item := &InstagramItem{}
		if err := json.Unmarshal(*hit.Source, item); err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (s *Store) ListPromotions(ctx context.Context) ([]*InstagramItem, error) {
	result, err := s.esClient.Search().
		Index(s.index.Alias()).
		Type(PromotionType).
		Do(ctx)
	if err != nil {
		return nil, err
	}

	var items []*InstagramItem
	for _, hit := range result.Hits.Hits {
		var item *InstagramItem
		err := json.Unmarshal(*hit.Source, &item)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (s *Store) InsertPromotion(ctx context.Context, item Item) error {
	_, err := s.esClient.Index().
		Index(s.index.Alias()).
		Type(PromotionType).
		Id(item.GetID()).
		BodyJson(item).
		Do(ctx)

	return err
}

func (s *Store) DeletePromotion(ctx context.Context, id string) error {
	_, err := s.esClient.Delete().
		Index(s.index.Alias()).
		Type(PromotionType).
		Id(id).
		Do(ctx)

	return err
}

type ESItemIterable struct {
	svc *elastic.ScrollService
}

func (it *ESItemIterable) Next(ctx context.Context) ([]*InstagramItem, error) {
	res, err := it.svc.Do(ctx)
	if err != nil {
		return nil, err
	}

	var items []*InstagramItem
	for _, hit := range res.Hits.Hits {
		var item *InstagramItem
		err := json.Unmarshal(*hit.Source, &item)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (s *Store) Scroll(ctx context.Context) (*ESItemIterable, error) {
	svc := elastic.NewScrollService(s.esClient).Index(s.index.Name()).Type(s.index.Type()).Size(10)
	return &ESItemIterable{svc}, nil
}

func (s *Store) ScrollWithQuery(ctx context.Context, q elastic.Query) (*ESItemIterable, error) {
	svc := elastic.NewScrollService(s.esClient).Index(s.index.Name()).Type(s.index.Type()).Query(q).Sort("date", false).Size(10)
	return &ESItemIterable{svc}, nil
}
