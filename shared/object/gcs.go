package object

import (
	"context"
	"io"

	"cloud.google.com/go/storage"
)

type GCSStore struct {
	bucket string
}

func NewGCSStore(bucket string) *GCSStore {
	return &GCSStore{bucket}
}

func (s *GCSStore) Get(ctx context.Context, path string) (io.Reader, error) {
	client, err := storage.NewClient(ctx)
	if err != nil {
		return nil, err
	}

	bucket := client.Bucket(s.bucket)
	obj := bucket.Object(path)
	reader, err := obj.NewReader(ctx)
	if err == storage.ErrObjectNotExist {
		return nil, ErrNotExist
	}

	return reader, err
}

func (s *GCSStore) Put(ctx context.Context, data io.Reader, path string) error {
	client, err := storage.NewClient(ctx)
	if err != nil {
		return err
	}

	wc := client.Bucket(s.bucket).Object(path).NewWriter(ctx)

	if _, err := io.Copy(wc, data); err != nil {
		return err
	}

	if err := wc.Close(); err != nil {
		return err
	}

	return nil
}
