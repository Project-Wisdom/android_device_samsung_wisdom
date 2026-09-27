#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from os import path
from extract_utils.file import File
from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)
from extract_utils.makefiles import (
    MakefilesCtx,
    ProductPackagesCtx,
)
from extract_utils.tools import android_root

blob_fixups: blob_fixups_user_type = {
    ('vendor/lib/libwvhidl.so', 'vendor/lib/mediadrm/libwvdrmengine.so'): blob_fixup()
        .add_needed('libcrypto_shim.so'),
    'vendor/lib/hw/audio.primary.exynos7904.so': blob_fixup()
        .add_needed('libshim_audioparams.so')
        .binary_regex_replace(b'str_parms_get_str', b'str_parms_get_mod'),
    'vendor/lib64/hw/hwcomposer.exynos7904.so': blob_fixup()
        .replace_needed('libutils.so', 'libutils-v32.so'),
    ('vendor/lib/libexynosgraphicbuffer.so', 'vendor/lib64/libexynosgraphicbuffer.so'): blob_fixup()
        .add_needed('libshim_graphicsmapper_legacy_lockasync.so'),
    ('vendor/lib/libsensorlistener.so', 'vendor/lib64/libsensorlistener.so'): blob_fixup()
        .add_needed('libshim_sensorndkbridge.so'),
    ('vendor/lib/libhifills.so', 'vendor/lib64/libhifills.so'): blob_fixup()
        .add_needed('libunwindstack.so'),
    (
        'vendor/lib/android.hardware.camera.provider@2.4-legacy.p205.so',
        'vendor/lib/android.hardware.camera.provider@2.5-legacy.p205.so',
        'vendor/lib/camera.device@1.0-impl.p205.so',
        'vendor/lib/camera.device@3.2-impl.p205.so',
        'vendor/lib/camera.device@3.3-impl.p205.so',
        'vendor/lib/camera.device@3.4-impl.p205.so',
        'vendor/lib/camera.device@3.5-impl.p205.so',
        'vendor/lib/vendor.samsung.hardware.camera.provider@4.0.p205.so',
        'vendor/lib64/android.hardware.camera.provider@2.4-legacy.p205.so',
        'vendor/lib64/android.hardware.camera.provider@2.5-legacy.p205.so',
        'vendor/lib64/camera.device@1.0-impl.p205.so',
        'vendor/lib64/camera.device@3.2-impl.p205.so',
        'vendor/lib64/camera.device@3.3-impl.p205.so',
        'vendor/lib64/camera.device@3.4-impl.p205.so',
        'vendor/lib64/camera.device@3.5-impl.p205.so',
        'vendor/lib64/vendor.samsung.hardware.camera.provider@4.0.p205.so',
    ): blob_fixup()
        .fix_soname()
        .replace_needed('android.hardware.camera.provider@2.4-legacy.so', 'android.hardware.camera.provider@2.4-legacy.p205.so')
        .replace_needed('android.hardware.camera.provider@2.5-legacy.so', 'android.hardware.camera.provider@2.5-legacy.p205.so')
        .replace_needed('camera.device@1.0-impl.so', 'camera.device@1.0-impl.p205.so')
        .replace_needed('camera.device@3.2-impl.so', 'camera.device@3.2-impl.p205.so')
        .replace_needed('camera.device@3.3-impl.so', 'camera.device@3.3-impl.p205.so')
        .replace_needed('camera.device@3.4-impl.so', 'camera.device@3.4-impl.p205.so')
        .replace_needed('camera.device@3.5-impl.so', 'camera.device@3.5-impl.p205.so'),
    (
        'vendor/bin/hw/vendor.samsung.hardware.camera.provider@4.0-service',
        'vendor/lib/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so',
        'vendor/lib/vendor.samsung.hardware.camera.provider@4.0-legacy.so',
        'vendor/lib/vendor.samsung.hardware.camera.device@5.0-impl.so',
        'vendor/lib64/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so',
        'vendor/lib64/vendor.samsung.hardware.camera.provider@4.0-legacy.so',
        'vendor/lib64/vendor.samsung.hardware.camera.device@5.0-impl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.camera.provider@2.4-legacy.so', 'android.hardware.camera.provider@2.4-legacy.p205.so')
        .replace_needed('android.hardware.camera.provider@2.5-legacy.so', 'android.hardware.camera.provider@2.5-legacy.p205.so')
        .replace_needed('vendor.samsung.hardware.camera.provider@4.0.so', 'vendor.samsung.hardware.camera.provider@4.0.p205.so')
        .replace_needed('camera.device@1.0-impl.so', 'camera.device@1.0-impl.p205.so')
        .replace_needed('camera.device@3.2-impl.so', 'camera.device@3.2-impl.p205.so')
        .replace_needed('camera.device@3.3-impl.so', 'camera.device@3.3-impl.p205.so')
        .replace_needed('camera.device@3.4-impl.so', 'camera.device@3.4-impl.p205.so')
        .replace_needed('camera.device@3.5-impl.so', 'camera.device@3.5-impl.p205.so'),
    (
        'vendor/bin/hw/rild',
        'vendor/lib/libril-samsung.so',
        'vendor/lib64/libril-samsung.so',
        'vendor/lib64/libsec-ril.so',
        'vendor/lib64/libsec-ril-dsds.so',
    ): blob_fixup()
        .replace_needed('libril.so', 'libril-samsung.so'),
    (
        'vendor/lib/camera.device@3.2-impl.universal7904.so',
        'vendor/lib/camera.device@3.3-impl.universal7904.so',
        'vendor/lib/camera.device@3.4-impl.universal7904.so',
        'vendor/lib/camera.device@3.5-impl.universal7904.so',
    ): blob_fixup()
        .fix_soname(),
}


class PlatformExtractUtilsModule(ExtractUtilsModule):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.vendor_rel_path = 'vendor/samsung/wisdom/platform'
        self.vendor_path = path.join(android_root, self.vendor_rel_path)
        self.vendor_rro_path = path.join(self.vendor_path, 'rro_overlays')


def add_platform_inheritance(ctx: MakefilesCtx, packages_ctx: ProductPackagesCtx):
    ctx.product_mk_out.write(
        '$(call inherit-product, vendor/samsung/wisdom/platform/platform-vendor.mk)\n\n'
    )


wisdom_module = ExtractUtilsModule(
    'wisdom',
    'samsung',
    device_rel_path='device/samsung/wisdom',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    check_elf=False,
)
wisdom_module.proprietary_files[0].add_pre_makefile_generation_fn(add_platform_inheritance)

platform_module = PlatformExtractUtilsModule(
    'platform',
    'samsung',
    device_rel_path='device/samsung/wisdom',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    check_elf=False,
    skip_main_proprietary_file=True,
)
platform_module.add_proprietary_file('proprietary-files-platform.txt')

module = wisdom_module

if __name__ == '__main__':
    utils = ExtractUtils(wisdom_module, [platform_module])
    utils.run()
