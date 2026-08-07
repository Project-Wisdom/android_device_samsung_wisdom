# Samsung Galaxy Tab A 8.0 with S Pen LTE (SM-P205)

Unified device tree for the Samsung Galaxy Tab A 8.0 with S Pen LTE
(`SM-P205`, codename `wisdom`) Android 17 bring-up. The former platform-common
tree is merged into this repository; the only device path is
`device/samsung/wisdom`.

This `android-17` branch is a bring-up baseline. It preserves the latest
LineageOS 23.2 device history and is intended to be ported and validated against
LineageOS 24.0 before release use.

## Sync

```bash
gh auth setup-git
repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs
git clone -b android-17 \
  https://github.com/Project-Wisdom/android_manifest_samsung_wisdom.git \
  .repo/local_manifests
repo sync -c --force-sync --no-clone-bundle --no-tags -j"$(nproc --all)"
```

## Apply Patches

```bash
./patches/samsung/wisdom/apply-patches.sh "$PWD"
```

## Bring-up target

```bash
source build/envsetup.sh
lunch lineage_wisdom-bp4a-userdebug
mka bacon -j"$(nproc --all)"
```

The target name is carried forward from the Android 16 tree; a successful
Android 17 build and boot are not claimed yet.

## Recovery

This device tree uses a validated prebuilt TWRP 12.1 recovery image. The
`recoveryimage` target copies `device/samsung/wisdom/prebuilt/recovery.img` to
`out/target/product/wisdom/recovery.img` instead of rebuilding recovery during a
normal ROM build.

The source and rebuild recipe for this recovery image live in:

```text
https://github.com/xuanyayi/twrp-for-sm-p205
```

The local TWRP build tree is:

```text
/twrp/twrp-12.1
```

To verify the recovery output:

```bash
mka recoveryimage -j"$(nproc --all)"
cmp device/samsung/wisdom/prebuilt/recovery.img out/target/product/wisdom/recovery.img
```

To rebuild the recovery image itself, follow the README in
`/twrp/twrp-12.1/device/samsung/p205`, then replace
`device/samsung/wisdom/prebuilt/recovery.img` only after validating the new
image size, boot behavior, and SHA-256.
