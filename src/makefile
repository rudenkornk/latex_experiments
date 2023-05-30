SHELL = /usr/bin/env bash

ASSETS_DIR := src/assets
ROOT_FILE := main

DRAWIO_IMAGES :=
DRAWIO_IMAGES += $(BUILD_DIR)/drawio_example.pdf

TEX_IMAGES :=
TEX_IMAGES += $(BUILD_DIR)/mathcha_example.pdf
TEX_IMAGES += $(BUILD_DIR)/geogebra_example.pdf

ASSETS_DEPS != find $(ASSETS_DIR)/* -type f,l
TEX_DEPS != find src -maxdepth 1 -type f,l -name \*.tex
BIB_DEPS != find src -maxdepth 1 -type f,l -name \*.bib


.PHONY: build
build: $(BUILD_DIR)/$(ROOT_FILE).pdf

.PHONY: $(BUILD_DIR)/$(ROOT_FILE).pdf # let latexmk decide whether to recompile the document
$(BUILD_DIR)/$(ROOT_FILE).pdf: $(TEX_IMAGES) $(DRAWIO_IMAGES) $(TEX_DEPS) $(BIB_DEPS) $(ASSETS_DEPS) $(BUILD_DIR)/fonts
	latexmk --output-directory=$(BUILD_DIR) src/$(ROOT_FILE).tex
	# latexmk may exit with false-positive success, thus double-check it with pdfinfo
	pdfinfo $@ &> /dev/null

$(DRAWIO_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.xml
	drawio --transparent --crop --export --output $@ $<

.PHONY: $(TEX_IMAGES) # let latexmk decide whether to recompile the document
$(TEX_IMAGES): $(BUILD_DIR)/%.pdf: $(ASSETS_DIR)/%.tex $(BUILD_DIR)/fonts
	latexmk --output-directory=$(BUILD_DIR) $<
	# latexmk may exit with false-positive success, thus double-check it with pdfinfo
	pdfinfo $@ &> /dev/null

$(BUILD_DIR)/fonts:
	mktextfm larm1000
	mktextfm larm1200
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: version
version:
	$(info $(VERSION))

.PHONY: release_file
release_file:
	$(info $(BUILD_DIR)/$(ROOT_FILE).pdf)

.PHONY: check
check: $(BUILD_DIR)/$(ROOT_FILE).pdf
	for i in \
		$(TEX_IMAGES) \
		$(DRAWIO_IMAGES) \
		$(BUILD_DIR)/$(ROOT_FILE).pdf \
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
	rm --force --recursive logs
	rm --force --recursive $(BUILD_DIR)/_minted-main
