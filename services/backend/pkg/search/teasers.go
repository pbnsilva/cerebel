package search

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/es"
	"github.com/petard/cerebel/shared/log"
	product "github.com/petard/cerebel/shared/product.v3"
	shared_search "github.com/petard/cerebel/shared/search"
	"github.com/petard/cerebel/shared/service"
	"github.com/petard/cerebel/shared/time"
)

const (
	storeID = "faer"

	latParamName      = "lat"
	lonParamName      = "lon"
	distanceParamName = "distance"
	defaultDistance   = "50km"

	distanceRegex = "^[0-9]+(m|km)"

	maxNearbyShops = 20
)

func (s *Service) getTeasers(ctx *gin.Context) {
	startTime := time.NowInMilliseconds()

	query := ctx.Request.URL.Query()

	gender := strings.ToLower(query.Get(genderParamName))
	if gender != "men" && gender != "women" {
		ctx.JSON(http.StatusBadRequest, service.NewErrorResponse("invalid gender"))
		return
	}

	data, err := s.statsStore.GetSearchTeasers(gender)
	if err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	var teasers []*shared_search.TeaserGroup
	if err := json.Unmarshal(data.([]byte), &teasers); err != nil {
		log.Error(err)
		ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
		return
	}

	latQ := query.Get(latParamName)
	lonQ := query.Get(lonParamName)
	distance := query.Get(distanceParamName)
	if latQ != "" && lonQ != "" {
		lat, err := strconv.ParseFloat(latQ, 32)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusBadRequest, service.NewErrorResponse(err.Error()))
			return
		}

		lon, err := strconv.ParseFloat(lonQ, 32)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusBadRequest, service.NewErrorResponse(err.Error()))
			return
		}

		if distance == "" {
			distance = defaultDistance
		}

		if !isValidDistance(distance) {
			log.Error(err)
			ctx.JSON(http.StatusBadRequest, service.NewErrorResponse(err.Error()))
			return
		}

		shops, err := s.getNearbyShops(ctx, &es.Location{Lat: float32(lat), Lon: float32(lon)}, distance)
		if err != nil {
			log.Error(err)
			ctx.JSON(http.StatusInternalServerError, service.NewErrorResponse(err.Error()))
			return
		}

		for _, grp := range teasers {
			if grp.Type == shared_search.MapTeaserType {
				grp.Items = shops
				break
			}
		}
	} else {
		for _, grp := range teasers {
			if grp.Type == shared_search.MapTeaserType {
				grp.Error = "missing lat/lon"
				break
			}
		}
	}

	response := shared_search.NewTeasersResponse()
	response.WithID()
	response.Items = teasers
	response.Took = time.NowInMilliseconds() - startTime

	ctx.Writer.Header().Set("Cache-Control", "private, max-age=900")
	ctx.JSON(http.StatusOK, response)
}

func (s *Service) getNearbyShops(ctx context.Context, location *es.Location, distance string) ([]*shared_search.BrandShop, error) {
	size := 0
	filtersRaw := json.RawMessage(fmt.Sprintf(`{"distance": "%s", "location": {"lat": %f, "lon": %f}}`, distance, location.Lat, location.Lon))
	baseRequest := &shared_search.BaseRequest{
		Filters: map[string]*json.RawMessage{
			"store_locations": &filtersRaw,
		},
		Aggregations: &shared_search.AggregationsQuery{
			CountQuery: &shared_search.CountAggregationsQuery{
				Fields:  []string{"brand"},
				TopHits: 1,
			},
		},
		Size: &size,
	}

	request := &shared_search.TextRequest{
		BaseRequest: baseRequest,
	}

	// create connection to elasticsearch
	esClient, err := es.NewSimpleClient(s.cfg.GetElasticHost())
	if err != nil {
		return nil, err
	}

	store, err := product.NewESStore(storeID, esClient)
	if err != nil {
		return nil, err
	}

	engine := shared_search.NewESEngine(store)
	result, err := engine.Search(ctx, &shared_search.AnnotatedTextRequest{TextRequest: request}, false)
	if err != nil {
		return nil, err
	}

	distanceMeters := convertDistanceToMeters(distance)

	shops := []*shared_search.BrandShop{}
	i := 0
	for {
		for _, bucket := range result.Aggregations["count_brand"].Buckets {
			hit := bucket.TopHits.Hits.Hits[0].Item
			if i >= len(hit.Shops) {
				break
			}

			store := hit.Shops[i]
			if getDistanceInMeters(float64(location.Lat), float64(location.Lon), float64(store.Location.Lat), float64(store.Location.Lon)) > distanceMeters {
				break
			}
			shops = append(shops, &shared_search.BrandShop{
				Brand:      bucket.Key,
				Name:       store.Name,
				Country:    store.Country,
				City:       store.City,
				PostalCode: store.PostalCode,
				Location:   store.Location,
				Address:    store.Address,
			})

			if len(shops) == maxNearbyShops {
				break
			}
		}

		if len(shops) == maxNearbyShops {
			break
		}

		i += 1
		fmt.Println(i)
		if i >= maxNearbyShops {
			break
		}
	}

	return shops, nil
}

func convertDistanceToMeters(value string) float64 {
	if value[len(value)-2:len(value)] == "km" {
		val := value[:len(value)-2]
		floatVal, _ := strconv.ParseFloat(val, 64)
		return float64(floatVal) * 1000
	}

	val := value[:len(value)-1]
	floatVal, _ := strconv.ParseFloat(val, 64)
	return float64(floatVal)
}

func isValidDistance(value string) bool {
	match, _ := regexp.MatchString(distanceRegex, value)
	return match
}

// haversin(θ) function
func hsin(theta float64) float64 {
	return math.Pow(math.Sin(theta/2), 2)
}

// Distance function returns the distance (in meters) between two points of
//     a given longitude and latitude relatively accurately (using a spherical
//     approximation of the Earth) through the Haversin Distance Formula for
//     great arc distance on a sphere with accuracy for small distances
//
// point coordinates are supplied in degrees and converted into rad. in the func
//
// distance returned is METERS!!!!!!
// http://en.wikipedia.org/wiki/Haversine_formula
func getDistanceInMeters(lat1, lon1, lat2, lon2 float64) float64 {
	// convert to radians
	// must cast radius as float to multiply later
	var la1, lo1, la2, lo2, r float64
	la1 = lat1 * math.Pi / 180
	lo1 = lon1 * math.Pi / 180
	la2 = lat2 * math.Pi / 180
	lo2 = lon2 * math.Pi / 180

	r = 6378100 // Earth radius in METERS

	// calculate
	h := hsin(la2-la1) + math.Cos(la1)*math.Cos(la2)*hsin(lo2-lo1)

	return 2 * r * math.Asin(math.Sqrt(h))
}
