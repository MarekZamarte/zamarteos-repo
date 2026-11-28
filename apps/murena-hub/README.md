# Murena Hub — native Sailfish WebDAV client

This version replaces the old embedded-web prototype with native Sailfish Silica UI and Qt Network. No browser or WebView is used.

Implemented: WebDAV PROPFIND folder/file listing, HTTP GET downloads to app cache, native image viewing. Credentials are kept in memory only and cleared when the app closes.

Setup: create an app password in Murena security settings. Enter the WebDAV URL `https://murena.io/remote.php/dav/files/`, your Murena username/email and app password, then tap connect. Use an app password, not your account password.

Contacts and calendar synchronization are not implemented in this initial native version; do not treat them as available here. The app is independent and not an official Murena product. Build only in Sailfish SDK AArch64 target, never against host glibc.