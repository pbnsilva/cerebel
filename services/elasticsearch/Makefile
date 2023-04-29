.DEFAULT_GOAL := help

GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/))
NAME=$(notdir $(patsubst %/,%,$(dir $(path))))-cluster
TAG=eu.gcr.io/cerebel-prod/$(NAME)
DEPLOYMENT=stateful.deployment.yaml
DEPLOYMENT_OUT=tmp.$(DEPLOYMENT)

help:
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"
	@echo "make deploy             - deploys the service"

.PHONY: docker-build
docker-build:
	@echo "${GREEN}Building image $(TAG)${NC}"
	@docker build -t $(TAG) .

.PHONY: docker-push
docker-push:
	@echo "${GREEN}Pushing image $(TAG)${NC}"
	@docker push $(TAG)

.PHONY: deploy
deploy: docker-build docker-push
	@echo "${GREEN}Deploying service $(TAG)${NC}"
	@sed 's/_IMAGE_/$(NAME)/g' $(DEPLOYMENT) > $(DEPLOYMENT_OUT)
	@kubectl apply -f $(DEPLOYMENT_OUT)
	@rm $(DEPLOYMENT_OUT)
	@echo "${GREEN}Deployed $(TAG) ${NC}"
