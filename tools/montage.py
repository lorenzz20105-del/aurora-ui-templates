#!/usr/bin/env python3
"""Builds docs/styles/hero.jpg — the ten templates as one contact sheet.

    python3 tools/montage.py

Requires Pillow (`pip install pillow`). Run after tools/style-shots.js.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLES = os.path.join(ROOT, "docs", "styles")

ORDER = [
    "midnight", "daylight", "neon", "terminal", "brutalist",
    "frost", "material", "arcade", "executive", "solar",
]

COLUMNS = 2
TILE_WIDTH = 760
GAP = 18
BACKDROP = (7, 9, 15)


def main():
    try:
        from PIL import Image
    except ImportError:
        print("Pillow is required: pip install pillow")
        return 1

    tiles = []
    for slug in ORDER:
        path = os.path.join(STYLES, f"{slug}.jpg")
        if not os.path.exists(path):
            print(f"missing {path} — run node tools/style-shots.js first")
            return 1
        image = Image.open(path).convert("RGB")
        ratio = TILE_WIDTH / image.width
        tiles.append(image.resize((TILE_WIDTH, int(image.height * ratio)), Image.LANCZOS))

    tile_height = max(tile.height for tile in tiles)
    rows = (len(tiles) + COLUMNS - 1) // COLUMNS
    width = COLUMNS * TILE_WIDTH + (COLUMNS + 1) * GAP
    height = rows * tile_height + (rows + 1) * GAP

    sheet = Image.new("RGB", (width, height), BACKDROP)
    for index, tile in enumerate(tiles):
        column = index % COLUMNS
        row = index // COLUMNS
        x = GAP + column * (TILE_WIDTH + GAP)
        y = GAP + row * (tile_height + GAP)
        sheet.paste(tile, (x, y))

    out = os.path.join(STYLES, "hero.jpg")
    sheet.save(out, quality=88, optimize=True)
    print(f"[montage] {out} ({width}x{height}, {os.path.getsize(out) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
