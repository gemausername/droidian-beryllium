# Makefile for Droidian Poco F1 (beryllium) - Multi-Variant Support
# This Makefile provides convenient targets for building all variants

.PHONY: all clean help setup-gpg kernel adaptation rootfs repo install docker-build docker-shell

# Configuration
PROJECT_DIR := $(shell pwd)
OUTPUT_DIR := $(PROJECT_DIR)/output
SCRIPTS_DIR := $(PROJECT_DIR)/scripts

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
MAGENTA := \033[0;35m
NC := \033[0m

# Available variants
VARIANTS := phosh-ebbg phosh-tianma phosh-tianmaft lomiri-ebbg lomiri-tianma lomiri-tianmaft
DESKTOPS := phosh lomiri
PANELS := ebbg tianma tianmaft

# Default target
all: setup-dirs setup-gpg kernel all-variants

# Create output directory
setup-dirs:
	@echo "$(GREEN)[INFO]$(NC) Creating output directory..."
	@mkdir -p $(OUTPUT_DIR)

# Help target
help:
	@echo "$(CYAN)Droidian Build System for Poco F1 - Multi-Variant$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "$(BLUE)General Targets:$(NC)"
	@echo "  all              - Build everything (kernel + all variants)"
	@echo "  setup-gpg        - Setup GPG key for signing"
	@echo "  kernel           - Build kernel package"
	@echo "  repo             - Setup local repository"
	@echo "  install          - Install to device"
	@echo "  docker-build     - Build using Docker"
	@echo "  docker-shell     - Open Docker shell"
	@echo "  clean            - Clean build artifacts"
	@echo "  help             - Show this help"
	@echo "  list             - List all variants"
	@echo ""
	@echo "$(BLUE)Variant Targets:$(NC)"
	@echo "  all-variants     - Build all 6 variants"
	@echo "  phosh            - Build all Phosh variants"
	@echo "  lomiri           - Build all Lomiri variants"
	@echo "  ebbg             - Build all eBBG variants"
	@echo "  tianma           - Build all Tianma variants"
	@echo "  tianmaft         - Build all TianmaFT variants"
	@echo "  VARIANT=<name>   - Build specific variant"
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make all                    # Build everything"
	@echo "  make VARIANT=phosh-ebbg     # Build Phosh + eBBG only"
	@echo "  make phosh                  # Build all Phosh variants"
	@echo "  make tianma                 # Build all Tianma variants"
	@echo ""
	@echo "$(MAGENTA)Available Variants:$(NC)"
	@for v in $(VARIANTS); do echo "  - $$v"; done

# List variants
list:
	@echo ""
	@echo "$(CYAN)Available Variants:$(NC)"
	@echo ""
	@echo "$(BLUE)Desktop: Phosh$(NC)"
	@for p in $(PANELS); do echo "  - phosh-$$p"; done
	@echo ""
	@echo "$(BLUE)Desktop: Lomiri$(NC)"
	@for p in $(PANELS); do echo "  - lomiri-$$p"; done
	@echo ""
	@echo "Total: $(words $(VARIANTS)) variants"

# Setup GPG key
setup-gpg:
	@echo "$(GREEN)[INFO]$(NC) Setting up GPG key..."
	@bash $(SCRIPTS_DIR)/setup-gpg.sh

# Build kernel
kernel: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building kernel package..."
	@bash $(SCRIPTS_DIR)/build-kernel.sh

# Build all variants
all-variants: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building all variants..."
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --all

# Build specific variant
variant: setup-dirs
	@if [ -z "$(VARIANT)" ]; then \
		echo "$(YELLOW)[WARN]$(NC) Please specify VARIANT: make VARIANT=phosh-ebbg"; \
		exit 1; \
	fi
	@echo "$(GREEN)[INFO]$(NC) Building variant: $(VARIANT)"
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --variant $(VARIANT)

# Build by desktop
phosh: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building all Phosh variants..."
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --desktop phosh

lomiri: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building all Lomiri variants..."
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --desktop lomiri

# Build by panel
ebbg: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building all eBBG variants..."
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --panel ebbg

tianma: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building all Tianma variants..."
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --panel tianma

tianmaft: setup-dirs
	@echo "$(GREEN)[INFO]$(NC) Building all TianmaFT variants..."
	@bash $(SCRIPTS_DIR)/build-all-variants.sh --panel tianmaft

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
	@rm -rf $(PROJECT_DIR)/packages/adaptation-droidian-beryllium*/debian/adaptation-droidian-beryllium*
	@rm -rf $(PROJECT_DIR)/packages/adaptation-droidian-beryllium*/debian/.debhelper
	@rm -rf $(PROJECT_DIR)/packages/adaptation-droidian-beryllium*/debian/files
	@echo "$(GREEN)[INFO]$(NC) Clean complete"

# Quick start guide
quickstart:
	@echo "$(CYAN)Quick Start Guide$(NC)"
	@echo ""
	@echo "1. Setup GPG key:"
	@echo "   make setup-gpg"
	@echo ""
	@echo "2. Build all variants:"
	@echo "   make all"
	@echo ""
	@echo "3. Or build specific variant:"
	@echo "   make VARIANT=phosh-ebbg"
	@echo ""
	@echo "4. Setup local repository:"
	@echo "   make repo"
	@echo ""
	@echo "5. Install to device:"
	@echo "   make install"
	@echo ""
	@echo "Or use Docker:"
	@echo "   make docker-build"
