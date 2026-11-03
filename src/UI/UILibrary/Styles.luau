--[[
	Aurora UI  •  Styles.luau
	------------------------------------------------------------------
	Ten complete design languages built on one component library.

	A *palette* only changes colours. A *style* changes colour **and**
	form: corner radius, border weight, card treatment, button
	treatment, rail geometry and typography. Pass `Style = "Terminal"`
	to CreateWindow and every component follows.

		UILibrary.CreateWindow({ Style = "Neon Grid" })

	Adding your own style is one table — put it in Styles.All and it
	shows up in the picker, the preview and the docs automatically.
--]]

local Theme = require(script.Parent.Theme)

local Styles = {}

local fromHex = Color3.fromHex

------------------------------------------------------------------
-- Palette scaffolding
------------------------------------------------------------------

--- Builds a full palette from the 22 tokens the components read, so a
--- style only has to spell out what makes it different.
local function makePalette(name, swatch, tokens)
	return {
		Name = name,
		Swatch = fromHex(swatch),
		Backdrop = fromHex(tokens.backdrop),
		Panel = fromHex(tokens.panel),
		PanelSolid = fromHex(tokens.panelSolid or tokens.panel),
		Surface = fromHex(tokens.surface),
		SurfaceHover = fromHex(tokens.surfaceHover),
		SurfaceActive = fromHex(tokens.surfaceActive),
		Elevated = fromHex(tokens.elevated or tokens.surface),

		Stroke = fromHex(tokens.stroke),
		StrokeSoft = fromHex(tokens.strokeSoft or tokens.stroke),
		StrokeBright = fromHex(tokens.strokeBright or tokens.stroke),

		Text = fromHex(tokens.text),
		TextMuted = fromHex(tokens.textMuted),
		TextDim = fromHex(tokens.textDim or tokens.textMuted),
		TextInverse = fromHex(tokens.textInverse or "#FFFFFF"),

		Accent = fromHex(tokens.accent),
		Accent2 = fromHex(tokens.accent2 or tokens.accent),
		AccentSoft = fromHex(tokens.accentSoft),
		AccentText = fromHex(tokens.accentText or "#FFFFFF"),

		Success = fromHex(tokens.success or "#34D399"),
		Warning = fromHex(tokens.warning or "#FBBF24"),
		Danger = fromHex(tokens.danger or "#FB7185"),
		Info = fromHex(tokens.info or "#60A5FA"),

		Shadow = fromHex(tokens.shadow or "#000000"),
		Glass = tokens.glass or 0,
	}
end

------------------------------------------------------------------
-- Metric defaults — the "Midnight" look, i.e. what the library did
-- before styles existed. Anything a style omits falls back to this.
------------------------------------------------------------------

-- A style is three things: a palette, a *layout blueprint* and a *motion
-- profile*. The blueprint decides what the window is made of -- where the
-- navigation lives, how the numbers are presented, what a section looks
-- like, whether there is a footer, what decorates the backdrop. The motion
-- profile decides how it enters, how it reacts and what it does while idle.
-- Change the blueprint and the same components become a different app.

-- Layout: Nav     rail | sidebar | tabs | float | dock
--         Header  bar | strip | hero
--         Stats   cards | headline | rows | chips | dials
--         Sections panels | cards | list | console | accordion
--         Footer  status | ticker | none
--         Decor   none | glow | grid | scan | dots
Styles.LayoutDefaults = {
	Nav = "rail",
	NavWidth = 74,
	Header = "bar",
	Stats = "cards",
	Sections = "panels",
	Footer = "status",
	Decor = "none",
}

-- Motion: Entry rise | pop | fade | glitch | type | snap | bounce
--         Hover glow | lift | press | none
--         Idle  shimmer | scan | blink | pulse | none
Styles.MotionDefaults = {
	Entry = "rise",
	Hover = "lift",
	Idle = "none",
	Duration = 0.3,
	Stagger = 0.03,
	Easing = "Quad",
}

Styles.Defaults = {
	Rail = "rail",          -- rail | tabs | sidebar
	RailWidth = 74,         -- ignored by "tabs"
	Card = "glass",         -- glass | flat | outline | brutal | elevated
	Button = "gradient",    -- gradient | solid | outline | brutal
	TabShape = "rounded",   -- rounded | square | pill
	HeaderCase = "normal",  -- normal | upper
	Density = 1,            -- row height multiplier
	RadiusScale = 1,        -- multiplies every UICorner in the kit
	MaxRadius = 999,        -- clamps it (0 = perfectly square)
	BorderScale = 1,        -- multiplies every UIStroke thickness
	BorderAlphaScale = 1,   -- multiplies stroke transparency
	Shadow = 1,             -- multiplies every drop shadow
	Glow = false,           -- accent halo on the active tab/buttons
	Mono = false,           -- monospace numbers and headings
	SectionGap = 10,
}

------------------------------------------------------------------
-- The ten styles
------------------------------------------------------------------

Styles.All = {

	----------------------------------------------------------------
	{
		Slug = "midnight",
		Name = "Midnight",
		Tagline = "Glass panels, indigo-to-cyan gradient, icon rail",
		Mood = "Dark · Glass · Gradient",
		Palette = makePalette("Midnight", "#7C5CFF", {
			backdrop = "#05060A", panel = "#0F121B", surface = "#161A26",
			surfaceHover = "#1C2130", surfaceActive = "#232A3C", elevated = "#1B2030",
			stroke = "#252C3E", strokeSoft = "#1A1F2D", strokeBright = "#39435C",
			text = "#EAEEF9", textMuted = "#8B95AE", textDim = "#5A6379",
			accent = "#7C5CFF", accent2 = "#22D3EE", accentSoft = "#2A2350",
			success = "#34D399", warning = "#FBBF24", danger = "#FB7185", info = "#60A5FA",
			glass = 0.04,
		}),
		Metrics = {
			Rail = "rail", Card = "glass", Button = "gradient",
			RadiusScale = 1, MaxRadius = 20, TabShape = "rounded",
			Shadow = 1, Glow = true,
		},
		Layout = { Nav = "rail", Header = "bar", Stats = "cards", Sections = "panels", Footer = "status", Decor = "glow", NavWidth = 74 },
		Motion = { Entry = "rise", Hover = "glow", Idle = "shimmer", Duration = 0.30, Stagger = 0.035, Easing = "Quint" }
	},

	----------------------------------------------------------------
	{
		Slug = "daylight",
		Name = "Daylight",
		Tagline = "Bright surfaces, soft shadows, friendly and airy",
		Mood = "Light · Soft · Rounded",
		Palette = makePalette("Daylight", "#6D5BFF", {
			backdrop = "#DDE2EF", panel = "#FFFFFF", surface = "#F2F5FB",
			surfaceHover = "#E8EDF8", surfaceActive = "#DCE3F3", elevated = "#FFFFFF",
			stroke = "#DCE2F0", strokeSoft = "#E7EBF5", strokeBright = "#C3CCE0",
			text = "#111827", textMuted = "#6B7690", textDim = "#98A1B5",
			accent = "#6D5BFF", accent2 = "#12B5D6", accentSoft = "#EDEBFF",
			success = "#12B76A", warning = "#E2A008", danger = "#F04438", info = "#2E90FA",
			shadow = "#7A87A8", glass = 0,
		}),
		Metrics = {
			Rail = "rail", Card = "elevated", Button = "gradient",
			RadiusScale = 1.1, MaxRadius = 22, TabShape = "rounded",
			Shadow = 1.5, Glow = false,
		},
		Layout = { Nav = "tabs", Header = "hero", Stats = "headline", Sections = "cards", Footer = "none", Decor = "none", NavWidth = 0 },
		Motion = { Entry = "pop", Hover = "lift", Idle = "none", Duration = 0.26, Stagger = 0.04, Easing = "Back" }
	},

	----------------------------------------------------------------
	{
		Slug = "neon",
		Name = "Neon Grid",
		Tagline = "Cyberpunk: black glass, magenta and cyan glow, hairline borders",
		Mood = "Dark · Sharp · Glow",
		Palette = makePalette("Neon Grid", "#FF2E97", {
			backdrop = "#06040D", panel = "#0B0716", surface = "#120C22",
			surfaceHover = "#1A1030", surfaceActive = "#241542", elevated = "#160E28",
			stroke = "#3A1F6B", strokeSoft = "#241141", strokeBright = "#FF2E97",
			text = "#F3ECFF", textMuted = "#9A86C9", textDim = "#6A5794",
			accent = "#FF2E97", accent2 = "#22F0FF", accentSoft = "#2A0F3E",
			success = "#3DFFA2", warning = "#FFC93C", danger = "#FF4D6D", info = "#22F0FF",
			shadow = "#000000", glass = 0.12,
		}),
		Metrics = {
			Rail = "tabs", Card = "outline", Button = "outline",
			RadiusScale = 0.45, MaxRadius = 8, TabShape = "square",
			BorderScale = 1.4, BorderAlphaScale = 0.4, Shadow = 0.6,
			Glow = true, HeaderCase = "upper", SectionGap = 12,
		},
		Layout = { Nav = "rail", Header = "strip", Stats = "chips", Sections = "panels", Footer = "ticker", Decor = "grid", NavWidth = 74 },
		Motion = { Entry = "glitch", Hover = "glow", Idle = "scan", Duration = 0.34, Stagger = 0.028, Easing = "Linear" }
	},

	----------------------------------------------------------------
	{
		Slug = "terminal",
		Name = "Terminal",
		Tagline = "Phosphor green on black, monospace, squared-off and dense",
		Mood = "Dark · Mono · Flat",
		Palette = makePalette("Terminal", "#3DFF88", {
			backdrop = "#020603", panel = "#05090A", surface = "#08110C",
			surfaceHover = "#0D1A12", surfaceActive = "#12261A", elevated = "#0A140E",
			stroke = "#1C4B31", strokeSoft = "#123021", strokeBright = "#3DFF88",
			text = "#B8FFD0", textMuted = "#5F9E76", textDim = "#3C6B4E",
			accent = "#3DFF88", accent2 = "#9BFF57", accentSoft = "#0D2A19",
			success = "#3DFF88", warning = "#D7FF3D", danger = "#FF6B57", info = "#5BD6FF",
			shadow = "#000000", glass = 0,
		}),
		Metrics = {
			Rail = "sidebar", RailWidth = 178, Card = "flat", Button = "outline",
			RadiusScale = 0, MaxRadius = 0, TabShape = "square",
			BorderScale = 1, BorderAlphaScale = 0.5, Shadow = 0,
			HeaderCase = "upper", Mono = true, Density = 0.94,
		},
		Layout = { Nav = "sidebar", Header = "strip", Stats = "rows", Sections = "console", Footer = "status", Decor = "scan", NavWidth = 168 },
		Motion = { Entry = "type", Hover = "none", Idle = "blink", Duration = 0.20, Stagger = 0.02, Easing = "Linear" }
	},

	----------------------------------------------------------------
	{
		Slug = "brutalist",
		Name = "Brutalist",
		Tagline = "Paper white, hard black borders, offset shadows, zero radius",
		Mood = "Light · Bold · Blocky",
		Palette = makePalette("Brutalist", "#111111", {
			backdrop = "#F4F0E6", panel = "#FFFDF6", surface = "#FFFFFF",
			surfaceHover = "#F6F0DE", surfaceActive = "#EFE5CC", elevated = "#FFFFFF",
			stroke = "#111111", strokeSoft = "#D8CFBA", strokeBright = "#111111",
			text = "#0B0B0B", textMuted = "#5A5347", textDim = "#8A8272",
			accent = "#FF4D2E", accent2 = "#FFC93C", accentSoft = "#FFE9A8",
			accentText = "#111111",
			success = "#0FA958", warning = "#F5A524", danger = "#E5484D", info = "#2E6BFF",
			shadow = "#111111", glass = 0,
		}),
		Metrics = {
			Rail = "tabs", Card = "brutal", Button = "brutal",
			RadiusScale = 0, MaxRadius = 0, TabShape = "square",
			BorderScale = 2.4, BorderAlphaScale = 0, Shadow = 1.8,
			HeaderCase = "upper", SectionGap = 14,
		},
		Layout = { Nav = "tabs", Header = "hero", Stats = "rows", Sections = "list", Footer = "none", Decor = "none", NavWidth = 0 },
		Motion = { Entry = "snap", Hover = "press", Idle = "none", Duration = 0.10, Stagger = 0.0, Easing = "Linear" }
	},

	----------------------------------------------------------------
	{
		Slug = "frost",
		Name = "Frost",
		Tagline = "Frosted pastel glass, very round, whisper-thin white borders",
		Mood = "Light · Glass · Dreamy",
		Palette = makePalette("Frost", "#8B7CFF", {
			backdrop = "#E8E4FF", panel = "#F4F1FF", surface = "#FBFAFF",
			surfaceHover = "#F0ECFF", surfaceActive = "#E6DFFF", elevated = "#FFFFFF",
			stroke = "#FFFFFF", strokeSoft = "#EDE8FF", strokeBright = "#FFFFFF",
			text = "#241E3D", textMuted = "#6B6490", textDim = "#9B95B8",
			accent = "#8B7CFF", accent2 = "#5AD1FF", accentSoft = "#EDE9FF",
			success = "#1FBF75", warning = "#E7A32B", danger = "#F0607C", info = "#4B8BFF",
			shadow = "#8F86C6", glass = 0.42,
		}),
		Metrics = {
			Rail = "rail", Card = "glass", Button = "gradient",
			RadiusScale = 2.1, MaxRadius = 28, TabShape = "pill",
			BorderScale = 1.4, BorderAlphaScale = 1.6, Shadow = 1.2, Glow = true,
		},
		Layout = { Nav = "float", Header = "bar", Stats = "headline", Sections = "cards", Footer = "none", Decor = "dots", NavWidth = 64 },
		Motion = { Entry = "fade", Hover = "lift", Idle = "pulse", Duration = 0.42, Stagger = 0.05, Easing = "Sine" }
	},

	----------------------------------------------------------------
	{
		Slug = "material",
		Name = "Material You",
		Tagline = "Soft tonal surfaces, pill controls, calm elevation",
		Mood = "Light · Tonal · Pill",
		Palette = makePalette("Material You", "#6750A4", {
			backdrop = "#EFE9F6", panel = "#FAF5FF", surface = "#F3EDFA",
			surfaceHover = "#EDE4F8", surfaceActive = "#E3D6F4", elevated = "#FFFBFE",
			stroke = "#E2D8F0", strokeSoft = "#EFE7F8", strokeBright = "#CBBDE4",
			text = "#1D1B20", textMuted = "#625B71", textDim = "#8F8699",
			accent = "#6750A4", accent2 = "#7F67BE", accentSoft = "#EADDFF",
			accentText = "#FFFFFF",
			success = "#2E7D32", warning = "#E9A400", danger = "#BA1A1A", info = "#3B6FE0",
			shadow = "#5C5470", glass = 0,
		}),
		Metrics = {
			Rail = "rail", Card = "elevated", Button = "solid",
			RadiusScale = 1.7, MaxRadius = 999, TabShape = "pill",
			BorderScale = 0.8, Shadow = 1.3, Glow = false,
		},
		Layout = { Nav = "tabs", Header = "bar", Stats = "cards", Sections = "cards", Footer = "none", Decor = "none", NavWidth = 0 },
		Motion = { Entry = "pop", Hover = "lift", Idle = "none", Duration = 0.28, Stagger = 0.045, Easing = "Back" }
	},

	----------------------------------------------------------------
	{
		Slug = "arcade",
		Name = "Arcade",
		Tagline = "Retro cabinet: deep purple, hot pink, chunky panels",
		Mood = "Dark · Bold · Retro",
		Palette = makePalette("Arcade", "#FF3D8B", {
			backdrop = "#140A2B", panel = "#1D1140", surface = "#271650",
			surfaceHover = "#331C64", surfaceActive = "#40247A", elevated = "#2A1858",
			stroke = "#FF3D8B", strokeSoft = "#3A2268", strokeBright = "#FFD166",
			text = "#FFF3FF", textMuted = "#B49AD8", textDim = "#8065A8",
			accent = "#FF3D8B", accent2 = "#FFD166", accentSoft = "#4A1A5E",
			accentText = "#1A0B2E",
			success = "#4BE58C", warning = "#FFD166", danger = "#FF5C5C", info = "#5BD6FF",
			shadow = "#07030F", glass = 0,
		}),
		Metrics = {
			Rail = "tabs", Card = "brutal", Button = "solid",
			RadiusScale = 0.4, MaxRadius = 6, TabShape = "square",
			BorderScale = 2, BorderAlphaScale = 0, Shadow = 1.6,
			HeaderCase = "upper", Density = 1.05,
		},
		Layout = { Nav = "dock", Header = "strip", Stats = "cards", Sections = "cards", Footer = "ticker", Decor = "grid", NavWidth = 0 },
		Motion = { Entry = "bounce", Hover = "press", Idle = "blink", Duration = 0.38, Stagger = 0.05, Easing = "Bounce" }
	},

	----------------------------------------------------------------
	{
		Slug = "executive",
		Name = "Executive",
		Tagline = "Quiet corporate greys, hairline rules, navy accent",
		Mood = "Light · Minimal · Dense",
		Palette = makePalette("Executive", "#1F3A93", {
			backdrop = "#EDEFF3", panel = "#FFFFFF", surface = "#F7F8FA",
			surfaceHover = "#F0F2F6", surfaceActive = "#E6E9F0", elevated = "#FFFFFF",
			stroke = "#DCE0E8", strokeSoft = "#E9ECF1", strokeBright = "#C4CAD6",
			text = "#15181F", textMuted = "#5C6474", textDim = "#8B93A3",
			accent = "#1F3A93", accent2 = "#3E6BE0", accentSoft = "#E8EDFA",
			success = "#1C7F4B", warning = "#B27100", danger = "#B4282C", info = "#2563EB",
			shadow = "#7C8798", glass = 0,
		}),
		Metrics = {
			Rail = "sidebar", RailWidth = 186, Card = "outline", Button = "solid",
			RadiusScale = 0.75, MaxRadius = 10, TabShape = "rounded",
			BorderScale = 0.9, Shadow = 0.7, Density = 0.92, SectionGap = 8,
		},
		Layout = { Nav = "sidebar", Header = "bar", Stats = "rows", Sections = "list", Footer = "status", Decor = "none", NavWidth = 186 },
		Motion = { Entry = "fade", Hover = "none", Idle = "none", Duration = 0.18, Stagger = 0.015, Easing = "Sine" }
	},

	----------------------------------------------------------------
	{
		Slug = "solar",
		Name = "Solar",
		Tagline = "Warm sand and amber, sunlit gradients, generous rounding",
		Mood = "Dark · Warm · Cozy",
		Palette = makePalette("Solar", "#FFB020", {
			backdrop = "#1B1208", panel = "#241A0F", surface = "#2E2213",
			surfaceHover = "#3A2B18", surfaceActive = "#47351E", elevated = "#2A1F11",
			stroke = "#4A3A22", strokeSoft = "#332714", strokeBright = "#7A5C2E",
			text = "#FFF4E2", textMuted = "#C0A886", textDim = "#8A7458",
			accent = "#FFB020", accent2 = "#FF6B4A", accentSoft = "#3D2A12",
			accentText = "#20150A",
			success = "#6FCF5F", warning = "#FFB020", danger = "#FF6B5C", info = "#5FC8FF",
			shadow = "#0B0703", glass = 0.06,
		}),
		Metrics = {
			Rail = "rail", Card = "glass", Button = "gradient",
			RadiusScale = 1.3, MaxRadius = 24, TabShape = "pill",
			Shadow = 1.2, Glow = true,
		},
		Layout = { Nav = "rail", Header = "hero", Stats = "dials", Sections = "accordion", Footer = "status", Decor = "glow", NavWidth = 74 },
		Motion = { Entry = "rise", Hover = "lift", Idle = "pulse", Duration = 0.40, Stagger = 0.05, Easing = "Sine" }
	},
}

------------------------------------------------------------------
-- Lookup
------------------------------------------------------------------

-- slug -> style, and "Name" -> style, both case-insensitive
Styles.Index = {}
for _, style in ipairs(Styles.All) do
	Styles.Index[string.lower(style.Slug)] = style
	Styles.Index[string.lower(style.Name)] = style
end

--- Returns a style by slug or display name, falling back to Midnight.
function Styles.Get(name: string?)
	return Styles.Index[string.lower(name or "")] or Styles.All[1]
end

--- Merged layout blueprint: style values on top of Styles.LayoutDefaults.
function Styles.Layout(style)
	local layout = table.clone(Styles.LayoutDefaults)
	for key, value in pairs(style.Layout or {}) do
		layout[key] = value
	end
	return layout
end

--- Merged motion profile: style values on top of Styles.MotionDefaults.
function Styles.Motion(style)
	local motion = table.clone(Styles.MotionDefaults)
	for key, value in pairs(style.Motion or {}) do
		motion[key] = value
	end
	return motion
end

--- Merged metrics: style values on top of Styles.Defaults. The navigation
--- geometry is derived from the layout blueprint, so `Nav = "dock"` in a
--- style is enough to move the whole rail to the bottom of the window.
function Styles.Metrics(style)
	local metrics = table.clone(Styles.Defaults)
	for key, value in pairs(style.Metrics or {}) do
		metrics[key] = value
	end
	local layout = Styles.Layout(style)
	metrics.Rail = layout.Nav
	metrics.RailWidth = layout.NavWidth or metrics.RailWidth
	metrics.Header = layout.Header
	metrics.Footer = layout.Footer
	metrics.Stats = layout.Stats
	metrics.Sections = layout.Sections
	metrics.Decor = layout.Decor
	return metrics
end

--- Ordered slugs, used by the preview and the docs generator.
function Styles.Slugs(): { string }
	local slugs = {}
	for _, style in ipairs(Styles.All) do
		table.insert(slugs, style.Slug)
	end
	return slugs
end

--- Registers every style palette with the theme system so the built-in
--- theme picker and Window:SetTheme() can reach them.
function Styles.Install()
	for _, style in ipairs(Styles.All) do
		Theme.Palettes[style.Name] = style.Palette
		Theme.Styles = Theme.Styles or {}
		Theme.Styles[style.Name] = Styles.Metrics(style)
	end
end

Styles.Install()

return Styles
