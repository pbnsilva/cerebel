.DEFAULT_GOAL := build 

PROJECT_PATH=$(GOPATH)/src/github.com/petard/cerebel
GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/../../))
NAME=suggesterindexer
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make          				   - builds the binaries"
	@echo "make clean              - cleans the binaries"
	@echo "make docker-run         - runs the job"
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"
	@echo "make deploy             - deploys the job"

build:
	@go build -o bin/cmd main.go

run:
	go run main.go

clean:
	@go clean
	@rm -rf bin

docker-build: 
	@echo "${GREEN}Building image $(TAG)${NC}"
	@mkdir -p tmp/jobs/$(NAME)/pkg
	@mkdir -p tmp/jobs/$(NAME)/cmd
	@cp $(PROJECT_PATH)/Gopkg.toml tmp/
	@cp $(PROJECT_PATH)/jobs/$(NAME)/pkg/*.go tmp/jobs/$(NAME)/pkg/
	@cp $(PROJECT_PATH)/jobs/$(NAME)/cmd/*.go tmp/jobs/$(NAME)/cmd/
	@cp -r $(PROJECT_PATH)/shared tmp/ 
	@docker build -t $(TAG) . 
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
	@sed 's/_SHA_/$(SHA)/g' deployment.yaml > deployment.tmp.yaml
	@kubectl apply -f deployment.tmp.yaml
	@rm deployment.tmp.yaml
	@echo "${GREEN}Deployed $(NAME) with hash $(SHA) ${NC}"

.PHONY: help run docker-build docker-push deploy
