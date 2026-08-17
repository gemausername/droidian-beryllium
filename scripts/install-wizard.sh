#!/bin/bash
# Complete Installation Wizard for Droidian on Poco F1
# This script guides you through the entire installation process

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
    echo "║           Droidian Installation Wizard for Poco F1           ║"
    echo "║                        (beryllium)                           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_header

# ============================================
# STEP 1: Check Prerequisites
# ============================================
print_section "STEP 1: Checking Prerequisites"

print_step "Checking system requirements..."

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script must be run on Linux"
    print_msg "Please use Ubuntu/Debian-based system"
    exit 1
fi

# Check for required tools
MISSING_TOOLS=()

for cmd in adb fastboot docker git curl wget; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_TOOLS+=("$cmd")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_warn "Missing tools: ${MISSING_TOOLS[*]}"
    echo ""
    read -p "Do you want to install missing tools? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Installing missing tools..."
        sudo apt-get update
        sudo apt-get install -y android-tools-adb android-tools-fastboot docker.io git curl wget
    else
        print_error "Please install missing tools manually"
        exit 1
    fi
fi

print_msg "All prerequisites satisfied!"

# ============================================
# STEP 2: Download Required Files
# ============================================
print_section "STEP 2: Downloading Required Files"

DOWNLOAD_DIR="${HOME}/droidian-downloads"
mkdir -p "$DOWNLOAD_DIR"

print_msg "Files will be downloaded to: $DOWNLOAD_DIR"
echo ""

# Download URLs
TWRP_URL="https://dl.twrp.me/beryllium/twrp-latest-beryllium.img"
VENDOR_URL="https://github.com/ubports-beryllium/artifacts/releases/download/v3/vendor.img"
FIRMWARE_URL="https://xiaomifirmwareupdater.com/download/?file=fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip"

# Download Droidian images
print_step "Downloading Droidian images..."
echo ""
echo "Please download the following files manually from the browser:"
echo ""
echo "1. Droidian rootfs (arm64):"
echo "   https://github.com/droidian-images/rootfs-api28gsi-all/releases"
echo ""
echo "2. Droidian devtools (arm64):"
echo "   https://github.com/droidian-images/rootfs-api28gsi-all/releases"
echo ""
echo "3. Boot image for Poco F1:"
echo "   https://github.com/Unofficial-droidian-for-pocof1/linux_android_xiaomi_beryllium/releases"
echo ""

read -p "Press Enter after downloading Droidian files to $DOWNLOAD_DIR..."

# Download TWRP
print_step "Downloading TWRP..."
if [ ! -f "$DOWNLOAD_DIR/twrp-latest-beryllium.img" ]; then
    wget -O "$DOWNLOAD_DIR/twrp-latest-beryllium.img" "$TWRP_URL" || print_warn "Failed to download TWRP"
else
    print_msg "TWRP already downloaded"
fi

# Download Vendor image
print_step "Downloading Vendor image..."
if [ ! -f "$DOWNLOAD_DIR/vendor.img" ]; then
    wget -O "$DOWNLOAD_DIR/vendor.img" "$VENDOR_URL" || print_warn "Failed to download vendor image"
else
    print_msg "Vendor image already downloaded"
fi

# Download Firmware
print_step "Downloading Firmware..."
if [ ! -f "$DOWNLOAD_DIR/fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip" ]; then
    wget -O "$DOWNLOAD_DIR/fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip" "$FIRMWARE_URL" || print_warn "Failed to download firmware"
else
    print_msg "Firmware already downloaded"
fi

print_msg "All files downloaded!"

# ============================================
# STEP 3: Unlock Bootloader (Instructions)
# ============================================
print_section "STEP 3: Unlock Bootloader"

echo ""
echo "Please follow these steps to unlock your bootloader:"
echo ""
echo "1. Enable Developer Options:"
echo "   - Go to Settings > About Phone"
echo "   - Tap MIUI version 7 times"
echo ""
echo "2. Enable OEM Unlocking:"
echo "   - Go to Settings > Additional Settings > Developer Options"
echo "   - Enable 'OEM Unlocking'"
echo ""
echo "3. Unlock Bootloader:"
echo "   - Visit https://en.miui.com/unlock/download_en.html"
echo "   - Download and install Mi Unlock Tool on Windows PC"
echo "   - Login with your Mi Account"
echo "   - Connect your phone in Fastboot mode"
echo "   - Click 'Unlock'"
echo ""
echo "Note: You may need to wait 72 hours after applying for unlock."
echo ""

read -p "Press Enter when bootloader is unlocked..."

# ============================================
# STEP 4: Install TWRP
# ============================================
print_section "STEP 4: Installing TWRP Recovery"

print_step "Please boot your phone into Fastboot mode:"
echo ""
echo "1. Power off your phone completely"
echo "2. Press and hold Volume Down + Power buttons"
echo "3. Hold until you see Fastboot logo"
echo ""

read -p "Press Enter when phone is in Fastboot mode..."

# Check device connection
print_step "Checking device connection..."
if ! fastboot devices | grep -q "fastboot"; then
    print_error "No device detected in Fastboot mode!"
    echo ""
    echo "Please try:"
    echo "1. Check USB connection (use USB 2.0 port)"
    echo "2. Install USB drivers"
    echo "3. Try different USB cable"
    echo ""
    read -p "Press Enter when device is connected..."
fi

print_msg "Device detected!"

# Flash TWRP
print_step "Flashing TWRP recovery..."
TWRP_FILE=$(ls "$DOWNLOAD_DIR"/twrp-*-beryllium.img 2>/dev/null | head -1)

if [ -n "$TWRP_FILE" ]; then
    fastboot flash recovery "$TWRP_FILE"
    print_msg "TWRP flashed successfully!"
else
    print_error "TWRP image not found"
    exit 1
fi

# ============================================
# STEP 5: Install Droidian
# ============================================
print_section "STEP 5: Installing Droidian"

print_step "Please boot into TWRP recovery:"
echo ""
echo "1. Press and hold Volume Up + Power buttons"
echo "2. Hold until you see TWRP logo"
echo ""

read -p "Press Enter when in TWRP..."

# Format data
print_step "Formatting data partition..."
echo ""
echo "In TWRP, please:"
echo "1. Go to Wipe"
echo "2. Tap 'Format Data'"
echo "3. Type 'yes' and confirm"
echo ""

read -p "Press Enter after formatting data..."

# Reboot to TWRP
print_step "Rebooting to TWRP..."
echo ""
echo "IMPORTANT: You need to reboot into TWRP again!"
echo "1. In TWRP main menu, tap Reboot"
echo "2. Select 'Recovery'"
echo ""

read -p "Press Enter when back in TWRP..."

# Copy files to device
print_step "Copying files to device..."
echo ""
echo "The phone's internal storage should be accessible via MTP."
echo "Please copy the following files to the phone:"
echo ""
ls -1 "$DOWNLOAD_DIR"/*.zip "$DOWNLOAD_DIR"/*.img 2>/dev/null | while read file; do
    echo "  - $(basename "$file")"
done
echo ""

read -p "Press Enter after copying files..."

# Flash firmware
print_step "Flashing firmware..."
echo ""
echo "In TWRP, please:"
echo "1. Tap Install"
echo "2. Navigate to the firmware file"
echo "3. Swipe to confirm flash"
echo ""
echo "File: fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip"
echo ""

read -p "Press Enter after flashing firmware..."

# Flash boot image
print_step "Flashing boot image..."
echo ""
echo "In TWRP, please:"
echo "1. Tap Install"
echo "2. Tap 'Install Image'"
echo "3. Select boot.img"
echo "4. Select 'Boot' partition"
echo "5. Swipe to confirm flash"
echo ""

read -p "Press Enter after flashing boot image..."

# Flash vendor image
print_step "Flashing vendor image..."
echo ""
echo "In TWRP, please:"
echo "1. Tap Install"
echo "2. Tap 'Install Image'"
echo "3. Select vendor.img"
echo "4. Select 'Vendor' partition"
echo "5. Swipe to confirm flash"
echo ""

read -p "Press Enter after flashing vendor image..."

# Flash Droidian rootfs
print_step "Flashing Droidian rootfs..."
echo ""
echo "In TWRP, please:"
echo "1. Tap Install"
echo "2. Select droidian-rootfs-api28gsi_arm64_*.zip"
echo "3. Swipe to confirm flash"
echo ""

read -p "Press Enter after flashing rootfs..."

# Flash devtools
print_step "Flashing devtools..."
echo ""
echo "In TWRP, please:"
echo "1. Tap Install"
echo "2. Select droidian-devtools_arm64_*.zip"
echo "3. Swipe to confirm flash"
echo ""

read -p "Press Enter after flashing devtools..."

# ============================================
# STEP 6: First Boot
# ============================================
print_section "STEP 6: First Boot"

print_step "Rebooting to system..."
echo ""
echo "In TWRP, please:"
echo "1. Tap Reboot"
echo "2. Select 'System'"
echo ""
echo "Note: First boot may take a few minutes."
echo "Default unlock code: 1234"
echo ""

read -p "Press Enter when device has booted..."

# ============================================
# STEP 7: Apply Device Tweaks
# ============================================
print_section "STEP 7: Applying Device Tweaks"

print_step "Applying device-specific tweaks..."
echo ""
echo "Please connect to your device via SSH or terminal app."
echo ""
echo "Run the following command:"
echo ""
echo "  sudo bash /path/to/apply-all-tweaks.sh"
echo ""
echo "Or apply tweaks manually:"
echo ""
echo "1. Bluetooth fix:"
echo "   sudo touch /var/lib/bluetooth/board-address"
echo ""
echo "2. Brightness fix:"
echo "   echo 128 | sudo tee /sys/class/leds/lcd-backlight/brightness"
echo ""
echo "3. Notch fix:"
echo "   Edit ~/.config/gtk-3.0/gtk.css"
echo ""

read -p "Press Enter after applying tweaks..."

# ============================================
# STEP 8: Setup APT Repository
# ============================================
print_section "STEP 8: Setting Up APT Repository"

print_step "Setting up APT repository for updates..."
echo ""
echo "To receive OTA updates, you need to set up the APT repository."
echo ""
echo "Option 1: GitHub Pages (Recommended)"
echo "  Run: ./setup-github-repo.sh"
echo ""
echo "Option 2: Local Repository"
echo "  Run: sudo ./setup-repository.sh"
echo ""

read -p "Press Enter when repository is set up..."

# ============================================
# FINAL SUMMARY
# ============================================
print_section "INSTALLATION COMPLETE!"

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║              Installation Complete!                          ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

print_msg "Droidian has been successfully installed on your Poco F1!"
echo ""
echo "Quick reference:"
echo ""
echo "  Unlock code: 1234"
echo ""
echo "  SSH access: ssh droidian@<device-ip>"
echo ""
echo "  Useful commands:"
echo "    brightness-control up/down     - Adjust brightness"
echo "    fix-bluetooth                  - Fix Bluetooth"
echo "    fix-halium                     - Fix Halium container"
echo "    fix-waydroid                   - Fix Waydroid"
echo ""
echo "  Recovery tool:"
echo "    sudo ./recovery-tool.sh"
echo ""
echo "  OTA updates:"
echo "    sudo ./ota-update.sh"
echo ""
echo "For more information, see README.md"
echo ""
echo "Community:"
echo "  - Droidian Telegram: https://t.me/DroidianLinux"
echo "  - Poco F1 Group: https://t.me/pocof1droidian"
echo ""
print_msg "Enjoy your Droidian experience!"
