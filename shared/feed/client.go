package feed

import (
	"context"
	"strings"

	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/metadata"
	pb "github.com/petard/cerebel/shared/rpc/feed"
	"google.golang.org/grpc"
)

type Client struct {
	host string
}

func NewClient(host string) (*Client, error) {
	return &Client{host}, nil
}

func (c *Client) GetPage(nb, size int32, isLive bool, gender string) ([]byte, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	req := &pb.GetPageRequest{
		Nb:     nb,
		Size:   size,
		Gender: pb.GetPageRequest_Gender(pb.GetPageRequest_Gender_value[strings.ToUpper(gender)]),
	}

	client := pb.NewFeedClient(conn)
	resp, err := client.GetPage(context.Background(), req)
	if err != nil {
		return nil, err
	}

	return resp.Records, nil
}

func (c *Client) ListPromotions() ([]byte, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	client := pb.NewFeedClient(conn)
	resp, err := client.ListPromotions(context.Background(), &pb.ListPromotionsRequest{})
	if err != nil {
		return nil, err
	}

	return resp.Records, nil
}

func (c *Client) SetItems(id string, itemIDs []string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	req := &pb.SetItemsRequest{
		Id:      id,
		ItemIds: itemIDs,
	}

	client := pb.NewFeedClient(conn)
	if _, err := client.SetItems(context.Background(), req); err != nil {
		log.Error(err)
		return err
	}

	return nil
}

func (c *Client) DeleteByIDs(ids []string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	req := &pb.DeleteByIDsRequest{
		Ids: ids,
	}

	client := pb.NewFeedClient(conn)
	if _, err := client.DeleteByIDs(context.Background(), req); err != nil {
		return err
	}

	return nil
}

func (c *Client) ListSources() ([]*metadata.FeedSource, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	client := pb.NewFeedClient(conn)
	resp, err := client.ListSources(context.Background(), &pb.ListSourcesRequest{})
	if err != nil {
		return nil, err
	}

	sources := []*metadata.FeedSource{}
	for _, src := range resp.Sources {
		sources = append(sources, &metadata.FeedSource{Type: src.Type, URL: src.Url})
	}

	return sources, nil
}

func (c *Client) AddSource(srcType, url string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	req := &pb.Source{
		Type: srcType,
		Url:  url,
	}

	client := pb.NewFeedClient(conn)
	if _, err := client.AddSource(context.Background(), req); err != nil {
		log.Error(err)
		return err
	}

	return nil
}

func (c *Client) DeleteSource(srcType, url string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	req := &pb.Source{
		Type: srcType,
		Url:  url,
	}

	client := pb.NewFeedClient(conn)
	if _, err := client.DeleteSource(context.Background(), req); err != nil {
		log.Error(err)
		return err
	}

	return nil
}

func (c *Client) AddPromotion(productID, imageURL string, position int32, name string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	req := &pb.Promotion{
		ProductId: productID,
		ImageUrl:  imageURL,
		Position:  position,
		Name:      name,
	}

	client := pb.NewFeedClient(conn)
	if _, err := client.AddPromotion(context.Background(), req); err != nil {
		log.Error(err)
		return err
	}

	return nil
}

func (c *Client) DeletePromotion(productID string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	req := &pb.Promotion{
		ProductId: productID,
	}

	client := pb.NewFeedClient(conn)
	if _, err := client.DeletePromotion(context.Background(), req); err != nil {
		log.Error(err)
		return err
	}

	return nil
}
