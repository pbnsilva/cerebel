package pkg

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/backend/pkg/brand"
	"github.com/petard/cerebel/services/backend/pkg/feed"
	"github.com/petard/cerebel/services/backend/pkg/search"
	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/services/backend/pkg/user"
	"github.com/petard/cerebel/shared/auth"
	"github.com/petard/cerebel/shared/events"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/monitoring"
	shared_service "github.com/petard/cerebel/shared/service"
)

type BackendHTTPService struct {
	cfg         *service.Config
	authStore   *auth.Store
	eventLogger *events.Logger
	ginEngine   *gin.Engine

	searchSvc *search.Service
	userSvc   *user.Service
	feedSvc   *feed.HTTPService
	brandSvc  *brand.Service
}

func NewBackendHTTPService(cfg *service.Config, authStore *auth.Store, eventLogger *events.Logger) (*BackendHTTPService, error) {
	if cfg.IsProductionEnvironment() {
		gin.SetMode(gin.ReleaseMode)
	}

	searchSvc, err := search.NewService(cfg, eventLogger)
	if err != nil {
		return nil, err
	}

	userSvc, err := user.NewService(cfg)
	if err != nil {
		return nil, err
	}

	feedSvc, err := feed.NewHTTPService(cfg)
	if err != nil {
		return nil, err
	}

	brandSvc, err := brand.NewService(cfg)
	if err != nil {
		return nil, err
	}

	svc := &BackendHTTPService{
		cfg:         cfg,
		authStore:   authStore,
		eventLogger: eventLogger,
		ginEngine:   gin.New(),

		searchSvc: searchSvc,
		userSvc:   userSvc,
		feedSvc:   feedSvc,
		brandSvc:  brandSvc,
	}

	return svc, nil
}

func (s *BackendHTTPService) Run() error {
	s.ginEngine.Use(
		gin.Recovery(),
		shared_service.ReadAuthMiddleware(s.authStore),
	)

	s.searchSvc.SetRoutes(s.ginEngine)
	s.userSvc.SetRoutes(s.ginEngine)
	s.feedSvc.SetRoutes(s.ginEngine)
	s.brandSvc.SetRoutes(s.ginEngine)

	s.ginEngine.GET("/", s.healthCheck)
	s.ginEngine.GET("/health_check", s.healthCheck)

	// metrics endpoint
	monitoring.StartPrometheus(s.cfg.GetPrometheusPort())

	address := fmt.Sprintf(":%d", s.cfg.GetHTTPPort())
	log.Info("Listening and serving.", "address", address, "env", s.cfg.GetEnvironment())

	return s.ginEngine.Run(address)
}

func (s *BackendHTTPService) healthCheck(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{"health_check": "ok"})
}
