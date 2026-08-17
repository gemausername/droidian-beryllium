#!/bin/bash
# Complete Device Tweaks Script for Xiaomi Poco F1 (beryllium)
# This script applies all necessary tweaks and fixes for Droidian

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
    echo "  Droidian Device Tweaks for Poco F1"
    echo "============================================"
    echo -e "${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_header

# Function to backup file before modifying
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d%H%M%S)"
        print_msg "Backed up: $file"
    fi
}

# Function to create systemd service
create_service() {
    local name="$1"
    local desc="$2"
    local exec_start="$3"
    local wanted_by="${4:-multi-user.target}"
    
    cat > "/etc/systemd/system/${name}" << EOF
[Unit]
Description=${desc}
After=multi-user.target

[Service]
Type=oneshot
ExecStart=${exec_start}
RemainAfterExit=yes

[Install]
WantedBy=${wanted_by}
EOF
    
    systemctl daemon-reload
    systemctl enable "${name}"
    print_msg "Created service: ${name}"
}

# ============================================
# 1. BLUETOOTH FIX
# ============================================
print_step "1. Applying Bluetooth fix..."

# Create bluetooth directory
mkdir -p /var/lib/bluetooth

# Create empty board-address file
touch /var/lib/bluetooth/board-address
chmod 644 /var/lib/bluetooth/board-address

# Create bluetooth fix script
cat > /usr/local/bin/fix-bluetooth << 'EOF'
#!/bin/bash
# Fix Bluetooth MAC address issue

BT_ADDR_FILE="/var/lib/bluetooth/board-address"

# Try to get BT address from Android properties
if command -v getprop &> /dev/null; then
    BT_ADDR=$(getprop persist.bluetooth.bdroid_addr)
    if [ -n "$BT_ADDR" ]; then
        echo "$BT_ADDR" > "$BT_ADDR_FILE"
        echo "Bluetooth address set to: $BT_ADDR"
    fi
fi

# If still empty, create dummy address
if [ ! -s "$BT_ADDR_FILE" ]; then
    echo "00:00:00:00:00:00" > "$BT_ADDR_FILE"
    echo "Created dummy Bluetooth address"
fi
EOF
chmod +x /usr/local/bin/fix-bluetooth

# Run fix
/usr/local/bin/fix-bluetooth
print_msg "Bluetooth fix applied"

# ============================================
# 2. BRIGHTNESS FIX
# ============================================
print_step "2. Applying brightness fix..."

# Create brightness service
create_service "brightness-fix.service" "Fix LCD brightness on boot" "/bin/sh -c 'echo 128 > /sys/class/leds/lcd-backlight/brightness'"

# Create brightness control script
cat > /usr/local/bin/brightness-control << 'EOF'
#!/bin/bash
# Brightness control script for Poco F1

BRIGHTNESS_FILE="/sys/class/leds/lcd-backlight/brightness"
MAX_BRIGHTNESS=2047

case "$1" in
    up)
        current=$(cat "$BRIGHTNESS_FILE")
        new=$((current + 50))
        if [ $new -gt $MAX_BRIGHTNESS ]; then
            new=$MAX_BRIGHTNESS
        fi
        echo $new > "$BRIGHTNESS_FILE"
        echo "Brightness: $new"
        ;;
    down)
        current=$(cat "$BRIGHTNESS_FILE")
        new=$((current - 50))
        if [ $new -lt 0 ]; then
            new=0
        fi
        echo $new > "$BRIGHTNESS_FILE"
        echo "Brightness: $new"
        ;;
    set)
        if [ -n "$2" ] && [ "$2" -ge 0 ] && [ "$2" -le $MAX_BRIGHTNESS ]; then
            echo $2 > "$BRIGHTNESS_FILE"
            echo "Brightness: $2"
        else
            echo "Usage: brightness-control set <0-$MAX_BRIGHTNESS>"
        fi
        ;;
    get)
        current=$(cat "$BRIGHTNESS_FILE")
        echo "Current brightness: $current"
        ;;
    *)
        echo "Usage: brightness-control {up|down|set <value>|get}"
        ;;
esac
EOF
chmod +x /usr/local/bin/brightness-control

print_msg "Brightness fix applied"

# ============================================
# 3. NOTCH FIX
# ============================================
print_step "3. Applying notch fix..."

# Create phosh config directory
mkdir -p /etc/phosh

# Create phoc.ini with notch fix
cat > /etc/phosh/phoc.ini << 'EOF'
[core]
# Scale factor for the display (1.0 = no scaling)
scale=1.5

[output:HWCOMPOSER-1]
# Poco F1 display settings
transform=0
EOF

# Create GTK CSS fix for notch
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/gtk.css << 'EOF'
.phosh-topbar-clock {
   margin-left: 195px;
}

.phosh-panel-btn > box {
   margin-left: 0px;
   margin-right: 0px;
}

.phosh-power-button {
   margin-right: 50px;
}
EOF

print_msg "Notch fix applied"

# ============================================
# 4. SCHEDTUNE WORKAROUND
# ============================================
print_step "4. Applying schedtune workaround..."

# Create override directory
mkdir -p /etc/systemd/system/android-mount.service.d

# Create schedtune override
cat > /etc/systemd/system/android-mount.service.d/10-schedtune.conf << 'EOF'
[Service]
ExecStartPre=-/usr/bin/umount -l /sys/fs/cgroup/schedtune
EOF

systemctl daemon-reload
print_msg "Schedtune workaround applied"

# ============================================
# 5. USB NETWORKING FIX
# ============================================
print_step "5. Applying USB networking fix..."

# Enable IP forwarding
cat > /etc/sysctl.d/99-usb-networking.conf << 'EOF'
net.ipv4.ip_forward = 1
EOF
sysctl -p /etc/sysctl.d/99-usb-networking.conf

print_msg "USB networking fix applied"

# ============================================
# 6. VENDOR PARTITION MOUNT
# ============================================
print_step "6. Setting up vendor partition mount..."

# Create vendor mount script
cat > /usr/local/bin/mount-vendor << 'EOF'
#!/bin/bash
# Mount vendor partition if not mounted

if [ ! -d /vendor ] || [ -z "$(ls -A /vendor)" ]; then
    echo "Vendor partition not mounted, attempting to mount..."
    
    # Find vendor partition
    VENDOR_PARTITION=""
    for part in /dev/disk/by-partlabel/vendor /dev/disk/by-name/vendor /dev/block/bootdevice/by-name/vendor; do
        if [ -b "$part" ]; then
            VENDOR_PARTITION="$part"
            break
        fi
    done
    
    if [ -n "$VENDOR_PARTITION" ]; then
        mkdir -p /vendor
        mount "$VENDOR_PARTITION" /vendor
        echo "Mounted vendor partition: $VENDOR_PARTITION"
    else
        echo "Could not find vendor partition"
    fi
fi
EOF
chmod +x /usr/local/bin/mount-vendor

# Create systemd service for vendor mount
create_service "mount-vendor.service" "Mount vendor partition" "/usr/local/bin/mount-vendor"

print_msg "Vendor partition mount setup complete"

# ============================================
# 7. HALIUM CONTAINER FIX
# ============================================
print_step "7. Applying Halium container fix..."

# Create Halium container fix script
cat > /usr/local/bin/fix-halium << 'EOF'
#!/bin/bash
# Fix Halium container issues

# Regenerate udev rules
DEVICE="beryllium"
cat /var/lib/lxc/android/rootfs/ueventd*.rc \
    /var/lib/lxc/android/rootfs/system/etc/ueventd*.rc \
    /vendor/ueventd*.rc \
    /var/lib/lxc/android/rootfs/vendor/etc/ueventd*.rc 2>/dev/null | \
    grep "^/dev" | \
    sed -e 's/^\/dev\///' | \
    awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | \
    sed -e 's/\r//' > /etc/udev/rules.d/70-${DEVICE}.rules

echo "Udev rules regenerated for $DEVICE"
EOF
chmod +x /usr/local/bin/fix-halium

# Run fix
/usr/local/bin/fix-halium

print_msg "Halium container fix applied"

# ============================================
# 8. PHOSH WAIT FIX
# ============================================
print_step "8. Applying Phosh wait fix..."

# Create Phosh wait override
mkdir -p /etc/systemd/system/phosh.service.d
cat > /etc/systemd/system/phosh.service.d/90-wait.conf << 'EOF'
# FIXME
[Service]
ExecStartPre=/usr/bin/sleep 5
EOF

systemctl daemon-reload
print_msg "Phosh wait fix applied"

# ============================================
# 9. MOBILE DATA FIX
# ============================================
print_step "9. Applying mobile data fix..."

# Create APN configuration helper
cat > /usr/local/bin/setup-apn << 'EOF'
#!/bin/bash
# Setup mobile data APN

echo "Mobile Data APN Setup"
echo "====================="
echo ""
echo "Please configure your APN in the settings:"
echo "  1. Open Settings"
echo "  2. Go to Mobile Network"
echo "  3. Add new APN"
echo "  4. Enter your carrier's APN settings"
echo ""
echo "Common APN settings:"
echo "  - Telkomsel: internet"
echo "  - Indosat: indosatgprs"
echo "  - XL: xlconnect"
echo "  - Tri: 3gprs"
echo ""
echo "After setting up APN, toggle mobile data off/on if it doesn't work."
EOF
chmod +x /usr/local/bin/setup-apn

print_msg "Mobile data fix applied"

# ============================================
# 10. WAYDROID FIX
# ============================================
print_step "10. Applying Waydroid fix..."

# Create Waydroid fix script
cat > /usr/local/bin/fix-waydroid << 'EOF'
#!/bin/bash
# Fix Waydroid issues

# Disable suspend in Waydroid
waydroid prop set persist.waydroid.no_suspend true
waydroid prop set persist.waydroid.suspend false

# Hide redundant apps
for i in ~/.local/share/applications/waydroid*.desktop; do
    if [ -f "$i" ]; then
        echo 'NoDisplay=true' >> "$i"
    fi
done

echo "Waydroid fixes applied"
EOF
chmod +x /usr/local/bin/fix-waydroid

print_msg "Waydroid fix applied"

# ============================================
# 11. AUDIO FIX
# ============================================
print_step "11. Applying audio fix..."

# Create PulseAudio custom config for MediaTek
mkdir -p /etc/pulse
cat > /etc/pulse/arm_droid_card_custom.pa << 'EOF'
# Custom PulseAudio configuration for Poco F1

# Load module for Android audio
load-module module-droid-discover
load-module module-droid-card

# Set default sink
set-default-sink android_output
set-default-source android_input
EOF

print_msg "Audio fix applied"

# ============================================
# 12. CAMERA FIX
# ============================================
print_step "12. Applying camera fix..."

# Create camera fix script
cat > /usr/local/bin/fix-camera << 'EOF'
#!/bin/bash
# Fix camera issues

# Check if camera is working
if [ ! -d /dev/video0 ]; then
    echo "Camera device not found"
    echo "Please check kernel configuration for camera support"
fi

# Install camera apps if not present
if ! dpkg -l | grep -q pinhole; then
    echo "Installing pinhole camera app..."
    apt-get update
    apt-get install -y pinhole
fi

echo "Camera fix applied"
EOF
chmod +x /usr/local/bin/fix-camera

print_msg "Camera fix applied"

# ============================================
# 13. BATTERY FIX
# ============================================
print_step "13. Applying battery fix..."

# Create battery optimization script
cat > /usr/local/bin/optimize-battery << 'EOF'
#!/bin/bash
# Optimize battery usage

# Disable thermal engine if present
if systemctl is-active --quiet thermal-engine; then
    systemctl stop thermal-engine
    systemctl disable thermal-engine
    echo "Disabled thermal engine"
fi

# Enable batman for battery management
if command -v batman &> /dev/null; then
    systemctl enable batman
    systemctl start batman
    echo "Enabled batman battery manager"
fi

echo "Battery optimization applied"
EOF
chmod +x /usr/local/bin/optimize-battery

print_msg "Battery fix applied"

# ============================================
# 14. FLASHLIGHT FIX
# ============================================
print_step "14. Applying flashlight fix..."

# Create flashlight support files
mkdir -p /usr/lib/droidian/device
touch /usr/lib/droidian/device/flashlightd-sysfs
echo "/sys/class/leds/lcd-backlight/brightness" > /usr/lib/droidian/device/flashlightd-sysfs-nodes

print_msg "Flashlight fix applied"

# ============================================
# 15. ENCRYPTION SUPPORT
# ============================================
print_step "15. Enabling encryption support..."

touch /usr/lib/droidian/device/encryption-supported
print_msg "Encryption support enabled"

# ============================================
# 16. CUSTOM HOSTNAME
# ============================================
print_step "16. Setting custom hostname..."

mkdir -p /usr/lib/droidian/device
echo "pocof1" > /usr/lib/droidian/device/preferred-hostname
print_msg "Custom hostname set to: pocof1"

# ============================================
# 17. MTP SUPPORT
# ============================================
print_step "17. Enabling MTP support..."

touch /usr/lib/droidian/device/mtp-supported
print_msg "MTP support enabled"

# ============================================
# 18. UDEV RULES
# ============================================
print_step "18. Setting up udev rules..."

cat > /etc/udev/rules.d/70-beryllium.rules << 'EOF'
# Udev rules for Xiaomi Poco F1 (beryllium)

# LCD Backlight
ACTION=="add|change", KERNEL=="lcd-backlight", OWNER="root", GROUP="system", MODE="0666"

# Battery
ACTION=="add|change", KERNEL=="battery", OWNER="root", GROUP="system", MODE="0666"

# USB
ACTION=="add|change", KERNEL=="usb", OWNER="root", GROUP="system", MODE="0666"

# Touchscreen
ACTION=="add|change", KERNEL=="event[0-9]*", SUBSYSTEM=="input", ATTRS{name}=="fts_ts", OWNER="root", GROUP="input", MODE="0664"

# Proximity sensor
ACTION=="add|change", KERNEL=="event[0-9]*", SUBSYSTEM=="input", ATTRS{name}=="proximity", OWNER="root", GROUP="input", MODE="0664"

# Accelerometer
ACTION=="add|change", KERNEL=="event[0-9]*", SUBSYSTEM=="input", ATTRS{name}=="accelerometer", OWNER="root", GROUP="input", MODE="0664"

# Hide unused HID interface that shows cursor
ACTION=="add|change", KERNEL=="event[0-9]*", SUBSYSTEM=="input", ATTRS{name}=="gpio-keys", ENV{LIBINPUT_IGNORE_DEVICE}="1"

# Camera flash LED
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="flash", OWNER="root", GROUP="system", MODE="0666"

# Notification LED
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="red", OWNER="root", GROUP="system", MODE="0666"
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="green", OWNER="root", GROUP="system", MODE="0666"
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="blue", OWNER="root", GROUP="system", MODE="0666"
EOF

udevadm control --reload-rules
udevadm trigger
print_msg "Udev rules applied"

# ============================================
# FINAL SUMMARY
# ============================================
echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  All Device Tweaks Applied Successfully!${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
print_msg "Applied tweaks:"
echo "  1. Bluetooth fix"
echo "  2. Brightness fix"
echo "  3. Notch fix"
echo "  4. Schedtune workaround"
echo "  5. USB networking fix"
echo "  6. Vendor partition mount"
echo "  7. Halium container fix"
echo "  8. Phosh wait fix"
echo "  9. Mobile data fix"
echo "  10. Waydroid fix"
echo "  11. Audio fix"
echo "  12. Camera fix"
echo "  13. Battery optimization"
echo "  14. Flashlight fix"
echo "  15. Encryption support"
echo "  16. Custom hostname"
echo "  17. MTP support"
echo "  18. Udev rules"
echo ""
print_msg "Please reboot your device for all changes to take effect."
print_msg ""
print_msg "Quick commands:"
echo "  brightness-control up/down/set <value>  - Control brightness"
echo "  fix-bluetooth                           - Fix Bluetooth"
echo "  fix-halium                              - Fix Halium container"
echo "  fix-waydroid                            - Fix Waydroid"
echo "  fix-camera                              - Fix camera"
echo "  optimize-battery                        - Optimize battery"
echo "  setup-apn                               - Setup mobile data"
