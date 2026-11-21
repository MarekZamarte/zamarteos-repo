#!/bin/sh
set -eu

TARGET="${1:-/usr/bin/zamarteos-mail}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Uruchom jako root: sudo sh $0 [ścieżka-do-zamarteos-mail]" >&2
    exit 1
fi

if [ ! -f "$TARGET" ]; then
    echo "Nie znaleziono aplikacji: $TARGET" >&2
    echo "Najpierw zainstaluj pakiet zamarteos-mail." >&2
    exit 1
fi

BACKUP="${TARGET}.bak-0.5-r0"
cp -p "$TARGET" "$BACKUP"

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")

old = 'SECRET_TOOL = "/usr/sbin/secret-tool"'
new = 'SECRET_TOOL = "/usr/bin/secret-tool"'
source = source.replace(old, new)

# The 0.5-r0 script contains double-escaped regex/newline sequences.
# Collapse repeated backslashes to their intended single escape.
while "\\\\" in source:
    source = source.replace("\\\\", "\\")

compile(source, str(path), "exec")
path.write_text(source, encoding="utf-8")
PY

echo "Poprawiono: $TARGET"
echo "Kopia zapasowa: $BACKUP"
echo "Kontrola składni Python: OK"
