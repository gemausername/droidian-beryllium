#!/bin/bash
# Build Rootfs for Specific Variant
# Usage: ./build-rootfs-variant.sh <variant>

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check variant argument
if [ -z "$1" ]; then
    print_error "Usage: $0 <variant>"
    print_error "Example: $0 phosh-ebbg"
    exit 1
fi

VARIANT="$1"
VARIANT_DIR="${PROJECT_DIR}/variants/${VARIANT}"

# Check if variant exists
if [ ! -d "$VARIANT_DIR" ]; then
    print_error "Variant not found: $VARIANT"
    exit 1
fi

# Source variant config
source "${VARIANT_DIR}/variant.conf"

print_step "Building rootfs for: $VARIANT"
print_msg "Desktop: $DESKTOP"
print_msg "Panel: $PANEL_TYPE"

# Check for Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Initialize qemu-user-static for cross-architecture builds
print_msg "Initializing qemu-user-static for cross-architecture builds..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Create variant-specific community_devices.yml
COMMUNITY_DEVICES="${PROJECT_DIR}/rootfs/droidian/community_devices_${VARIANT}.yml"

cat > "$COMMUNITY_DEVICES" << EOF
# Community devices configuration for Droidian
# Xiaomi Poco F1 (beryllium) - ${VARIANT}

beryllium:
  vendor: xiaomi
  codename: beryllium
  name: "Poco F1"
  arch: arm64
  api: 28
  gsiconfig:
    enabled: true
  desktop: ${DESKTOP}
  formfactor: phone
  community: true
  maintainer: "Droidian Community"
  description: "Xiaomi Poco F1 (SDM845) - ${VARIANT}"

  packages:
    - adaptation-droidian-beryllium-${VARIANT}
    - linux-image-*

  overlays:
    - path: /usr/lib/droidian/device
      contents:
        - path: encryption-supported
          empty: true
        - path: flashlightd-sysfs
          empty: true
        - path: flashlightd-sysfs-nodes
          content: "/sys/class/leds/lcd-backlight/brightness"
EOF

# Create variant-specific build script
BUILD_SCRIPT="${PROJECT_DIR}/rootfs/build-rootfs-${VARIANT}.sh"

cat > "$BUILD_SCRIPT" << BUILDEOF
#!/bin/bash
# Rootfs build script for Xiaomi Poco F1 (${VARIANT})

set -e

# Device configuration
VENDOR="xiaomi"
CODENAME="beryllium"
ARCH="arm64"
APIVER="28"
FORMFACTOR="phone"
DESKTOP="${DESKTOP}"
VARIANT="${VARIANT}"

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

print_msg() {
    echo -e "\${GREEN}[INFO]\${NC} \$1"
}

print_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Check if running as root
if [ "\$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Get script directory
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="\$(dirname "\$SCRIPT_DIR")"

# Create output directory
OUTPUT_DIR="\${PROJECT_DIR}/output"
mkdir -p "\$OUTPUT_DIR"

print_msg "Building rootfs for \${CODENAME} (\${VARIANT})..."
print_msg "Architecture: \${ARCH}"
print_msg "API Version: \${APIVER}"
print_msg "Desktop: \${DESKTOP}"

# Pull rootfs-builder Docker image
print_msg "Pulling rootfs-builder Docker image..."
docker pull quay.io/droidian/rootfs-builder:current-amd64

# Run debos in Docker container
print_msg "Building rootfs image..."
docker run --privileged \\
    -v "\${OUTPUT_DIR}:/buildd/out" \\
    -v "/dev:/host-dev" \\
    -v "/sys/fs/cgroup:/sys/fs/cgroup" \\
    -v "\${PROJECT_DIR}:/buildd/sources" \\
    --security-opt seccomp:unconfined \\
    --cgroupns host \\
    quay.io/droidian/rootfs-builder:current-amd64 \\
    /bin/sh -c "cd /buildd/sources; \\
        DROIDIAN_VERSION=\\"next\\" \\
        ./generate_device_recipe.py \${VENDOR}_\${CODENAME} \${ARCH} \${DESKTOP} \${FORMFACTOR} \${APIVER} && \\
        debos --disable-fakemachine generated/droidian.yaml"

# Check if build was successful
if [ \$? -eq 0 ]; then
    print_msg "Rootfs build completed successfully!"
    print_msg "Output images are in: \${OUTPUT_DIR}"
    ls -lh "\${OUTPUT_DIR}"
else
    print_error "Rootfs build failed!"
    exit 1
fi

print_msg "Build process finished."
BUILDEOF

chmod +x "$BUILD_SCRIPT"

# Build the rootfs
print_step "Building rootfs image..."
cd "${PROJECT_DIR}/rootfs"
bash "build-rootfs-${VARIANT}.sh"

print_msg "Rootfs for $VARIANT built successfully!"
