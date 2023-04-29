.DEFAULT_GOAL := build

PROJECT_PATH=$(GOPATH)/src/github.com/petard/cerebel
GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/../../))
NAME=$(notdir $(patsubst %/,%,$(dir $(path))))
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make                    - build service binaries"
	@echo "make run                - runs the service"
	@echo "make clean              - clean service binaries"
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"
	@echo "make deploy             - deploys the service"

build:
	@echo "${GREEN}Building $(NAME) service${NC}"
	@CGO_ENABLED=1 GOOS=linux GOARCH=amd64 GOBIN=$(GOBIN) go build -o bin/$(NAME) $(GOFILES)

run:
	@GOBIN=$(GOBIN) go run $(GOFILES)

clean:
	@echo "${GREEN}Cleaning $(NAME) service${NC}"
	@GOBIN=$(GOBIN) go clean
	@rm -rf $(GOBIN) tmp

docker-build: 
	@echo "${GREEN}Building image $(TAG)${NC}"
	@mkdir -p tmp/services/$(NAME)
	@cp $(PROJECT_PATH)/Gopkg.toml tmp/
	@cp -r $(PROJECT_PATH)/shared tmp/ 
	@cp -r $(PROJECT_PATH)/services/$(NAME)/pkg tmp/services/$(NAME)/
	@cp $(PROJECT_PATH)/services/$(NAME)/cmd/srv/main.go tmp/services/$(NAME)/
	docker build -t $(TAG) .
	@rm -r tmp

docker-push:
	@echo "${GREEN}Pushing image $(TAG)${NC}"
	@docker push $(TAG)

deploy: docker-build docker-push
	@echo "${GREEN}Deploying service $(TAG)${NC}"
	$(eval SHA=$(shell docker image inspect $(TAG):latest | jq -r '.[0].RepoDigests[0]' | cut -d':' -f 2))
	@sed 's/_SHA_/$(SHA)/g' deployment.yaml > deployment.tmp.yaml
	@kubectl apply -f deployment.tmp.yaml
	@rm deployment.tmp.yaml
	@echo "${GREEN}Deployed $(NAME) with hash $(SHA) ${NC}"

.PHONY: help build run clean docker-build docker-push deploy
