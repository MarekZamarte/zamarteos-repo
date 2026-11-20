# FP4 call audio: experimental Sailfish HAL alternative (not selected)

Status: **deferred alternative; not part of the ZamarteOS Pure runtime image**. The active FP4 path is the native Q6Voice/VoiceMMode1 stack from the pinned Moarchy hardware base. Do not switch the image to PulseAudio/Droid HAL on the basis of this package-only experiment. The packages below are isolated build research and are not proof of working calls. The active Q6Voice image still requires real incoming/outgoing call acceptance tests on the target Fairphone 4.

## Stage 1 now tracked in ZamarteOS\n\nThe branch now contains pinned ARM64 PKGBUILDs for `hybris-android-headers`, `libhybris-fp4`, `pulseaudio-modules-droid-fp4`, `hidl-audio-fp4`, and `droid-config-fp4`. A separate GitHub Actions workflow builds only these packages on an ARM64 runner and uploads the package artifacts. It does not build or flash a phone image.\n\nThe first build is intended to expose real dependency/ABI problems, especially whether the Arch Linux ARM PulseAudio package exports the `pulsecore` development metadata required by the Droid modules. A package compile is not proof of working call audio.\n\n## Header ABI correction after reference build #57

The previous reference-image workflow failed before image assembly because the bundled Android 5.1.1 header snapshot did not define Android 11 audio symbols used by the pinned Droid modules. The package error for `hidl-audio-fp4` was only a downstream dependency failure.

The header package now keeps the legacy common headers for compatibility but overlays the pinned ARM64 public headers from the Android VNDK 30 snapshot (AOSP mirror commit `5f9884aa352825291757dfd6694b874ad8c1805e`). Its compile-time preflight checks the exact missing device enums, call mode, audio sources, input/output flags, formats and microphone address constants. The libhybris build also receives these VNDK 30 include paths first.

This package-only CI run is a dependency/ABI check. It is not a full ZamarteOS image build and does not prove that calls work on the phone.

## Required implementation

The FP4 Sailfish adaptation uses the Android 11 audio HAL through the following chain:

`PulseAudio -> pulseaudio-modules-droid -> libhybris/libhardware -> FP4 HIDL audio compatibility library -> Android vendor audio HAL`.

The device-specific HIDL package installs:

- `audio.hidl_compat.default.so` under `/usr/libexec/droid-hybris/system/lib64/hw/`
- a `libaudioroute.so` link to `/apex/com.android.vndk.v30/lib64/libaudioroute.so`

The FP4 adaptation also supplies device-specific PulseAudio policy/configuration, including `xpolicy.conf`, voice-call routing, microphone, earpiece, speaker, wired headset and Bluetooth HFP/HSP mappings.

Sources:
- https://github.com/SailfishOS-for-the-fairphone-4/hidl_audio
- https://github.com/SailfishOS-for-the-fairphone-4/droid-configs-FP4
- https://github.com/mer-hybris/pulseaudio-modules-droid
- https://docs.sailfishos.org/Reference/Architecture/

## Compatibility facts established

- The FP4 HIDL RPM spec is MIT-licensed and provides the HIDL compatibility library plus the VNDK v30 `libaudioroute.so` link.
- The upstream `pulseaudio-modules-droid` project documents Android 11.x support and requires PulseAudio core >= 14.2, Android headers, libhardware/libhybris, ALSA and libudev.
- Its `module-droid-card` exposes virtual `voicecall` routing profiles. The FP4 Sailfish configuration includes the policy mappings for call audio and physical outputs/inputs.
- The current pinned Moarchy FP4 base uses PipeWire, PipeWire-Pulse and WirePlumber alongside the native Q6Voice kernel/daemon path.
- ZamarteOS currently inherits that native Q6Voice path. The Sailfish PulseAudio/Droid HAL chain remains a separate, deferred alternative and must not be mixed into the active image without a complete server-ownership and call-state design.

## Integration blockers that must be resolved before a release image

1. Build/package a compatible PulseAudio runtime and the Droid modules for the target Arch ARM userspace. The Droid modules must be built against the exact PulseAudio core ABI installed in the image.
2. Build/package libhybris and the required Android 11 headers/runtime compatibility pieces. Do not assume Sailfish RPM binaries are installable on Arch.
3. Include the FP4 HIDL compatibility library and verify that the pinned vendor image really contains the expected VNDK v30 target `/apex/com.android.vndk.v30/lib64/libaudioroute.so`.
4. Port the FP4 PulseAudio policy/configuration and its call-state integration to ZamarteOS. The Sailfish policy cannot simply be copied without verifying which service publishes call state and route changes in this image.
5. Resolve the audio-server ownership transition. The current image uses PipeWire/WirePlumber; the Droid HAL modules are PulseAudio modules. They cannot be treated as drop-in PipeWire plugins. The final image must have one deliberate audio-server/routing design, not two competing services controlling the same ALSA device.
6. These steps apply only if the project explicitly chooses the Sailfish alternative later; they are not prerequisites for validating the active Q6Voice path.\n7. Add a ModemManager call-state bridge that switches the Droid card to `voicecall` on call connect and returns to `default` after hangup. The Sailfish `xpolicy.conf` is intentionally not installed because it expects Sailfish/Telepathy policy properties absent from ZamarteOS.

## Required hardware acceptance tests

A successful package build or static image check is not proof of working calls. On the FP4, verify all of these with real calls:

- incoming call rings;
- outgoing and incoming call audio through the earpiece;
- two-way microphone and speakerphone audio;
- mute and volume control;
- wired headset microphone/output;
- Bluetooth HFP/HSP call audio;
- return to normal media audio after hanging up.

## Build policy

Do not trigger or label the current Q6Voice/PipeWire image as the Sailfish-audio build. Do not flash the phone as part of CI. Trigger the full reference-image build only after the dependencies, runtime switch, policy and verifier are changed together.
