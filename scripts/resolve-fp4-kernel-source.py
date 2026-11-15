#!/usr/bin/env python3
"""Read trusted upstream deviceinfo and resolve its declared kernel source."""
from pathlib import Path
import re
import sys

deviceinfo = Path(sys.argv[1] if len(sys.argv) > 1 else "upstream-fairphone-fp4/deviceinfo")
text = deviceinfo.read_text(encoding="utf-8")

def value(name: str) -> str:
    match = re.search(r"^" + re.escape(name) + r"=(['\"])(.*?)\1\s*$", text, re.M)
    if not match:
        raise SystemExit(f"Required deviceinfo field missing: {name}")
    return match.group(2).strip()

url = value("deviceinfo_kernel_source")
branch = value("deviceinfo_kernel_source_branch")
defconfig = value("deviceinfo_kernel_defconfig")
if not url.startswith(("https://gitlab.com/", "https://github.com/")):
    raise SystemExit(f"Refusing unexpected kernel source URL: {url}")
if not re.fullmatch(r"[A-Za-z0-9._/-]+", branch):
    raise SystemExit(f"Refusing unexpected kernel branch name: {branch}")
if not re.fullmatch(r"[A-Za-z0-9_. -]+", defconfig):
    raise SystemExit(f"Refusing unexpected defconfig value: {defconfig}")

print(f"kernel_source={url}")
print(f"kernel_branch={branch}")
print(f"kernel_defconfig={defconfig}")
if "GITHUB_OUTPUT" in __import__("os").environ:
    with open(__import__("os").environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as out:
        out.write(f"kernel_source={url}\n")
        out.write(f"kernel_branch={branch}\n")
        out.write(f"kernel_defconfig={defconfig}\n")
