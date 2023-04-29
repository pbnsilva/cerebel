package brand

import (
	"context"

	"github.com/petard/cerebel/shared/es"
)

type Client struct {
	elasticHost string
}

func NewClient(host string) (*Client, error) {
	return &Client{host}, nil
}

func (c *Client) ListBrands(ctx context.Context) ([]*Item, error) {
	esClient, err := es.NewSimpleClient(c.elasticHost)
	if err != nil {
		return nil, err
	}

	store := NewStore(esClient)
	items, err := store.GetAll(ctx)
	if err != nil {
		return nil, err
	}

	return items, nil
}

func (c *Client) Get(ctx context.Context, id string) (*Item, error) {
	esClient, err := es.NewSimpleClient(c.elasticHost)
	if err != nil {
		return nil, err
	}

	store := NewStore(esClient)
	item, err := store.Get(ctx, id)
	if err != nil {
		return nil, err
	}

	return item, nil
}

func (c *Client) Put(ctx context.Context, item *Item) error {
	esClient, err := es.NewSimpleClient(c.elasticHost)
	if err != nil {
		return err
	}

	store := NewStore(esClient)
	if err := store.Put(ctx, item); err != nil {
		return err
	}

	return nil
}
