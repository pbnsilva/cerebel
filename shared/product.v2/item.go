package product

import "encoding/json"

type Source struct {
	ID               string   `json:"id,omitempty"`
	Name             string   `json:"name,omitempty"`
	Brand            string   `json:"brand,omitempty"`
	URL              string   `json:"url,omitempty"`
	Gender           []string `json:"gender,omitempty"`
	Description      string   `json:"description,omitempty"`
	ImageURL         []string `json:"image_url,omitempty"`
	Categories       []string `json:"categories,omitempty"`
	Currency         string   `json:"currency,omitempty"`
	Price            float32  `json:"price,omitempty"`
	PriceEUR         float32  `json:"price_eur,omitempty"`
	PriceGBP         float32  `json:"price_gbp,omitempty"`
	PriceUSD         float32  `json:"price_usd,omitempty"`
	PriceDKK         float32  `json:"price_dkk,omitempty"`
	PriceSEK         float32  `json:"price_sek,omitempty"`
	PriceINR         float32  `json:"price_inr,omitempty"`
	PriceAUD         float32  `json:"price_aud,omitempty"`
	OriginalPrice    float32  `json:"original_price,omitempty"`
	OriginalPriceEUR float32  `json:"original_price_eur,omitempty"`
	OriginalPriceGBP float32  `json:"original_price_gbp,omitempty"`
	OriginalPriceUSD float32  `json:"original_price_usd,omitempty"`
	OriginalPriceDKK float32  `json:"original_price_dkk,omitempty"`
	OriginalPriceSEK float32  `json:"original_price_sek,omitempty"`
	OriginalPriceINR float32  `json:"original_price_inr,omitempty"`
	OriginalPriceAUD float32  `json:"original_price_aud,omitempty"`
	Stores           []*Store `json:"stores,omitempty"`
	StoreLocations   []Point  `json:"store_locations,omitempty"`
}

type Store struct {
	Name       string    `json:"name"`
	Country    string    `json:"country"`
	City       string    `json:"city"`
	PostalCode string    `json:"postal_code"`
	Location   *Location `json:"location"`
	Address    string    `json:"address"`
}

type Point []float32

type Location struct {
	Lat float32 `json:"lat"`
	Lon float32 `json:"lon"`
}

type Annotations map[string][]string

type Item struct {
	Source      *Source     `json:"source"`
	Annotations Annotations `json:"annotations"`
}

func NewItemFromBytes(data []byte) (*Item, error) {
	var source *Source
	if err := json.Unmarshal(data, &source); err != nil {
		return nil, err
	}
	return &Item{
		Source:      source,
		Annotations: map[string][]string{},
	}, nil
}

func (i *Item) SetAnnotation(name string, value []string) error {
	i.Annotations[name] = value
	return nil
}

type ScoredItem struct {
	Item  *Item
	Score float32
}

type ScoredItems []*ScoredItem

func (it *Item) GetID() string {
	return it.Source.ID
}

func (s ScoredItems) Len() int {
	return len(s)
}

func (s ScoredItems) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

func (s ScoredItems) Less(i, j int) bool {
	return s[i].Score < s[j].Score
}
