package apps

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/search"
	"github.com/petard/cerebel/shared/store"
	"github.com/petard/cerebel/shared/suggester"
)

const (
	faerStoreID     = "faer"
	faerSearchToken = "AonNLZaEXMtLiHdqJqqGQjKrVRGMhq"
	faerAdminToken  = "PJYsxDjsgNOhWOwDENHjUzoYrOtlVv"
)

type searchRequest struct {
	Query  string `json:"query"`
	Gender string `json:"gender"`
	Page   int    `json:"page"`
}

type updateRequest struct {
	IDs         []string            `json:"ids"`
	Annotations map[string][]string `json:"annotations"`
}

type SearchDemo struct {
	cfg *shared.DashboardConfig
}

func NewSearchDemo(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *SearchDemo {
	app := &SearchDemo{cfg}

	engine.GET("/searchdemo", auth.AuthorizeRequestMiddleware(engine), app.getSearchDemo)
	engine.GET("/searchdemo/suggest", auth.AuthorizeRequestMiddleware(engine), app.getSuggestions)
	engine.POST("/searchdemo/search", auth.AuthorizeRequestMiddleware(engine), app.doSearch)
	engine.POST("/searchdemo/update", auth.AuthorizeRequestMiddleware(engine), app.doUpdate)

	return app
}
func (a *SearchDemo) doUpdate(ctx *gin.Context) {
	var request *updateRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := store.NewClient(a.cfg.GetStoreHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error updating."})
		return
	}

	items, err := client.BulkGetItemsByID(request.IDs, faerStoreID, faerAdminToken)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error updating."})
		return
	}

	for _, item := range items {
		item.Annotations = request.Annotations
	}

	if err := client.BulkUpsertItems(items, faerStoreID, faerAdminToken); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error updating."})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{})
}

func (a *SearchDemo) getSearchDemo(ctx *gin.Context) {
	isEditMode := false
	q := ctx.Request.URL.Query()
	if val, found := q["edit"]; found {
		if val[0] == "1" {
			isEditMode = true
		}
	}

	ctx.HTML(http.StatusOK, "searchdemo.html", gin.H{"IsEditMode": isEditMode})
}

func (a *SearchDemo) getSuggestions(ctx *gin.Context) {
	query := ctx.Request.URL.Query()
	term := query["q"][0]
	endpoint := fmt.Sprintf("%s/store/%s/suggest?token=%s&q=%s", a.cfg.GetSearchHost(), faerStoreID, faerSearchToken, term)
	resp, err := http.Get(endpoint)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error doing search."})
		return
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error doing search."})
		return
	}

	response := &suggester.Response{}
	if err := json.Unmarshal(data, &response); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error doing search."})
		return
	}

	suggestions := []string{}
	for _, sug := range response.Suggestions {
		var suggestion *suggester.Suggestion
		if err := json.Unmarshal(sug, &suggestion); err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error doing search."})
			return
		}
		suggestions = append(suggestions, suggestion.Value)
	}

	ctx.JSON(http.StatusOK, gin.H{"suggestions": suggestions})
}

func (a *SearchDemo) doSearch(ctx *gin.Context) {
	var request *searchRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	response, err := a.doTextSearch(request.Query, request.Gender, request.Page)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error doing search."})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"response": response})
}

func (a *SearchDemo) doTextSearch(query, gender string, page int) (*search.Response, error) {
	offset := (page - 1) * 20
	searchRequest := &search.TextRequest{
		BaseRequest: &search.BaseRequest{
			Offset: &offset,
		},
		Query: query,
	}

	searchClient, err := search.NewClient(a.cfg.GetSearchHost(), faerStoreID, faerSearchToken)
	if err != nil {
		return nil, err
	}

	if gender != "" {
		gen := json.RawMessage(fmt.Sprintf(`["%s"]`, gender))
		searchRequest.Filters = map[string]*json.RawMessage{"gender": &gen}
	}

	searchResponse, err := searchClient.TextSearch(searchRequest)

	return searchResponse, err
}
