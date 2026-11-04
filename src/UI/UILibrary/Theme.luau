--[[
	Aurora UI  •  Theme.luau
	------------------------------------------------------------------
	Single source of truth for colors, fonts, spacing, rounding and
	motion. Everything in the library reads from here, which means a
	theme swap re-paints the entire interface with zero component edits.

	Add your own palette at the bottom of Theme.Palettes and it will
	appear automatically in Window:SetTheme() and the demo picker.
--]]

local Theme = {}

Theme.Name = "Midnight"
Theme.Version = "4.1.0"

-- Typography ---------------------------------------------------------
-- Roblox's Gotham family is used because it ships with the client and
-- is metric-compatible with Inter, so web-designed mockups translate
-- 1:1 to in-engine layouts.
Theme.Fonts = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
	Mono = Enum.Font.Code,
}

-- Corner radii -------------------------------------------------------
Theme.Rounding = {
	Tiny = 4,
	Small = 8,
	Medium = 12,
	Large = 16,
	Huge = 22,
	Pill = 999,
}

-- Motion -------------------------------------------------------------
Theme.Duration = {
	Instant = 0.08,
	Fast = 0.14,
	Normal = 0.22,
	Slow = 0.38,
	Spring = 0.52,
}

Theme.Easing = {
	Smooth = Enum.EasingStyle.Quint,
	Fast = Enum.EasingStyle.Quad,
	Overshoot = Enum.EasingStyle.Back,
	Linear = Enum.EasingStyle.Linear,
}

-- Spacing scale (4pt grid) -------------------------------------------
Theme.Spacing = {
	XSmall = 4,
	Small = 8,
	Medium = 12,
	Large = 16,
	XLarge = 24,
	XXLarge = 32,
}

-- Type scale ---------------------------------------------------------
Theme.TextSize = {
	Micro = 10,
	Small = 11,
	Body = 13,
	Label = 14,
	Title = 16,
	Heading = 20,
	Display = 26,
}

-- Layout constants ---------------------------------------------------
Theme.Layout = {
	WindowWidth = 880,
	WindowHeight = 570,
	WindowMinWidth = 620,
	WindowMinHeight = 420,
	TitleBarHeight = 58,
	SidebarWidth = 74,
	FooterHeight = 38,
	SectionPadding = 12,
	RowHeight = 44,
	ControlHeight = 30,
	Gap = 10,
}

------------------------------------------------------------------
-- PALETTES
------------------------------------------------------------------
Theme.Palettes = {

	--------------------------------------------------------------
	Midnight = {
		Name = "Midnight",
		Swatch = Color3.fromHex("#7C5CFF"),

		Backdrop = Color3.fromHex("#05060A"),
		Panel = Color3.fromHex("#0F121B"),
		PanelSolid = Color3.fromHex("#0F121B"),
		Surface = Color3.fromHex("#161A26"),
		SurfaceHover = Color3.fromHex("#1C2130"),
		SurfaceActive = Color3.fromHex("#232A3C"),
		Elevated = Color3.fromHex("#1B2030"),

		Stroke = Color3.fromHex("#252C3E"),
		StrokeSoft = Color3.fromHex("#1A1F2D"),
		StrokeBright = Color3.fromHex("#39435C"),

		Text = Color3.fromHex("#EAEEF9"),
		TextMuted = Color3.fromHex("#8B95AE"),
		TextDim = Color3.fromHex("#5A6379"),
		TextInverse = Color3.fromHex("#0A0C12"),

		Accent = Color3.fromHex("#7C5CFF"),
		Accent2 = Color3.fromHex("#22D3EE"),
		AccentSoft = Color3.fromHex("#2A2350"),
		AccentText = Color3.fromHex("#FFFFFF"),

		Success = Color3.fromHex("#34D399"),
		Warning = Color3.fromHex("#FBBF24"),
		Danger = Color3.fromHex("#FB7185"),
		Info = Color3.fromHex("#60A5FA"),

		Shadow = Color3.fromHex("#000000"),
		Glass = 0.04, -- transparency offset applied to panels
	},

	--------------------------------------------------------------
	Nebula = {
		Name = "Nebula",
		Swatch = Color3.fromHex("#FF5CC8"),

		Backdrop = Color3.fromHex("#0A0410"),
		Panel = Color3.fromHex("#170C24"),
		PanelSolid = Color3.fromHex("#170C24"),
		Surface = Color3.fromHex("#22122F"),
		SurfaceHover = Color3.fromHex("#2B183C"),
		SurfaceActive = Color3.fromHex("#37204C"),
		Elevated = Color3.fromHex("#2A1740"),

		Stroke = Color3.fromHex("#3A2053"),
		StrokeSoft = Color3.fromHex("#2A1740"),
		StrokeBright = Color3.fromHex("#5A3479"),

		Text = Color3.fromHex("#F6ECFF"),
		TextMuted = Color3.fromHex("#A78FC0"),
		TextDim = Color3.fromHex("#6E5588"),
		TextInverse = Color3.fromHex("#12071C"),

		Accent = Color3.fromHex("#FF5CC8"),
		Accent2 = Color3.fromHex("#A855F7"),
		AccentSoft = Color3.fromHex("#3E1244"),
		AccentText = Color3.fromHex("#FFFFFF"),

		Success = Color3.fromHex("#4ADE80"),
		Warning = Color3.fromHex("#FCD34D"),
		Danger = Color3.fromHex("#FF6B81"),
		Info = Color3.fromHex("#C084FC"),

		Shadow = Color3.fromHex("#000000"),
		Glass = 0.02,
	},

	--------------------------------------------------------------
	Emerald = {
		Name = "Emerald",
		Swatch = Color3.fromHex("#10B981"),

		Backdrop = Color3.fromHex("#04090A"),
		Panel = Color3.fromHex("#0B1414"),
		PanelSolid = Color3.fromHex("#0B1414"),
		Surface = Color3.fromHex("#10201E"),
		SurfaceHover = Color3.fromHex("#152A27"),
		SurfaceActive = Color3.fromHex("#1B3631"),
		Elevated = Color3.fromHex("#142823"),

		Stroke = Color3.fromHex("#1D3A34"),
		StrokeSoft = Color3.fromHex("#152A26"),
		StrokeBright = Color3.fromHex("#2F5A50"),

		Text = Color3.fromHex("#E6FBF4"),
		TextMuted = Color3.fromHex("#82A79C"),
		TextDim = Color3.fromHex("#547066"),
		TextInverse = Color3.fromHex("#04100D"),

		Accent = Color3.fromHex("#10B981"),
		Accent2 = Color3.fromHex("#5EEAD4"),
		AccentSoft = Color3.fromHex("#0F3A2F"),
		AccentText = Color3.fromHex("#03120E"),

		Success = Color3.fromHex("#34D399"),
		Warning = Color3.fromHex("#FBBF24"),
		Danger = Color3.fromHex("#F87171"),
		Info = Color3.fromHex("#38BDF8"),

		Shadow = Color3.fromHex("#000000"),
		Glass = 0.04,
	},

	--------------------------------------------------------------
	Daylight = {
		Name = "Daylight",
		Swatch = Color3.fromHex("#6D5BFF"),

		Backdrop = Color3.fromHex("#DDE2EF"),
		Panel = Color3.fromHex("#FFFFFF"),
		PanelSolid = Color3.fromHex("#FFFFFF"),
		Surface = Color3.fromHex("#F2F5FB"),
		SurfaceHover = Color3.fromHex("#E8EDF8"),
		SurfaceActive = Color3.fromHex("#DCE3F3"),
		Elevated = Color3.fromHex("#FFFFFF"),

		Stroke = Color3.fromHex("#DCE2F0"),
		StrokeSoft = Color3.fromHex("#E7EBF5"),
		StrokeBright = Color3.fromHex("#C3CCE0"),

		Text = Color3.fromHex("#111827"),
		TextMuted = Color3.fromHex("#6B7690"),
		TextDim = Color3.fromHex("#98A1B5"),
		TextInverse = Color3.fromHex("#FFFFFF"),

		Accent = Color3.fromHex("#6D5BFF"),
		Accent2 = Color3.fromHex("#12B5D6"),
		AccentSoft = Color3.fromHex("#EDEBFF"),
		AccentText = Color3.fromHex("#FFFFFF"),

		Success = Color3.fromHex("#12B76A"),
		Warning = Color3.fromHex("#E2A008"),
		Danger = Color3.fromHex("#F04438"),
		Info = Color3.fromHex("#2E90FA"),

		Shadow = Color3.fromHex("#7A87A8"),
		Glass = 0,
	},
}

------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------

--- Returns a palette by name, falling back to Midnight.
function Theme.Get(name: string?)
	local palette = Theme.Palettes[name or "Midnight"] or Theme.Palettes.Midnight
	return palette
end

--- Ordered list of palette names, useful for building theme pickers.
function Theme.List(): { string }
	local names = {}
	for name in pairs(Theme.Palettes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--- Returns a UIGradient-ready ColorSequence from two theme colors.
function Theme.GradientSequence(palette, fromKey, toKey)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, palette[fromKey or "Accent"]),
		ColorSequenceKeypoint.new(1, palette[toKey or "Accent2"]),
	})
end

return Theme
