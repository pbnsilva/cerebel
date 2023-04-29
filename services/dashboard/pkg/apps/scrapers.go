package apps

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"
	"strconv"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	"github.com/petard/cerebel/shared/scrapyd"
)

const (
	scrapydProjectName = "scrapers"
)

type Scrapers struct {
	cfg *shared.DashboardConfig
}

type scheduleJobRequest struct {
	Spider string `json:"spider"`
}

type cancelJobRequest struct {
	JobID string `json:"jobid"`
}

func NewScrapers(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *Scrapers {
	app := &Scrapers{cfg}

	engine.GET("/scrapers", auth.AuthorizeRequestMiddleware(engine), app.getScrapers)
	engine.GET("/scrapers/listSpiders", auth.AuthorizeRequestMiddleware(engine), app.listSpiders)
	engine.GET("/scrapers/getLogs", auth.AuthorizeRequestMiddleware(engine), app.getLogs)
	engine.GET("/scrapers/listJobs", auth.AuthorizeRequestMiddleware(engine), app.listJobs)
	engine.POST("/scrapers/scheduleJob", auth.AuthorizeRequestMiddleware(engine), app.scheduleJob)
	engine.POST("/scrapers/cancelJob", auth.AuthorizeRequestMiddleware(engine), app.cancelJob)
	engine.POST("/scrapers/deleteProducts", auth.AuthorizeRequestMiddleware(engine), app.deleteProducts)

	return app
}

func (a *Scrapers) getScrapers(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "scrapers.html", gin.H{})
}

func (a *Scrapers) listSpiders(ctx *gin.Context) {
	client := scrapyd.NewClient(a.cfg.GetScrapydHost())

	spiders, err := client.ListSpiders(scrapydProjectName)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"spiders": spiders})
}

func (a *Scrapers) deleteProducts(ctx *gin.Context) {
	var request *scheduleJobRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	es, err := es.NewSimpleClient(a.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	store, err := product.NewESStore("faer", es)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := store.DeleteByQuery(ctx, elastic.NewBoolQuery().Filter(elastic.NewTermQuery("brand", request.Spider))); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{})
}

func (a *Scrapers) getLogs(ctx *gin.Context) {
	endpoint := fmt.Sprintf("%s/logs/scrapers/%s/%s.log", a.cfg.GetScrapydHost(), ctx.Query("spider"), ctx.Query("id"))
	resp, err := http.Get(endpoint)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"text": string(data)})
}

func (a *Scrapers) listJobs(ctx *gin.Context) {
	client := scrapyd.NewClient(a.cfg.GetScrapydHost())

	jobs, err := client.ListJobs(scrapydProjectName)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// get number of indexed products for finished jobs
	for _, j := range jobs.Finished {
		endpoint := fmt.Sprintf("%s/logs/scrapers/%s/%s.log", a.cfg.GetScrapydHost(), j.Spider, j.ID)
		resp, err := http.Get(endpoint)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer resp.Body.Close()

		data, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		j.Indexed = -1
		foundRe := regexp.MustCompile(`Found (\d+) products`)
		foundMatch := foundRe.FindSubmatch(data)
		if len(foundMatch) > 0 {
			found, err := strconv.Atoi(string(foundMatch[1]))
			if err == nil {
				j.Indexed = found
			}
		}

		upsertedRe := regexp.MustCompile(`Upserted (\d+) products`)
		upsertedMatch := upsertedRe.FindSubmatch(data)
		if len(upsertedMatch) > 0 {
			upserted, err := strconv.Atoi(string(upsertedMatch[1]))
			if err == nil {
				j.Indexed += upserted
			}
		}

		deletedRe := regexp.MustCompile(`Deleted (\d+) products`)
		deletedMatch := deletedRe.FindSubmatch(data)
		if len(deletedMatch) > 0 {
			deleted, err := strconv.Atoi(string(deletedMatch[1]))
			if err == nil {
				j.Indexed -= deleted
			}
		}
	}

	ctx.JSON(http.StatusOK, gin.H{"jobs": jobs})
}

func (a *Scrapers) scheduleJob(ctx *gin.Context) {
	var request *scheduleJobRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client := scrapyd.NewClient(a.cfg.GetScrapydHost())
	jobID, err := client.ScheduleJob(scrapydProjectName, request.Spider)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"jobid": jobID})
}

func (a *Scrapers) cancelJob(ctx *gin.Context) {
	var request *cancelJobRequest
	if err := ctx.ShouldBindWith(&request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"message": "Request validation failed."})
		return
	}

	client := scrapyd.NewClient(a.cfg.GetScrapydHost())
	if err := client.CancelJob(scrapydProjectName, request.JobID); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ok"})
}
