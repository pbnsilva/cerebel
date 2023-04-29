package main

import (
	"github.com/petard/cerebel/jobs/feedindexer/pkg"
	"github.com/petard/cerebel/shared/log"
)

func main() {
	cfg, err := pkg.NewIndexerJobConfig()
	if err != nil {
		log.Fatal(err)
	}

	feedIndexer := pkg.NewFeedIndexer(cfg)
	if err = feedIndexer.Run(); err != nil {
		log.Fatal(err)
	}
}
