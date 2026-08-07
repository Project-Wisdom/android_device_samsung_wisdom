#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Adapt the LineageOS samsung_slsi-linaro media/graphics stack for Exynos7904.
# The shape follows the maintained Exynos9610/9611 configuration, with the
# kernel and codec capabilities adjusted to the SM-P205 stock 4.4 baseline.

TARGET_LINUX_KERNEL_VERSION := 4.4
# samsung_slsi-linaro has no dedicated exynos7904 graphics platform. Exynos7904
# belongs to the 7885 family, and the maintained HWC/gralloc headers are under
# the exynos7885 profile.
TARGET_SOC_BASE := exynos7885

BOARD_USES_EXYNOS_GRALLOC_VERSION := 3
BOARD_USES_ALIGN_RESTRICTION := true
BOARD_USES_GRALLOC_ION_SYNC := true
BOARD_EXYNOS_S10B_FORMAT_ALIGN := 64
BOARD_USES_EXYNOS_DATASPACE_FEATURE := true

# Samsung OpenMAX Video
BOARD_USE_DMA_BUF := true
BOARD_USE_NON_CACHED_GRAPHICBUFFER := true
BOARD_USE_GSC_RGB_ENCODER := true
BOARD_USE_CSC_HW := false
BOARD_USE_S3D_SUPPORT := false
BOARD_USE_DEINTERLACING_SUPPORT := true
BOARD_USE_HEVCENC_SUPPORT := true
BOARD_USE_HEVC_HWIP := false
BOARD_USE_VP9DEC_SUPPORT := true
BOARD_USE_VP9ENC_SUPPORT := false
BOARD_USE_WFDENC_SUPPORT := false
BOARD_USE_CUSTOM_COMPONENT_SUPPORT := true
BOARD_USE_VIDEO_EXT_FOR_WFD_HDCP := true
BOARD_USE_SINGLE_PLANE_IN_DRM := true
BOARD_USE_WA_ION_BUF_REF := true

# HWComposer config is consumed by the linaro common file. Wisdom still ships
# the known-working exynos7904 composer service, so no linaro HWC package is
# selected from product makefiles yet.
BOARD_USES_EXYNOS_AFBC_FEATURE := true

# SCALER
BOARD_DEFAULT_CSC_HW_SCALER := 4
BOARD_USES_SCALER_M2M1SHOT := true
BOARD_HAS_SCALER_ALIGN_RESTRICTION := true

# Acryl
BOARD_LIBACRYL_DEFAULT_COMPOSITOR := fimg2d_9610
BOARD_LIBACRYL_DEFAULT_SCALER := mscl_9810
BOARD_LIBACRYL_DEFAULT_BLTER := fimg2d_9810_blter

include hardware/samsung_slsi-linaro/config/BoardConfigCommon.mk
