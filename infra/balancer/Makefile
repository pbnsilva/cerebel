.DEFAULT_GOAL := build

GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/))
NAME=balancer
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make clean              - clean service binaries"
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-run         - runs the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"
	@echo "make deploy             - deploys the service"

clean:
	@echo "${GREEN}Cleaning $(NAME) service${NC}"

docker-build:
	@echo "${GREEN}Building $(NAME) ${NC}"
	@docker build -t $(TAG) . 

docker-run:
	@echo "${GREEN}Running $(NAME) ${NC}"
	@docker run -t $(TAG) 

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

.PHONY: help clean docker-build docker-push deploy
