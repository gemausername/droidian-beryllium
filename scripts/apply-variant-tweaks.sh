#!/bin/bash
# Comprehensive Device Tweaks for Xiaomi Poco F1 (beryllium)
# Runs variant-specific tweaks based on detected panel and desktop

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Validate input
if [ -z "$1" ]; then
    print_error "Usage: $0 <variant>"
    print_error "Variants: phosh-ebbg, phosh-tianma, phosh-tianmaft, lomiri-ebbg, lomiri-tianma, lomiri-tianmaft"
    exit 1
fi

VARIANT="$1"
VARIANT_DIR="${PROJECT_DIR}/tweaks/${VARIANT}"

if [ ! -d "$VARIANT_DIR" ]; then
    print_error "Variant directory not found: $VARIANT_DIR"
    exit 1
fi

# Parse variant
DESKTOP="${VARIANT%%-*}"
PANEL="${VARIANT#*-}"

print_step "Applying tweaks for: $VARIANT (Desktop: $DESKTOP, Panel: $PANEL)"
echo ""

# ============================================
# SECTION 1: Common Tweaks (all variants)
# ============================================
print_step "Applying common device tweaks..."

# Notch workaround - suppress notch UI warnings
if [ -d /etc/phosh ]; then
    print_msg "Applying notch suppression for Phosh..."
    mkdir -p /etc/phosh/phoc/
    cp "${PROJECT_DIR}/packages/adaptation-droidian-beryllium/debian/notch-fix.json" \
       /etc/phosh/phoc/notch-fix.json 2>/dev/null || true
fi

# ModemManager optimizations
print_msg "Configuring ModemManager..."
mkdir -p /etc/ModemManager/conf.d/
cat > /etc/ModemManager/conf.d/beryllium.conf << 'EOF'
[ModemManager]
# Disable SMS polling to save battery
EnablePolling=false

# Log level
LogLevel=WARN
EOF

# Logind configuration for suspend/resume
print_msg "Configuring logind..."
mkdir -p /etc/systemd/logind.conf.d/
cat > /etc/systemd/logind.conf.d/beryllium.conf << 'EOF'
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
IdleAction=suspend
IdleActionSec=300
EOF

# NetworkManager dispatcher for power management
print_msg "Configuring NetworkManager power saving..."
mkdir -p /etc/NetworkManager/conf.d/
cat > /etc/NetworkManager/conf.d/beryllium-powersave.conf << 'EOF'
[connection]
wifi.powersave = 2

[device]
wifi.scan-rand-mac-address=yes
EOF

# tmpfs for /tmp and /var/log to reduce eMMC writes
print_msg "Configuring tmpfs mounts..."
mkdir -p /etc/tmpfiles.d/
cat > /etc/tmpfiles.d/beryllium.conf << 'EOF'
d /tmp 0755 root root 0
d /var/log 0755 root root 0
EOF

# I/O scheduler for eMMC
print_msg "Setting I/O scheduler..."
mkdir -p /etc/udev/rules.d/
cat > /etc/udev/rules.d/60-io-scheduler.rules << 'EOF'
# Set BFQ scheduler for eMMC (better interactive performance)
ACTION=="add|change", KERNEL=="mmcblk[0-9]*", ATTR{queue/scheduler}="bfq"
# Set none scheduler for zram (no I/O needed)
ACTION=="add|change", KERNEL=="zram*", ATTR{queue/scheduler}="none"
EOF

# SchedTune workaround for SDM845
print_msg "Applying schedtune workaround..."
cat > /etc/udev/rules.d/99-schedtune.rules << 'EOF'
# Disable schedtune boosting to prevent kernel warnings on SDM845
ACTION=="add|change", SUBSYSTEM=="cpu", RUN+="/bin/sh -c 'echo 0 > /dev/stune/top-app/schedtune.boost'"
EOF

print_msg "Common tweaks applied."
echo ""

# ============================================
# SECTION 2: Panel-Specific Tweaks
# ============================================
print_step "Applying panel-specific tweaks for: $PANEL"

case "$PANEL" in
    ebbg)
        print_msg "Panel: eBBG (Everlight TD4375)"
        
        # Panel-specific backlight steps
        cat > /etc/udev/rules.d/98-backlight.rules << 'EOF'
# eBBG backlight control
ACTION=="add|change", SUBSYSTEM=="backlight", RUN+="/bin/sh -c 'echo 2 > /sys/class/backlight/panel-backlight/max_brightness'"
EOF
        
        # Gamma correction for eBBG panel
        mkdir -p /usr/share/colorscreen/
        cat > /usr/share/colorscreen/ebbg-gamma.json << 'EOF'
{
    "name": "eBBG TD4375",
    "gamma": 2.2,
    "brightness": 1.0,
    "contrast": 1.0,
    "red": 1.0,
    "green": 1.0,
    "blue": 1.0
}
EOF
        ;;
        
    tianma)
        print_msg "Panel: Tianma TD4375"
        
        # Tianma-specific brightness
        cat > /etc/udev/rules.d/98-backlight.rules << 'EOF'
# Tianma backlight control
ACTION=="add|change", SUBSYSTEM=="backlight", RUN+="/bin/sh -c 'echo 3 > /sys/class/backlight/panel-backlight/max_brightness'"
EOF
        
        # Tianma touch calibration
        mkdir -p /usr/share/touchscreen/
        cat > /usr/share/touchscreen/tianma-calibration.conf << 'EOF'
# Tianma touch calibration values
# Adjust these based on your specific panel
MIN_X=0
MAX_X=1079
MIN_Y=0
MAX_Y=2339
SWAP_XY=false
INVERT_X=false
INVERT_Y=false
EOF
        ;;
        
    tianmaft)
        print_msg "Panel: Tianma TD4375 + Focaltech Touch"
        
        # Same backlight as Tianma
        cat > /etc/udev/rules.d/98-backlight.rules << 'EOF'
# Tianma+FT backlight control
ACTION=="add|change", SUBSYSTEM=="backlight", RUN+="/bin/sh -c 'echo 3 > /sys/class/backlight/panel-backlight/max_brightness'"
EOF
        
        # Focaltech touch specific config
        mkdir -p /etc/focaltech/
        cat > /etc/focaltech/fts.conf << 'EOF'
# Focaltech FTS touch controller configuration
# For Tianma panel variant

# Touch sensitivity
touch_threshold=12

# Grip suppression
grip_suppression=1

# Edge suppression (reduce false touches near edges)
edge_suppress_left=20
edge_suppress_right=20
edge_suppress_top=20
edge_suppress_bottom=60

# Palm rejection
palm_reject_enable=1
palm_reject_size=150

# Touch report rate (1 = high, 0 = low)
high_report_rate=1

# glove mode (0=off, 1=on)
glove_mode=0
EOF
        
        # Focaltech udev rules
        cat > /etc/udev/rules.d/99-focaltech.rules << 'EOF'
# Focaltech touch controller udev rules
ACTION=="add|change", KERNEL=="fts", RUN+="/bin/sh -c 'echo 1 > /sys/devices/virtual/input/input0/inhibited'"
EOF
        ;;
        
    *)
        print_warn "Unknown panel type: $PANEL - using defaults"
        ;;
esac

print_msg "Panel tweaks applied."
echo ""

# ============================================
# SECTION 3: Desktop-Specific Tweaks
# ============================================
print_step "Applying desktop-specific tweaks for: $DESKTOP"

case "$DESKTOP" in
    phosh)
        print_msg "Desktop: Phosh"
        
        # Phosh configuration
        mkdir -p /etc/phosh/
        
        # Phosh settings (lockscreen timeout, etc.)
        cat > /etc/phosh/phosh-settings.conf << 'EOF'
[phosh]
lock-timeout-seconds=300
rotation-lock=false
EOF
        
        # Phosh compositor (phoc) tweaks
        mkdir -p /etc/phosh/phoc/
        cat > /etc/phosh/phoc/config.ini << 'EOF'
[core]
# Reduce rendering latency
render-damage-tracking=true

[input]
# Touchscreen calibration
touchscreen-enabled=true
EOF
        
        # Onboard keyboard tweaks for Phosh
        mkdir -p /etc/onboard/
        cat > /etc/onboard/onboard.conf << 'EOF'
[general]
# Larger keyboard for phone use
orientation=auto
EOF
        
        # Phosh notification daemon tweaks
        mkdir -p /usr/lib/systemd/system/
        cat > /usr/lib/systemd/system/phosh-notifications.service.d/override.conf << 'EOF'
[Service]
Environment="G_MESSAGES_DEBUG=0"
EOF
        
        # Suspend tweaks for Phosh
        mkdir -p /usr/lib/systemd/system/
        cat > /usr/lib/systemd/system/phosh.service.d/suspend.conf << 'EOF'
[Service]
Environment="PHOSH_SUSPEND_TIMEOUT=300"
EOF
        
        ;;
        
    lomiri)
        print_msg "Desktop: Lomiri"
        
        # Lomiri (Unity8) configuration
        mkdir -p /usr/share/lomiri/
        
        # Lomiri shell settings
        cat > /usr/share/lomiri/launcher.json << 'EOF'
{
    "pageWidth": 1,
    "maxNumberPages": 2,
    "hasDecayAnimation": true
}
EOF
        
        # Lomiri indicators configuration
        mkdir -p /etc/lomiri-indicators/
        cat > /etc/lomiri-indicators/beryllium.conf << 'EOF'
[indicators]
# Show battery indicator
battery=true

# Show network indicator  
network=true

# Show sound indicator
sound=true

# Show datetime indicator
datetime=true
EOF
        
        # Lomiri apparmor tweaks for better permissions
        mkdir -p /etc/apparmor.d/
        cat > /etc/apparmor.d/lomiri-beryllium << 'EOF'
# Additional apparmor rules for beryllium
/usr/sbin/backlight-helper ix,
/sys/class/backlight/** rw,
/sys/class/leds/** rw,
/dev/input/** rw,
/dev/fb* rw,
EOF
        
        # Unity8/Lomiri touch gestures
        mkdir -p /usr/share/unity8/
        cat > /usr/share/unity8/touch-gestures.conf << 'EOF'
[gestures]
# Swipe from left edge = app drawer
left-edge-swipe=true

# Swipe from right edge = back
right-edge-swipe=true

# Swipe from top = indicators
top-edge-swipe=true

# Swipe from bottom = app spread
bottom-edge-swipe=true
EOF
        
        # Lomiri window manager settings
        mkdir -p /etc/lomiri/
        cat > /etc/lomiri/window-management.conf << 'EOF'
[window-management]
# Phablet mode
mode=phablet

# Animations
animations-enabled=true
animation-speed=1.0
EOF
        
        ;;
        
    *)
        print_warn "Unknown desktop: $DESKTOP - using defaults"
        ;;
esac

print_msg "Desktop tweaks applied."
echo ""

# ============================================
# SECTION 4: Variant-Specific Optimizations
# ============================================
print_step "Applying variant-specific optimizations: $VARIANT"

# Read variant config if it exists
if [ -f "${VARIANT_DIR}/variant.conf" ]; then
    source "${VARIANT_DIR}/variant.conf"
    print_msg "Loaded variant config: $VARIANT"
fi

# Variant-specific audio tweaks
print_msg "Configuring audio pipeline..."
mkdir -p /etc/pulse/
cat > /etc/pulse/daemon.d/beryllium.conf << 'EOF'
[daemon]
# Reduce latency for phone use
default-fragments = 2
default-fragment-size-msec = 10

# Sample rate
default-sample-rate = 44100
default-sample-channels = 2

# Resample method (fast)
resample-method = speex-float-1

# Avoid resampling when possible
enable-remixing = no
EOF

# Camera quirks for SDM845
print_msg "Applying camera quirks..."
mkdir -p /etc/camera/
cat > /etc/camera/beryllium-quirks.conf << 'EOF'
# SDM845 camera quirks
# Disable HDR by default (causes crashes on some variants)
hdr_default=false

# Video stabilization
ois_enabled=true

# Front camera mirror
front_camera_mirror=true
EOF

# Bluetooth optimizations
print_msg "Configuring Bluetooth..."
mkdir -p /etc/bluetooth/
cat > /etc/bluetooth/main.conf << 'EOF'
[General]
# Enable A2DP Sink
Enable=Source,Sink,Media,Socket

# Enable fast pairing
FastConnectable = true

# Auto-enable on boot
AutoEnable=true

[Policy]
# Auto-enable for all
AutoEnable=true

# Enable A2DP
A2DP=true

# Enable HFP
HFP=true
EOF

# GPS configuration
print_msg "Configuring GPS..."
mkdir -p /etc/gps/
cat > /etc/gps/beryllium.conf << 'EOF'
[GPS]
# AGPS configuration
enabled=true
agps_server=supl.google.com
agps_port=7276

# Power saving
power_save_mode=false

# NMEA logging (disable for production)
nmea_logging=false
EOF

# Thermal management
print_msg "Configuring thermal management..."
mkdir -p /etc/thermal/
cat > /etc/thermal/beryllium.conf << 'EOF'
[thermal]
# Thermal zones
# SDM845 has multiple thermal zones

# Battery charging limit (prevent overheating during charging)
battery_thermal_limit=42

# CPU throttling temperatures
cpu_warning_temp=45
cpu_critical_temp=50

# GPU throttling
gpu_warning_temp=45
gpu_critical_temp=50
EOF

print_msg "Variant-specific optimizations applied."
echo ""

# ============================================
# SECTION 5: Power Management Profile
# ============================================
print_step "Applying power management profile..."

mkdir -p /etc/systemd/sleep.conf.d/
cat > /etc/systemd/sleep.conf.d/beryllium.conf << 'EOF'
[Sleep]
AllowHibernation=no
AllowSuspend=yes
AllowHybridSleep=no
AllowSuspendThenHibernate=no

# Suspend state
SuspendState=mem standby freeze

# Suspend timeout (5 minutes)
SuspendTimeoutSec=300
EOF

# TLP for power management (if installed)
if command -v tlp &> /dev/null; then
    print_msg "Configuring TLP power management..."
    cat > /etc/tlp.d/01-beryllium.conf << 'EOF'
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
WiFi_PWR_ON_AC=on
WiFi_PWR_ON_BAT=on
EOF
fi

print_msg "Power management configured."
echo ""

# ============================================
# SECTION 6: Cleanup and Final Steps
# ============================================
print_step "Finalizing tweaks..."

# Update udev rules
if command -v udevadm &> /dev/null; then
    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger 2>/dev/null || true
fi

# Reload systemd
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload 2>/dev/null || true
fi

# Fix permissions
chmod 644 /etc/udev/rules.d/*.rules 2>/dev/null || true
chmod 644 /etc/systemd/*.conf 2>/dev/null || true

echo ""
print_msg "=========================================="
print_msg "All tweaks applied successfully for: $VARIANT"
print_msg "=========================================="
echo ""
print_msg "Summary:"
print_msg "  - Common device tweaks (power, I/O, modem)"
print_msg "  - Panel tweaks ($PANEL)"
print_msg "  - Desktop tweaks ($DESKTOP)"
print_msg "  - Audio pipeline configured"
print_msg "  - Camera quirks applied"
print_msg "  - Bluetooth optimized"
print_msg "  - GPS configured"
print_msg "  - Thermal management set"
print_msg "  - Power management profile active"
echo ""
print_msg "Reboot recommended for all changes to take effect."
