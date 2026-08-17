#!/bin/bash
# APT Repository Setup Script
# This script sets up a local APT repository for Droidian packages

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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Configuration
REPO_DIR="/var/local/repo/droidian-beryllium"
REPO_URL="http://localhost/repo/droidian-beryllium"

print_step "1. Creating repository directory structure..."
mkdir -p "${REPO_DIR}/dists/bookworm/main/binary-arm64"
mkdir -p "${REPO_DIR}/pool/main"

print_step "2. Copying packages..."
# Copy adaptation package
if [ -f "${PROJECT_DIR}/output/adaptation-droidian-beryllium_1.0_arm64.deb" ]; then
    cp "${PROJECT_DIR}/output/adaptation-droidian-beryllium_1.0_arm64.deb" "${REPO_DIR}/pool/main/"
    print_msg "Copied adaptation package"
fi

# Copy kernel packages
if ls "${HOME}/droidian/packages/"*.deb 1> /dev/null 2>&1; then
    cp "${HOME}/droidian/packages/"*.deb "${REPO_DIR}/pool/main/"
    print_msg "Copied kernel packages"
fi

print_step "3. Generating Packages file..."
cd "${REPO_DIR}/dists/bookworm/main/binary-arm64"
dpkg-scanpackages --arch arm64 ../../pool/main /dev/null > Packages
gzip -k -f Packages

print_step "4. Generating Release file..."
cd "${REPO_DIR}/dists/bookworm"

cat > Release << EOF
Origin: Droidian Poco F1 Repository
Label: Droidian Poco F1
Suite: bookworm
Codename: bookworm
Architectures: arm64
Components: main
Description: Droidian packages for Xiaomi Poco F1 (beryllium)
Date: $(date -R)
SHA256:
 $(sha256sum main/binary-arm64/Packages | awk '{print $1}') $(stat -c%s main/binary-arm64/Packages) main/binary-arm64/Packages
 $(sha256sum main/binary-arm64/Packages.gz | awk '{print $1}') $(stat -c%s main/binary-arm64/Packages.gz) main/binary-arm64/Packages.gz
EOF

print_step "5. Signing repository..."
# Check for GPG key
if gpg --list-keys | grep -q "Droidian"; then
    KEY_ID=$(gpg --list-keys --keyid-format long "Droidian" | grep -E "^[[:space:]]*[0-9a-f]{40}" | head -1 | awk '{print $1}')
    
    if [ -n "$KEY_ID" ]; then
        print_msg "Signing with key: ${KEY_ID}"
        gpg --default-key "${KEY_ID}" --clearsign -o InRelease Release
        gpg --default-key "${KEY_ID}" --armor --detach-sign -o Release.gpg Release
    else
        print_warn "No GPG key found, skipping signing"
    fi
else
    print_warn "No GPG key found, skipping signing"
fi

print_step "6. Setting up web server..."
# Install nginx if not present
if ! command -v nginx &> /dev/null; then
    print_msg "Installing nginx..."
    apt-get update
    apt-get install -y nginx
fi

# Create nginx configuration
cat > /etc/nginx/sites-available/droidian-beryllium << 'NGINX_EOF'
server {
    listen 80;
    server_name localhost;
    
    root /var/local/repo/droidian-beryllium;
    
    location / {
        autoindex on;
    }
}
NGINX_EOF

# Enable site
ln -sf /etc/nginx/sites-available/droidian-beryllium /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Restart nginx
systemctl restart nginx
systemctl enable nginx

print_step "7. Testing repository..."
if curl -s "http://localhost/dists/bookworm/Release" > /dev/null; then
    print_msg "Repository is working!"
else
    print_warn "Repository might not be accessible yet"
fi

print_msg ""
print_msg "=========================================="
print_msg "Repository Setup Complete!"
print_msg "=========================================="
print_msg ""
print_msg "Local repository: ${REPO_DIR}"
print_msg "Web access: http://localhost"
print_msg ""
print_msg "To add this repository to your Droidian device:"
print_msg ""
print_msg "  sudo echo 'deb [signed-by=/usr/share/keyrings/beryllium.gpg] http://YOUR_IP/bookworm main' > /etc/apt/sources.list.d/beryllium.list"
print_msg ""
print_msg "Then run:"
print_msg "  sudo apt update"
print_msg "  sudo apt install adaptation-droidian-beryllium"
print_msg ""
print_msg "For external access, replace YOUR_IP with your computer's IP address."
