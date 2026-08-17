#!/bin/bash
# Bluetooth MAC address retrieval script for Xiaomi Poco F1 (beryllium)
# This script retrieves the Bluetooth address from Android properties

set -e

BT_ADDR_FILE="/var/lib/bluetooth/board-address"

# Try to get BT address from various sources
get_bt_address() {
    # Method 1: From Android properties via getprop
    if command -v getprop &> /dev/null; then
        local addr=$(getprop persist.bluetooth.bdroid_addr)
        if [ -n "$addr" ]; then
            echo "$addr"
            return 0
        fi
    fi

    # Method 2: From /var/lib/bluetooth/board-address (if exists)
    if [ -f "$BT_ADDR_FILE" ] && [ -s "$BT_ADDR_FILE" ]; then
        cat "$BT_ADDR_FILE"
        return 0
    fi

    # Method 3: From sysfs (Qualcomm specific)
    if [ -f /sys/devices/soc0/serial_number ]; then
        local serial=$(cat /sys/devices/soc0/serial_number)
        # Generate pseudo-random but deterministic BT address from serial
        echo "00:${serial:0:2}:${serial:2:2}:${serial:4:2}:${serial:6:2}:${serial:8:2}"
        return 0
    fi

    # Method 4: From firmware
    if [ -f /sys/module/btpower/parameters/bd_address ]; then
        local addr=$(cat /sys/module/btpower/parameters/bd_address)
        if [ -n "$addr" ]; then
            echo "$addr"
            return 0
        fi
    fi

    return 1
}

# Main execution
BT_ADDR=$(get_bt_address)

if [ -n "$BT_ADDR" ]; then
    mkdir -p /var/lib/bluetooth
    echo "$BT_ADDR" > "$BT_ADDR_FILE"
    chmod 644 "$BT_ADDR_FILE"
    echo "Bluetooth address set to: $BT_ADDR"
else
    echo "Could not determine Bluetooth address, creating empty file"
    mkdir -p /var/lib/bluetooth
    touch "$BT_ADDR_FILE"
fi
