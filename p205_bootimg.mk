# Copyright (C) 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0

# Keep Samsung-compatible boot.img construction, but allow this device to ship
# the recovery image that was validated on real SM-P205 hardware.

ifeq ($(strip $(BOARD_KERNEL_SEPARATED_DT)),true)
ifneq ($(strip $(BOARD_KERNEL_PREBUILT_DT)),true)
ifeq ($(strip $(BUILD_TINY_ANDROID)),true)
include system/tools/dtbtool/Android.mk
endif

ifeq ($(strip $(TARGET_CUSTOM_DTBTOOL)),)
DTBTOOL_NAME := dtbToolLineage
else
DTBTOOL_NAME := $(TARGET_CUSTOM_DTBTOOL)
endif

DTBTOOL := $(HOST_OUT_EXECUTABLES)/$(DTBTOOL_NAME)$(HOST_EXECUTABLE_SUFFIX)

INSTALLED_DTIMAGE_TARGET := $(PRODUCT_OUT)/dt.img

ifeq ($(strip $(TARGET_CUSTOM_DTBTOOL)),)
possible_dtb_dirs = $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/
else
possible_dtb_dirs = $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/dts/exynos/ $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/dts/ $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/
endif

define build-dtimage-target
    $(call pretty,"Target dt image: $@")
    $(hide) for dir in $(possible_dtb_dirs); do \
        if [ -d "$$dir" ]; then \
            dtb_dir="$$dir"; \
            break; \
        fi; \
    done; \
    $(DTBTOOL) $(BOARD_DTBTOOL_ARGS) -o $@ -s $(BOARD_KERNEL_PAGESIZE) -p $(KERNEL_OUT)/scripts/dtc/ "$$dtb_dir";
    $(hide) chmod a+r $@
endef

$(INSTALLED_DTIMAGE_TARGET): $(DTBTOOL) $(INSTALLED_KERNEL_TARGET)
	$(build-dtimage-target)
	@echo "Made DT image: $@"

.PHONY: dtimage
dtimage: $(INSTALLED_DTIMAGE_TARGET)

endif
endif

ifeq ($(strip $(TARGET_NEEDS_LOKI)),true)
LOKI_TOOL := loki_tool
else
LOKI_TOOL :=
TARGET_LOKI_ABOOT_IMAGE :=
endif

$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_FILES) $(BOOTIMAGE_EXTRA_DEPS) $(INSTALLED_KERNEL_TARGET)
	$(call pretty,"Target boot image: $@")
	$(hide) $(MKBOOTIMG) --kernel $(call bootimage-to-kernel,$(1)) $(INTERNAL_BOOTIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(hide) python3 -c 'import struct,sys; f=open(sys.argv[1],"r+b"); assert f.read(8)==b"ANDROID!"; f.seek(24); assert struct.unpack("<I",f.read(4))[0]==0; f.seek(40); assert struct.unpack("<I",f.read(4))[0]==1; f.seek(28); f.write(struct.pack("<I",int(sys.argv[2],0))); f.close()' $@ $(P205_BOOTIMAGE_EMPTY_SECOND_ADDR)
	$(hide) echo -n "SEANDROIDENFORCE" >> $@
ifeq ($(strip $(TARGET_NEEDS_LOKI)),true)
	$(hide) $(LOKI_TOOL) patch boot $(TARGET_LOKI_ABOOT_IMAGE) $@ $@.lok
	$(hide) cp $@.lok $@ || true
endif
	$(hide) $(call assert-max-image-size,$@,$(BOARD_BOOTIMAGE_PARTITION_SIZE),raw)
	@echo "Made boot image: $@"

ifndef BOARD_RECOVERY_MKBOOTIMG_ARGS
BOARD_RECOVERY_MKBOOTIMG_ARGS := $(BOARD_MKBOOTIMG_ARGS)
endif

ifneq ($(strip $(BOARD_PREBUILT_RECOVERYIMAGE)),)
$(INSTALLED_RECOVERYIMAGE_TARGET): $(BOARD_PREBUILT_RECOVERYIMAGE) $(recovery_ramdisk) $(RECOVERYIMAGE_EXTRA_DEPS)
	@echo "----- Installing prebuilt recovery image ------"
	$(hide) mkdir -p $(dir $@)
	$(hide) cp $(BOARD_PREBUILT_RECOVERYIMAGE) $@
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE),raw)
	@echo "Installed prebuilt recovery image: $@"
else
$(INSTALLED_RECOVERYIMAGE_TARGET): $(MKBOOTIMG) $(recovery_ramdisk) $(recovery_kernel) $(RECOVERYIMAGE_EXTRA_DEPS)
	@echo "----- Making recovery image ------"
	$(hide) $(MKBOOTIMG) $(INTERNAL_RECOVERYIMAGE_ARGS) $(INTERNAL_MKBOOTIMG_VERSION_ARGS) $(BOARD_RECOVERY_MKBOOTIMG_ARGS) --output $@
	$(hide) python3 -c 'import struct,sys; f=open(sys.argv[1],"r+b"); assert f.read(8)==b"ANDROID!"; f.seek(24); assert struct.unpack("<I",f.read(4))[0]==0; f.seek(40); assert struct.unpack("<I",f.read(4))[0]==1; f.seek(28); f.write(struct.pack("<I",int(sys.argv[2],0))); f.close()' $@ $(P205_BOOTIMAGE_EMPTY_SECOND_ADDR)
	$(hide) echo -n "SEANDROIDENFORCE" >> $@
ifeq ($(strip $(TARGET_NEEDS_LOKI)),true)
	$(hide) $(LOKI_TOOL) patch recovery $(TARGET_LOKI_ABOOT_IMAGE) $@ $@.lok
	$(hide) cp $@.lok $@ || true
endif
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE),raw)
	@echo "Made recovery image: $@"
endif
