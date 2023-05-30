SHELL = /usr/bin/env bash

# make some_target, make TARGET=some_target or make in_container TARGET=some_target
TARGET ?= build

PROJECT_NAME := latex_experiments
BUILD_DIR := __build__
BUILD_ABS_DIR := $(abspath $(BUILD_DIR))
VERSION:= 1.0.0


.PHONY: $(BUILD_DIR)/redirect
$(BUILD_DIR)/redirect: $(TARGET)

include src/makefile


###################### container support ######################
IMAGE_NAMETAG := ghcr.io/rudenkornk/latex_ubuntu:22.0.0
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
