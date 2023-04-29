package suggester

import (
	"context"
	"encoding/json"
	"strings"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
)

type Store struct {
	index *Index

	client *elastic.Client
}

func NewStore(id string, client *elastic.Client) *Store {
	return &Store{
		client: client,
		index:  NewIndex(id),
	}
}

func (s *Store) Create(ctx context.Context) error {
	return es.CreateIndex(ctx, s.index, s.client)
}

func (s *Store) Put(ctx context.Context, item *Item) error {
	_, err := s.client.Index().
		Index(s.index.Name()).
		Type(s.index.Type()).
		Id(strings.Replace(item.Suggestion.Input[0], " ", "_", -1)).
		BodyJson(item).
		Do(ctx)

	// handle concurrency errors nicely
	if err != nil {
		return err
	}

	return nil
}

func (s *Store) GetWithoutPrefix(ctx context.Context, size int, gender []string) ([]*Suggestion, error) {
	// TODO get this from redis, mocking for now
	suggestions := []*Suggestion{
		&Suggestion{Value: "dress"},
		&Suggestion{Value: "jeans"},
		&Suggestion{Value: "shoes"},
		&Suggestion{Value: "coat"},
		&Suggestion{Value: "pullover"},
		&Suggestion{Value: "boots"},
		&Suggestion{Value: "shirt"},
		&Suggestion{Value: "sneakers"},
		&Suggestion{Value: "underwear"},
		&Suggestion{Value: "sweater"},
		&Suggestion{Value: "trousers"},
		&Suggestion{Value: "tops"},
		&Suggestion{Value: "cardigan"},
		&Suggestion{Value: "hoody"},
		&Suggestion{Value: "denim jeans"},
		&Suggestion{Value: "jumpsuit"},
		&Suggestion{Value: "gloves"},
		&Suggestion{Value: "socks"},
		&Suggestion{Value: "parka"},
		&Suggestion{Value: "blazer"},
	}

	if size > len(suggestions) {
		return suggestions, nil
	}

	return suggestions[:size], nil
}

func (s *Store) GetWithPrefix(ctx context.Context, prefix string, size int, gender []string) ([]*Suggestion, error) {
	prefix = strings.ToLower(prefix)
	sug := elastic.NewCompletionSuggester("query-suggest").
		Prefix(prefix).
		Field("suggestion").
		Size(size)
		//FuzzyOptions(elastic.NewFuzzyCompletionSuggesterOptions().EditDistance(1))

	if len(gender) > 0 {
		sug = sug.ContextQueries(elastic.NewSuggesterCategoryQuery("gender", gender...))
	}

	searchSource := elastic.NewSearchSource().
		Suggester(sug)

	svc := s.client.Search().
		Index(s.index.Name()).
		Type(s.index.Type()).
		SearchSource(searchSource)

	result, err := svc.Do(ctx)
	if err != nil {
		return nil, err
	}

	suggestions := []*Suggestion{}
	for _, s := range result.Suggest["query-suggest"] {
		for _, opt := range s.Options {
			var item *Item
			if err := json.Unmarshal(*opt.Source, &item); err != nil {
				return nil, err
			}
			val := item.Suggestion.Input[0]

			offset := strings.Index(strings.ToLower(val), prefix)
			suggestions = append(suggestions, &Suggestion{
				Value:  val,
				Offset: &offset,
			})
		}
	}

	return suggestions, nil
}
