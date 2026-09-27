# Samsung SM-P205 Device Facts

This file records hardware facts for the `wisdom` device tree. The DerpFest 17
product remains named `lineage_wisdom` because DerpFest's `breakfast` helper
resolves device codenames to that prefix; its Android 17.0 build target is
`lineage_wisdom-cp2a-userdebug`. Do not blindly encode every public spec into
Android resources; only use values that affect framework, partition, or HAL
behavior.

## Identity

- Marketing name: Samsung Galaxy Tab A 8.0 with S Pen (2019), LTE
- Model: SM-P205
- DerpFest 17 product/lunch target: `lineage_wisdom` / `lineage_wisdom-cp2a-userdebug`
- Upstream community codename: `wisdom`
- Product/device assert aliases: `p205,wisdom,wisdomx`

## Platform

- SoC: Samsung Exynos 7904 / `universal7904`
- CPU: 2x Cortex-A73 + 6x Cortex-A53, arm64
- GPU: Mali-G71 MP2
- Display: 8.0 inch, 1200 x 1920
- Memory/storage public SKU: 3 GB RAM / 32 GB storage
- Battery: 4200 mAh class
- Factory Android generation: Android 9, so `PRODUCT_SHIPPING_API_LEVEL := 28`
- Official firmware generation used for blobs: Android 11
- Current bring-up baseline assumption: SM-P205 Android 11 stock firmware,
  defaulting to `P205DXU6CVG2` until a dump from the exact target tablet is
  provided and recorded here.
- Kernel/dtbo currently staged in this tree:
  - `device/samsung/wisdom/prebuilt/Image`
  - `device/samsung/wisdom/prebuilt/recovery_dtbo`
  - `device/samsung/wisdom/prebuilt/vbmeta.img`
  `BoardConfig.mk` retains the prebuilt kernel as a rescue fallback, but the
  current diagnostic build selects the source-built 4.4.302 kernel. The prebuilt
  dtbo remains the recovery-compatible base. These files must be replaced
  together from the same selected stock baseline; do not mix a recovery dtbo
  with blobs or firmware from another build.
- Recovery in this device tree is Lineage Recovery. Standalone third-party
  recovery experiments are not the design baseline for `lineage_wisdom` bring-up.
- Current diagnostic bring-up keeps `wisdom_defconfig` and leaves
  `TARGET_FORCE_PREBUILT_KERNEL` unset. The permissive SELinux and panic-to-
  recovery settings are temporary diagnostics; restore enforcing mode and
  validate the p205 DTS before a release build.
- The current boot test deliberately removes the `/data` `fileencryption` option
  from boot, vendor, and recovery fstab files; userdata was formatted with the
  user's authorization. This is a bring-up setting only. Revisit encryption
  before any release build, and preserve the user's IMS/CarrierConfig/OMC tree.
- Bluetooth bring-up is enabled through the Samsung SLSI H4 vendor library and
  `/dev/scsc_h4_0`. The 2026-05-25 pstore logs previously showed
  `com.android.bluetooth` aborting when the HCI service could not start, so
  validate the HCI HAL, feature XML, and profile properties together after each
  build.
- Wi-Fi uses Lineage's legacy HIDL service. The Android 13 1.6 default Wi-Fi
  service crashed in `getLinkLayerStats_1_6()` with the SLSI legacy HAL.
- `wlbtd` and `tfadsp.bin` are expected from the selected SM-P205 Android 11
  stock baseline and are present in the current local blob tree. The TFA
  speaker amplifier firmware is installed to both `/vendor/firmware` and the
  boot/recovery ramdisks under `/lib/firmware` because the kernel requests it
  before vendor is mounted.
- Do not ship `gsi_skip_mount.cfg` in p205 device builds. It skips `/product`
  and `/system_ext`, which made the 2026-05-25 build boot without product
  permissions/overlays and caused SystemUI to crash because
  `lineageglobalactions` was never published.

## Vendor Firmware Hashes

Current p205 camera firmware blobs:

```text
edaf335c151ad2d830db2d48fef302fd5bd3219e142bf58f7045a87097332949  fimc_is_lib.bin
53c169f830176d49e3585c0acec0f68016384d8fd027294f011bd8357bd30ee5  fimc_is_rta.bin
290bcafd2412a77fe451dbcb19099f7a79c249313ccc0d71a1b9ff6db71de85d  setfile_3l6.bin
f710e0c95a37176cfb3e1c9d463aedd8ad2833ab1085cf7a350ee107dff820ad  setfile_4ha.bin
61824aca51a708ed4a880e8a27767d3b85b80613ac12dd1b158319cc2d254433  setfile_5e9.bin
```

The source build fingerprint for these blobs is still unverified. Before
declaring the camera stack stable, re-extract these files from the selected
SM-P205 Android 11 stock firmware and update this section with the exact build
fingerprint and partition image hashes.

## Features

- LTE single-SIM tablet: expose one radio slot in VINTF and one default network entry.
  Keep the default preferred network mode at `LTE/GSM/WCDMA` (`9`) so data can
  register on LTE. Until VoLTE is validated, normal calls use the non-IMS CS
  voice path and request GSM/WCDMA during dialing.
- Wi-Fi 802.11 a/b/g/n/ac, Bluetooth 5.0, GPS/GLONASS/BDS/Galileo.
- Cameras: 8 MP rear, 5 MP front.
- Sensors publicly listed across sources: accelerometer, ambient light, hall,
  proximity. Do not advertise fingerprint, NFC or gyroscope unless verified on
  hardware.
- S Pen / Wacom input is device-defining; do not remove input support while pruning.
- NFC is not part of the SM-P205 public spec and there is no `nfc` partition/HAL in the current bring-up.

## Samsung Feature Porting Notes

The SM-P205 Android 11 user manual lists Samsung features such as S Pen/Air
command, Smart select, Screen write, Live messages, Air view, Screen off memo,
Face recognition, Palm swipe to capture, Daily Board, Dolby Atmos, Eye comfort
shield, Secure Folder, and Samsung Kids. Do not treat this list as a mandate to
ship closed Samsung applications or Knox services in LineageOS.

- Supported through AOSP/Lineage plumbing in this tree:
  - S Pen input and hover are handled by the Wacom `sec_e-pen` input device,
    `sec_e-pen.idc`, and framework/inputflinger stylus handling.
  - Double-tap-to-wake uses the framework `DOUBLE_TAP_TO_WAKE` setting through
    the Power HAL to the Samsung `aot_enable` touchscreen command.
  - Adaptive brightness uses the Samsung light sensor through standard Android
    auto-brightness resources.
  - Eye comfort shield maps to AOSP Night Display. The device overlay enables
    accelerated color transforms and defaults Night Display to a 22:00-06:00
    custom schedule.
  - Flip cover sleep/wake maps the Hall sensor to Android's standard lid switch
    handling. FlipFlap is installed with the device overlay set to the full-screen
    cover style so closing the cover can present a Lineage clock/notification
    surface instead of only blanking the display.
  - Dolby Atmos has the Samsung `libswdap` DAP effect registered against the
    stock blob descriptor UUID. Keep the Lineage Dolby UI disabled until the
    effect parameters and `dax-default.xml` behavior are validated on hardware.
  - Palm swipe to capture is approximated with a framework-level multi-finger
    horizontal gesture that calls Android's screenshot service. The gesture
    thresholds still need runtime validation on the tablet.
  - Screen write is approximated by routing screenshot edit actions to Gallery2
    FilterShow. This gives users an immediate post-screenshot editor without
    shipping Samsung Air command.
  - Multi window and Pop-up view map to Android split-screen and freeform window
    management. The device declares `android.software.freeform_window_management`
    and allows non-resizable activities in multi-window modes to better match the
    stock Samsung tablet behavior.
  - The tablet taskbar is handled by Lineage/Trebuchet's large-screen taskbar,
    which is enabled by default for tablet layouts and provides a practical
    launcher/task-switching entry point for split-screen workflows.
  - Smart View / wireless display maps to Android Wi-Fi Display / Miracast. The
    common framework overlay enables `config_enableWifiDisplay`; the build ships
    Wi-Fi Direct permissions, `wifi.direct.interface=p2p0`, remote-submix audio
    HAL/policy, and the Exynos `video/avc-wfd` encoder. Runtime validation still
    needs a Miracast sink to confirm discovery, connection, audio, latency, and
    protected-video behavior.
  - Daily Board is approximated with Android's screensaver/Dream framework.
    `PhotoTable` is installed and the default dream is the photo-frame mode,
    activated when the tablet sleeps while charging.
- Not implemented by the current AOSP/Lineage feature set:
  - Smart select is intentionally not exposed. The selected-region screenshot
    approximation is not useful enough on this device.
  - Screen off memo is not just generic stylus input. Android 13 in this tree
    does not provide the Android 14 notes role / note-taking intent flow, and
    there is no bundled Samsung Notes-compatible app. A correct implementation
    would need a dedicated lockscreen/offscreen note app plus an explicit S Pen
    removal or button-triggered wake/launch path.
- Do not advertise without a real HAL/service stack:
  - Face recognition requires a working Android face biometrics HAL and enrolled
    template storage; the front camera alone is not sufficient.
  - Secure Folder depends on Samsung Knox/container services.
  - Samsung Kids, PENUP, Samsung Notes, Live messages, and Air command are
    Samsung application/framework features rather than generic hardware
    capabilities.

## Verified Partition Layout

Captured from the target SM-P205:

```text
boot      mmcblk0p15   32768 KiB
recovery  mmcblk0p16   38912 KiB
dtb       mmcblk0p17    8192 KiB
dtbo      mmcblk0p18    8192 KiB
radio     mmcblk0p19   46080 KiB
vbmeta    mmcblk0p22     512 KiB
system    mmcblk0p25 4128768 KiB
vendor    mmcblk0p26  557056 KiB
product   mmcblk0p27  425984 KiB
cache     mmcblk0p28  358400 KiB
userdata  mmcblk0p32 24760320 KiB
```

There is no dedicated `odm` or `system_ext` partition on this device.
