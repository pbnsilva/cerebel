package apps

import (
	"net/http"
	"sort"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/brand"
	"github.com/petard/cerebel/shared/log"
)

type BrandPages struct {
	cfg *shared.DashboardConfig
}

func NewBrandPages(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *BrandPages {
	app := &BrandPages{cfg}

	engine.GET("/brandpages", auth.AuthorizeRequestMiddleware(engine), app.getBrandPages)
	engine.GET("/brandpages/:brandID", auth.AuthorizeRequestMiddleware(engine), app.getBrand)
	engine.POST("/brandpages/:brandID/update", auth.AuthorizeRequestMiddleware(engine), app.updateBrand)

	return app
}

func (a *BrandPages) getBrandPages(ctx *gin.Context) {
	client, err := brand.NewClient(a.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	brands, err := client.ListBrands(ctx)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	sort.Slice(brands, func(i, j int) bool {
		return strings.ToLower(brands[i].Name) < strings.ToLower(brands[j].Name)
	})

	ctx.HTML(http.StatusOK, "brandpages.html", gin.H{"brands": brands})
}

func (a *BrandPages) getBrand(ctx *gin.Context) {
	client, err := brand.NewClient(a.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	brandID := ctx.Param("brandID")

	brand, err := client.Get(ctx, brandID)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	brandTags := strings.Join(brand.Tags, ",")

	ctx.HTML(http.StatusOK, "brandpages.html", gin.H{"brand": brand, "brandTags": brandTags})
}

func (a *BrandPages) updateBrand(ctx *gin.Context) {
	var request *brand.Item
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client, err := brand.NewClient(a.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	for i, _ := range request.Tags {
		request.Tags[i] = strings.ToLower(strings.TrimSpace(request.Tags[i]))
	}

	if err := client.Put(ctx, request); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{})
}
