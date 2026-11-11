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

# Moarchy's session startup already calls omarchy-launch-shell, which delegates
# to moarchy-restart-shell. Keep that startup contract but point it at our own
# QML config. Do not replace the compositor, modem, audio, or kernel packages.
cat > "$ROOT/bin/moarchy-restart-shell" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_RUNTIME_DIR
[[ -n "${WAYLAND_DISPLAY:-}" ]] || {
  echo "ZamarteOS shell: WAYLAND_DISPLAY is not set" >&2
  exit 1
}

export PATH="$HOME/.local/bin:$(dirname "$(readlink -f "$0")"):$PATH"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/zamarteos/shell-off"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/zamarteos/shell.log"
pkill -x quickshell 2>/dev/null || true
for _ in $(seq 40); do
  pgrep -x quickshell >/dev/null 2>&1 || break
  sleep 0.25
done
[[ -f "$STATE" ]] && exit 0
mkdir -p "$(dirname "$LOG")"
QS_NO_RELOAD_POPUP=1 setsid qs -n -p /usr/share/zamarteos-shell >"$LOG" 2>&1 &
EOF
chmod +x "$ROOT/bin/moarchy-restart-shell"

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

# Keep the existing power/idle path (moarchy-screen -> moarchy-lock), but
# direct the actual lock request to our PAM-backed Quickshell session lock.
cat > "$ROOT/bin/moarchy-lock" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
exec timeout 3 qs ipc call zamarteos-lock lock >/dev/null 2>&1
EOF
chmod +x "$ROOT/bin/moarchy-lock"

 

# Extend the pinned base verifier so a green image check also proves that the
# ZamarteOS shell package and its session/lock wiring are actually in rootfs.
python3 - "$ROOT/image/verify.sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
marker = "# ZamarteOS Pure overlay checks"
needle = "have /usr/bin/quickshell\n"
lines = [
    marker,
    "have /usr/share/zamarteos-shell/shell.qml",
    "have /etc/pam.d/zamarteos-lock",
    "if grep -Fxq 'auth include login' \"$R/etc/pam.d/zamarteos-lock\"; then",
    "  ok \"the ZamarteOS lock delegates authentication to the system login PAM stack\"",
    "else",
    "  no \"the ZamarteOS lock PAM policy does not include the system login stack\"",
    "fi",
    "if grep -Fq 'qs -n -p /usr/share/zamarteos-shell' \"$R/usr/lib/moarchy/bin/moarchy-restart-shell\"; then",
    "  ok \"the session launcher starts the ZamarteOS Quickshell\"",
    "else",
    "  no \"the session launcher does not start /usr/share/zamarteos-shell\"",
    "fi",
    "if grep -Fq 'qs ipc call zamarteos-lock lock' \"$R/usr/lib/moarchy/bin/moarchy-lock\"; then",
    "  ok \"the screen-lock command reaches the ZamarteOS PAM lock\"",
    "else",
    "  no \"the screen-lock command is not wired to zamarteos-lock\"",
    "fi",
    "if grep -q '^LANG=pl_PL.UTF-8$' \"$R/etc/locale.conf\"; then",
    "  ok \"Polish is the active system locale\"",
    "else",
    "  no \"the active system locale is not pl_PL.UTF-8\"",
    "fi",
]
checks = "\n".join(lines) + "\n"
if "have /usr/share/zamarteos-shell/shell.qml" not in source:
    if needle not in source:
        raise SystemExit("Could not find the Quickshell check in the pinned image verifier")
    source = source.replace(needle, needle + checks, 1)
    path.write_text(source)
PY


# Do not ship a shared PIN or passwordless sudo. The first-boot PIN service
# sets a private credential on tty1 before the normal autologin session starts.
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
install -d "$ROOTDIR/etc/sudoers.d"
rm -f "$ROOTDIR/etc/sudoers.d/10-moarchy"
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

marker = "have /usr/share/zamarteos-shell/shell.qml"
extra = """have /usr/lib/zamarteos/firstboot-pin
have /usr/lib/systemd/system/zamarteos-firstboot-pin.service
have /usr/lib/systemd/system/moarchy-firstboot.service.d/10-zamarteos-pin.conf
have /usr/lib/systemd/system/getty@tty1.service.d/10-zamarteos-firstboot.conf
if bash -n "$R/usr/lib/zamarteos/firstboot-pin" 2>/dev/null; then
  ok "the first-boot PIN setup script has valid Bash syntax"
else
  no "the first-boot PIN setup script has invalid Bash syntax"
fi
if grep -Fq 'StandardInput=tty' "$R/usr/lib/systemd/system/zamarteos-firstboot-pin.service" &&
   grep -Fq 'TTYPath=/dev/tty1' "$R/usr/lib/systemd/system/zamarteos-firstboot-pin.service" &&
   grep -Fq 'Before=moarchy-firstboot.service getty@tty1.service' "$R/usr/lib/systemd/system/zamarteos-firstboot-pin.service"; then
  ok "the private PIN prompt runs on tty1 before autologin"
else
  no "the private PIN service is not ordered on tty1 before autologin"
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
    source = source.replace(marker, marker + extra, 1)

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
fi"""
source = source[:cred_start] + secure_credentials + source[loop_end:]

test_marker = '[ -e "$R/etc/moarchy-debug-image" ]'
test_block = """# Exercise the PIN prompt without changing the image's real shadow database.
sec "behaviour: ZamarteOS first-boot PIN setup"
TESTBIN="$R/tmp/zamarteos-verify-bin"
mkdir -p "$TESTBIN"
cat > "$TESTBIN/chpasswd" <<'EOF'
#!/bin/sh
[ "$#" -eq 2 ] && [ "$1" = "-c" ] && [ "$2" = "SHA512" ] || exit 2
IFS= read -r value || exit 3
[ "$value" = "moarchy:246810" ] || exit 4
printf 'called\\n' > /tmp/zamarteos-verify-chpasswd-called
EOF
chmod 755 "$TESTBIN/chpasswd"
rm -f "$R/tmp/zamarteos-verify-chpasswd-called"
if chroot "$R" env PATH=/tmp/zamarteos-verify-bin:/usr/bin:/bin \\
     ZAMARTEOS_STATE_DIR=/var/lib/zamarteos-verify \\
     /usr/lib/zamarteos/firstboot-pin > "$WORK/zamarteos-pin.log" 2>&1 <<'EOF'
2468
246810
000000
246810
246810
EOF
then
  if [ -s "$R/tmp/zamarteos-verify-chpasswd-called" ] &&
     [ -f "$R/var/lib/zamarteos-verify/firstboot-pin-done" ]; then
    ok "first boot rejects a short/mismatched PIN and accepts a confirmed private PIN"
  else
    no "first-boot PIN setup did not call chpasswd or write its completion stamp"
    sed 's/^/       /' "$WORK/zamarteos-pin.log"
  fi
else
  no "first-boot PIN setup failed its interactive test"
  sed 's/^/       /' "$WORK/zamarteos-pin.log"
fi
rm -rf "$TESTBIN" "$R/tmp/zamarteos-verify-chpasswd-called" "$R/var/lib/zamarteos-verify"

"""
if test_marker not in source:
    raise SystemExit("Could not find the debug-image verifier marker")
if test_block not in source:
    source = source.replace(test_marker, test_block + test_marker, 1)

path.write_text(source)
PY

echo "ZamarteOS overlay applied to $ROOT"
