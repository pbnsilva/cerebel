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
	annotations := m{
		"type": "object",
		"properties": m{
			"gender": m{
				"type": "keyword",
			},
			"category": m{
				"type": "keyword",
			},
			"color": m{
				"type": "keyword",
			},
			"color_count": m{
				"type": "keyword",
			},
			"fabric": m{
				"type": "keyword",
			},
			"shape": m{
				"type": "keyword",
			},
			"style": m{
				"type": "keyword",
			},
			"texture": m{
				"type": "keyword",
			},
			"density": m{
				"type": "keyword",
			},
			"filling": m{
				"type": "keyword",
			},
			"heel_form": m{
				"type": "keyword",
			},
			"heel_height": m{
				"type": "keyword",
			},
			"length": m{
				"type": "keyword",
			},
			"occasion": m{
				"type": "keyword",
			},
			"pattern": m{
				"type": "keyword",
			},
			"season": m{
				"type": "keyword",
			},
			"shaft_height": m{
				"type": "keyword",
			},
			"shaft_width": m{
				"type": "keyword",
			},
			"shirt_collar": m{
				"type": "keyword",
			},
			"shoe_fastener": m{
				"type": "keyword",
			},
			"shoe_toecap": m{
				"type": "keyword",
			},
			"shoe_width": m{
				"type": "keyword",
			},
			"sport": m{
				"type": "keyword",
			},
			"technology": m{
				"type": "keyword",
			},
			"trouser_rise": m{
				"type": "keyword",
			},
			"upper_material": m{
				"type": "keyword",
			},
			"volume": m{
				"type": "keyword",
			},
			"brand": m{
				"type": "keyword",
			},
		},
	}

	source := m{
		"type": "object",
		"properties": m{
			"id": m{
				"type":  "keyword",
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
			"currency": m{
				"type": "keyword",
			},
			"price": m{
				"type":  "float",
				"store": true,
			},
			"price_eur": m{
				"type":  "float",
				"store": true,
			},
			"price_gbp": m{
				"type":  "float",
				"store": true,
			},
			"price_usd": m{
				"type":  "float",
				"store": true,
			},
			"price_dkk": m{
				"type":  "float",
				"store": true,
			},
			"price_sek": m{
				"type":  "float",
				"store": true,
			},
			"price_inr": m{
				"type":  "float",
				"store": true,
			},
			"price_aud": m{
				"type":  "float",
				"store": true,
			},
			"store_locations": m{
				"type":  "geo_point",
				"store": true,
			},
			indexedTextField: m{
				"type":     "text",
				"store":    false,
				"analyzer": "language_analyzer",
			},
		},
	}

	mapping := m{
		productType: m{
			"_all": m{
				"enabled": false,
			},
			"properties": m{
				"source":      source,
				"annotations": annotations,
			},
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
					"synonym_filter": m{
						"type": "synonym",
						"synonyms": a{
							"trainers,sneakers,running shoes",
							"men,man",
							"women,woman",
							"phone cases,smartphone cases",
							"gloves,mittens",
							"purses,pouches",
							"keychains,keyrings",
							"nighties,nightshirts",
							"tees,t-shirts,tshirts,jerseys",
							"v-neck,vneck",
							"long sleeves,longsleeves",
							"short sleeves,shortsleeves",
							"trousers,pants",
							"lace-ups,lace ups",
							"slip ons,slip-ons",
						},
					},
				},
				"analyzer": m{
					"language_analyzer": m{
						"tokenizer": "standard",
						// TODO: install  analysis-icu plugin and enable "icu_folding" filter
						"filter": a{"lowercase", "word_delimeter_filter", "stop_words", "synonym_filter", "language_stemmer"},
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
