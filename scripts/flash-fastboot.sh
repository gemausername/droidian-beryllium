#!/bin/bash
# Fastboot Flash Tool for Xiaomi Poco F1 (beryllium)
# Droidian Porting Project

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

# Check if running on Windows or Linux
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    FASTBOOT="fastboot.exe"
    ADB="adb.exe"
    PLATFORM="windows"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    FASTBOOT="fastboot"
    ADB="adb"
    PLATFORM="macos"
else
    FASTBOOT="sudo fastboot"
    ADB="sudo adb"
    PLATFORM="linux"
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Output directory
OUTPUT_DIR="${PROJECT_DIR}/output"

print_step "Droidian Flash Tool for Xiaomi Poco F1"
echo ""

# ============================================
# SECTION 1: Check prerequisites
# ============================================
print_step "Checking prerequisites..."

# Check fastboot
if ! command -v $FASTBOOT &> /dev/null; then
    print_error "Fastboot not found!"
    echo "Install Android platform-tools:"
    echo "  Windows: https://developer.android.com/tools/releases/platform-tools"
    echo "  Linux: sudo apt install android-tools-fastboot"
    echo "  macOS: brew install android-platform-tools"
    exit 1
fi
print_msg "Fastboot found: $($FASTBOOT --version 2>/dev/null || echo 'installed')"

# Check ADB
if ! command -v $ADB &> /dev/null; then
    print_warn "ADB not found (optional but recommended)"
fi

# Check device connection
print_step "Checking device connection..."
if $FASTBOOT getvar product 2>&1 | grep -q "beryllium"; then
    print_msg "Poco F1 detected in fastboot mode!"
else
    print_warn "Device not detected. Please boot to fastboot:"
    echo "  1. Power off the device"
    echo "  2. Hold Vol- and Power simultaneously"
    echo "  3. Release when vibration is felt"
    echo ""
    print_msg "Or use ADB: $ADB reboot bootloader"
    exit 1
fi

echo ""

# ============================================
# SECTION 2: Select variant
# ============================================
print_step "Select variant to flash:"
echo ""
echo "  1) phosh-ebbg      (Phosh + eBBG Panel)"
echo "  2) phosh-tianma    (Phosh + Tianma Panel)"
echo "  3) phosh-tianmaft  (Phosh + Tianma + Focaltech)"
echo "  4) lomiri-ebbg     (Lomiri + eBBG Panel)"
echo "  5) lomiri-tianma   (Lomiri + Tianma Panel)"
echo "  6) lomiri-tianmaft (Lomiri + Tianma + Focaltech)"
echo ""
read -p "Select variant (1-6): " CHOICE

case $CHOICE in
    1) VARIANT="phosh-ebbg"; DESKTOP="phosh"; PANEL="ebbg" ;;
    2) VARIANT="phosh-tianma"; DESKTOP="phosh"; PANEL="tianma" ;;
    3) VARIANT="phosh-tianmaft"; DESKTOP="phosh"; PANEL="tianmaft" ;;
    4) VARIANT="lomiri-ebbg"; DESKTOP="lomiri"; PANEL="ebbg" ;;
    5) VARIANT="lomiri-tianma"; DESKTOP="lomiri"; PANEL="tianma" ;;
    6) VARIANT="lomiri-tianmaft"; DESKTOP="lomiri"; PANEL="tianmaft" ;;
    *) print_error "Invalid choice"; exit 1 ;;
esac

print_msg "Selected: $VARIANT"
echo ""

# ============================================
# SECTION 3: Locate images
# ============================================
print_step "Looking for images..."

# Check for required files
KERNEL_IMG=""
BOOT_IMG=""
ROOTFS_IMG=""
ADAPTATION_DEB=""
VENDOR_IMG=""
SYSTEM_IMG=""

# Find kernel/boot image
for f in "${OUTPUT_DIR}/out/KERNEL_OBJ/boot.img" \
         "${OUTPUT_DIR}/boot.img" \
         "${OUTPUT_DIR}/droidian-boot-beryllium.img" \
         "${PROJECT_DIR}/images/boot.img"; do
    if [ -f "$f" ]; then
        BOOT_IMG="$f"
        break
    fi
done

# Find rootfs
for f in "${OUTPUT_DIR}/droidian-rootfs-${DESKTOP}-arm64.img" \
         "${OUTPUT_DIR}/droidian-rootfs-api28gsi_arm64.img" \
         "${OUTPUT_DIR}/system.img"; do
    if [ -f "$f" ]; then
        ROOTFS_IMG="$f"
        break
    fi
done

# Find adaptation
for f in "${OUTPUT_DIR}/adaptation-droidian-beryllium-${VARIANT}.deb" \
         "${OUTPUT_DIR}/adaptation-droidian-beryllium_${VARIANT}_*.deb"; do
    if [ -f "$f" ]; then
        ADAPTATION_DEB="$f"
        break
    fi
done

# Find vendor image
for f in "${OUTPUT_DIR}/vendor.img" \
         "${PROJECT_DIR}/images/vendor.img"; do
    if [ -f "$f" ]; then
        VENDOR_IMG="$f"
        break
    fi
done

echo ""
echo "Found files:"
echo "  Boot image:    ${BOOT_IMG:-NOT FOUND}"
echo "  Rootfs image:  ${ROOTFS_IMG:-NOT FOUND}"
echo "  Adaptation:    ${ADAPTATION_DEB:-NOT FOUND}"
echo "  Vendor image:  ${VENDOR_IMG:-NOT FOUND}"
echo ""

if [ -z "$BOOT_IMG" ]; then
    print_error "Boot image not found!"
    echo "Build kernel first: make kernel"
    echo "Or download from: https://github.com/Unofficial-droidian-for-pocof1/linux_android_xiaomi_beryllium/releases"
    exit 1
fi

if [ -z "$ROOTFS_IMG" ]; then
    print_warn "Rootfs image not found. You'll need to flash rootfs separately."
    echo "Build rootfs first: make rootfs"
    echo "Or download from: https://github.com/droidian-images/rootfs-api28gsi-all/releases"
fi

echo ""

# ============================================
# SECTION 4: Confirmation
# ============================================
print_warn "WARNING: This will wipe your device!"
echo ""
echo "Make sure you have:"
echo "  - Unlocked bootloader"
echo "  - TWRP recovery (optional but recommended)"
echo "  - All required files"
echo ""
read -p "Continue with flashing? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# ============================================
# SECTION 5: Flash partitions
# ============================================

# 5.1 Flash boot/kernel
print_step "1/5: Flashing boot image..."
$FASTBOOT flash boot "$BOOT_IMG"
print_msg "Boot image flashed!"
echo ""

# 5.2 Flash rootfs (system)
if [ -n "$ROOTFS_IMG" ]; then
    print_step "2/5: Flashing rootfs (system partition)..."
    $FASTBOOT flash system "$ROOTFS_IMG"
    print_msg "Rootfs flashed!"
else
    print_warn "2/5: Skipping rootfs (not found)"
fi
echo ""

# 5.3 Flash vendor
if [ -n "$VENDOR_IMG" ]; then
    print_step "3/5: Flashing vendor image..."
    $FASTBOOT flash vendor "$VENDOR_IMG"
    print_msg "Vendor image flashed!"
else
    print_warn "3/5: Skipping vendor (not found)"
fi
echo ""

# 5.4 Wipe userdata
print_step "4/5: Wiping userdata partition..."
$FASTBOOT -w
print_msg "Userdata wiped!"
echo ""

# 5.5 Reboot
print_step "5/5: Rebooting device..."
$FASTBOOT reboot
print_msg "Device rebooting..."
echo ""

# ============================================
# SECTION 6: Post-flash instructions
# ============================================
echo ""
echo "=========================================="
print_msg "Flashing completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Wait for device to boot (first boot takes 3-5 minutes)"
echo ""
echo "2. Default unlock code: 1234"
echo ""
echo "3. After boot, install adaptation package:"
echo "   - Connect via SSH or USB"
echo "   - Copy adaptation .deb to device"
echo "   - Install: sudo dpkg -i adaptation-droidian-beryllium-${VARIANT}.deb"
echo "   - Reboot: sudo reboot"
echo ""
echo "4. If bootloop occurs:"
echo "   - Boot to TWRP"
echo "   - Wipe cache/dalvik"
echo "   - Try different boot image"
echo ""
echo "5. Useful commands:"
echo "   - Check device: $FASTBOOT devices"
echo "   - Check vars: $FASTBOOT getvar all"
echo "   - Boot recovery: $FASTBOOT boot twrp.img"
echo ""
echo "=========================================="
