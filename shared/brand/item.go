package brand

import (
	"crypto/sha1"
	"encoding/json"
	"fmt"

	"github.com/petard/cerebel/shared/es"
)

type Item struct {
	ID              string              `json:"id"`
	URL             string              `json:"url,omitempty"`
	Name            string              `json:"name,omitempty"`
	Description     string              `json:"description,omitempty"`
	Tags            []string            `json:"tags,omitempty"`
	Location        string              `json:"location,omitempty"`
	Shops           []*Shop             `json:"stores,omitempty"` // TODO naming conflict
	PriceRange      string              `json:"price_range,omitempty"`
	PopularProducts json.RawMessage     `json:"popular_products,omitempty"`
	Categories      []*CategoryProducts `json:"categories,omitempty"`
}

type CategoryProducts struct {
	Name     string          `json:"name,omitempty"`
	Products json.RawMessage `json:"products,omitempty"`
}

type Shop struct {
	Name       string       `json:"name"`
	Country    string       `json:"country"`
	City       string       `json:"city"`
	PostalCode string       `json:"postal_code"`
	Location   *es.Location `json:"location"`
	Address    string       `json:"address"`
}

func IDFromName(name string) string {
	h := sha1.New()
	h.Write([]byte(name))
	bs := h.Sum(nil)
	return fmt.Sprintf("%x", bs)
}
