package service

import (
	"errors"
	"fmt"

	"github.com/petard/cerebel/shared/rand"
)

var (
	ErrBadRequest          = errors.New("Bad request.")
	ErrUnauthorizedRequest = errors.New("Unauthorized request.")
)

type BaseResponse struct {
	ID     string `json:"id,omitempty"`
	Status string `json:"status,omitempty"`
	Took   int64  `json:"took"`
}

func (r *BaseResponse) WithID() *BaseResponse {
	r.ID = rand.StringBytes(10)
	return r
}

type ErrorResponse struct {
	*BaseResponse

	Message string `json:"message,omitempty"`
}

func NewOKResponse() *BaseResponse {
	return &BaseResponse{Status: "ok"}
}

func NewBasicErrorResponse() *ErrorResponse {
	return &ErrorResponse{
		BaseResponse: &BaseResponse{Status: "error"},
	}
}

func NewErrorResponse(format string, a ...interface{}) *ErrorResponse {
	r := NewBasicErrorResponse()
	r.Message = fmt.Sprintf(format, a...)
	return r
}
