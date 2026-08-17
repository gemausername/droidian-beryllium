# Makefile for Droidian Poco F1 (beryllium)
# This Makefile provides convenient targets for building all components

.PHONY: all clean help setup-gpg kernel adaptation rootfs repo install docker-build docker-shell

# Configuration
PROJECT_DIR := $(shell pwd)
OUTPUT_DIR := $(PROJECT_DIR)/output
SCRIPTS_DIR := $(PROJECT_DIR)/scripts

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# Default target
all: setup-dirs setup-gpg kernel adaptation rootfs

# Create output directory
setup-dirs:
	@echo "$(GREEN)[INFO]$(NC) Creating output directory..."
	@mkdir -p $(OUTPUT_DIR)

# Help target
help:
	@echo "$(BLUE)Droidian Build System for Poco F1$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all           - Build everything (default)"
	@echo "  setup-gpg     - Setup GPG key for signing"
	@echo "  kernel        - Build kernel package"
	@echo "  adaptation    - Build adaptation package"
	@echo "  rootfs        - Build rootfs image"
	@echo "  repo          - Setup local repository"
	@echo "  install       - Install to device"
	@echo "  docker-build  - Build using Docker"
	@echo "  docker-shell  - Open Docker shell"
	@echo "  clean         - Clean build artifacts"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make all              # Build everything"
	@echo "  make kernel           # Build kernel only"
	@echo "  make docker-build     # Build using Docker"

# Setup GPG key
setup-gpg:
	@echo "$(GREEN)[INFO]$(NC) Setting up GPG key..."
	@bash $(SCRIPTS_DIR)/setup-gpg.sh

# Build kernel
kernel: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building kernel package..."
	@bash $(SCRIPTS_DIR)/build-kernel.sh

# Build adaptation package
adaptation: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building adaptation package..."
	@bash $(SCRIPTS_DIR)/build-adaptation.sh

# Build rootfs
rootfs: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building rootfs image..."
	@sudo bash $(PROJECT_DIR)/rootfs/build-rootfs.sh

# Setup repository
repo:
	@echo "$(GREEN)[INFO]$(NC) Setting up local repository..."
	@sudo bash $(SCRIPTS_DIR)/setup-repository.sh

# Install to device
install:
	@echo "$(GREEN)[INFO]$(NC) Installing to device..."
	@bash $(SCRIPTS_DIR)/install-to-device.sh

# Build using Docker
docker-build:
	@echo "$(GREEN)[INFO]$(NC) Building using Docker..."
	@docker build -t droidian-beryllium-builder -f Dockerfile .
	@docker run --rm -v $(PROJECT_DIR):/build -v $(OUTPUT_DIR):/output droidian-beryllium-builder

# Open Docker shell
docker-shell:
	@echo "$(GREEN)[INFO]$(NC) Opening Docker shell..."
	@docker build -t droidian-beryllium-builder -f Dockerfile .
	@docker run --rm -it -v $(PROJECT_DIR):/build -v $(OUTPUT_DIR):/output droidian-beryllium-builder /bin/bash

# Clean build artifacts
clean:
	@echo "$(YELLOW)[WARN]$(NC) Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)
	@rm -rf $(PROJECT_DIR)/packages/adaptation-droidian-beryllium/debian/adaptation-droidian-beryllium
	@rm -rf $(PROJECT_DIR)/packages/adaptation-droidian-beryllium/debian/.debhelper
	@rm -rf $(PROJECT_DIR)/packages/adaptation-droidian-beryllium/debian/files
	@echo "$(GREEN)[INFO]$(NC) Clean complete"

# Quick start guide
quickstart:
	@echo "$(BLUE)Quick Start Guide$(NC)"
	@echo ""
	@echo "1. Setup GPG key:"
	@echo "   make setup-gpg"
	@echo ""
	@echo "2. Build everything:"
	@echo "   make all"
	@echo ""
	@echo "3. Setup local repository:"
	@echo "   make repo"
	@echo ""
	@echo "4. Install to device:"
	@echo "   make install"
	@echo ""
	@echo "Or use Docker:"
	@echo "   make docker-build"
