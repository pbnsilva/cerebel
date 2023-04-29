.DEFAULT_GOAL := help

GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/))
NAME=$(notdir $(patsubst %/,%,$(dir $(path))))-cluster
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make deploy             - deploys the service"

.PHONY: deploy
deploy:
	@echo "${GREEN}Deploying service $(TAG)${NC}"
	@kubectl apply -f deployment.yaml
	@echo "${GREEN}Deployed $(TAG) ${NC}"
