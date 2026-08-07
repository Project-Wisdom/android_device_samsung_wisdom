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

INITIAL_COPYRIGHT_YEAR=2018

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d ${MY_DIR} ]]; then MY_DIR="${PWD}"; fi

LINEAGE_ROOT="${MY_DIR}/../../.."

HELPER="${LINEAGE_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
	echo "Unable to find helper script at ${HELPER}"
	exit 1
fi
source "${HELPER}"

# Initialize the helper for the unified wisdom vendor tree
setup_vendor "${DEVICE}" "${VENDOR}" "${LINEAGE_ROOT}" false

# Copyright headers and guards
write_headers "p205"

# Generate the unified wisdom blob makefiles
write_makefiles "${MY_DIR}/proprietary-files.txt" true

# Finish
write_footers
