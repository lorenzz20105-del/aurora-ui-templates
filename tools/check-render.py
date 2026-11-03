#!/usr/bin/env python3
"""Sanity checks for the generated previews.

    python3 tools/check-render.py

Verifies that every dump in docs/styles/ is a real capture of a window (not a
stub) and that docs/templates.html is one self-contained page built from them.
Run it after

    python3 tools/bundle.py
    LUAU=/path/to/luau python3 tools/dump-all.py
    node tools/render.js --all
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
STYLES_DIR = ROOT / "docs" / "styles"
GALLERY = ROOT / "docs" / "templates.html"
SINGLE = ROOT / "docs" / "real-ui.html"

MIN_STYLES = 10
MIN_INSTANCES = 600
MIN_PAGE_BYTES = 400_000

failures = []


def check(condition, message):
    if condition:
        print(f"  ✓ {message}")
    else:
        failures.append(message)
        print(f"  ✗ {message}")


def walk(node):
    yield node
    for child in node.get("children", []):
        yield from walk(child)


def main():
    if not STYLES_DIR.exists():
        print("docs/styles/ is missing — run tools/dump-all.py first")
        return 1

    dumps = sorted(STYLES_DIR.glob("*.json"))
    print(f"[check-render] {len(dumps)} style dump(s)")
    check(len(dumps) >= MIN_STYLES, f"{len(dumps)} templates captured (>= {MIN_STYLES})")

    slug_names = set()
    for path in dumps:
        data = json.loads(path.read_text())
        meta = data.get("meta") or {}
        window = data.get("window") or data
        nodes = list(walk(window))
        names = {node.get("Name") for node in nodes}
        slug_names.add(path.stem)

        problems = []
        if len(nodes) < MIN_INSTANCES:
            problems.append(f"only {len(nodes)} instances")
        if not meta.get("name"):
            problems.append("no style metadata")
        for required in ("Main", "TitleBar", "Content", "Footer"):
            if required not in names:
                problems.append(f"no {required}")
        pages = [name for name in names if name and name.startswith("Page_")]
        if len(pages) != 5:
            problems.append(f"{len(pages)} pages")
        rails = [name for name in names if name in ("Rail", "TabBar", "Sidebar")]
        if len(rails) < 2:
            problems.append("no rail geometry")
        texts = [n.get("Text") for n in nodes if n.get("class") in ("TextLabel", "TextButton", "TextBox")]
        if sum(1 for text in texts if text) < 30:
            problems.append("too little text")

        if problems:
            failures.append(f"{path.name}: {', '.join(problems)}")
            print(f"  ✗ {path.name}: {', '.join(problems)}")
        else:
            print(f"  ✓ {path.stem:10s} {len(nodes)} instances · {len(pages)} pages · {meta.get('mood', '')}")

    print("[check-render] pages")
    for page, label, minimum in ((GALLERY, "templates.html", MIN_PAGE_BYTES), (SINGLE, "real-ui.html", 150_000)):
        if not page.exists():
            failures.append(f"{label} missing")
            print(f"  ✗ {label} missing")
            continue
        html = page.read_text()
        external = re.findall(r'(?:src|href)="(?:https?:)?//[^"]+"', html)
        ok = len(html) >= minimum and not external and "@import" not in html
        check(ok, f"{label} ({len(html) // 1024} KB, {len(external)} external refs)")

    if GALLERY.exists():
        html = GALLERY.read_text()
        for slug in sorted(slug_names):
            if f'"slug":"{slug}"' not in html:
                failures.append(f"{slug} missing from templates.html")
        check(all(f'"slug":"{slug}"' in html for slug in slug_names), "every template is embedded in the gallery")
        check('aria-pressed' in html and "mountAuroraWindow" in html, "gallery switcher wired to the engine")

    version = re.search(r'Util\.Version\s*=\s*"([\d.]+)"', (ROOT / "src/UI/UILibrary/Util.luau").read_text())
    if version and GALLERY.exists():
        check(version.group(1) in GALLERY.read_text(), f"page reports version {version.group(1)}")
        changelog = (ROOT / "CHANGELOG.md").read_text()
        check(f"## [{version.group(1)}]" in changelog, f"CHANGELOG has a {version.group(1)} section")

    print()
    if failures:
        print(f"{len(failures)} check(s) failed")
        return 1
    print("all render checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
