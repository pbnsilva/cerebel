package service

import "github.com/petard/cerebel/shared/config"

type Config struct {
	*config.Base
}

func NewConfig() (*Config, error) {
	cfg := &Config{
		Base: config.NewBase(),
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
