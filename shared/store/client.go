package store

import (
	"context"

	"github.com/petard/cerebel/shared/auth"
	product "github.com/petard/cerebel/shared/product.v3"
	pb "github.com/petard/cerebel/shared/rpc/store"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

type Client struct {
	host string
}

func NewClient(host string) (*Client, error) {
	return &Client{host}, nil
}

func (c *Client) Create(storeID string) (*auth.Tokens, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	req := &pb.CreateRequest{
		StoreId: storeID,
	}

	client := pb.NewProductStoreClient(conn)
	resp, err := client.Create(context.Background(), req)
	if err != nil {
		return nil, err
	}

	tokensResponse := &auth.Tokens{
		ReadTokens: resp.Tokens.ReadTokens,
		AdminToken: resp.Tokens.AdminToken,
	}

	return tokensResponse, nil
}

func (c *Client) Delete(storeID, adminToken string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	// authorize request
	md := metadata.Pairs("X-Cerebel-Token", adminToken)
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	client := pb.NewProductStoreClient(conn)
	_, err = client.Delete(ctx, &pb.DeleteRequest{storeID})
	if err != nil {
		return err
	}

	return nil
}

func (c *Client) BulkGetItemsByID(ids []string, storeID, readToken string) ([]*product.Item, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	// authorize request
	md := metadata.Pairs("X-Cerebel-Token", readToken)
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	client := pb.NewProductStoreClient(conn)
	resp, err := client.BulkGetItemsByID(ctx, &pb.BulkGetItemsByIDRequest{storeID, ids})
	if err != nil {
		return nil, err
	}

	items := []*product.Item{}
	for _, item := range resp.Items {
		items = append(items, &product.Item{
			ID: item.Id,
		})
	}

	return items, nil
}

func (c *Client) BulkUpsertItems(items []*product.Item, storeID, adminToken string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	// authorize request
	md := metadata.Pairs("X-Cerebel-Token", adminToken)
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	pbItems := []*pb.Item{}
	for _, item := range items {
		pbItems = append(pbItems, item.ToProto())
	}

	client := pb.NewProductStoreClient(conn)
	if _, err = client.BulkUpsertItems(ctx, &pb.BulkUpsertItemsRequest{storeID, pbItems}); err != nil {
		return err
	}

	return nil
}

func (c *Client) BulkDeleteItemsByID(ids []string, storeID, adminToken string) error {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return err
	}
	defer conn.Close()

	// authorize request
	md := metadata.Pairs("X-Cerebel-Token", adminToken)
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	client := pb.NewProductStoreClient(conn)
	if _, err = client.BulkDeleteItemsByID(ctx, &pb.BulkDeleteItemsByIDRequest{storeID, ids}); err != nil {
		return err
	}

	return nil
}

func (c *Client) GenerateReadToken(storeID, adminToken string) (string, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return "", err
	}
	defer conn.Close()

	// authorize request
	md := metadata.Pairs("X-Cerebel-Token", adminToken)
	ctx := metadata.NewOutgoingContext(context.Background(), md)

	client := pb.NewProductStoreClient(conn)
	resp, err := client.GenerateReadToken(ctx, &pb.GenerateReadTokenRequest{storeID})
	if err != nil {
		return "", err
	}

	return resp.ReadToken, nil
}
