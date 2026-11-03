# Aurora UI — Templates

**Ten complete design languages for Roblox, built on one component library.**
Same API, same widgets, same demo script — swap one line and the whole menu
changes its palette, radius, borders, card treatment, button treatment, tab
geometry and typography.

[![License: MIT](https://img.shields.io/badge/license-MIT-7C5CFF.svg)](LICENSE)
[![Luau](https://img.shields.io/badge/language-Luau-00A2FF.svg)](https://luau.org)
[![Rojo](https://img.shields.io/badge/Rojo-7.x-FF4757.svg)](https://rojo.space)
[![Version](https://img.shields.io/badge/version-3.0.0-7C5CFF.svg)](CHANGELOG.md)
[![Templates](https://img.shields.io/badge/templates-10-22D3EE.svg)](docs/templates.html)
[![Tests](https://img.shields.io/badge/tests-5%20suites%20passing-34D399.svg)](.github/workflows/tests.yml)

### ▶ **[Open the live preview — all ten templates, rendered from the real Luau](docs/templates.html)**

![All ten Aurora templates](docs/styles/hero.jpg)

Every window in this repo is a screenshot of **the Luau itself**. `tools/dump.py`
runs the real `CreateWindow(...)` call and the real demo inside a headless Roblox
mock, and `tools/engine.js` lays the captured instance tree out in HTML. No
mock-ups, no hand-drawn approximations — if a border is 2 px in the picture, it is
2 px because `Styles.luau` says so.

```lua
local UI = require(game.ReplicatedStorage.UI.UILibrary)

local window = UI.CreateWindow({
    Title = "Aurora",
    Style = "Neon Grid",   -- ← the only line that changes
})
```

---

## The ten templates

| | | |
| --- | --- | --- |
| ![Midnight](docs/styles/midnight.jpg) | ![Daylight](docs/styles/daylight.jpg) | ![Neon Grid](docs/styles/neon.jpg) |
| **Midnight** · `midnight`<br>Glass panels, indigo→cyan gradient, icon rail | **Daylight** · `daylight`<br>Bright surfaces, hairline cards, friendly | **Neon Grid** · `neon`<br>Cyberpunk: outline cards, magenta glow |
| ![Terminal](docs/styles/terminal.jpg) | ![Brutalist](docs/styles/brutalist.jpg) | ![Frost](docs/styles/frost.jpg) |
| **Terminal** · `terminal`<br>Phosphor green, monospace, square and dense | **Brutalist** · `brutalist`<br>Paper white, 2 px black borders, zero radius | **Frost** · `frost`<br>Frosted pastel glass, very round |
| ![Material You](docs/styles/material.jpg) | ![Arcade](docs/styles/arcade.jpg) | ![Executive](docs/styles/executive.jpg) |
| **Material You** · `material`<br>Soft tonal surfaces, pill controls | **Arcade** · `arcade`<br>Retro cabinet: deep purple, hot pink | **Executive** · `executive`<br>Quiet corporate greys, navy accent |
| ![Solar](docs/styles/solar.jpg) | **What changes between them** | |
| **Solar** · `solar`<br>Warm sand and amber, sunlit gradients | Not just colour: each style sets `Rail` (icon rail / labelled sidebar / top tab bar), `Card` (glass / elevated / outline / flat / brutal), `Button` (gradient / solid / outline / brutal), radius scale and clamp, border weight, shadow strength, header casing, row density. | |

---

## How a style is defined

One table in [`src/UI/UILibrary/Styles.luau`](src/UI/UILibrary/Styles.luau):

```lua
{
    Slug = "terminal",
    Name = "Terminal",
    Tagline = "Phosphor green on black, monospace, squared-off and dense",
    Mood = "Dark · Mono · Flat",

    Palette = makePalette("Terminal", "#3DFF88", {
        backdrop = "#020603", panel = "#05090A", surface = "#08110C",
        text = "#B8FFD0", textMuted = "#5F9E76",
        accent = "#3DFF88", accent2 = "#9BFF57", accentSoft = "#0D2A19",
        stroke = "#1C4B31", strokeBright = "#3DFF88",
    }),

    Metrics = {
        Rail = "sidebar", RailWidth = 178,   -- wide labelled column
        Card = "flat", Button = "outline",
        RadiusScale = 0, MaxRadius = 0,      -- perfectly square
        TabShape = "square", HeaderCase = "upper",
        BorderAlphaScale = 0.5, Shadow = 0, Density = 0.94, Mono = true,
    },
}
```

### Metrics reference

| Key | Values | What it does |
| --- | --- | --- |
| `Rail` | `rail` · `sidebar` · `tabs` | 74 px icon column, wide labelled column, or a horizontal tab bar |
| `RailWidth` | number | width of the labelled sidebar |
| `Card` | `glass` · `elevated` · `outline` · `flat` · `brutal` | section card treatment |
| `Button` | `gradient` · `solid` · `outline` · `brutal` | primary/block button treatment |
| `TabShape` | `rounded` · `square` · `pill` | rail button shape |
| `HeaderCase` | `normal` · `upper` | section titles and tab labels |
| `RadiusScale` / `MaxRadius` | number / number | multiply, then clamp **every** corner in the kit |
| `BorderScale` / `BorderAlphaScale` | number / number | compress or thicken every `UIStroke` |
| `Shadow` | number | multiplies drop-shadow strength |
| `Density` | number | row height multiplier |
| `Glow` / `Mono` | boolean | accent halo on active elements / monospace headings |

Styles are registered with the theme system on load, so `window:SetTheme("Solar")`
still works for live palette swaps; geometry is baked when the window is built, so
rebuild the window to change the *shape*.

### Adding your own

Drop a table into `Styles.All` (palette + metrics), then:

```bash
python3 tools/bundle.py && node tools/render.js --all
```

It appears in the preview chips, the docs and the README generator with no other
edits.

---

## The preview

There is exactly **one** preview page — [`docs/templates.html`](docs/templates.html) —
and it is generated, not drawn:

```bash
python3 tools/bundle.py                      # flatten src/ → dist/AuroraUI.luau
LUAU=/path/to/luau python3 tools/dump-all.py  # build all 10 windows headlessly
node tools/render.js --all                    # → docs/templates.html
node tools/style-shots.js                     # → docs/styles/*.jpg for this README
```

1. `tools/dump-all.py` walks the registry and runs the **real** library + demo once
   per style inside `tools/robloxmock.luau` (a headless stub of `Instance.new`,
   `TweenService`, `RunService`, `UDim2`, `UIScale`, attributes …).
2. `tools/dump-tree.luau` serialises every GUI instance with its properties and its
   `UIListLayout` / `UIGridLayout` / `UIPadding` / `UICorner` / `UIStroke` /
   `UIGradient` / `UIFlexItem` children → `docs/styles/<slug>.json`
   (7,293 instances across the ten templates).
3. `tools/engine.js` re-implements the parts of Roblox's layout engine that matter
   (automatic sizing, list/grid layout, padding, anchors, rotation, gradients,
   strokes, text metrics) and paints the tree into one self-contained HTML file —
   no network, no images, no webfonts. Tab switching is wired back to the dumped
   geometry, so the rail, tab bar and sidebar all work.

Because the renderer is honest, it doubles as a regression test: it is what caught
a 1 px sidebar, a footer overlapping the page body, buttons whose labels were laid
out off-screen, section descriptions drifting into the header row, drop shadows on
auto-sized cards collapsing to a sliver, and `Util.TrimNumber` turning `60` into `6`.

---

## Install

### Option A — Rojo (recommended)

```bash
git clone <this repo> aurora-ui && cd aurora-ui
rojo serve            # then connect from Studio
```

`default.project.json` maps `ReplicatedStorage.UI` ← `src/UI` and
`StarterPlayerScripts.Main` ← `src/Client/Main.client.luau`. Press **Right Shift**.

### Option B — single file (executors, mobile, Delta)

`dist/` holds the whole library flattened into one script — no `ModuleScripts`, no
`require`, no asset ids:

| File | Lines | What it does |
| --- | --- | --- |
| `dist/AuroraUI.luau` | 6,994 | Library only — returns the `Aurora` table (includes `Styles`) |
| `dist/AuroraDemo.luau` | 7,645 | Library **+** the 5-tab demo — builds the menu on execution |
| `dist/AuroraPreview.luau` | 7,631 | Library **+** `Preview` — mounts the live component preview |

To choose a template in a single-file build, edit the one constant at the top of
the demo:

```lua
local STYLE = "Midnight"   -- midnight · daylight · neon · terminal · brutalist
                           -- frost · material · arcade · executive · solar
```

---

## Window API

```lua
local window = UI.CreateWindow({
    Title = "Aurora",
    Subtitle = "v" .. UI.Version,
    Icon = "sparkle",
    Style = "Midnight",       -- template: palette + geometry
    Theme = "Daylight",       -- optional palette-only override
    Scale = 1,                -- 0.5–1.6, auto-fits the viewport
    Search = true,            -- title-bar search
    Footer = true,
    MobileButton = true,      -- on-screen toggle for touch devices
    Keybind = Enum.KeyCode.RightShift,
    Status = "Connected  •  62 ms",
})
```

| Method | Purpose |
| --- | --- |
| `window:CreateTab{ Name, Icon, Badge }` | add a tab (rail button, labelled row or tab-bar pill depending on the style) |
| `window:SelectTab(tab)` | switch pages |
| `window:Notify{ Title, Body, Type, Icon, Duration }` | toast (max 4, oldest is retired) |
| `window:SetTheme(name)` / `window:SetAccent(color)` | live palette change |
| `window:SetScale(n)` / `window:GetScale()` | user scaling |
| `window:SetSubtitle(text)` / `window:ClearNotifications()` | small runtime helpers |
| `window:Modal{ Title, Body, Actions }` | confirm dialog |
| `tab:CreateSection{ Name, Icon, Description, Badge }` | card that groups rows |
| `tab:AddStats{ … }` / `tab:AddGrid{ Columns }` / `tab:AddSpacer(h)` | layout helpers |
| `section:AddToggle/AddSlider/AddDropdown/AddTextBox/AddKeybind/AddColorPicker/AddButton` | controls |
| `section:SetCollapsed(bool)` / `ToggleCollapsed()` / `SetVisible(bool)` | card state |

---

## What is in the box

| | |
| --- | --- |
| Source | 8,169 lines of Luau across 21 files |
| Templates | 10 styles, 4 palettes shipped, unlimited via `Styles.All` |
| Components | 14 widgets, 31 vector icons drawn from Frames (zero assets) |
| Layouts | icon rail, labelled sidebar, horizontal tab bar |
| Card treatments | glass, elevated, outline, flat, brutal |
| Tests | 5 headless suites: desktop, touch-only phone, zero viewport, preview, demo |
| Preview | one self-contained page, 10 windows, 7,293 captured instances |
| Runtime deps | none; build needs Luau CLI + Python 3 (+ Node for the preview) |

---

## Repository layout

```
dist/                        # generated by tools/bundle.py — commit it
├── AuroraUI.luau            # single-file library   (returns Aurora)
├── AuroraDemo.luau          # library + demo        (runs)
└── AuroraPreview.luau       # library + preview     (runs)

docs/
├── templates.html           # THE preview: all ten templates, one page
├── real-ui.html             # the same engine, single window (Midnight)
├── styles/                  # per-template dumps (.json) and shots (.jpg)
└── index.html               # hand-authored design mock (legacy reference)

src/
├── Client/Main.client.luau  # demo: 5 tabs, live stats, every component
└── UI/UILibrary/
    ├── init.luau            # public API (CreateWindow, SetTheme, Format …)
    ├── Styles.luau          # ← the ten templates
    ├── Theme.luau           # palettes, type scale, spacing, layout constants
    ├── Util.luau            # instance helpers, tweens, drag, theming, style metrics
    ├── Icons.luau           # 31 vector icons + asset override table
    ├── Preview.luau         # in-engine live preview module
    └── Components/          # Window, Tab, Section, Row, Button, Toggle, Slider,
                             # Dropdown, TextBox, Keybind, ColorPicker, StatCard,
                             # Notification, Tooltip

tools/
├── bundle.py                # flattens the module tree, cycle-checks requires
├── run-tests.sh             # the five suites
├── smoke.luau               # builds every component, round-trips setters
├── robloxmock.luau          # headless Roblox API mock (tests + dump)
├── dump.py / dump-all.py    # run the library headlessly → docs/**/*.json
├── dump-tree.luau           # serialises the instance tree
├── engine.css / engine.js   # the layout engine used by both preview pages
├── render.js                # dump + engine → docs/real-ui.html | templates.html
└── style-shots.js           # per-template screenshots (docs/styles/*.jpg)
```

---

## Testing

```bash
LUAU=/path/to/luau ./tools/run-tests.sh

▸ desktop                SMOKE OK — 31 icons, 3 tabs, all setters round-tripped
▸ touch-only phone       MOBILE PASS
▸ zero viewport          ZERO VIEWPORT PASS
▸ preview build          PREVIEW PASS — 4 tabs, log lines: 1
▸ demo build             DEMO PASS
✓ all suites passed
```

The preview has its own checks:

```bash
python3 tools/check-render.py          # structure of the dumps + the page
python3 tools/compare-dump.py a.json b.json   # structural drift, ignores live numbers
```

CI runs the suites, a `luau-compile` sweep, a check that `dist/` matches the
sources, and a `render` job that rebuilds all ten dumps and the preview from
scratch.

---

## Mobile & executors

- Every control is touch-friendly (44 px targets, no hover-only affordances) and
  the window auto-scales from 0.5× to 1.6× to fit the viewport.
- `MobileButton` adds an on-screen toggle; the keybind is optional.
- No `require` of uploaded assets, no `rbxassetid://`, no `HttpService` — the whole
  kit is Frames, UICorners, UIStrokes and TextLabels, which is why it survives
  constrained executors (Delta and friends) and phones.
- Single-file builds in `dist/` are the paste-and-run path.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). New template? Add a `Styles.All` entry,
run `python3 tools/dump-all.py && node tools/render.js --all`, and the preview,
the README table and the screenshots pick it up.

## License

MIT — see [LICENSE](LICENSE).
