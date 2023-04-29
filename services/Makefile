.DEFAULT_GOAL := build

TOPTARGETS := build clean

GREEN=\033[0;32m
NC=\033[0m

SUBDIRS := $(filter-out face/cmd/srv/, $(wildcard */cmd/srv/))
SUBDIRS += annotation/

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

help:
	@echo "make                    - build services binaries"
	@echo "make clean              - clean services binaries"

.PHONY: $(TOPTARGETS) $(SUBDIRS) help
