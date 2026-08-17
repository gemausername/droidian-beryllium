# Droidian for Xiaomi Poco F1 (beryllium)

Porting guide and adaptation package for running [Droidian](https://droidian.org) on the Xiaomi Poco F1.

## Multi-Variant Support

This project supports **6 variants** with different desktop environments and panel types:

| Variant | Desktop | Panel | Description |
|---------|---------|-------|-------------|
| `phosh-ebbg` | Phosh | eBBG (Everlight) | Standard panel variant |
| `phosh-tianma` | Phosh | Tianma | Alternative panel |
| `phosh-tianmaft` | Phosh | Tianma + Focaltech | Tianma panel with Focaltech touch |
| `lomiri-ebbg` | Lomiri | eBBG (Everlight) | Ubuntu Touch-like experience |
| `lomiri-tianma` | Lomiri | Tianma | Alternative panel |
| `lomiri-tianmaft` | Lomiri | Tianma + Focaltech | Tianma panel with Focaltech touch |

### Quick Build Commands

```bash
# Build all 6 variants
make all

# Build specific variant
make VARIANT=phosh-ebbg

# Build all Phosh variants
make phosh

# Build all Lomiri variants
make lomiri

# Build all eBBG variants
make ebbg

# Build all Tianma variants
make tianma

# Build all TianmaFT variants
make tianmaft
```

## Device Specifications

| Property | Value |
|----------|-------|
| **Device** | Xiaomi Poco F1 |
| **Codename** | beryllium |
| **SoC** | Qualcomm Snapdragon 845 (SDM845) |
| **CPU** | Octa-core Kryo 385 (4x2.8GHz + 4x1.8GHz) |
| **GPU** | Adreno 630 |
| **RAM** | 6/8GB |
| **Storage** | 64/128/256GB |
| **Android** | 9.0 Pie (API 28) |
| **Architecture** | arm64 |

## Requirements

- Unlocked bootloader
- TWRP recovery installed
- Computer with `adb` and `fastboot` installed
- USB 2.0 port/hub (USB 3.0 can cause issues with Poco F1)
- Backup all your data (phone will be wiped)

## Fastboot Installation (Recommended)

### Prerequisites

- Unlocked bootloader
- Computer with `adb` and `fastboot` installed
- USB cable (USB 2.0 port/hub recommended)
- Download required files (see below)

### Download Links

| File | Download |
|------|----------|
| **Boot image** | [Community builds](https://github.com/Unofficial-droidian-for-pocof1/linux_android_xiaomi_beryllium/releases) |
| **Rootfs** | [Droidian releases](https://github.com/droidian-images/rootfs-api28gsi-all/releases) |
| **Vendor image** | [UBports](https://github.com/ubports-beryllium/artifacts/releases/download/v3/vendor.img) |
| **Android 9 firmware** | [MIUI firmware](https://xiaomifirmwareupdater.com/download/?file=fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip) |

### Flash Steps

#### 1. Boot to Fastboot Mode

```bash
# Power off device completely
# Hold Volume- and Power simultaneously
# Release when vibration is felt
# Device shows fastboot logo

# Or use ADB:
adb reboot bootloader
```

#### 2. Check Device Connection

```bash
fastboot devices
# Should show: XXXXXXXX	fastboot
```

#### 3. Flash Boot Image (Kernel)

```bash
fastboot flash boot boot.img
```

#### 4. Flash Rootfs (Optional - can do via TWRP)

```bash
fastboot flash system droidian-rootfs-arm64.img
```

#### 5. Flash Vendor (Optional)

```bash
fastboot flash vendor vendor.img
```

#### 6. Wipe Data (First Install)

```bash
fastboot -w
```

#### 7. Reboot

```bash
fastboot reboot
```

### Quick Flash Script

```bash
# Run the automated flash script
chmod +x scripts/flash-fastboot.sh
./scripts/flash-fastboot.sh
```

### Post-Install

1. Wait for first boot (3-5 minutes)
2. Default unlock code: `1234`
3. Install adaptation package:
   ```bash
   # Copy .deb to device, then:
   sudo dpkg -i adaptation-droidian-beryllium-<variant>.deb
   sudo reboot
   ```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| **Bootloop** | Boot to TWRP, wipe cache/dalvik, try different boot image |
| **No touch** | Wrong panel variant - try different adaptation package |
| **Black screen** | Check display settings, try different boot image |
| **WiFi not working** | Install firmware: `sudo dpkg -i firmware-*` |
| **No sound** | Check audio config: `alsamixer` |

---

## Quick Installation (Using Pre-built Images - Alternative)

### 1. Download Required Files

- **Droidian rootfs**: `droidian-rootfs` and `droidian-devtools` for arm64 from [Droidian releases](https://github.com/droidian-images/rootfs-api28gsi-all/releases)
- **Boot image**: From [community builds](https://github.com/Unofficial-droidian-for-pocof1/linux_android_xiaomi_beryllium/releases) or [alternative](https://github.com/thomashastings/droidian-beryllium-guide/releases/download/Boot/droidian-boot-beryllium.zip)
- **Vendor image**: From [UBports](https://github.com/ubports-beryllium/artifacts/releases/download/v3/vendor.img)
- **Android 9 firmware**: [Official MIUI firmware](https://xiaomifirmwareupdater.com/download/?file=fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip)

### 2. Install TWRP

```bash
# Boot to fastboot mode
# Press Vol- and Power buttons until phone vibrates

# Check device connection
fastboot devices

# Flash TWRP
fastboot flash recovery twrp-*-beryllium.img
```

### 3. Install Droidian

1. Boot into TWRP (Vol+ and Power buttons)
2. Go to **Wipe** → **Format data** (type `yes`)
3. **IMPORTANT: Reboot into TWRP again**
4. Connect phone to PC via USB
5. Copy all downloaded files to phone storage
6. In TWRP:
   - Install zip: `fw_beryllium_miui_POCOF1Global_9.6.27_6673f8a455_9.0.zip`
   - Install image: `boot.img` → Boot partition
   - Install image: `vendor.img` → Vendor partition
   - Install zip: `droidian-rootfs-api28gsi_arm64_*.zip`
   - Install zip: `droidian-devtools_arm64_*.zip`
7. Reboot to System

**Default unlock code:** `1234`

## Building from Source

### Prerequisites

- Docker installed
- Git
- Internet connection

### 1. Clone Repository

```bash
git clone https://github.com/your-username/droidian-beryllium.git
cd droidian-beryllium
```

### 2. Build Kernel

```bash
# Start Docker container
docker run --rm -v $(pwd)/kernel:/buildd/sources -it quay.io/droidian/build-essential:current-amd64 bash

# Inside Docker container
apt-get install linux-packaging-snippets
cd /buildd/sources
mkdir -p debian/source
cp -v /usr/share/linux-packaging-snippets/kernel-info.mk.example debian/kernel-info.mk
echo "13" > debian/compat
echo "3.0 (native)" > debian/source/format

# Edit kernel-info.mk with your settings
nano debian/kernel-info.mk

# Build kernel
debian/rules debian/control
RELENG_HOST_ARCH="arm64" releng-build-package
```

### 3. Build Adaptation Package

```bash
cd packages/adaptation-droidian-beryllium
dpkg-buildpackage -b -uc -us
```

### 4. Build Rootfs

```bash
cd rootfs
chmod +x build-rootfs.sh
sudo ./build-rootfs.sh
```

## Device-Specific Tweaks

### Bluetooth

```bash
sudo touch /var/lib/bluetooth/board-address
```

### Notch Fix

Edit `~/.config/gtk-3.0/gtk.css`:

```css
.phosh-topbar-clock {
   margin-left: 195px;
}

.phosh-panel-btn > box {
   margin-left: 0px;
   margin-right: 0px;
}

.phosh-power-button {
   margin-right: 50px;
}
```

### Screen Brightness

```bash
# Set brightness (0-2047)
echo 128 > /sys/class/leds/lcd-backlight/brightness
```

### Mobile Data

Mobile data works after setting up the APN. May stop working after calls - toggle mobile data off/on in settings.

### Waydroid

```bash
sudo apt install waydroid -y
sudo waydroid init
sudo waydroid container start
```

After first successful run, hide redundant apps:

```bash
for i in ~/.local/share/applications/waydroid*.desktop; do
    echo 'NoDisplay=true' >> $i
done
```

## Project Structure

```
droidian-beryllium/
├── README.md                    # This file
├── LICENSE                      # GPLv3
├── .github/
│   └── workflows/
│       └── build.yml           # GitHub Actions CI/CD
├── packages/
│   └── adaptation-droidian-beryllium/
│       ├── debian/
│       │   ├── control         # Package metadata
│       │   ├── rules           # Build rules
│       │   ├── compat          # Debhelper compatibility
│       │   ├── source/
│       │   │   └── format      # Package format
│       │   ├── device-info     # Device information
│       │   ├── droid-get-bt-address.sh  # Bluetooth script
│       │   ├── adaptation-droidian-beryllium.brightness.service
│       │   ├── phoc.ini        # Phosh config
│       │   ├── notch-fix.json  # Notch fix
│       │   ├── 70-beryllium.rules  # Udev rules
│       │   └── 10-schedtune.conf   # Schedtune workaround
│       └── sparse/
│           └── usr/lib/adaptation-droidian-beryllium/sources.list.d/
│               └── community-beryllium.list
├── kernel/
│   └── debian/
│       ├── kernel-info.mk      # Kernel build configuration
│       ├── rules               # Kernel build rules
│       ├── compat
│       └── source/format
│   └── droidian/
│       └── sdm845.config       # Droidian kernel config fragment
├── rootfs/
│   ├── build-rootfs.sh         # Rootfs build script
│   └── droidian/
│       └── community_devices.yml
├── scripts/
│   ├── build-all.sh            # Master build script
│   ├── setup-gpg.sh            # GPG key setup
│   ├── build-kernel.sh         # Kernel build script
│   ├── build-adaptation.sh     # Adaptation build script
│   ├── setup-repository.sh     # Local repository setup
│   ├── setup-github-repo.sh    # GitHub Pages setup
│   └── install-to-device.sh    # Device installation
└── output/                     # Build outputs
    ├── adaptation-droidian-beryllium_*.deb
    ├── linux-image-*.deb
    └── droidian.img
```

## Build Scripts

| Script | Description |
|--------|-------------|
| `build-all.sh` | Master build script (builds everything) |
| `setup-gpg.sh` | Generate GPG key for package signing |
| `build-kernel.sh` | Build kernel package |
| `build-adaptation.sh` | Build adaptation package |
| `setup-repository.sh` | Setup local APT repository |
| `setup-github-repo.sh` | Setup GitHub Pages repository |
| `install-to-device.sh` | Install Droidian on device |

## Quick Build Commands

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
./scripts/build-all.sh --repo       # Setup local repository
./scripts/build-all.sh --install    # Install to device
```

## Troubleshooting

### Boot Issues

1. **Stuck at logo**: Check if `systempart=` is in kernel cmdline and remove it
2. **Bootloop**: Try masking problematic systemd services via recovery
3. **No display**: Check if vendor partition is mounted

### SSH Access

If RNDIS doesn't work, connect via WiFi:

```bash
# In TWRP, edit /etc/network/interfaces
auto wlan0
iface wlan0 inet dhcp
  wpa-ssid YOUR_SSID
  wpa-psk YOUR_PASSWORD
```

### Common Fixes

- **Bluetooth**: `sudo touch /var/lib/bluetooth/board-address`
- **Brightness**: Create brightness service
- **Long boot times**: Check `dmesg` and `systemd-analyze`

## Community

- [Droidian Telegram Group](https://t.me/DroidianLinux/)
- [Poco F1 Droidian Group](https://t.me/pocof1droidian)
- [Droidian Documentation](https://devices.droidian.org)

## Credits

- [Droidian Project](https://droidian.org)
- [Joel Selvaraj](https://github.com/joelselvaraj)
- [1petro](https://github.com/1petro)
- [UBports](https://ubuntu-touch.io)
- [Community contributors](https://github.com/thomashastings/droidian-beryllium-guide)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
