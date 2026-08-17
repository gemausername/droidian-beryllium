#!/bin/bash
# Master Build Script for Droidian Poco F1 - Multi-Variant Support
# This script builds all variants or specific variants

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║        Droidian Build System for Poco F1 (beryllium)         ║"
    echo "║                    Multi-Variant Support                     ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Available variants
VARIANTS=(
    "phosh-ebbg"
    "phosh-tianma"
    "phosh-tianmaft"
    "lomiri-ebbg"
    "lomiri-tianma"
    "lomiri-tianmaft"
)

# Available desktops
DESKTOPS=("phosh" "lomiri")

# Available panels
PANELS=("ebbg" "tianma" "tianmaft")

# Show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --all           Build all variants"
    echo "  --variant NAME  Build specific variant (e.g., phosh-ebbg)"
    echo "  --desktop DE    Build all variants for a desktop (phosh/lomiri)"
    echo "  --panel PANEL   Build all variants for a panel (ebbg/tianma/tianmaft)"
    echo "  --list          List all available variants"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Build all 6 variants"
    echo "  $0 --variant phosh-ebbg     # Build Phosh + eBBG only"
    echo "  $0 --desktop phosh          # Build all Phosh variants"
    echo "  $0 --panel tianma           # Build all Tianma variants"
    echo ""
    echo "Available variants:"
    for v in "${VARIANTS[@]}"; do
        echo "  - $v"
    done
}

# List variants
list_variants() {
    echo ""
    echo "Available variants:"
    echo ""
    echo -e "${CYAN}Desktop: Phosh${NC}"
    for panel in "${PANELS[@]}"; do
        echo "  - phosh-$panel"
    done
    echo ""
    echo -e "${CYAN}Desktop: Lomiri${NC}"
    for panel in "${PANELS[@]}"; do
        echo "  - lomiri-$panel"
    done
    echo ""
    echo "Total: ${#VARIANTS[@]} variants"
}

# Build single variant
build_variant() {
    local variant="$1"
    local variant_dir="${PROJECT_DIR}/variants/${variant}"
    
    if [ ! -d "$variant_dir" ]; then
        print_error "Variant not found: $variant"
        return 1
    fi
    
    print_step "Building variant: $variant"
    
    # Source variant config
    source "${variant_dir}/variant.conf"
    
    print_msg "Desktop: $DESKTOP"
    print_msg "Panel: $PANEL_TYPE"
    print_msg "Build target: $BUILD_TARGET"
    echo ""
    
    # Build adaptation package for this variant
    print_step "Building adaptation package..."
    bash "${SCRIPT_DIR}/build-adaptation-variant.sh" "$variant"
    
    # Build rootfs for this variant
    print_step "Building rootfs image..."
    bash "${SCRIPT_DIR}/build-rootfs-variant.sh" "$variant"
    
    print_msg "Variant $variant built successfully!"
}

# Build multiple variants
build_variants() {
    local variants=("$@")
    local total=${#variants[@]}
    local current=0
    
    for variant in "${variants[@]}"; do
        current=$((current + 1))
        echo ""
        echo -e "${MAGENTA}[$current/$total] Building variant: $variant${NC}"
        echo ""
        build_variant "$variant"
    done
}

# Parse arguments
BUILD_ALL=false
BUILD_VARIANT=""
BUILD_DESKTOP=""
BUILD_PANEL=""
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            BUILD_ALL=true
            shift
            ;;
        --variant)
            BUILD_VARIANT="$2"
            shift 2
            ;;
        --desktop)
            BUILD_DESKTOP="$2"
            shift 2
            ;;
        --panel)
            BUILD_PANEL="$2"
            shift 2
            ;;
        --list)
            LIST_ONLY=true
            shift
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

print_header

# List variants
if [ "$LIST_ONLY" = true ]; then
    list_variants
    exit 0
fi

# Create output directory
mkdir -p "${PROJECT_DIR}/output"

# Determine what to build
if [ "$BUILD_ALL" = true ]; then
    print_msg "Building all variants..."
    build_variants "${VARIANTS[@]}"
elif [ -n "$BUILD_VARIANT" ]; then
    build_variant "$BUILD_VARIANT"
elif [ -n "$BUILD_DESKTOP" ]; then
    if [[ ! " ${DESKTOPS[@]} " =~ " ${BUILD_DESKTOP} " ]]; then
        print_error "Invalid desktop: $BUILD_DESKTOP"
        print_msg "Available desktops: ${DESKTOPS[*]}"
        exit 1
    fi
    print_msg "Building all $BUILD_DESKTOP variants..."
    variants=()
    for panel in "${PANELS[@]}"; do
        variants+=("${BUILD_DESKTOP}-${panel}")
    done
    build_variants "${variants[@]}"
elif [ -n "$BUILD_PANEL" ]; then
    if [[ ! " ${PANELS[@]} " =~ " ${BUILD_PANEL} " ]]; then
        print_error "Invalid panel: $BUILD_PANEL"
        print_msg "Available panels: ${PANELS[*]}"
        exit 1
    fi
    print_msg "Building all $BUILD_PANEL variants..."
    variants=()
    for desktop in "${DESKTOPS[@]}"; do
        variants+=("${desktop}-${BUILD_PANEL}")
    done
    build_variants "${variants[@]}"
else
    show_help
    exit 1
fi

print_msg ""
print_msg "=========================================="
print_msg "Build Complete!"
print_msg "=========================================="
print_msg ""
print_msg "Output files: ${PROJECT_DIR}/output"
ls -lh "${PROJECT_DIR}/output/" 2>/dev/null || print_warn "No output files found"
