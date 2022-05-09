# Example Makefile used to illustrate how to set up target-aware `make build`
# Based on
# https://itnext.io/docker-makefile-x-ops-sharing-infra-as-code-parts-ea6fa0d22946

# The first target in this file is 'shell', so instead of naming it explicitly,
# as in
#     `make cmd="whoami" shell` OR `make shell cmd="whoami"`
# we can type:
#     make cmd="whoami".

# All our targets are phony (no files to check).
.PHONY: shell help show-vars build rebuild start status attach stop

CONTAINER_NAME := make_build_example
# We use $(CONTAINER_NAME) for the names of both the Docker image and the
# running container.
TAG := $(CONTAINER_NAME):latest

# Get the name of the directory holding this Makefile.
WORKSPACE := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# Remove trailing slash from WORKSPACE.
WORKSPACE != TMP="$(WORKSPACE)"; echo $${TMP%%/}

SHELL_CMDS ?= $(cmd)

UID != echo $${UID:=$$(id -u)}
GID != echo $${GID:=$$(id -g)}
# Test with ``make GID=1138403528 show-vars` and `make GID=1138403528 rebuild`

BUILD_OPTS = -t $(TAG) \
	--force-rm \
	--build-arg uid=$(UID) \
	--build-arg gid=$(GID) \
	-f Dockerfile $(WORKSPACE)/context

# Default opts are to run -i(nteractive) and with -t(ty). To run in background,
# explicitly add the -d(etach) option to the relevant target.
RUN_OPTS =  --rm -it --network=host \
            --env BUILD_TIME="$(shell date --iso-8601=seconds)"

shell:
ifeq ($(SHELL_CMDS),)
# No command is given, default to shell.
	@docker run $(RUN_OPTS) --entrypoint=/bin/sh $(TAG)
else
# Run the command.
	@docker run $(RUN_OPTS) --entrypoint=/bin/sh $(TAG) -c "$(SHELL_CMDS)"
endif

help:
	@echo ''
	@echo 'Usage: make {TARGET} {cmd="SHELL_CMDS"}'
	@echo 'Targets:'
	@echo '  shell      Run Docker container with default ENTRYPOINT and CMD.'
	@echo '             If `cmd="SHELL_CMDS"` is given, run those instead in /bin/sh.'
	@echo '  show-vars  Print out values of vars used - useful for debugging.'
	@echo '  build      Build Docker image.'
	@echo '  rebuild    Rebuild Docker image (without cache).'
	@echo '  start      Start container in detached mode (run in background).'
	@echo "  status     Retrieve container's output."
	@echo '  attach     Drop into running container.'
	@echo '  stop       Stop container running in background.'
	@echo ''

show-vars:
	@echo "TAG:        '$(TAG)'"
	@echo "WORKSPACE:  '$(WORKSPACE)'"
	@echo "SHELL_CMDS: '$(SHELL_CMDS)'"
	@echo "UID:        '$(UID)'"
	@echo "GID:        '$(GID)'"
	@echo "Build options:\n\t'$(BUILD_OPTS)'"
	@echo "Run options:\n\t'$(RUN_OPTS)'"

build:
# Build the Docker image.
	@docker build $(BUILD_OPTS)

rebuild:
# Force a rebuild of the Docker image by passing --no-cache.
	@docker build --no-cache $(BUILD_OPTS)

start:
# Run as a (background) service, or print ID if already running.
	@docker ps -a --no-trunc --filter name=^/$(CONTAINER_NAME)$$ | grep $(CONTAINER_NAME) 1>/dev/null \
	&& docker ps -a --no-trunc --filter name=^/$(CONTAINER_NAME)$$ --format "{{.ID}}" \
	|| docker run -d $(RUN_OPTS) \
		--name $(CONTAINER_NAME) \
		$(TAG)

attach:
# Attach to a container running in the background.
	@docker ps -a --no-trunc --filter name=^/$(CONTAINER_NAME)$$ | grep $(CONTAINER_NAME) 1>/dev/null \
	&& docker exec -it $(CONTAINER_NAME) /bin/sh

status:
# Retrieve the container's logs, to get some idea of how it's running
	@docker logs $(CONTAINER_NAME)

stop:
# Stop running containers.
	@docker stop $(CONTAINER_NAME) 2>/dev/null \
	&& echo 'Running container for "$(TAG)" stopped.' \
	|| echo 'No running container for "$(TAG)" found.'