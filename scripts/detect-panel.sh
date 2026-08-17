#!/bin/bash
# Panel Detection Script for Xiaomi Poco F1 (beryllium)
# This script detects which panel type is installed on the device

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
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           Panel Detection Tool for Poco F1                   ║"
    echo "║                      (beryllium)                             ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_header

# Function to check if running on device
check_device() {
    if [ ! -f /sys/class/dmi/id/product_name ]; then
        print_warn "Not running on a device. Running in detection mode..."
        return 1
    fi
    
    local product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
    if [[ "$product" != *"beryllium"* ]]; then
        print_warn "This doesn't appear to be a Poco F1 (beryllium)"
        print_warn "Product: $product"
        return 1
    fi
    
    print_msg "Running on Poco F1 (beryllium)"
    return 0
}

# Function to detect panel via device tree
detect_panel_dt() {
    print_step "Detecting panel via device tree..."
    
    local panel_path="/sys/firmware/devicetree/base/soc/dsi@ae94000/panel@0"
    
    if [ -d "$panel_path" ]; then
        local compatible=$(cat "$panel_path/compatible" 2>/dev/null | tr '\0' '\n' | head -1)
        
        if [[ "$compatible" == *"truly"* ]] || [[ "$compatible" == *"ebbg"* ]]; then
            echo "ebbg"
            return 0
        elif [[ "$compatible" == *"tianma"* ]]; then
            # Check for Focaltech touch
            local touch_path="/sys/firmware/devicetree/base/soc/i2@a94000/fts@49"
            if [ -d "$touch_path" ]; then
                local touch_compat=$(cat "$touch_path/compatible" 2>/dev/null | tr '\0' '\n' | head -1)
                if [[ "$touch_compat" == *"focaltech"* ]]; then
                    echo "tianmaft"
                    return 0
                fi
            fi
            echo "tianma"
            return 0
        fi
    fi
    
    echo "unknown"
    return 1
}

# Function to detect panel via kernel logs
detect_panel_dmesg() {
    print_step "Detecting panel via kernel logs..."
    
    if command -v dmesg &> /dev/null; then
        local panel_info=$(dmesg 2>/dev/null | grep -i "panel\|display\|dsi" | head -10)
        
        if [[ "$panel_info" == *"truly"* ]] || [[ "$panel_info" == *"ebbg"* ]]; then
            echo "ebbg"
            return 0
        elif [[ "$panel_info" == *"tianma"* ]]; then
            echo "tianma"
            return 0
        fi
    fi
    
    echo "unknown"
    return 1
}

# Function to detect panel via lshw
detect_panel_lshw() {
    print_step "Detecting panel via lshw..."
    
    if command -v lshw &> /dev/null; then
        local display_info=$(sudo lshw -C display 2>/dev/null)
        
        if [[ "$display_info" == *"truly"* ]] || [[ "$display_info" == *"ebbg"* ]]; then
            echo "ebbg"
            return 0
        elif [[ "$display_info" == *"tianma"* ]]; then
            echo "tianma"
            return 0
        fi
    fi
    
    echo "unknown"
    return 1
}

# Function to detect touch controller
detect_touch() {
    print_step "Detecting touch controller..."
    
    local touch_path="/sys/class/input/"
    
    for event in "$touch_path"event*; do
        if [ -d "$event" ]; then
            local name=$(cat "$event/device/name" 2>/dev/null)
            
            if [[ "$name" == *"fts"* ]]; then
                echo "fts"
                return 0
            elif [[ "$name" == *"focaltech"* ]]; then
                echo "focaltech"
                return 0
            fi
        fi
    done
    
    echo "unknown"
    return 1
}

# Function to detect current desktop
detect_desktop() {
    print_step "Detecting current desktop environment..."
    
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        echo "$XDG_CURRENT_DESKTOP"
    elif [ -n "$DESKTOP_SESSION" ]; then
        echo "$DESKTOP_SESSION"
    elif pgrep -x "phoc" > /dev/null; then
        echo "phosh"
    elif pgrep -x "lomiri" > /dev/null; then
        echo "lomiri"
    elif pgrep -x "unity8" > /dev/null; then
        echo "lomiri"
    else
        echo "unknown"
    fi
}

# Main detection
PANEL="unknown"
TOUCH="unknown"
DESKTOP="unknown"

# Try detection methods
if check_device; then
    # Method 1: Device tree
    PANEL=$(detect_panel_dt)
    
    # Method 2: Kernel logs (if device tree failed)
    if [ "$PANEL" = "unknown" ]; then
        PANEL=$(detect_panel_dmesg)
    fi
    
    # Method 3: lshw (if others failed)
    if [ "$PANEL" = "unknown" ]; then
        PANEL=$(detect_panel_lshw)
    fi
fi

# Detect touch controller
TOUCH=$(detect_touch)

# Detect desktop
DESKTOP=$(detect_desktop)

# Determine variant
VARIANT="unknown"
case "$DESKTOP" in
    phosh)
        case "$PANEL" in
            ebbg) VARIANT="phosh-ebbg" ;;
            tianma)
                if [ "$TOUCH" = "focaltech" ]; then
                    VARIANT="phosh-tianmaft"
                else
                    VARIANT="phosh-tianma"
                fi
                ;;
            *) VARIANT="phosh-unknown" ;;
        esac
        ;;
    lomiri|unity8)
        case "$PANEL" in
            ebbg) VARIANT="lomiri-ebbg" ;;
            tianma)
                if [ "$TOUCH" = "focaltech" ]; then
                    VARIANT="lomiri-tianmaft"
                else
                    VARIANT="lomiri-tianma"
                fi
                ;;
            *) VARIANT="lomiri-unknown" ;;
        esac
        ;;
esac

# Print results
echo ""
echo "=========================================="
echo "  Detection Results"
echo "=========================================="
echo ""
echo "Panel Type:    $PANEL"
echo "Touch:         $TOUCH"
echo "Desktop:       $DESKTOP"
echo "Variant:       $VARIANT"
echo ""

# Recommend variant
if [ "$VARIANT" != "unknown" ]; then
    print_msg "Recommended variant: $VARIANT"
    echo ""
    echo "To install the correct adaptation package:"
    echo "  sudo apt install adaptation-droidian-beryllium-$VARIANT"
else
    print_warn "Could not determine variant"
    echo ""
    echo "Please check your device manually:"
    echo "  - Check device tree: ls /sys/firmware/devicetree/base/soc/dsi@ae94000/panel@0/"
    echo "  - Check kernel logs: dmesg | grep panel"
    echo "  - Check input devices: cat /sys/class/input/event*/device/name"
fi

echo ""
echo "=========================================="
