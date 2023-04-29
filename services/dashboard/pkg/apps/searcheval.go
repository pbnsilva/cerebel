package apps

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
)

type SearchEval struct {
	cfg *shared.DashboardConfig
}

func NewSearchEval(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *SearchEval {
	app := &SearchEval{cfg}

	engine.GET("/searcheval", auth.AuthorizeRequestMiddleware(engine), app.getSearchEval)

	return app
}

func (a *SearchEval) getSearchEval(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "searcheval.html", gin.H{})
}
