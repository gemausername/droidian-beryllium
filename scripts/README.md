# Droidian Poco F1 Build Scripts

This directory contains scripts to build and install Droidian for Xiaomi Poco F1 (beryllium).

## Prerequisites

- Ubuntu/Debian-based host system
- Docker installed
- Android SDK platform-tools (adb, fastboot)
- GPG key for package signing

## Quick Start

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Build everything (interactive)
./scripts/build-all.sh --all

# Or build individual components:
./scripts/build-all.sh --gpg        # Setup GPG key first
./scripts/build-all.sh --kernel     # Build kernel
./scripts/build-all.sh --adaptation # Build adaptation package
./scripts/build-all.sh --rootfs     # Build rootfs
```

## Scripts Overview

| Script | Description |
|--------|-------------|
| `build-all.sh` | Master build script |
| `setup-gpg.sh` | Generate GPG key for signing |
| `build-kernel.sh` | Build kernel package |
| `build-adaptation.sh` | Build adaptation package |
| `setup-repository.sh` | Setup local APT repository |
| `install-to-device.sh` | Install Droidian on device |
| `setup-github-repo.sh` | Setup GitHub Pages repository |

## Build Order

1. **Setup GPG** - `./scripts/build-all.sh --gpg`
2. **Build Kernel** - `./scripts/build-all.sh --kernel`
3. **Build Adaptation** - `./scripts/build-all.sh --adaptation`
4. **Build Rootfs** - `./scripts/build-all.sh --rootfs`
5. **Setup Repository** - `./scripts/build-all.sh --repo`
6. **Install to Device** - `./scripts/build-all.sh --install`

## Output Files

After building, you'll find:

```
output/
├── adaptation-droidian-beryllium_1.0_arm64.deb
├── linux-image-*.deb
├── linux-bootimage-*.deb
└── droidian.img
```

## Troubleshooting

### Docker Issues

```bash
# Reset Docker
docker system prune -a

# Restart Docker
sudo systemctl restart docker
```

### Build Failures

1. Check logs in the terminal output
2. Ensure all dependencies are installed
3. Verify GPG key is set up correctly
4. Check Docker is running

### Device Not Detected

```bash
# Check USB connection
lsusb

# Restart ADB server
adb kill-server
adb start-server

# Check fastboot
sudo fastboot devices
```

## Resources

- [Droidian Documentation](https://devices.droidian.org)
- [Poco F1 Community Guide](https://github.com/thomashastings/droidian-beryllium-guide)
- [Telegram Support](https://t.me/pocof1droidian)
