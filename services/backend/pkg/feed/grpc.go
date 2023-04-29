package feed

import (
	"encoding/json"
	"errors"
	"strings"

	"golang.org/x/net/context"

	validator "gopkg.in/validator.v2"

	"github.com/petard/cerebel/services/backend/pkg/service"
	"github.com/petard/cerebel/shared/es"
	shared_feed "github.com/petard/cerebel/shared/feed"
	"github.com/petard/cerebel/shared/metadata"
	product "github.com/petard/cerebel/shared/product.v3"
	pb "github.com/petard/cerebel/shared/rpc/feed"
)

var (
	errNoItemsFoundInProductStore = errors.New("Items not found in the product store")
)

type GRPCService struct {
	cfg *service.Config
}

func NewGRPCService(cfg *service.Config) (*GRPCService, error) {
	return &GRPCService{cfg}, nil
}

func (s *GRPCService) CreateStore(ctx context.Context, request *pb.CreateStoreRequest) (*pb.CreateStoreResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	store := shared_feed.NewStore(storeID, esClient)
	if err := store.Create(context.TODO()); err != nil {
		return nil, err
	}

	return &pb.CreateStoreResponse{}, nil
}

func (s *GRPCService) DeleteStore(ctx context.Context, request *pb.DeleteStoreRequest) (*pb.DeleteStoreResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	store := shared_feed.NewStore(storeID, esClient)
	if err := store.Delete(context.TODO()); err != nil {
		return nil, err
	}

	return &pb.DeleteStoreResponse{}, nil
}

func (s *GRPCService) GetPage(ctx context.Context, request *pb.GetPageRequest) (*pb.GetPageResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	requestParams := map[string]interface{}{
		"page":   int(request.Nb),
		"size":   int(request.Size),
		"gender": strings.ToLower(pb.GetPageRequest_Gender_name[int32(request.Gender)]),
	}

	store := shared_feed.NewStore(storeID, esClient)
	results, _, err := getFeedItems(ctx, store, nil, requestParams, "")
	if err != nil {
		return nil, err
	}

	resultsBytes, err := json.Marshal(results)
	if err != nil {
		return nil, err
	}

	return &pb.GetPageResponse{Records: resultsBytes}, nil
}

func (s *GRPCService) ListPromotions(ctx context.Context, request *pb.ListPromotionsRequest) (*pb.ListPromotionsResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	store := shared_feed.NewStore(storeID, esClient)
	results, err := store.ListPromotions(ctx)
	if err != nil {
		return nil, err
	}

	if len(results) == 0 {
		return &pb.ListPromotionsResponse{}, nil
	}

	resultsBytes, err := json.Marshal(results)
	if err != nil {
		return nil, err
	}

	return &pb.ListPromotionsResponse{Records: resultsBytes}, nil
}

func (s *GRPCService) SetItems(ctx context.Context, request *pb.SetItemsRequest) (*pb.SetItemsResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	feedStore := shared_feed.NewStore(storeID, esClient)
	feedItem, err := feedStore.Get(ctx, request.Id)
	if err != nil {
		return nil, err
	}

	var items []*product.Item
	if len(request.ItemIds) > 0 {
		productStore, err := product.NewESStore(storeID, esClient)
		if err != nil {
			return nil, err
		}

		items, err = productStore.BulkGetItemsByID(ctx, request.ItemIds)
		if err != nil {
			return nil, err
		}

		if len(items) == 0 {
			return nil, errNoItemsFoundInProductStore
		}
	}

	feedItem.Items = items

	if err := feedStore.Update(ctx, feedItem); err != nil {
		return nil, err
	}

	return &pb.SetItemsResponse{}, nil
}

func (s *GRPCService) DeleteByIDs(ctx context.Context, request *pb.DeleteByIDsRequest) (*pb.DeleteByIDsResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	store := shared_feed.NewStore(storeID, esClient)
	for _, id := range request.Ids {
		if err := store.DeleteByID(ctx, id); err != nil {
			return nil, err
		}
	}

	return &pb.DeleteByIDsResponse{}, nil
}

func (s *GRPCService) AddSource(ctx context.Context, request *pb.Source) (*pb.AddSourceResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	metadataStore := metadata.NewStore(esClient)
	metadataItem, err := metadataStore.Get(ctx, storeID)
	if err != nil {
		return nil, err
	}

	if metadataItem.FeedConfig == nil {
		metadataItem.FeedConfig = &metadata.FeedConfig{
			Sources: []*metadata.FeedSource{},
		}
	}

	metadataItem.FeedConfig.Sources = append(metadataItem.FeedConfig.Sources, &metadata.FeedSource{Type: request.Type, URL: request.Url})

	if err := metadataStore.Update(ctx, metadataItem); err != nil {
		return nil, err
	}

	return &pb.AddSourceResponse{}, nil
}

func (s *GRPCService) DeleteSource(ctx context.Context, request *pb.Source) (*pb.DeleteSourceResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	metadataStore := metadata.NewStore(esClient)
	metadataItem, err := metadataStore.Get(ctx, storeID)
	if err != nil {
		return nil, err
	}

	newSources := []*metadata.FeedSource{}
	for _, source := range metadataItem.FeedConfig.Sources {
		if source.Type == request.Type && source.URL == request.Url {
			continue
		}
		newSources = append(newSources, source)
	}

	metadataItem.FeedConfig.Sources = newSources

	if err := metadataStore.Update(ctx, metadataItem); err != nil {
		return nil, err
	}

	return &pb.DeleteSourceResponse{}, nil
}

func (s *GRPCService) ListSources(ctx context.Context, request *pb.ListSourcesRequest) (*pb.ListSourcesResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	metadataStore := metadata.NewStore(esClient)
	metadataItem, err := metadataStore.Get(ctx, storeID)
	if err != nil {
		return nil, err
	}

	response := []*pb.Source{}
	for _, source := range metadataItem.FeedConfig.Sources {
		response = append(response, &pb.Source{Type: source.Type, Url: source.URL})
	}

	return &pb.ListSourcesResponse{Sources: response}, nil
}

func (s *GRPCService) AddPromotion(ctx context.Context, request *pb.Promotion) (*pb.AddPromotionResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore("faer", esClient)
	if err != nil {
		return nil, err
	}

	productItem, err := productStore.GetItemByID(ctx, request.ProductId)
	if err != nil {
		return nil, err
	}

	productItem.Promotion = request.Name

	item := &shared_feed.InstagramItem{
		ID:       productItem.ID,
		Title:    productItem.Name,
		Date:     productItem.CreatedAt,
		ImageURL: request.ImageUrl,
		Source:   &shared_feed.ItemSource{Name: "instagram", Username: ""},
		Items:    []*product.Item{productItem},
		Position: int(request.Position),
	}

	store := shared_feed.NewStore(storeID, esClient)
	if err := store.InsertPromotion(ctx, item); err != nil {
		return nil, err
	}

	return &pb.AddPromotionResponse{}, nil
}

func (s *GRPCService) DeletePromotion(ctx context.Context, request *pb.Promotion) (*pb.DeletePromotionResponse, error) {
	if err := validator.Validate(request); err != nil {
		return nil, err
	}

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	store := shared_feed.NewStore(storeID, esClient)
	if err := store.DeletePromotion(ctx, request.ProductId); err != nil {
		return nil, err
	}

	return &pb.DeletePromotionResponse{}, nil
}
