package main

import (
	"log"

	"github.com/petard/cerebel/jobs/statsupdater/pkg"
)

func main() {
	cfg, err := pkg.NewStatsUpdaterJobConfig()
	if err != nil {
		log.Fatal(err)
	}

	statsUpdater, err := pkg.NewStatsUpdater(cfg)
	if err != nil {
		log.Fatal(err)
	}

	if err = statsUpdater.Run(); err != nil {
		log.Fatal(err)
	}
}
