package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/aws/aws-lambda-go/lambda"

	appapplicant "github.com/troysnowden/applicant-service/internal/application/applicant"
	"github.com/troysnowden/applicant-service/internal/config"
	handlerapplicant "github.com/troysnowden/applicant-service/internal/handler/applicant"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: logLevel(cfg.LogLevel),
	}))

	ctx := context.Background()

	processor := appapplicant.NewProcessViewing()
	h := handlerapplicant.New(logger, processor)

	lambda.StartWithOptions(h.Handle, lambda.WithContext(ctx))
}

func logLevel(level string) slog.Level {
	switch level {
	case "DEBUG":
		return slog.LevelDebug
	case "WARN":
		return slog.LevelWarn
	case "ERROR":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
