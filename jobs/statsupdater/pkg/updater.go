package pkg

import (
	"context"
	"fmt"
	"strings"
	"time"

	"google.golang.org/api/iterator"

	elastic "gopkg.in/olivere/elastic.v5"

	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	"github.com/petard/cerebel/shared/stats"

	"cloud.google.com/go/bigquery"
)

const (
	projectID = "faer-180421"

	likeEventName  = "add_to_wishlist"
	shareEventName = "share"
)

type event struct {
	Name      string `bigquery:"event_name"`
	Timestamp int64  `bigquery:"event_timestamp"`
	UserID    string `bigquery:"user_pseudo_id"`
	ProductID string `bigquery:"product_id"`
}

type StatsUpdater struct {
	cfg          *StatsUpdaterJobConfig
	esClient     *elastic.Client
	productStore *product.ESStore
	statsStore   *stats.Store
	lastUpdated  uint64
}

func NewStatsUpdater(cfg *StatsUpdaterJobConfig) (*StatsUpdater, error) {
	esClient, err := es.NewSimpleClient(cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	productStore, err := product.NewESStore("faer", esClient)
	if err != nil {
		return nil, err
	}

	statsStore, err := stats.NewStore(cfg.GetRedisHost())
	if err != nil {
		return nil, err
	}

	lastUpdated, err := statsStore.GetLastUpdatedTimestamp()
	if err != nil {
		return nil, err
	}

	return &StatsUpdater{cfg, esClient, productStore, statsStore, lastUpdated}, nil
}

func (s *StatsUpdater) Run() error {
	ctx := context.Background()

	rows, err := s.query()
	if err != nil {
		return err
	}

	var e event
	processedCount := 0
	for {
		err := rows.Next(&e)
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Error(err)
			break
		}

		if err := s.updateStats(ctx, e); err != nil {
			log.Error(err)
			continue
		}

		processedCount += 1
	}

	if e.Timestamp != 0 {
		if err := s.statsStore.SetLastUpdatedTimestamp(uint64(e.Timestamp)); err != nil {
			log.Error(err, "Error setting last updated timestamp")
		}
	}

	log.Info("Events processed", "count", processedCount)

	return nil
}

func (s *StatsUpdater) updateStats(ctx context.Context, e event) error {
	var err error

	item, err := s.productStore.GetItemByID(ctx, e.ProductID)
	if err != nil {
		if err == product.ErrItemNotFound {
			return nil
		}
		return err
	}

	// update product stats
	if e.Name == likeEventName {
		if _, err = s.statsStore.IncrLikesForProduct(e.ProductID, item.BrandID, item.Gender, 1); err != nil {
			return err
		}
	} else if e.Name == shareEventName {
		if _, err = s.statsStore.IncrSharesForProduct(e.ProductID, item.BrandID, item.Gender, 1); err != nil {
			return err
		}
	}

	// update user-brand stats
	if _, err := s.statsStore.IncrUserBrandInteractions(e.UserID, item.BrandID, 1); err != nil {
		return err
	}

	// update user's product set
	if err := s.statsStore.AddUserProductInteraction(e.UserID, item.ID); err != nil {
		return err
	}

	// update category stats
	if cats, found := item.Annotations["category"]; found {
		category := strings.Replace(cats[0], " ", "_", -1)
		if e.Name == likeEventName {
			for _, gender := range item.Gender {
				if _, err := s.statsStore.IncrLikesForCategory(category, gender, 1); err != nil {
					return err
				}
			}
		} else if e.Name == shareEventName {
			for _, gender := range item.Gender {
				if _, err := s.statsStore.IncrSharesForCategory(category, gender, 1); err != nil {
					return err
				}
			}
		}
	}

	// update brand stats
	if e.Name == likeEventName {
		for _, gender := range item.Gender {
			if _, err := s.statsStore.IncrLikesForBrand(item.BrandID, gender, 1); err != nil {
				return err
			}
		}
	} else if e.Name == shareEventName {
		for _, gender := range item.Gender {
			if _, err := s.statsStore.IncrSharesForBrand(item.BrandID, gender, 1); err != nil {
				return err
			}
		}
	}

	return nil
}

func (s *StatsUpdater) query() (*bigquery.RowIterator, error) {
	ctx := context.Background()

	client, err := bigquery.NewClient(ctx, projectID)
	if err != nil {
		return nil, err
	}

	updatedDate := time.Unix(0, int64(s.lastUpdated/1000))
	todayDay, todayMonth, todayYear := time.Now().Date()

	intradayTable := fmt.Sprintf("analytics_163193596.events_intraday_%s", time.Now().Format("20060102"))
	intraDayQ := s.getInteractionsQuery(intradayTable, s.lastUpdated)

	var query *bigquery.Query
	if updatedDate.Day() == todayDay && updatedDate.Month() == todayMonth && updatedDate.Year() == todayYear {
		// if we last updated today, then check the intraday events table
		query = client.Query(intraDayQ)
	} else {
		fromQueries := []string{}

		fromQueries = append(fromQueries, intraDayQ)

		for i := 0; i < 3; i++ {
			date := time.Now().Add(-time.Duration(i*32*24) * time.Hour).Format("20060102")
			tableName := fmt.Sprintf("analytics_163193596.events_%s*", date[:6])
			fromQueries = append(fromQueries, s.getInteractionsQuery(tableName, s.lastUpdated))
		}

		query = client.Query(fmt.Sprintf(`
			SELECT
				event_name,
				event_timestamp,
				user_pseudo_id,
				product_id
			FROM (%s)
			ORDER BY event_timestamp ASC`, strings.Join(fromQueries, " UNION ALL ")))
	}

	return query.Read(ctx)
}

func (s *StatsUpdater) getInteractionsQuery(table string, sinceTimestamp uint64) string {
	// TODO add product detail page views
	/*return fmt.Sprintf(`
	SELECT
		event_name,
		event_timestamp,
		user_pseudo_id,
		e.value.string_value
	FROM `+"`%s`"+`, UNNEST(event_params) as e
	WHERE
		(event_name="add_to_wishlist" AND e.key="item_id") OR
		(event_name="share" AND e.key="item_id") OR
		(event_name="user_engagement" AND e.key="firebase_screen_class" AND (e.value.string_value="ProductDetailActivity" OR e.value.string_value="ProductDetailCollectionViewController) AND
		event_timestamp>%d
	ORDER BY event_timestamp ASC
	`, table, sinceTimestamp)*/
	return fmt.Sprintf(`
	SELECT
		event_name,
		event_timestamp,
		user_pseudo_id,
		(SELECT value.string_value FROM UNNEST(event_params) WHERE key="item_id") as product_id
	FROM `+"`%s`"+`
	WHERE
		(event_name="add_to_wishlist" OR
		event_name="share") AND
		event_timestamp>%d
	`, table, sinceTimestamp)
}
