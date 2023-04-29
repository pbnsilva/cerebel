package apps

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
)

type ImageTagger struct {
	cfg *shared.DashboardConfig
}

func NewImageTagger(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *ImageTagger {
	app := &ImageTagger{cfg}

	engine.GET("/imagetagger", auth.AuthorizeRequestMiddleware(engine), app.getImageTagger)

	return app
}

func (a *ImageTagger) getImageTagger(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "imagetagger.html", gin.H{})
}
