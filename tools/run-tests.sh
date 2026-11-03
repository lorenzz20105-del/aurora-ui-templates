#!/usr/bin/env bash
# Aurora UI — headless smoke tests.
# Requires a `luau` CLI binary (https://github.com/luau-lang/luau/releases).
#
#   ./tools/run-tests.sh              # uses `luau` from PATH
#   LUAU=/path/to/luau ./tools/run-tests.sh
set -euo pipefail

LUAU="${LUAU:-luau}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "▸ bundling"
python3 "$ROOT/tools/bundle.py" | sed 's/^/  /'

# core = bundle minus its generated header and trailing `return Aurora`
tail -n +1 "$ROOT/dist/AuroraUI.luau" | awk 'f{print} /^--\]\]$/{f=1}' | sed '$d' > "$TMP/core.luau"

run_case () {
  local name="$1" prelude="$2" postlude="$3"
  local out="$TMP/$name.luau"
  cat "$ROOT/tools/robloxmock.luau" > "$out"
  if [ -n "$prelude" ]; then cat "$prelude" >> "$out"; fi
  cat "$TMP/core.luau" "$ROOT/tools/smoke.luau" >> "$out"
  if [ -n "$postlude" ]; then printf '\n%s\n' "$postlude" >> "$out"; fi
  "$LUAU" "$out"
}

printf '%s\n' 'local uis = game:GetService("UserInputService")' \
  'uis.TouchEnabled = true; uis.MouseEnabled = false; uis.KeyboardEnabled = false' \
  'workspace.CurrentCamera.ViewportSize = Vector2.new(667, 375)' > "$TMP/phone.luau"
printf '%s\n' 'local uis2 = game:GetService("UserInputService")' \
  'uis2.TouchEnabled = true; uis2.MouseEnabled = false' \
  'workspace.CurrentCamera.ViewportSize = Vector2.new(0, 0)' > "$TMP/zero.luau"

echo "▸ desktop"
run_case desktop "" ""
echo "▸ touch-only phone (667×375)"
run_case mobile "$TMP/phone.luau" 'print("MOBILE PASS")'
echo "▸ zero viewport"
run_case zerovp "$TMP/zero.luau" 'print("ZERO VIEWPORT PASS")'
echo "▸ preview build"
cat "$ROOT/tools/robloxmock.luau" "$ROOT/dist/AuroraPreview.luau" > "$TMP/preview.luau"
cat >> "$TMP/preview.luau" <<'LUA'

task.__flush()
assert(AuroraPreview.Window ~= nil, "preview did not mount a window")
assert(#AuroraPreview.Window.Tabs == 4, "expected 4 preview tabs, got " .. #AuroraPreview.Window.Tabs)
assert(AuroraPreview.IsMounted(), "IsMounted() returned false")
assert(AuroraPreview.Log ~= nil and #AuroraPreview.Log.Entries > 0, "event log empty")
AuroraPreview.Unmount()
assert(not AuroraPreview.IsMounted(), "Unmount() left the window alive")
local again = AuroraPreview.Mount()
assert(again ~= nil and AuroraPreview.IsMounted(), "re-mount failed")
print("PREVIEW PASS — " .. #again.Tabs .. " tabs, log lines: " .. #AuroraPreview.Log.Entries)
LUA
"$LUAU" "$TMP/preview.luau"

echo "▸ demo build"
cat "$ROOT/tools/robloxmock.luau" "$ROOT/dist/AuroraDemo.luau" > "$TMP/demo.luau"
printf '\ntask.__flush()\nprint("DEMO PASS")\n' >> "$TMP/demo.luau"
"$LUAU" "$TMP/demo.luau"
echo "✓ all suites passed"
