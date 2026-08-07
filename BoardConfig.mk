DEVICE_PATH := device/samsung/wisdom

# Basic hardware bring-up defaults. Keep this overridable for rescue builds
# that need the old no-camera package shape.
TARGET_ENABLE_CAMERA_BRINGUP ?= true

TARGET_OTA_ASSERT_DEVICE := p205,wisdom,wisdomx

# SM-P205 uses a non-A/B partition layout. Keep OTA packaging on the
# non-A/B updater path so target-files does not require META/ab_partitions.txt.
AB_OTA_UPDATER := false
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)

# Kernel
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_KERNEL_CONFIG := wisdom_defconfig
BOARD_CUSTOM_BOOTIMG := true
BOARD_CUSTOM_BOOTIMG_MK := $(DEVICE_PATH)/p205_bootimg.mk
TARGET_CUSTOM_DTBTOOL := dtbhtoolExynos
BOARD_BOOT_HEADER_VERSION := 1
BOARD_KERNEL_CMDLINE := androidboot.hardware=exynos7904 androidboot.selinux=permissive firmware_class.path=/vendor/firmware

# Keep the known-booting 4.4.177 p205 kernel until the 4.4.302 source kernel
# is boot-stable on this tablet.

# Use the known-booting SM-P205 recovery DTBO as a base until the source kernel
# is stable, but keep its speaker route aligned with the runtime
# `tfa98xx-aif-9-34` widget rather than the broken `8-34` route in the stock
# blob.
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/recovery_dtbo
BOARD_PREBUILT_RECOVERY_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/recovery_dtbo

BOARD_ROOT_EXTRA_SYMLINKS := \
    /mnt/vendor/efs:/efs \
    /mnt/vendor/efs:/factory

# Recovery
# This device tree packages a validated prebuilt TWRP 12.1 recovery image for
# SM-P205, instead of rebuilding recovery from the LineageOS source tree.
BOARD_PREBUILT_RECOVERYIMAGE := $(DEVICE_PATH)/prebuilt/recovery.img
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_USES_FULL_RECOVERY_IMAGE := true
BOOTLOADER_MESSAGE_OFFSET := 2048
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := ABGR_8888
BOARD_RECOVERY_IMAGE_PREPARE += \
    grep -q '^ro.adb.secure.recovery=' $(TARGET_RECOVERY_ROOT_OUT)/prop.default || echo 'ro.adb.secure.recovery=0' >> $(TARGET_RECOVERY_ROOT_OUT)/prop.default; \
    grep -q '^service.adb.root=' $(TARGET_RECOVERY_ROOT_OUT)/prop.default || echo 'service.adb.root=1' >> $(TARGET_RECOVERY_ROOT_OUT)/prop.default;

# Prebuilt Recovery Kernel
TARGET_PREBUILT_RECOVERY_KERNEL := $(DEVICE_PATH)/prebuilt/recovery_Image

# Sepolicy
BOARD_SEPOLICY_TEE_FLAVOR := mobicore

# SPL
VENDOR_SECURITY_PATCH := 2023-02-01

# Inherit the unified wisdom platform board flags.
include device/samsung/wisdom/BoardConfigPlatform.mk

# Keep boot image headers aligned with the SM-P205 images that the bootloader
# accepts. The prebuilt TWRP recovery is copied as-is by p205_bootimg.mk.
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --second_offset 0x00f00000 --set_empty_second_addr --tags_offset 0x00000100 --header_version 1 --board SRPSA16A009RU --os_version 12.0.0 --os_patch_level 2099-12
BOARD_RECOVERY_MKBOOTIMG_ARGS := $(BOARD_MKBOOTIMG_ARGS)

# p205-specific partition sizes. Keep these after the platform BoardConfig so
# the platform defaults do not override the real SM-P205 layout.
TARGET_COPY_OUT_PRODUCT := product
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4227858432
BOARD_VENDORIMAGE_PARTITION_SIZE := 570425344
BOARD_PRODUCTIMAGE_PARTITION_SIZE := 436207616
BOARD_CACHEIMAGE_PARTITION_SIZE := 367001600
BOARD_USERDATAIMAGE_PARTITION_SIZE := 25354567680
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 39845888
TARGET_USERIMAGES_USE_F2FS := false

# AVB is disabled for initial bring-up; flash disabled vbmeta separately.
BOARD_AVB_ENABLE := false
BOARD_BUILD_DISABLED_VBMETAIMAGE := true

# VINTF
DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/configs/android.hardware.keymaster@3.0-service.xml \
    $(DEVICE_PATH)/configs/radio_manifest.xml

ifeq ($(TARGET_ENABLE_CAMERA_BRINGUP),true)
DEVICE_MANIFEST_FILE += \
    $(DEVICE_PATH)/configs/camera-provider.xml
endif
