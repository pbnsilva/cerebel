.DEFAULT_GOAL := build 

PROJECT_PATH=../../../
GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/../../))
NAME=searchteasers
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make          				   - builds the binaries"
	@echo "make clean              - cleans the binaries"
	@echo "make docker-run         - runs the job"
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"
	@echo "make deploy             - deploys the job"

build:
	@CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o bin/$(NAME) $(GOFILES)

run:
	go run main.go

clean:
	@go clean
	@rm -rf bin

docker-build:
	@echo "${GREEN}Building image $(TAG)${NC}"
	@mkdir -p tmp/jobs/$(NAME)
	@cp $(PROJECT_PATH)/go.mod tmp/ 
	@cp $(PROJECT_PATH)/go.sum tmp/ 
	@cp -r $(PROJECT_PATH)/shared tmp/ 
	@cp -r $(PROJECT_PATH)/jobs/$(NAME)/pkg tmp/jobs/$(NAME)/
	@cp $(PROJECT_PATH)/jobs/$(NAME)/cmd/main.go tmp/jobs/$(NAME)/
	docker build -t $(TAG) .
	@rm -r tmp

docker-run:
	@echo "${GREEN}Running service $(TAG)${NC}"
	@docker run $(TAG)

docker-push:
	@echo "${GREEN}Pushing image $(TAG)${NC}"
	@docker push $(TAG)

deploy: docker-build docker-push
	@echo "${GREEN}Deploying job $(TAG)${NC}"
	$(eval SHA=$(shell docker image inspect $(TAG):latest | jq -r '.[0].RepoDigests[0]' | cut -d':' -f 2))
	@sed 's/_SHA_/$(SHA)/g' cronjob.yaml > cronjob.tmp.yaml
	@kubectl apply -f cronjob.tmp.yaml
	@rm cronjob.tmp.yaml
	@echo "${GREEN}Deployed $(NAME) with hash $(SHA) ${NC}"

.PHONY: help run docker-build docker-push deploy
