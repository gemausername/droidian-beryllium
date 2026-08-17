#!/bin/bash
# Master Build Script for Droidian Poco F1
# This script orchestrates the entire build process

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_header() {
    echo -e "${CYAN}"
    echo "============================================"
    echo "  Droidian Build System for Poco F1"
    echo "  (beryllium)"
    echo "============================================"
    echo -e "${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_header

# Parse command line arguments
BUILD_ALL=false
BUILD_KERNEL=false
BUILD_ADAPTATION=false
BUILD_ROOTFS=false
SETUP_REPO=false
INSTALL=false

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all           Build everything"
    echo "  --kernel        Build kernel package"
    echo "  --adaptation    Build adaptation package"
    echo "  --rootfs        Build rootfs image"
    echo "  --repo          Setup local repository"
    echo "  --install       Install to device"
    echo "  --gpg           Setup GPG key"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all        # Build everything"
    echo "  $0 --kernel     # Build only kernel"
    echo "  $0 --gpg        # Setup GPG key first"
}

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            BUILD_ALL=true
            shift
            ;;
        --kernel)
            BUILD_KERNEL=true
            shift
            ;;
        --adaptation)
            BUILD_ADAPTATION=true
            shift
            ;;
        --rootfs)
            BUILD_ROOTFS=true
            shift
            ;;
        --repo)
            SETUP_REPO=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --gpg)
            print_step "Running GPG setup..."
            bash "${SCRIPT_DIR}/setup-gpg.sh"
            exit 0
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# If --all is set, enable all build options
if [ "$BUILD_ALL" = true ]; then
    BUILD_KERNEL=true
    BUILD_ADAPTATION=true
    BUILD_ROOTFS=true
    SETUP_REPO=true
fi

# Create output directory
mkdir -p "${PROJECT_DIR}/output"

print_msg "Build configuration:"
print_msg "  Project directory: ${PROJECT_DIR}"
print_msg "  Build kernel: ${BUILD_KERNEL}"
print_msg "  Build adaptation: ${BUILD_ADAPTATION}"
print_msg "  Build rootfs: ${BUILD_ROOTFS}"
print_msg "  Setup repository: ${SETUP_REPO}"
echo ""

# Step 1: GPG Setup (if needed)
if [ ! -f "${HOME}/.gnupg/trustdb.gpg" ]; then
    print_warn "GPG key not found!"
    read -p "Do you want to setup GPG key now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bash "${SCRIPT_DIR}/setup-gpg.sh"
    fi
fi

# Step 2: Build Kernel
if [ "$BUILD_KERNEL" = true ]; then
    print_step "Building kernel package..."
    bash "${SCRIPT_DIR}/build-kernel.sh"
fi

# Step 3: Build Adaptation Package
if [ "$BUILD_ADAPTATION" = true ]; then
    print_step "Building adaptation package..."
    bash "${SCRIPT_DIR}/build-adaptation.sh"
fi

# Step 4: Build Rootfs
if [ "$BUILD_ROOTFS" = true ]; then
    print_step "Building rootfs image..."
    bash "${PROJECT_DIR}/rootfs/build-rootfs.sh"
fi

# Step 5: Setup Repository
if [ "$SETUP_REPO" = true ]; then
    print_step "Setting up local repository..."
    sudo bash "${SCRIPT_DIR}/setup-repository.sh"
fi

# Step 6: Install to Device
if [ "$INSTALL" = true ]; then
    print_step "Installing to device..."
    bash "${SCRIPT_DIR}/install-to-device.sh"
fi

print_msg ""
print_msg "=========================================="
print_msg "Build Process Complete!"
print_msg "=========================================="
print_msg ""
print_msg "Output files are in: ${PROJECT_DIR}/output"
print_msg ""
ls -lh "${PROJECT_DIR}/output/" 2>/dev/null || print_warn "No output files found"
print_msg ""
print_msg "Next steps:"
print_msg "1. Setup APT repository (if not done)"
print_msg "2. Install packages on your Poco F1"
print_msg "3. Enjoy Droidian!"
