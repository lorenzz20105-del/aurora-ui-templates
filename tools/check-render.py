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
GALLERY = ROOT / "docs" / "index.html"
SINGLE = ROOT / "docs" / "real-ui.html"

MIN_STYLES = 10
MIN_INSTANCES = 600
MIN_PAGE_BYTES = 120_000  # the gallery embeds gzipped dumps (~170 KB total)

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
        layout = meta.get("layout") or {}
        motion = meta.get("motion") or {}
        if not layout.get("Nav"):
            problems.append("no layout blueprint")
        if not motion.get("Entry"):
            problems.append("no motion profile")
        # a style is allowed to drop the footer entirely -- that is a
        # blueprint decision, not a missing component
        required = ["Main", "TitleBar", "Content"]
        if layout.get("Footer", "status") != "none":
            required.append("Footer")
        for name in required:
            if name not in names:
                problems.append(f"no {name}")
        pages = [name for name in names if name and name.startswith("Page_")]
        if len(pages) != 5:
            problems.append(f"{len(pages)} pages")
        rails = [name for name in names if name in ("Rail", "TabBar", "Sidebar", "Dock")]
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

    print("[check-render] blueprints")
    seen = {}
    duplicate = []
    for path in dumps:
        data = json.loads(path.read_text())
        layout = (data.get("meta") or {}).get("layout") or {}
        signature = "|".join(
            str(layout.get(key, ""))
            for key in ("Nav", "Header", "Stats", "Sections", "Footer", "Decor")
        )
        if signature in seen:
            duplicate.append(f"{path.stem} == {seen[signature]}")
        else:
            seen[signature] = path.stem
    if duplicate:
        failures.append("duplicate blueprints: " + ", ".join(duplicate))
        print(f"  ✗ {len(duplicate)} duplicate blueprint(s): {', '.join(duplicate)}")
    else:
        print(f"  ✓ {len(seen)} layouts, all different")

    print("[check-render] pages")
    for page, label, minimum in ((GALLERY, "index.html (gallery)", MIN_PAGE_BYTES), (SINGLE, "real-ui.html", 150_000)):
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
                failures.append(f"{slug} missing from the gallery")
        check(all(f'"slug":"{slug}"' in html for slug in slug_names), "every template is embedded in the gallery")
        check('aria-pressed' in html and "mountAuroraWindow" in html, "gallery switcher wired to the engine")
        check("DecompressionStream" in html, "dumps are compressed and inflated on demand")
        interactive = [
            "makeInteractive",
            "function toast(",
            "aurora-toast",
            "contenteditable",
            "aurora-slider",
            "aurora-toggle",
            "onCycleStyle",
        ]
        missing = [marker for marker in interactive if marker not in html]
        check(not missing, "preview is interactive (switches, sliders, search, toasts, drag"
                           + ("" if not missing else " — missing " + ", ".join(missing)) + ")")

    version = re.search(r'Util\.Version\s*=\s*"([\d.]+)"', (ROOT / "src/UI/UILibrary/Util.luau").read_text())
    if version and GALLERY.exists():
        tag = re.search(r'<meta name="aurora-version" content="([\d.]+)">', GALLERY.read_text())
        check(bool(tag) and tag.group(1) == version.group(1), f"page reports version {version.group(1)}")
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
