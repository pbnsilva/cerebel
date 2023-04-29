package gcs

import (
	"context"
	"io"
	"os"
	"path/filepath"

	"cloud.google.com/go/storage"
)

func DownloadObject(bucketName, objectName, saveFilePath string) error {
	dirPath := filepath.Dir(saveFilePath)
	if err := os.MkdirAll(dirPath, 0777); err != nil {
		return err
	}

	ctx := context.TODO()

	client, err := storage.NewClient(ctx)
	if err != nil {
		return err
	}

	bucket := client.Bucket(bucketName)
	obj := bucket.Object(objectName)
	reader, err := obj.NewReader(ctx)
	if err != nil {
		return err
	}

	out, err := os.Create(saveFilePath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, reader)
	if err != nil {
		return err
	}

	return nil
}

func UploadObject(bucketName, objectName string, data io.Reader) error {
	return doUploadObject(bucketName, objectName, data, false)
}

func UploadObjectWithPublicRead(bucketName, objectName string, data io.Reader) error {
	return doUploadObject(bucketName, objectName, data, true)
}

func GetAllObjects(bucketName string, query *storage.Query) (*storage.ObjectIterator, error) {
	ctx := context.TODO()

	client, err := storage.NewClient(ctx)
	if err != nil {
		return nil, err
	}

	bucket := client.Bucket(bucketName)

	return bucket.Objects(ctx, query), nil
}

func doUploadObject(bucketName, objectName string, data io.Reader, publicRead bool) error {
	ctx := context.TODO()

	client, err := storage.NewClient(ctx)
	if err != nil {
		return err
	}

	wc := client.Bucket(bucketName).Object(objectName).NewWriter(ctx)

	if publicRead {
		wc.ACL = []storage.ACLRule{{Entity: storage.AllUsers, Role: storage.RoleReader}}
	}

	if _, err := io.Copy(wc, data); err != nil {
		return err
	}

	if err := wc.Close(); err != nil {
		return err
	}

	return nil
}
