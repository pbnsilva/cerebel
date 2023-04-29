package apps

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/feed"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/search"
)

const (
	storeID          = "faer"
	configBucketName = "faer.cerebel.io"
	configObjectName = "feed.config"
)

type GetPageRequest struct {
	Nb     int    `json:"nb"`
	Size   int    `json:"size"`
	IsLive bool   `json:"isLive"`
	Gender string `json:"gender"`
}

type SetIsLiveRequest struct {
	ID     string `json:"id"`
	IsLive bool   `json:"isLive"`
}

type SetItemsRequest struct {
	ID    string   `json:"id"`
	Items []string `json:"items"`
}

type ProductInfoRequest struct {
	ID string `json:"id"`
}

type DeleteItemRequest struct {
	ID string `json:"id"`
}

type ProductInfo struct {
	ID       string   `json:"id"`
	Name     string   `json:"name"`
	Brand    string   `json:"brand"`
	URL      string   `json:"url"`
	ImageURL []string `json:"image_url"`
}

type SearchRequest struct {
	Brand  string `json:"brand"`
	Text   string `json:"text"`
	Gender string `json:"gender"`
}

type SourceRequest struct {
	Type string `json:"type"`
	URL  string `json:"url"`
}

type PromotionRequest struct {
	ProductID string `json:"product_id"`
	ImageURL  string `json:"image_url"`
	Position  int32  `json:"position"`
	Name      string `json:"name"`
}

type FeedEditor struct {
	cfg *shared.DashboardConfig
}

func NewFeedEditor(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *FeedEditor {
	app := &FeedEditor{cfg}

	engine.GET("/feededitor", auth.AuthorizeRequestMiddleware(engine), app.index)
	engine.GET("/feededitor/listSources", auth.AuthorizeRequestMiddleware(engine), app.listSources)
	engine.POST("/feededitor/getPage", auth.AuthorizeRequestMiddleware(engine), app.getPage)
	engine.POST("/feededitor/deleteItem", auth.AuthorizeRequestMiddleware(engine), app.deleteItem)
	engine.POST("/feededitor/setItems", auth.AuthorizeRequestMiddleware(engine), app.setItems)
	engine.POST("/feededitor/productInfo", auth.AuthorizeRequestMiddleware(engine), app.productInfo)
	engine.POST("/feededitor/search", auth.AuthorizeRequestMiddleware(engine), app.search)
	engine.POST("/feededitor/deleteSource", auth.AuthorizeRequestMiddleware(engine), app.deleteSource)
	engine.POST("/feededitor/addSource", auth.AuthorizeRequestMiddleware(engine), app.addSource)
	engine.POST("/feededitor/addPromotion", auth.AuthorizeRequestMiddleware(engine), app.addPromotion)
	engine.GET("/feededitor/listPromotions", auth.AuthorizeRequestMiddleware(engine), app.listPromotions)
	engine.POST("/feededitor/deletePromotion", auth.AuthorizeRequestMiddleware(engine), app.deletePromotion)

	return app
}

func (s *FeedEditor) index(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "feededitor.html", gin.H{})
}

func (s *FeedEditor) getPage(ctx *gin.Context) {
	var request *GetPageRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	response, err := client.GetPage(int32(request.Nb), int32(request.Size), request.IsLive, request.Gender)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error fetching items from feed"})
		return
	}

	var items []map[string]interface{} // TODO this should be feed.Item
	if err := json.Unmarshal(response, &items); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error fetching items from feed"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"items": items})
}

func (s *FeedEditor) deleteItem(ctx *gin.Context) {
	var request *DeleteItemRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	if err := client.DeleteByIDs([]string{request.ID}); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error deleting item"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func (s *FeedEditor) setItems(ctx *gin.Context) {
	var request *SetItemsRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	if err := client.SetItems(request.ID, request.Items); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func (s *FeedEditor) productInfo(ctx *gin.Context) {
	var request *ProductInfoRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := search.NewClient(s.cfg.GetSearchHost(), "faer", "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq")
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	response, err := client.GetItem(request.ID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error setting value"})
		return
	}

	if response.Matches == nil {
		ctx.JSON(http.StatusNotFound, gin.H{"message": "Product was not found!"})
		return
	}

	var productInfo *ProductInfo
	if err := json.Unmarshal(response.Matches.Items[0], &productInfo); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error fetching product"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"info": productInfo})
}

func (s *FeedEditor) listSources(ctx *gin.Context) {
	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to feed host"})
		return
	}

	sources, err := client.ListSources()
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error getting sources"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"sources": sources})
}

func (s *FeedEditor) search(ctx *gin.Context) {
	var request *SearchRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := search.NewClient(s.cfg.GetSearchHost(), "faer", "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq")
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	var size int = 200
	var order string = "asc"
	searchRequest := &search.TextRequest{
		BaseRequest: &search.BaseRequest{
			Size:   &size,
			Fields: []string{"id", "name", "brand", "url", "image_url"},
			SortByField: map[string]*search.SortByFieldValue{
				"annotations.category": &search.SortByFieldValue{&order},
			},
		},
		Query: request.Brand + " " + request.Text,
	}

	if request.Gender != "all genders" {
		msg := json.RawMessage(fmt.Sprintf(`"%s"`, request.Gender))
		searchRequest.BaseRequest.Filters = map[string]*json.RawMessage{"gender": &msg}
	}

	response, err := client.TextSearch(searchRequest)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error searching for products"})
		return
	}

	var products []*ProductInfo
	for _, item := range response.Matches.Items {
		var product *ProductInfo
		if err := json.Unmarshal(item, &product); err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error searching for products"})
			return
		}
		products = append(products, product)
	}

	ctx.JSON(http.StatusOK, gin.H{"products": products})
}

func (s *FeedEditor) listPromotions(ctx *gin.Context) {
	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to feed host"})
		return
	}

	response, err := client.ListPromotions()
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error getting promotions"})
		return
	}

	var promotions []*feed.InstagramItem

	if len(response) > 0 {
		if err := json.Unmarshal(response, &promotions); err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error fetching items from feed"})
			return
		}
	}

	ctx.JSON(http.StatusOK, gin.H{"promotions": promotions})
}

func (s *FeedEditor) addPromotion(ctx *gin.Context) {
	var request *PromotionRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	if err := client.AddPromotion(request.ProductID, request.ImageURL, request.Position, request.Name); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error adding promotion"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func (s *FeedEditor) deletePromotion(ctx *gin.Context) {
	var request *PromotionRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	if err := client.DeletePromotion(request.ProductID); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error deleting promotion"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func (s *FeedEditor) addSource(ctx *gin.Context) {
	var request *SourceRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	if err := client.AddSource(request.Type, request.URL); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error adding source"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func (s *FeedEditor) deleteSource(ctx *gin.Context) {
	var request *SourceRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := feed.NewClient(s.cfg.GetFeedHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to host"})
		return
	}

	if err := client.DeleteSource(request.Type, request.URL); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error deleting source"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}
