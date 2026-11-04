#!/usr/bin/env python3
"""Regenerate the template gallery + blueprint matrix in README.md.

Reads docs/styles/*.json (the captured dumps) and rewrites everything between
the <!-- styles:start --> / <!-- styles:end --> markers, so adding a style to
Styles.luau and running the pipeline updates the README instead of leaving it
lying about how many templates there are.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLES_DIR = os.path.join(ROOT, "docs", "styles")
README = os.path.join(ROOT, "README.md")

NAV = {"rail": "icon rail", "sidebar": "labelled sidebar", "tabs": "top tab bar",
       "float": "floating rail", "dock": "bottom dock"}
HEADER = {"bar": "bar", "strip": "strip", "hero": "hero"}
STATS = {"cards": "3 cards + sparklines", "headline": "hero headline + fill bar",
         "rows": "table rows", "chips": "capsules", "dials": "ring dials"}
SECTIONS = {"panels": "glass panels", "cards": "free cards", "list": "hairline list",
            "console": "console panes", "accordion": "pill accordion"}
FOOTER = {"status": "status", "ticker": "ticker", "none": "—"}
DECOR = {"none": "—", "glow": "glow", "grid": "grid", "scan": "scanlines", "dots": "dots"}

WORDS = {24: "twenty-four", 23: "twenty-three", 22: "twenty-two", 21: "twenty-one",
         20: "twenty", 19: "nineteen", 18: "eighteen", 17: "seventeen", 16: "sixteen",
         15: "fifteen", 14: "fourteen", 13: "thirteen", 12: "twelve", 11: "eleven", 10: "ten"}


def load():
    styles = []
    for name in sorted(os.listdir(STYLES_DIR)):
        if not name.endswith(".json"):
            continue
        meta = json.load(open(os.path.join(STYLES_DIR, name)))["meta"]
        styles.append(meta)
    styles.sort(key=lambda m: m.get("order", 0))
    return styles


def gallery(styles):
    cells = []
    for meta in styles:
        alt = meta["name"]
        cells.append(
            f"| ![{alt}](docs/styles/{meta['slug']}.jpg) |"
        )
    rows = []
    per_row = 3
    for i in range(0, len(styles), per_row):
        chunk = styles[i:i + per_row]
        imgs = " ".join(f"![{m['name']}](docs/styles/{m['slug']}.jpg) |" for m in chunk)
        caps = " ".join(f"**{m['name']}** · `{m['slug']}`<br>{m['tagline']} |" for m in chunk)
        rows.append("| " + imgs + ("" if len(chunk) == per_row else " |" * (per_row - len(chunk))))
        rows.append("| " + caps + ("" if len(chunk) == per_row else " |" * (per_row - len(chunk))))
    head = "| | | |\n| --- | --- | --- |"
    return head + "\n" + "\n".join(rows)


def matrix(styles):
    out = ["| Style | Navigation | Header | Numbers | Sections | Footer | Decor | Motion |",
           "| --- | --- | --- | --- | --- | --- | --- | --- |"]
    for meta in styles:
        lay = meta.get("layout") or {}
        mot = meta.get("motion") or {}
        motion = " · ".join(x for x in (mot.get("Entry"), mot.get("Hover") if mot.get("Hover") != "none" else None,
                                        mot.get("Idle") if mot.get("Idle") not in (None, "none") else None) if x)
        out.append("| **%s** | %s | %s | %s | %s | %s | %s | %s |" % (
            meta["name"],
            NAV.get(lay.get("Nav"), lay.get("Nav")),
            HEADER.get(lay.get("Header"), lay.get("Header")),
            STATS.get(lay.get("Stats"), lay.get("Stats")),
            SECTIONS.get(lay.get("Sections"), lay.get("Sections")),
            FOOTER.get(lay.get("Footer"), lay.get("Footer")),
            DECOR.get(lay.get("Decor"), lay.get("Decor")),
            motion,
        ))
    return "\n".join(out)


def main():
    styles = load()
    if not styles:
        sys.exit("[readme-styles] no dumps — run tools/dump-all.py first")
    readme = open(README).read()
    count = len(styles)
    block = (
        f"## The {WORDS.get(count, str(count))} templates\n\n"
        + gallery(styles)
        + "\n\n### The blueprint matrix\n\n"
        "Each row is what you get from `CreateWindow({ Style = \"…\" })`. No two rows are\n"
        "the same, and none of this is a recolour.\n\n"
        + matrix(styles)
        + "\n"
    )
    start, end = "<!-- styles:start -->", "<!-- styles:end -->"
    if start not in readme or end not in readme:
        sys.exit("[readme-styles] README is missing the styles markers")
    head, rest = readme.split(start, 1)
    _, tail = rest.split(end, 1)
    readme = head + start + "\n" + block + "\n" + end + tail
    open(README, "w").write(readme)
    print(f"[readme-styles] {count} templates written")


if __name__ == "__main__":
    main()
