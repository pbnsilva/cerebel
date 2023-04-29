package monitoring

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/service"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func StartPrometheus(port int) {
	go func() {
		http.Handle("/metrics", promhttp.Handler())
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", port), nil))
	}()
}

func InstrumentHandler(handler gin.HandlerFunc, namespace, handlerName string) gin.HandlerFunc {
	durationSummary := prometheus.NewSummaryVec(prometheus.SummaryOpts{
		Namespace: namespace,
		Name:      "api_request_duration_ms",
		Help:      "Time in milliseconds spent in API code while processing the request",
	}, []string{"store_id", "handler", "code"})

	requestsCounter := prometheus.NewCounterVec(prometheus.CounterOpts{
		Namespace: namespace,
		Name:      "api_request_count",
		Help:      "Total number of API requests",
	}, []string{"store_id", "handler", "code"})

	responseTimeMilliseconds := mustRegisterOrGet(durationSummary).(*prometheus.SummaryVec)
	requestsTotal := mustRegisterOrGet(requestsCounter).(*prometheus.CounterVec)

	return func(ctx *gin.Context) {
		startedAt := time.Now()

		handler(ctx)

		storeID, _ := service.GetAuthStoreIDFromGinContext(ctx)

		duration := float64(time.Since(startedAt) / time.Millisecond)

		responseTimeMilliseconds.With(
			prometheus.Labels{
				"store_id": storeID,
				"handler":  handlerName,
				"code":     fmt.Sprintf("%d", ctx.Writer.Status()),
			}).Observe(duration)

		requestsTotal.With(
			prometheus.Labels{
				"store_id": storeID,
				"handler":  handlerName,
				"code":     fmt.Sprintf("%d", ctx.Writer.Status()),
			}).Inc()
	}
}

func mustRegisterOrGet(c prometheus.Collector) prometheus.Collector {
	c, err := registerOrGet(c)
	if err != nil {
		panic(err)
	}
	return c
}

func registerOrGet(c prometheus.Collector) (prometheus.Collector, error) {
	if err := prometheus.Register(c); err != nil {
		if are, ok := err.(prometheus.AlreadyRegisteredError); ok {
			return are.ExistingCollector, nil
		}
		return nil, err
	}
	return c, nil
}
