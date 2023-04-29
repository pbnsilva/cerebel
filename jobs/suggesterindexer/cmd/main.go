package main

import (
	"log"

	"github.com/petard/cerebel/jobs/suggesterindexer/pkg"
)

func main() {
	cfg, err := pkg.NewIndexerJobConfig()
	if err != nil {
		log.Fatal(err)
	}

	suggesterIndexer := pkg.NewSuggesterIndexer(cfg)
	if err = suggesterIndexer.Run(); err != nil {
		log.Fatal(err)
	}
}
