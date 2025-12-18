.PHONY: help lint build smoke-test

SIF ?= warptools_cuda118.sif
DEF ?= apptainer/warptools_cuda118.def

help:
	@echo "Targets:"
	@echo "  make lint        - basic repo linting (shellcheck/yamllint if installed)"
	@echo "  make build       - build the Apptainer image to $(SIF)"
	@echo "  make smoke-test  - run basic checks using the built image"

lint:
	./scripts/lint.sh

build:
	./scripts/build.sh "$(DEF)" "$(SIF)"

smoke-test:
	./scripts/test.sh "$(SIF)"
