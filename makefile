SHELL = /usr/bin/env bash

# make some_target, make TARGET=some_target or make in_container TARGET=some_target
TARGET ?= build

PROJECT_NAME := latex_experiments
BUILD_DIR := __build__
ASSETS_DIR := assets
ROOT_FILE := main
VERSION:= 1.0.0

DRAWIO_IMAGES :=
DRAWIO_IMAGES += $(BUILD_DIR)/drawio_example.pdf

TEX_IMAGES :=
TEX_IMAGES += $(BUILD_DIR)/mathcha_example.pdf
TEX_IMAGES += $(BUILD_DIR)/geogebra_example.pdf

ASSETS_DEPS != find $(ASSETS_DIR)/* -type f,l
TEX_DEPS != find -maxdepth 1 -type f,l -name \*.tex
BIB_DEPS != find -maxdepth 1 -type f,l -name \*.bib


.PHONY: $(BUILD_DIR)/redirect
$(BUILD_DIR)/redirect: $(TARGET)

.PHONY: build
build: $(BUILD_DIR)/$(ROOT_FILE).pdf

.PHONY: $(BUILD_DIR)/$(ROOT_FILE).pdf # let latexmk decide whether to recompile the document
$(BUILD_DIR)/$(ROOT_FILE).pdf: $(TEX_IMAGES) $(DRAWIO_IMAGES) $(TEX_DEPS) $(BIB_DEPS) $(ASSETS_DEPS) $(BUILD_DIR)/fonts
	latexmk --output-directory=$(BUILD_DIR) $(ROOT_FILE).tex
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
	rm --force --recursive $(BUILD_DIR)/_minted-main


###################### container support ######################
IMAGE_NAMETAG := ghcr.io/rudenkornk/latex_image:2.0.0
CONTAINER_NAME := $(PROJECT_NAME)

.PHONY: $(BUILD_DIR)/not_ready

IF_PODMAN_UP := command -v podman &> /dev/null

CONTAINER_ID != $(IF_PODMAN_UP) && podman container ls --quiet --all --filter name=^$(CONTAINER_NAME)$
CONTAINER_STATE != $(IF_PODMAN_UP) && podman container ls --format {{.State}} --all --filter name=^$(CONTAINER_NAME)$
CONTAINER_RUN_STATUS != [[ ! "$(CONTAINER_STATE)" =~ ^Up ]] && echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/container: $(CONTAINER_RUN_STATUS)
ifneq ($(CONTAINER_ID),)
	podman container rename $(CONTAINER_NAME) $(CONTAINER_NAME)_$(CONTAINER_ID)
endif
	podman run --interactive --tty --detach \
		--cap-add=SYS_ADMIN `# for drawio` \
		--env "TERM=xterm-256color" `# colored terminal` \
		--mount type=bind,source="$$(pwd)",target="$$(pwd)" `# mount your repo` \
		--name $(CONTAINER_NAME) \
		--userns keep-id `# keeps non-root username` \
		--workdir "$$HOME" `# podman sets homedir to the workdir for some readon` \
		$(IMAGE_NAMETAG)
	podman exec --user root $(CONTAINER_NAME) bash -c "chown $$(id --user):$$(id --group) $$HOME"
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: container
container: $(BUILD_DIR)/container

.PHONY: in_container
in_container: $(BUILD_DIR)/container
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) bash -c 'make $(TARGET)'

.PHONY: cclean
cclean:
	podman container ls --quiet --filter name=^$(CONTAINER_NAME) | xargs podman stop || true
	podman container ls --quiet --filter name=^$(CONTAINER_NAME) --all | xargs podman rm || true
