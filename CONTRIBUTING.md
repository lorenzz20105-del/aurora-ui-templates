# Contributing

Thanks for taking a look. This is a small, dependency-free Luau kit — the whole
test loop runs locally in a couple of seconds.

## 1. Get the tools

| Tool | Why | Install |
| --- | --- | --- |
| [Luau CLI](https://github.com/luau-lang/luau/releases) | runs the headless suite | download `luau-ubuntu.zip` / `luau-macos.zip` and put `luau` on your `PATH` |
| [Rojo](https://rojo.space) 7+ | optional, for Studio sync | `rokit add rojo-rbx/rojo` |
| Python 3.9+ | runs the bundler | already installed on most systems |

## 2. Run the suite

```bash
python3 tools/bundle.py          # rebuild dist/
./tools/run-tests.sh             # desktop + phone + zero viewport + preview + demo
```

A clean run looks like this:

```
▸ desktop
SMOKE OK — 31 icons, 3 tabs, all setters round-tripped
▸ touch-only phone (667×375)
SMOKE OK — 31 icons, 3 tabs, all setters round-tripped
MOBILE PASS
▸ zero viewport
SMOKE OK — 31 icons, 3 tabs, all setters round-tripped
ZERO VIEWPORT PASS
▸ preview build
PREVIEW PASS — 4 tabs, log lines: 1
▸ demo build
DEMO PASS
✓ all suites passed
```

No Luau binary? Point the script at one: `LUAU=/path/to/luau ./tools/run-tests.sh`.

## 3. House rules

1. **Method definitions are colon-style with an explicit `self`.**
   ```lua
   function toggle:Set(value: boolean, silent: boolean?)  -- ✅
   function toggle.Set(value)                             -- ❌ silently shifts arguments
   ```
   This was the single biggest bug class in 2.0; the whole library was colonised in 2.1.
2. **Tabs, never spaces.** Four-wide, `column_width = 110` (see `stylua.toml`).
3. **No external assets.** Icons are frames; nothing may need uploading.
4. **No globals.** Everything hangs off the module table.
5. **User callbacks go through `Util.SafeCall`** — one bad handler must not kill the UI.
6. **New tokens go in every palette** in `Theme.luau`, or theming breaks silently.
7. **Keep it usable on a phone**: nothing may assume a keyboard, a large viewport,
   or `Enum.UserInputType.MouseMovement`.

## 4. Adding things

**A component:** copy the shape of `src/UI/UILibrary/Components/Toggle.luau` —
build with `Util.*` helpers, register themables instead of hard-coding colours, then
expose it from `Section.luau` as `section:AddMyThing(config)`. Add it to `ORDER` in
`tools/bundle.py`, exercise it in `tools/smoke.luau`, and show it in
`src/UI/UILibrary/Preview.luau`.

**An icon:** add the glyph to `Icons.luau` (`Icons.List` is asserted by the tests, so
a missing draw function fails the suite) and to the browser preview's `<symbol>` sprite.

**A palette:** add a table to `Theme.Palettes` — it appears in every theme picker
automatically. Fill in *every* token.

## 5. Before you open a PR

- [ ] `./tools/run-tests.sh` is green (all five cases)
- [ ] `python3 tools/bundle.py` was run and `dist/` is committed
- [ ] `preview.html` and `docs/index.html` are identical (`cp preview.html docs/index.html`)
- [ ] Public API changes are reflected in `README.md` and `CHANGELOG.md`
- [ ] `luau-compile --binary` accepts every file you touched
- [ ] Screenshots regenerated if the look changed (see below)

## 6. Regenerating screenshots (optional)

The README images are captured from the browser preview with Playwright:

```bash
npm i -D playwright@1.49.1
npx playwright install chromium
node tools/shots.js        # writes docs/screenshot-*.jpg
```

Keep the shots at 1600×1000 @1.5× so they stay consistent.

## 7. What this project will not do

Aurora is a UI kit. It does not ship game automation, remote spam, or anything that
interacts with a game you do not own. Contributions in that direction are declined —
not because of the code, but because that is not what the library is for.
