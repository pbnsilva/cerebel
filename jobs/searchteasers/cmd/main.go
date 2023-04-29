package main

import (
	"log"

	"github.com/petard/cerebel/jobs/searchteasers/pkg"
)

func main() {
	cfg, err := pkg.NewSearchTeasersJobConfig()
	if err != nil {
		log.Fatal(err)
	}

	searchTeasersJob, err := pkg.NewSearchTeasersJob(cfg)
	if err != nil {
		log.Fatal(err)
	}

	if err = searchTeasersJob.Run(); err != nil {
		log.Fatal(err)
	}
}
