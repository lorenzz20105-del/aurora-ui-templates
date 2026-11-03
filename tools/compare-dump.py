#!/usr/bin/env python3
"""Structural comparison between two dumps.

    python3 tools/compare-dump.py old.json new.json

Live values (memory, counters, timings) change from run to run, so this compares
the *shape* of the tree — every node's path and class — instead of the bytes.
"""

import json
import sys


def signature(path):
    with open(path) as handle:
        dump = json.load(handle)
    root = dump.get("window") or dump
    out = []
    stack = [(root, "")]
    while stack:
        node, trail = stack.pop()
        here = trail + "/" + str(node.get("Name") or node.get("class"))
        out.append(f"{here} [{node.get('class')}]")
        for child in node.get("children", []):
            stack.append((child, here))
    return sorted(out)


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    old, new = signature(sys.argv[1]), signature(sys.argv[2])
    missing = [path for path in old if path not in new]
    added = [path for path in new if path not in old]
    if missing or added:
        print("::error::the committed preview is stale — run tools/dump.py and tools/render.js")
        for path in missing[:10]:
            print("  removed:", path)
        for path in added[:10]:
            print("  added:  ", path)
        return 1
    print(f"{len(new)} nodes match the committed preview")
    return 0


if __name__ == "__main__":
    sys.exit(main())
