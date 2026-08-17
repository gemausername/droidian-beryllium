#!/bin/bash
# Kernel Build Script for Xiaomi Poco F1 (beryllium)
# This script builds the Droidian kernel package

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

# Configuration
KERNEL_REPO="https://github.com/nicknormandin/linux_android_xiaomi_beryllium.git"
KERNEL_BRANCH="lineage-20"
PACKAGES_DIR="${HOME}/droidian/packages"
KERNEL_DIR="${HOME}/droidian/kernel/beryllium"

# Check if running as non-root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

print_step "1. Setting up directories..."
mkdir -p "${PACKAGES_DIR}"
mkdir -p "${KERNEL_DIR}"

print_step "2. Cloning kernel sources..."
if [ -d "${KERNEL_DIR}/.git" ]; then
    print_msg "Kernel repository already exists, pulling latest changes..."
    cd "${KERNEL_DIR}"
    git pull
else
    print_msg "Cloning kernel repository..."
    git clone --depth 1 -b "${KERNEL_BRANCH}" "${KERNEL_REPO}" "${KERNEL_DIR}"
    cd "${KERNEL_DIR}"
fi

print_step "3. Creating Droidian branch..."
if ! git branch | grep -q "droidian"; then
    git checkout -b droidian
else
    git checkout droidian
fi

print_step "4. Starting Docker build container..."
print_msg "This will open a Docker container for building."
print_msg "Follow the instructions inside the container."
echo ""

docker run --rm \
    -v "${PACKAGES_DIR}:/buildd" \
    -v "${KERNEL_DIR}:/buildd/sources" \
    -it quay.io/droidian/build-essential:current-amd64 bash << 'DOCKER_EOF'

# Inside Docker container
set -e

print_msg() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

print_step() {
    echo -e "\033[0;34m[STEP]\033[0m $1"
}

print_step "Installing required packages..."
apt-get update
apt-get install -y linux-packaging-snippets

print_step "Setting up Debian packaging..."
cd /buildd/sources

# Create packaging skeleton
mkdir -p debian/source
cp -v /usr/share/linux-packaging-snippets/kernel-info.mk.example debian/kernel-info.mk
echo "13" > debian/compat
echo "3.0 (native)" > debian/source/format

# Create rules file
cat > debian/rules << 'RULES_EOF'
#!/usr/bin/make -f

include /usr/share/linux-packaging-snippets/kernel-snippet.mk

%:
	dh $@
RULES_EOF
chmod +x debian/rules

print_msg ""
print_msg "=========================================="
print_msg "Docker container ready!"
print_msg "=========================================="
print_msg ""
print_msg "Now edit debian/kernel-info.mk with your settings."
print_msg ""
print_msg "Key settings to modify:"
print_msg "  - KERNEL_BASE_VERSION"
print_msg "  - KERNEL_DEFCONFIG"
print_msg "  - KERNEL_BOOTIMAGE_CMDLINE"
print_msg "  - All BOOTIMAGE offsets"
print_msg ""
print_msg "After editing, run:"
print_msg "  debian/rules debian/control"
print_msg "  RELENG_HOST_ARCH=\"arm64\" releng-build-package"
print_msg ""
print_msg "Type 'exit' when done."
print_msg ""

# Keep container open for manual steps
exec /bin/bash

DOCKER_EOF

print_msg ""
print_msg "Kernel build process completed!"
print_msg "Packages should be in: ${PACKAGES_DIR}"
print_msg ""
ls -lh "${PACKAGES_DIR}"/*.deb 2>/dev/null || print_warn "No .deb files found. Check for build errors."
