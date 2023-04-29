package search

type ScrollRequest struct {
	Size   *int `json:"size,omitempty"`
	Offset *int `json:"offset,omitempty"`

	// TODO this is a write only field, should be in a different structure
	Endpoint string `json:"endpoint"`
}

func (req *ScrollRequest) GetSize() int {
	if req.Size == nil {
		return defaultSize
	}
	return *req.Size
}

func (req *ScrollRequest) GetOffset() int {
	if req.Offset == nil {
		return 0
	}
	return *req.Offset
}
