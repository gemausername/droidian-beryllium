#!/bin/bash
# Device Installation Script
# This script helps install Droidian on Poco F1 from a computer

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
DOWNLOAD_DIR="${HOME}/droidian-downloads"
TWRP_URL="https://dl.twrp.me/beryllium/twrp-latest-beryllium.img"
VENDOR_URL="https://github.com/ubports-beryllium/artifacts/releases/download/v3/vendor.img"
FIRMWARE_URL="https://xiaomifirmwareupdater.com/download/?file=fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip"

# Check if running as non-root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Check for required tools
print_step "1. Checking required tools..."
for cmd in adb fastboot; do
    if ! command -v $cmd &> /dev/null; then
        print_error "$cmd is not installed. Please install Android SDK platform-tools."
        exit 1
    fi
done
print_msg "All required tools found!"

# Create download directory
mkdir -p "${DOWNLOAD_DIR}"

print_step "2. Downloading required files..."
echo ""
echo "Please download the following files manually:"
echo ""
echo "1. Droidian rootfs and devtools:"
echo "   https://github.com/droidian-images/rootfs-api28gsi-all/releases"
echo ""
echo "2. Boot image for Poco F1:"
echo "   https://github.com/Unofficial-droidian-for-pocof1/linux_android_xiaomi_beryllium/releases"
echo ""
echo "3. TWRP recovery:"
echo "   ${TWRP_URL}"
echo ""
echo "4. Vendor image:"
echo "   ${VENDOR_URL}"
echo ""
echo "5. Android 9 firmware:"
echo "   ${FIRMWARE_URL}"
echo ""

read -p "Press Enter after you have downloaded all files to ${DOWNLOAD_DIR}..."

print_step "3. Checking device connection..."
print_msg "Please boot your phone into fastboot mode:"
print_msg "  1. Power off the phone"
print_msg "  2. Press and hold Vol- and Power buttons"
print_msg "  3. Hold until phone vibrates"
echo ""

read -p "Press Enter when phone is in fastboot mode..."

if ! fastboot devices | grep -q "fastboot"; then
    print_error "No device detected in fastboot mode!"
    print_msg "Try these steps:"
    print_msg "  1. Check USB connection (use USB 2.0 port)"
    print_msg "  2. Install appropriate USB drivers"
    print_msg "  3. Run: sudo apt install android-tools-adb android-tools-fastboot"
    exit 1
fi

print_msg "Device detected!"

print_step "4. Installing TWRP..."
TWRP_FILE=$(ls "${DOWNLOAD_DIR}"/twrp-*-beryllium.img 2>/dev/null | head -1)
if [ -z "$TWRP_FILE" ]; then
    print_error "TWRP image not found in ${DOWNLOAD_DIR}"
    print_msg "Please download from: ${TWRP_URL}"
    exit 1
fi

print_msg "Flashing TWRP..."
fastboot flash recovery "${TWRP_FILE}"

print_step "5. Booting into TWRP..."
print_msg "Please boot into TWRP now:"
print_msg "  1. Press Vol+ and Power buttons"
print_msg "  2. Hold until TWRP logo appears"
echo ""

read -p "Press Enter when in TWRP..."

print_step "6. Formatting data..."
print_msg "In TWRP:"
print_msg "  1. Go to Wipe"
print_msg "  2. Tap 'Format Data'"
print_msg "  3. Type 'yes' and confirm"
echo ""

read -p "Press Enter after formatting..."

print_msg "IMPORTANT: Reboot into TWRP again!"
print_msg "  In TWRP main menu, tap Reboot > Recovery"
echo ""

read -p "Press Enter when back in TWRP..."

print_step "7. Copying files to device..."
print_msg "Connecting to device via MTP..."
print_msg "Copy all downloaded files to the phone's internal storage."
echo ""

read -p "Press Enter after copying files..."

print_step "8. Flashing firmware..."
FIRMWARE_FILE=$(ls "${DOWNLOAD_DIR}"/fw_beryllium*.zip 2>/dev/null | head -1)
if [ -n "$FIRMWARE_FILE" ]; then
    print_msg "Flashing firmware..."
    # Note: This needs to be done via TWRP on the phone
    print_msg "In TWRP, tap Install > select ${FIRMWARE_FILE}"
    read -p "Press Enter after flashing firmware..."
else
    print_warn "Firmware file not found, skipping..."
fi

print_step "9. Flashing boot and vendor images..."
BOOT_FILE=$(ls "${DOWNLOAD_DIR}"/droidian-boot-*.img 2>/dev/null | head -1)
VENDOR_FILE=$(ls "${DOWNLOAD_DIR}"/vendor.img 2>/dev/null | head -1)

if [ -n "$BOOT_FILE" ]; then
    print_msg "Flash boot.img to Boot partition via TWRP"
    read -p "Press Enter after flashing boot..."
fi

if [ -n "$VENDOR_FILE" ]; then
    print_msg "Flash vendor.img to Vendor partition via TWRP"
    read -p "Press Enter after flashing vendor..."
fi

print_step "10. Flashing Droidian rootfs..."
ROOTFS_FILE=$(ls "${DOWNLOAD_DIR}"/droidian-rootfs*.zip 2>/dev/null | head -1)
DEVTOOLS_FILE=$(ls "${DOWNLOAD_DIR}"/droidian-devtools*.zip 2>/dev/null | head -1)

if [ -n "$ROOTFS_FILE" ]; then
    print_msg "Flash rootfs via TWRP"
    read -p "Press Enter after flashing rootfs..."
fi

if [ -n "$DEVTOOLS_FILE" ]; then
    print_msg "Flash devtools via TWRP"
    read -p "Press Enter after flashing devtools..."
fi

print_step "11. Rebooting device..."
print_msg "In TWRP, tap Reboot > System"
print_msg ""
print_msg "First boot may take a few minutes."
print_msg "Default unlock code: 1234"
echo ""

print_msg "=========================================="
print_msg "Installation Complete!"
print_msg "=========================================="
print_msg ""
print_msg "If the device doesn't boot, try these fixes:"
print_msg ""
print_msg "1. Bluetooth: sudo touch /var/lib/bluetooth/board-address"
print_msg ""
print_msg "2. Notch fix: Edit ~/.config/gtk-3.0/gtk.css"
print_msg ""
print_msg "3. SSH access: Connect via WiFi or USB networking"
print_msg ""
print_msg "For more help, visit:"
print_msg "  - https://t.me/pocof1droidian"
print_msg "  - https://t.me/droidianlinux"
