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

The tracked overlay script integrates the actual ZamarteOS session into the
pinned FP4 image build:
- installs shell.qml, the Hyprland touch-first session config and launchers;
- redirects tty1 from the upstream desktop shell to zamarteos-session;
- routes lock and restart helpers to ZamarteOS IPC and QML;
- starts the FP4 graphical-session target, polkit/geoclue agents, on-screen
  keyboard and idle/suspend policy from the ZamarteOS session.

This replaces the user-facing shell and session, not the kernel, modem,
firmware, NetworkManager or audio services. The native Moarchy/Omarchy shell
must not start in the finished image. Package/image verification checks the
session wiring, but QML behaviour and every hardware feature still require
tests on a physical Fairphone 4. Do not call the image ready before those tests.

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
