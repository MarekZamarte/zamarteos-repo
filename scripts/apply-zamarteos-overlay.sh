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

# Pull the shell package into the rootfs transaction.
META="$ROOT/pkgbuilds/moarchy-meta/PKGBUILD"
if ! grep -q "'zamarteos-shell'" "$META"; then
  sed -i "/^  'moarchy-device'$/a\\  'zamarteos-shell'" "$META"
fi
# Bump package releases because both payloads changed. This matters for future
# pacman upgrades, not only for a clean first image build.
sed -i 's/^pkgrel=2$/pkgrel=3/' "$META"
sed -i 's/^pkgrel=18$/pkgrel=19/' "$ROOT/pkgbuilds/moarchy/PKGBUILD"

# Keep the upstream session launcher intact. It starts the complete Quickshell
# host, plugin registry, app drawer, control center and Settings. Replacing it
# with a standalone QML file removes Phone/Messages/Settings plugins and the
# volume panel even though their packages are present.

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

# Keep the upstream lock helper and PAM service. They target the lock plugin
# in the full Moarchy shell; the standalone ZamarteOS shell IPC target is not
# present once the native plugin host is restored.

 

# Extend the pinned base verifier: a green image must contain the native
# phone apps, settings, volume plugin and the Hyprland hardware-key bindings.
python3 - "$ROOT/image/verify.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
needle = "have /usr/bin/quickshell\\n"
lines = [
    "# ZamarteOS Pure integration checks",
    "have /usr/lib/zamarteos/firstboot-pin",
    "have /usr/lib/systemd/system/zamarteos-firstboot-pin.service",
    "have /usr/share/moarchy/plugins/moarchy.phone/manifest.json",
    "have /usr/share/moarchy/plugins/moarchy.messages/manifest.json",
    "have /usr/share/moarchy/plugins/moarchy.settings/manifest.json",
    "have /usr/share/moarchy/plugins/moarchy.volume/manifest.json",
    "have /usr/lib/moarchy/bin/moarchy-volume",
    "have /usr/share/moarchy/config/hypr/bindings.lua",
    "if grep -Fq 'moarchy-volume up' \"$R/usr/share/moarchy/config/hypr/bindings.lua\" && grep -Fq 'moarchy-volume down' \"$R/usr/share/moarchy/config/hypr/bindings.lua\" && grep -Fq 'XF86AudioRaiseVolume' \"$R/usr/share/moarchy/config/hypr/bindings.lua\" && grep -Fq 'XF86AudioLowerVolume' \"$R/usr/share/moarchy/config/hypr/bindings.lua\"; then",
    "  ok \"the physical volume keys are bound in the active Hyprland Lua configuration\"",
    "else",
    "  no \"the physical volume key bindings are missing from the active Hyprland Lua configuration\"",
    "fi",
    "if grep -Fq 'wpctl set-volume' \"$R/usr/lib/moarchy/bin/moarchy-volume\" && grep -Fq 'wpctl set-mute' \"$R/usr/lib/moarchy/bin/moarchy-volume\"; then",
    "  ok \"the hardware volume helper controls the existing PipeWire sink\"",
    "else",
    "  no \"the hardware volume helper is missing PipeWire controls\"",
    "fi",
    "if grep -Fq 'auth include login' \"$R/etc/pam.d/omarchy-lock-password\"; then",
    "  ok \"the native session lock uses the system login PAM stack\"",
    "else",
    "  no \"the native session lock PAM service is missing or misconfigured\"",
    "fi",
    "if grep -Fq 'qs -p \"$OMARCHY_PATH/shell\" ipc call lock lock' \"$R/usr/lib/moarchy/bin/moarchy-lock\"; then",
    "  ok \"the lock helper targets the native Quickshell session\"",
    "else",
    "  no \"the lock helper does not target the native Quickshell session\"",
    "fi",
    "if grep -Fq 'quickshell -n -p \"$OMARCHY_PATH/shell\"' \"$R/usr/lib/moarchy/bin/moarchy-restart-shell\"; then",
    "  ok \"the session launcher starts the native plugin host\"",
    "else",
    "  no \"the session launcher has been replaced or does not start the plugin host\"",
    "fi",
    "if grep -q '^LANG=pl_PL.UTF-8$' \"$R/etc/locale.conf\"; then",
    "  ok \"Polish is the active system locale\"",
    "else",
    "  no \"the active system locale is not pl_PL.UTF-8\"",
    "fi",
]
checks = "\\n".join(lines) + "\\n"
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
# ZamarteOS first-boot service asks the owner to choose a private PIN on tty1.
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

marker = "have /usr/lib/zamarteos/firstboot-pin"
extra = """have /usr/lib/zamarteos/firstboot-pin
have /usr/lib/systemd/system/zamarteos-firstboot-pin.service
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
    raise SystemExit("Could not find the ZamarteOS shell verifier marker")
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

echo "ZamarteOS overlay applied to $ROOT"
