package suggester

import "fmt"

const (
	storePrefix = "suggester"
	esType      = "item"
)

type a []interface{}
type m map[string]interface{}

type Index struct {
	name string
}

func NewIndex(id string) *Index {
	name := fmt.Sprintf("%s_%s", storePrefix, id)
	return &Index{
		name: name,
	}
}

func (i *Index) Type() string {
	return esType
}

func (i *Index) Name() string {
	return i.name
}

func (i *Index) Mapping() map[string]interface{} {
	return m{
		"settings": withShardsAndReplicas(m{}),
		"mappings": m{
			i.Type(): m{
				"properties": m{
					"suggestion": m{
						"type": "completion",
						"contexts": a{
							m{
								"name": "gender",
								"type": "category",
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
