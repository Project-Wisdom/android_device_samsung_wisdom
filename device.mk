DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Basic hardware bring-up defaults. This must be set before inheriting the
# platform/vendor products because they gate camera packages on this variable.
TARGET_ENABLE_CAMERA_BRINGUP ?= true

LINEAGE_SKIP_CUSTOM_LOCALES := true

PRODUCT_SHIPPING_API_LEVEL := 28
PRODUCT_USE_DYNAMIC_PARTITIONS := false

# Avoid .capex decompression through /data/apex while the Android 16 data-label
# path is still unstable on the 4.4.177 kernel.
PRODUCT_COMPRESSED_APEX := false

# Release diagnostics. Keep larger log buffers for field debugging, but do not
# force insecure or always-on ADB in normal Android. Lineage common properties
# keep ADB authentication enabled for non-eng builds, and users can opt in from
# Developer options when they need host debugging.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.logd.size=8M \
    ro.logd.size=8M \
    persist.bluetooth.enablenewavrcp=false \
    ro.fastbootd.available=true \
    ro.product_ship=true

PRODUCT_VENDOR_PROPERTIES += \
    ro.recovery.usb.vid=04E8 \
    ro.recovery.usb.adb.pid=685D \
    ro.recovery.usb.fastboot.pid=685D

# Inherit the unified wisdom platform configuration.
$(call inherit-product, device/samsung/wisdom/platform.mk)

$(call inherit-product, vendor/samsung/wisdom/wisdom-vendor.mk)

# Samsung's RIL and carrier-feature blobs look up OMC data under /product/omc
# for CSC/network policy, including legacy CS fallback behavior. The OMC
# cscfeature XML files are Samsung-encoded, so they are installed as prebuilt
# modules instead of PRODUCT_COPY_FILES to avoid host xmllint validation.
include vendor/samsung/wisdom/omc-packages.mk

PRODUCT_PRODUCT_PROPERTIES += \
    ro.omc.build.version=P205OLM6CWA2 \
    ro.omc.build.id=61127026 \
    ro.omc.changetype=NONE \
    ro.simbased.changetype=NONE \
    ro.omc.disabler=FALSE

# P205 stock camera provider uses Samsung's prebuilt camera.device/provider
# legacy implementations. Do not install AOSP stubs with the same stems.
PRODUCT_PACKAGES := $(filter-out \
    android.hardware.camera.provider@2.4-legacy \
    android.hardware.camera.provider@2.5-legacy \
    camera.device@1.0-impl \
    camera.device@3.2-impl \
    camera.device@3.3-impl \
    camera.device@3.4-impl \
    camera.device@3.5-impl, \
    $(PRODUCT_PACKAGES))

# Bootable bring-up: use the generated Samsung radio HIDL interface libraries
# that Lineage-side RIL helpers link against, and avoid installing proprietary
# prebuilts with the same vendor/lib stems.
PRODUCT_PACKAGES := $(filter-out \
    vendor.samsung.hardware.radio@2.0-vendorblob \
    vendor.samsung.hardware.radio@2.1-vendorblob, \
    $(PRODUCT_PACKAGES))

# Prefer the maintained samsung_slsi-linaro media/gralloc stack over legacy
# proprietary OMX/gralloc blobs with the same module names.
PRODUCT_PACKAGES := $(filter-out \
    gralloc.exynos7904 \
    libExynosOMX_Core \
    libExynosOMX_Resourcemanager \
    libOMX.Exynos.AVC.Decoder \
    libOMX.Exynos.AVC.Encoder \
    libOMX.Exynos.HEVC.Decoder \
    libOMX.Exynos.HEVC.Encoder \
    libOMX.Exynos.MPEG4.Decoder \
    libOMX.Exynos.MPEG4.Encoder \
    libOMX.Exynos.VP8.Decoder \
    libOMX.Exynos.VP8.Encoder \
    libOMX.Exynos.VP9.Decoder \
    libOMX.Exynos.WMV.Decoder, \
    $(PRODUCT_PACKAGES))

PRODUCT_PACKAGES += \
    gralloc.universal7904 \
    libExynosOMX_Core \
    libExynosOMX_Resourcemanager \
    libOMX.Exynos.AVC.Decoder \
    libOMX.Exynos.AVC.Encoder \
    libOMX.Exynos.HEVC.Decoder \
    libOMX.Exynos.HEVC.Encoder \
    libOMX.Exynos.MPEG4.Decoder \
    libOMX.Exynos.MPEG4.Encoder \
    libOMX.Exynos.VP8.Decoder \
    libOMX.Exynos.VP8.Encoder \
    libOMX.Exynos.VP9.Decoder \
    libOMX.Exynos.WMV.Decoder

PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.multisim.simslotcount=1 \
    ro.vendor.radio.voice_capable=1 \
    ro.vendor.telephony.force_legacy_voice_capability=1

# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-service \
    android.hardware.keymaster@3.0-impl \
    libkeymaster3device

# Rootdir
PRODUCT_PACKAGES += \
	fstab.exynos7904 \
	init.target.rc \
	init.baseband.rc

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# Navigation bar mode overlays. The 2-button overlay is inherited from the
# Lineage tablet config and is harmless to keep for now.
PRODUCT_PACKAGES += \
    Dialer \
    NavigationBarMode3ButtonOverlay \
    NavigationBarModeGesturalOverlay \
    TransparentNavigationBarOverlay \
    PhhImsFrameworkOverlay \
    framework_compatibility_matrix.p205_kernel_2.xml
