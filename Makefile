test:
	go test ./...

push-applicant:
	./scripts/push-to-ecr.sh $$(git rev-parse --short HEAD) applicant

push-all:
	$(MAKE) push-applicant
