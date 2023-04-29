package apps

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
)

type PIM struct {
	cfg *shared.DashboardConfig
}

func NewPIM(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *PIM {
	app := &PIM{cfg}

	engine.GET("/pim", auth.AuthorizeRequestMiddleware(engine), app.getPIM)

	return app
}

func (a *PIM) getPIM(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "pim.html", gin.H{})
}
