package search

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	product "github.com/petard/cerebel/shared/product.v3"

	elastic "gopkg.in/olivere/elastic.v5"
)

var suggestionAggregationFields = map[string]string{
	"category":      "annotations.category",
	"brand":         "annotations.brand",
	"color":         "annotations.color",
	"fabric":        "annotations.fabric",
	"heel_form":     "annotations.heel_form",
	"length":        "annotations.length",
	"occasion":      "annotations.occasion",
	"pattern":       "annotations.pattern",
	"season":        "annotations.season",
	"shirt_collar":  "annotations.shirt_collar",
	"shoe_fastener": "annotations.shoe_fastener",
	"sleeve_length": "annotations.sleeve_length",
	"trouser_rise":  "annotations.trouser_rise",
}

type ESEngine struct {
	store *product.ESStore
}

func NewESEngine(store *product.ESStore) *ESEngine {
	return &ESEngine{store}
}

func (en *ESEngine) Search(ctx context.Context, request *AnnotatedTextRequest, doFullTextSearch bool) (*Result, error) {
	result, err := en.doSearch(ctx, request, doFullTextSearch)
	if err != nil {
		return nil, err
	}

	// TODO use a goroutine to speed this up
	if doFullTextSearch {
		if result.TotalCount == 0 && len(request.Annotations) > 0 {
			result, err = en.doSearch(ctx, request, false)
			if err != nil {
				return nil, err
			}
		}
	}

	return result, nil
}

func (en *ESEngine) doSearch(ctx context.Context, request *AnnotatedTextRequest, doFullTextSearch bool) (*Result, error) {
	q := elastic.NewBoolQuery()
	buildQueryWithAnnotationsV20(q, request, doFullTextSearch)

	filters, err := buildTextFiltersFromRequest(request)
	if err != nil {
		return nil, err
	}
	q.Filter(filters...)

	// this is a hack to add brand diversity to search results
	fs := elastic.NewFunctionScoreQuery().AddScoreFunc(elastic.NewRandomFunction().Seed("b832da24d1b65ec6e0bccbfcd42b5814")).Query(q)

	client := en.store.GetESClient()
	index := en.store.GetIndex()
	svc := client.Search().
		Index(index.Name()).
		Query(fs).
		From(request.GetOffset()).
		Size(request.GetSize())

	svc, err = updateWithSorting(request, svc)
	if err != nil {
		return nil, err
	}

	if len(request.GetFields()) > 0 {
		svc = svc.FetchSourceContext(elastic.NewFetchSourceContext(true).Include(request.GetFields()...))
	}

	aggregations := map[string]elastic.Aggregation{}
	if request.GetShowGuided() {
		for k, agg := range getSuggestionsAggregations() {
			aggregations[k] = agg
		}
	}

	if request.GetAggregations() != nil {
		for k, agg := range getAggregations(request.GetAggregations()) {
			if _, ok := aggregations[k]; ok {
				continue
			}
			aggregations[k] = agg
		}
	}

	for k, agg := range aggregations {
		svc = svc.Aggregation(k, agg)
	}

	svcResult, err := svc.Do(ctx)
	if err != nil {
		return nil, err
	}

	result := &Result{}
	result.TotalCount = svcResult.TotalHits()
	brandItems := map[string][]*product.Item{}
	for _, hit := range svcResult.Hits.Hits {
		item := &product.Item{}
		if err := json.Unmarshal(*hit.Source, item); err != nil {
			return nil, err
		}
		if _, found := brandItems[item.Brand]; !found {
			brandItems[item.Brand] = []*product.Item{}
		}

		brandItems[item.Brand] = append(brandItems[item.Brand], item)
	}

	// brand diversity
	i := 0
	for i < len(svcResult.Hits.Hits) {
		for k := range brandItems {
			if len(brandItems[k]) == 0 {
				continue
			}
			var item *product.Item
			item, brandItems[k] = brandItems[k][0], brandItems[k][1:]
			result.Items = append(result.Items, item)
			i += 1
		}
	}

	if request.GetAggregations() != nil || request.GetShowGuided() {
		aggregations := map[string]*ResultAggregation{}
		for k, v := range svcResult.Aggregations {
			var agg *ResultAggregation
			if err := json.Unmarshal([]byte(*v), &agg); err != nil {
				return nil, err
			}

			aggregations[k] = agg
		}
		result.Aggregations = aggregations
	}

	return result, nil
}

func (en *ESEngine) Scroll(ctx context.Context, request *ScrollRequest) (*Result, error) {
	client := en.store.GetESClient()
	index := en.store.GetIndex()
	svc := client.Search().
		Index(index.Name()).
		Query(elastic.NewMatchAllQuery()).
		From(request.GetOffset()).
		Size(request.GetSize())

	svcResult, err := svc.Do(ctx)

	if err != nil {
		return nil, err
	}

	result := &Result{}
	result.TotalCount = svcResult.TotalHits()
	for _, hit := range svcResult.Hits.Hits {
		item := &product.Item{}
		if err := json.Unmarshal(*hit.Source, item); err != nil {
			return nil, err
		}
		result.Items = append(result.Items, item)
	}

	return result, nil
}

func buildQueryWithAnnotationsV20(q *elastic.BoolQuery, request *AnnotatedTextRequest, doFullTextSearch bool) {
	// TODO this is too manual and specific; should place into some Filter abstraction pipeline that can be added to the engine
	hasVintage := false
	mustQs := []elastic.Query{}
	shouldQs := []elastic.Query{}
	for k := range request.Annotations {
		for _, v := range request.Annotations[k] {
			if k == "category" {
				shouldQs = append(shouldQs, elastic.NewTermQuery(fmt.Sprintf("annotations.%s", k), v.Value))
				for k := range request.QueryExpansions {
					for _, v := range request.QueryExpansions[k] {
						shouldQs = append(shouldQs, elastic.NewTermQuery(fmt.Sprintf("annotations.%s", k), v))
					}
				}

				if v.Value == "vintage" {
					hasVintage = true
				}
			} else if k == "sale" {
				mustQs = append(mustQs, elastic.NewExistsQuery("original_price"))
			} else {
				mustQs = append(mustQs, elastic.NewTermQuery(fmt.Sprintf("annotations.%s", k), v.Value))
				if k == "color" {
					mustQs = append(mustQs, elastic.NewTermQuery("annotations.color_count", strconv.FormatInt(int64(len(request.Annotations[k])), 10)))
				}
			}
		}
	}

	if len(shouldQs) > 0 {
		q.Should(shouldQs...).MinimumNumberShouldMatch(1)
	}

	if doFullTextSearch {
		matchQuery := request.GetQuery()
		for k := range request.Annotations {
			for _, v := range request.Annotations[k] {
				matchQuery = strings.Replace(matchQuery, v.Original, "", -1)
			}
		}
		matchQuery = strings.Trim(matchQuery, " ")
		if len(matchQuery) > 0 {
			mustQs = append(mustQs, elastic.NewMatchQuery("indexed_text", matchQuery).Analyzer("language_analyzer"))
		}
	}

	if len(mustQs) > 0 {
		q.Must(mustQs...)
	}

	// ! Temporary: don't show vintage items unless explicitely searched for
	if !hasVintage {
		q.MustNot(elastic.NewTermQuery("annotations.category", "vintage"))
	}
	// !

	if request.PriceRange != nil {
		priceRange := request.PriceRange
		cur := strings.ToLower(priceRange.Currency)
		rangeQuery := elastic.NewRangeQuery("price." + cur)
		if priceRange.Gte != 0 {
			rangeQuery = rangeQuery.Gte(priceRange.Gte)
		}
		if priceRange.Lte != 0 {
			rangeQuery = rangeQuery.Lte(priceRange.Lte)
		}
		if priceRange.Eq != 0 {
			rangeQuery = rangeQuery.Gte(priceRange.Eq - 5)
			rangeQuery = rangeQuery.Lte(priceRange.Eq + 5)
		}
		q.Must(rangeQuery)
	}
}

func getAggregations(aggregationsQuery *AggregationsQuery) map[string]elastic.Aggregation {
	aggs := map[string]elastic.Aggregation{}

	countQuery := aggregationsQuery.CountQuery
	if countQuery != nil {
		for _, field := range countQuery.Fields {
			termAgg := elastic.NewTermsAggregation().Field(field)
			if countQuery.TopHits > 0 {
				termAgg = termAgg.SubAggregation("top_hits", elastic.NewTopHitsAggregation().DocvalueField(field).Size(countQuery.TopHits))
			}

			// TODO this isn't right: key should be the aggregation name;
			// this means we can't have different aggregations for the same field!
			aggs["count_"+field] = termAgg
		}
	}

	maxQuery := aggregationsQuery.MaxQuery
	if maxQuery != nil {
		for _, field := range maxQuery.Fields {
			aggs["max_"+field] = elastic.NewMaxAggregation().Field(field)
		}
	}

	minQuery := aggregationsQuery.MinQuery
	if minQuery != nil {
		for _, field := range minQuery.Fields {
			aggs["min_"+field] = elastic.NewMinAggregation().Field(field)
		}
	}

	return aggs
}

func getSuggestionsAggregations() map[string]elastic.Aggregation {
	aggs := map[string]elastic.Aggregation{}
	for k, val := range suggestionAggregationFields {
		aggs[k] = elastic.NewTermsAggregation().Field(val).SubAggregation("top_hits", elastic.NewTopHitsAggregation().DocvalueField(val).Size(1))
	}
	return aggs
}
