# Makefile for building and publishing multi-platform container images to GHCR

# Variables
REGISTRY := ghcr.io
ORG := polar-team
IMAGE_NAME := diffusion-molecule-container
# DIND_VERSION can be overridden: make publish DIND_VERSION=29.0.5-dind-alpine3.22
DIND_VERSION ?= 29.0.4-dind-alpine3.22
CACHE_PATH ?= ./cache
EXTRA_CONF :=
ifneq ($(wildcard /buildkitd.toml),)
	EXTRA_CONF := -extra-conf
endif

# Get version from git tag or use 'latest'
ifeq ($(OS),Windows_NT)
VERSION ?= $(shell powershell -Command "git describe --tags")
else
VERSION ?= $(shell git describe --tags)
endif

# Full image reference
IMAGE := $(REGISTRY)/$(ORG)/$(IMAGE_NAME)

# Platforms to build for
PLATFORMS := linux/amd64,linux/arm64

# Build arguments
BUILD_ARGS := --build-arg DIND_VERSION=$(DIND_VERSION)

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
		-t $(IMAGE):$(VERSION)-amd64 \
		-t $(IMAGE):latest-amd64 \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		--cache-to=type=local,dest=${CACHE_PATH}  \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-arm64 \
		-t $(IMAGE):latest-arm64 \
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
		-t $(IMAGE):$(VERSION)-amd64 \
		-t $(IMAGE):latest-amd64 \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		--cache-from=type=local,src=${CACHE_PATH} \
		--cache-to=type=local,dest=${CACHE_PATH}  \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-arm64 \
		-t $(IMAGE):latest-arm64 \
		--push \
		.
endif

.PHONY: publish
publish:check_certificate check_cache setup-buildx$(EXTRA_CONF) login build-and-push-separate ## Publish with separate architecture tags


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

.PHONY: clean
clean: ## Remove buildx builder
	@echo "Cleaning up buildx builder..."
	-docker buildx rm multiplatform-builder

.PHONY: show-platforms
show-platforms: ## Show configured platforms
	@echo "Configured platforms: $(PLATFORMS)"
	@echo "DIND Version: $(DIND_VERSION)"
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
	@echo "Override DIND version:"
	@echo "  make publish DIND_VERSION=29.0.5-dind-alpine3.22"

# Default target
.DEFAULT_GOAL := help
