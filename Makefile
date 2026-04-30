test:
	go test ./...

push-applicant-viewing-processor:
	./scripts/push-to-ecr.sh $$(git rev-parse --short HEAD) applicant-viewing-processor

push-all:
	$(MAKE) push-applicant-viewing-processor
