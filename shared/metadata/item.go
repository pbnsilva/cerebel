package metadata

const (
	FeedSourceTypeInstagram = "instagram"
)

type FeedConfig struct {
	Sources         []*FeedSource `json:"sources"`
	LastIndexedDate uint64        `json:"last_indexed_date"`
}

type FeedSource struct {
	Type string `json:"type"`
	URL  string `json:"url"`
}

type Item struct {
	StoreID      string      `json:"store_id"`
	ReadTokens   []string    `json:"read_tokens"`
	AdminToken   string      `json:"admin_token"`
	ImageIndexID string      `json:"image_index_id"`
	FeedConfig   *FeedConfig `json:"feed_config"`
}
