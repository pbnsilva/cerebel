package image

import (
	"errors"

	"github.com/petard/cerebel/shared/annotation"
)

type FeaturesResponse struct {
	Vector []float32
	Error  error
}

type FeaturesExtractor struct {
	annotationClient *annotation.Client
}

func NewFeaturesExtractor(annotationClient *annotation.Client) *FeaturesExtractor {
	return &FeaturesExtractor{annotationClient}
}

func (ex *FeaturesExtractor) GetFeaturesFromBytes(images [][]byte) ([]*FeaturesResponse, error) {
	vectorsResponse, err := ex.annotationClient.GetFeatureVectorsFromBytes(images)
	if err != nil {
		return nil, err
	}

	response := []*FeaturesResponse{}
	for _, resp := range vectorsResponse.Responses {
		if resp.Error != nil {
			if resp.Error.Message != "" {
				response = append(response, &FeaturesResponse{Error: errors.New(resp.Error.Message)})
			}
			continue
		}

		response = append(response, &FeaturesResponse{Vector: resp.FeatureVector.Vector})
	}

	return response, nil
}

func (ex *FeaturesExtractor) GetFeaturesFromURLs(imageURLs []string) ([]*FeaturesResponse, error) {
	vectorsResponse, err := ex.annotationClient.GetFeatureVectorsFromURLs(imageURLs)
	if err != nil {
		return nil, err
	}

	response := []*FeaturesResponse{}
	for _, resp := range vectorsResponse.Responses {
		if resp.Error != nil {
			response = append(response, &FeaturesResponse{Error: errors.New(resp.Error.Message)})
			continue
		}

		response = append(response, &FeaturesResponse{Vector: resp.FeatureVector.Vector})
	}

	return response, nil
}
