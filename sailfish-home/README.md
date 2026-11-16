# ZamarteOS Home — Sailfish OS prototype

This directory contains an **independent native Sailfish Silica application prototype** for Fairphone 4 running Sailfish OS 5.0.0.72.

It is intentionally a normal app, not a replacement for Lipstick, the system launcher, telephony, audio, modem, or device adaptation. It does not change system settings or intercept calls.

## Contents

- `ZamarteOS-Home.pro` — qmake project for Sailfish SDK
- `src/harbour-zamarteos-home.cpp` — Sailfish application entry point
- `qml/main.qml` — home-screen concept with app tiles and status panel
- `harbour-zamarteos-home.desktop` — application launcher entry

## Build

Build with the **Sailfish OS SDK** and its SailfishOS 5.0-compatible ARM64 target. Open `ZamarteOS-Home.pro` in Sailfish IDE, select the aarch64 Sailfish target, then build the RPM.

The GitHub repository currently stores APK repository packages separately. This source is kept under `sailfish-home/` so it does not overwrite those packages.

## Current limitations

This is an early UI prototype. The tiles are visual shortcuts/placeholders; they do not yet launch or control system applications. It has not yet been compiled or tested on the Fairphone 4. Do not install it as a system launcher or replace Lipstick.

## Safety / compatibility priorities

- Keep the existing Sailfish kernel, modem, audio stack, and telephony services untouched.
- Keep the application sandboxed.
- Verify compilation and on-device launch before adding integrations.
- Do not claim call audio, contacts, messaging, or hardware integration until each is tested on the phone.
