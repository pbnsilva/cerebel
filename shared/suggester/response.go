package suggester

import (
	"encoding/json"

	"github.com/petard/cerebel/shared/service"
)

type Response struct {
	*service.BaseResponse

	Suggestions []json.RawMessage `json:"suggestions"`

	Took  int64 `json:"took"`
	Total int64 `json:"total"`
}

func NewResponse() *Response {
	suggesterResponse := &Response{
		BaseResponse: service.NewOKResponse(),
		Suggestions:  []json.RawMessage{},
	}
	return suggesterResponse
}
