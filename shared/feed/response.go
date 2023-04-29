package feed

import (
	"encoding/json"

	"github.com/petard/cerebel/shared/service"
)

type Response struct {
	*service.BaseResponse

	Records []json.RawMessage `json:"records"`

	Took  int64 `json:"took"`
	Total int64 `json:"total"`
}

func NewResponse() *Response {
	feedResponse := &Response{
		BaseResponse: service.NewOKResponse(),
		Records:      []json.RawMessage{},
	}
	return feedResponse
}
