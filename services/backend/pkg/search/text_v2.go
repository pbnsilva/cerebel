package search

import (
	"encoding/json"
	"net/http"
	"strings"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/petard/cerebel/shared/annotation"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	shared_search "github.com/petard/cerebel/shared/search"
	"github.com/petard/cerebel/shared/time"

	"github.com/petard/cerebel/shared/service"
)

// searchByText returns search results given a text query.
func (s *Service) searchByTextV2(ctx *gin.Context) {
	startTime := time.NowInMilliseconds()

	request := shared_search.NewTextRequest()
	if err := ctx.MustBindWith(request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, service.NewErrorResponse(err.Error()))
		return
	}

	storeID, err := service.GetAuthStoreIDFromGinContext(ctx)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, service.NewErrorResponse(err.Error()))
		return
	}

	// create connection to elasticsearch
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	annotationClient, err := annotation.NewClient(s.cfg.GetAnnotationHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	annotator := shared_search.NewTextRequestAnnotator(annotationClient)
	annotatedRequest, err := annotator.Annotate(request)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	// TODO this should be somewhere else
	if categoryAnnotation, found := annotatedRequest.Annotations["category"]; found {
		entity, err := s.ontGraph.GetEntity(categoryAnnotation[0].ID)
		if err != nil {
			log.Error(err)
		} else {
			childrenLabels := []string{}
			for _, c := range entity.Children {
				childrenLabels = append(childrenLabels, strings.ToLower(c.Label))
			}
			annotatedRequest.QueryExpansions = map[string][]string{
				"category": childrenLabels,
			}
		}
	}

	// ----------
	// NOTE temporary check to deal with iOS build <=86 that crashes
	// if there are search results, but no entities, as it happens in some
	// cases when we use full text shared_search.
	// We'll want to remove this check when all users have updated their apps.
	doFullTextSearch := true
	deviceInfo, err := service.GetAuthDeviceInfoFromGinContext(ctx)
	if err != nil {
		log.Error(err)
	}

	if deviceInfo != nil {
		if deviceInfo.OS == service.DeviceIOS && deviceInfo.BuildNumber <= 86 {
			doFullTextSearch = false
		}
	}
	// ----------

	result, err := s.doSearchV2(ctx, annotatedRequest, storeID, esClient, doFullTextSearch)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	// build response
	response := shared_search.NewResponse()
	response.WithID()
	response.Matches = &shared_search.Matches{}
	for _, item := range result.Items {
		item_v2 := s.toItemV2(item)
		itemBytes, err := json.Marshal(item_v2)
		if err != nil {
			log.Error(err)
			continue
		}
		response.Matches.Items = append(response.Matches.Items, json.RawMessage(itemBytes))
	}
	response.Matches.Total = result.TotalCount

	// if no matches, has category and other entities
	// then, show similar
	if request.GetShowSimilar() {
		if len(result.Items) == 0 {
			similar, err := s.searchSimilarV2(ctx, annotatedRequest, storeID, esClient, doFullTextSearch)
			if err != nil {
				log.Error(err)
				ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
				return
			}
			response.Similar = similar
		}
	}

	if request.GetAggregations() != nil {
		response.Aggregations = s.buildAggregationsV2(annotatedRequest, result)
	}

	if request.GetShowGuided() {
		response.Guided = s.buildGuidedV2(annotatedRequest, result)
	}

	response.Query = &shared_search.QueryAnalysis{
		Intent:     annotatedRequest.GetIntent(),
		Entities:   s.buildTextEntitiesResponseV2(annotatedRequest),
		PriceRange: annotatedRequest.PriceRange,
	}

	response.Took = time.NowInMilliseconds() - startTime

	ctx.JSON(http.StatusOK, response)

	// log event
	annotatedRequest.Endpoint = ctx.Request.URL.String()
	annotatedRequest.MatchesCount = response.Matches.Total
	go s.eventLogger.Save(storeID, annotatedRequest)
}

func (s *Service) searchSimilarV2(ctx *gin.Context, request *shared_search.AnnotatedTextRequest, storeID string, esClient *elastic.Client, doFullTextSearch bool) (*shared_search.Similar, error) {
	similar := &shared_search.Similar{}
	category, hasCategory := request.Annotations["category"]
	if hasCategory && len(request.Annotations) > 1 {
		newRequest := shared_search.NewAnnotatedTextRequest(request.TextRequest)
		newRequest.Size = request.Size
		newRequest.Filters = request.Filters
		for _, v := range request.Annotations["category"] {
			newRequest.AddAnnotation(v)
		}

		result, err := s.doSearchV2(ctx, newRequest, storeID, esClient, doFullTextSearch)
		if err != nil {
			return nil, err
		}

		for _, item := range result.Items {
			item_v2 := s.toItemV2(item)
			itemBytes, err := json.Marshal(item_v2)
			if err != nil {
				log.Error(err)
				continue
			}
			similar.Matches.Items = append(similar.Matches.Items, json.RawMessage(itemBytes))
		}
		similar.Query = category[0].Value
		similar.Matches.Total = result.TotalCount
	}
	return similar, nil
}

func (s *Service) doSearchV2(ctx *gin.Context, request *shared_search.AnnotatedTextRequest, storeID string, esClient *elastic.Client, doFullTextSearch bool) (*shared_search.Result, error) {
	// convert fields to v3 format
	if request.GetSortByField() != nil {
		newSort := map[string]*shared_search.SortByFieldValue{}
		for k, v := range request.GetSortByField() {
			if strings.Contains(k, "price_") {
				k = strings.Replace(k, "price_", "price.", -1)
			}
			newSort[strings.Replace(k, "source.", "", -1)] = v
		}
		request.SortByField = newSort
	}

	if request.GetFilters() != nil {
		newFilters := map[string]*json.RawMessage{}
		for k, v := range request.GetFilters() {
			if k == "store_location" {
				k = "store_locations"
			} else if strings.Contains(k, "price_") {
				k = strings.Replace(k, "price_", "price.", -1)
			}
			newFilters[strings.Replace(k, "source.", "", -1)] = v
		}
		request.Filters = newFilters
	}

	if request.GetAggregations() != nil {
		if request.Aggregations.CountQuery != nil {
			fields := []string{}
			for _, v := range request.Aggregations.CountQuery.Fields {
				if strings.Contains(v, "price_") {
					v = strings.Replace(v, "price_", "price.", -1)
				}
				fields = append(fields, strings.Replace(v, "source.", "", -1))
			}
			request.Aggregations.CountQuery.Fields = fields
		}
		if request.Aggregations.MaxQuery != nil {
			fields := []string{}
			for _, v := range request.Aggregations.MaxQuery.Fields {
				if strings.Contains(v, "price_") {
					v = strings.Replace(v, "price_", "price.", -1)
				}
				fields = append(fields, strings.Replace(v, "source.", "", -1))
			}
			request.Aggregations.MaxQuery.Fields = fields
		}
		if request.Aggregations.MinQuery != nil {
			fields := []string{}
			for _, v := range request.Aggregations.MinQuery.Fields {
				if strings.Contains(v, "price_") {
					v = strings.Replace(v, "price_", "price.", -1)
				}
				fields = append(fields, strings.Replace(v, "source.", "", -1))
			}
			request.Aggregations.MinQuery.Fields = fields
		}
	}
	// ---

	store, err := product.NewESStore(storeID, esClient)
	if err != nil {
		return nil, err
	}

	if !doFullTextSearch && len(request.Annotations) == 0 {
		return &shared_search.Result{}, nil
	}

	engine := shared_search.NewESEngine(store)
	result, err := engine.Search(ctx, request, doFullTextSearch)
	if err != nil {
		return nil, err
	}

	return result, nil
}

func (s *Service) buildAggregationsV2(request shared_search.Request, result *shared_search.Result) *shared_search.Aggregations {
	aggs := &shared_search.Aggregations{}

	countQuery := request.GetAggregations().CountQuery
	if countQuery != nil {
		aggs.Count = map[string][]*shared_search.CountAggregation{}
		for _, k := range countQuery.Fields {
			if agg, ok := result.Aggregations["count_"+k]; ok {
				for _, bucket := range agg.Buckets {
					newAggregation := &shared_search.CountAggregation{
						Value: bucket.Key,
						Count: bucket.DocCount,
					}
					for i := 0; i < countQuery.TopHits; i++ {
						hit := bucket.TopHits.Hits.Hits[i]
						newAggregation.TopHits = append(newAggregation.TopHits, hit.Item)
					}
					aggs.Count[k] = append(aggs.Count[k], newAggregation)
				}
			}
		}
	}

	maxQuery := request.GetAggregations().MaxQuery
	if maxQuery != nil {
		for _, field := range maxQuery.Fields {
			if agg, ok := result.Aggregations["max_"+field]; ok {
				if aggs.Max == nil {
					aggs.Max = map[string]float32{}
				}
				aggs.Max[field] = agg.Value
			}
		}
	}

	minQuery := request.GetAggregations().MinQuery
	if minQuery != nil {
		for _, field := range minQuery.Fields {
			if agg, ok := result.Aggregations["min_"+field]; ok {
				if aggs.Min == nil {
					aggs.Min = map[string]float32{}
				}
				aggs.Min[field] = agg.Value
			}
		}
	}

	return aggs
}

// TODO this has to be abstracted, shouldn't be using elastic-specific primitives here
func (s *Service) buildGuidedV2(request *shared_search.AnnotatedTextRequest, result *shared_search.Result) []shared_search.GuidedSearchItem {
	items := []shared_search.GuidedSearchItem{}
	keys := []string{"heel_form", "shoe_width", "upper_material", "volume", "pattern", "technology", "color", "length", "category", "occasion", "gender", "filling", "season", "heel_height", "shoe_toecap", "sport", "density", "shaft_height", "shirt_collar", "shaft_width", "trouser_rise", "shoe_fastener"}
	for _, k := range keys {
		// don't suggest for same categories
		if _, found := request.Annotations[k]; found {
			continue
		}
		if agg, found := result.Aggregations[k]; found {
			for _, bucket := range agg.Buckets {
				newItem := shared_search.GuidedSearchItem(bucket.Key)
				items = append(items, newItem)
			}
		}
	}

	if len(items) > 20 {
		items = items[:20]
	}

	return items
}

func (s *Service) buildTextEntitiesResponseV2(request *shared_search.AnnotatedTextRequest) []*shared_search.TextRequestAnnotation {
	entities := []*shared_search.TextRequestAnnotation{}
	for k := range request.Annotations {
		for _, v := range request.Annotations[k] {
			entities = append(entities, v)
		}
	}
	return entities
}
