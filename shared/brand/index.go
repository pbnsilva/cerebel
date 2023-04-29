package brand

const (
	esType = "item"
	esName = "brands"
)

type a []interface{}
type m map[string]interface{}

type Index struct {
}

func NewIndex() *Index {
	return &Index{}
}

func (i *Index) Type() string {
	return esType
}

func (i *Index) Name() string {
	return esName
}

func (i *Index) Mapping() map[string]interface{} {
	return m{
		"settings": withShardsAndReplicas(m{}),
		"mappings": m{
			i.Type(): m{
				"_all": m{
					"enabled": false,
				},
				"properties": m{
					"id": m{
						"type":  "keyword",
						"index": "not_analyzed",
					},
					"url": m{
						"type":  "keyword",
						"index": "not_analyzed",
					},
					"name": m{
						"type": "text",
					},
					"description": m{
						"type":  "text",
						"index": "not_analyzed",
					},
					"tags": m{
						"type":  "keyword",
						"index": "not_analyzed",
					},
					"location": m{
						"type":  "keyword",
						"index": "not_analyzed",
					},
					"price_range": m{
						"type":  "keyword",
						"index": "not_analyzed",
					},
					"stores": m{
						"properties": m{
							"name": m{
								"type":  "text",
								"store": true,
								"index": "not_analyzed",
							},
							"country": m{
								"type":  "keyword",
								"store": true,
								"index": "not_analyzed",
							},
							"city": m{
								"type":  "keyword",
								"store": true,
								"index": "not_analyzed",
							},
							"postal_code": m{
								"type":  "keyword",
								"store": true,
								"index": "not_analyzed",
							},
							"location": m{
								"type":  "geo_point",
								"store": true,
								"index": "not_analyzed",
							},
							"address": m{
								"type":  "text",
								"store": true,
								"index": "not_analyzed",
							},
						},
					},
				},
			},
		},
	}
}

func withShardsAndReplicas(settings map[string]interface{}) map[string]interface{} {
	// TODO: only for test run
	settings["number_of_shards"] = 1
	settings["number_of_replicas"] = 0

	return settings
}
