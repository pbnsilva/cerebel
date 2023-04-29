package auth

import (
	"context"
	"errors"
	"sync"
	"time"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/metadata"
)

const (
	refreshInterval = 15 * time.Second
)

var (
	errStoreIDAlreadyExists = errors.New("StoreID already exists")
	errEmptyTokenParam      = errors.New("Token parameter is empty")
	errEmptyStoreIDParam    = errors.New("StoreID parameter is empty")
	errUnauthorized         = errors.New("Unauthorized")
)

type Store struct {
	esHost        string
	readTokenMap  map[string]string
	adminTokenMap map[string]string
	storeIDset    map[string]struct{}
	mu            *sync.RWMutex
}

func NewStore(esHost string) (*Store, error) {
	authStore := &Store{
		esHost:        esHost,
		readTokenMap:  map[string]string{},
		adminTokenMap: map[string]string{},
		storeIDset:    map[string]struct{}{},
		mu:            &sync.RWMutex{},
	}

	if err := authStore.Refresh(); err != nil {
		return nil, err
	}

	// schedule refreshes
	ticker := time.NewTicker(refreshInterval)
	go func(store *Store) {
		for _ = range ticker.C {
			if err := store.Refresh(); err != nil {
				log.Error(err)
				continue
			}
		}
	}(authStore)

	return authStore, nil
}

func (s *Store) Refresh() error {
	// connect to metadata store
	client, err := es.NewSimpleClient(s.esHost)
	if err != nil {
		//TODO: proper logging
		return err
	}

	ctx := context.Background()

	metadataStore := metadata.NewStore(client)
	items, err := metadataStore.GetAll(ctx)
	if err != nil {
		e, ok := err.(*elastic.Error)
		if !ok {
			return err
		}

		// index might be created later
		// TODO is it a good idea to hide this ? resource initialization should be done somehere else?
		if e.Status == 404 {
			log.Error(err)
			return nil
		}

		return err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	// update maps
	s.readTokenMap = map[string]string{}
	s.adminTokenMap = map[string]string{}
	s.storeIDset = map[string]struct{}{}
	for _, item := range items {
		s.readTokenMap[item.AdminToken] = item.StoreID
		s.adminTokenMap[item.AdminToken] = item.StoreID
		s.storeIDset[item.StoreID] = struct{}{}
		for _, readToken := range item.ReadTokens {
			s.readTokenMap[readToken] = item.StoreID
		}
	}

	return nil
}

func (s *Store) AuthRead(storeID, token string) error {
	if token == "" {
		return errEmptyTokenParam
	}

	if storeID == "" {
		return errEmptyStoreIDParam
	}

	s.mu.RLock()
	defer s.mu.RUnlock()

	matchedStoreID, found := s.readTokenMap[token]
	if !found {
		return errUnauthorized
	}

	if matchedStoreID != storeID {
		return errUnauthorized
	}

	return nil
}

func (s *Store) AuthAdmin(storeID, token string) error {
	if token == "" {
		return errEmptyTokenParam
	}

	if storeID == "" {
		return errEmptyStoreIDParam
	}

	s.mu.RLock()
	defer s.mu.RUnlock()

	matchedStoreID, found := s.adminTokenMap[token]
	if !found {
		return errUnauthorized
	}

	if matchedStoreID != storeID {
		return errUnauthorized
	}

	return nil
}
