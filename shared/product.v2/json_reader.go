package product

import (
	"bufio"
	"io"
)

type JSONReader struct {
	ioReader io.Reader
	scanner  *bufio.Scanner
}

func NewJSONReader(r io.Reader) (*JSONReader, error) {
	return &JSONReader{r, bufio.NewScanner(r)}, nil
}

func (r *JSONReader) Read() bool {
	return r.scanner.Scan()
}

func (r *JSONReader) Item() (*Item, error) {
	item, err := NewItemFromBytes(r.scanner.Bytes())
	if err != nil {
		return nil, err
	}

	if err := r.scanner.Err(); err != nil {
		return nil, err
	}

	return item, nil
}
