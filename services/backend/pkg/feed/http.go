package feed

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/shared/es"
	shared_feed "github.com/petard/cerebel/shared/feed"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/monitoring"
	product_v2 "github.com/petard/cerebel/shared/product.v2"
	product_v3 "github.com/petard/cerebel/shared/product.v3"
	shared_service "github.com/petard/cerebel/shared/service"
	"github.com/petard/cerebel/shared/stats"
	"github.com/petard/cerebel/shared/time"
)

const (
	monitoringNamespace       = "feed"
	monitoringFeedHandlerName = "feed"

	pageParamName     = "page"
	sizeParamName     = "size"
	genderParamName   = "gender"
	categoryParamName = "category"
)

type instagramItemV1 struct {
	ID        string                  `json:"id"`
	Title     string                  `json:"title"`
	Date      uint64                  `json:"date"`
	ImageURL  string                  `json:"image_url"`
	MediaType string                  `json:"media_type"`
	Source    *shared_feed.ItemSource `json:"source"`
	Items     []*product_v2.Item      `json:"items"`
	Position  int                     `json:"position,omitempty"`
}

// HTTPService exposes search operations on records.
type HTTPService struct {
	cfg        *service.Config
	statsStore *stats.Store
}

// NewHTTPService returns a new instance of HTTPService.
func NewHTTPService(cfg *service.Config) (*HTTPService, error) {
	statsStore, err := stats.NewStore(cfg.GetRedisHost())
	if err != nil {
		return nil, err
	}

	return &HTTPService{
		cfg:        cfg,
		statsStore: statsStore,
	}, nil
}

func (s *HTTPService) SetRoutes(engine *gin.Engine) {
	v1Group := engine.Group("/")
	{
		v1Group.GET(fmt.Sprintf("/store/:%s/feed", shared_service.AuthStoreIDContextParam), monitoring.InstrumentHandler(s.feedV1, monitoringNamespace, monitoringFeedHandlerName))
	}

	v3Group := engine.Group("/v3")
	{
		v3Group.GET(fmt.Sprintf("/store/:%s/feed", shared_service.AuthStoreIDContextParam), monitoring.InstrumentHandler(s.feedV3, monitoringNamespace, monitoringFeedHandlerName))
	}
}

func (s *HTTPService) feedV3(ctx *gin.Context) {
	// create connection to elasticsearch
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	requestQueryParams := ctx.Request.URL.Query()
	queryParams := map[string]interface{}{}
	if pageParam, found := requestQueryParams[pageParamName]; found {
		queryParams[pageParamName], _ = strconv.Atoi(pageParam[0])
	}
	if sizeParam, found := requestQueryParams[sizeParamName]; found {
		queryParams[sizeParamName], _ = strconv.Atoi(sizeParam[0])
	}
	if genderParam, found := requestQueryParams[genderParamName]; found {
		queryParams[genderParamName] = genderParam[0]
	}
	if categoryParam, found := requestQueryParams[categoryParamName]; found {
		queryParams[categoryParamName] = categoryParam[0]
	}

	// get user ID
	userID, _ := shared_service.GetAuthUserIDFromGinContext(ctx)

	// do search
	startTime := time.NowInMilliseconds()
	store := shared_feed.NewStore(storeID, esClient)
	results, totalCount, err := getFeedItems(ctx, store, s.statsStore, queryParams, userID)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	// build response
	response := shared_feed.NewResponse()
	response.WithID()
	response.Records = results
	response.Total = totalCount
	response.Took = time.NowInMilliseconds() - startTime

	ctx.Writer.Header().Set("Cache-Control", "private, max-age=600")
	ctx.JSON(http.StatusOK, response)
}

func (s *HTTPService) feedV1(ctx *gin.Context) {
	// create connection to elasticsearch
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	requestQueryParams := ctx.Request.URL.Query()
	queryParams := map[string]interface{}{}
	if pageParam, found := requestQueryParams[pageParamName]; found {
		queryParams[pageParamName], _ = strconv.Atoi(pageParam[0])
	}
	if sizeParam, found := requestQueryParams[sizeParamName]; found {
		queryParams[sizeParamName], _ = strconv.Atoi(sizeParam[0])
	}
	if genderParam, found := requestQueryParams[genderParamName]; found {
		queryParams[genderParamName] = genderParam[0]
	}

	// do search
	startTime := time.NowInMilliseconds()
	store := shared_feed.NewStore(storeID, esClient)
	results, totalCount, err := getFeedItems(ctx, store, nil, queryParams, "")
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	// convert to v2 format
	v2Results := []json.RawMessage{}
	for _, res := range results {
		var feedItem *shared_feed.InstagramItem
		if err := json.Unmarshal(res, &feedItem); err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
			return
		}

		feedItemV1 := s.toFeedItemV1(feedItem)

		v2Products := []*product_v2.Item{}
		for _, item := range feedItem.Items {
			v2Products = append(v2Products, s.toItemV2(item))
		}
		feedItemV1.Items = v2Products

		itemRaw, err := json.Marshal(feedItemV1)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
			return
		}

		v2Results = append(v2Results, json.RawMessage(itemRaw))
	}
	// ---

	// build response
	response := shared_feed.NewResponse()
	response.WithID()
	response.Records = v2Results
	response.Total = totalCount
	response.Took = time.NowInMilliseconds() - startTime

	ctx.Writer.Header().Set("Cache-Control", "private, max-age=900")
	ctx.JSON(http.StatusOK, response)
}

func (s *HTTPService) toFeedItemV1(item *shared_feed.InstagramItem) *instagramItemV1 {
	return &instagramItemV1{
		ID:        item.ID,
		Title:     item.Title,
		Date:      item.Date,
		ImageURL:  item.ImageURL,
		MediaType: item.MediaType,
		Source:    item.Source,
		Position:  item.Position,
	}
}

func (s *HTTPService) toItemV2(item *product_v3.Item) *product_v2.Item {
	stores := []*product_v2.Store{}
	for _, v := range item.Shops {
		stores = append(stores, &product_v2.Store{
			Name:       v.Name,
			Country:    v.Country,
			City:       v.City,
			PostalCode: v.PostalCode,
			Location:   &product_v2.Location{Lat: v.Location.Lat, Lon: v.Location.Lon},
			Address:    v.Address,
		})
	}

	v2Item := &product_v2.Item{
		Source: &product_v2.Source{
			ID:          item.ID,
			Name:        item.Name,
			Brand:       item.Brand,
			URL:         item.URL,
			Gender:      item.Gender,
			Description: item.Description,
			ImageURL:    item.ImageURL,
			Currency:    "EUR",
			Price:       item.Price.EUR,
			PriceEUR:    item.Price.EUR,
			PriceGBP:    item.Price.GBP,
			PriceUSD:    item.Price.USD,
			PriceDKK:    item.Price.DKK,
			PriceSEK:    item.Price.SEK,
			PriceINR:    item.Price.INR,
			PriceAUD:    item.Price.AUD,
			Stores:      stores,
		},
		Annotations: item.Annotations,
	}

	if item.OriginalPrice != nil {
		v2Item.Source.OriginalPrice = item.OriginalPrice.EUR
		v2Item.Source.OriginalPriceEUR = item.OriginalPrice.EUR
		v2Item.Source.OriginalPriceGBP = item.OriginalPrice.GBP
		v2Item.Source.OriginalPriceUSD = item.OriginalPrice.USD
		v2Item.Source.OriginalPriceDKK = item.OriginalPrice.DKK
		v2Item.Source.OriginalPriceSEK = item.OriginalPrice.SEK
		v2Item.Source.OriginalPriceINR = item.OriginalPrice.INR
		v2Item.Source.OriginalPriceAUD = item.OriginalPrice.AUD
	}

	return v2Item
}
