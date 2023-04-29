package search

import "encoding/json"

var (
	defaultSize = 20
)

type Request interface {
	GetSize() int
	GetOffset() int
	GetFilters() map[string]*json.RawMessage
	GetFields() []string
	GetAggregations() *AggregationsQuery
	GetSortByField() map[string]*SortByFieldValue
	GetSortByDistance() map[string]*SortByDistanceValue
}

type CountAggregationsQuery struct {
	Fields  []string `json:"fields"`
	TopHits int      `json:"topHits"`
}

type MaxAggregationsQuery struct {
	Fields []string `json:"fields"`
}

type MinAggregationsQuery struct {
	Fields []string `json:"fields"`
}

type AggregationsQuery struct {
	CountQuery *CountAggregationsQuery `json:"count"`
	MaxQuery   *MaxAggregationsQuery   `json:"max"`
	MinQuery   *MinAggregationsQuery   `json:"min"`
}

type SortByFieldValue struct {
	Order *string `json:"order"`
}

type SortByDistanceValue struct {
	Order    *string `json:"order"`
	Location *struct {
		Lat *float64 `json:"lat"`
		Lon *float64 `json:"lon"`
	} `json:"location"`
}

type BaseRequest struct {
	Size           *int                            `json:"size,omitempty"`
	Offset         *int                            `json:"offset,omitempty"`
	Filters        map[string]*json.RawMessage     `json:"filters,omitempty"`
	Fields         []string                        `json:"fields,omitempty"`
	Aggregations   *AggregationsQuery              `json:"aggregations,omitempty"`
	SortByField    map[string]*SortByFieldValue    `json:"sortByField,omitempty"`
	SortByDistance map[string]*SortByDistanceValue `json:"sortByDistance,omitempty"`
}

func (req *BaseRequest) GetFields() []string {
	return req.Fields
}

func (req *BaseRequest) GetAggregations() *AggregationsQuery {
	return req.Aggregations
}

func (req *BaseRequest) GetFilters() map[string]*json.RawMessage {
	return req.Filters
}

func (req *BaseRequest) GetSize() int {
	if req.Size == nil {
		return defaultSize
	}
	return *req.Size
}

func (req *BaseRequest) GetOffset() int {
	if req.Offset == nil {
		return 0
	}
	return *req.Offset
}

func (req *BaseRequest) GetSortByField() map[string]*SortByFieldValue {
	return req.SortByField
}

func (req *BaseRequest) GetSortByDistance() map[string]*SortByDistanceValue {
	return req.SortByDistance
}
