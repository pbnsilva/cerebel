package main

import (
	"github.com/petard/cerebel/services/dashboard/pkg"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/log"
)

func main() {
	cfg, err := shared.NewDashboardConfig()
	if err != nil {
		log.Fatal(err)
	}

	svc, err := pkg.NewDashboard(cfg)
	if err != nil {
		log.Fatal(err)
	}

	if err := svc.Run(); err != nil {
		log.Fatal(err)
	}
}
