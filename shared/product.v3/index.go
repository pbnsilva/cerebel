package product

import "fmt"

type a []interface{}
type m map[string]interface{}

type FieldType string

const (
	storePrefix      = "cerebel_store"
	productType      = "product"
	indexedTextField = "indexed_text"
)

type Index struct {
	name    string
	mapping m
}

func NewIndex(id string) *Index {
	name := fmt.Sprintf("%s_%s", storePrefix, id)
	return &Index{
		name: name,
	}
}

func (i *Index) Type() string {
	return productType
}

func (i *Index) Name() string {
	return i.name
}

func (i *Index) Mapping() map[string]interface{} {
	itemProperties := m{
		"id": m{
			"type":  "keyword",
			"store": true,
			"index": "not_analyzed",
		},
		"created_at": m{
			"type":  "date",
			"store": true,
			"index": "not_analyzed",
		},
		"name": m{
			"type":     "text",
			"store":    true,
			"copy_to":  a{"indexed_text"},
			"analyzer": "language_analyzer",
		},
		"brand": m{
			"type":    "keyword",
			"store":   true,
			"copy_to": a{"indexed_text"},
		},
		"url": m{
			"type":  "text",
			"store": true,
		},
		"categories": m{
			"type":    "keyword",
			"store":   true,
			"copy_to": a{"indexed_text"},
		},
		"gender": m{
			"type":    "keyword",
			"store":   true,
			"copy_to": a{"indexed_text"},
		},
		"description": m{
			"type":     "text",
			"store":    true,
			"copy_to":  a{"indexed_text"},
			"analyzer": "language_analyzer",
		},
		"image_url": m{
			"type": "text",
			"fields": m{
				"keyword": m{
					"type":         "keyword",
					"ignore_above": 256,
				},
			},
		},
		"price": m{
			"type": "object",
			"properties": m{
				"eur": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"gbp": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"usd": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"dkk": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"sek": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"inr": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"aud": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
			},
		},
		"original_price": m{
			"type": "object",
			"properties": m{
				"eur": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"gbp": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"usd": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"dkk": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"sek": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"inr": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
				"aud": m{
					"type":  "float",
					"store": true,
					"index": "not_analyzed",
				},
			},
		},
		"stores": m{
			"type": "object",
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
		"variants": m{
			"type": "object",
			"properties": m{
				"id": m{
					"type":  "keyword",
					"store": true,
					"index": "not_analyzed",
				},
				"name": m{
					"type":  "text",
					"store": true,
				},
				"available": m{
					"type":  "boolean",
					"store": true,
					"index": "not_analyzed",
				},
				"image_url": m{
					"type": "keyword",
					"fields": m{
						"keyword": m{
							"type":         "keyword",
							"ignore_above": 256,
						},
					},
				},
				"color": m{
					"type":  "keyword",
					"store": true,
				},
				"size": m{
					"type":  "keyword",
					"store": true,
				},
			},
		},
		"store_locations": m{
			"type":  "geo_point",
			"store": false,
		},
		"annotations": m{
			"type": "object",
			"properties": m{
				"category": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"brand": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"color": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"fabric": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"heel_form": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"length": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"occasion": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"pattern": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"season": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"shirt_collar": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"shoe_fastener": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"sleeve_length": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
				"trouser_rise": m{
					"type":    "keyword",
					"store":   true,
					"copy_to": a{"indexed_text"},
				},
			},
		},
		indexedTextField: m{
			"type":     "text",
			"store":    false,
			"analyzer": "language_analyzer",
		},
	}

	mapping := m{
		productType: m{
			"_all": m{
				"enabled": false,
			},
			"properties": itemProperties,
		},
	}

	return m{
		"settings": withShardsAndReplicas(m{
			"analysis": m{
				"filter": m{
					"word_delimeter_filter": m{
						"type":                  "word_delimiter",
						"preserve_original":     "true",
						"catenate_words":        "true",
						"split_on_numerics":     "true",
						"generate_number_parts": "true",
						"generate_word_parts":   "true",
					},
					"stop_words": m{
						"type":      "stop",
						"stopwords": "_english_",
					},
					"language_stemmer": m{
						"type":     "stemmer",
						"language": "english",
					},
				},
				"analyzer": m{
					"language_analyzer": m{
						"tokenizer": "standard",
						// TODO: install  analysis-icu plugin and enable "icu_folding" filter
						"filter": a{"lowercase", "word_delimeter_filter", "stop_words", "language_stemmer"},
					},
				},
			},
		}),
		"mappings": mapping,
	}
}

func withShardsAndReplicas(settings map[string]interface{}) map[string]interface{} {
	// TODO: only for test run
	settings["number_of_shards"] = 1
	settings["number_of_replicas"] = 0

	return settings
}
