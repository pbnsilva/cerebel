package search

type TextRequest struct {
	*BaseRequest

	Query       string `json:"query,omitempty"`
	ShowGuided  bool   `json:"showGuided"`
	ShowSimilar bool   `json:"showSimilar"`

	// TODO these are write only fields, should be in a different structure
	Endpoint     string `json:"endpoint"`
	MatchesCount int64  `json:"matches_count"`
}

func NewTextRequest() *TextRequest {
	return &TextRequest{
		BaseRequest: &BaseRequest{},
	}
}

func (req *TextRequest) GetQuery() string {
	return req.Query
}

func (req *TextRequest) GetShowGuided() bool {
	return req.ShowGuided
}

func (req *TextRequest) GetShowSimilar() bool {
	return req.ShowSimilar
}
