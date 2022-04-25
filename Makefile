SHELL = /usr/bin/env bash

BUILD_DIR ?= build
ASSETS_DIR ?= assets
DRAWIO_CMD ?= drawio
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

$(TEX_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.tex
	latexmk --output-directory=$(BUILD_DIR) $(BUILD_OPTIONS) $<
	touch $@ && file $@ | grep --quiet ' PDF '

$(BUILD_DIR)/$(MAIN).pdf: $(MAIN_DEPS)
	latexmk --output-directory=$(BUILD_DIR) $(BUILD_OPTIONS) $(MAIN).tex
	touch $@ && file $@ | grep --quiet ' PDF '

.PHONY: continuous
continuous: $(MAIN_DEPS)
	latexmk --output-directory=$(BUILD_DIR) --interaction=nonstopmode $(MAIN).tex -pvc

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

