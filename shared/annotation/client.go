package annotation

import (
	"context"

	pb "github.com/petard/cerebel/shared/rpc/annotation"
	"google.golang.org/grpc"
)

// Client is a thin wrapper over the gRPC client for the Annotation service
type Client struct {
	host string
}

// NewClient returns a new instance of annotation client.
func NewClient(host string) (*Client, error) {
	return &Client{host}, nil
}

func (c *Client) BatchAnnotateImagesFromBytes(images [][]byte, features []*pb.ImageFeature) (*pb.BatchAnnotateImagesResponse, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	requests := []*pb.AnnotateImageRequest{}
	for _, img := range images {
		requests = append(requests, &pb.AnnotateImageRequest{
			Image: &pb.Image{
				Content: img,
			},
			Features: features,
		})
	}

	client := pb.NewAnnotatorClient(conn)
	resp, err := client.BatchAnnotateImages(context.Background(), &pb.BatchAnnotateImagesRequest{requests})
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (c *Client) BatchAnnotateImagesFromURLs(urls []string, features []*pb.ImageFeature) (*pb.BatchAnnotateImagesResponse, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	requests := []*pb.AnnotateImageRequest{}
	for _, url := range urls {
		requests = append(requests, &pb.AnnotateImageRequest{
			Image: &pb.Image{
				Source: &pb.ImageSource{ImageUrl: url},
			},
			Features: features,
		})
	}

	client := pb.NewAnnotatorClient(conn)
	resp, err := client.BatchAnnotateImages(context.Background(), &pb.BatchAnnotateImagesRequest{requests})
	if err != nil {
		return nil, err
	}

	return resp, nil
}

// GetFeatureVectors returns image encodings for a set of images.
func (c *Client) GetFeatureVectorsFromBytes(images [][]byte) (*pb.BatchAnnotateImagesResponse, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	requests := []*pb.AnnotateImageRequest{}
	for _, img := range images {
		requests = append(requests, &pb.AnnotateImageRequest{
			Image: &pb.Image{
				Content: img,
			},
			Features: []*pb.ImageFeature{
				&pb.ImageFeature{
					Type: pb.ImageFeature_FEATURE_VECTOR,
				},
			},
		})
	}

	client := pb.NewAnnotatorClient(conn)
	resp, err := client.BatchAnnotateImages(context.Background(), &pb.BatchAnnotateImagesRequest{requests})
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (c *Client) GetFeatureVectorsFromURLs(imageURLs []string) (*pb.BatchAnnotateImagesResponse, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	requests := []*pb.AnnotateImageRequest{}
	for _, url := range imageURLs {
		requests = append(requests, &pb.AnnotateImageRequest{
			Image: &pb.Image{
				Source: &pb.ImageSource{
					ImageUrl: url,
				},
			},
			Features: []*pb.ImageFeature{
				&pb.ImageFeature{
					Type: pb.ImageFeature_FEATURE_VECTOR,
				},
			},
		})
	}

	client := pb.NewAnnotatorClient(conn)
	resp, err := client.BatchAnnotateImages(context.Background(), &pb.BatchAnnotateImagesRequest{requests})
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (c *Client) BatchAnnotateTexts(texts []string, features []*pb.TextFeature) (*pb.BatchAnnotateTextsResponse, error) {
	conn, err := grpc.Dial(c.host, grpc.WithInsecure())
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	requests := []*pb.AnnotateTextRequest{}
	for _, text := range texts {
		requests = append(requests, &pb.AnnotateTextRequest{
			Text:     text,
			Features: features,
		})
	}

	client := pb.NewAnnotatorClient(conn)
	resp, err := client.BatchAnnotateTexts(context.Background(), &pb.BatchAnnotateTextsRequest{requests})
	if err != nil {
		return nil, err
	}

	return resp, nil
}
