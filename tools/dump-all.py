#!/usr/bin/env python3
"""Dump every style in the registry.

    LUAU=/path/to/luau python3 tools/dump-all.py

Writes docs/styles/<slug>.json (one GUI tree per template) and refreshes
docs/real-ui.json (the Midnight/Midnight-default window used by the single
window preview).
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUAU = os.environ.get("LUAU", "luau")
STYLES_DIR = os.path.join(ROOT, "docs", "styles")


def registry():
    path = os.path.join(ROOT, "src", "UI", "UILibrary", "Styles.luau")
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    return re.findall(r'Slug = "([^"]+)",\s*\n\s*Name = "([^"]+)"', text)


def main():
    styles = registry()
    if not styles:
        raise SystemExit("[dump-all] no styles found in Styles.luau")

    os.makedirs(STYLES_DIR, exist_ok=True)
    failures = []

    for slug, name in styles:
        out = os.path.join(STYLES_DIR, f"{slug}.json")
        result = subprocess.run(
            [sys.executable, os.path.join(ROOT, "tools", "dump.py"), f"--style={slug}", out],
            cwd=ROOT,
            capture_output=True,
            text=True,
            env={**os.environ, "LUAU": LUAU},
        )
        line = (result.stdout or "").strip().splitlines()
        if result.returncode != 0:
            failures.append((slug, (result.stdout or "")[-600:] + (result.stderr or "")[-600:]))
            print(f"  ✗ {slug}")
            continue
        print(f"  ✓ {slug:10s} {line[-1] if line else ''}")

    # the single-window preview keeps using Midnight
    if not failures:
        midnight = os.path.join(STYLES_DIR, "midnight.json")
        with open(midnight, "r", encoding="utf-8") as handle:
            data = json.load(handle)
        with open(os.path.join(ROOT, "docs", "real-ui.json"), "w", encoding="utf-8") as handle:
            json.dump(data, handle, separators=(",", ":"))
        print("  ✓ docs/real-ui.json refreshed from midnight.json")

    if failures:
        for slug, log in failures:
            print(f"\n[{slug}]\n{log}")
        raise SystemExit(f"[dump-all] {len(failures)} style(s) failed")

    print(f"[dump-all] {len(styles)} styles captured")


if __name__ == "__main__":
    main()
