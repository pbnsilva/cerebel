package object

import (
	"context"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
)

type LocalStore struct {
	dir string
}

func NewLocalStore(dir string) *LocalStore {
	return &LocalStore{dir}
}

func (s *LocalStore) Get(ctx context.Context, path string) (io.Reader, error) {
	fpath := filepath.Join(s.dir, path)
	if _, err := os.Stat(fpath); os.IsNotExist(err) {
		return nil, ErrNotExist
	}
	return os.Open(fpath)
}

func (s *LocalStore) Put(ctx context.Context, data io.Reader, path string) error {
	dir := filepath.Dir(filepath.Join(s.dir, path))
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		err = os.MkdirAll(dir, 0755)
		if err != nil {
			return err
		}
	}

	file, err := os.Create(filepath.Join(s.dir, path))
	if err != nil {
		return err
	}

	bytes, err := ioutil.ReadAll(data)
	if err != nil {
		return err
	}

	if _, err := file.Write(bytes); err != nil {
		return err
	}

	return nil
}
