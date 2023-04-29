package search

import (
	"encoding/json"

	product "github.com/petard/cerebel/shared/product.v3"
	"github.com/petard/cerebel/shared/service"
)

const (
	IntentSearch  = "search"
	IntentUnknown = "unknown"
)

type GuidedSearchItem string

type CountAggregation struct {
	Value   string          `json:"value"`
	Count   int             `json:"count"`
	TopHits []*product.Item `json:"topHits,omitempty"`
}

type Aggregations struct {
	Count map[string][]*CountAggregation `json:"count,omitempty"`
	Max   map[string]float32             `json:"max,omitempty"`
	Min   map[string]float32             `json:"min,omitempty"`
}

type Matches struct {
	Total int64             `json:"total"`
	Items []json.RawMessage `json:"items,omitempty"`
}

type Similar struct {
	Query   string  `json:"query,omitempty"`
	Matches Matches `json:"matches,omitempty"`
}

type Response struct {
	*service.BaseResponse

	Matches      *Matches           `json:"matches"`
	Guided       []GuidedSearchItem `json:"guided,omitempty"`
	Aggregations *Aggregations      `json:"aggregations,omitempty"`

	Similar *Similar `json:"similar,omitempty"`

	Query *QueryAnalysis `json:"query,omitempty"`
}

type QueryAnalysis struct {
	Intent string `json:"intent,omitempty"`
	// TODO interface here isn't a good idea
	Entities   interface{}           `json:"entities,omitempty"`
	PriceRange *PriceRangeAnnotation `json:"price_range,omitempty"`
}

func NewResponse() *Response {
	response := &Response{
		BaseResponse: service.NewOKResponse(),
	}
	return response
}

type ItemStatsResponse struct {
	*service.BaseResponse

	Likes  int `json:"likes"`
	Shares int `json:"shares"`
}

func NewItemStatsResponse() *ItemStatsResponse {
	response := &ItemStatsResponse{
		BaseResponse: service.NewOKResponse(),
	}
	return response
}

type TeasersResponse struct {
	*service.BaseResponse

	Items []*TeaserGroup `json:"items,omitempty"`
}

func NewTeasersResponse() *TeasersResponse {
	response := &TeasersResponse{
		BaseResponse: service.NewOKResponse(),
	}
	return response
}
