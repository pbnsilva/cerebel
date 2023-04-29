package metadata

const (
	esType = "item"
	esName = "metadata"
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
					"store_id": m{
						"type":  "string",
						"index": "not_analyzed",
					},
					"read_tokens": m{
						"type":  "string",
						"index": "not_analyzed",
					},
					"admin_token": m{
						"type":  "string",
						"index": "not_analyzed",
					},
					"image_index_id": m{
						"type":  "string",
						"index": "not_analyzed",
					},
					"feed_config": m{
						"last_indexed_date": m{
							"type":  "long",
							"index": "not_analyzed",
						},
						"sources": m{
							"properties": m{
								"type": m{
									"type":  "string",
									"index": "not_analyzed",
								},
								"url": m{
									"type":  "string",
									"index": "not_analyzed",
								},
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
