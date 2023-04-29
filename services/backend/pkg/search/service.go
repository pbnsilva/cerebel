package search

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/shared/events"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/object"
	"github.com/petard/cerebel/shared/ontology"
	"github.com/petard/cerebel/shared/stats"
)

const (
	refreshInterval           = 10 * time.Minute
	vectorindicesObjectPrefix = "vectorindices/"
	nlpObjectPrefix           = "models/nlp/"

	// TODO this should not be here
	ontologyVersion = "20181205_165732"
)

// Service exposes search operations on products.
type Service struct {
	cfg         *service.Config
	eventLogger *events.Logger

	objectStore object.Storer
	statsStore  *stats.Store

	ontGraph *ontology.Graph
}

// NewService returns a new instance of Service.
func NewService(cfg *service.Config, eventLogger *events.Logger) (*Service, error) {
	statsStore, err := stats.NewStore(cfg.GetRedisHost())
	if err != nil {
		return nil, err
	}

	s := &Service{
		cfg:         cfg,
		eventLogger: eventLogger,
		objectStore: object.NewStore(cfg),
		statsStore:  statsStore,
	}

	if err := s.fetchAndLoadOntology(); err != nil {
		return nil, err
	}

	if err := s.updateAnnoyStores(); err != nil {
		if err == object.ErrNotExist {
			log.Error(err)
		} else {
			return nil, err
		}
	}

	ticker := time.NewTicker(refreshInterval)
	go func() {
		for _ = range ticker.C {
			if err := s.updateAnnoyStores(); err != nil {
				log.Error(err)
				continue
			}
		}
	}()

	return s, nil
}

func (s *Service) SetRoutes(engine *gin.Engine) {
	s.rootHandlers(engine.Group("/"))
	s.v2Handlers(engine.Group("/v2"))
	s.v3Handlers(engine.Group("/v3"))
}

func (s *Service) makeIndexID(accountID, storeID string) string {
	return fmt.Sprintf("%s_%s", accountID, storeID)
}

func (s *Service) fetchAndLoadOntology() error {
	ctx := context.TODO()

	path := fmt.Sprintf("%sfashion_%s.owl", nlpObjectPrefix, ontologyVersion)
	reader, err := s.objectStore.Get(ctx, path)
	if err != nil {
		return err
	}

	bytes, err := ioutil.ReadAll(reader)
	if err != nil {
		return err
	}

	nlpPath := filepath.Join(s.cfg.GetDataPath(), nlpObjectPrefix)
	if _, err := os.Stat(nlpPath); os.IsNotExist(err) {
		os.MkdirAll(nlpPath, 0755)
	}

	if err := ioutil.WriteFile(filepath.Join(s.cfg.GetDataPath(), path), bytes, 0644); err != nil {
		return err
	}

	graph, err := ontology.NewGraph(filepath.Join(s.cfg.GetDataPath(), path))
	if err != nil {
		return err
	}

	s.ontGraph = graph

	return nil
}
