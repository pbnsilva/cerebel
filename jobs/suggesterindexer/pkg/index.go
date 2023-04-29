package pkg

import (
	"context"
	"io"
	"regexp"
	"strings"

	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	"github.com/petard/cerebel/shared/suggester"
	"github.com/petard/cerebel/shared/text"
)

const (
	storeID = "faer"
)

type tokenSequence struct {
	Value        string
	UniqueBrands map[string]struct{}
	Count        int
	Gender       []string
}

type tokenSequenceList []tokenSequence

func (p tokenSequenceList) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
func (p tokenSequenceList) Len() int           { return len(p) }
func (p tokenSequenceList) Less(i, j int) bool { return p[i].Value < p[j].Value }

type SuggesterIndexer struct {
	cfg *IndexerJobConfig
}

func NewSuggesterIndexer(cfg *IndexerJobConfig) *SuggesterIndexer {
	return &SuggesterIndexer{cfg}
}

func (s *SuggesterIndexer) Run() error {
	ctx := context.TODO()

	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return err
	}

	productStore, err := product.NewESStore(storeID, esClient)
	if err != nil {
		return err
	}

	reg, err := regexp.Compile("[^a-z\\s]+")
	if err != nil {
		return err
	}

	tokenSequences := map[string]*tokenSequence{}
	suggestionItems := map[string]*suggester.Item{}
	it, _ := productStore.Scroll(ctx)
	for {
		items, err := it.Next(ctx)
		if err == io.EOF {
			break
		}

		if err != nil {
			return err
		}

		for _, item := range items {

			// add the brands
			if _, found := suggestionItems[item.Brand]; !found {
				suggestionItems[item.Brand] = suggester.NewItemWithWeight(s.getMultiWordInput(item.Brand, false), 5, []string{"men", "women"})
			}

			nameTokens := s.tokenize(string(text.RemoveStopWords([]byte(reg.ReplaceAllString(strings.ToLower(item.Name), "")), "en")))
			for i := 0; i < len(nameTokens); i++ {
				for j := i + 1; j < len(nameTokens)+1; j++ {
					seq := strings.Trim(strings.Join(nameTokens[i:j], " "), " ")
					if _, found := tokenSequences[seq]; !found {
						tokenSequences[seq] = &tokenSequence{Value: seq, Count: 1, UniqueBrands: map[string]struct{}{}, Gender: item.Gender}
						tokenSequences[seq].UniqueBrands[item.Brand] = struct{}{}
					} else {
						if _, found := tokenSequences[seq].UniqueBrands[item.Brand]; !found {
							tokenSequences[seq].Count += 1
							tokenSequences[seq].UniqueBrands[item.Brand] = struct{}{}
						}
					}
				}
			}
		}
	}

	for _, seq := range tokenSequences {
		if seq.Count < 4 {
			continue
		}
		stemmed := text.StemString(seq.Value)
		if _, found := suggestionItems[stemmed]; !found {
			suggestionItems[stemmed] = suggester.NewItemWithWeight(s.getMultiWordInput(seq.Value, true), seq.Count, seq.Gender)
		}
	}

	suggesterStore := suggester.NewStore(storeID, esClient)
	for _, item := range suggestionItems {
		if err := suggesterStore.Put(ctx, item); err != nil {
			return err
		}
	}

	log.Info("Indexed suggestions", "affected", len(suggestionItems))

	return nil
}

// TODO proper tokenization
func (s *SuggesterIndexer) tokenize(str string) []string {
	tokens := []string{}
	for _, w := range strings.Split(str, " ") {
		w := strings.Trim(w, " ")
		if len(w) < 2 {
			continue
		}
		tokens = append(tokens, w)
	}
	return tokens
}

func (s *SuggesterIndexer) getMultiWordInput(str string, lowercase bool) []string {
	if lowercase {
		str = strings.ToLower(str)
	}

	words := strings.Split(str, " ")
	input := []string{}
	for i := 0; i < len(words); i++ {
		input = append(input, strings.Join(words[i:len(words)], " "))
	}
	return input
}
