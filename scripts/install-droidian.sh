#!/bin/bash
# Droidian Installation Script for Xiaomi Poco F1 (beryllium)
# Complete flashing guide with all methods

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_msg() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║         Droidian Flash Guide for Xiaomi Poco F1             ║"
    echo "║                      (beryllium)                             ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_header

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_DIR}/output"

# Check if running on Windows or Linux
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    FASTBOOT="fastboot.exe"
    ADB="adb.exe"
    PLATFORM="windows"
else
    FASTBOOT="fastboot"
    ADB="adb"
    PLATFORM="linux"
fi

# ============================================
# STEP 1: Prerequisites
# ============================================
print_step "Step 1: Checking prerequisites"
echo ""

# Check ADB
if command -v $ADB &> /dev/null; then
    print_msg "ADB found: $($ADB version 2>&1 | head -1)"
else
    print_warn "ADB not found (optional but recommended)"
fi

# Check fastboot
if command -v $FASTBOOT &> /dev/null; then
    print_msg "Fastboot found: $($FASTBOOT --version 2>&1 | head -1)"
else
    print_error "Fastboot not found!"
    echo ""
    echo "Install Android platform-tools:"
    echo ""
    echo "Windows:"
    echo "  1. Download: https://developer.android.com/tools/releases/platform-tools"
    echo "  2. Extract to C:\platform-tools"
    echo "  3. Add to PATH"
    echo ""
    echo "Linux:"
    echo "  sudo apt install android-tools-fastboot android-tools-adb"
    echo ""
    echo "macOS:"
    echo "  brew install android-platform-tools"
    echo ""
    exit 1
fi

# Check device
print_step "Checking device connection..."
echo ""

echo "Boot your Poco F1 to fastboot mode:"
echo "  1. Power off the device completely"
echo "  2. Hold Volume- and Power simultaneously"
echo "  3. Release when vibration is felt"
echo "  4. Device should show fastboot logo"
echo ""
read -p "Press Enter when device is in fastboot mode..."

if $FASTBOOT getvar product 2>&1 | grep -q "beryllium"; then
    print_msg "Poco F1 detected in fastboot mode!"
    $FASTBOOT getvar product
else
    print_error "Device not detected!"
    echo ""
    echo "Troubleshooting:"
    echo "  - Make sure USB cable is connected"
    echo "  - Try different USB port"
    echo "  - Install USB drivers (Windows)"
    echo "  - Run: $FASTBOOT devices"
    echo ""
    exit 1
fi

echo ""

# ============================================
# STEP 2: Download required files
# ============================================
print_step "Step 2: Required files"
echo ""

echo "You need the following files:"
echo ""
echo "1. Boot image (kernel):"
echo "   - Build: make kernel"
echo "   - Download: https://github.com/Unofficial-droidian-for-pocof1/linux_android_xiaomi_beryllium/releases"
echo ""
echo "2. Rootfs image:"
echo "   - Build: make rootfs"
echo "   - Download: https://github.com/droidian-images/rootfs-api28gsi-all/releases"
echo ""
echo "3. Vendor image (optional):"
echo "   - Download: https://github.com/ubports-beryllium/artifacts/releases/download/v3/vendor.img"
echo ""
echo "4. Android 9 firmware (required for first install):"
echo "   - Download: https://xiaomifirmwareupdater.com/download/?file=fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip"
echo ""

# Check for files
echo "Looking for files in: $OUTPUT_DIR"
echo ""

FOUND_FILES=()
if [ -f "${OUTPUT_DIR}/out/KERNEL_OBJ/boot.img" ]; then
    FOUND_FILES+=("boot.img")
    print_msg "Found: boot.img"
fi
if [ -f "${OUTPUT_DIR}/droidian-rootfs-arm64.img" ]; then
    FOUND_FILES+=("rootfs.img")
    print_msg "Found: rootfs.img"
fi
if [ -f "${OUTPUT_DIR}/vendor.img" ]; then
    FOUND_FILES+=("vendor.img")
    print_msg "Found: vendor.img"
fi

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    print_warn "No files found in output directory!"
    echo "Please download required files first."
    echo ""
    read -p "Press Enter to continue anyway (you'll need to provide file paths)..."
fi

echo ""

# ============================================
# STEP 3: Flash boot image
# ============================================
print_step "Step 3: Flash boot image (kernel)"
echo ""

# Find boot image
BOOT_IMG=""
for f in "${OUTPUT_DIR}/out/KERNEL_OBJ/boot.img" \
         "${OUTPUT_DIR}/boot.img" \
         "${OUTPUT_DIR}/droidian-boot-beryllium.img" \
         "${PROJECT_DIR}/images/boot.img"; do
    if [ -f "$f" ]; then
        BOOT_IMG="$f"
        break
    fi
done

if [ -z "$BOOT_IMG" ]; then
    read -p "Enter path to boot.img: " BOOT_IMG
fi

if [ -f "$BOOT_IMG" ]; then
    print_msg "Flashing boot image: $BOOT_IMG"
    $FASTBOOT flash boot "$BOOT_IMG"
    print_msg "Boot image flashed successfully!"
else
    print_error "Boot image not found: $BOOT_IMG"
    echo "Skipping boot image flash."
fi

echo ""

# ============================================
# STEP 4: Flash rootfs (optional)
# ============================================
print_step "Step 4: Flash rootfs (optional - can be done via TWRP)"
echo ""

read -p "Do you want to flash rootfs via fastboot? (y/N): " FLASH_ROOTFS

if [[ "$FLASH_ROOTFS" =~ ^[Yy]$ ]]; then
    ROOTFS_IMG=""
    for f in "${OUTPUT_DIR}/droidian-rootfs-arm64.img" \
             "${OUTPUT_DIR}/system.img"; do
        if [ -f "$f" ]; then
            ROOTFS_IMG="$f"
            break
        fi
    done
    
    if [ -z "$ROOTFS_IMG" ]; then
        read -p "Enter path to rootfs.img: " ROOTFS_IMG
    fi
    
    if [ -f "$ROOTFS_IMG" ]; then
        print_msg "Flashing rootfs image: $ROOTFS_IMG"
        $FASTBOOT flash system "$ROOTFS_IMG"
        print_msg "Rootfs flashed successfully!"
    else
        print_error "Rootfs image not found: $ROOTFS_IMG"
        echo "Skipping rootfs flash."
    fi
else
    print_msg "Skipping rootfs flash."
    echo "You can flash rootfs later via TWRP."
fi

echo ""

# ============================================
# STEP 5: Flash vendor (optional)
# ============================================
print_step "Step 5: Flash vendor image (optional)"
echo ""

read -p "Do you want to flash vendor image? (y/N): " FLASH_VENDOR

if [[ "$FLASH_VENDOR" =~ ^[Yy]$ ]]; then
    VENDOR_IMG=""
    for f in "${OUTPUT_DIR}/vendor.img" \
             "${PROJECT_DIR}/images/vendor.img"; do
        if [ -f "$f" ]; then
            VENDOR_IMG="$f"
            break
        fi
    done
    
    if [ -z "$VENDOR_IMG" ]; then
        read -p "Enter path to vendor.img: " VENDOR_IMG
    fi
    
    if [ -f "$VENDOR_IMG" ]; then
        print_msg "Flashing vendor image: $VENDOR_IMG"
        $FASTBOOT flash vendor "$VENDOR_IMG"
        print_msg "Vendor image flashed successfully!"
    else
        print_error "Vendor image not found: $VENDOR_IMG"
        echo "Skipping vendor flash."
    fi
else
    print_msg "Skipping vendor flash."
fi

echo ""

# ============================================
# STEP 6: Wipe partitions (optional)
# ============================================
print_step "Step 6: Wipe userdata (optional)"
echo ""

read -p "Do you want to wipe userdata? (y/N): " WIPE_USERDATA

if [[ "$WIPE_USERDATA" =~ ^[Yy]$ ]]; then
    print_warn "WARNING: This will wipe ALL data on the device!"
    read -p "Are you sure? (yes/no): " CONFIRM_WIPE
    if [[ "$CONFIRM_WIPE" == "yes" ]]; then
        print_msg "Wiping userdata..."
        $FASTBOOT -w
        print_msg "Userdata wiped!"
    else
        print_msg "Skipping userdata wipe."
    fi
else
    print_msg "Skipping userdata wipe."
fi

echo ""

# ============================================
# STEP 7: Reboot
# ============================================
print_step "Step 7: Reboot device"
echo ""

read -p "Reboot device now? (Y/n): " DO_REBOOT
if [[ ! "$DO_REBOOT" =~ ^[Nn]$ ]]; then
    print_msg "Rebooting device..."
    $FASTBOOT reboot
    print_msg "Device is rebooting!"
else
    print_msg "Device will stay in fastboot mode."
    echo "To reboot manually: $FASTBOOT reboot"
fi

echo ""

# ============================================
# POST-INSTALL
# ============================================
echo ""
echo "=========================================="
print_msg "Installation completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Wait for first boot (3-5 minutes)"
echo ""
echo "2. Default unlock code: 1234"
echo ""
echo "3. After boot, install adaptation package:"
echo "   Connect via SSH or USB"
echo "   Copy .deb file to device"
echo "   Install: sudo dpkg -i adaptation-droidian-beryllium-<variant>.deb"
echo "   Reboot: sudo reboot"
echo ""
echo "4. If bootloop occurs:"
echo "   - Boot to TWRP (Vol+ and Power)"
echo "   - Wipe cache/dalvik"
echo "   - Try different boot image"
echo ""
echo "5. Useful commands:"
echo "   - $FASTBOOT devices"
echo "   - $FASTBOOT getvar all"
echo "   - $FASTBOOT boot twrp.img"
echo ""
echo "=========================================="
