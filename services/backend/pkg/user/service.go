package user

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	shared_service "github.com/petard/cerebel/shared/service"
	shared_time "github.com/petard/cerebel/shared/time"
	shared_user "github.com/petard/cerebel/shared/user"
)

const (
	userIDParamName    = "userID"
	productIDParamName = "productID"
)

type Service struct {
	cfg *service.Config
}

func NewService(cfg *service.Config) (*Service, error) {
	return &Service{
		cfg: cfg,
	}, nil
}

func (s *Service) SetRoutes(engine *gin.Engine) {
	v3Group := engine.Group("/v3")
	{
		v3Group.GET(fmt.Sprintf("/store/:%s/user/:%s", shared_service.AuthStoreIDContextParam, userIDParamName), s.getUser)
		v3Group.DELETE(fmt.Sprintf("/store/:%s/user/:%s", shared_service.AuthStoreIDContextParam, userIDParamName), s.deleteUser)
		v3Group.PUT(fmt.Sprintf("/store/:%s/user/:%s", shared_service.AuthStoreIDContextParam, userIDParamName), s.putUser)
	}
}

func (s *Service) getUser(ctx *gin.Context) {
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	userID := ctx.Params.ByName(userIDParamName)
	if userID == "" {
		ctx.JSON(http.StatusBadRequest, shared_service.NewErrorResponse(shared_service.ErrBadRequest.Error()))
		return
	}

	userStore := shared_user.NewStore(esClient)
	userItem, err := userStore.Get(ctx, userID)
	if err != nil {
		if err == shared_user.ErrUserNotFound {
			ctx.JSON(http.StatusNotFound, shared_service.NewErrorResponse("User not found"))
			return
		}
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
	}

	startTime := shared_time.NowInMilliseconds()
	response := shared_user.NewResponse()
	response.WithID()

	itemBytes, err := json.Marshal(userItem)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	response.User = itemBytes
	response.Took = shared_time.NowInMilliseconds() - startTime
	response.Total = 1

	ctx.JSON(http.StatusOK, response)
}

func (s *Service) deleteUser(ctx *gin.Context) {
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	userID := ctx.Params.ByName(userIDParamName)
	if userID == "" {
		ctx.JSON(http.StatusBadRequest, shared_service.NewErrorResponse(shared_service.ErrBadRequest.Error()))
		return
	}

	userStore := shared_user.NewStore(esClient)
	if err := userStore.Delete(ctx, userID); err != nil {
		if err == shared_user.ErrUserNotFound {
			ctx.JSON(http.StatusNotFound, shared_service.NewErrorResponse("User not found"))
			return
		}
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
	}

	ctx.JSON(http.StatusOK, shared_service.NewOKResponse())
}

func (s *Service) putUser(ctx *gin.Context) {
	request := &shared_user.Item{}
	if err := ctx.MustBindWith(request, binding.JSON); err != nil {
		ctx.JSON(http.StatusBadRequest, shared_service.NewErrorResponse(err.Error()))
		return
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	userID := ctx.Params.ByName(userIDParamName)
	if userID == "" {
		ctx.JSON(http.StatusBadRequest, shared_service.NewErrorResponse(shared_service.ErrBadRequest.Error()))
		return
	}

	userStore := shared_user.NewStore(esClient)
	userItem, err := userStore.Get(ctx, userID)
	if err != nil {
		if err != shared_user.ErrUserNotFound {
			ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
			return
		}
	}

	if userItem == nil {
		userItem = request
		userItem.ID = userID
		userItem.CreationDate = time.Now()
	} else {
		if request.OS != "" {
			userItem.OS = request.OS
		}

		if request.FCMToken != "" {
			userItem.FCMToken = request.FCMToken
		}

		if request.LastNotificationDate != nil {
			userItem.LastNotificationDate = request.LastNotificationDate
		}
	}

	if err := userStore.Put(ctx, userItem); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, shared_service.NewErrorResponse(err.Error()))
		return
	}

	ctx.JSON(http.StatusOK, shared_service.NewOKResponse())
}
