package apps

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/suggester"
)

type SuggesterDemo struct {
	cfg *shared.DashboardConfig
}

func NewSuggesterDemo(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *SuggesterDemo {
	app := &SuggesterDemo{cfg}

	engine.GET("/suggesterdemo", auth.AuthorizeRequestMiddleware(engine), app.getSuggesterDemo)
	engine.GET("/suggesterdemo/suggest", auth.AuthorizeRequestMiddleware(engine), app.suggest)

	return app
}

func (a *SuggesterDemo) getSuggesterDemo(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "suggesterdemo.html", gin.H{})
}

func (a *SuggesterDemo) suggest(ctx *gin.Context) {
	var response *suggester.Response

	urlQ := ctx.Request.URL.Query()
	if val, found := urlQ["q"]; found {
		client, err := suggester.NewClient(a.cfg.GetSuggesterHost(), faerStoreID, faerSearchToken)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error connecting to client."})
			return
		}

		response, err = client.Suggest(val[0], []string{})
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"message": "Error fetching suggestions."})
			return
		}
	}

	ctx.JSON(http.StatusOK, gin.H{"response": response})
}
