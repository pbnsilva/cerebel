package config

type Configer interface {
	GetBase() *Base
	GetEnvironment() string
	IsProductionEnvironment() bool
	GetDataPath() string
	GetGCSBucket() string
	GetHTTPPort() int
	GetGRPCPort() int
	GetPrometheusPort() int
	GetElasticHost() string
	GetSearchHost() string
	GetStoreHost() string
	GetAnnotationHost() string
	GetRedisHost() string
}

// Base holds configuration settings shared by multiple services
type Base struct {
	// dev or prod environments
	Environment string `env:"env"`

	// data path on local
	DataPath string `env:"data_path"`

	GCSBucket string `env:"gcs_bucket"`

	// access ports
	HTTPPort int `env:"http_port"`
	GRPCPort int `env:"grpc_port"`

	// metrics port
	PrometheusPort int `env:"prometheus_port"`

	// elasticsearch host
	ElasticHost string `env:"elastic_host"`

	// other services hosts
	SearchHost     string `env:"search_host"`
	StoreHost      string `env:"store_host"`
	AnnotationHost string `env:"annotation_host"`

	// Redis
	RedisHost string `env:"redis_host"`
}

func NewBase() *Base {
	return &Base{
		Environment:    "dev",
		DataPath:       "/data",
		GCSBucket:      "data.cerebel.io",
		HTTPPort:       8080,
		GRPCPort:       9090,
		ElasticHost:    "http://localhost:9200",
		StoreHost:      "localhost:9090",
		AnnotationHost: "localhost:9092",
		RedisHost:      "localhost:6379",
	}
}

func (c *Base) GetBase() *Base {
	return c
}

func (c *Base) GetEnvironment() string {
	return c.Environment
}

func (c *Base) IsProductionEnvironment() bool {
	return c.Environment == "prod"
}

func (c *Base) GetDataPath() string {
	return c.DataPath
}

func (c *Base) GetGCSBucket() string {
	return c.GCSBucket
}

func (c *Base) GetHTTPPort() int {
	return c.HTTPPort
}

func (c *Base) GetGRPCPort() int {
	return c.GRPCPort
}

func (c *Base) GetPrometheusPort() int {
	return c.PrometheusPort
}

func (c *Base) GetElasticHost() string {
	return c.ElasticHost
}

func (c *Base) GetSearchHost() string {
	return c.SearchHost
}

func (c *Base) GetStoreHost() string {
	return c.StoreHost
}

func (c *Base) GetAnnotationHost() string {
	return c.AnnotationHost
}

func (c *Base) GetRedisHost() string {
	return c.RedisHost
}
