package pkg

import (
	"github.com/petard/cerebel/shared/config"
)

// StatsUpdaterJobConfig holds the service configuration.
type StatsUpdaterJobConfig struct {
	*config.Base
}

// NewStatsUpdaterJobConfig returns a new StatsUpdaterJobConfig instance.
func NewStatsUpdaterJobConfig() (*StatsUpdaterJobConfig, error) {
	cfg := &StatsUpdaterJobConfig{
		Base: config.NewBase(),
	}

	// override default port
	cfg.Base.HTTPPort = 8081
	cfg.Base.GRPCPort = 9090

	if err := config.BindFromEnv(cfg); err != nil {
		return nil, err
	}

	// required to bind fields outside Base
	if err := config.BindFromEnv(cfg.Base); err != nil {
		return nil, err
	}

	return cfg, nil
}
