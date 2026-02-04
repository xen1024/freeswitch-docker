# FreeSWITCH Docker Makefile
# Simplified commands for building and managing FreeSWITCH

.PHONY: help build build-minimal build-full run stop restart logs cli status clean prune

# Variables
IMAGE_NAME := freeswitch-source
IMAGE_TAG := latest
CONTAINER_NAME := freeswitch
FS_VERSION := v1.10.12
MAKE_JOBS := $(shell nproc)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)FreeSWITCH Docker Makefile$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

build: ## Build FreeSWITCH from source (full)
	@echo "$(GREEN)Building FreeSWITCH $(FS_VERSION) with $(MAKE_JOBS) jobs...$(NC)"
	docker build -f Dockerfile.source \
		--build-arg FREESWITCH_VERSION=$(FS_VERSION) \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)Build complete!$(NC)"

build-minimal: ## Build minimal FreeSWITCH (smaller image)
	@echo "$(GREEN)Building minimal FreeSWITCH $(FS_VERSION)...$(NC)"
	docker build -f Dockerfile.source-minimal \
		--build-arg FREESWITCH_VERSION=$(FS_VERSION) \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		-t $(IMAGE_NAME):minimal .
	@echo "$(GREEN)Minimal build complete!$(NC)"

build-full: ## Build with all features (largest image)
	@echo "$(GREEN)Building full-featured FreeSWITCH $(FS_VERSION)...$(NC)"
	docker build -f Dockerfile.source \
		--build-arg FREESWITCH_VERSION=$(FS_VERSION) \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		-t $(IMAGE_NAME):full .
	@echo "$(GREEN)Full build complete!$(NC)"

build-nofax: ## Build without fax support (faster, recommended)
	@echo "$(GREEN)Building FreeSWITCH without fax support $(FS_VERSION)...$(NC)"
	docker build -f Dockerfile.source-nofax \
		--build-arg FREESWITCH_VERSION=$(FS_VERSION) \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		-t $(IMAGE_NAME):nofax .
	@echo "$(GREEN)No-fax build complete! (faster & more reliable)$(NC)"

build-dev: ## Build latest development version
	@echo "$(YELLOW)Building development version from master...$(NC)"
	docker build -f Dockerfile.source \
		--build-arg FREESWITCH_VERSION=master \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		-t $(IMAGE_NAME):dev .
	@echo "$(GREEN)Dev build complete!$(NC)"

run: ## Run FreeSWITCH container
	@if docker ps -a | grep -q $(CONTAINER_NAME); then \
		echo "$(YELLOW)Container already exists. Use 'make restart' or 'make stop' first.$(NC)"; \
		exit 1; \
	fi
	@mkdir -p freeswitch/{conf,db,recordings,storage,logs,scripts}
	@echo "$(GREEN)Starting FreeSWITCH container...$(NC)"
	docker run -d \
		--name $(CONTAINER_NAME) \
		--net host \
		-v $(PWD)/freeswitch/conf:/usr/local/freeswitch/conf \
		-v $(PWD)/freeswitch/db:/usr/local/freeswitch/db \
		-v $(PWD)/freeswitch/recordings:/usr/local/freeswitch/recordings \
		-v $(PWD)/freeswitch/storage:/usr/local/freeswitch/storage \
		-v $(PWD)/freeswitch/logs:/var/log/freeswitch \
		-v $(PWD)/freeswitch/scripts:/usr/local/freeswitch/scripts \
		$(IMAGE_NAME):$(IMAGE_TAG)
	@echo "$(GREEN)Container started!$(NC)"
	@echo "Use 'make logs' to view logs or 'make cli' to access CLI"

stop: ## Stop FreeSWITCH container
	@echo "$(YELLOW)Stopping FreeSWITCH container...$(NC)"
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@echo "$(GREEN)Container stopped.$(NC)"

start: ## Start stopped container
	@echo "$(GREEN)Starting FreeSWITCH container...$(NC)"
	@docker start $(CONTAINER_NAME)

restart: ## Restart FreeSWITCH container
	@echo "$(YELLOW)Restarting FreeSWITCH container...$(NC)"
	@docker restart $(CONTAINER_NAME)
	@echo "$(GREEN)Container restarted.$(NC)"

logs: ## View container logs (follow mode)
	docker logs -f $(CONTAINER_NAME)

cli: ## Access FreeSWITCH CLI
	@echo "$(GREEN)Connecting to FreeSWITCH CLI...$(NC)"
	@echo "$(YELLOW)Press Ctrl+D or type 'exit' to quit$(NC)"
	docker exec -it $(CONTAINER_NAME) fs_cli

status: ## Show FreeSWITCH status
	@if docker ps | grep -q $(CONTAINER_NAME); then \
		echo "$(GREEN)Container is running$(NC)"; \
		docker exec $(CONTAINER_NAME) fs_cli -x "status" 2>/dev/null || echo "$(YELLOW)FreeSWITCH is starting...$(NC)"; \
	else \
		echo "$(RED)Container is not running$(NC)"; \
	fi

shell: ## Open bash shell in container
	docker exec -it $(CONTAINER_NAME) bash

remove: ## Remove container
	@$(MAKE) stop
	@echo "$(YELLOW)Removing container...$(NC)"
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true
	@echo "$(GREEN)Container removed.$(NC)"

clean: ## Remove container and images
	@$(MAKE) remove
	@echo "$(YELLOW)Removing images...$(NC)"
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):minimal 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):full 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):dev 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete.$(NC)"

prune: ## Remove all Docker build cache
	@echo "$(YELLOW)Removing Docker build cache...$(NC)"
	docker builder prune -f
	@echo "$(GREEN)Cache cleared.$(NC)"

size: ## Show image sizes
	@echo "$(GREEN)Image sizes:$(NC)"
	@docker images | grep $(IMAGE_NAME) || echo "No images found"

compose-up: ## Start using docker-compose
	docker-compose -f docker-compose.source.yml up -d

compose-down: ## Stop using docker-compose
	docker-compose -f docker-compose.source.yml down

compose-build: ## Build using docker-compose
	docker-compose -f docker-compose.source.yml build

compose-logs: ## View logs using docker-compose
	docker-compose -f docker-compose.source.yml logs -f

info: ## Show build information
	@echo "$(GREEN)Build Configuration:$(NC)"
	@echo "  Image name:    $(IMAGE_NAME)"
	@echo "  Image tag:     $(IMAGE_TAG)"
	@echo "  Container:     $(CONTAINER_NAME)"
	@echo "  FS Version:    $(FS_VERSION)"
	@echo "  Make jobs:     $(MAKE_JOBS)"
	@echo ""
	@echo "$(GREEN)Directory Structure:$(NC)"
	@ls -la freeswitch/ 2>/dev/null || echo "  freeswitch/ directory not yet created"

# Version-specific targets
build-v1.10.12: ## Build FreeSWITCH v1.10.12
	@$(MAKE) build FS_VERSION=v1.10.12 IMAGE_TAG=1.10.12

build-v1.10.11: ## Build FreeSWITCH v1.10.11
	@$(MAKE) build FS_VERSION=v1.10.11 IMAGE_TAG=1.10.11

# Quick rebuild without cache
rebuild: ## Rebuild without using cache
	docker build -f Dockerfile.source \
		--no-cache \
		--build-arg FREESWITCH_VERSION=$(FS_VERSION) \
		--build-arg MAKE_JOBS=$(MAKE_JOBS) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

# Development helpers
dev-run: build-dev ## Build and run development version
	@$(MAKE) run IMAGE_TAG=dev CONTAINER_NAME=freeswitch-dev

test: ## Test FreeSWITCH functionality
	@echo "$(GREEN)Testing FreeSWITCH...$(NC)"
	@docker exec $(CONTAINER_NAME) fs_cli -x "status" || echo "$(RED)FreeSWITCH not responding$(NC)"
	@docker exec $(CONTAINER_NAME) fs_cli -x "sofia status" || echo "$(RED)SIP not running$(NC)"
	@echo "$(GREEN)Test complete.$(NC)"

backup: ## Backup configuration
	@echo "$(GREEN)Backing up configuration...$(NC)"
	@tar -czf freeswitch-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz freeswitch/
	@echo "$(GREEN)Backup created.$(NC)"

# All-in-one commands
all: build run ## Build and run FreeSWITCH

minimal: build-minimal ## Build minimal version and run
	@$(MAKE) run IMAGE_TAG=minimal
