package search

import (
	"errors"

	"github.com/petard/cerebel/shared/annotation"
	pb "github.com/petard/cerebel/shared/rpc/annotation"
)

var (
	errNoAnnotations = errors.New("No annotations were possible")
)

type TextRequestAnnotator struct {
	annotationClient *annotation.Client
}

func NewTextRequestAnnotator(annotationClient *annotation.Client) *TextRequestAnnotator {
	return &TextRequestAnnotator{annotationClient}
}

func (an *TextRequestAnnotator) Annotate(request *TextRequest) (*AnnotatedTextRequest, error) {
	features := []*pb.TextFeature{
		&pb.TextFeature{Type: pb.TextFeature_ENTITY_PREDICTION},
		&pb.TextFeature{Type: pb.TextFeature_PRICE_RANGE_DETECTION},
	}
	annotationResponse, err := an.annotationClient.BatchAnnotateTexts([]string{request.GetQuery()}, features)
	if err != nil {
		return nil, err
	}

	if len(annotationResponse.Responses) == 0 {
		return nil, errNoAnnotations
	}

	response := annotationResponse.Responses[0]
	annotatedRequest := NewAnnotatedTextRequest(request)
	entityAnnotations := response.EntityAnnotations
	for _, entAn := range entityAnnotations {
		annotatedRequest.AddAnnotation(&TextRequestAnnotation{
			ID:       entAn.Id,
			Type:     entAn.Cls,
			Value:    entAn.Label,
			Start:    entAn.Start,
			End:      entAn.End,
			Original: entAn.Original,
		})
	}

	if len(entityAnnotations) > 0 {
		annotatedRequest.Intent = IntentSearch
	}

	if response.PriceRangeAnnotation != nil {
		priceAnnotation := &PriceRangeAnnotation{Currency: response.PriceRangeAnnotation.Currency}
		for _, an := range response.PriceRangeAnnotation.RangeAnnotations {
			if an.Operator == pb.RangeAnnotation_GTE {
				priceAnnotation.Gte = an.Value
			} else if an.Operator == pb.RangeAnnotation_LTE {
				priceAnnotation.Lte = an.Value
			} else if an.Operator == pb.RangeAnnotation_EQ {
				priceAnnotation.Eq = an.Value
			}
		}
		annotatedRequest.PriceRange = priceAnnotation
	}

	return annotatedRequest, nil
}
