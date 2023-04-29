package pkg

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/apps"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/log"
)

type Dashboard struct {
	cfg    *shared.DashboardConfig
	engine *gin.Engine
}

func NewDashboard(cfg *shared.DashboardConfig) (*Dashboard, error) {
	if cfg.IsProductionEnvironment() {
		gin.SetMode(gin.ReleaseMode)
	}

	return &Dashboard{cfg, gin.New()}, nil
}

func (s *Dashboard) Run() error {
	s.engine.Use(
		gin.Recovery(),
	)

	s.engine.LoadHTMLGlob("templates/*")
	s.engine.Static("/js", "./static/js")
	s.engine.Static("/css", "./static/css")
	s.engine.Static("/img", "./static/img")

	authorizer, err := shared.NewAuthorizer(s.cfg)
	if err != nil {
		return err
	}

	apps.NewAuth(s.engine, authorizer, s.cfg)
	apps.NewHome(s.engine, authorizer, s.cfg)
	apps.NewFeedEditor(s.engine, authorizer, s.cfg)
	apps.NewAnalytics(s.engine, authorizer, s.cfg)
	apps.NewPIM(s.engine, authorizer, s.cfg)
	apps.NewSearchDemo(s.engine, authorizer, s.cfg)
	apps.NewImageTagger(s.engine, authorizer, s.cfg)
	apps.NewSearchEval(s.engine, authorizer, s.cfg)
	apps.NewVisionDemo(s.engine, authorizer, s.cfg)
	apps.NewScrapers(s.engine, authorizer, s.cfg)
	apps.NewBrandPages(s.engine, authorizer, s.cfg)
	// apps.NewSuggesterDemo(s.engine, authorizer, s.cfg)

	address := fmt.Sprintf(":%d", s.cfg.GetHTTPPort())
	log.Info("Listening and serving.", "address", address, "env", s.cfg.GetEnvironment())

	return s.engine.Run(address)
}
