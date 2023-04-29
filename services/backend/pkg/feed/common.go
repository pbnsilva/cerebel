package feed

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	shared_feed "github.com/petard/cerebel/shared/feed"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/stats"
	elastic "gopkg.in/olivere/elastic.v5"
)

const (
	storeID = "faer"

	defaultPageParam = 1
	defaultSizeParam = 20
)

func getFeedItems(ctx context.Context, store *shared_feed.Store, statsStore *stats.Store, queryParams map[string]interface{}, userID string) ([]json.RawMessage, int64, error) {
	client := store.GetClient()
	index := store.GetIndex()

	page := defaultPageParam
	if pageParam, found := queryParams[pageParamName]; found {
		page, _ = pageParam.(int)
	}

	if page < 1 {
		page = 1
	}

	size := defaultSizeParam
	if sizeParam, found := queryParams[sizeParamName]; found {
		size, _ = sizeParam.(int)
	}

	gender := ""
	if genderArg, found := queryParams[genderParamName]; found {
		gender = genderArg.(string)
	}

	category := ""
	if categoryArg, found := queryParams[categoryParamName]; found {
		category = categoryArg.(string)
	}

	boolQuery := elastic.NewBoolQuery()
	if gender != "" && gender != "all" {
		boolQuery = boolQuery.Filter(elastic.NewTermQuery("items.gender", gender))
	}

	if category != "" {
		boolQuery = boolQuery.Filter(elastic.NewTermQuery("items.annotations.category", category))
	}

	doPersonalization := userID != "" && statsStore != nil

	var brands []string
	var err error
	if doPersonalization {
		brands, _, err = statsStore.GetTopUserBrands(userID, 10)
		if err != nil {
			doPersonalization = false
			log.Error(err, "user_id", userID)
		}
	}

	var source *elastic.SearchSource
	if doPersonalization {

		// exclude products the user already interacted with
		productIDs, err := statsStore.GetUserInteractedProducts(userID)
		if err != nil {
			log.Error(err, "user_id", userID)
		}

		if len(productIDs) > 0 {
			ids := make([]interface{}, len(productIDs))
			for i, id := range productIDs {
				ids[i] = id
			}
			boolQuery = boolQuery.MustNot(elastic.NewTermsQuery("items.id", ids...))
		}

		dateSortFunction := elastic.NewGaussDecayFunction().FieldName("date").Origin(time.Now().Unix()).Scale("1h").Decay(0.9).Weight(2)

		q := elastic.NewFunctionScoreQuery().Query(boolQuery).AddScoreFunc(dateSortFunction)

		for _, brand := range brands {
			q = q.Add(elastic.NewMatchQuery("items.brand", brand), elastic.NewRandomFunction().Weight(1.15))
		}

		q = q.BoostMode("replace").ScoreMode("multiply")

		randomScript := elastic.NewScript("Math.random()")
		randomFunctionScore := elastic.NewFunctionScoreQuery().AddScoreFunc(elastic.NewScriptFunction(randomScript))
		randomRescorer := elastic.NewQueryRescorer(randomFunctionScore)
		randomRescore := elastic.NewRescore().Rescorer(randomRescorer).WindowSize(20)

		source = elastic.NewSearchSource().Query(q).Rescorer(randomRescore)
	} else {
		source = elastic.NewSearchSource().Query(boolQuery).Sort("date", false)
	}

	from := (page - 1) * size
	source = source.From(from).Size(size)

	svcResult, err := client.Search().
		Index(index.Alias()).
		Type(shared_feed.ItemType).
		SearchSource(source).
		Do(ctx)
	if err != nil {
		return nil, 0, err
	}

	fixedItems, err := getFixedFeedItems(ctx, store, gender, from, from+size)
	if err != nil {
		return nil, 0, err
	}

	items := []json.RawMessage{}
	for i, hit := range svcResult.Hits.Hits {
		if fixedItem, found := fixedItems[i+from]; found {
			items = append(items, fixedItem)
		}

		if len(items) < size {
			items = append(items, *hit.Source)
		}
	}

	return items, svcResult.TotalHits(), nil
}

func getFixedFeedItems(ctx context.Context, store *shared_feed.Store, gender string, from, to int) (map[int]json.RawMessage, error) {
	client := store.GetClient()
	index := store.GetIndex()

	positionFilter := elastic.NewRangeQuery("position").Gte(from).Lt(to)
	query := elastic.NewBoolQuery().Filter(positionFilter)
	if gender != "" && gender != "all" {
		query = query.Filter(elastic.NewTermQuery("items.gender", gender))
	}

	svc := client.Search().
		Index(index.Alias()).
		Type(shared_feed.PromotionType)

	svc = svc.Query(query)
	svcResult, err := svc.Do(ctx)
	if err != nil {
		return nil, err
	}

	items := map[int]json.RawMessage{}
	for _, hit := range svcResult.Hits.Hits {
		var item *shared_feed.InstagramItem
		if err := json.Unmarshal(*hit.Source, &item); err != nil {
			return nil, err
		}
		items[item.GetPosition()] = *hit.Source
	}

	return items, nil
}

func makeIndexID(accountID, storeID string) string {
	return fmt.Sprintf("%s_%s", accountID, storeID)
}
