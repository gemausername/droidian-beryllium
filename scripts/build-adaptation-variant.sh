#!/bin/bash
# Build Adaptation Package for Specific Variant
# Usage: ./build-adaptation-variant.sh <variant>

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

print_step "Building adaptation package for: $VARIANT"
print_msg "Desktop: $DESKTOP"
print_msg "Panel: $PANEL_TYPE"

# Create variant-specific adaptation package
ADAPTATION_DIR="${PROJECT_DIR}/packages/adaptation-droidian-beryllium-${VARIANT}"
mkdir -p "${ADAPTATION_DIR}/debian/source"
mkdir -p "${ADAPTATION_DIR}/sparse/usr/lib/adaptation-droidian-beryllium-${VARIANT}"
mkdir -p "${ADAPTATION_DIR}/sparse/usr/lib/droidian/device"
mkdir -p "${ADAPTATION_DIR}/sparse/usr/lib/droidian/device/phosh-notch"
mkdir -p "${ADAPTATION_DIR}/sparse/etc/phosh"
mkdir -p "${ADAPTATION_DIR}/sparse/etc/lomiri"
mkdir -p "${ADAPTATION_DIR}/sparse/etc/systemd/system"
mkdir -p "${ADAPTATION_DIR}/sparse/etc/udev/rules.d"
mkdir -p "${ADAPTATION_DIR}/sparse/usr/share/keyrings"
mkdir -p "${ADAPTATION_DIR}/sparse/usr/bin/droid"

# Copy variant config
cp "${VARIANT_DIR}/variant.conf" "${ADAPTATION_DIR}/debian/variant.conf"

# Create debian/control
cat > "${ADAPTATION_DIR}/debian/control" << EOF
Source: adaptation-droidian-beryllium-${VARIANT}
Section: system
Priority: optional
Maintainer: Droidian Community <community@droidian.org>
Build-Depends: debhelper (>= 13), dpkg-dev

Package: adaptation-droidian-beryllium-${VARIANT}
Architecture: arm64
Depends: \${shlibs:Depends}, \${misc:Depends}, linux-image-*, lxc-android, droidian-udev-rules
Description: Droidian adaptation for Xiaomi Poco F1 (${VARIANT})
 This package contains device-specific configurations for the
 Xiaomi Poco F1 (beryllium) with ${PANEL_TYPE} panel and ${DESKTOP} desktop.
 .
 Desktop: ${DESKTOP}
 Panel: ${PANEL_TYPE}
 Variant: ${VARIANT}
EOF

# Create debian/rules
cat > "${ADAPTATION_DIR}/debian/rules" << 'EOF'
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_install:
	# Create necessary directories
	install -d $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/adaptation-droidian-beryllium-$(VARIANT)
	install -d $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/droidian/device
	install -d $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/bin/droid

	# Install device info
	install -m 644 debian/device-info $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/adaptation-droidian-beryllium-$(VARIANT)/device-info

	# Install variant config
	install -m 644 debian/variant.conf $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/adaptation-droidian-beryllium-$(VARIANT)/variant.conf

	# Install panel config
	install -m 644 debian/panel.conf $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/adaptation-droidian-beryllium-$(VARIANT)/panel.conf

	# Install desktop config
	install -m 644 debian/desktop.conf $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/adaptation-droidian-beryllium-$(VARIANT)/desktop.conf

	# Install bluetooth script
	install -m 755 debian/droid-get-bt-address.sh $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/bin/droid/droid-get-bt-address.sh

	# Install udev rules
	install -m 644 debian/70-beryllium.rules $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/etc/udev/rules.d/70-beryllium.rules

	# Install schedtune workaround
	install -d $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/etc/systemd/system/android-mount.service.d
	install -m 644 debian/10-schedtune.conf $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/etc/systemd/system/android-mount.service.d/10-schedtune.conf

	# Install brightness service
	install -m 644 debian/adaptation-droidian-beryllium.brightness.service $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/etc/systemd/system/adaptation-droidian-beryllium.brightness.service

	# Create device-specific marker files
	touch $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/droidian/device/encryption-supported
	touch $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/droidian/device/flashlightd-sysfs
	echo "/sys/class/leds/lcd-backlight/brightness" > $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/droidian/device/flashlightd-sysfs-nodes

	# Install sources.list
	install -m 644 debian/community-beryllium.list $(CURDIR)/debian/adaptation-droidian-beryllium-$(VARIANT)/usr/lib/adaptation-droidian-beryllium-$(VARIANT)/community-beryllium.list

override_dh_auto_build:
	# Nothing to build

override_dh_auto_test:
	# No tests

override_dh_dwz:
override_dh_strip:
override_dh_makeshlibs:
EOF

# Create device-info
cat > "${ADAPTATION_DIR}/debian/device-info" << EOF
DEVICE_NAME=beryllium
DEVICE_MODEL=Poco F1
DEVICE_MANUFACTURER=Xiaomi
DEVICE_VENDOR=Xiaomi
DEVICE_SOC=SDM845
DEVICE_ARCH=arm64
DEVICE_API=28
DEVICE_GSI=true
VARIANT=${VARIANT}
DESKTOP=${DESKTOP}
PANEL=${PANEL}
PANEL_TYPE=${PANEL_TYPE}
EOF

# Create panel.conf
cat > "${ADAPTATION_DIR}/debian/panel.conf" << EOF
# Panel Configuration: ${PANEL_TYPE}
PANEL_COMPATIBLE=${PANEL_COMPATIBLE}
PANEL_ORIENTATION=${PANEL_ORIENTATION}
PANEL_REFRESH_RATE=${PANEL_REFRESH_RATE}
TOUCH_COMPATIBLE=${TOUCH_COMPATIBLE}
TOUCH_MAX_X=${TOUCH_MAX_X}
TOUCH_MAX_Y=${TOUCH_MAX_Y}
EOF

# Add touch-specific settings for TianmaFT
if [ "$PANEL" = "tianmaft" ]; then
    cat >> "${ADAPTATION_DIR}/debian/panel.conf" << EOF
TOUCH_IRQ=${TOUCH_IRQ}
TOUCH_RESET=${TOUCH_RESET}
EOF
fi

# Create desktop.conf
cat > "${ADAPTATION_DIR}/debian/desktop.conf" << EOF
# Desktop Configuration: ${DESKTOP}
DESKTOP=${DESKTOP}
EOF

if [ "$DESKTOP" = "phosh" ]; then
    cat >> "${ADAPTATION_DIR}/debian/desktop.conf" << EOF
PHOSH_SCALE=${PHOSH_SCALE}
PHOSH_NOTCH_FIX=${PHOSH_NOTCH_FIX}
EOF
elif [ "$DESKTOP" = "lomiri" ]; then
    cat >> "${ADAPTATION_DIR}/debian/desktop.conf" << EOF
LOMIRI_SCALE=${LOMIRI_SCALE}
LOMIRI_NOTCH_FIX=${LOMIRI_NOTCH_FIX}
EOF
fi

# Create droid-get-bt-address.sh
cat > "${ADAPTATION_DIR}/debian/droid-get-bt-address.sh" << 'BTEOF'
#!/bin/bash
# Bluetooth MAC address retrieval script for Xiaomi Poco F1

set -e

BT_ADDR_FILE="/var/lib/bluetooth/board-address"

get_bt_address() {
    if command -v getprop &> /dev/null; then
        local addr=$(getprop persist.bluetooth.bdroid_addr)
        if [ -n "$addr" ]; then
            echo "$addr"
            return 0
        fi
    fi

    if [ -f "$BT_ADDR_FILE" ] && [ -s "$BT_ADDR_FILE" ]; then
        cat "$BT_ADDR_FILE"
        return 0
    fi

    if [ -f /sys/devices/soc0/serial_number ]; then
        local serial=$(cat /sys/devices/soc0/serial_number)
        echo "00:${serial:0:2}:${serial:2:2}:${serial:4:2}:${serial:6:2}:${serial:8:2}"
        return 0
    fi

    return 1
}

BT_ADDR=$(get_bt_address)

if [ -n "$BT_ADDR" ]; then
    mkdir -p /var/lib/bluetooth
    echo "$BT_ADDR" > "$BT_ADDR_FILE"
    chmod 644 "$BT_ADDR_FILE"
    echo "Bluetooth address set to: $BT_ADDR"
else
    echo "Could not determine Bluetooth address"
    mkdir -p /var/lib/bluetooth
    touch "$BT_ADDR_FILE"
fi
BTEOF
chmod +x "${ADAPTATION_DIR}/debian/droid-get-bt-address.sh"

# Create udev rules
cat > "${ADAPTATION_DIR}/debian/70-beryllium.rules" << 'UDEV'
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

# Hide unused HID interface
ACTION=="add|change", KERNEL=="event[0-9]*", SUBSYSTEM=="input", ATTRS{name}=="gpio-keys", ENV{LIBINPUT_IGNORE_DEVICE}="1"

# Camera flash LED
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="flash", OWNER="root", GROUP="system", MODE="0666"

# Notification LED
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="red", OWNER="root", GROUP="system", MODE="0666"
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="green", OWNER="root", GROUP="system", MODE="0666"
ACTION=="add|change", KERNEL=="leds", SUBSYSTEM=="leds", ATTRS{name}=="blue", OWNER="root", GROUP="system", MODE="0666"
UDEV

# Create schedtune workaround
cat > "${ADAPTATION_DIR}/debian/10-schedtune.conf" << 'EOF'
[Service]
ExecStartPre=-/usr/bin/umount -l /sys/fs/cgroup/schedtune
EOF

# Create brightness service
cat > "${ADAPTATION_DIR}/debian/adaptation-droidian-beryllium.brightness.service" << 'EOF'
[Unit]
Description=Set LCD brightness on boot for Poco F1
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 128 > /sys/class/leds/lcd-backlight/brightness'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create sources.list
cat > "${ADAPTATION_DIR}/debian/community-beryllium.list" << EOF
deb [signed-by=/usr/share/keyrings/beryllium-${VARIANT}.gpg] https://YOURREPO.TLD bookworm main
EOF

# Create compat and source/format
echo "13" > "${ADAPTATION_DIR}/debian/compat"
echo "3.0 (native)" > "${ADAPTATION_DIR}/debian/source/format"

# Build the package
print_step "Building .deb package..."
cd "${ADAPTATION_DIR}"
dpkg-buildpackage -b -uc -us

# Copy to output
mkdir -p "${PROJECT_DIR}/output"
mv "${PROJECT_DIR}/../adaptation-droidian-beryllium-${VARIANT}_1.0_arm64.deb" "${PROJECT_DIR}/output/" 2>/dev/null || true

print_msg "Adaptation package for $VARIANT built successfully!"
