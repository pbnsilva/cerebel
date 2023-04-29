package shared

import (
	"github.com/petard/cerebel/shared/config"
)

type DashboardConfig struct {
	*config.Base
	SearchHost     string `env:"search_host"`
	SearchBetaHost string `env:"search_beta_host"`
	FeedHost       string `env:"feed_host"`
	SuggesterHost  string `env:"suggester_host"`
	HomeBaseURL    string `env:"home_base_url"`
	CID            string `env:"cid"`
	CSecret        string `env:"csecret"`
	ScrapydHost    string `env:"scrapyd_host"`
}

func NewDashboardConfig() (*DashboardConfig, error) {
	cfg := &DashboardConfig{
		Base:          config.NewBase(),
		FeedHost:      "localhost:9093",
		ScrapydHost:   "localhost:6800",
		SuggesterHost: "http://localhost:8086",
		HomeBaseURL:   "http://localhost:8080",
	}

	if err := config.BindFromEnv(cfg); err != nil {
		return nil, err
	}

	// required to bind fields outside Base
	if err := config.BindFromEnv(cfg.Base); err != nil {
		return nil, err
	}

	return cfg, nil
}

func (cfg *DashboardConfig) GetHomeBaseURL() string {
	return cfg.HomeBaseURL
}

func (cfg *DashboardConfig) GetSearchHost() string {
	return cfg.SearchHost
}

func (cfg *DashboardConfig) GetSearchBetaHost() string {
	return cfg.SearchBetaHost
}

func (cfg *DashboardConfig) GetFeedHost() string {
	return cfg.FeedHost
}

func (cfg *DashboardConfig) GetSuggesterHost() string {
	return cfg.SuggesterHost
}

func (cfg *DashboardConfig) GetCID() string {
	return cfg.CID
}

func (cfg *DashboardConfig) GetCSecret() string {
	return cfg.CSecret
}

func (cfg *DashboardConfig) GetScrapydHost() string {
	return cfg.ScrapydHost
}
