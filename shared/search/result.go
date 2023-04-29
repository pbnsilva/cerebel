package search

import (
	product "github.com/petard/cerebel/shared/product.v3"
)

type Result struct {
	Items        []*product.Item
	TotalCount   int64
	Facets       map[string]interface{}
	Aggregations map[string]*ResultAggregation
}

type ResultAggregation struct {
	Value   float32                    `json:"value,omitempty"`
	Buckets []*ResultAggregationBucket `json:"buckets,omitempty"`
}

type ResultAggregationBucket struct {
	Key      string `json:"key"`
	DocCount int    `json:"doc_count"`
	TopHits  struct {
		Hits struct {
			Hits []*ResultAggregationHit `json:"hits"`
		} `json:"hits"`
	} `json:"top_hits"`
}

type ResultAggregationHit struct {
	Item *product.Item `json:"_source"`
}
