package brand

import (
	"encoding/json"

	"github.com/petard/cerebel/shared/service"
)

type Response struct {
	*service.BaseResponse

	Brand json.RawMessage `json:"brand"`

	Took  int64 `json:"took"`
	Total int64 `json:"total"`
}

func NewResponse() *Response {
	brandResponse := &Response{
		BaseResponse: service.NewOKResponse(),
		Brand:        json.RawMessage{},
	}
	return brandResponse
}
