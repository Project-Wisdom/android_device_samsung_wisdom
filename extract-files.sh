#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

export DEVICE=wisdom
export VENDOR=samsung

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d ${MY_DIR} ]]; then MY_DIR="${PWD}"; fi

LINEAGE_ROOT="${MY_DIR}"/../../..

HELPER="${LINEAGE_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
	echo "Unable to find helper script at ${HELPER}"
	exit 1
fi
source "${HELPER}"

function blob_fixup {
	case "$1" in
	vendor/lib*/libhifills.so)
		grep -q libunwindstack.so "$2" || "$PATCHELF" --add-needed "libunwindstack.so" "$2"
		;;
	vendor/lib*/hw/camera.vendor.exynos7904.so)
		"$PATCHELF" --replace-needed "libcamera_client.so" "libcamera_metadata_helper.so" "$2"
		"$PATCHELF" --replace-needed "libgui.so" "libgui_vendor.so" "$2"
		;;
	vendor/lib*/libexynoscamera.so | vendor/lib*/libexynoscamera3.so)
		"$PATCHELF" --remove-needed "libcamera_client.so" "$2"
		"$PATCHELF" --remove-needed "libgui.so" "$2"
		;;
	vendor/lib*/libsensorlistener.so)
		grep -q libshim_sensorndkbridge.so "$2" || "$PATCHELF" --add-needed "libshim_sensorndkbridge.so" "$2"
		;;
	vendor/lib*/android.hardware.camera.provider@2.*-legacy.p205.so | \
	vendor/lib*/camera.device@*-impl.p205.so | \
	vendor/lib*/vendor.samsung.hardware.camera.provider@4.0.p205.so)
		"$PATCHELF" --set-soname "$(basename "$2")" "$2"
		if [ "${DEVICE}" = "wisdom" ]; then
			"$PATCHELF" --replace-needed \
				"android.hardware.camera.provider@2.4-legacy.so" \
				"android.hardware.camera.provider@2.4-legacy.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"android.hardware.camera.provider@2.5-legacy.so" \
				"android.hardware.camera.provider@2.5-legacy.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@1.0-impl.so" \
				"camera.device@1.0-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.2-impl.so" \
				"camera.device@3.2-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.3-impl.so" \
				"camera.device@3.3-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.4-impl.so" \
				"camera.device@3.4-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.5-impl.so" \
				"camera.device@3.5-impl.p205.so" "$2"
		fi
		;;
	vendor/bin/hw/vendor.samsung.hardware.camera.provider@4.0-service | \
	vendor/lib*/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so | \
	vendor/lib*/vendor.samsung.hardware.camera.provider@4.0-legacy.so | \
	vendor/lib*/vendor.samsung.hardware.camera.device@5.0-impl.so)
		if [ "${DEVICE}" = "wisdom" ]; then
			"$PATCHELF" --replace-needed \
				"android.hardware.camera.provider@2.4-legacy.so" \
				"android.hardware.camera.provider@2.4-legacy.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"android.hardware.camera.provider@2.5-legacy.so" \
				"android.hardware.camera.provider@2.5-legacy.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"vendor.samsung.hardware.camera.provider@4.0.so" \
				"vendor.samsung.hardware.camera.provider@4.0.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@1.0-impl.so" \
				"camera.device@1.0-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.2-impl.so" \
				"camera.device@3.2-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.3-impl.so" \
				"camera.device@3.3-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.4-impl.so" \
				"camera.device@3.4-impl.p205.so" "$2"
			"$PATCHELF" --replace-needed \
				"camera.device@3.5-impl.so" \
				"camera.device@3.5-impl.p205.so" "$2"
		fi
		;;
	vendor/bin/hw/rild | vendor/lib*/libsec-ril*.so)
		"$PATCHELF" --replace-needed libril.so libril-samsung.so "$2"
		;;
	vendor/lib*/camera.device@*-impl.universal7904.so)
		"$PATCHELF" --set-soname "$(basename "$2")" "$2"
		;;
	vendor/lib/hw/audio.primary.exynos7904.so)
		grep -q libshim_audioparams.so "$2" || "$PATCHELF" --add-needed libshim_audioparams.so "$2"
		sed -i 's/str_parms_get_str/str_parms_get_mod/g' "$2"
		;;
	vendor/lib64/hw/hwcomposer.exynos7904.so)
		"$PATCHELF" --replace-needed "libutils.so" "libutils-v32.so" "$2"
		;;
	esac
}

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
	case "${1}" in
	-n | --no-cleanup)
		CLEAN_VENDOR=false
		;;
	-k | --kang)
		KANG="--kang"
		;;
	-s | --section)
		SECTION="${2}"
		shift
		CLEAN_VENDOR=false
		;;
	*)
		SRC="${1}"
		;;
	esac
	shift
done

if [ -z "${SRC}" ]; then
	SRC="adb"
fi

# Extract the unified wisdom blob list into one vendor repository.
setup_vendor "${DEVICE}" "${VENDOR}" "${LINEAGE_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
	"${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
