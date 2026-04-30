package config

import "github.com/caarlos0/env/v11"

type Config struct {
	LogLevel       string `env:"LOG_LEVEL" envDefault:"INFO"`
	TokenTableName string `env:"TOKEN_TABLE_NAME,required"`
	KMSKeyARN      string `env:"KMS_KEY_ARN,required"`
}

func Load() (Config, error) {
	var cfg Config
	return cfg, env.Parse(&cfg)
}
