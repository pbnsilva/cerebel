package search

import (
	"encoding/json"
	"net/http"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	shared_search "github.com/petard/cerebel/shared/search"
	"github.com/petard/cerebel/shared/service"
	"github.com/petard/cerebel/shared/time"
)

func (s *Service) getItemByIDV3(ctx *gin.Context) {
	startTime := time.NowInMilliseconds()

	storeID, err := service.GetAuthStoreIDFromGinContext(ctx)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, service.NewErrorResponse(err.Error()))
		return
	}

	itemID := ctx.Params.ByName(idParamName)
	if itemID == "" {
		ctx.JSON(http.StatusBadRequest, service.NewErrorResponse(service.ErrBadRequest.Error()))
		return
	}

	// create connection to elasticsearch
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	// do search
	store, err := product.NewESStore(storeID, esClient)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	item, err := store.GetItemByID(ctx, itemID)
	if err != nil {
		log.Error(err)
		e, ok := err.(*elastic.Error)
		if ok && e.Status == 404 {
			ctx.JSON(http.StatusNotFound, service.NewErrorResponse(errItemNotFound.Error()))
			return
		}
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	// build response
	response := shared_search.NewResponse()
	response.WithID()

	itemBytes, err := json.Marshal(item)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	response.Matches = &shared_search.Matches{
		Items: []json.RawMessage{itemBytes},
	}

	response.Matches.Total = 1

	response.Took = time.NowInMilliseconds() - startTime

	ctx.JSON(http.StatusOK, response)
}

func (s *Service) getItemStats(ctx *gin.Context) {
	storeID, err := service.GetAuthStoreIDFromGinContext(ctx)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, service.NewErrorResponse(err.Error()))
		return
	}

	itemID := ctx.Params.ByName(idParamName)
	if itemID == "" {
		ctx.JSON(http.StatusBadRequest, service.NewErrorResponse(service.ErrBadRequest.Error()))
		return
	}

	// create connection to elasticsearch
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	store, err := product.NewESStore(storeID, esClient)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	item, err := store.GetItemByID(ctx, itemID)
	if err != nil {
		log.Error(err)
		e, ok := err.(*elastic.Error)
		if ok && e.Status == 404 {
			ctx.JSON(http.StatusNotFound, service.NewErrorResponse(errItemNotFound.Error()))
			return
		}
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	// build response
	startTime := time.NowInMilliseconds()
	response := shared_search.NewItemStatsResponse()
	response.WithID()

	likesCount, sharesCount := 0, 0
	for _, gender := range item.Gender {
		count, err := s.statsStore.GetLikesForProduct(itemID, item.BrandID, gender)
		if err == nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
			return
		}

		likesCount += count

		count, err = s.statsStore.GetSharesForProduct(itemID, item.BrandID, gender)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
			return
		}

		sharesCount += count
	}

	response.Likes = likesCount
	response.Shares = sharesCount

	response.Took = time.NowInMilliseconds() - startTime

	ctx.JSON(http.StatusOK, response)
}
