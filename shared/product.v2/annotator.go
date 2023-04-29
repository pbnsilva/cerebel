package product

import (
	"strconv"

	"github.com/petard/cerebel/shared/annotation"
	pb "github.com/petard/cerebel/shared/rpc/annotation"
)

const (
	hasParentRelationLabel = "has_parent"
	categoryType           = "category"
)

type Annotator struct {
	annotationClient *annotation.Client
}

func NewAnnotator(annotationClient *annotation.Client) *Annotator {
	return &Annotator{annotationClient}
}

func (an *Annotator) BatchAnnotate(items []*Item) error {
	allFieldStrings := []string{}
	itemFields := [][]int{}
	for _, item := range items {
		fieldStrings := an.getFieldStringsForItem(item)
		fieldIdxs := []int{}
		for _, str := range fieldStrings {
			fieldIdxs = append(fieldIdxs, len(allFieldStrings))
			allFieldStrings = append(allFieldStrings, str)
		}
		itemFields = append(itemFields, fieldIdxs)
	}

	features := []*pb.TextFeature{
		&pb.TextFeature{Type: pb.TextFeature_ENTITY_PREDICTION},
	}

	annotationResponse, err := an.annotationClient.BatchAnnotateTexts(allFieldStrings, features)
	if err != nil {
		return err
	}

	for i, item := range items {
		labels := map[string][]string{}
		ents := map[string]struct{}{}
		for _, j := range itemFields[i] {
			response := annotationResponse.Responses[j]
			for _, entAn := range response.EntityAnnotations {
				// no duplicates
				if _, ok := ents[entAn.Label]; ok {
					continue
				}
				labels[entAn.Cls] = append(labels[entAn.Cls], entAn.Label)
				ents[entAn.Label] = struct{}{}

				// TODO this is too hacky!
				if entAn.Relations != nil {
					for _, rel := range entAn.Relations {
						if rel.Name == hasParentRelationLabel {
							labels[categoryType] = append(labels[categoryType], rel.Target)
						}
					}
				}
			}
		}
		for k, v := range labels {
			item.SetAnnotation(k, v)

			// TODO color_count is used to improve ranking
			// figure out a better way to generate this field
			if k == "color" {
				item.SetAnnotation("color_count", []string{strconv.Itoa(len(v))})
			}
		}
	}

	return nil
}

func (an *Annotator) getFieldStringsForItem(item *Item) []string {
	vals := []string{
		item.Source.Name,
		item.Source.Brand,
	}
	vals = append(vals, item.Source.Gender...)
	vals = append(vals, item.Source.Categories...)
	return vals
}
