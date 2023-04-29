package pkg

import (
	"github.com/petard/cerebel/shared/config"
)

// SearchTeasersJobConfig holds the service configuration.
type SearchTeasersJobConfig struct {
	*config.Base
}

// NewSearchTeasersJobConfig returns a new SearchTeasersJobConfig instance.
func NewSearchTeasersJobConfig() (*SearchTeasersJobConfig, error) {
	cfg := &SearchTeasersJobConfig{
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
