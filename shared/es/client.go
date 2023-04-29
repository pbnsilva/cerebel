package es

import (
	elastic "gopkg.in/olivere/elastic.v5"
)

func NewSimpleClient(url string) (*elastic.Client, error) {
	// factory method
	return elastic.NewSimpleClient(
		elastic.SetURL(url),
		// elastic.SetTraceLog(log.New(os.Stderr, "[[ELASTIC]]", 0)),
	)
}

func NewClient(url string) (*elastic.Client, error) {
	// factory method
	// TODO proper configuration
	return elastic.NewClient(
		elastic.SetURL(url),
		elastic.SetSniff(false),
	)
}
