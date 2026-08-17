#!/bin/bash
# GitHub Pages Repository Setup Script
# This script sets up a GitHub repository for hosting Droidian packages

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

# Check if running as non-root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Check for GitHub CLI
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed."
    print_msg "Install it with: sudo apt install gh"
    print_msg "Or visit: https://cli.github.com/"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    print_error "Not logged in to GitHub CLI."
    print_msg "Run: gh auth login"
    exit 1
fi

print_step "1. Creating GitHub repository..."
REPO_NAME="droidian-beryllium-repo"
REPO_DESC="APT repository for Droidian packages (Xiaomi Poco F1)"

# Check if repo exists
if gh repo view "${REPO_NAME}" &> /dev/null; then
    print_msg "Repository already exists!"
else
    gh repo create "${REPO_NAME}" --public --description "${REPO_DESC}"
    print_msg "Repository created: ${REPO_NAME}"
fi

print_step "2. Cloning repository..."
REPO_DIR="${HOME}/droidian-beryllium-repo"
if [ -d "${REPO_DIR}" ]; then
    print_msg "Repository already cloned, pulling latest..."
    cd "${REPO_DIR}"
    git pull
else
    gh repo clone "${REPO_NAME}" "${REPO_DIR}"
    cd "${REPO_DIR}"
fi

print_step "3. Setting up repository structure..."
mkdir -p dists/stable/main/binary-arm64
mkdir -p pool/main
mkdir -p .github/workflows

print_step "4. Creating GitHub Actions workflow..."
cat > .github/workflows/main.yml << 'WORKFLOW_EOF'
name: Update Packages Repository

on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - 'pool/*.deb'

jobs:
  update-repo:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - name: Import GPG key and setup gpg
        env:
          GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
        run: |
          echo "$GPG_PRIVATE_KEY" | gpg --import --batch
          echo "allow-preset-passphrase" > ~/.gnupg/gpg-agent.conf
          echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf
          echo "no-tty" >> ~/.gnupg/gpg.conf
          gpg-connect-agent reloadagent /bye

      - name: Generate Packages and Release files
        env:
          GPG_TTY: $(tty)
          GNUPGHOME: /home/runner/.gnupg
          GPG_KEY_ID: ${{ secrets.GPG_KEY_ID }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
          USER: ${{github.repository_owner}}
          REPO: ${{github.event.repository.name}}
        run: |
          mkdir -p public/dists/stable/main/binary-arm64
          dpkg-scanpackages --arch arm64 pool > public/dists/stable/main/binary-arm64/Packages
          gzip -k -f public/dists/stable/main/binary-arm64/Packages
          
          cd public/dists/stable
          
          cat << EOF > Release
          Origin: https://$USER.github.io/$REPO
          Label: Droidian Poco F1 Repository
          Suite: stable
          Codename: stable
          Version: 1.0
          Architectures: arm64
          Components: main
          Description: Droidian packages for Xiaomi Poco F1 (beryllium)
          EOF
          
          apt-ftparchive release . >> Release
          
          echo "$GPG_PASSPHRASE" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --default-key $GPG_KEY_ID --clearsign -o InRelease Release
          echo "$GPG_PASSPHRASE" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --default-key $GPG_KEY_ID -abs -o Release.gpg Release

      - name: Move pool directory to public
        run: cp -r pool public/

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
          force_orphan: true
WORKFLOW_EOF

print_step "5. Creating README..."
cat > README.md << 'README_EOF'
# Droidian Poco F1 Repository

APT repository for Droidian packages for Xiaomi Poco F1 (beryllium).

## Repository URL

```
deb [signed-by=/usr/share/keyrings/beryllium.gpg] https://YOUR_USERNAME.github.io/droidian-beryllium-repo stable main
```

## Available Packages

- `adaptation-droidian-beryllium` - Device adaptation package
- `linux-image-*` - Custom kernel packages

## Installation

1. Add the repository key:
```bash
wget -qO- https://YOUR_USERNAME.github.io/droidian-beryllium-repo/beryllium.gpg | sudo gpg --dearmor -o /usr/share/keyrings/beryllium.gpg
```

2. Add the repository:
```bash
echo "deb [signed-by=/usr/share/keyrings/beryllium.gpg] https://YOUR_USERNAME.github.io/droidian-beryllium-repo stable main" | sudo tee /etc/apt/sources.list.d/beryllium.list
```

3. Update and install:
```bash
sudo apt update
sudo apt install adaptation-droidian-beryllium
```

## Adding Packages

1. Place `.deb` files in the `pool/` directory
2. Commit and push to `main` branch
3. The repository will be updated automatically

## Community

- [Droidian Telegram](https://t.me/DroidianLinux)
- [Poco F1 Droidian](https://t.me/pocof1droidian)
README_EOF

print_step "6. Initial commit and push..."
git add -A
git commit -m "Initial repository setup"
git push origin main

print_msg ""
print_msg "=========================================="
print_msg "GitHub Repository Setup Complete!"
print_msg "=========================================="
print_msg ""
print_msg "Repository: https://github.com/${GITHUB_USER}/${REPO_NAME}"
print_msg "APT URL: https://${GITHUB_USER}.github.io/${REPO_NAME}"
print_msg ""
print_msg "IMPORTANT: You need to add GitHub secrets:"
print_msg "  1. GPG_KEY_ID - Your GPG key ID"
print_msg "  2. GPG_PRIVATE_KEY - Your GPG private key (gpg --armor --export-secret-keys KEY_ID)"
print_msg "  3. GPG_PASSPHRASE - Your GPG key passphrase"
print_msg ""
print_msg "To add secrets:"
print_msg "  1. Go to repository Settings > Secrets and variables > Actions"
print_msg "  2. Add new repository secrets"
print_msg ""
print_msg "To add packages:"
print_msg "  1. Copy .deb files to pool/ directory"
print_msg "  2. git add . && git commit -m 'Add package' && git push"
print_msg "  3. The repository will be updated automatically"
print_msg ""
print_msg "To use on your device:"
print_msg "  1. Add the GPG key and repository URL to your device"
print_msg "  2. Run: sudo apt update"
print_msg "  3. Run: sudo apt install adaptation-droidian-beryllium"
