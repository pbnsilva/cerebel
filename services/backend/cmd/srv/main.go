package main

import (
	"log"

	"github.com/petard/cerebel/services/backend/pkg"
	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/shared/auth"
	"github.com/petard/cerebel/shared/events"
)

func main() {
	cfg, err := service.NewConfig()
	if err != nil {
		log.Fatal(err)
	}

	authStore, err := auth.NewStore(cfg.GetElasticHost())
	if err != nil {
		log.Fatal(err)
	}

	eventLogger, err := events.NewLogger()
	if err != nil {
		log.Fatal(err)
	}

	httpSvc, err := pkg.NewBackendHTTPService(cfg, authStore, eventLogger)
	if err != nil {
		log.Fatal(err)
	}

	grpcSvc, err := pkg.NewBackendGRPCService(cfg, authStore)
	if err != nil {
		log.Fatal(err)
	}

	go func() {
		if err := grpcSvc.Run(); err != nil {
			log.Fatal(err)
		}
	}()

	if err := httpSvc.Run(); err != nil {
		log.Fatal(err)
	}
}
