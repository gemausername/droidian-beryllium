#!/bin/bash
# GPG Key Setup Script for Droidian Package Signing
# This script generates a GPG key for signing Debian packages

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

# Check if running as non-root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Get user info
read -p "Enter your name: " USER_NAME
read -p "Enter your email: " USER_EMAIL

print_step "1. Creating GPG key directory..."
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

print_step "2. Generating GPG key..."
cat > /tmp/gpg-key-params << EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${USER_NAME}
Name-Email: ${USER_EMAIL}
Expire-Date: 0
%commit
EOF

gpg --batch --gen-key /tmp/gpg-key-params
rm /tmp/gpg-key-params

print_step "3. Exporting GPG key..."
KEY_ID=$(gpg --list-keys --keyid-format long "${USER_EMAIL}" | grep -E "^[[:space:]]*[0-9a-f]{40}" | head -1 | awk '{print $1}')

if [ -z "$KEY_ID" ]; then
    print_error "Failed to get key ID"
    exit 1
fi

print_msg "Generated Key ID: ${KEY_ID}"

# Export keys
gpg --armor --export "${KEY_ID}" > ~/gpg-public-key.asc
gpg --armor --export-secret-keys "${KEY_ID}" > ~/gpg-private-key.asc
gpg --export --armor "${KEY_ID}" > ~/gpg-export-key.asc

print_step "4. Creating keyring for repository..."
mkdir -p ~/droidian-beryllium/packages/adaptation-droidian-beryllium/sparse/usr/share/keyrings
gpg --export "${KEY_ID}" | \
    gpg --dearmor > ~/droidian-beryllium/packages/adaptation-droidian-beryllium/sparse/usr/share/keyrings/beryllium.gpg

print_step "5. Saving key information..."
cat > ~/droidian-gpg-key-info.txt << EOF
=====================================
Droidian GPG Key Information
=====================================
Key ID:     ${KEY_ID}
Name:       ${USER_NAME}
Email:      ${USER_EMAIL}
Created:    $(date)

Files:
  - ~/gpg-public-key.asc      (Public key - share this)
  - ~/gpg-private-key.asc     (Private key - KEEP SECURE!)
  - ~/gpg-export-key.asc      (Export format)

Repository Keyring:
  - ~/droidian-beryllium/packages/.../beryllium.gpg

=====================================
IMPORTANT: Keep your private key secure!
=====================================
EOF

print_msg "GPG key generated successfully!"
echo ""
print_msg "Key ID: ${KEY_ID}"
print_msg ""
print_msg "Next steps:"
print_msg "1. Save the Key ID - you'll need it for GitHub/GitLab secrets"
print_msg "2. Keep ~/gpg-private-key.asc secure - never share it!"
print_msg "3. Use ~/gpg-public-key.asc as your repository's public key"
echo ""
print_msg "Information saved to: ~/droidian-gpg-key-info.txt"
cat ~/droidian-gpg-key-info.txt
