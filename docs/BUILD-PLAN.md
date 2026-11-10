# ZamarteOS Pure FP4 — build plan

## Architecture decision

Use a native aarch64 Linux userspace and the existing FP4 Linux hardware port
as the initial device-support base:

- Arch Linux ARM userspace with systemd;
- SM6350/SM7225 Linux kernel and FP4 device tree;
- Qualcomm firmware only where the hardware requires it;
- ModemManager + Q6Voice + q6voiced for cellular call audio;
- Hyprland as the Wayland compositor;
- a new ZamarteOS Quickshell/QML shell, written as our own project.

This avoids the old Ubuntu Touch builder, which only replaced branding and
continued to launch Lomiri. It also avoids shipping an Android userspace.
The Android boot-image container is a bootloader format, not the OS.

## Milestone 1 — reproduce the hardware base

Build the pinned FP4 development tree in CI. This is a reference build only.
It must not be flashed. Save the complete build log and image artifact.

Acceptance checks:
1. Kernel package builds from the pinned source commit.
2. The ZamarteOS shell package builds and qmllint passes.
3. The image builder completes for DEVICE=fp4.
4. Image verification passes.
5. The artifact includes the FP4 device package, Q6Voice modules, q6voiced
   configuration and zamarteos-shell.
6. The build log and source pins are retained with the artifact.

## Milestone 2 — ZamarteOS shell

A first prototype now exists under packaging/zamarteos-shell. It provides a
home screen, desktop-entry app drawer, search, a persistent top strip, a
control-centre entry point and a PAM-backed Wayland session lock.

The tracked overlay script integrates it into the pinned FP4 image build:
- copies the package into the base tree's pkgbuilds/;
- adds it to moarchy-meta;
- redirects the existing session shell launcher to the ZamarteOS config;
- redirects the existing lock helper to the ZamarteOS IPC lock endpoint.

This replaces the user shell only. It does not replace the kernel, modem,
firmware, NetworkManager or audio services. The QML still needs an ARM64
qmllint/package build and real FP4 tests. Do not ship the upstream
Moarchy/Omarchy shell as the final UI.

The first shell milestone will provide:
- ZamarteOS home screen and application drawer;
- status bar and quick settings/control centre;
- lock screen and idle integration;
- call/notification presentation;
- Polish locale and ZamarteOS visual identity.

## Milestone 3 — apps and device integration

Integrate native Linux applications and ZamarteOS apps. Validate modem, calls,
SMS, mobile data, Wi-Fi, audio routing, sensors, camera, GPS, suspend/resume,
charging and updates.

## Milestone 4 — release candidate

Only create a flashable release after repeated physical-device tests. Verify
incoming/outgoing calls, two-way audio, ringback, speaker/earpiece routing and
operator-specific VoLTE. Keep the current phone installation untouched until
the user explicitly chooses to test the image.
