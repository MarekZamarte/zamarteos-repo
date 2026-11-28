# Murena Hub for Sailfish OS

First native Sailfish Silica prototype with Sailfish WebView pointing to https://murena.io.

It uses the Murena Workspace dashboard and its account-enabled web services: Photos, Files, Contacts, Calendar, Notes, Tasks and Mail. Login remains inside the Murena web session; the app does not ask for or save the password.

This is a web portal prototype, not a native offline gallery or background synchronization client. Native WebDAV photo/file browsing and CardDAV/CalDAV sync are later development phases.

Build only inside the Sailfish SDK target matching the Fairphone 4 Sailfish installation (Sailfish OS 5.0 AArch64). Do not compile on the desktop host and package that binary.
