package search

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/monitoring"
	"github.com/petard/cerebel/shared/service"
)

const (
	monitoringNamespace              = "search"
	monitoringTextSearchHandlerName  = "text"
	monitoringImageSearchHandlerName = "image"
	monitoringItemHandlerName        = "item"
	monitoringSuggestHandlerName     = "suggest"
	monitoringTeasersHandlerName     = "teasers"
)

func (s *Service) rootHandlers(v *gin.RouterGroup) {
	v.GET(fmt.Sprintf("/store/:%s/suggest", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.suggestV3, monitoringNamespace, monitoringSuggestHandlerName))
}

func (s *Service) v2Handlers(v *gin.RouterGroup) {
	v.POST(fmt.Sprintf("/store/:%s/search/text", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.searchByTextV2, monitoringNamespace, monitoringTextSearchHandlerName))
	v.GET(fmt.Sprintf("/store/:%s/item/:id", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.getItemByIDV2, monitoringNamespace, monitoringItemHandlerName))
}

func (s *Service) v3Handlers(v *gin.RouterGroup) {
	v.POST(fmt.Sprintf("/store/:%s/search/text", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.searchByTextV3, monitoringNamespace, monitoringTextSearchHandlerName))
	v.GET(fmt.Sprintf("/store/:%s/item/:id", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.getItemByIDV3, monitoringNamespace, monitoringItemHandlerName))
	v.GET(fmt.Sprintf("/store/:%s/suggest", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.suggestV3, monitoringNamespace, monitoringSuggestHandlerName))
	v.GET(fmt.Sprintf("/store/:%s/item/:id/stats", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.getItemStats, monitoringNamespace, monitoringItemHandlerName))
	v.GET(fmt.Sprintf("/store/:%s/search/teasers", service.AuthStoreIDContextParam),
		monitoring.InstrumentHandler(s.getTeasers, monitoringNamespace, monitoringTeasersHandlerName))
}
