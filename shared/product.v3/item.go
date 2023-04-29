package product

import (
	"encoding/json"

	"github.com/petard/cerebel/shared/brand"
	"github.com/petard/cerebel/shared/es"
	pb "github.com/petard/cerebel/shared/rpc/store"
)

type Item struct {
	ID            string        `json:"id,omitempty"`
	CreatedAt     uint64        `json:"created_at,omitempty"`
	VendorID      string        `json:"vendor_id,omitempty"` // vendor's product ID
	Name          string        `json:"name,omitempty"`
	Brand         string        `json:"brand,omitempty"`
	BrandID       string        `json:"brand_id,omitempty"`
	URL           string        `json:"url,omitempty"`
	ShareURL      string        `json:"share_url,omitempty"`
	Gender        []string      `json:"gender,omitempty"`
	Description   string        `json:"description,omitempty"`
	ImageURL      []string      `json:"image_url,omitempty"`
	Tags          []string      `json:"tags,omitempty,omitempty"`
	Price         *Price        `json:"price,omitempty"`
	OriginalPrice *Price        `json:"original_price,omitempty"`
	Shops         []*brand.Shop `json:"stores,omitempty"`
	Variants      []*Variant    `json:"variants,omitempty"`
	Promotion     string        `json:"promotion,omitempty"`

	Annotations map[string][]string `json:"annotations,omitempty"`

	// this field is used to simplify geo queries
	StoreLocations []*es.Location `json:"store_locations,omitempty"`
}

type Variant struct {
	ID        string   `json:"id,omitempty"`
	VendorID  string   `json:"vendor_id"`            // vendor's variant ID
	VendorSKU string   `json:"vendor_sku,omitempty"` // vendor's variant SKU
	Name      string   `json:"name"`
	ImageURL  []string `json:"image_url,omitempty"`
	Available bool     `json:"available"`

	// so far we only support size and color variations
	Color string `json:"color,omitempty"`
	Size  string `json:"size,omitempty"`
}

type Price struct {
	EUR float32 `json:"eur,omitempty"`
	GBP float32 `json:"gbp,omitempty"`
	USD float32 `json:"usd,omitempty"`
	DKK float32 `json:"dkk,omitempty"`
	SEK float32 `json:"sek,omitempty"`
	INR float32 `json:"inr,omitempty"`
	AUD float32 `json:"aud,omitempty"`
}

func NewItemFromBytes(data []byte) (*Item, error) {
	var item *Item
	if err := json.Unmarshal(data, &item); err != nil {
		return nil, err
	}
	item.Annotations = map[string][]string{}
	return item, nil
}

func (item *Item) SetAnnotation(name string, value []string) error {
	item.Annotations[name] = value
	return nil
}

func (item *Item) ToProto() *pb.Item {
	price := &pb.Price{
		Eur: item.Price.EUR,
		Gbp: item.Price.GBP,
		Usd: item.Price.USD,
		Dkk: item.Price.DKK,
		Sek: item.Price.SEK,
		Inr: item.Price.INR,
		Aud: item.Price.AUD,
	}

	var originalPrice *pb.Price
	if item.OriginalPrice != nil {
		originalPrice = &pb.Price{
			Eur: item.OriginalPrice.EUR,
			Gbp: item.OriginalPrice.GBP,
			Usd: item.OriginalPrice.USD,
			Dkk: item.OriginalPrice.DKK,
			Sek: item.OriginalPrice.SEK,
			Inr: item.OriginalPrice.INR,
			Aud: item.OriginalPrice.AUD,
		}
	}

	var stores []*pb.Store
	for _, store := range item.Shops {
		stores = append(stores, &pb.Store{Name: store.Name,
			Country:    store.Country,
			City:       store.City,
			PostalCode: store.PostalCode,
			Location:   &pb.Location{Lon: store.Location.Lon, Lat: store.Location.Lat},
			Address:    store.Address,
		})
	}

	var variants []*pb.Variant
	for _, variant := range item.Variants {
		variants = append(variants, &pb.Variant{
			Id:        variant.ID,
			VendorId:  variant.VendorID,
			VendorSku: variant.VendorSKU,
			Name:      variant.Name,
			Available: variant.Available,
			ImageUrl:  variant.ImageURL,
			Color:     variant.Color,
			Size:      variant.Size,
		})
	}

	annotations := []*pb.Annotation{}
	for k, v := range item.Annotations {
		annotations = append(annotations, &pb.Annotation{Kind: k, Values: v})
	}

	return &pb.Item{
		Id:            item.ID,
		CreatedAt:     item.CreatedAt,
		VendorId:      item.VendorID,
		Name:          item.Name,
		Brand:         item.Brand,
		BrandId:       item.BrandID,
		Url:           item.URL,
		ShareUrl:      item.ShareURL,
		Gender:        item.Gender,
		Description:   item.Description,
		ImageUrl:      item.ImageURL,
		Tags:          item.Tags,
		Price:         price,
		OriginalPrice: originalPrice,
		Stores:        stores,
		Variants:      variants,
		Annotations:   annotations,
	}
}

func ItemFromProto(item *pb.Item) *Item {
	price := &Price{
		EUR: item.Price.Eur,
		GBP: item.Price.Gbp,
		USD: item.Price.Usd,
		DKK: item.Price.Dkk,
		SEK: item.Price.Sek,
		INR: item.Price.Inr,
		AUD: item.Price.Aud,
	}

	var originalPrice *Price
	if item.OriginalPrice != nil {
		originalPrice = &Price{
			EUR: item.OriginalPrice.Eur,
			GBP: item.OriginalPrice.Gbp,
			USD: item.OriginalPrice.Usd,
			DKK: item.OriginalPrice.Dkk,
			SEK: item.OriginalPrice.Sek,
			INR: item.OriginalPrice.Inr,
			AUD: item.OriginalPrice.Aud,
		}
	}

	var stores []*brand.Shop
	var storeLocations []*es.Location
	for _, store := range item.Stores {
		stores = append(stores, &brand.Shop{
			Name:       store.Name,
			Country:    store.Country,
			City:       store.City,
			PostalCode: store.PostalCode,
			Location:   &es.Location{Lon: store.Location.Lon, Lat: store.Location.Lat},
			Address:    store.Address,
		})

		storeLocations = append(storeLocations, &es.Location{Lon: store.Location.Lon, Lat: store.Location.Lat})
	}

	var variants []*Variant
	for _, variant := range item.Variants {
		variants = append(variants, &Variant{
			ID:        variant.Id,
			VendorID:  variant.VendorId,
			VendorSKU: variant.VendorSku,
			Name:      variant.Name,
			Available: variant.Available,
			ImageURL:  variant.ImageUrl,
			Color:     variant.Color,
			Size:      variant.Size,
		})
	}

	annotations := map[string][]string{}
	for _, v := range item.Annotations {
		annotations[v.Kind] = v.Values
	}

	return &Item{
		ID:             item.Id,
		CreatedAt:      item.CreatedAt,
		VendorID:       item.VendorId,
		Name:           item.Name,
		Brand:          item.Brand,
		BrandID:        item.BrandId,
		URL:            item.Url,
		ShareURL:       item.ShareUrl,
		Gender:         item.Gender,
		Description:    item.Description,
		ImageURL:       item.ImageUrl,
		Tags:           item.Tags,
		Price:          price,
		OriginalPrice:  originalPrice,
		Shops:          stores,
		Variants:       variants,
		Annotations:    annotations,
		StoreLocations: storeLocations,
	}
}

func (item *Item) IsOnSale() bool {
	return item.OriginalPrice != nil
}

type ScoredItem struct {
	Item  *Item
	Score float32
}

type ScoredItems []*ScoredItem

func (it *Item) GetID() string {
	return it.ID
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
