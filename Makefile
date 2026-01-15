# Makefile for building and publishing multi-platform container images to GHCR

# Variables
REGISTRY := ghcr.io
ORG := polar-team
IMAGE_NAME := diffusion-molecule-container
# DIND_VERSION can be overridden: make publish DIND_VERSION=29.0.5-dind-alpine3.22
DIND_VERSION ?= 29.1.4-dind-alpine3.23
VERSION ?= $(shell git describe --tags)
# PYTHON_VERSIONS can be overridden: make publish ADDITIONAL_PYTHON_VERSIONS="3.12.0 3.11.0"
PYTHON_VERSIONS ?=
UV_VERSION ?=
CACHE_PATH ?= ./cache
EXTRA_CONF :=
TEST_CONTAINER := false

ifneq ($(wildcard /buildkitd.toml),)
	EXTRA_CONF := -extra-conf
endif

ifeq ($(TEST_CONTAINER), true)
	  TEST_SUFFIX := -test
endif


# Full image reference
IMAGE := $(REGISTRY)/$(ORG)/$(IMAGE_NAME)

# Platforms to build for
PLATFORMS := linux/amd64,linux/arm64

# Build arguments
BUILD_ARGS := --build-arg DIND_VERSION=$(DIND_VERSION)
ifneq ($(PYTHON_VERSIONS),)
BUILD_ARGS += --build-arg PYTHON_VERSIONS="$(PYTHON_VERSIONS)"
endif
ifneq ($(UV_VERSION),)
BUILD_ARGS += --build-arg UV_VERSION=$(UV_VERSION)
endif

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

.PHONY: check_cache
check_cache:
	@echo "Checking cache at $(CACHE_PATH)..."
ifneq ($(wildcard ${CACHE_PATH}/index.json),)
	@echo "Cache found."
else
	@echo "No cache found. Creating firstinit file."
	@[ -d ./cache ] || mkdir -p ./cache
	@touch ${CACHE_PATH}/firstinit
endif

.PHONY: check_certificate
check_certificate:
	@echo "Checking for custom certificate..."
ifneq ($(wildcard certificate.pem),)
	@echo "Custom certificate found."
else
	@echo "No custom certificate found."
	@touch certificate.pem
endif




.PHONY: login
login: ## Login to GitHub Container Registry
	@echo "Logging in to $(REGISTRY)..."
ifeq ($(OS),Windows_NT)
	@powershell -Command 'echo "$$env:GITHUB_TOKEN" | docker login $(REGISTRY) -u "$$env:GITHUB_ACTOR" --password-stdin'
else
	@echo "$$GITHUB_TOKEN" | docker login $(REGISTRY) -u "$$GITHUB_ACTOR" --password-stdin
endif


.PHONY: build-and-push-separate
build-and-push-separate: ## Build and push with separate tags per architecture
ifneq ($(wildcard ${CACHE_PATH}/firstinit),)
	@echo "Building and pushing $(IMAGE) with architecture-specific tags..."
	docker buildx build \
		--platform linux/amd64 \
		--cache-to=type=local,dest=${CACHE_PATH}  \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-amd64$(TEST_SUFFIX) \
		-t $(IMAGE):latest-amd64$(TEST_SUFFIX) \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		--cache-to=type=local,dest=${CACHE_PATH}  \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-arm64$(TEST_SUFFIX) \
		-t $(IMAGE):latest-arm64$(TEST_SUFFIX) \
		--push \
		.
	@rm -f ${CACHE_PATH}/firstinit
else
	@echo "Building and pushing $(IMAGE) with architecture-specific tags using cache..."
	docker buildx build \
		--platform linux/amd64 \
		--cache-from=type=local,src=${CACHE_PATH} \
		--cache-to=type=local,dest=${CACHE_PATH}  \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-amd64$(TEST_SUFFIX) \
		-t $(IMAGE):latest-amd64$(TEST_SUFFIX) \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		--cache-from=type=local,src=${CACHE_PATH} \
		--cache-to=type=local,dest=${CACHE_PATH}  \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-arm64$(TEST_SUFFIX) \
		-t $(IMAGE):latest-arm64$(TEST_SUFFIX) \
		--push \
		.
endif


.PHONY: publish
publish:check_certificate check_cache setup-buildx$(EXTRA_CONF) login build-and-push-separate


.PHONY: setup-buildx-extra-conf
setup-buildx-extra-conf: ## Setup Docker Buildx for multi-platform builds
	@echo "Setting up Docker Buildx..."
	@docker buildx inspect multiplatform-builder > /dev/null 2>&1 || \
		docker buildx create --config /buildkitd.toml  --name multiplatform-builder --driver docker-container --use
	@docker buildx inspect --bootstrap

.PHONY: setup-buildx
setup-buildx: ## Setup Docker Buildx for multi-platform builds
	@echo "Setting up Docker Buildx..."
	@docker buildx inspect multiplatform-builder > /dev/null 2>&1 || \
		docker buildx create   --name multiplatform-builder --driver docker-container --use
	@docker buildx inspect --bootstrap

.PHONY: test-local
test-local: ## Build and test image locally for current platform
	@echo "Building local test image..."
	docker build $(BUILD_ARGS) -t $(IMAGE):test .
	@echo "Testing image..."
	docker run --rm $(IMAGE):test molecule --version

.PHONY: build-local
build-local: check_certificate ## Build image locally for current platform
	@echo "Building local image for testing..."
	docker build $(BUILD_ARGS) -t $(IMAGE_NAME):local .
	@echo "Image built: $(IMAGE_NAME):local"
	@echo "Test with: docker run --rm $(IMAGE_NAME):local molecule --version"

.PHONY: build-and-save
build-and-save: check_certificate ## Build and save image to tar file for testing
	@echo "Building and saving image to local repository..."
	docker build $(BUILD_ARGS) -t $(IMAGE_NAME):local .
	@mkdir -p ./images
	docker save $(IMAGE_NAME):local -o ./images/$(IMAGE_NAME)-local.tar
	@echo "Image saved to: ./images/$(IMAGE_NAME)-local.tar"
	@echo "Load with: docker load -i ./images/$(IMAGE_NAME)-local.tar"

.PHONY: load-local
load-local: ## Load saved image from tar file
	@echo "Loading image from local repository..."
	@if [ -f ./images/$(IMAGE_NAME)-local.tar ]; then \
		docker load -i ./images/$(IMAGE_NAME)-local.tar; \
		echo "Image loaded: $(IMAGE_NAME):local"; \
	else \
		echo "Error: ./images/$(IMAGE_NAME)-local.tar not found"; \
		echo "Run 'make build-and-save' first"; \
		exit 1; \
	fi

.PHONY: clean
clean: ## Remove buildx builder
	@echo "Cleaning up buildx builder..."
	-docker buildx rm multiplatform-builder

.PHONY: clean-local
clean-local: ## Remove local images and saved tar files
	@echo "Cleaning up local images..."
	-docker rmi $(IMAGE_NAME):local
	-docker rmi $(IMAGE):test
	@echo "Cleaning up saved images..."
	-rm -rf ./images
	@echo "Local cleanup complete"

.PHONY: show-platforms
show-platforms: ## Show configured platforms
	@echo "Configured platforms: $(PLATFORMS)"
	@echo "DIND Version: $(DIND_VERSION)"
	@echo "Python Version: $(PYTHON_VERSION)"
	@echo "Image: $(IMAGE):$(VERSION)"
	@echo ""
	@echo "Manifest list tags:"
	@echo "  - $(IMAGE):$(VERSION)"
	@echo "  - $(IMAGE):latest"
	@echo ""
	@echo "Architecture-specific tags:"
	@echo "  - $(IMAGE):$(VERSION)-amd64"
	@echo "  - $(IMAGE):latest-amd64"
	@echo "  - $(IMAGE):$(VERSION)-arm64"
	@echo "  - $(IMAGE):latest-arm64"
	@echo ""
	@echo "Override versions:"
	@echo "  make publish DIND_VERSION=29.0.5-dind-alpine3.22"
	@echo "  make publish PYTHON_VERSION=3.13"

# Default target
.DEFAULT_GOAL := help
