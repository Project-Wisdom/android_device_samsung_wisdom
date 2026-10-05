# Copyright (C) 2018 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

# The SM-P205 product partition is only 416 MiB. Avoid full_base_telephony.mk
# because it pulls large generic /product apps that do not fit the real device
# layout. Keep the system/vendor pieces required for telephony bring-up, and
# only include the small product base plus WebView.
$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_system.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_system_ext.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_vendor.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_system.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_system_ext.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/telephony_vendor.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/media_product.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/non_ab_device.mk)

# Inherit device configuration
$(call inherit-product, device/samsung/wisdom/device.mk)

# Keep media frontends installed. Aperture is Lineage's maintained camera
# frontend and is already part of the common full mobile set, but this minimal
# product does not inherit that optional app suite.
PRODUCT_PACKAGES += \
    Aperture \
    FlipFlap \
    FlipFlapOverlay \
    Gallery2 \
    PhotoTable \
    Profiles

# Restore the standard Android language set; this target does not inherit
# full_base.mk because the product partition is small.
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# Wisdom's initial DerpFest flavor is vanilla and does not use blur. These
# selectors must be set before common_mini_tablet imports DerpFest config.
WITH_GMS := false
WITH_GMS_COMMS_SUITE := false
TARGET_SUPPORTS_BLUR := false
TARGET_INCLUDE_ACCORD := false
TARGET_INCLUDE_FOSSIFY_GALLERY := true
TARGET_INCLUDE_CUSTOM_FONTS := false
TARGET_FAKE_ENCRYPTION := false
DERP_BOOTANIMATION := default
DERP_BOOTANIMATION_DARK_DEFAULT := true

# Linux 4.4 on Exynos 7904 does not support userfaultfd(2) / MREMAP_DONTUNMAP.
# Disable UFFD GC so dexpreopt compiles OAT artifacts with Concurrent Copying (CC)
# read barriers matching the runtime kernel capability.
PRODUCT_ENABLE_UFFD_GC := false

## Inherit DerpFest's common mini-tablet base without the full optional app suite.
$(call inherit-product, vendor/lineage/config/common_mini_tablet.mk)

# DerpFest's common product adds Updater unconditionally. This unofficial
# wisdom build has no OTA update service, so keep the client out of the image.
PRODUCT_PACKAGES := $(filter-out Updater,$(PRODUCT_PACKAGES))

# Keep Settings search available while staying on the mini package set.
PRODUCT_PACKAGES += \
    SettingsIntelligence

# Final package pruning after Lineage common inheritance. The P205 camera stack
# must use Samsung/P205 prebuilt implementations, not AOSP generic stubs.
PRODUCT_PACKAGES := $(filter-out \
    android.hardware.camera.provider@2.4-legacy \
    android.hardware.camera.provider@2.5-legacy \
    camera.device@1.0-impl \
    camera.device@3.2-impl \
    camera.device@3.3-impl \
    camera.device@3.4-impl \
    camera.device@3.5-impl, \
    $(PRODUCT_PACKAGES))

# DerpFest's breakfast helper resolves a device codename to lineage_<device>.
# Keep this product prefix for DerpFest build integration; wisdom is the
# canonical device path and p205 remains the hardware/model alias for SM-P205.
PRODUCT_DEVICE := wisdom
PRODUCT_NAME := lineage_wisdom
PRODUCT_MODEL := SM-P205
PRODUCT_BRAND := samsung
PRODUCT_MANUFACTURER := samsung

TARGET_DISABLE_EPPE := true
PRODUCT_CHARACTERISTICS := tablet
