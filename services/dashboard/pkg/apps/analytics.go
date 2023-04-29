package apps

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"math"
	"net/http"
	"sort"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/gcs"
	"github.com/petard/cerebel/shared/log"
)

const (
	gcsBucket    = "faer.cerebel.io"
	gcsKeyPrefix = "metrics/"

	dateLayout = "20060102"
)

var (
	errInvalidDateRange = errors.New("Invalid date range")
)

type Analytics struct {
	cfg     *shared.DashboardConfig
	metrics map[string]*Metrics
}

type Metrics struct {
	NewUsersCount            int                `json:"new_users_count"`
	TotalUsersCount          int                `json:"total_users_count"`
	ActiveNewUsersCount      int                `json:"active_new_users_count"`
	ActiveUsersCount         int                `json:"active_users_count"`
	SessionsCount            int                `json:"sessions_count"`
	SearchesCount            int                `json:"searches_count"`
	SearchClickoutRate       float64            `json:"search_clickout_rate"`
	FreshlooksClickoutRate   float64            `json:"freshlooks_clickout_rate"`
	NotificationsSentCount   int                `json:"notifications_sent_count"`
	NotificationsOpenCount   int                `json:"notifications_open_count"`
	NotificationsOpenRate    float64            `json:"notifications_open_rate"`
	Searches                 []*SearchTermValue `json:"searches"`
	EmptySearches            []*SearchTermValue `json:"empty_searches"`
	AnnotationCoverage       map[string]float32 `json:"annotation_coverage"`
	EngagementActionsPerUser float64            `json:"engagement_actions_per_user"`
	ReturnRate               float64            `json:"weekly_return_rate"`
	ProductCount             int                `json:"product_count"`
	BrandCount               int                `json:"brand_count"`
	NewProductCount          int                `json:"new_product_count"`
	Checkouts                int                `json:"checkouts"`
	GMV                      float64            `json:"gmv"`
	ThreeMonthRetentionRate  []float64          `json:"three_month_retention_rate"`
}

type SearchTermValue struct {
	Term  string `json:"term"`
	Count int    `json:"count"`
}

type MetricsResult struct {
	NewUsersCount                int                `json:"new_users_count"`
	NewUsersCountDiff            int                `json:"new_users_count_diff"`
	TotalUsersCount              int                `json:"total_users_count"`
	TotalUsersCountDiff          int                `json:"total_users_count_diff"`
	ActiveNewUsersCount          int                `json:"active_new_users_count"`
	ActiveNewUsersCountDiff      int                `json:"active_new_users_count_diff"`
	ActiveUsersCount             int                `json:"active_users_count"`
	ActiveUsersCountDiff         int                `json:"active_users_count_diff"`
	SessionsCount                int                `json:"sessions_count"`
	SessionsCountDiff            int                `json:"sessions_count_diff"`
	SearchesCount                int                `json:"searches_count"`
	SearchesCountDiff            int                `json:"searches_count_diff"`
	SearchClickoutRate           []float64          `json:"search_clickout_rate"`
	SearchClickoutRateDiff       int                `json:"search_clickout_rate_diff"`
	SearchClickoutRateMean       float64            `json:"search_clickout_rate_mean"`
	FreshlooksClickoutRate       []float64          `json:"freshlooks_clickout_rate"`
	FreshlooksClickoutRateDiff   int                `json:"freshlooks_clickout_rate_diff"`
	FreshlooksClickoutRateMean   float64            `json:"freshlooks_clickout_rate_mean"`
	NotificationsSentCount       int                `json:"notifications_sent_count"`
	NotificationsSentCountDiff   int                `json:"notifications_sent_count_diff"`
	NotificationsOpenCount       int                `json:"notifications_open_count"`
	NotificationsOpenCountDiff   int                `json:"notifications_open_count_diff"`
	NotificationsOpenRate        []float64          `json:"notifications_open_rate"`
	NotificationsOpenRateMean    float64            `json:"notifications_open_rate_mean"`
	Searches                     []*SearchTermValue `json:"searches"`
	EmptySearches                []*SearchTermValue `json:"empty_searches"`
	AnnotationCoverage           map[string]float32 `json:"annotation_coverage"`
	EngagementActionsPerUser     []float64          `json:"engagement_actions_per_user"`
	EngagementActionsPerUserMean float64            `json:"engagement_actions_per_user_mean"`
	EngagementActionsPerUserDiff int                `json:"engagement_actions_per_user_diff"`
	ReturnRate                   []float64          `json:"return_rate"`
	ProductCount                 int                `json:"product_count"`
	BrandCount                   int                `json:"brand_count"`
	NewProductCount              []int              `json:"new_product_count"`
	Checkouts                    []int              `json:"checkouts"`
	CheckoutsTotal               int                `json:"checkouts_total"`
	CheckoutsTotalDiff           int                `json:"checkouts_total_diff"`
	GMV                          []float64          `json:"gmv"`
	GMVTotal                     float64            `json:"gmv_total"`
	GMVTotalDiff                 int                `json:"gmv_total_diff"`
	ThreeMonthRetentionRate      []float64          `json:"three_month_retention_rate"`
}

func NewAnalytics(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *Analytics {
	app := &Analytics{cfg, map[string]*Metrics{}}

	engine.GET("/analytics", auth.AuthorizeRequestMiddleware(engine), app.getAnalytics)
	engine.GET("/analytics/metrics", auth.AuthorizeRequestMiddleware(engine), app.getMetrics)

	return app
}

func (a *Analytics) getAnalytics(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "analytics.html", gin.H{})
}

func (a *Analytics) getMetrics(ctx *gin.Context) {
	startDate, err := time.Parse(dateLayout, ctx.Query("startDate"))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err})
		return
	}

	endDate, err := time.Parse(dateLayout, ctx.Query("endDate"))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err})
		return
	}

	metrics, err := a.fetchMetrics(startDate, endDate)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"values": metrics})
}

func (a *Analytics) fetchMetrics(startDate, endDate time.Time) (*MetricsResult, error) {
	daysDiff := int(endDate.Sub(startDate).Hours() / 24)
	if daysDiff < 1 {
		return nil, errInvalidDateRange
	}

	result := &MetricsResult{}
	for d := startDate; d.Before(endDate); d = d.AddDate(0, 0, 1) {
		metrics, err := a.fetchMetricsForDate(d)
		if err != nil {
			log.Error(err)
			continue
		}

		result.NewUsersCount += metrics.NewUsersCount
		result.TotalUsersCount += metrics.TotalUsersCount
		result.ActiveNewUsersCount += metrics.ActiveNewUsersCount
		result.ActiveUsersCount += metrics.ActiveUsersCount
		result.SessionsCount += metrics.SessionsCount
		result.SearchesCount += metrics.SearchesCount
		result.NotificationsSentCount += metrics.NotificationsSentCount
		result.NotificationsOpenCount += metrics.NotificationsOpenCount
		result.Searches = append(result.Searches, metrics.Searches...)
		result.EmptySearches = append(result.EmptySearches, metrics.EmptySearches...)
		result.AnnotationCoverage = metrics.AnnotationCoverage
		result.SearchClickoutRate = append(result.SearchClickoutRate, math.Round(metrics.SearchClickoutRate*100)/100)
		result.FreshlooksClickoutRate = append(result.FreshlooksClickoutRate, math.Round(metrics.FreshlooksClickoutRate*100)/100)
		result.EngagementActionsPerUser = append(result.EngagementActionsPerUser, math.Round(metrics.EngagementActionsPerUser*100)/100)
		result.ReturnRate = append(result.ReturnRate, metrics.ReturnRate)
		result.NotificationsOpenRate = append(result.NotificationsOpenRate, metrics.NotificationsOpenRate)
		result.ProductCount = metrics.ProductCount
		result.BrandCount = metrics.BrandCount
		result.NewProductCount = append(result.NewProductCount, metrics.NewProductCount)
		result.Checkouts = append(result.Checkouts, metrics.Checkouts)
		result.GMV = append(result.GMV, metrics.GMV)
		result.ThreeMonthRetentionRate = metrics.ThreeMonthRetentionRate
	}

	result.Searches = a.mergeSearchTerms(result.Searches)
	result.EmptySearches = a.mergeSearchTerms(result.EmptySearches)

	result.EngagementActionsPerUserMean = math.Round(getMean(result.EngagementActionsPerUser)*100) / 100
	result.SearchClickoutRateMean = math.Round(getMean(result.SearchClickoutRate)*100) / 100
	result.FreshlooksClickoutRateMean = math.Round(getMean(result.FreshlooksClickoutRate)*100) / 100
	result.NotificationsOpenRateMean = math.Round(getMean(result.NotificationsOpenRate)*100) / 100
	result.CheckoutsTotal = sum(result.Checkouts)
	result.GMVTotal = sumFloat64(result.GMV)

	prevNewUsersCount := 0
	prevTotalUsersCount := 0
	prevActiveNewUsersCount := 0
	prevActiveUsersCount := 0
	prevSessionsCount := 0
	prevSearchesCount := 0
	prevNotificationsSentCount := 0
	prevNotificationsOpenCount := 0
	prevEngagementActionsPerUser := []float64{}
	prevSearchClickoutRate := []float64{}
	prevFreshlooksClickoutRate := []float64{}
	prevCheckouts := 0
	prevGMV := 0.0
	for d := startDate.AddDate(0, 0, -daysDiff); d.Before(endDate.AddDate(0, 0, -daysDiff)); d = d.AddDate(0, 0, 1) {
		metrics, err := a.fetchMetricsForDate(d)
		if err != nil {
			log.Error(err)
			continue
		}

		prevNewUsersCount += metrics.NewUsersCount
		prevTotalUsersCount += metrics.TotalUsersCount
		prevActiveNewUsersCount += metrics.ActiveNewUsersCount
		prevActiveUsersCount += metrics.ActiveUsersCount
		prevSessionsCount += metrics.SessionsCount
		prevSearchesCount += metrics.SearchesCount
		prevNotificationsSentCount += metrics.NotificationsSentCount
		prevNotificationsOpenCount += metrics.NotificationsOpenCount
		prevEngagementActionsPerUser = append(prevEngagementActionsPerUser, metrics.EngagementActionsPerUser)
		prevSearchClickoutRate = append(prevSearchClickoutRate, metrics.SearchClickoutRate)
		prevFreshlooksClickoutRate = append(prevFreshlooksClickoutRate, metrics.FreshlooksClickoutRate)
		prevCheckouts += metrics.Checkouts
		prevGMV += metrics.GMV
	}

	if prevNewUsersCount != 0 {
		result.NewUsersCountDiff = getDiff(prevNewUsersCount, result.NewUsersCount)
	}

	if prevTotalUsersCount != 0 {
		result.TotalUsersCountDiff = getDiff(prevTotalUsersCount, result.TotalUsersCount)
	}

	if prevActiveNewUsersCount != 0 {
		result.ActiveNewUsersCountDiff = getDiff(prevActiveNewUsersCount, result.ActiveNewUsersCount)
	}

	if prevActiveUsersCount != 0 {
		result.ActiveUsersCountDiff = getDiff(prevActiveUsersCount, result.ActiveUsersCount)
	}

	if prevSessionsCount != 0 {
		result.SessionsCountDiff = getDiff(prevSessionsCount, result.SessionsCount)
	}

	if prevSearchesCount != 0 {
		result.SearchesCountDiff = getDiff(prevSearchesCount, result.SearchesCount)
	}

	if prevNotificationsSentCount != 0 {
		result.NotificationsSentCountDiff = getDiff(prevNotificationsSentCount, result.NotificationsSentCount)
	}

	if prevNotificationsOpenCount != 0 {
		result.NotificationsOpenCountDiff = getDiff(prevNotificationsOpenCount, result.NotificationsOpenCount)
	}

	if len(prevEngagementActionsPerUser) > 0 {
		result.EngagementActionsPerUserDiff = getFloat64Diff(getMean(prevEngagementActionsPerUser), result.EngagementActionsPerUserMean)
	}

	if len(prevSearchClickoutRate) > 0 {
		result.SearchClickoutRateDiff = getFloat64Diff(getMean(prevSearchClickoutRate), result.SearchClickoutRateMean)
	}

	if len(prevFreshlooksClickoutRate) > 0 {
		result.FreshlooksClickoutRateDiff = getFloat64Diff(getMean(prevFreshlooksClickoutRate), result.FreshlooksClickoutRateMean)
	}

	if prevCheckouts != 0 {
		result.CheckoutsTotalDiff = getDiff(prevCheckouts, result.CheckoutsTotal)
	}

	if prevGMV != 0 {
		result.GMVTotalDiff = getFloat64Diff(prevGMV, result.GMVTotal)
	}

	return result, nil
}

func getMean(vals []float64) float64 {
	sum := 0.0
	for _, v := range vals {
		sum += v
	}
	return sum / float64(len(vals))
}

func sum(vals []int) int {
	sum := 0
	for _, v := range vals {
		sum += v
	}
	return sum
}

func sumFloat64(vals []float64) float64 {
	sum := 0.0
	for _, v := range vals {
		sum += v
	}
	return sum
}

func getFloat64Diff(old, new float64) int {
	return -int(100.0 * (1.0 - (new / old)))
}

func getDiff(old, new int) int {
	return -int(100.0 * (1.0 - (float32(new) / float32(old))))
}

func (a *Analytics) mergeSearchTerms(terms []*SearchTermValue) []*SearchTermValue {
	counts := map[string]int{}
	for i := range terms {
		term := terms[i]
		if _, ok := counts[term.Term]; !ok {
			counts[term.Term] = 0
		}
		counts[term.Term] += term.Count
	}

	result := []*SearchTermValue{}
	for k, v := range counts {
		result = append(result, &SearchTermValue{Term: k, Count: v})
	}

	sort.Sort(ByTermCount(result))

	return result
}

func (a *Analytics) fetchMetricsForDate(date time.Time) (*Metrics, error) {
	key := date.Format(dateLayout)
	// check memory first
	if metrics, ok := a.metrics[key]; ok {
		return metrics, nil
	}

	tmpPath := "/tmp/" + key
	if err := gcs.DownloadObject(gcsBucket, gcsKeyPrefix+key, tmpPath); err != nil {
		return nil, err
	}

	data, err := ioutil.ReadFile(tmpPath)
	if err != nil {
		return nil, err
	}

	var metrics *Metrics
	if err := json.Unmarshal(data, &metrics); err != nil {
		return nil, err
	}

	// TODO lock!
	a.metrics[key] = metrics

	return metrics, nil
}

type ByTermCount []*SearchTermValue

func (s ByTermCount) Len() int {
	return len(s)
}

func (s ByTermCount) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

func (s ByTermCount) Less(i, j int) bool {
	return s[i].Count > s[j].Count
}

func meanSlice(slice []float32) float32 {
	total := float32(0.0)
	for _, v := range slice {
		total += v
	}
	return total / float32(len(slice))
}
