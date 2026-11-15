#!/usr/bin/env bash
set -euo pipefail

SRC="${1:?Usage: audit-fp4-halium-source.sh /path/to/fairphone-fp4 [output]}"
OUT="${2:-hybrid-device-audit.txt}"
SRC="$(cd "$SRC" && pwd)"

test -s "$SRC/deviceinfo" || { echo "Missing deviceinfo: this is not a complete device-port checkout" >&2; exit 1; }

{
  echo "ZamarteOS Hybrid FP4 — device source audit"
  echo "project=https://gitlab.com/ubports/porting/reference-device-ports/android11/fairphone-4/fairphone-fp4"
  echo "branch=focal"
  echo "audited_at_utc=$(date -u +%FT%TZ)"
  echo
  echo "== git provenance =="
  git -C "$SRC" remote -v
  git -C "$SRC" log -1 --format=fuller
  git -C "$SRC" status --short
  echo
  echo "== deviceinfo (source of build parameters) =="
  cat "$SRC/deviceinfo"
  echo
  echo "== top-level source files =="
  find "$SRC" -maxdepth 3 -type f -printf '%P\n' | sort | head -n 500
  echo
  echo "== device and build metadata references =="
  find "$SRC" -type f \( -name deviceinfo -o -name '*.mk' -o -name '*.xml' -o -name '*.conf' -o -name '*.sh' -o -name README.md \) -print0 |
    sort -z |
    xargs -0 -r grep -nEi 'halium|android|lineage|kernel|vendor|firmware|device|fp4|sm7225|sm6350|repo init|manifest' || true
} > "$OUT"

test -s "$OUT"
echo "Device source audit written to $OUT"
