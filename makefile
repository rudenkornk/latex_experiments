SHELL = /usr/bin/env bash

PROJECT_NAME=latex_experiments
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

.PHONY: main
main: $(BUILD_DIR)/$(MAIN).pdf

$(DRAWIO_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.xml
	$(DRAWIO_CMD) --transparent --crop --export --output $@ $< --no-sandbox

.PHONY: $(TEX_IMAGES) # let latexmk decide whether to recompile the document
$(TEX_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.tex
	latexmk --output-directory=$(BUILD_DIR) $(BUILD_OPTIONS) $<
	# latexmk may exit with false-positive success, thus double-check it with pdfinfo
	pdfinfo $@ &> /dev/null

.PHONY: $(BUILD_DIR)/$(MAIN).pdf # let latexmk decide whether to recompile the document
$(BUILD_DIR)/$(MAIN).pdf: $(MAIN_DEPS)
	latexmk --output-directory=$(BUILD_DIR) $(BUILD_OPTIONS) $(MAIN).tex
	# latexmk may exit with false-positive success, thus double-check it with pdfinfo
	pdfinfo $@ &> /dev/null

.PHONY: continuous
continuous: $(MAIN_DEPS)
	latexmk --output-directory=$(BUILD_DIR) --interaction=nonstopmode $(MAIN).tex -pvc

.PHONY: lint
lint: $(MAIN_DEPS)

.PHONY: check
check: $(BUILD_DIR)/$(MAIN).pdf
	for i in \
		$(TEX_IMAGES) \
		$(DRAWIO_IMAGES) \
		$(BUILD_DIR)/$(MAIN).pdf \
		; do pdfinfo $$i; done

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
TARGET ?=
COMMAND ?=
KEEP_CI_USER_SUDO ?= false
KEEP_CI_USER_SUDO := $(KEEP_CI_USER_SUDO)
DOCKER_IMAGE_TAG ?= rudenkornk/docker_latex:1.0.2
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_TAG)
DOCKER_CONTAINER_NAME ?= $(PROJECT_NAME)_container
DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)

IF_DOCKERD_UP := command -v docker &> /dev/null && pidof dockerd &> /dev/null

DOCKER_CONTAINER_ID := $(shell $(IF_DOCKERD_UP) && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_STATE := $(shell $(IF_DOCKERD_UP) && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_RUN_STATUS := $(shell [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running")
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
		--env "TERM=xterm-256color" \
		--name $(DOCKER_CONTAINER_NAME) \
		--mount type=bind,source="$$(pwd)",target=/home/repo \
		$(DOCKER_IMAGE_TAG)
	sleep 1
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: $(DOCKER_CONTAINER_NAME)
$(DOCKER_CONTAINER_NAME): $(DOCKER_CONTAINER)

.PHONY: in_docker
in_docker: $(DOCKER_CONTAINER)
ifneq ($(COMMAND),)
	docker exec \
		$(DOCKER_CONTAINER_NAME) \
		bash -c "source ~/.profile && $(COMMAND)"
else
	docker exec \
		$(DOCKER_CONTAINER_NAME) \
		bash -c "source ~/.profile && make $(TARGET)"
endif

