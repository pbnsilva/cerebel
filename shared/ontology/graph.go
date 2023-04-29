package ontology

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"os"
)

const (
	classTypeURI = "http://www.w3.org/2002/07/owl#Class"
)

var (
	errEntityNotFound = errors.New("Entity not found")
)

type Entity struct {
	Key      string
	Label    string
	Parent   *Entity
	Children []*Entity
}

type triple struct {
	ID         string   `json:"@id"`
	Type       []string `json:"@type"`
	Label      []*value `json:"http://www.w3.org/2000/01/rdf-schema#label"`
	SubClassOf []*id    `json:"http://www.w3.org/2000/01/rdf-schema#subClassOf"`
}

type value struct {
	Value string `json:"@value"`
}

type id struct {
	ID string `json:"@id"`
}

type Graph struct {
	entities map[string]*Entity
}

func NewGraph(fpath string) (*Graph, error) {
	entities, err := loadEntities(fpath)
	if err != nil {
		return nil, err
	}

	return &Graph{entities}, nil
}

func (g *Graph) GetEntity(key string) (*Entity, error) {
	entity, found := g.entities[key]
	if !found {
		return nil, errEntityNotFound
	}
	return entity, nil
}

func loadEntities(fpath string) (map[string]*Entity, error) {
	f, err := os.Open(fpath)
	if err != nil {
		return nil, err
	}

	data, err := ioutil.ReadAll(f)
	if err != nil {
		return nil, err
	}

	var jsonData []*triple
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return nil, err
	}

	entities := map[string]*Entity{}
	for _, t := range jsonData {
		if t.Type[0] != classTypeURI {
			continue
		}

		if _, found := entities[t.ID]; !found {
			entities[t.ID] = &Entity{
				Key:   t.ID,
				Label: t.Label[0].Value,
			}
		}

		if t.SubClassOf != nil {
			if parent, found := entities[t.SubClassOf[0].ID]; found {
				entities[t.ID].Parent = parent
				parent.Children = append(parent.Children, entities[t.ID])
			}
		}

	}

	return entities, err
}
