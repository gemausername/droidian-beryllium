#!/bin/bash
# Adaptation Package Build Script
# This script builds the adaptation package for Poco F1

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if running as non-root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Check for required packages
print_step "1. Checking required packages..."
if ! dpkg -l | grep -q "dpkg-dev"; then
    print_msg "Installing dpkg-dev..."
    sudo apt-get update
    sudo apt-get install -y dpkg-dev build-essential devscripts
fi

print_step "2. Building adaptation package..."
cd "${PROJECT_DIR}/packages/adaptation-droidian-beryllium"

print_msg "Building package..."
dpkg-buildpackage -b -uc -us

print_step "3. Checking build output..."
if [ -f "${PROJECT_DIR}/../adaptation-droidian-beryllium_1.0_arm64.deb" ]; then
    print_msg "Package built successfully!"
    ls -lh "${PROJECT_DIR}/../adaptation-droidian-beryllium_1.0_arm64.deb"
    
    # Copy to output directory
    mkdir -p "${PROJECT_DIR}/output"
    cp "${PROJECT_DIR}/../adaptation-droidian-beryllium_1.0_arm64.deb" "${PROJECT_DIR}/output/"
    print_msg "Package copied to: ${PROJECT_DIR}/output/"
else
    print_error "Package build failed!"
    exit 1
fi

print_msg "Build completed successfully!"
print_msg ""
print_msg "Package location: ${PROJECT_DIR}/output/adaptation-droidian-beryllium_1.0_arm64.deb"
print_msg ""
print_msg "Next steps:"
print_msg "1. Copy the .deb package to your APT repository"
print_msg "2. Sign the package with GPG"
print_msg "3. Update the Packages file"
