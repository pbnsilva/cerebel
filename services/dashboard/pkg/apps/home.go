package apps

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
)

type Home struct {
	cfg *shared.DashboardConfig
}

func NewHome(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *Home {
	app := &Home{cfg}

	engine.GET("/", auth.AuthorizeRequestMiddleware(engine), app.getHome)

	return app
}

func (a *Home) getHome(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "home.html", gin.H{})
}
