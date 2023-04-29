.DEFAULT_GOAL := docker-build 

PROJECT_PATH=$(GOPATH)/src/github.com/petard/cerebel
GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/../../))
NAME=scrapers
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make docker-run         - runs the service"
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"
	@echo "make deploy-cronjob     - deploys the cronjob"
	@echo "make deploy-spiders     - deploys the spiders"

run:
	./run.sh

clean:
	@rm -rf __pycache__
	@rm -rf build
	@rm -rf project.egg-info
	@rm -rf scrapers/spiders/__pycache__

docker-build: 
	@echo "${GREEN}Building image $(TAG)${NC}"
	@docker build -t $(TAG) . 

docker-run:
	@echo "${GREEN}Running $(TAG)${NC}"
	@docker run $(TAG)

docker-push:
	@echo "${GREEN}Pushing image $(TAG)${NC}"
	@docker push $(TAG)

deploy-cronjob: docker-build docker-push
	@echo "${GREEN}Deploying job $(TAG)${NC}"
	$(eval SHA=$(shell docker image inspect $(TAG):latest | jq -r '.[0].RepoDigests[0]' | cut -d':' -f 2))
	@sed 's/_SHA_/$(SHA)/g' cronjob.yaml > cronjob.tmp.yaml
	@kubectl apply -f cronjob.tmp.yaml
	@rm cronjob.tmp.yaml
	@echo "${GREEN}Deployed $(NAME) with hash $(SHA) ${NC}"

deploy-spiders:
	@scrapyd-deploy

.PHONY: help run docker-build docker-push deploy-cronjob deploy-spiders
