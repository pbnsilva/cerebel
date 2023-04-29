package feed

import product "github.com/petard/cerebel/shared/product.v3"

type Item interface {
	GetID() string
	GetCreationDate() uint64
	GetPosition() int
}

type ItemSource struct {
	Name     string `json:"name"`
	Username string `json:"username"`
}

type InstagramItem struct {
	ID        string          `json:"id"`
	Title     string          `json:"title"`
	Date      uint64          `json:"date"`
	ImageURL  string          `json:"image_url"`
	MediaType string          `json:"media_type"`
	Source    *ItemSource     `json:"source"`
	Items     []*product.Item `json:"items"`
	Position  int             `json:"position,omitempty"`
}

type CatalogItem struct {
	ID       string          `json:"id"`
	Title    string          `json:"title"`
	Date     uint64          `json:"date"`
	ImageURL string          `json:"image_url"`
	Source   *ItemSource     `json:"source"`
	Items    []*product.Item `json:"items"`
	Position int             `json:"position,omitempty"`
}

func (item *CatalogItem) GetID() string {
	return item.ID
}

func (item *CatalogItem) GetCreationDate() uint64 {
	return item.Date
}

func (item *CatalogItem) GetPosition() int {
	return item.Position
}

func (item *InstagramItem) GetID() string {
	return item.ID
}

func (item *InstagramItem) GetCreationDate() uint64 {
	return item.Date
}

func (item *InstagramItem) GetPosition() int {
	return item.Position
}
