package store

import (
	"context"
	"fmt"
	"io"
	"strings"

	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/shared/auth"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/metadata"
	product "github.com/petard/cerebel/shared/product.v3"
	pb "github.com/petard/cerebel/shared/rpc/store"
	shared_service "github.com/petard/cerebel/shared/service"
	elastic "gopkg.in/olivere/elastic.v5"
	validator "gopkg.in/validator.v2"
)

const (
	invalidCharacters = " \"*\\<|,>/?"
)

var (
	errInvalidStoreID = fmt.Errorf("Invalid store ID. Must not contain the following characters: '%s'", invalidCharacters)
)

type Service struct {
	cfg       *service.Config
	authStore *auth.Store
}

func NewService(cfg *service.Config, authStore *auth.Store) (*Service, error) {
	svc := &Service{
		cfg:       cfg,
		authStore: authStore,
	}

	if err := svc.initializeStoreMetadata(); err != nil {
		return nil, err
	}

	return svc, nil
}

func (s *Service) initializeStoreMetadata() error {
	client, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return err
	}

	// TODO must check for errors, other than index already exists
	if err := metadata.NewStore(client).Create(context.Background()); err == nil {
		log.Info("Initialized metadata store")
	}

	return nil
}

// GenerateReadToken creates a new read token for a given store.
func (s *Service) GenerateReadToken(ctx context.Context, request *pb.GenerateReadTokenRequest) (*pb.GenerateReadTokenResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	// get admin token from context metadata
	token, err := shared_service.GetAuthTokenFromGRPCContext(ctx)
	if err != nil {
		log.Error(err)
		return nil, err
	}

	// usually, this should be handled by the middleware
	// but in this case, different endpoints have different auth requirements
	if err := s.authStore.AuthAdmin(request.StoreId, token); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	metadataStore := metadata.NewStore(esClient)
	item, err := metadataStore.Get(ctx, request.StoreId)
	if err != nil {
		return nil, err
	}

	// update metadata
	newReadToken := auth.GenerateRandomToken()
	item.ReadTokens = append(item.ReadTokens, newReadToken)
	if err := metadataStore.Update(ctx, item); err != nil {
		return nil, err
	}

	return &pb.GenerateReadTokenResponse{newReadToken}, nil
}

func isValidName(value string) bool {
	return !strings.ContainsAny(value, invalidCharacters)
}

// Create creates a new product store.
func (s *Service) Create(ctx context.Context, request *pb.CreateRequest) (*pb.CreateResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	// validate store name
	if !isValidName(request.StoreId) {
		return nil, errInvalidStoreID
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	tokens := auth.GenerateTokens()
	metaItem := &metadata.Item{
		StoreID:    request.StoreId,
		ReadTokens: tokens.ReadTokens,
		AdminToken: tokens.AdminToken,
	}

	metadataStore := metadata.NewStore(esClient)
	if err = metadataStore.Put(ctx, metaItem); err != nil {
		return nil, err
	}

	// create product store
	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return nil, err
	}

	if err := productStore.Create(ctx); err != nil {
		// TODO delete metadata record
		return nil, err
	}

	tokensResponse := &pb.AuthTokens{
		ReadTokens: metaItem.ReadTokens,
		AdminToken: metaItem.AdminToken,
	}

	return &pb.CreateResponse{tokensResponse}, nil
}

// Delete removes a record store.
func (s *Service) Delete(ctx context.Context, request *pb.DeleteRequest) (*pb.DeleteResponse, error) {
	if err := validator.Validate(request); err != nil {
		log.Error(err)
		return nil, err
	}

	// get auth token from context metadata
	token, err := shared_service.GetAuthTokenFromGRPCContext(ctx)
	if err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	// make sure the token can write to this store
	// usually, this should be handled by the middleware
	// but in this case, different endpoints have different auth requirements
	if err := s.authStore.AuthAdmin(request.StoreId, token); err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	// delete store metadata information
	metadataStore := metadata.NewStore(esClient)
	if err := metadataStore.Delete(ctx, request.StoreId); err != nil {
		return nil, err
	}

	// delete product store
	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return nil, err
	}

	if err := productStore.Delete(ctx); err != nil {
		return nil, err
	}

	return &pb.DeleteResponse{}, nil
}

func (s *Service) BulkGetItemsByID(ctx context.Context, request *pb.BulkGetItemsByIDRequest) (*pb.BulkGetItemsByIDResponse, error) {
	if err := validator.Validate(request); err != nil {
		log.Error(err)
		return nil, err
	}

	// get auth token from context metadata
	token, err := shared_service.GetAuthTokenFromGRPCContext(ctx)
	if err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	if err := s.authStore.AuthRead(request.StoreId, token); err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return nil, err
	}

	items, err := productStore.BulkGetItemsByID(ctx, request.Ids)
	if err != nil {
		return nil, err
	}

	itemsResponse := []*pb.Item{}
	for _, item := range items {
		itemsResponse = append(itemsResponse, item.ToProto())
	}

	return &pb.BulkGetItemsByIDResponse{itemsResponse}, nil
}

func (s *Service) BulkUpsertItems(ctx context.Context, request *pb.BulkUpsertItemsRequest) (*pb.BulkUpsertItemsResponse, error) {
	if err := validator.Validate(request); err != nil {
		log.Error(err)
		return nil, err
	}

	// get auth token from context metadata
	token, err := shared_service.GetAuthTokenFromGRPCContext(ctx)
	if err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	if err := s.authStore.AuthAdmin(request.StoreId, token); err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return nil, err
	}

	items := []*product.Item{}
	for _, item := range request.Items {
		items = append(items, product.ItemFromProto(item))
	}

	if err := productStore.BulkUpsertItems(ctx, items); err != nil {
		return nil, err
	}

	return &pb.BulkUpsertItemsResponse{}, nil
}

func (s *Service) BulkDeleteItemsByID(ctx context.Context, request *pb.BulkDeleteItemsByIDRequest) (*pb.BulkDeleteItemsByIDResponse, error) {
	if err := validator.Validate(request); err != nil {
		log.Error(err)
		return nil, err
	}

	// get auth token from context metadata
	token, err := shared_service.GetAuthTokenFromGRPCContext(ctx)
	if err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	if err := s.authStore.AuthAdmin(request.StoreId, token); err != nil {
		log.Error(err, "store_id", request.StoreId)
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return nil, err
	}

	if err := productStore.BulkDeleteItemsByID(ctx, request.Ids); err != nil {
		return nil, err
	}

	return &pb.BulkDeleteItemsByIDResponse{}, nil
}

func (s *Service) ListItems(request *pb.ListItemsRequest, stream pb.ProductStore_ListItemsServer) error {
	ctx := context.TODO()

	if err := validator.Validate(request); err != nil {
		return err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return err
	}

	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return err
	}

	it, err := productStore.Scroll(ctx)
	if err != nil {
		return err
	}

	for {
		items, err := it.Next(ctx)
		if err == io.EOF {
			break
		}

		if err != nil {
			return err
		}

		for _, item := range items {
			if err := stream.Send(item.ToProto()); err != nil {
				return err
			}
		}
	}

	return nil
}

func (s *Service) ListItemsForBrand(request *pb.ListItemsForBrandRequest, stream pb.ProductStore_ListItemsForBrandServer) error {
	ctx := context.TODO()

	if err := validator.Validate(request); err != nil {
		return err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return err
	}

	productStore, err := product.NewESStore(request.StoreId, esClient)
	if err != nil {
		return err
	}

	q := elastic.NewBoolQuery().Filter(elastic.NewTermQuery("brand", request.Brand))
	it, err := productStore.ScrollWithQuery(ctx, q)
	if err != nil {
		return err
	}

	for {
		items, err := it.Next(ctx)
		if err == io.EOF {
			break
		}

		if err != nil {
			return err
		}

		for _, item := range items {
			if err := stream.Send(item.ToProto()); err != nil {
				return err
			}
		}
	}

	return nil
}
