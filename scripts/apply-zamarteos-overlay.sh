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
QS_NO_RELOAD_POPUP=1 setsid quickshell -n -p /usr/share/zamarteos-shell >"$LOG" 2>&1 &
EOF
chmod +x "$ROOT/bin/moarchy-restart-shell"

# Keep the existing power/idle path (moarchy-screen -> moarchy-lock), but
# direct the actual lock request to our PAM-backed Quickshell session lock.
cat > "$ROOT/bin/moarchy-lock" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
exec timeout 3 qs ipc call zamarteos-lock lock >/dev/null 2>&1
EOF
chmod +x "$ROOT/bin/moarchy-lock"

echo "ZamarteOS overlay applied to $ROOT"
