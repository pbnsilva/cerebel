package es

import (
	"context"
	"errors"

	elastic "gopkg.in/olivere/elastic.v5"
)

var (
	ErrOpRejected = errors.New("backend rejected operation")
)

type Index interface {
	Name() string
	Type() string

	Mapping() map[string]interface{}
}

func CreateIndex(ctx context.Context, index Index, client *elastic.Client) error {
	result, err := client.CreateIndex(index.Name()).
		BodyJson(index.Mapping()).
		Do(ctx)

	if err != nil {
		return err
	}

	if !result.Acknowledged {
		return ErrOpRejected
	}

	return nil
}

func DeleteIndex(ctx context.Context, indexName string, client *elastic.Client) error {
	result, err := client.DeleteIndex(indexName).Do(ctx)
	if err != nil {
		return err
	}

	if err != nil {
		return err
	}

	if !result.Acknowledged {
		return ErrOpRejected
	}

	return nil
}
