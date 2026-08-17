#!/bin/bash
# Rootfs build script for Xiaomi Poco F1 (beryllium)
# This script builds the Droidian rootfs image for beryllium

set -e

# Device configuration
VENDOR="xiaomi"
CODENAME="beryllium"
ARCH="arm64"
APIVER="28"
FORMFACTOR="phone"
DESKTOP="phosh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check for required packages
print_msg "Checking required packages..."
apt-get update
apt-get install -y dpkg-dev gpg git apt-utils

# Initialize qemu-user-static for cross-architecture builds
print_msg "Initializing qemu-user-static for cross-architecture builds..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Create output directory
OUTPUT_DIR="${PROJECT_DIR}/output"
mkdir -p "$OUTPUT_DIR"

print_msg "Building rootfs for ${CODENAME} (${VENDOR})..."
print_msg "Architecture: ${ARCH}"
print_msg "API Version: ${APIVER}"
print_msg "Desktop: ${DESKTOP}"
print_msg "Output directory: ${OUTPUT_DIR}"

# Pull rootfs-builder Docker image
print_msg "Pulling rootfs-builder Docker image..."
docker pull quay.io/droidian/rootfs-builder:current-amd64

# Run debos in Docker container
print_msg "Building rootfs image..."
docker run --privileged \
    -v "${OUTPUT_DIR}:/buildd/out" \
    -v "/dev:/host-dev" \
    -v "/sys/fs/cgroup:/sys/fs/cgroup" \
    -v "${PROJECT_DIR}:/buildd/sources" \
    --security-opt seccomp:unconfined \
    --cgroupns host \
    quay.io/droidian/rootfs-builder:current-amd64 \
    /bin/sh -c "cd /buildd/sources; \
        DROIDIAN_VERSION=\"next\" \
        ./generate_device_recipe.py ${VENDOR}_${CODENAME} ${ARCH} ${DESKTOP} ${FORMFACTOR} ${APIVER} && \
        debos --disable-fakemachine generated/droidian.yaml"

# Check if build was successful
if [ $? -eq 0 ]; then
    print_msg "Rootfs build completed successfully!"
    print_msg "Output images are in: ${OUTPUT_DIR}"
    ls -lh "${OUTPUT_DIR}"
else
    print_error "Rootfs build failed!"
    exit 1
fi

print_msg "Build process finished."
print_msg ""
print_msg "Next steps:"
print_msg "1. Flash the boot.img to your device"
print_msg "2. Flash the rootfs.img using fastboot"
print_msg "3. Boot into Droidian"
print_msg ""
print_msg "For more information, see the README.md file."
