package pkg

import (
	"fmt"
	"net"

	"github.com/petard/cerebel/services/backend/pkg/feed"
	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/services/backend/pkg/store"
	"github.com/petard/cerebel/shared/auth"
	"github.com/petard/cerebel/shared/log"
	feed_pb "github.com/petard/cerebel/shared/rpc/feed"
	store_pb "github.com/petard/cerebel/shared/rpc/store"
	"google.golang.org/grpc"
)

type BackendGRPCService struct {
	cfg       *service.Config
	authStore *auth.Store

	storeSvc *store.Service
	feedSvc  *feed.GRPCService
}

func NewBackendGRPCService(cfg *service.Config, authStore *auth.Store) (*BackendGRPCService, error) {
	storeSvc, err := store.NewService(cfg, authStore)
	if err != nil {
		return nil, err
	}

	feedSvc, err := feed.NewGRPCService(cfg)
	if err != nil {
		return nil, err
	}

	svc := &BackendGRPCService{
		cfg:       cfg,
		authStore: authStore,

		storeSvc: storeSvc,
		feedSvc:  feedSvc,
	}

	return svc, nil
}

func (s *BackendGRPCService) Run() error {
	address := fmt.Sprintf(":%d", s.cfg.GetGRPCPort())
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return err
	}

	// TODO use interceptors to do auth
	server := grpc.NewServer()
	store_pb.RegisterProductStoreServer(server, s.storeSvc)
	feed_pb.RegisterFeedServer(server, s.feedSvc)

	log.Info("Listening and serving.", "address", address, "env", s.cfg.GetEnvironment())

	return server.Serve(listener)
}
