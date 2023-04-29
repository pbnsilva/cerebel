.DEFAULT_GOAL := build

help:
	@echo "make                    - build package"
	@echo "make install            - installs the package"
	@echo "make clean              - clean package binaries"

build:
	@python setup.py build

install:
	@python setup.py install

clean:
	@rm -rf build
	@rm -rf cerebel.egg-info
	@rm -rf dist
	@rm -rf notebooks/.ipynb_checkpoints

.PHONY: help build install clean
