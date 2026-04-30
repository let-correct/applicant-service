package applicant

import (
	"context"
	"log/slog"

	"github.com/aws/aws-lambda-go/events"

	appapplicant "github.com/troysnowden/applicant-service/internal/application/applicant"
)

type processor interface {
	Handle(ctx context.Context, cmd appapplicant.Command) error
}

type Handler struct {
	logger    *slog.Logger
	processor processor
}

func New(logger *slog.Logger, processor processor) *Handler {
	return &Handler{logger: logger, processor: processor}
}

func (h *Handler) Handle(ctx context.Context, event events.SQSEvent) (events.SQSEventResponse, error) {
	var resp events.SQSEventResponse

	for _, record := range event.Records {
		if err := h.processRecord(ctx, record); err != nil {
			h.logger.ErrorContext(ctx, "failed to process record",
				"messageId", record.MessageId,
				"error", err,
			)
			resp.BatchItemFailures = append(resp.BatchItemFailures, events.SQSBatchItemFailure{
				ItemIdentifier: record.MessageId,
			})
		}
	}

	return resp, nil
}

func (h *Handler) processRecord(ctx context.Context, record events.SQSMessage) error {
	h.logger.InfoContext(ctx, "received message", "messageId", record.MessageId)
	return h.processor.Handle(ctx, appapplicant.Command{})
}
