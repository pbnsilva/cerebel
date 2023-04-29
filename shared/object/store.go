package object

import (
	"context"
	"errors"
	"io"

	"github.com/petard/cerebel/shared/config"
)

var (
	ErrNotExist = errors.New("Object does not exist")
)

type Storer interface {
	Get(context.Context, string) (io.Reader, error)
	Put(context.Context, io.Reader, string) error
}

func NewStore(cfg config.Configer) Storer {
	if cfg.IsProductionEnvironment() {
		return NewGCSStore(cfg.GetGCSBucket())
	}
	return NewLocalStore(cfg.GetDataPath())
}
