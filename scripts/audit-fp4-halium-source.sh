#!/usr/bin/env bash
set -euo pipefail

SRC="${1:?Usage: audit-fp4-halium-source.sh /path/to/fairphone-fp4}"
OUT="${2:-hybrid-source-audit.txt}"
SRC="$(cd "$SRC" && pwd)"

{
  echo "ZamarteOS Hybrid FP4 — source audit"
  echo "project=https://gitlab.com/ubports/porting/reference-device-ports/android11/fairphone-4/fairphone-fp4"
  echo "branch=focal"
  echo "audited_at_utc=$(date -u +%FT%TZ)"
  echo
  echo "== git =="
  git -C "$SRC" remote -v
  git -C "$SRC" rev-parse HEAD
  git -C "$SRC" status --short
  echo
  echo "== top-level =="
  find "$SRC" -maxdepth 2 -type f -printf '%P\n' | sort | head -n 300
  echo
  echo "== device and build metadata =="
  find "$SRC" -type f \( -name deviceinfo -o -name '*.mk' -o -name '*.xml' -o -name '*.conf' -o -name '*.sh' -o -name README.md \) -print0 |
    sort -z |
    xargs -0 -r grep -nEi 'halium|android|lineage|kernel|vendor|firmware|device|fp4|sm7225|sm6350|repo init|manifest' || true
} > "$OUT"

test -s "$OUT"
echo "Source audit written to $OUT"
