# Makefile for building and publishing multi-platform container images to GHCR

# Variables
REGISTRY := ghcr.io
ORG := polar-team
IMAGE_NAME := diffusion-molecule-container
DIND_VERSION := 29.0.4-dind-alpine3.22

# Get version from git tag or use 'latest'
VERSION ? = $(shell git describe --tags --always --dirty 2>/dev/null || echo "latest")

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

.PHONY: login
login: ## Login to GitHub Container Registry
	@echo "Logging in to $(REGISTRY)..."
	@echo "$$GITHUB_TOKEN" | docker login $(REGISTRY) -u $(GITHUB_ACTOR) --password-stdin

.PHONY: build
build: ## Build multi-platform image locally (without pushing)
	@echo "Building $(IMAGE):$(VERSION) for $(PLATFORMS)..."
	docker buildx build \
		--platform $(PLATFORMS) \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION) \
		-t $(IMAGE):latest \
		--load \
		.

.PHONY: build-and-push
build-and-push: ## Build and push multi-platform image to GHCR (manifest list)
	@echo "Building and pushing $(IMAGE):$(VERSION) for $(PLATFORMS)..."
	docker buildx build \
		--platform $(PLATFORMS) \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION) \
		-t $(IMAGE):latest \
		--push \
		.

.PHONY: build-and-push-separate
build-and-push-separate: ## Build and push with separate tags per architecture
	@echo "Building and pushing $(IMAGE) with architecture-specific tags..."
	docker buildx build \
		--platform linux/amd64 \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-amd64 \
		-t $(IMAGE):latest-amd64 \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-arm64 \
		-t $(IMAGE):latest-arm64 \
		--push \
		.

.PHONY: build-and-push-all
build-and-push-all: ## Build with both manifest list AND separate architecture tags
	@echo "Building with manifest list..."
	docker buildx build \
		--platform $(PLATFORMS) \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION) \
		-t $(IMAGE):latest \
		--push \
		.
	@echo "Building architecture-specific tags..."
	docker buildx build \
		--platform linux/amd64 \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-amd64 \
		-t $(IMAGE):latest-amd64 \
		--push \
		.
	docker buildx build \
		--platform linux/arm64 \
		$(BUILD_ARGS) \
		-t $(IMAGE):$(VERSION)-arm64 \
		-t $(IMAGE):latest-arm64 \
		--push \
		.

.PHONY: publish
publish: setup-buildx login build-and-push ## Complete workflow: setup, login, build and push (manifest list)

.PHONY: publish-separate
publish-separate: setup-buildx login build-and-push-separate ## Publish with separate architecture tags

.PHONY: publish-all
publish-all: setup-buildx login build-and-push-all ## Publish both manifest list and separate tags

.PHONY: setup-buildx
setup-buildx: ## Setup Docker Buildx for multi-platform builds
	@echo "Setting up Docker Buildx..."
	@docker buildx inspect multiplatform-builder > /dev/null 2>&1 || \
		docker buildx create --name multiplatform-builder --driver docker-container --use
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

# Default target
.DEFAULT_GOAL := help
