package pkg

import "github.com/petard/cerebel/shared/config"

// IndexerJobConfig holds the service configuration.
type IndexerJobConfig struct {
	*config.Base
	IndexImages bool
}

// NewIndexerJobConfig returns a new IndexerJobConfig instance.
func NewIndexerJobConfig() (*IndexerJobConfig, error) {
	cfg := &IndexerJobConfig{
		Base:        config.NewBase(),
		IndexImages: true,
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
