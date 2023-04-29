package search

import (
	"encoding/json"
	"errors"
	"net/http"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product_v2 "github.com/petard/cerebel/shared/product.v2"
	product_v3 "github.com/petard/cerebel/shared/product.v3"
	shared_search "github.com/petard/cerebel/shared/search"
	"github.com/petard/cerebel/shared/service"
	"github.com/petard/cerebel/shared/time"
)

var (
	idParamName = "id"

	errItemNotFound = errors.New("Item not found.")
)

func (s *Service) getItemByIDV2(ctx *gin.Context) {
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
	store, err := product_v3.NewESStore(storeID, esClient)
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
	response := shared_search.NewResponse()
	response.WithID()

	// hackish convert to v3
	item_v2 := s.toItemV2(item)

	itemBytes, err := json.Marshal(item_v2)
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

func (s *Service) toItemV2(item *product_v3.Item) *product_v2.Item {
	v2Item := &product_v2.Item{
		Source: &product_v2.Source{
			ID: item.ID,
		},
		Annotations: item.Annotations,
	}

	if item.Name != "" {
		v2Item.Source.Name = item.Name
	}

	if item.Brand != "" {
		v2Item.Source.Brand = item.Brand
	}

	if item.Description != "" {
		v2Item.Source.Description = item.Description
	}

	if item.URL != "" {
		v2Item.Source.URL = item.URL
	}

	if item.Gender != nil {
		v2Item.Source.Gender = item.Gender
	}

	if item.ImageURL != nil {
		v2Item.Source.ImageURL = item.ImageURL
	}

	if item.Price != nil {
		v2Item.Source.Currency = "EUR"
		v2Item.Source.Price = item.Price.EUR
		v2Item.Source.PriceEUR = item.Price.EUR
		v2Item.Source.PriceGBP = item.Price.GBP
		v2Item.Source.PriceUSD = item.Price.USD
		v2Item.Source.PriceDKK = item.Price.DKK
		v2Item.Source.PriceSEK = item.Price.SEK
		v2Item.Source.PriceINR = item.Price.INR
		v2Item.Source.PriceAUD = item.Price.AUD
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

	if item.Shops != nil {
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
		v2Item.Source.Stores = stores
	}

	return v2Item
}
