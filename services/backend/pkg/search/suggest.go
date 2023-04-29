package search

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/service"
	"github.com/petard/cerebel/shared/suggester"
	"github.com/petard/cerebel/shared/time"
)

const (
	sizeParamName   = "size"
	termParamName   = "q"
	genderParamName = "gender"

	defaultSize = 10
)

var (
	errMissingTermParam = errors.New("Missing term parameter")
	errInvalidGender    = errors.New("Invalid gender")
)

func (s *Service) suggestV3(ctx *gin.Context) {
	storeID, err := service.GetAuthStoreIDFromGinContext(ctx)
	if err != nil {
		ctx.JSON(http.StatusUnauthorized, service.NewErrorResponse(err.Error()))
		return
	}

	qParams := ctx.Request.URL.Query()

	term := qParams.Get(termParamName)

	var gender []string
	if qParams.Get(genderParamName) != "" {
		gender = strings.Split(qParams.Get(genderParamName), ",")
	}

	size := defaultSize
	if qParams.Get(sizeParamName) != "" {
		size, _ = strconv.Atoi(qParams.Get(sizeParamName))
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	var suggestions []*suggester.Suggestion

	startTime := time.NowInMilliseconds()
	store := suggester.NewStore(storeID, esClient)

	if term != "" {
		suggestions, err = store.GetWithPrefix(ctx, term, size, gender)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
			return
		}
	} else {
		// suggest even if term is empty
		suggestions, err = store.GetWithoutPrefix(ctx, size, gender)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
			return
		}
	}

	// build response
	response := suggester.NewResponse()
	response.WithID()
	for _, item := range suggestions {
		itemBytes, err := json.Marshal(item)
		if err != nil {
			log.Error(err)
			continue
		}
		response.Suggestions = append(response.Suggestions, json.RawMessage(itemBytes))
	}
	response.Took = time.NowInMilliseconds() - startTime
	response.Total = int64(len(suggestions))

	ctx.Writer.Header().Set("Cache-Control", "private, max-age=43200")
	ctx.JSON(http.StatusOK, response)
}
