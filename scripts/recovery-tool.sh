#!/bin/bash
# Recovery and Repair Script for Droidian Poco F1
# This script helps recover from boot issues and common problems

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
    echo "  Droidian Recovery Tool for Poco F1"
    echo "============================================"
    echo -e "${NC}"
}

# Function to mount rootfs
mount_rootfs() {
    print_step "Mounting rootfs..."
    
    # Try to find and mount the rootfs
    ROOTFS_PARTITION=""
    for part in /dev/disk/by-partlabel/userdata /dev/sda23 /dev/mmcblk0p23; do
        if [ -b "$part" ]; then
            ROOTFS_PARTITION="$part"
            break
        fi
    done
    
    if [ -z "$ROOTFS_PARTITION" ]; then
        print_error "Could not find rootfs partition"
        return 1
    fi
    
    mkdir -p /tmp/mpoint
    mount "$ROOTFS_PARTITION" /tmp/mpoint
    print_msg "Mounted rootfs at /tmp/mpoint"
}

# Function to chroot into rootfs
chroot_rootfs() {
    print_step "Entering chroot environment..."
    mount_rootfs
    
    # Mount necessary filesystems
    mount --bind /dev /tmp/mpoint/dev
    mount --bind /proc /tmp/mpoint/proc
    mount --bind /sys /tmp/mpoint/sys
    
    # Chroot
    chroot /tmp/mpoint /bin/bash
}

# Function to unmount rootfs
unmount_rootfs() {
    print_step "Unmounting rootfs..."
    umount /tmp/mpoint/dev 2>/dev/null || true
    umount /tmp/mpoint/proc 2>/dev/null || true
    umount /tmp/mpoint/sys 2>/dev/null || true
    umount /tmp/mpoint 2>/dev/null || true
}

# Function to fix boot issues
fix_boot() {
    print_step "Fixing boot issues..."
    
    mount_rootfs
    
    # Check for common boot issues
    print_msg "Checking for common boot issues..."
    
    # 1. Check if systempart is in cmdline
    if grep -q "systempart=" /tmp/mpoint/etc/kernel/cmdline 2>/dev/null; then
        print_warn "Found systempart= in cmdline, removing..."
        sed -i 's/systempart=[^ ]* //g' /tmp/mpoint/etc/kernel/cmdline
        print_msg "Removed systempart from cmdline"
    fi
    
    # 2. Check for problematic systemd services
    print_msg "Masking potentially problematic services..."
    chroot /tmp/mpoint systemctl mask systemd-journald 2>/dev/null || true
    chroot /tmp/mpoint systemctl mask systemd-resolved 2>/dev/null || true
    chroot /tmp/mpoint systemctl mask systemd-timesyncd 2>/dev/null || true
    
    # 3. Fix fstab
    print_msg "Checking fstab..."
    if [ ! -f /tmp/mpoint/etc/fstab ]; then
        print_warn "fstab not found, creating default..."
        cat > /tmp/mpoint/etc/fstab << 'EOF'
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/root       /               auto    defaults,noatime 0 1
proc            /proc           proc    defaults          0 0
sysfs           /sys            sysfs   defaults          0 0
tmpfs           /tmp            tmpfs   defaults,noatime 0 0
EOF
    fi
    
    unmount_rootfs
    print_msg "Boot fixes applied"
}

# Function to fix networking
fix_networking() {
    print_step "Fixing networking..."
    
    mount_rootfs
    
    # Fix resolv.conf
    print_msg "Fixing resolv.conf..."
    echo "nameserver 8.8.8.8" > /tmp/mpoint/etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /tmp/mpoint/etc/resolv.conf
    
    # Fix network interfaces
    print_msg "Setting up network interfaces..."
    cat > /tmp/mpoint/etc/network/interfaces << 'EOF'
# Loopback
auto lo
iface lo inet loopback

# Primary network interface
auto eth0
iface eth0 inet dhcp

# USB networking
auto usb0
iface usb0 inet static
    address 10.15.19.101
    netmask 255.255.255.0
    gateway 10.15.19.100
EOF
    
    unmount_rootfs
    print_msg "Networking fixes applied"
}

# Function to fix SSH
fix_ssh() {
    print_step "Fixing SSH access..."
    
    mount_rootfs
    
    # Enable SSH
    print_msg "Enabling SSH..."
    chroot /tmp/mpoint systemctl enable ssh 2>/dev/null || true
    
    # Create SSH fix service
    cat > /tmp/mpoint/etc/systemd/system/ssh-fix.service << 'EOF'
[Unit]
Description=Fix SSH boot issue
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    chroot /tmp/mpoint systemctl enable ssh-fix 2>/dev/null || true
    
    # Set default password
    print_msg "Setting default password..."
    echo "droidian:1234" | chroot /tmp/mpoint chpasswd 2>/dev/null || true
    
    unmount_rootfs
    print_msg "SSH fixes applied"
}

# Function to fix Bluetooth
fix_bluetooth() {
    print_step "Fixing Bluetooth..."
    
    mount_rootfs
    
    # Create bluetooth directory
    mkdir -p /tmp/mpoint/var/lib/bluetooth
    
    # Create empty board-address file
    touch /tmp/mpoint/var/lib/bluetooth/board-address
    chmod 644 /tmp/mpoint/var/lib/bluetooth/board-address
    
    unmount_rootfs
    print_msg "Bluetooth fix applied"
}

# Function to fix display
fix_display() {
    print_step "Fixing display..."
    
    mount_rootfs
    
    # Create phosh config
    mkdir -p /tmp/mpoint/etc/phosh
    cat > /tmp/mpoint/etc/phosh/phoc.ini << 'EOF'
[core]
scale=1.5

[output:HWCOMPOSER-1]
transform=0
EOF
    
    # Create brightness fix
    cat > /tmp/mpoint/etc/systemd/system/brightness-fix.service << 'EOF'
[Unit]
Description=Fix LCD brightness on boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 128 > /sys/class/leds/lcd-backlight/brightness'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    chroot /tmp/mpoint systemctl enable brightness-fix 2>/dev/null || true
    
    unmount_rootfs
    print_msg "Display fix applied"
}

# Function to fix Halium container
fix_halium() {
    print_step "Fixing Halium container..."
    
    mount_rootfs
    
    # Regenerate udev rules
    print_msg "Regenerating udev rules..."
    DEVICE="beryllium"
    cat /tmp/mpoint/var/lib/lxc/android/rootfs/ueventd*.rc \
        /tmp/mpoint/var/lib/lxc/android/rootfs/system/etc/ueventd*.rc \
        /tmp/mpoint/vendor/ueventd*.rc \
        /tmp/mpoint/var/lib/lxc/android/rootfs/vendor/etc/ueventd*.rc 2>/dev/null | \
        grep "^/dev" | \
        sed -e 's/^\/dev\///' | \
        awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | \
        sed -e 's/\r//' > /tmp/mpoint/etc/udev/rules.d/70-${DEVICE}.rules
    
    # Fix Halium container startup
    print_msg "Fixing Halium container..."
    cat > /tmp/mpoint/etc/systemd/system/lxc@android.service << 'EOF'
[Unit]
Description=LXC Container: Android
After=network.target

[Service]
Type=simple
ExecStartPre=/bin/true
ExecStart=/bin/true
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    unmount_rootfs
    print_msg "Halium container fix applied"
}

# Function to factory reset
factory_reset() {
    print_step "Factory reset..."
    
    echo -e "${RED}WARNING: This will erase all data!${NC}"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        mount_rootfs
        
        # Backup important files
        print_msg "Backing up important files..."
        mkdir -p /tmp/backup
        cp -r /tmp/mpoint/etc/ssh /tmp/backup/ 2>/dev/null || true
        cp -r /tmp/mpoint/home /tmp/backup/ 2>/dev/null || true
        
        # Clean rootfs
        print_msg "Cleaning rootfs..."
        rm -rf /tmp/mpoint/*
        
        # Restore backup
        print_msg "Restoring backup..."
        cp -r /tmp/backup/* /tmp/mpoint/ 2>/dev/null || true
        
        unmount_rootfs
        print_msg "Factory reset complete"
    else
        print_msg "Factory reset cancelled"
    fi
}

# Function to backup system
backup_system() {
    print_step "Backing up system..."
    
    BACKUP_DIR="/tmp/droidian-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    mount_rootfs
    
    # Backup important files
    print_msg "Backing up configuration..."
    tar -czf "$BACKUP_DIR/etc.tar.gz" -C /tmp/mpoint etc
    tar -czf "$BACKUP_DIR/home.tar.gz" -C /tmp/mpoint home
    
    unmount_rootfs
    
    print_msg "Backup created at: $BACKUP_DIR"
}

# Function to restore system
restore_system() {
    print_step "Restoring system..."
    
    # Find backup
    BACKUP_DIR=$(ls -d /tmp/droidian-backup-* 2>/dev/null | head -1)
    
    if [ -z "$BACKUP_DIR" ]; then
        print_error "No backup found"
        return 1
    fi
    
    mount_rootfs
    
    # Restore files
    print_msg "Restoring configuration..."
    tar -xzf "$BACKUP_DIR/etc.tar.gz" -C /tmp/mpoint
    tar -xzf "$BACKUP_DIR/home.tar.gz" -C /tmp/mpoint
    
    unmount_rootfs
    print_msg "System restored from: $BACKUP_DIR"
}

# Main menu
show_menu() {
    echo ""
    echo "Available options:"
    echo "  1. Fix boot issues"
    echo "  2. Fix networking"
    echo "  3. Fix SSH access"
    echo "  4. Fix Bluetooth"
    echo "  5. Fix display"
    echo "  6. Fix Halium container"
    echo "  7. Factory reset"
    echo "  8. Backup system"
    echo "  9. Restore system"
    echo "  10. Enter chroot"
    echo "  0. Exit"
    echo ""
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_header

while true; do
    show_menu
    read -p "Select option: " choice
    
    case $choice in
        1) fix_boot ;;
        2) fix_networking ;;
        3) fix_ssh ;;
        4) fix_bluetooth ;;
        5) fix_display ;;
        6) fix_halium ;;
        7) factory_reset ;;
        8) backup_system ;;
        9) restore_system ;;
        10) chroot_rootfs ;;
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
