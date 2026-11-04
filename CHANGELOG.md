# Changelog

All notable changes to Aurora UI are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.2.1] — 2026-11-04

**The window actually looks like the window.**

### Fixed

- A leftover `position: relative` on `[data-tip]` and `.motion-idle` was
  overriding the engine's `.n { position: absolute }`, so every node carrying a
  tooltip or an idle animation left the absolute flow and stacked diagonally.
  In the gallery this showed up as the title bar collapsing: the search field,
  moon, bell, minus and close buttons marched down the right edge on top of the
  stat cards, and the title overlapped its own subtitle. They are back on one
  line. `.n` is already a containing block, so the tooltip still anchors to it
  without any `position` override.
- `docs/real-ui.html` was rendered before that fix and kept the broken CSS;
  it is rebuilt from the same engine now.

### Added

- `tools/check-geometry.js` — walks all ten templates plus the single window
  and fails if any node is not `position: absolute`, if title-bar children
  overlap or drop below the bar, or if a node escapes the window. This is the
  check that would have caught the bug above; errors alone never see it.

## [4.2.0] — 2026-11-04

**The preview tells you what it is, and responds like the component does.**

### Added

- **Blueprint strip** under every template in the gallery: the pills read the
  style's `Layout` and `Motion` straight from the dump — `nav rail`,
  `header bar`, `stats cards`, `sections panels`, `footer status`, `decor glow`,
  `motion rise · glow · shimmer` — and change as you switch templates.
- **Dropdowns open.** Clicking a select row raises a real popover with the
  options for that row (camera mode, weather effects, …); picking one updates
  the value and toasts the change.
- **Keybind capture.** Click the key pill, press any key, and it is rebound
  (with a 4 s timeout that restores the old hint).
- **Tooltips** on the rail tabs and the window controls (`Close`,
  `Minimise`, `Notifications`, `Swap template`).
- **Page transitions** on tab switch and a soft **fade** at the bottom of the
  page area, so it is obvious there is more content below.

### Fixed

- Toasts no longer cover the window controls; they stack under the title bar.
- The hover hint sits above the footer instead of on top of it.

## [4.1.0] — 2026-11-03

**The preview is a working menu, not a picture.**

### Added

- **Interactivity in `tools/engine.js`** — the rendered tree is wired back up
  after it is laid out:
  - tabs switch pages (and the section rail indicator slides)
  - switches flip, with the knob travelling and the track taking the accent
  - sliders drag: knob, fill and the value pill update together
  - section headers collapse their body and rotate the chevron
  - buttons press and raise a toast built from the style's own palette
  - the search box is typable and filters the rows on the active page
  - colour swatches cycle and update the hex label
  - the title bar shoves the window, which springs back
  - close hides the window and offers "Reopen preview"; minimise collapses it
  - the moon button swaps templates in the gallery; Esc reopens a closed window
- `docs/index.html` gains a **Live preview** row plus a hover hint inside the
  window, and the interactive pass is covered by `tools/check-render.py`.

### Fixed

- Full-bleed helper frames (`Blocker`, `Overlay`, `Notifications`, `Resizer`)
  covered the window and swallowed every pointer event; they are now
  click-through, and the controls the preview actually wires up opt back in.

## [4.0.0] — 2026-11-03

**Ten design languages, not ten recolours.** A style now decides what the
window is *made of* and *how it moves*, not only what colour it is.

### Added

- **Layout blueprint** — every style carries a `Layout` table:
  `Nav` (`rail` / `sidebar` / `tabs` / `float` / `dock`), `Header` (`bar` /
  `strip` / `hero`), `Stats` (`cards` / `rows` / `chips` / `headline` /
  `dials`), `Sections` (`panels` / `cards` / `list` / `console` /
  `accordion`), `Footer` (`status` / `ticker` / `none`) and `Decor`
  (`none` / `glow` / `grid` / `scan` / `dots`).
- **Motion profile** — every style carries a `Motion` table: `Entry`
  (`rise` / `pop` / `fade` / `glitch` / `type` / `snap` / `bounce`),
  `Hover` (`glow` / `lift` / `press` / `none`), `Idle` (`shimmer` / `scan` /
  `blink` / `pulse` / `none`), plus `Duration`, `Stagger` and `Easing`.
- **`Anim.luau`** — runs the motion profile through `TweenService`:
  `Anim.Entry`, `Anim.Entrance` (staggered), `Anim.Hover`, `Anim.Idle`,
  `Anim.Adopt`. Open the window and the body staggers in with the style's own
  timing; hover and idle loops follow the same profile.
- **Two new navigation layouts** — `float` (the rail detaches into its own
  rounded panel with a shadow) and `dock` (a bottom tab bar with an accent
  hairline, for phone-shaped screens).
- **Three new header layouts** — `strip` (half-height, uppercase title, no
  subtitle), `hero` (tall header, big title, accent wash) and the default
  `bar`.
- **Footer variants** — `status` (version pill + live dot + theme chip),
  `ticker` (LIVE pill + fps/ping/nodes legend) and `none`.
- **Four new stat presentations** in `StatCard`: `rows` (label · value ·
  delta, table style), `chips` (compact pills), `headline` (one hero number
  with a fill bar) and `dials` (a 14-segment ring gauge, no assets).
- **Four new section treatments** in `Section`: `cards` (no shell, every
  control its own card), `list` (flat panel + hairline rule), `console`
  (mono, accent rule, terminal pane) and `accordion` (pill header).
- **Animated preview** — `tools/engine.js` reads `meta.motion` and
  `meta.layout` from the dump and replays the profile in CSS: staggered
  entrances, hover feedback, idle loops (shimmer / scan / blink / pulse) and
  per-style backdrop decoration (grid / scanlines / dots / glow). Honours
  `prefers-reduced-motion`.
- `tools/check-render.py` now fails on duplicate blueprints and validates the
  blueprint + motion metadata in every dump.

### Changed

- `Styles.Metrics()` derives the navigation geometry from `Layout.Nav`, so one
  field moves the whole rail.
- `Tab` understands `dock` and `float` (sized and labelled per layout).
- `Window` reads header/footer/dock heights *before* building anything, so the
  body, the pages and the chrome always agree.
- Demo, previews and every dump rebuilt for 4.0.0.

## [3.0.0] — 2026-11-03

**Ten templates, one library, one generated preview.**

### Added

- **`Styles.luau`** — ten complete design languages. A style is a palette *plus*
  geometry: rail layout (`rail` / `sidebar` / `tabs`), card treatment (`glass` /
  `elevated` / `outline` / `flat` / `brutal`), button treatment (`gradient` /
  `solid` / `outline` / `brutal`), radius scale + clamp, border weight,
  shadow strength, tab shape, header casing, row density and mono headings.
  Midnight · Daylight · Neon Grid · Terminal · Brutalist · Frost · Material You ·
  Arcade · Executive · Solar.
- `CreateWindow({ Style = "Terminal" })` — one line changes the whole menu.
  `Theme = "…"` still works for palette-only overrides.
- **Horizontal tab bar** and **labelled sidebar** rail layouts (Window + Tab),
  including a right-aligned profile chip in the tab bar.
- `Util.ApplyStyle`, `Util.M`, `Util.ShapeRadius` — every `UICorner` and
  `UIStroke` in the kit now resolves through the active style.
- `docs/templates.html` — **one preview, ten windows**, generated from the real
  instance tree: `tools/dump-all.py` → `docs/styles/<slug>.json` →
  `tools/render.js --all`.
- `tools/engine.css` / `tools/engine.js` — the layout engine extracted out of the
  single-window template so both preview pages share one implementation.
- `tools/dump-all.py`, `tools/style-shots.js`, `tools/montage.py`,
  `tools/check-render.py` (rewritten for the ten-template layout).
- Per-template screenshots in `docs/styles/` plus a contact sheet `hero.jpg`.

### Changed

- `README` is now the template gallery — all ten designs with real renders.
- Demo script takes its template from a single `local STYLE = "Midnight"`
  constant (and `_G.AURORA_DUMP_STYLE` for the dump harness).
- `Tab` measures its label for the tab-bar layout instead of relying on
  `AutomaticSize` through a full-size content frame.

### Fixed

- **Drop shadows on auto-sized cards collapsed into a sliver** — a sibling shadow
  has nothing to measure when the target is `AutomaticSize.Y`. `Util.Shadow` now
  skips auto-sized targets and Section uses a hairline stroke for its elevated
  and brutal cards.
- Tab labels in the tab bar were clipped ("HOM", "GAMEPL") because the measured
  width ignored padding; widths now use the label bounds plus a safe fallback.

## [2.3.0] — 2026-11-03

Theme of this release: **stop trusting the mock**. The window is now rendered
from the real instance tree (see "Rendered from the real code" in the README),
and that render exposed a series of layout and formatting bugs that screenshots
of a hand-written HTML mock could never show.

### Added

- **`docs/real-ui.html`** — the preview, generated from the library itself:
  `tools/dump.py` runs the real `CreateWindow` + demo against a headless Roblox
  mock, `tools/dump-tree.luau` serialises the resulting GUI tree (724 instances)
  to `docs/real-ui.json`, and `tools/render.js` lays it out in a single
  self-contained HTML file (no network, no images, no webfonts).
- `tools/real-ui.template.html` — the HTML/CSS/JS layout engine (automatic
  sizing, list/grid layout, padding, anchoring, gradients, flex fill).
- `tools/real-shots.js` — captures one screenshot per tab from the rendered page.
- `Icons.Tint` / `Icons.Mask` helpers; glyphs can now contain real "holes"
  (pieces painted pure black are re-coloured to the surface behind the icon).

### Changed

- **Icons** — `gear`, `shield` and `eye` were redrawn with the new hole support,
  so they read as a cog, an outlined shield and a lens with a pupil instead of
  three blobs. `Icons.Get` scales every glyph from one 20×20 design grid.
- `Section` headers are laid out by hand instead of with a `UIListLayout`: a
  description can now take the second line while the chevron stays pinned to the
  right edge.
- `Button` gained an internal `Content` wrapper so decorative layers (`Sheen`,
  ripple) can no longer take part in the label's list layout.
- The headless mock compares `Color3` by component (like Roblox does), which is
  what makes the icon-hole pass work in the dump.

### Fixed

- `Window`: the sidebar was `UDim2.fromOffset(L.SidebarWidth, 1)` — one pixel
  tall — so the avatar/profile chip was anchored to the top of the window.
  It now spans the full body height.
- `Window`: the footer was drawn over the page body whenever `Footer` was left at
  its default, because the body only reserved space for an explicit
  `Footer = true`. It now reserves space unless `Footer = false`.
- `Button`: the label of a block button was laid out off-screen (the Sheen and
  ripple frames were list items and consumed the row).
- `Util.TrimNumber` turned `60` into `6` (the trailing-zero trim ran on the
  integer part). Sliders formatted as `60 fps` now read `60 fps`, not `6 fps`.
- `Section`: a description was rendered inline after the chevron.
- `Tab.CreateSection` was defined as `function tab.CreateSection(config)`, so
  `tab:CreateSection{...}` passed the tab as the config table.
- `Util.List`, `Util.Corner`, `Util.Padding`, `Util.Stroke` and `Util.Gradient`
  dropped a `Parent` passed in their props table — 98 layout instances were
  missing from every window.

### Renderer notes

- The dump steps the demo's `Heartbeat` loop and then its `RenderStepped` tweens
  so count-up animations, fades and slider values are captured settled.
- Tab pages are serialised with `Visible = true` so all five pages have real
  geometry; the HTML then emulates tab switching without re-running Luau.

## [2.2.0] — 2026-11-03

### Added

- **`Preview` module** — `require(ReplicatedStorage.UI.UILibrary.Preview).Mount()`
  builds a live, interactive preview of the *real* components in your own game:
  `Gallery` (every widget, wired to a live event log), `Appearance` (palette,
  accent, scale changed at runtime), `Events` (toast lab, modals, the log) and
  `Reference` (the public API on one screen). `Preview.Unmount()` tears it down;
  `Preview.IsMounted()` reports state.
- **`dist/AuroraPreview.luau`** — the third single-file build, paste-and-run.
- `window:SetAccent(color)` / `window:SetAccent(nil)` — runtime accent override
  that derives `Accent2` and `AccentSoft` and survives palette swaps.
- `window:SetScale(multiplier)` and `window:GetScale()` — user-controlled scale,
  combined with the existing auto-fit (0.5×–1.6×).
- `window:ClearNotifications()`, plus a four-toast cap that dismisses the oldest
  card when a burst arrives.
- `section:SetCollapsed(bool)` and `section:ToggleCollapsed()` — programmatic
  collapse, in addition to clicking the header.
- Browser preview: visible keyboard focus ring, `prefers-reduced-motion` support,
  and a header hover surface that reads as clickable.

### Changed

- Section headers are clickable across the whole row, with a hover surface and a
  chevron that is always right-aligned (previously inline when a section had no
  description).
- Tab switches slide in gently instead of snapping.
- The bundler now ships **only the modules reachable from the entry point** and
  reads the version from `Util.Version` instead of a hard-coded string.
- The demo and the browser preview use neutral, game-menu copy (sprint, camera,
  nameplates) so the kit reads as a general-purpose UI library.

### Fixed

- Section chevrons no longer sit next to the title in description-less sections.
- The default page no longer clips its last row on a 900×580 window — it fits
  without scrolling.
- The demo's keybind toast still referenced the old module names.
- The preview's `gear` glyph rendered as a sunburst; it is now an actual cog.

## [2.1.0] — 2026-10-28

### Added

- `dist/` single-file builds (`AuroraUI.luau`, `AuroraDemo.luau`) produced by a
  require flattener with cycle detection and stdlib shims — no ModuleScripts needed.
- Headless Roblox mock (`tools/robloxmock.luau`) and a smoke suite that runs
  desktop, a touch-only 667×375 phone and a zero-size viewport.
- Mobile pass: auto-fit scaling down to 0.42×, a draggable floating toggle button
  (phones have no `RightShift`), 6 px touch scrollbars, tooltip suppression.

### Changed

- **Breaking:** every component method (`:Set`, `:Get`, `:SetValue`, `:SetText`,
  `:ScrollTo`, …) now takes an explicit `self`, so colon calls work everywhere.
  Before this, `slider:Set(50)` silently passed the slider as the value.
- All user callbacks are routed through `Util.SafeCall` (`pcall` + `warn`).
- Sandbox guards for `GetGuiObjectsAtPosition`, `GetTextBoundsAsync` and
  `GetUserThumbnailAsync`.

## [2.0.0] — 2026-10-20

### Added

- Four palettes (`Midnight`, `Nebula`, `Emerald`, `Daylight`) driven by a live
  themable registry — swapping a palette repaints every open control instantly.
- Global search that indexes every control, jumps to its tab and flashes it.
- Sparkline stat cards with animated counters and delta pills.
- Searchable single- and multi-select dropdowns that flip upward near the screen edge.
- Full keybind recorder with modifier display, plus colour picker with HSV area,
  hue rail, hex input and presets.
- Window resize grip, minimise animation, optional `Lighting.BlurEffect`.
- Zero-asset vector icon set (31 glyphs) with an asset-id override table.

## [1.0.0] — 2026-10-11

- Initial release: window shell, rail, sections, rows, toggles, sliders, buttons.
