package search

import (
	"github.com/petard/cerebel/shared/es"
	product "github.com/petard/cerebel/shared/product.v3"
)

type TeaserType string

const (
	CategoriesTeaserType TeaserType = "categories"
	BrandsTeaserType     TeaserType = "brands"
	MapTeaserType        TeaserType = "map"
)

type BrandShop struct {
	Brand      string       `json:"brand"`
	Name       string       `json:"name"`
	Country    string       `json:"country"`
	City       string       `json:"city"`
	PostalCode string       `json:"postal_code"`
	Location   *es.Location `json:"location"`
	Address    string       `json:"address"`
}

type TeaserGroup struct {
	Type  TeaserType  `json:"type"`
	Name  string      `json:"name"`
	Items interface{} `json:"items,omitempty"`
	Error string      `json:"error,omitempty"`
}

type Teaser interface {
}

type BrandTeaser struct {
	Title    string          `json:"title"`
	ID       string          `json:"id"`
	Products []*product.Item `json:"products"`
}

type CategoryTeaser struct {
	Title    string `json:"title"`
	ImageURL string `json:"image_url"`
}

type MapTeaser struct {
	Title  string       `json:"title"`
	Stores []*BrandShop `json:"stores"`
}
