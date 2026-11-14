# ZamarteOS Recovery — Fairphone 4

This is a separate recovery build track for the Fairphone 4 (FP4, codename `FP4`).
The first prototype uses the existing Fairphone 4 TeamWin device tree maintained by
[z3ntu](https://github.com/z3ntu/android_device_fairphone_FP4), branch `android-11`,
with the TWRP 11 build manifest.

## What this does

- Builds a recovery image in GitHub Actions.
- Keeps recovery development separate from ZamarteOS Pure and Hybrid OS branches.
- Publishes the image only as a CI artifact for inspection and controlled testing.
- Does not run fastboot, ADB, flashing, partition erasure, or release publishing.

## Build

Open **Actions → ZamarteOS Recovery FP4 — build only → Run workflow**.
The workflow synchronizes the TWRP 11 sources, adds the FP4 device tree, builds
`twrp_FP4-eng` / `recoveryimage`, checks that the image is no larger than the
documented 96 MiB recovery partition, and uploads the image plus SHA-256 checksum.

The build requires a large runner workspace and can fail because upstream Android/TWRP
dependencies or runner limits change. A green workflow means only that the recovery
image compiled and passed the size check; it does not prove that touch, decryption,
backup/restore, USB, or booting works on a physical FP4.

## Known device limitations

- TeamWin's FP4 page documents AVB and dynamic partitions. Do not disable AVB or flash
  anything as part of this build workflow.
- The FP4 community thread documents that encrypted `/data` is not supported by the
  older recovery port. Therefore, do not assume that personal files can be backed up
  from an encrypted installation.
- The image uses a TWRP base and will show TWRP/Android-recovery internals in this
  prototype. This is a maintenance environment, not the normal ZamarteOS user interface.
  ZamarteOS branding/custom UI can be considered only after a successful device test.

## Safety

**Nothing here flashes the phone.** First test, if approved later, should be a temporary
`fastboot boot recovery.img` session rather than writing a partition. Do not use this
artifact until its checksum, image size, boot behavior, touch, storage visibility, and
recovery partition layout have been checked against the exact FP4 firmware currently
installed on the device.

## Upstream sources

- Device tree: https://github.com/z3ntu/android_device_fairphone_FP4/tree/android-11
- Build instructions: https://github.com/z3ntu/android_device_fairphone_FP4
- TWRP FP4 support and partition notes: https://twrp.me/fairphone/fairphone4.html
- TWRP manifest: https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp
