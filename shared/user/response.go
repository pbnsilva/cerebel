package user

import (
	"encoding/json"

	"github.com/petard/cerebel/shared/service"
)

type Response struct {
	*service.BaseResponse

	User json.RawMessage `json:"user"`

	Took  int64 `json:"took"`
	Total int64 `json:"total"`
}

func NewResponse() *Response {
	userResponse := &Response{
		BaseResponse: service.NewOKResponse(),
		User:         json.RawMessage{},
	}
	return userResponse
}
