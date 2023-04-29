package brand

import (
	"context"
	"encoding/json"
	"errors"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
)

var (
	ErrBrandNotFound = errors.New("Brand not found")
)

type Store struct {
	index  *Index
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
		Id(item.ID).
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
		Id(item.ID).
		Doc(item).
		Do(ctx)
	return err
}

func (s *Store) Get(ctx context.Context, brandID string) (*Item, error) {
	result, err := s.client.Get().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(brandID).
		Do(ctx)
	if err != nil {
		e, ok := err.(*elastic.Error)
		if ok {
			if e.Status == 404 {
				return nil, ErrBrandNotFound
			}
		}
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
		Size(5000).
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
				return nil, err
			}
			items = append(items, d)
		}
	}

	return items, nil
}

func (s *Store) GetByGeoDistance(ctx context.Context, location *es.Location, distance string) ([]*Item, error) {
	distanceQuery := elastic.NewGeoDistanceQuery("stores.location").
		Lat(float64(location.Lat)).
		Lon(float64(location.Lon)).
		Distance(distance)

	boolQuery := elastic.NewBoolQuery()
	boolQuery = boolQuery.Must(elastic.NewMatchAllQuery())
	boolQuery = boolQuery.Filter(distanceQuery)

	result, err := s.client.Search().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Query(boolQuery).
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

type ItemIterable struct {
	svc *elastic.ScrollService
}

func (it *ItemIterable) Next(ctx context.Context) ([]*Item, error) {
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

func (s *Store) Scroll(ctx context.Context) (*ItemIterable, error) {
	svc := elastic.NewScrollService(s.client).Index(s.index.Name()).Type(s.index.Type()).Size(10)
	return &ItemIterable{svc}, nil
}

func (s *Store) Delete(ctx context.Context, brandID string) error {
	_, err := s.client.Delete().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(brandID).
		Do(ctx)
	if err != nil {
		return err
	}

	// TODO proper response
	return nil
}
