.DEFAULT_GOAL := build

GOBIN=$(shell pwd)/bin
GOFILES=$(wildcard *.go)
GREEN=\033[0;32m
NC=\033[0m
path=$(abspath $(lastword $(MAKEFILE_LIST)/))
NAME=$(notdir $(patsubst %/,%,$(dir $(path))))
TAG=eu.gcr.io/cerebel-prod/$(NAME)

help:
	@echo "make                    - build service binaries"
	@echo "make run                - runs the service"
	@echo "make clean              - clean service binaries"
	@echo "make docker-build       - builds the docker image"
	@echo "make docker-push        - pushes the docker image to the registry"

build: clean
	@echo "${GREEN}Building $(NAME) service${NC}"
	@cp -r ../../ml .
	@cd ml && make clean

run:
	@python run.py

clean:
	@echo "${GREEN}Cleaning $(NAME) service${NC}"
	@rm -rf ml
	@rm -rf __pycache__

docker-build: build
	@echo "${GREEN}Building image $(TAG)${NC}"
	docker build -t $(TAG) . 

docker-push:
	@echo "${GREEN}Pushing image $(TAG)${NC}"
	@docker push $(TAG)

.PHONY: help build run clean docker-build docker-push
