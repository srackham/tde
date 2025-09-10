MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := test
.DELETE_ON_ERROR:
.SUFFIXES:
.ONESHELL:

.PHONY: test
test:
	shellcheck tde
	shellcheck test-tde.sh
	make fmt
	./test-tde.sh

.PHONY: fmt
fmt:
	shfmt -i 4 -w tde
	shfmt -i 4 -w test-tde.sh
