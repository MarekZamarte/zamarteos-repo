# Fairphone 4 audio and telephony integration notes

Status: reference analysis only. This file deliberately does not enable unverified packages or copy Android init/vendor configuration into the Alpine image.

## Primary objective

Working cellular-call audio on Fairphone 4:
- earpiece receive path;
- loudspeaker receive path;
- handset and speaker microphone transmit paths;
- correct call start/stop routing through oFono and PulseAudio;
- normal ringtone/notification audio remains functional.

Call audio is not considered supported until tested on physical FP4 with an incoming call, outgoing call, two-way speech, speakerphone, mute/unmute, and call termination.

## Verified upstream references

- Device tree: https://github.com/mlehtima/android_device_fairphone_FP4/tree/lineage-20
  - `audio/audio_policy_configuration.xml`
  - `audio/mixer_paths_lagoon_fp4.xml`
  - `audio/audio_platform_info_lagoon_fp4.xml`
  - `manifest.xml` (Audio HAL 6.0, Radio HAL 1.5 declarations)
  - `device.mk`
- Sailfish FP4 adaptation: https://github.com/mlehtima/droid-config-fp4
  - `patterns/patterns-sailfish-device-adaptation-fp4.inc`
  - `sparse/etc/ofono/binder.d/fp4.conf`
  - `sparse/etc/pulse/arm_droid_card_custom.pa`
  - `sparse/etc/modules-load.d/fp4.conf`
- Boot integration: https://github.com/mlehtima/droid-hal-img-boot-fp4/tree/devel
- Kernel: https://github.com/mlehtima/android_kernel_fairphone_qcm6490/tree/hybris-21.0

## Important FP4 audio facts from the device mixer configuration

The reference mixer defines device paths including:
- `handset`, `voice-handset`, and `voice-hac`;
- `speaker`, `voice-speaker`, and `voice-speaker-stereo`;
- `handset-mic`, `handset-mic2`, `speaker-mic`, and `voice-speaker-mic`;
- `voice-headphones` and `voice-headset`.

The voice speaker paths select the AW882xx amplifier in Voice mode. The handset receive path selects the receiver amplifier in Rcv mode. These controls are hardware-specific and must not be replaced with generic mixer names.

The audio policy declares call-related endpoints such as Earpiece, Speaker, Telephony Tx and Telephony Rx. The policy is an Android audio-policy input, not a PulseAudio configuration file; it must not be installed as-is into the Linux root filesystem.

## Sailfish/Hybris integration evidence

The upstream Sailfish FP4 adaptation package declares:
- `pulseaudio-modules-droid`
- `pulseaudio-modules-droid-hidl`
- `audiosystem-passthrough-dummy-af`
- `ofono-binder-plugin`
- `ofono-binder-plugin-ext-qti` (VoLTE-related)
- `bluebinder`

Its PulseAudio custom card fragment loads `module-droid-card`. Its oFono binder configuration sets `radioInterface = 1.5`.

These package names and settings are evidence for the Sailfish RPM/Hybris stack. They are **not automatically valid Alpine APK package names** and must not be added to an APKBUILD as dependencies without locating compatible Alpine packages/build recipes.

## Integration plan for ZamarteOS

1. **Identify actual build stack and package recipes**
   - Confirm the rootfs base, package manager, architecture, init system and existing Hybris version.
   - Inventory available packages/recipes for libhybris, Android binder/HIDL, PulseAudio Droid modules and oFono binder.
   - Do not mix RPM/Sailfish package names with Alpine APK dependencies.

2. **Kernel and vendor compatibility**
   - Keep the FP4 kernel branch and vendor blobs aligned with the Hybris Android base expected by the selected userspace.
   - Verify required audio kernel drivers/codecs and AW882xx amplifier support.
   - Do not change kernel or boot image until the current known-good boot path is preserved.

3. **Audio HAL bridge**
   - Ensure the matching vendor `audio.primary.lito.so` and its dependent vendor libraries are present in the Hybris vendor environment.
   - Ensure the matching HIDL audio service and passthrough bridge can start.
   - Use the FP4 mixer and platform configuration through the supported Droid/HIDL bridge; do not feed Android XML to PulseAudio directly.

4. **PulseAudio routing**
   - Load the compatible Droid card modules only after the HIDL bridge and vendor HAL are verified.
   - Validate card/profile/port names exposed on this device before adding forced profile selections.
   - Confirm call entry/exit hooks route voice uplink/downlink and restore the normal media profile.

5. **Telephony**
   - Verify modem detection and oFono binder plugin startup before changing Radio HAL settings.
   - Use the FP4 binder setting `radioInterface = 1.5` only when the installed plugin supports that interface.
   - Confirm SIM registration, incoming/outgoing calls and call-state transitions separately from audio.

6. **Boot image**
   - Compare the existing ZamarteOS boot/initrd process with the Sailfish FP4 boot integration.
   - Avoid importing unrelated boot scripts or replacing a working image without a successful build and recovery path.

## Required checks before building

- Package names resolve in the actual Alpine repositories/build recipes.
- Vendor HAL and HIDL service versions match the installed Android vendor image.
- No unresolved shared-library dependencies for audio HAL.
- PulseAudio starts without failing to load Droid/HIDL modules.
- oFono binder plugin starts and exposes the FP4 modem.
- XML reference files parse correctly if used as packaged data.
- Existing boot and rootfs integrity checks remain green.

## Physical-device acceptance test

1. Boot to UI and verify normal media playback.
2. Verify ringtone and incoming-call notification.
3. Receive a cellular call: earpiece output and handset microphone in both directions.
4. During the call, switch to speakerphone: loudspeaker output and speaker microphone in both directions.
5. Toggle mute, volume and route; verify no one-way audio.
6. End the call; verify audio returns to normal media routing.
7. Place an outgoing call and repeat the same tests.
8. Reboot and repeat at least one incoming and one outgoing call.

## Current status

- FP4 reference audio configuration inspected.
- Sailfish FP4 package-pattern references inspected.
- ZamarteOS repository currently exposes a small Alpine APK repository under `v26.06/aarch64`; this repository alone does not contain the build recipes or device adaptation source needed to wire the above components.
- No audio/telephony packages have been blindly added.
- No claim is made that call audio works yet.
