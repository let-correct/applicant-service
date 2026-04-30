package applicant

import "context"

type Command struct{}

type ProcessViewing struct{}

func NewProcessViewing() *ProcessViewing {
	return &ProcessViewing{}
}

func (s *ProcessViewing) Handle(_ context.Context, _ Command) error {
	return nil
}
