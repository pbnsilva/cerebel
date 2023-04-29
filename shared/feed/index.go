package feed

import (
	"fmt"
	"strings"
)

type m map[string]interface{}

type FieldType string

const (
	itemType      = "item"
	fixedItemType = "fixed_item"

	cerebelIndexPrefix = "cerebel"
	cerebelFeedPrefix  = cerebelIndexPrefix + "_feed"
)

type Index struct {
	name  string
	alias string
}

func NewIndex(id string) *Index {
	alias := strings.ToLower(fmt.Sprintf("%s_%s", cerebelFeedPrefix, id))
	return &Index{
		name:  alias,
		alias: alias,
	}
}

func (i *Index) Type() string {
	return itemType
}

func (i *Index) Name() string {
	return i.name
}

func (i *Index) Alias() string {
	return i.alias
}

func (i *Index) Mapping() map[string]interface{} {
	return m{
		"settings": m{
			"index": m{
				"number_of_shards":   1,
				"number_of_replicas": 0,
			},
		},
		"mappings": m{
			itemType: m{
				"properties": m{
					"date": m{
						"type": "date",
					},
					"items": m{
						"properties": m{
							"brand": m{
								"type": "text",
							},
						},
					},
				},
			},
		},
	}
}
