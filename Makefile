SHELL = /usr/bin/env bash

BUILD_DIR := build
ASSETS_DIR := assets
DRAWIO_CMD ?= drawio
DRAWIO_CMD := $(DRAWIO_CMD)
BUILD_OPTIONS ?=
BUILD_OPTIONS := $(BUILD_OPTIONS)
MAIN := main

DRAWIO_IMAGES :=
DRAWIO_IMAGES += $(BUILD_DIR)/drawio_example.pdf

TEX_IMAGES :=
TEX_IMAGES += $(BUILD_DIR)/mathcha_example.pdf
TEX_IMAGES += $(BUILD_DIR)/geogebra_example.pdf

ASSETS_DEPS := $(shell find $(ASSETS_DIR)/* -type f,l)
TEX_DEPS := $(shell find -maxdepth 1 -type f,l -name \*.tex)
BIB_DEPS := $(shell find -maxdepth 1 -type f,l -name \*.bib)
MAIN_DEPS := $(TEX_DEPS) $(BIB_DEPS) $(ASSETS_DEPS) $(TEX_IMAGES) $(DRAWIO_IMAGES)

KEEP_CI_USER_SUDO ?= false
KEEP_CI_USER_SUDO := $(KEEP_CI_USER_SUDO)
DOCKER_TARGET ?= main
DOCKER_TARGET := $(DOCKER_TARGET)
DOCKER_IMAGE_TAG ?= rudenkornk/docker_latex:0.4.0
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_TAG)
DOCKER_CONTAINER_NAME ?= docker_latex_container
DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)

.PHONY: main
main: $(BUILD_DIR)/$(MAIN).pdf

$(DRAWIO_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.xml
	$(DRAWIO_CMD) --transparent --crop --export --output $@ $< --no-sandbox

$(TEX_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.tex
	latexmk --output-directory=$(BUILD_DIR) $(BUILD_OPTIONS) $<
	touch $@ && file $@ | grep --quiet ' PDF '

$(BUILD_DIR)/$(MAIN).pdf: $(MAIN_DEPS)
	latexmk --output-directory=$(BUILD_DIR) $(BUILD_OPTIONS) $(MAIN).tex
	touch $@ && file $@ | grep --quiet ' PDF '

.PHONY: continuous
continuous: $(MAIN_DEPS)
	latexmk --output-directory=$(BUILD_DIR) --interaction=nonstopmode $(MAIN).tex -pvc

.PHONY: lint
lint: $(MAIN_DEPS)

.PHONY: check
check: $(BUILD_DIR)/$(MAIN).pdf

.PHONY: clean
clean:
	rm --force $(BUILD_DIR)/*.aux
	rm --force $(BUILD_DIR)/*.bbl
	rm --force $(BUILD_DIR)/*.bcf
	rm --force $(BUILD_DIR)/*.blg
	rm --force $(BUILD_DIR)/*.fdb_latexmk
	rm --force $(BUILD_DIR)/*.fls
	rm --force $(BUILD_DIR)/*.lof
	rm --force $(BUILD_DIR)/*.log
	rm --force $(BUILD_DIR)/*.lot
	rm --force $(BUILD_DIR)/*.out
	rm --force $(BUILD_DIR)/*.xml
	rm --force --recursive $(BUILD_DIR)/_minted-main


###################### docker support ######################
DOCKER_CONTAINER_ID = $(shell command -v docker &> /dev/null && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_STATE = $(shell command -v docker &> /dev/null && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_RUN_STATUS = $(shell [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running")
.PHONY: $(DOCKER_CONTAINER)_not_running
$(DOCKER_CONTAINER): $(DOCKER_CONTAINER_RUN_STATUS)
ifneq ($(DOCKER_CONTAINER_ID),)
	docker container rename $(DOCKER_CONTAINER_NAME) $(DOCKER_CONTAINER_NAME)_$(DOCKER_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--user ci_user \
		--env BUILD_OPTIONS="$(BUILD_OPTIONS)" \
		--env KEEP_CI_USER_SUDO="$(KEEP_CI_USER_SUDO)" \
		--env CI_UID="$$(id --user)" --env CI_GID="$$(id --group)" \
		--name $(DOCKER_CONTAINER_NAME) \
		--mount type=bind,source="$$(pwd)",target=/home/repo \
		$(DOCKER_IMAGE_TAG)
	sleep 1
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: in_docker
in_docker: $(DOCKER_CONTAINER)
	docker exec \
		$(DOCKER_CONTAINER_NAME) \
		bash -c "source ~/.profile && make $(DOCKER_TARGET)"

