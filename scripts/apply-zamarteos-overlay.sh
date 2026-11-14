#!/usr/bin/env bash
# Apply the tracked ZamarteOS shell overlay to a clean, pinned Moarchy FP4 tree.
# Usage: bash scripts/apply-zamarteos-overlay.sh /path/to/moarchy
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${1:?Usage: apply-zamarteos-overlay.sh /path/to/moarchy}"
ROOT="$(cd "$ROOT" && pwd)"

for required in pkgbuilds/moarchy-meta/PKGBUILD pkgbuilds/moarchy/PKGBUILD bin/moarchy-lock bin/moarchy-restart-shell; do
  [[ -f "$ROOT/$required" ]] || { echo "Missing expected Moarchy path: $required" >&2; exit 1; }
done

# The shell is an ordinary in-repo package, so the upstream package builder
# builds it and the image's local pacman repository can resolve it.
rm -rf "$ROOT/pkgbuilds/zamarteos-shell"
cp -a "$HERE/packaging/zamarteos-shell" "$ROOT/pkgbuilds/zamarteos-shell"

# Patch the pinned standalone Wayland keyboard after it is cloned by the
# upstream package builder. The patch is kept in this repository and applied
# only to the exact keyboard commit pinned by the base manifest.
PREDICTOR="$HERE/packaging/zamarteos-keyboard-predictor"
[[ -f "$PREDICTOR/apply.py" ]] || { echo "Missing ZamarteOS keyboard predictor patch" >&2; exit 1; }
rm -rf "$ROOT/zamarteos-keyboard-predictor"
cp -a "$PREDICTOR" "$ROOT/zamarteos-keyboard-predictor"
python3 - "$ROOT/docker/build-packages.sh" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
anchor = '''     as_builder_dir "/home/builder/$component"; then
    if already_built "/home/builder/$component/$c_dir"; then
'''
insert = '''     as_builder_dir "/home/builder/$component"; then
    if [[ "$component" == "moarchy-keyboard" ]]; then
      python3 /repo/zamarteos-keyboard-predictor/apply.py "/home/builder/$component"
      chown -R builder:builder "/home/builder/$component"
    fi
    if already_built "/home/builder/$component/$c_dir"; then
'''
if insert not in s:
    if anchor not in s:
        raise SystemExit("Could not find the pinned component build hook")
    s = s.replace(anchor, insert, 1)
    p.write_text(s)
PY

# Skip one optional AUR application that currently prevents the ARM64 package
# batch from completing: spot-client 0.5.0 pins openssl-sys 0.9.104, which
# rejects the OpenSSL 4.1 shipped by the current Arch Linux ARM build image.
# It is not a moarchy-meta dependency or a phone hardware service. Do not let
# this optional Spotify client block the operating-system image.
python3 - "$ROOT/manifest.toml" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
s = p.read_text()
pattern = r"(?ms)^\[aur\.spot-client\]\n.*?(?=^\[|\Z)"
updated, count = re.subn(pattern, "", s)
if count != 1:
    raise SystemExit(f"Expected exactly one optional spot-client manifest section, found {count}")
p.write_text(updated)
PY

# Pull the shell and the IMS data daemon into the rootfs transaction.
# q6voiced holds the FP4 VoiceMMode1 PCM; 81voltd provides the IMS PDN
# requested by the modem on VoLTE-only networks (no circuit-switched fallback).
META="$ROOT/pkgbuilds/moarchy-meta/PKGBUILD"
if ! grep -q "'zamarteos-shell'" "$META"; then
  sed -i "/^  'moarchy-device'$/a\\  'zamarteos-shell'" "$META"
fi
if ! grep -q "'81voltd'" "$META"; then
  sed -i "/^  'callaudiod'$/a\\  '81voltd'" "$META"
fi
# pkgrel 4 includes both the ZamarteOS shell and mandatory IMS support.
# A dependency-set change must be visible to pacman on development images.
sed -i 's/^pkgrel=2$/pkgrel=4/' "$META"

# 81voltd is required on VoLTE-only networks. The upstream source package
# builds the daemon but its Arch recipe does not guarantee a systemd unit;
# ship and enable the service explicitly rather than relying on build-host
# Meson autodetection or a first-boot script.
VOLTE="$ROOT/pkgbuilds/81voltd"
cat > "$VOLTE/81voltd.service" <<'UNIT'
[Unit]
Description=QMI IMS Data service for VoLTE
After=ModemManager.service
Wants=ModemManager.service

[Service]
Type=simple
ExecStart=/usr/bin/81voltd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
python3 - "$VOLTE/PKGBUILD" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
old_source = 'source=("$pkgname-$_ver.tar.gz::$url/-/archive/v$_ver/$pkgname-v$_ver.tar.gz")'
new_source = 'source=("$pkgname-$_ver.tar.gz::$url/-/archive/v$_ver/$pkgname-v$_ver.tar.gz" "81voltd.service")'
old_sums = "sha256sums=('bb0e9774463fb4964067bf70f10cc316afc1c8ed163ff7969b3fd3ae3dc2e937')"
new_sums = "sha256sums=('bb0e9774463fb4964067bf70f10cc316afc1c8ed163ff7969b3fd3ae3dc2e937' 'SKIP')"
if old_source not in source or old_sums not in source:
    raise SystemExit("81voltd PKGBUILD source/checksum pins changed; refusing an unsafe patch")
source = source.replace(old_source, new_source, 1).replace(old_sums, new_sums, 1)
# The qrtr library is shipped by moarchy-qcom-modem (provides=qrtr).
# Depend on the actual package name so the offline builder can resolve it.
old_dep = "depends=('modemmanager' 'libqmi' 'qrtr' 'glib2')"
new_dep = "depends=('modemmanager' 'libqmi' 'moarchy-qcom-modem' 'glib2')"
if old_dep not in source:
    raise SystemExit("81voltd dependency list changed; refusing an unsafe patch")
source = source.replace(old_dep, new_dep, 1)
source = source.replace("pkgrel=1\n", "pkgrel=2\n", 1)
needle = '  DESTDIR="$pkgdir" ninja -C build install\n'
addition = '''  DESTDIR="$pkgdir" ninja -C build install

  install -Dm644 "$srcdir/81voltd.service" "$pkgdir/usr/lib/systemd/system/81voltd.service"
  install -d "$pkgdir/usr/lib/systemd/system/multi-user.target.wants"
  ln -s ../81voltd.service "$pkgdir/usr/lib/systemd/system/multi-user.target.wants/81voltd.service"
  [ -x "$pkgdir/usr/bin/81voltd" ] || { echo "!! 81voltd daemon was not installed"; return 1; }
'''
if needle not in source:
    raise SystemExit("81voltd package() install anchor missing")
source = source.replace(needle, addition, 1)
path.write_text(source)
PY

# Start the actual ZamarteOS session on tty1. The upstream session launcher
# must not start its own Moarchy/Omarchy shell: our package owns the user-facing
# Wayland session, while the pinned base continues to provide hardware services.
python3 - "$ROOT/default/etc/profile.d/zz-moarchy.sh" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = "exec Hyprland -c /usr/share/moarchy/config/hypr/hyprland.lua"
new = "exec /usr/bin/zamarteos-session"
if old not in s:
    raise SystemExit("Could not find the pinned base's tty1 Hyprland launch")
p.write_text(s.replace(old, new, 1))
PY

# Route system lock requests to the ZamarteOS shell's own PAM-backed IPC target.
python3 - "$ROOT/bin/moarchy-lock" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = 'exec timeout 3 qs -p "$OMARCHY_PATH/shell" ipc call lock lock >/dev/null 2>&1'
new = 'exec timeout 3 qs -p /usr/share/zamarteos-shell ipc call zamarteos-lock lock >/dev/null 2>&1'
if old not in s:
    raise SystemExit("Could not find the pinned base lock IPC command")
p.write_text(s.replace(old, new, 1))
PY

# Restart requests must relaunch ZamarteOS, never the upstream desktop shell.
cat > "$ROOT/bin/moarchy-restart-shell" <<'SH'
#!/bin/sh
exec /usr/bin/zamarteos-shell
SH
chmod 755 "$ROOT/bin/moarchy-restart-shell"

# Polish system locale. Keep en_US generated as a fallback, but make
# Polish the active locale so dates and system messages match the shell.
python3 - "$ROOT/image/configure.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
old_locale = """sed -i 's/^#\\(en_US.UTF-8 UTF-8\\)/\\1/' "$ROOTDIR/etc/locale.gen"
"""
new_locale = """sed -i -e 's/^#\\(en_US.UTF-8 UTF-8\\)/\\1/' -e 's/^#\\(pl_PL.UTF-8 UTF-8\\)/\\1/' "$ROOTDIR/etc/locale.gen"
"""
old_lang = """echo 'LANG=en_US.UTF-8' > "$ROOTDIR/etc/locale.conf"
"""
new_lang = """printf 'LANG=pl_PL.UTF-8\\nLANGUAGE=pl_PL:pl\\n' > "$ROOTDIR/etc/locale.conf"
"""
if old_locale not in source or old_lang not in source:
    raise SystemExit("Expected locale settings not found in pinned FP4 image/configure.sh")
source = source.replace(old_locale, new_locale, 1).replace(old_lang, new_lang, 1)
path.write_text(source)
PY

# Extend the pinned base verifier: a green image must contain the real ZamarteOS
# QML shell, its own session launchers, lock service and physical volume bindings.
python3 - "$ROOT/image/verify.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
needle = "have /usr/bin/quickshell\n"
lines = [
    "# ZamarteOS Pure integration checks",
    "have /usr/lib/zamarteos/firstboot-pin",
    "have /usr/lib/systemd/system/zamarteos-firstboot-pin.service",
    "have /usr/share/zamarteos-shell/shell.qml",
    "have /usr/share/zamarteos-shell/hyprland.conf",
    "have /usr/bin/zamarteos-session",
    "have /usr/bin/zamarteos-shell",
    "have /etc/pam.d/zamarteos-lock",
    "have /usr/share/wayland-sessions/zamarteos.desktop",
    "if grep -Fq 'XF86AudioRaiseVolume' \"$R/usr/share/zamarteos-shell/hyprland.conf\" && grep -Fq 'XF86AudioLowerVolume' \"$R/usr/share/zamarteos-shell/hyprland.conf\"; then",
    "  ok \"the physical volume keys are bound in the active Hyprland Lua configuration\"",
    "else",
    "  no \"the physical volume key bindings are missing from the active Hyprland Lua configuration\"",
    "fi",
    "if grep -Fq 'wpctl set-volume' \"$R/usr/share/zamarteos-shell/hyprland.conf\" && grep -Fq 'wpctl set-mute' \"$R/usr/share/zamarteos-shell/hyprland.conf\"; then",
    "  ok \"the hardware volume helper controls the existing PipeWire sink\"",
    "else",
    "  no \"the hardware volume helper is missing PipeWire controls\"",
    "fi",
    "if grep -Fq 'auth include login' \"$R/etc/pam.d/zamarteos-lock\"; then",
    "  ok \"the native session lock uses the system login PAM stack\"",
    "else",
    "  no \"the native session lock PAM service is missing or misconfigured\"",
    "fi",
    "if grep -Fq 'ipc call zamarteos-lock lock' \"$R/usr/lib/moarchy/bin/moarchy-lock\"; then",
    "  ok \"the lock helper targets the native Quickshell session\"",
    "else",
    "  no \"the lock helper does not target the native Quickshell session\"",
    "fi",
    "if grep -Fq 'zamarteos-shell' \"$R/usr/lib/moarchy/bin/moarchy-restart-shell\"; then",
    "  ok \"the session launcher starts the native plugin host\"",
    "else",
    "  no \"the session launcher has been replaced or does not start the plugin host\"",
    "fi",
    "if grep -Fq 'exec /usr/bin/zamarteos-session' \"$R/etc/profile.d/zz-moarchy.sh\"; then",
    "  ok \"tty1 starts the ZamarteOS Wayland session\"",
    "else",
    "  no \"tty1 still starts the upstream desktop shell\"",
    "fi",
    "if grep -q '^LANG=pl_PL.UTF-8$' \"$R/etc/locale.conf\"; then",
    "  ok \"Polish is the active system locale\"",
    "else",
    "  no \"the active system locale is not pl_PL.UTF-8\"",
    "fi",
]
checks = "\n".join(lines) + "\n"
if "# ZamarteOS Pure integration checks" not in source:
    if needle not in source:
        raise SystemExit("Could not find the Quickshell check in the pinned image verifier")
    source = source.replace(needle, needle + checks, 1)
    path.write_text(source)
PY


# Do not ship a shared PIN or passwordless sudo. The first-boot PIN service
# sets a private credential before the native session lock and tty1 autologin.
python3 - "$ROOT/image/configure.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
start = source.find("# --- the user (I8)")
end = source.find("# sshd off by default", start)
if start < 0 or end < 0:
    raise SystemExit("Could not find the pinned base user/security section")

user_setup = """# --- the user (I8) ---------------------------------------------------------
# No credential is baked into the image. The account stays locked until the
# ZamarteOS first-boot service generates a private per-device PIN and stores it in the user home.
arch-chroot "$ROOTDIR" useradd -m -G wheel,video,audio,input,feedbackd -s /bin/bash "$USER_NAME"
arch-chroot "$ROOTDIR" passwd -l "$USER_NAME" >/dev/null
arch-chroot "$ROOTDIR" passwd -l root >/dev/null

# Autologin is safe only after the first-boot PIN service has completed. The
# getty drop-in shipped by zamarteos-shell makes that ordering mandatory.
install -d "$ROOTDIR/etc/systemd/system/getty@tty1.service.d"
cat >"$ROOTDIR/etc/systemd/system/getty@tty1.service.d/autologin.conf" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $USER_NAME %I \\$TERM
EOF

# Wheel membership is retained, but sudo always asks for the user's private PIN.
# The pinned omarchy-config package also installs a command-scoped NOPASSWD
# browser-theme helper rule. It is not required by the ZamarteOS phone shell.
# Remove both upstream passwordless rules after pacstrap has installed packages.
install -d "$ROOTDIR/etc/sudoers.d"
rm -f "$ROOTDIR/etc/sudoers.d/10-moarchy" "$ROOTDIR/etc/sudoers.d/omarchy-theme-browser"
printf '%s\\n' '%wheel ALL=(ALL:ALL) ALL' > "$ROOTDIR/etc/sudoers.d/10-zamarteos-wheel"
chmod 440 "$ROOTDIR/etc/sudoers.d/10-zamarteos-wheel"
say "user $USER_NAME (locked until first-boot PIN setup; sudo requires password; root locked)"

"""
source = source[:start] + user_setup + source[end:]

old_ssh = """# The image's only password is the public default PIN (above), so password auth
# over ssh would be an open door until the user changes it. Keys only.
"""
new_ssh = """# The first-boot PIN is private to this device; SSH still accepts keys only.
"""
if old_ssh in source:
    source = source.replace(old_ssh, new_ssh, 1)

path.write_text(source)
PY

# Extend the offline image verifier for first-boot PIN setup and account security.
python3 - "$ROOT/image/verify.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()

marker = "# ZamarteOS Pure integration checks"
extra = """have /usr/lib/systemd/system/zamarteos-firstboot-pin.service
have /usr/lib/systemd/system/moarchy-firstboot.service.d/10-zamarteos-pin.conf
have /usr/lib/systemd/system/getty@tty1.service.d/10-zamarteos-firstboot.conf
if bash -n "$R/usr/lib/zamarteos/firstboot-pin" 2>/dev/null; then
  ok "the first-boot PIN setup script has valid Bash syntax"
else
  no "the first-boot PIN setup script has invalid Bash syntax"
fi
if grep -Fq 'Before=moarchy-firstboot.service getty@tty1.service' "$R/usr/lib/systemd/system/zamarteos-firstboot-pin.service" &&
   grep -Fq 'TimeoutStartSec=0' "$R/usr/lib/systemd/system/zamarteos-firstboot-pin.service"; then
  ok "the per-device PIN is generated before tty1 autologin without console input"
else
  no "the per-device PIN service is not ordered before tty1 autologin"
fi
if [ -e "$R/home/moarchy/PIERWSZE-URUCHOMIENIE.txt" ]; then
  no "a per-device PIN note is baked into the published image"
else
  ok "no per-device PIN is baked into the published image"
fi
if grep -Fq 'Requires=zamarteos-firstboot-pin.service' "$R/usr/lib/systemd/system/moarchy-firstboot.service.d/10-zamarteos-pin.conf" &&
   grep -Fq 'After=zamarteos-firstboot-pin.service' "$R/usr/lib/systemd/system/moarchy-firstboot.service.d/10-zamarteos-pin.conf" &&
   grep -Fq 'Requires=moarchy-firstboot.service' "$R/usr/lib/systemd/system/getty@tty1.service.d/10-zamarteos-firstboot.conf"; then
  ok "tty1 autologin is gated on successful first-boot setup"
else
  no "tty1 autologin is not gated on first-boot setup"
fi
"""
if marker not in source:
    raise SystemExit("Could not find the ZamarteOS integration verifier marker")
if extra not in source:
    source = source.replace(marker, marker + chr(10) + extra, 1)

cred_start = source.find("# A locked password is ! or *", source.find('sec "credentials -- what must NOT be here"'))
if cred_start < 0:
    raise SystemExit("Could not find the credential checks in the pinned verifier")
loop_start = source.find("for acct in moarchy root;", cred_start)
loop_end = source.find(chr(10) + "done" + chr(10), loop_start)
if loop_start < 0 or loop_end < 0:
    raise SystemExit("Could not find the account credential loop")
loop_end += len(chr(10) + "done" + chr(10))

secure_credentials = """# A published image must contain no usable password hash. The owner chooses
# a private PIN on first boot, before getty can start the autologin session.
for acct in moarchy root; do
  h=$(awk -F: -v a="$acct" '$1==a{print $2}' "$R/etc/shadow" 2>/dev/null)
  case "$h" in
    '!'*|'*'*|'!') ok "$acct password is locked in the image" ;;
    '')            no "$acct has an EMPTY password" ;;
    *)             no "$acct has a password hash in the published image" ;;
  esac
done
if grep -RqsE '^[[:space:]]*[^#[:space:]].*NOPASSWD[[:space:]]*:' "$R/etc/sudoers" "$R/etc/sudoers.d" 2>/dev/null; then
  no "an active passwordless sudo rule is present"
else
  ok "no active passwordless sudo rules"
fi
if grep -Fqx '%wheel ALL=(ALL:ALL) ALL' "$R/etc/sudoers.d/10-zamarteos-wheel" 2>/dev/null; then
  ok "wheel sudo requires the user's password"
else
  no "wheel sudo is missing its password-required rule"
fi
"""
source = source[:cred_start] + secure_credentials + source[loop_end:]

test_marker = '[ -e "$R/etc/moarchy-debug-image" ]'
test_block = """# Exercise the headless first-boot PIN generator without changing the image shadow database.
sec "behaviour: ZamarteOS first-boot PIN setup"
TESTBIN="$R/tmp/zamarteos-verify-bin"
mkdir -p "$TESTBIN"
cat > "$TESTBIN/od" <<'EOF'
#!/bin/sh
printf '1234567890\\n'
EOF
cat > "$TESTBIN/chpasswd" <<'EOF'
#!/bin/sh
[ "$#" -eq 2 ] && [ "$1" = "-c" ] && [ "$2" = "SHA512" ] || exit 2
IFS= read -r value || exit 3
[ "$value" = "moarchy:74567890" ] || exit 4
printf 'called\\n' > /tmp/zamarteos-verify-chpasswd-called
EOF
chmod 755 "$TESTBIN/od" "$TESTBIN/chpasswd"
rm -f "$R/tmp/zamarteos-verify-chpasswd-called" "$R/home/moarchy/PIERWSZE-URUCHOMIENIE.txt"
if chroot "$R" env PATH=/tmp/zamarteos-verify-bin:/usr/bin:/bin ZAMARTEOS_STATE_DIR=/var/lib/zamarteos-verify /usr/lib/zamarteos/firstboot-pin > "$WORK/zamarteos-pin.log" 2>&1; then
  if [ -s "$R/tmp/zamarteos-verify-chpasswd-called" ] &&
     [ -f "$R/var/lib/zamarteos-verify/firstboot-pin-done" ] &&
     grep -Fq 'Twój prywatny PIN: 74567890' "$R/home/moarchy/PIERWSZE-URUCHOMIENIE.txt" &&
     [ "$(stat -c %a "$R/home/moarchy/PIERWSZE-URUCHOMIENIE.txt")" = 600 ] &&
     [ "$(stat -c %u "$R/home/moarchy/PIERWSZE-URUCHOMIENIE.txt")" = "$(awk -F: '$1=="moarchy"{print $3}' "$R/etc/passwd")" ]; then
    ok "headless first boot creates a private 8-digit PIN, sets it, and stores a user-only note"
  else
    no "first-boot PIN setup did not set the password and create the private note"
    sed 's/^/       /' "$WORK/zamarteos-pin.log"
  fi
else
  no "first-boot PIN setup failed its headless test"
  sed 's/^/       /' "$WORK/zamarteos-pin.log"
fi
rm -rf "$TESTBIN" "$R/tmp/zamarteos-verify-chpasswd-called" "$R/var/lib/zamarteos-verify" "$R/home/moarchy/PIERWSZE-URUCHOMIENIE.txt"

"""
if test_marker not in source:
    raise SystemExit("Could not find the debug-image verifier marker")
if test_block not in source:
    source = source.replace(test_marker, test_block + test_marker, 1)

path.write_text(source)
PY

# Make call-audio support a hard image-build acceptance check. A media-only
# PipeWire setup is not enough: FP4 needs the Q6Voice kernel modules, the
# VoiceMMode1 PCM owner, the measured PCM selection, and the call mixer routes.
python3 - "$ROOT/image/verify.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
marker = "# ZamarteOS FP4 call-audio acceptance checks"
block = r"""# ZamarteOS FP4 call-audio acceptance checks
have /usr/bin/q6voiced
have /usr/bin/81voltd
have /usr/lib/systemd/system/81voltd.service
if [ -L "$R/usr/lib/systemd/system/multi-user.target.wants/81voltd.service" ]; then
  ok "81voltd IMS service is enabled at boot"
else
  no "81voltd IMS service is not enabled at boot"
fi
have /usr/lib/systemd/system/q6voiced.service
have /usr/share/q6voiced/q6voiced.conf
have /usr/share/alsa/ucm2/Fairphone/fp4/fp4.conf
have /usr/share/alsa/ucm2/Fairphone/fp4/HiFi.conf
have /usr/share/wireplumber/wireplumber.conf.d/52-fairphone-fp4.conf
have /usr/share/wireplumber/wireplumber.conf.d/53-fp4-ucm.conf
have /usr/lib/moarchy/bin/fp4-audio-route
have /usr/lib/systemd/user/moarchy-fp4-mic-route.service
if grep -qx 'q6voice_card=0' "$R/usr/share/q6voiced/q6voiced.conf" &&
   grep -qx 'q6voice_device=3' "$R/usr/share/q6voiced/q6voiced.conf"; then
  ok "q6voiced targets the measured FP4 VoiceMMode1 PCM (card 0, device 3)"
else
  no "q6voiced is not configured for the measured FP4 VoiceMMode1 PCM"
fi
for module in q6voice q6voice-dai q6mvm q6cvs q6cvp; do
  if find "$R/usr/lib/modules" -type f \( -name "$module.ko" -o -name "$module.ko.*" \) -print -quit 2>/dev/null | grep -q .; then
    ok "kernel module $module is installed"
  else
    no "kernel module $module is missing -- cellular call audio cannot start"
  fi
done
if grep -Fq 'VoiceMMode1 Capture Mixer TX_CODEC_DMA_TX_3|1' "$R/usr/lib/moarchy/bin/fp4-audio-route" &&
   grep -Fq 'QUIN_MI2S_RX Voice Mixer VoiceMMode1|1' "$R/usr/lib/moarchy/bin/fp4-audio-route" &&
   grep -Fq 'VoiceMMode1 TX Topology|69488' "$R/usr/lib/moarchy/bin/fp4-audio-route"; then
  ok "FP4 call uplink, downlink and uncalibrated-DSP topology routes are present"
else
  no "FP4 call mixer routes are incomplete"
fi
if grep -Fq '/usr/share/q6voiced/q6voiced.conf' "$R/usr/lib/systemd/system/q6voiced.service" &&
   grep -Fq 'DEVICE_SERVICES="q6voiced.service"' "$R/usr/share/moarchy/device/device.conf"; then
  ok "the Q6Voice daemon is wired to the FP4 device configuration"
else
  no "q6voiced is not wired to the FP4 device configuration"
fi
if grep -Fq 'q6voice_device=3' "$R/usr/share/q6voiced/q6voiced.conf" &&
   grep -Fq 'VoiceMMode1' "$R/usr/lib/moarchy/bin/fp4-audio-route"; then
  ok "call-audio userspace agrees on VoiceMMode1"
else
  no "call-audio userspace PCM selection is inconsistent"
fi
"""
if marker not in source:
    needle = "have /usr/bin/quickshell\n"
    if source.count(needle) != 1:
        raise SystemExit("Could not find the unique rootfs verifier insertion point")
    source = source.replace(needle, needle + "\n" + block + "\n", 1)
    path.write_text(source)
PY

echo "ZamarteOS overlay applied to $ROOT"
