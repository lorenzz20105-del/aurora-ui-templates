#!/usr/bin/env python3
"""
Aurora UI — dump the real GUI tree.

Runs the actual library (dist/AuroraUI.luau) + the actual demo
(src/Client/Main.client.luau) headlessly against tools/robloxmock.luau,
then serialises the window that the Luau code built to JSON.

    python3 tools/dump.py [output.json]

The JSON is consumed by tools/render.js, which turns it into
docs/real-ui.html — a preview of the real components, not a mock-up.
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUAU = os.environ.get("LUAU", "luau")

# TweenService in the mock is a no-op; the UI's entrance animations would
# otherwise leave everything at transparency 1. Apply final values immediately.
TWEEN_PATCH = """
-- tweens land on their final values immediately (headless dumping)
do
	local service = game:GetService("TweenService")
	service.Create = function(_, instance, info, props)
		local completed = {
			Connect = function()
				return { Disconnect = function() end }
			end,
		}
		return {
			Play = function()
				for key, value in pairs(props) do
					pcall(function()
						instance[key] = value
					end)
				end
			end,
			Cancel = function() end,
			Pause = function() end,
			Completed = completed,
		}
	end
end
"""


def read(path):
    with open(os.path.join(ROOT, path), "r", encoding="utf-8") as handle:
        return handle.read()


def core_library():
    """dist/AuroraUI.luau minus the generated header and `return Aurora`."""
    body = read("dist/AuroraUI.luau")
    body = body.split("--]]", 1)[1].lstrip("\n")
    return body.rsplit("return Aurora", 1)[0]


def demo_script():
    body = read("src/Client/Main.client.luau")
    body = re.sub(r"local UI = require\([^\n]*\)", "local UI = Aurora", body, count=1)
    # the demo's `local window` stays in scope for the appended dumper;
    # hand it a stable name there.
    return body + "\n\nDumpWindow = window\n"


def build_source():
    return "\n".join([
        read("tools/robloxmock.luau"),
        TWEEN_PATCH,
        core_library(),
        demo_script(),
        read("tools/dump-tree.luau"),
    ])


def style_meta(slug):
    """Pull the display metadata for a style straight out of Styles.luau."""
    path = os.path.join(ROOT, "src", "UI", "UILibrary", "Styles.luau")
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()

    order = 0
    for block in text.split('Slug = "')[1:]:
        order += 1
        if not block.startswith(slug + '"'):
            continue
        meta = {"slug": slug, "order": order}
        for key in ("Name", "Tagline", "Mood"):
            match = re.search(rf'{key} = "([^"]+)"', block)
            if match:
                meta[key.lower()] = match.group(1)
        swatch = re.search(r'makePalette\("[^"]+", "(#[0-9A-Fa-f]{6})"', block)
        if swatch:
            meta["swatch"] = swatch.group(1)
        for key in ("accent", "accent2", "panel", "surface", "text", "stroke"):
            match = re.search(rf'{key} = "(#[0-9A-Fa-f]{{6}})"', block)
            if match:
                meta[key] = match.group(1)
        # the blueprint + motion profile travel with the dump so the preview
        # can animate exactly what the Luau would animate
        for key in ("Layout", "Motion"):
            table = re.search(key + r"\s*=\s*\{(.*?)\}", block, re.S)
            if not table:
                continue
            parsed = {}
            for name, value in re.findall(r'(\w+)\s*=\s*("[^"]*"|[\d.]+)', table.group(1)):
                if value.startswith('"'):
                    parsed[name] = value.strip('"')
                else:
                    number = float(value)
                    parsed[name] = int(number) if number.is_integer() else number
            meta[key.lower()] = parsed
        return meta
    return {"slug": slug}


def styles():
    """Read the style registry so the CLI can accept slugs (and names)."""
    path = os.path.join(ROOT, "src", "UI", "UILibrary", "Styles.luau")
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    found = []
    for slug, name in re.findall(r'Slug = "([^"]+)",\s*\n\s*Name = "([^"]+)"', text):
        found.append((slug, name))
    return found


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    style = None
    for arg in sys.argv[1:]:
        if arg.startswith("--style="):
            style = arg.split("=", 1)[1]
    if not style and "--style" in sys.argv[1:]:
        index = sys.argv[1:].index("--style")
        style = sys.argv[1:][index + 1]

    out_path = args[0] if args else os.path.join(ROOT, "docs", "real-ui.json")
    source = build_source()
    if style:
        # swap the demo's template constant before it runs
        marker = 'local STYLE = "Midnight"'
        if marker not in source:
            raise SystemExit("[dump] could not find the demo style constant")
        source = source.replace(marker, f'local STYLE = "{style}"', 1)
    tmp = os.path.join(ROOT, "dist", ".dump.luau")
    with open(tmp, "w", encoding="utf-8") as handle:
        handle.write(source)

    try:
        result = subprocess.run([LUAU, tmp], capture_output=True, text=True)
    finally:
        os.remove(tmp)

    if result.returncode != 0:
        print(result.stdout[-4000:])
        print(result.stderr[-4000:], file=sys.stderr)
        raise SystemExit("[dump] the Luau run failed")

    stdout = result.stdout
    if "###DUMP###" not in stdout:
        print(stdout[-4000:])
        raise SystemExit("[dump] no dump marker in the output")

    payload = stdout.split("###DUMP###", 1)[1].split("###END###", 1)[0].strip()
    data = json.loads(payload)
    if style:
        data = {"meta": style_meta(style), "window": data["window"]}

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, separators=(",", ":"))

    nodes = 0

    def count(node):
        nonlocal nodes
        nodes += 1
        for child in node.get("children", []):
            count(child)

    count(data["window"] if "window" in data else data)
    size = os.path.getsize(out_path) / 1024
    print(f"[dump] {nodes} instances -> {out_path} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
