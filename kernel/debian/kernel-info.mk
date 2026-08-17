# Kernel configuration for Xiaomi Poco F1 (beryllium)
# Based on SDM845/Qualcomm Snapdragon 845

# Kernel version
KERNEL_BASE_VERSION=4.9.337

# Device configuration
KERNEL_DEFCONFIG=vendor/beryllium_defconfig
KERNEL_ARCH=arm64
DEB_BUILD_FOR=arm64

# Build settings
BUILD_CC=clang
BUILD_PATH=/usr/lib/llvm-android-12.0-r416183b/bin
DEB_TOOLCHAIN=clang-android-12.0-r416183b

# Build target
KERNEL_BUILD_TARGET=Image.gz-dtb

# DTB settings (SDM845)
KERNEL_IMAGE_WITH_DTB=1
KERNEL_IMAGE_DTB=arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium.dtb

# DTBO settings
KERNEL_IMAGE_WITH_DTB_OVERLAY=1
KERNEL_IMAGE_DTB_OVERLAY=arch/arm64/boot/dts/qcom/sdm845-overlay.dtbo

# Boot image settings (extract from stock boot.img using unpackbootimg)
KERNEL_BOOTIMAGE_CMDLINE="console=tty0 androidboot.console=tty0 androidboot.hardware=qcom androidboot.bootdevice=7884000.ufshc androidboot.selinux=permissive droidian.lvm.prefer"
KERNEL_BOOTIMAGE_PAGE_SIZE=4096
KERNEL_BOOTIMAGE_BASE_OFFSET=0x00000000
KERNEL_BOOTIMAGE_KERNEL_OFFSET=0x00008000
KERNEL_BOOTIMAGE_INITRAMFS_OFFSET=0x01000000
KERNEL_BOOTIMAGE_SECONDIMAGE_OFFSET=0x00f00000
KERNEL_BOOTIMAGE_TAGS_OFFSET=0x00000100
KERNEL_BOOTIMAGE_DTB_OFFSET=0x00000000

# Boot image header version (Android 9 = 1)
KERNEL_BOOTIMAGE_VERSION=1

# Flash settings (for OTA updates)
FLASH_ENABLED=1
FLASH_IS_LEGACY_DEVICE=0
FLASH_INFO_MANUFACTURER=Xiaomi
FLASH_INFO_MODEL=Poco F1
FLASH_INFO_CPU=Qualcomm Technologies, Inc SDM845

# Samsung device flag (not applicable)
DEVICE_VBMETA_IS_SAMSUNG=0

# Use defconfig fragments
KERNEL_CONFIG_USE_FRAGMENTS=1
