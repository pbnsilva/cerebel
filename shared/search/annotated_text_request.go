package search

type TextRequestAnnotation struct {
	ID       string `json:"id,omitempty"`
	Type     string `json:"type"`
	Value    string `json:"value"`
	Start    int32  `json:"start"`
	End      int32  `json:"end"`
	Original string `json:"original"`
}

type PriceRangeAnnotation struct {
	Currency string `json:"currency"`
	Gte      int32  `json:"gte,omitempty"`
	Lte      int32  `json:"lte,omitempty"`
	Eq       int32  `json:"eq,omitempty"`
}

type AnnotatedTextRequest struct {
	*TextRequest
	Intent          string                              `json:"intent,omitempty"`
	Annotations     map[string][]*TextRequestAnnotation `json:"annotations,omitempty"`
	PriceRange      *PriceRangeAnnotation               `json:"price_range,omitempty"`
	QueryExpansions map[string][]string
}

func NewAnnotatedTextRequest(baseRequest *TextRequest) *AnnotatedTextRequest {
	return &AnnotatedTextRequest{
		TextRequest: baseRequest,
		Annotations: make(map[string][]*TextRequestAnnotation),
	}
}

func (req *AnnotatedTextRequest) GetIntent() string {
	return req.Intent
}

func (req *AnnotatedTextRequest) AddAnnotation(annotation *TextRequestAnnotation) {
	req.Annotations[annotation.Type] = append(req.Annotations[annotation.Type], annotation)
}
