package search

import (
	"encoding/json"
	"errors"

	elastic "gopkg.in/olivere/elastic.v5"
)

var (
	errMissingDistanceFieldFilter = errors.New("Missing distance field in geo distance filter")
	errMissingLocationFieldFilter = errors.New("Missing location field in geo distance filter")
	errMissingLatFieldFilter      = errors.New("Missing location.lat field in geo distance filter")
	errMissingLonFieldFilter      = errors.New("Missing location.lon field in geo distance filter")

	errInvalidGeoDistanceSort = errors.New("Invalid value for geoDistanceSort")

	errUnknownSortOrder         = errors.New("Unknown field sort order")
	errMissingLocationFieldSort = errors.New("Missing location field in sort")
	errMissingLatFieldSort      = errors.New("Missing location.lat field in sort")
	errMissingLonFieldSort      = errors.New("Missing location.lon field in sort")
)

const (
	sortOrderAscending  = "asc"
	sortOrderDescending = "desc"

	onSaleFilterName = "onSale"
)

type AnnotationError struct {
	StatusCode int
	Error      error
}

type RangeQuery struct {
	Gt  *float64 `json:"gt,omitempty"`
	Gte *float64 `json:"gte,omitempty"`
	Lt  *float64 `json:"lt,omitempty"`
	Lte *float64 `json:"lte,omitempty"`
}

type GeoDistanceQuery struct {
	Distance *string `json:"distance,omitempty"`
	Location *struct {
		Lat *float64 `json:"lat"`
		Lon *float64 `json:"lon"`
	} `json:"location,omitempty"`
}

func buildTextFiltersFromRequest(request *AnnotatedTextRequest) ([]elastic.Query, error) {
	filters := []elastic.Query{}
	for field, value := range request.GetFilters() {
		var term string
		if err := json.Unmarshal(*value, &term); err == nil {
			// ugly hack to override gender filter
			if field == "gender" {
				if _, ok := request.Annotations["gender"]; ok {
					continue
				}
			}
			filters = append(filters, elastic.NewTermQuery(field, term))
			continue
		}

		// on sale filter
		if field == onSaleFilterName {
			var isOnSale bool
			if err := json.Unmarshal(*value, &isOnSale); err == nil {
				if isOnSale {
					filters = append(filters, elastic.NewExistsQuery("original_price"))
				} else {
					filters = append(filters, elastic.NewBoolQuery().MustNot(elastic.NewExistsQuery("original_price")))
				}
				continue
			}
		}

		var terms []interface{}
		if err := json.Unmarshal(*value, &terms); err == nil {
			filters = append(filters, elastic.NewTermsQuery(field, terms...))
			continue
		}

		var rangeQuery *RangeQuery
		err := json.Unmarshal(*value, &rangeQuery)
		if err == nil && *rangeQuery != (RangeQuery{}) {
			esRangeQuery, err := buildRangeQuery(field, rangeQuery)
			if err != nil {
				return nil, err
			}
			filters = append(filters, esRangeQuery)
			continue
		}

		var distanceQuery *GeoDistanceQuery
		if err := json.Unmarshal(*value, &distanceQuery); err == nil {
			esDistanceQuery, err := buildGeoDistanceQuery(field, distanceQuery)
			if err != nil {
				return nil, err
			}
			filters = append(filters, esDistanceQuery)
			continue
		}
	}
	return filters, nil
}

func buildRangeQuery(field string, value *RangeQuery) (*elastic.RangeQuery, error) {
	rangeQuery := elastic.NewRangeQuery(field)
	if value.Gt != nil {
		rangeQuery = rangeQuery.Gt(*value.Gt)
	}
	if value.Gte != nil {
		rangeQuery = rangeQuery.Gte(*value.Gte)
	}
	if value.Lt != nil {
		rangeQuery = rangeQuery.Lt(*value.Lt)
	}
	if value.Lte != nil {
		rangeQuery = rangeQuery.Lte(*value.Lte)
	}
	return rangeQuery, nil
}

func buildGeoDistanceQuery(field string, value *GeoDistanceQuery) (*elastic.GeoDistanceQuery, error) {
	if value.Location == nil {
		return nil, errMissingLocationFieldFilter
	}

	if value.Location.Lat == nil {
		return nil, errMissingLatFieldFilter
	}

	if value.Location.Lon == nil {
		return nil, errMissingLonFieldFilter
	}

	if value.Distance == nil {
		return nil, errMissingDistanceFieldFilter
	}

	distanceQuery := elastic.NewGeoDistanceQuery(field).
		Distance(*value.Distance).
		Lat(*value.Location.Lat).
		Lon(*value.Location.Lon)

	return distanceQuery, nil
}

func updateWithSorting(request Request, svc *elastic.SearchService) (*elastic.SearchService, error) {
	sorters := []elastic.Sorter{}

	sortByField := request.GetSortByField()
	if sortByField != nil {
		for k := range sortByField {
			value := sortByField[k]
			if value == nil || value.Order == nil {
				return nil, errUnknownSortOrder
			}

			sorter := elastic.NewFieldSort(k)
			if *value.Order == sortOrderDescending {
				sorter = sorter.Desc()
			} else if *value.Order == sortOrderAscending {
				sorter = sorter.Asc()
			} else {
				return nil, errUnknownSortOrder
			}
			sorters = append(sorters, sorter)
		}
	}

	sortByDistance := request.GetSortByDistance()
	if sortByDistance != nil {
		for k := range sortByDistance {
			value := sortByDistance[k]
			if value == nil || value.Order == nil {
				return nil, errUnknownSortOrder
			}
			if value.Location == nil {
				return nil, errMissingLocationFieldSort
			}
			if value.Location.Lat == nil {
				return nil, errMissingLatFieldSort
			}
			if value.Location.Lon == nil {
				return nil, errMissingLonFieldSort
			}

			sorter := elastic.NewGeoDistanceSort(k).
				Point(*value.Location.Lat, *value.Location.Lon).
				Unit("km").
				GeoDistance("plane")
			if *value.Order == sortOrderDescending {
				sorter = sorter.Desc()
			} else if *value.Order == sortOrderAscending {
				sorter = sorter.Asc()
			} else {
				return nil, errUnknownSortOrder
			}

			sorters = append(sorters, sorter)
		}
	}

	if len(sorters) > 0 {
		svc = svc.SortBy(sorters...)
	}

	return svc, nil
}
