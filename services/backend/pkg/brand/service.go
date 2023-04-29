package brand

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/backend/pkg/service"
	shared_brand "github.com/petard/cerebel/shared/brand"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	"github.com/petard/cerebel/shared/search"
	shared_service "github.com/petard/cerebel/shared/service"
	"github.com/petard/cerebel/shared/stats"
	shared_time "github.com/petard/cerebel/shared/time"
)

const (
	brandIDParamName = "brand"
	genderParamName  = "gender"

	defaultTopNPopularProducts = 20
)

var (
	errMissingGender = errors.New("missing gender parameter")
)

type Service struct {
	cfg          *service.Config
	productStore *product.ESStore
	statsStore   *stats.Store
}

func NewService(cfg *service.Config) (*Service, error) {
	esClient, err := es.NewSimpleClient(cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore("faer", esClient)
	if err != nil {
		return nil, err
	}

	statsStore, err := stats.NewStore(cfg.GetRedisHost())
	if err != nil {
		return nil, err
	}

	return &Service{
		cfg:          cfg,
		productStore: productStore,
		statsStore:   statsStore,
	}, nil
}

func (s *Service) SetRoutes(engine *gin.Engine) {
	v3Group := engine.Group("/v3")
	{
		v3Group.GET(fmt.Sprintf("/store/:%s/brand/:%s", shared_service.AuthStoreIDContextParam, brandIDParamName), s.getBrand)
	}
}

func (s *Service) getBrand(ctx *gin.Context) {
	startTime := shared_time.NowInMilliseconds()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	brandID := ctx.Params.ByName(brandIDParamName)
	if brandID == "" {
		ctx.JSON(http.StatusBadRequest, shared_service.NewErrorResponse(shared_service.ErrBadRequest.Error()))
		return
	}

	gender := ""
	genderParam, found := ctx.Request.URL.Query()[genderParamName]
	if found {
		gender = genderParam[0]
	}

	if gender == "" {
		ctx.JSON(http.StatusBadRequest, shared_service.NewErrorResponse(errMissingGender.Error()))
		return
	}

	brandStore := shared_brand.NewStore(esClient)
	brandItem, err := brandStore.Get(ctx, brandID)
	if err != nil {
		if err == shared_brand.ErrBrandNotFound {
			ctx.JSON(http.StatusNotFound, shared_service.NewErrorResponse("Brand not found"))
			return
		}
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
	}

	popularProducts, err := s.getPopularProducts(ctx, brandID, gender, defaultTopNPopularProducts)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	if len(popularProducts) > 0 {
		popularBytes, err := json.Marshal(popularProducts)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
			return
		}
		brandItem.PopularProducts = popularBytes
	}

	categories, categoryProducts, err := s.getProductsByCategory(ctx, brandID, gender, esClient)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	if len(categories) > 0 {
		catResults := []*shared_brand.CategoryProducts{}
		for i := 0; i < len(categories); i++ {
			productsBytes, err := json.Marshal(categoryProducts[i])
			if err != nil {
				log.Error(err)
				ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
				return
			}

			cat := &shared_brand.CategoryProducts{
				Name:     categories[i],
				Products: productsBytes,
			}

			catResults = append(catResults, cat)
		}
		brandItem.Categories = catResults
	}

	response := shared_brand.NewResponse()
	response.WithID()

	itemBytes, err := json.Marshal(brandItem)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	response.Brand = itemBytes

	response.Took = shared_time.NowInMilliseconds() - startTime
	response.Total = 1

	ctx.Writer.Header().Set("Cache-Control", "private, max-age=43200")
	ctx.JSON(http.StatusOK, response)
}

func (s *Service) getPopularProducts(ctx context.Context, brandID, gender string, topN int) ([]*product.Item, error) {
	likedProductIDs, _, err := s.statsStore.GetTopLikedProductsForBrand(brandID, gender, topN)
	if err != nil {
		return nil, err
	}

	// TODO add shared and viewed?

	if len(likedProductIDs) == 0 {
		return []*product.Item{}, nil
	}

	return s.productStore.BulkGetItemsByID(ctx, likedProductIDs)
}

func (s *Service) getProductsByCategory(ctx context.Context, brandID, gender string, esClient *elastic.Client) ([]string, [][]*product.Item, error) {
	q := elastic.NewBoolQuery().
		Filter(elastic.NewTermQuery("brand_id", brandID)).
		Filter(elastic.NewTermQuery("gender", gender))

	agg := elastic.NewTermsAggregation().Field("annotations.category").SubAggregation("top_hits", elastic.NewTopHitsAggregation().DocvalueField("annotations.category").Size(10))

	svcResult, err := esClient.Search().
		Index("cerebel_store_faer").
		Query(q).
		Aggregation("category", agg).
		Size(0).
		Do(ctx)
	if err != nil {
		return nil, nil, err
	}

	var resAgg *search.ResultAggregation
	if err := json.Unmarshal([]byte(*svcResult.Aggregations["category"]), &resAgg); err != nil {
		return nil, nil, err
	}

	res := [][]*product.Item{}
	categories := []string{}
	for _, bucket := range resAgg.Buckets {
		if len(bucket.TopHits.Hits.Hits) > 0 {
			categories = append(categories, bucket.Key)
			catRes := []*product.Item{}
			for _, hit := range bucket.TopHits.Hits.Hits {
				catRes = append(catRes, hit.Item)
			}
			res = append(res, catRes)
		}
	}

	return categories, res, nil
}
