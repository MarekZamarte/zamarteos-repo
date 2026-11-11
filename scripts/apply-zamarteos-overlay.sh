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
if marker not in source:
    if needle not in source:
        raise SystemExit("Could not find the Quickshell check in the pinned image verifier")
    source = source.replace(needle, needle + checks, 1)
    path.write_text(source)
PY

echo "ZamarteOS overlay applied to $ROOT"
