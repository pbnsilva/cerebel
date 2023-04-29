package user

const (
	esType = "item"
	esName = "users"
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
						"type":  "string",
						"index": "not_analyzed",
					},
					"creation_date": m{
						"type":  "date",
						"index": "not_analyzed",
					},
					"os": m{
						"type":  "string",
						"index": "not_analyzed",
					},
					"fcm_token": m{
						"type":  "string",
						"index": "not_analyzed",
					},
					"last_notification_date": m{
						"type":  "date",
						"index": "not_analyzed",
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
