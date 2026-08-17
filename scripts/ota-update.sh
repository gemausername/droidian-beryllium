#!/bin/bash
# OTA Update Script for Droidian Poco F1
# This script handles over-the-air updates for the device

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
    echo "  Droidian OTA Update for Poco F1"
    echo "============================================"
    echo -e "${NC}"
}

# Configuration
REPO_URL="https://YOUR_USERNAME.github.io/droidian-beryllium-repo"
KEY_URL="${REPO_URL}/beryllium.gpg"
KEYRING_PATH="/usr/share/keyrings/beryllium.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/beryllium.list"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_header

# Function to setup repository
setup_repo() {
    print_step "Setting up APT repository..."
    
    # Install GPG key
    print_msg "Installing repository key..."
    mkdir -p /usr/share/keyrings
    wget -qO- "$KEY_URL" | gpg --dearmor -o "$KEYRING_PATH"
    
    # Add repository
    print_msg "Adding repository..."
    echo "deb [signed-by=$KEYRING_PATH] $REPO_URL stable main" > "$SOURCES_LIST"
    
    # Update package lists
    print_msg "Updating package lists..."
    apt-get update
    
    print_msg "Repository setup complete"
}

# Function to check for updates
check_updates() {
    print_step "Checking for updates..."
    
    # Update package lists
    apt-get update
    
    # Check for available updates
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -E "(adaptation-droidian|linux-image|linux-bootimage)" | wc -l)
    
    if [ "$UPDATES" -gt 0 ]; then
        print_msg "Found $UPDATES updates available:"
        apt list --upgradable 2>/dev/null | grep -E "(adaptation-droidian|linux-image|linux-bootimage)"
        return 0
    else
        print_msg "System is up to date"
        return 1
    fi
}

# Function to perform update
perform_update() {
    print_step "Performing update..."
    
    # Check for updates
    if ! check_updates; then
        return 0
    fi
    
    # Ask for confirmation
    echo ""
    read -p "Do you want to install these updates? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_msg "Update cancelled"
        return 0
    fi
    
    # Backup current state
    print_msg "Creating backup..."
    BACKUP_DIR="/var/backups/droidian-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    dpkg --get-selections > "$BACKUP_DIR/package-selections.txt"
    
    # Perform upgrade
    print_msg "Upgrading packages..."
    apt-get upgrade -y
    
    # Update kernel if needed
    if apt list --upgradable 2>/dev/null | grep -q "linux-image"; then
        print_msg "Kernel update detected, updating boot image..."
        # The flash-bootimage script should handle this automatically
    fi
    
    # Clean up
    print_msg "Cleaning up..."
    apt-get autoremove -y
    apt-get autoclean
    
    print_msg "Update complete!"
    print_msg "Please reboot your device for changes to take effect."
}

# Function to update kernel
update_kernel() {
    print_step "Updating kernel..."
    
    # Check if kernel update is available
    if apt list --upgradable 2>/dev/null | grep -q "linux-image"; then
        print_msg "Kernel update available"
        
        # Ask for confirmation
        echo ""
        read -p "Do you want to update the kernel? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_msg "Kernel update cancelled"
            return 0
        fi
        
        # Update kernel package
        apt-get upgrade linux-image-* -y
        
        # The flash-bootimage script should handle flashing
        print_msg "Kernel updated. Please reboot for changes to take effect."
    else
        print_msg "No kernel update available"
    fi
}

# Function to rollback
rollback() {
    print_step "Rolling back to previous version..."
    
    # Find backup
    BACKUP_DIR=$(ls -d /var/backups/droidian-* 2>/dev/null | tail -1)
    
    if [ -z "$BACKUP_DIR" ]; then
        print_error "No backup found"
        return 1
    fi
    
    print_msg "Restoring from backup: $BACKUP_DIR"
    
    # Restore package selections
    dpkg --set-selections < "$BACKUP_DIR/package-selections.txt"
    
    # Downgrade packages
    apt-get dselect-upgrade -y
    
    print_msg "Rollback complete"
    print_msg "Please reboot your device."
}

# Function to show current version
show_version() {
    print_step "Current system information:"
    
    echo ""
    echo "Droidian version:"
    cat /etc/droidian-version 2>/dev/null || echo "Unknown"
    echo ""
    echo "Kernel version:"
    uname -r
    echo ""
    echo "Adaptation package version:"
    dpkg -l | grep adaptation-droidian-beryllium | awk '{print $3}' || echo "Not installed"
    echo ""
}

# Function to show update log
show_log() {
    print_step "Update log:"
    
    if [ -f /var/log/apt/history.log ]; then
        tail -50 /var/log/apt/history.log
    else
        print_msg "No update log found"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "Available options:"
    echo "  1. Setup repository"
    echo "  2. Check for updates"
    echo "  3. Install updates"
    echo "  4. Update kernel"
    echo "  5. Rollback"
    echo "  6. Show version"
    echo "  7. Show update log"
    echo "  0. Exit"
    echo ""
}

while true; do
    show_menu
    read -p "Select option: " choice
    
    case $choice in
        1) setup_repo ;;
        2) check_updates ;;
        3) perform_update ;;
        4) update_kernel ;;
        5) rollback ;;
        6) show_version ;;
        7) show_log ;;
        0) 
            print_msg "Exiting..."
            break
            ;;
        *)
            print_error "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
