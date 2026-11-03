--[[
	Aurora UI  •  Window.luau
	------------------------------------------------------------------
	The application frame: screen container, glass backdrop, title bar
	with global search, icon rail, tab pages, status footer, overlay
	layer for popups/modals and a notification stack.

	Everything else in the library hangs off the window object.
--]]

local Util = require(script.Parent.Parent.Util)
local Theme = require(script.Parent.Parent.Theme)
local Styles = require(script.Parent.Parent.Styles)
local Icons = require(script.Parent.Parent.Icons)
local Tab = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)
local Tooltip = require(script.Parent.Tooltip)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local Window = {}

local L = Theme.Layout

------------------------------------------------------------------
-- Small local builders
------------------------------------------------------------------

local function iconButton(parent, iconName, tooltip: string?)
	local button = Util.New("Frame", {
		Name = "IconButton_" .. iconName,
		BackgroundColor3 = Util.Theme.SurfaceHover,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(30, 30),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(9, button)
	Util.Themable(button, "BackgroundColor3", "SurfaceHover")

	local icon = Icons.Get(iconName, button, {
		Size = 13,
		Color = Util.Theme.TextMuted,
		Mask = Util.Theme.Panel,
	})
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)

	button.MouseEnter:Connect(function()
		Util.Tween(button, { BackgroundTransparency = 0 }, "Fast")
		Icons.Tint(icon, Util.Theme.Text)
	end)
	button.MouseLeave:Connect(function()
		Util.Tween(button, { BackgroundTransparency = 1 }, "Fast")
		Icons.Tint(icon, Util.Theme.TextMuted)
	end)

	if tooltip then
		button:SetAttribute("Tooltip", tooltip)
	end

	return button, icon
end

------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------

function Window.New(config: { [string]: any })
	config = config or {}

	local self = {}
	self.Tabs = {}
	self.ActiveTab = nil
	self.SearchIndex = {}
	self._toasts = {}
	self.Alive = true

	-- Style ------------------------------------------------------------
	-- A style is a palette *plus* its geometry: radius, border weight,
	-- rail layout, card treatment. `Theme` alone still works and keeps the
	-- Midnight geometry.
	local style = Styles.Get(config.Style or config.Theme)
	local metrics = Styles.Metrics(style)
	Util.ApplyStyle(metrics)
	self.Style = style
	self.Metrics = metrics
	self.StyleName = style.Name
	self.ThemeName = style.Name

	-- 4.0 -- the blueprint -------------------------------------------------
	-- The style also decides what the window is *made of*, not just what
	-- colour it is. These three numbers are read before a single frame is
	-- created, so the body, the pages and the footer all agree on where the
	-- chrome ends.
	local layout = Styles.Layout(style)
	local motion = Styles.Motion(style)
	self.Layout = layout
	self.Motion = motion

	local headerHeight = if layout.Header == "hero"
		then 92
		elseif layout.Header == "strip" then 44
		else L.TitleBarHeight
	local footerHeight = if layout.Footer == "none"
		then 0
		elseif layout.Footer == "ticker" then 27
		else L.FooterHeight
	local dockHeight = if layout.Nav == "dock" then 68 else 0

	self.HeaderHeight = headerHeight
	self.FooterHeight = footerHeight

	-- Staggered entrance: every direct child of the body slides in, in
	-- reading order, using the style's own motion profile.
	local Anim = require(script.Parent.Parent.Anim)
	self._anim = Anim
	self._motion = motion
	self._layout = layout

	local width = config.Width or L.WindowWidth
	local height = config.Height or L.WindowHeight

	-- Palette ----------------------------------------------------------
	Util.ApplyTheme(Theme.Get(self.ThemeName))

	-- Screen container --------------------------------------------------
	local gui = Util.New("ScreenGui", {
		Name = "AuroraUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = config.GuiParent or player:WaitForChild("PlayerGui"),
	})
	self.Gui = gui

	-- Click blocker (keeps game input out while the menu is open) ------
	local blocker = Util.New("TextButton", {
		Name = "Blocker",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	self.Blocker = blocker

	-- Blur -------------------------------------------------------------
	local blur
	if config.Blur ~= false then
		blur = Instance.new("BlurEffect")
		blur.Size = 0
		blur.Parent = game:GetService("Lighting")
		self.Blur = blur
	end

	-- Main panel --------------------------------------------------------
	local main = Util.New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Util.Theme.Panel,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = gui,
	})
	Util.Corner(18, main)
	Util.Stroke(Util.Theme.Stroke, 1, 0.15, main)
	Util.Themable(main, "BackgroundColor3", "Panel")

	local mainStroke = main:FindFirstChildOfClass("UIStroke")
	if mainStroke then
		Util.Themable(mainStroke, "Color", "Stroke")
	end

	local shadow = Util.Shadow(main, { Spread = 34, Strength = 1.4, Radius = 26, OffsetY = 12 })
	local mainScale = Util.Scale(main)

	-- Responsive scale ---------------------------------------------------
	-- The panel is authored at a fixed pixel size, then uniformly scaled
	-- down so it always fits the viewport. On phones (Delta / iOS / any
	-- touch device) this is what keeps a 900x580 window usable at 0.6x.
	local baseScale = 1
	local animScale = 0.94
	local userScale = math.clamp(config.Scale or 1, 0.5, 1.6)

	local function scaleTo(factor: number, preset: string?)
		animScale = factor
		Util.Tween(mainScale, { Scale = baseScale * factor }, preset or "Spring")
	end

	local function fitToViewport()
		local viewport = Util.Viewport()
		local margin = UserInputService.TouchEnabled and 28 or 90
		local factor = math.min(
			(viewport.X - margin) / math.max(width, 1),
			(viewport.Y - margin) / math.max(height, 1),
			1
		)
		baseScale = math.clamp(factor, 0.42, 1) * userScale
		mainScale.Scale = baseScale * animScale
	end

	fitToViewport()
	mainScale.Scale = baseScale * animScale

	-- Keep the shadow glued to the panel while dragging / resizing.
	local function syncShadow()
		if not shadow or not shadow.Parent then
			return
		end
		shadow.Position = UDim2.new(
			main.Position.X.Scale,
			main.Position.X.Offset,
			main.Position.Y.Scale,
			main.Position.Y.Offset + 12
		)
		shadow.Size = main.Size
	end
	main:GetPropertyChangedSignal("Size"):Connect(syncShadow)
	main:GetPropertyChangedSignal("Position"):Connect(syncShadow)

	self.Instance = main
	self.Root = gui

	------------------------------------------------------------------
	-- Title bar
	------------------------------------------------------------------
	local titleBar = Util.New("Frame", {
		Name = "TitleBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, headerHeight),
		Parent = main,
	})

	local logo = Util.New("Frame", {
		Name = "Logo",
		BackgroundColor3 = Util.Theme.Accent,
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(30, 30),
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	Util.Corner(10, logo)
	local logoGradient = Util.Gradient(
		ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2),
		45,
		logo
	)
	Util.Themable(logo, "BackgroundColor3", "Accent")
	Util.Themable(logoGradient, "Color", function(palette)
		return ColorSequence.new(palette.Accent, palette.Accent2)
	end)

	local logoIcon = Icons.Get(config.Icon or "sparkle", logo, {
		Size = 15,
		Color = Util.Theme.AccentText,
		Mask = Util.Theme.Accent,
	})
	logoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	logoIcon.Position = UDim2.fromScale(0.5, 0.5)

	local title = Util.Text({
		Name = "Title",
		Text = config.Title or "Aurora",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Util.Theme.Text,
		Position = UDim2.fromOffset(54, 12),
		Size = UDim2.new(0, 220, 0, 18),
		Parent = titleBar,
	})
	Util.Themable(title, "TextColor3", "Text")

	local subtitle = Util.Text({
		Name = "Subtitle",
		Text = config.Subtitle or ("v" .. Util.Version .. "  •  ready"),
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = Util.Theme.TextDim,
		Position = UDim2.fromOffset(54, 30),
		Size = UDim2.new(0, 240, 0, 14),
		Parent = titleBar,
	})
	Util.Themable(subtitle, "TextColor3", "TextDim")
	self.Subtitle = subtitle

	-- Header variants ---------------------------------------------------
	-- strip : half-height bar, uppercase title, no subtitle
	-- hero  : tall header, big title, accent wash behind the logo
	-- bar   : the default 58px bar
	if layout.Header == "hero" then
		logo.Size = UDim2.fromOffset(42, 42)
		logo.Position = UDim2.fromOffset(18, 20)
		Util.Corner(15, logo)
		logoIcon.Size = UDim2.fromOffset(20, 20)
		title.TextSize = 20
		title.Position = UDim2.fromOffset(72, 20)
		title.Size = UDim2.new(0, 360, 0, 26)
		subtitle.TextSize = 11.5
		subtitle.Position = UDim2.fromOffset(72, 48)
		subtitle.Size = UDim2.new(0, 380, 0, 18)

		local wash = Util.New("Frame", {
			Name = "HeaderWash",
			BackgroundColor3 = Util.Theme.Accent,
			BackgroundTransparency = 0.9,
			Size = UDim2.new(1, 0, 0, headerHeight),
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = titleBar,
		})
		Util.Corner(16, wash)
		Util.Gradient(ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2), 12, wash)
		Util.Themable(wash, "BackgroundColor3", "Accent")
		-- the wash sits behind the header contents
		for _, child in ipairs(titleBar:GetChildren()) do
			if child ~= wash and child:IsA("GuiObject") then
				child.ZIndex = 2
			end
		end
	elseif layout.Header == "strip" then
		logo.Size = UDim2.fromOffset(22, 22)
		logo.Position = UDim2.fromOffset(14, 11)
		Util.Corner(7, logo)
		logoIcon.Size = UDim2.fromOffset(12, 12)
		title.TextSize = 12
		title.Text = string.upper(title.Text)
		title.Position = UDim2.fromOffset(44, 5)
		title.Size = UDim2.new(0, 260, 0, 16)
		subtitle.Visible = false
		titleBar.Size = UDim2.new(1, 0, 0, headerHeight)
	end

	-- Window controls ---------------------------------------------------
	local controls = Util.New("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = titleBar,
	})
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 5),
		Parent = controls,
	})

	local themeButton, themeIcon = iconButton(controls, "moon", "Switch theme")
	local bellButton, bellIcon = iconButton(controls, "bell", "Notifications")
	local minimizeButton = iconButton(controls, "minus", "Minimize")
	local closeButton, closeIcon = iconButton(controls, "close", "Close")

	Util.OnClick(themeButton, function()
		self:CycleTheme()
	end)

	Util.OnClick(bellButton, function()
		self:Notify({
			Title = "Notifications",
			Body = "Everything is running smoothly.",
			Type = "success",
			Duration = 3,
			Icon = "bell",
		})
	end)

	Util.OnClick(closeButton, function()
		self:Close()
	end)

	closeButton.MouseEnter:Connect(function()
		Util.Tween(closeButton, { BackgroundColor3 = Util.Theme.Danger }, "Fast")
		Icons.Tint(closeIcon, Color3.new(1, 1, 1))
	end)
	closeButton.MouseLeave:Connect(function()
		Util.Tween(closeButton, { BackgroundColor3 = Util.Theme.SurfaceHover }, "Fast")
		Icons.Tint(closeIcon, Util.Theme.TextMuted)
	end)

	-- Search ------------------------------------------------------------
	local searchHolder = Util.New("Frame", {
		Name = "Search",
		BackgroundColor3 = Util.Theme.Surface,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, layout.Header == "hero" and -206 or (layout.Header == "strip" and -156 or -170), 0.5, 0),
		Size = UDim2.fromOffset(layout.Header == "hero" and 200 or (layout.Header == "strip" and 146 or 168), layout.Header == "strip" and 26 or 30),
		BorderSizePixel = 0,
		Visible = config.Search ~= false and layout.Header ~= "hero",
		Parent = titleBar,
	})
	Util.Corner(9, searchHolder)
	local searchStroke = Util.Stroke(Util.Theme.Stroke, 1, 0, searchHolder)
	Util.Padding({ X = 26 }, searchHolder)
	Util.Themable(searchHolder, "BackgroundColor3", "Surface")
	Util.Themable(searchStroke, "Color", "Stroke")

	local searchIcon = Icons.Get("search", searchHolder, {
		Size = 12,
		Color = Util.Theme.TextDim,
		Mask = Util.Theme.Surface,
	})
	searchIcon.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.Position = UDim2.new(0, -18, 0.5, 0)

	local searchInput = Util.New("TextBox", {
		Name = "Field",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = "",
		PlaceholderText = "Search settings…",
		PlaceholderColor3 = Util.Theme.TextDim,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = searchHolder,
	})
	Util.Themable(searchInput, "TextColor3", "Text")
	Util.Themable(searchInput, "PlaceholderColor3", "TextDim")

	searchInput.Focused:Connect(function()
		Util.Tween(searchStroke, { Color = Util.Theme.Accent, Thickness = 1.5 }, "Fast")
	end)
	searchInput.FocusLost:Connect(function()
		Util.Tween(searchStroke, { Color = Util.Theme.Stroke, Thickness = 1 }, "Fast")
		task.delay(0.15, function()
			if self._closeSearchResults then
				self._closeSearchResults()
			end
		end)
	end)

	------------------------------------------------------------------
	-- Body
	------------------------------------------------------------------
	local body = Util.New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, headerHeight),
		Size = UDim2.new(
			1,
			0,
			1,
			-(headerHeight + (config.Footer ~= false and footerHeight or 0) + dockHeight)
		),
		Parent = main,
	})
	self.Body = body

	-- Sidebar -----------------------------------------------------------
	local sidebar = Util.New("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Util.Theme.Panel,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, L.SidebarWidth, 1, 0),
		BorderSizePixel = 0,
		Parent = body,
	})

	local divider = Util.New("Frame", {
		Name = "SidebarDivider",
		BackgroundColor3 = Util.Theme.StrokeSoft,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	Util.Themable(divider, "BackgroundColor3", "StrokeSoft")

	local rail = Util.New("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	Util.List({
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = rail,
	})
	self._rail = rail

	-- Sliding active indicator
	local indicator = Util.New("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.fromOffset(3, 24),
		BackgroundColor3 = Util.Theme.Accent,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	Util.Corner(999, indicator)
	local indicatorGradient = Util.Gradient(
		ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2),
		90,
		indicator
	)
	Util.Themable(indicator, "BackgroundColor3", "Accent")
	Util.Themable(indicatorGradient, "Color", function(palette)
		return ColorSequence.new(palette.Accent, palette.Accent2)
	end)
	self._indicator = indicator

	-- Profile chip at the bottom of the rail ----------------------------
	local profile = Util.New("Frame", {
		Name = "Profile",
		BackgroundColor3 = Util.Theme.Surface,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(44, 44),
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	Util.Corner(999, profile)
	Util.Stroke(Util.Theme.Stroke, 1, 0, profile)
	Util.Themable(profile, "BackgroundColor3", "Surface")

	local avatar = Util.New("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = Util.Theme.SurfaceActive,
		Image = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		Parent = profile,
	})
	Util.Corner(999, avatar)

	local onlineDot = Util.New("Frame", {
		Name = "Status",
		BackgroundColor3 = Util.Theme.Success,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 1, 1, 1),
		Size = UDim2.fromOffset(11, 11),
		BorderSizePixel = 0,
		Parent = profile,
	})
	Util.Corner(999, onlineDot)
	Util.Stroke(Util.Theme.Panel, 2, 0, onlineDot)
	Util.Themable(onlineDot, "BackgroundColor3", "Success")

	profile:SetAttribute("Tooltip", config.ProfileTip or "Signed in")

	-- Async avatar (never blocks the UI) --------------------------------
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size150x150
			)
		end)
		if ok and image and avatar.Parent then
			avatar.Image = image
		end
	end)

	-- Page host ----------------------------------------------------------
	local content = Util.New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(L.SidebarWidth + 1, 0),
		Size = UDim2.new(1, -(L.SidebarWidth + 1), 1, 0),
		ClipsDescendants = true,
		Parent = body,
	})
	Util.Padding({ Left = 6, Right = 8, Top = 6 }, content)
	self._pages = content

	-- Rail variants ------------------------------------------------------
	-- "rail"    : 74px icon column (default)
	-- "sidebar" : wide labelled column
	-- "tabs"    : no column at all, a horizontal tab bar under the title bar
	local railKind = metrics.Rail or "rail"
	local railWidth = metrics.RailWidth or L.SidebarWidth

	if railKind == "sidebar" then
		sidebar.Size = UDim2.new(0, railWidth, 1, 0)
		content.Position = UDim2.fromOffset(railWidth + 1, 0)
		content.Size = UDim2.new(1, -(railWidth + 1), 1, 0)

		local oldList = rail:FindFirstChildOfClass("UIListLayout")
		if oldList then
			oldList:Destroy()
		end
		Util.Padding({ Left = 10, Right = 10, Top = 16 }, rail)
		Util.List({
			Padding = UDim.new(0, 4),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = rail,
		})
		indicator.Visible = false
	elseif railKind == "tabs" then
		sidebar.Visible = false

		local tabBar = Util.New("Frame", {
			Name = "TabBar",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 54),
			Parent = body,
		})
		Util.Padding({ Left = 14, Right = 14, Top = 6, Bottom = 4 }, tabBar)

		rail.Parent = tabBar
		rail.Position = UDim2.fromOffset(0, 0)
		rail.Size = UDim2.new(1, -46, 0, 44)
		rail.AutomaticSize = Enum.AutomaticSize.None

		local oldList = rail:FindFirstChildOfClass("UIListLayout")
		if oldList then
			oldList:Destroy()
		end
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = rail,
		})

		-- the avatar moves to the right end of the tab bar
		profile.Parent = tabBar
		profile.AnchorPoint = Vector2.new(1, 0.5)
		profile.Position = UDim2.new(1, 0, 0, 22)
		profile.Size = UDim2.fromOffset(32, 32)

		indicator.Visible = false
		content.Position = UDim2.fromOffset(0, 54)
		content.Size = UDim2.new(1, 0, 1, -54)
		self._tabBar = tabBar
	elseif railKind == "dock" then
		-- "dock": a horizontal navigation bar pinned to the bottom edge,
		-- like a phone tab bar or a console home row.
		sidebar.Visible = false

		local dock = Util.New("Frame", {
			Name = "Dock",
			BackgroundColor3 = Util.Theme.Panel,
			BackgroundTransparency = 0.04,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -(config.Footer ~= false and footerHeight or 0)),
			Size = UDim2.new(1, 0, 0, dockHeight),
			BorderSizePixel = 0,
			Parent = main,
		})
		Util.Corner(0, dock)
		local dockStroke = Util.Stroke(Util.Theme.Stroke, 1, 0.25, dock)
		Util.Themable(dock, "BackgroundColor3", "Panel")
		Util.Themable(dockStroke, "Color", "Stroke")

		local hair = Util.New("Frame", {
			Name = "DockAccent",
			BackgroundColor3 = Util.Theme.Accent,
			Size = UDim2.new(1, 0, 0, 2),
			BorderSizePixel = 0,
			Parent = dock,
		})
		Util.Gradient(ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2), 0, hair)
		Util.Themable(hair, "BackgroundColor3", "Accent")

		Util.Padding({ Left = 12, Right = 12, Top = 10, Bottom = 10 }, dock)

		rail.Parent = dock
		rail.Position = UDim2.fromOffset(0, 0)
		rail.Size = UDim2.new(1, -50, 1, 0)
		rail.AutomaticSize = Enum.AutomaticSize.None
		local dockList = rail:FindFirstChildOfClass("UIListLayout")
		if dockList then
			dockList:Destroy()
		end
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = rail,
		})

		profile.Parent = dock
		profile.AnchorPoint = Vector2.new(1, 0.5)
		profile.Position = UDim2.new(1, 0, 0.5, 0)
		profile.Size = UDim2.fromOffset(38, 38)

		indicator.Visible = false
		self._dock = dock
	elseif railKind == "float" then
		-- "float": the rail detaches from the window edge and becomes its
		-- own rounded panel with a drop shadow.
		local inset = 10
		sidebar.BackgroundColor3 = Util.Theme.Panel
		sidebar.BackgroundTransparency = 0.06
		sidebar.Position = UDim2.fromOffset(inset, inset)
		sidebar.Size = UDim2.new(0, railWidth, 1, -(inset * 2))
		Util.Corner(18, sidebar)
		local floatStroke = Util.Stroke(Util.Theme.Stroke, 1, 0.2, sidebar)
		Util.Themable(sidebar, "BackgroundColor3", "Panel")
		Util.Themable(floatStroke, "Color", "Stroke")
		Util.Shadow(sidebar, { Spread = 18, Strength = 0.8, Radius = 14, OffsetY = 4 })

		divider.Visible = false
		rail.Position = UDim2.fromOffset(0, 12)
		profile.AnchorPoint = Vector2.new(0.5, 1)
		profile.Position = UDim2.new(0.5, 0, 1, -10)

		content.Position = UDim2.fromOffset(railWidth + inset + 10, 8)
		content.Size = UDim2.new(1, -(railWidth + inset + 10), 1, -8)
	end

	-- Footer -------------------------------------------------------------
	-- status : version pill + live dot + theme chip (the default)
	-- ticker : a thin live strip with legend stats, no version chrome
	-- none   : no footer at all, the pages go all the way down
	if config.Footer ~= false and layout.Footer ~= "none" then
		local footer = Util.New("Frame", {
			Name = "Footer",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, footerHeight),
			Parent = main,
		})

		Util.New("Frame", {
			Name = "FooterDivider",
			BackgroundColor3 = Util.Theme.StrokeSoft,
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			Parent = footer,
		})

		local versionPill = Util.New("Frame", {
			Name = "VersionPill",
			BackgroundColor3 = Util.Theme.Surface,
			BackgroundTransparency = 0.4,
			Position = UDim2.fromOffset(14, 9),
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BorderSizePixel = 0,
			Parent = footer,
		})
		Util.Corner(6, versionPill)
		Util.Padding({ X = 7 }, versionPill)
		Util.Themable(versionPill, "BackgroundColor3", "Surface")

		local versionLabel = Util.Text({
			Name = "Version",
			Text = "Aurora UI " .. Util.Version,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = Util.Theme.TextDim,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = versionPill,
		})
		Util.Themable(versionLabel, "TextColor3", "TextDim")

		-- Live status ---------------------------------------------------
		local status = Util.New("Frame", {
			Name = "Status",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = footer,
		})
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			Parent = status,
		})

		local statusDot = Util.New("Frame", {
			Name = "Dot",
			BackgroundColor3 = Util.Theme.Success,
			Size = UDim2.fromOffset(6, 6),
			BorderSizePixel = 0,
			Parent = status,
		})
		Util.Corner(999, statusDot)
		Util.Themable(statusDot, "BackgroundColor3", "Success")

		local statusLabel = Util.Text({
			Name = "Label",
			Text = config.Status or "Connected  •  62 ms",
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = Util.Theme.TextDim,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = status,
		})
		Util.Themable(statusLabel, "TextColor3", "TextDim")

		self._statusDot = statusDot
		self._statusLabel = statusLabel

		-- Theme chip ----------------------------------------------------
		local themeChip = Util.New("Frame", {
			Name = "ThemeChip",
			BackgroundColor3 = Util.Theme.Surface,
			BackgroundTransparency = 0.4,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 9),
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BorderSizePixel = 0,
			Parent = footer,
		})
		Util.Corner(6, themeChip)
		Util.Padding({ X = 7 }, themeChip)
		Util.Themable(themeChip, "BackgroundColor3", "Surface")

		local swatch = Util.New("Frame", {
			Name = "Swatch",
			BackgroundColor3 = Util.Theme.Accent,
			Size = UDim2.fromOffset(8, 8),
			BorderSizePixel = 0,
			Parent = themeChip,
		})
		Util.Corner(999, swatch)
		swatch.AnchorPoint = Vector2.new(0, 0.5)
		swatch.Position = UDim2.new(0, 0, 0.5, 0)
		Util.Themable(swatch, "BackgroundColor3", "Accent")

		local themeLabel = Util.Text({
			Name = "Name",
			Text = self.ThemeName,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = Util.Theme.TextMuted,
			Position = UDim2.fromOffset(13, 0),
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = themeChip,
		})
		Util.Themable(themeLabel, "TextColor3", "TextMuted")

		self._themeLabel = themeLabel
		self._themeSwatch = swatch
		Util.OnClick(themeChip, function()
			self:CycleTheme()
		end)
		themeChip:SetAttribute("Tooltip", "Click to cycle themes")

		if layout.Footer == "ticker" then
			-- a live strip: LIVE pill, three legend stats, accent hairline
			versionPill.Visible = false
			status.Visible = false
			themeChip.Position = UDim2.new(1, -14, 0, 4)

			local live = Util.New("Frame", {
				Name = "Live",
				BackgroundColor3 = Util.Theme.Accent,
				Position = UDim2.fromOffset(14, 4),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BorderSizePixel = 0,
				Parent = footer,
			})
			Util.Corner(4, live)
			Util.Padding({ X = 7 }, live)
			Util.Themable(live, "BackgroundColor3", "Accent")

			Util.Text({
				Name = "Label",
				Text = "LIVE",
				Font = Enum.Font.GothamBold,
				TextSize = 9,
				TextColor3 = Util.Theme.AccentText,
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				Parent = live,
			})

			local legend = Util.New("Frame", {
				Name = "Legend",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromOffset(64, 4),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				Parent = footer,
			})
			Util.List({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 18),
				Parent = legend,
			})

			for _, item in ipairs({
				{ "fps", "40", "Success" },
				{ "ping", "62 ms", "Info" },
				{ "nodes", "724", "Accent" },
			}) do
				local group = Util.New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					Parent = legend,
				})
				Util.List({
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 5),
					Parent = group,
				})
				local dot = Util.New("Frame", {
					BackgroundColor3 = Util.Theme[item[3]],
					Size = UDim2.fromOffset(5, 5),
					BorderSizePixel = 0,
					Parent = group,
				})
				Util.Corner(999, dot)
				Util.Themable(dot, "BackgroundColor3", item[3])
				local key = Util.Text({
					Text = item[1],
					Font = Enum.Font.GothamMedium,
					TextSize = 10,
					TextColor3 = Util.Theme.TextDim,
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					Parent = group,
				})
				Util.Themable(key, "TextColor3", "TextDim")
				local val = Util.Text({
					Text = item[2],
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					TextColor3 = Util.Theme.Text,
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					Parent = group,
				})
				Util.Themable(val, "TextColor3", "Text")
			end
		end
	end

	------------------------------------------------------------------
	-- Overlay + notifications
	------------------------------------------------------------------
	local overlay = Util.New("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 500,
		Parent = main,
	})
	self._overlayFrame = overlay

	local notifications = Util.New("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, L.TitleBarHeight + 8),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 600,
		Parent = main,
	})
	Util.List({
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = notifications,
	})
	self._notificationFrame = notifications

	-- Resize grabber -----------------------------------------------------
	local resizer = Util.New("Frame", {
		Name = "Resizer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(18, 18),
		Parent = main,
	})
	resizer:SetAttribute("Tooltip", "Drag to resize")

	local gripA = Util.New("Frame", {
		BackgroundColor3 = Util.Theme.StrokeBright,
		BackgroundTransparency = 0.4,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -4),
		Size = UDim2.fromOffset(7, 2),
		BorderSizePixel = 0,
		Rotation = -45,
		Parent = resizer,
	})
	Util.Corner(999, gripA)
	local gripB = Util.New("Frame", {
		BackgroundColor3 = Util.Theme.StrokeBright,
		BackgroundTransparency = 0.4,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -9),
		Size = UDim2.fromOffset(12, 2),
		BorderSizePixel = 0,
		Rotation = -45,
		Parent = resizer,
	})
	Util.Corner(999, gripB)
	Util.Themable(gripA, "BackgroundColor3", "StrokeBright")
	Util.Themable(gripB, "BackgroundColor3", "StrokeBright")

	------------------------------------------------------------------
	-- Behaviour: drag
	------------------------------------------------------------------
	local startAbs, startSize

	Util.Drag(titleBar, function(deltaX, deltaY)
		if not startAbs then
			return
		end
		local viewport = workspace.CurrentCamera.ViewportSize
		local nextX = math.clamp(startAbs.X + deltaX, -(startSize.X - 90), viewport.X - 90)
		local nextY = math.clamp(startAbs.Y + deltaY, 0, viewport.Y - 46)
		main.Position = UDim2.new(
			0.5,
			nextX - viewport.X / 2,
			0.5,
			nextY - viewport.Y / 2
		)
	end, function()
		startAbs = main.AbsolutePosition
		startSize = main.AbsoluteSize
		scaleTo(1.01, "Fast")
	end, function()
		scaleTo(1, "Fast")
	end)

	------------------------------------------------------------------
	-- Behaviour: resize
	------------------------------------------------------------------
	local resizeSize

	Util.Drag(resizer, function(deltaX, deltaY)
		if not resizeSize then
			return
		end
		local nextWidth = math.clamp(resizeSize.X + deltaX, L.WindowMinWidth, 1400)
		local nextHeight = math.clamp(resizeSize.Y + deltaY, L.WindowMinHeight, 900)
		main.Size = UDim2.fromOffset(nextWidth, nextHeight)
	end, function()
		resizeSize = main.AbsoluteSize
		Util.Tween(mainStroke, { Color = Util.Theme.Accent }, "Fast")
	end, function()
		Util.Tween(mainStroke, { Color = Util.Theme.Stroke }, "Fast")
	end)

	------------------------------------------------------------------
	-- Behaviour: minimize / close / theme
	------------------------------------------------------------------
	local expanded = UDim2.fromOffset(width, height)
	local minimized = false

	local function setMinimized(value: boolean)
		minimized = value
		if value then
			expanded = UDim2.fromOffset(main.AbsoluteSize.X, main.AbsoluteSize.Y)
			body.Visible = false
			if main:FindFirstChild("Footer") then
				main.Footer.Visible = false
			end
			Util.Tween(main, { Size = UDim2.new(0, expanded.X.Offset, 0, L.TitleBarHeight) }, "Smooth")
			Util.Tween(themeIcon, { Rotation = 45 }, "Fast")
		else
			body.Visible = true
			if main:FindFirstChild("Footer") then
				main.Footer.Visible = true
			end
			Util.Tween(main, { Size = expanded }, "Smooth")
			Util.Tween(themeIcon, { Rotation = 0 }, "Fast")
		end
	end

	Util.OnClick(minimizeButton, function()
		setMinimized(not minimized)
	end)

	------------------------------------------------------------------
	-- Behaviour: search
	------------------------------------------------------------------
	local resultsPanel
	local function closeResults()
		if resultsPanel then
			local dying = resultsPanel
			resultsPanel = nil
			dying:Destroy()
		end
	end
	self._closeSearchResults = closeResults

	local function buildResults(matches)
		closeResults()
		if #matches == 0 then
			return
		end

		resultsPanel = Util.New("Frame", {
			Name = "SearchResults",
			BackgroundColor3 = Util.Theme.Elevated,
			Position = UDim2.new(1, -338, 0, L.TitleBarHeight - 2),
			Size = UDim2.fromOffset(328, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = 700,
			Parent = main,
		})
		Util.Corner(12, resultsPanel)
		Util.Stroke(Util.Theme.StrokeBright, 1, 0.4, resultsPanel)
		Util.Padding({ X = 6, Y = 6 }, resultsPanel)
		Util.List({ Padding = UDim.new(0, 2), Parent = resultsPanel })
		Util.Themable(resultsPanel, "BackgroundColor3", "Elevated")

		for _, entry in ipairs(matches) do
			local row = Util.New("Frame", {
				Name = "Result",
				BackgroundColor3 = Util.Theme.SurfaceHover,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 34),
				BorderSizePixel = 0,
				Parent = resultsPanel,
			})
			Util.Corner(8, row)

			local name = Util.Text({
				Text = entry.Name,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = Util.Theme.Text,
				Position = UDim2.fromOffset(8, 4),
				Size = UDim2.new(1, -110, 0, 14),
				Parent = row,
			})
			Util.Themable(name, "TextColor3", "Text")

			local meta = Util.Text({
				Text = (entry.Section or entry.Kind or "") .. "  •  " .. (entry.TabName or ""),
				Font = Enum.Font.Gotham,
				TextSize = 10,
				TextColor3 = Util.Theme.TextDim,
				Position = UDim2.fromOffset(8, 17),
				Size = UDim2.new(1, -20, 0, 13),
				Parent = row,
			})
			Util.Themable(meta, "TextColor3", "TextDim")

			local jump = Util.New("Frame", {
				Name = "Jump",
				BackgroundColor3 = Util.Theme.AccentSoft,
				Size = UDim2.fromOffset(24, 20),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Parent = row,
			})
			Util.Corner(6, jump)
			Util.Themable(jump, "BackgroundColor3", "AccentSoft")
			local arrow = Icons.Get("chevronRight", jump, {
				Size = 9,
				Color = Util.Theme.Accent,
				Mask = Util.Theme.AccentSoft,
			})
			arrow.AnchorPoint = Vector2.new(0.5, 0.5)
			arrow.Position = UDim2.fromScale(0.5, 0.5)

			row.MouseEnter:Connect(function()
				Util.Tween(row, { BackgroundTransparency = 0 }, "Fast")
			end)
			row.MouseLeave:Connect(function()
				Util.Tween(row, { BackgroundTransparency = 1 }, "Fast")
			end)
			Util.OnClick(row, function()
				self:SelectTab(entry.Tab)
				if entry.Tab and entry.Frame then
					entry.Tab:ScrollTo(entry.Frame)
					self:_pulse(entry.Frame)
				end
				searchInput.Text = ""
				closeResults()
			end)
		end
	end

	local function runSearch(query: string)
		if query == "" then
			closeResults()
			return
		end
		local needle = string.lower(query)
		local matches = {}
		for _, entry in ipairs(self.SearchIndex) do
			if string.find(string.lower(entry.Name), needle, 1, true) then
				table.insert(matches, entry)
			end
			if #matches >= 8 then
				break
			end
		end
		buildResults(matches)
	end

	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		runSearch(searchInput.Text)
	end)

	------------------------------------------------------------------
	-- Window API
	------------------------------------------------------------------
	self._searchInput = searchInput
	self._searchHolder = searchHolder

	function self:_overlayFrameRef()
		return overlay
	end

	function self:_overlay(): Frame
		return overlay
	end

	function self:_notificationHolder(): Frame
		return notifications
	end

	function self:_registerSearch(entry)
		entry.Tab = entry.Tab or self.ActiveTab
		entry.TabName = entry.Tab and entry.Tab.Name or ""
		table.insert(self.SearchIndex, entry)
	end

	--- Brief accent flash used to point at a control.
	function self:_pulse(frame: GuiObject)
		if not frame or not frame.Parent then
			return
		end
		local original = frame.BackgroundColor3
		frame.BackgroundColor3 = Util.Theme.AccentSoft
		frame.BackgroundTransparency = 0.2
		task.delay(0.5, function()
			if frame and frame.Parent then
				Util.Tween(frame, { BackgroundTransparency = 1 }, 0.45)
				task.delay(0.45, function()
					if frame and frame.Parent then
						frame.BackgroundColor3 = original
					end
				end)
			end
		end)
	end
	self._flash = self._pulse

	function self:SelectTab(tab)
		if not tab then
			return
		end
		for _, other in ipairs(self.Tabs) do
			if other ~= tab then
				other:SetActive(false)
			end
		end
		tab:SetActive(true)
		self.ActiveTab = tab

		task.defer(function()
			if not (tab.Instance and tab.Instance.Parent and indicator.Parent) then
				return
			end
			local targetY = tab.Instance.AbsolutePosition.Y
				- sidebar.AbsolutePosition.Y
				+ tab.Instance.AbsoluteSize.Y / 2
			Util.Tween(indicator, { Position = UDim2.new(0, -1, 0, targetY) }, "Spring")
		end)
	end

	function self:CreateTab(tabConfig)
		local tab = Tab.New(self, tabConfig, #self.Tabs + 1)
		table.insert(self.Tabs, tab)
		if #self.Tabs == 1 then
			self:SelectTab(tab)
		end
		return tab
	end

	local MAX_TOASTS = 4

	function self:Notify(notifyConfig)
		if type(notifyConfig) == "string" then
			notifyConfig = { Title = notifyConfig }
		end

		notifyConfig = table.clone(notifyConfig)

		-- Trim the oldest toast so a burst never blankets the window.
		while #self._toasts >= MAX_TOASTS do
			local oldest = table.remove(self._toasts, 1)
			if oldest then
				oldest:Dismiss()
			end
		end

		local userDismiss = notifyConfig.OnDismiss
		notifyConfig.OnDismiss = function()
			for index, entry in ipairs(self._toasts) do
				if entry.Instance == nil then
					table.remove(self._toasts, index)
					break
				end
			end
			Util.SafeCall(userDismiss)
		end

		local object = Notification.New(self, notifyConfig)
		table.insert(self._toasts, object)
		return object
	end

	function self:ClearNotifications()
		for _, entry in ipairs(self._toasts) do
			entry:Dismiss()
		end
		self._toasts = {}
	end

	--- Uniform scale multiplier (1 = 100%). Combined with auto-fit.
	function self:SetScale(multiplier: number, silent: boolean?)
		userScale = math.clamp(multiplier, 0.5, 1.6)
		fitToViewport()
		if not silent then
			Util.SafeCall(config.OnScaleChanged, multiplier)
		end
	end

	function self:GetScale(): number
		return userScale
	end

	--- Recolor the accent everywhere without changing palette.
	-- Derives Accent2 / AccentSoft so the gradient stays coherent.
	function self:SetAccent(color: Color3, silent: boolean?)
		if not color then
			self.AccentOverride = nil
			Util.ApplyTheme(Theme.Get(self.ThemeName))
			Icons.RefreshAll(gui, Util.Theme.Surface)
			return
		end

		local base = Theme.Get(self.ThemeName)
		local palette = table.clone(base)
		palette.Accent = color
		palette.Accent2 = color:Lerp(Color3.new(1, 1, 1), 0.34)
		palette.AccentSoft = color:Lerp(base.Panel, 0.78)
		palette.AccentText = Util.Contrast(color)

		self.AccentOverride = color
		Util.ApplyTheme(palette)
		Icons.RefreshAll(gui, palette.Surface)

		if self._themeSwatch then
			self._themeSwatch.BackgroundColor3 = color
		end
		if not silent then
			Util.SafeCall(config.OnAccentChanged, color)
		end
	end

	function self:SetSubtle(text: string)
		subtitle.Text = text
	end
	self.SetSubtitle = self.SetSubtle

	function self:SetStatus(text: string, ok: boolean?)
		if self._statusLabel then
			self._statusLabel.Text = text
		end
		if self._statusDot then
			local color = ok == false and Util.Theme.Danger or (ok == nil and Util.Theme.Warning or Util.Theme.Success)
			self._statusDot.BackgroundColor3 = color
		end
	end

	function self:SetTheme(name: string)
		self.ThemeName = name
		Util.ApplyTheme(Theme.Get(name))
		Icons.RefreshAll(gui, Util.Theme.Surface)
		if self.AccentOverride then
			self:SetAccent(self.AccentOverride, true)
		end
		if self._themeLabel then
			self._themeLabel.Text = name
		end
		if self._themeSwatch then
			self._themeSwatch.BackgroundColor3 = Util.Theme.Accent
		end
		if blur then
			blur.Size = Util.Theme.Glass > 0 and 14 or 0
		end
		Util.SafeCall(config.OnThemeChanged, name)
	end

	function self:CycleTheme()
		local names = Theme.List()
		local index = 1
		for position, name in ipairs(names) do
			if name == self.ThemeName then
				index = position
				break
			end
		end
		local nextName = names[(index % #names) + 1]
		self:SetTheme(nextName)
		self:Notify({
			Title = "Theme changed",
			Body = "Now using " .. nextName .. ".",
			Type = "info",
			Duration = 2.4,
			Icon = "sun",
		})
	end

	--- Modal dialog with backdrop.
	function self:Modal(modalConfig)
		modalConfig = modalConfig or {}
		local dialog = {}

		local catcher = Util.New("TextButton", {
			Name = "ModalBackdrop",
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 800,
			Parent = overlay,
		})

		local card = Util.New("Frame", {
			Name = "Modal",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(modalConfig.Width or 340, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Util.Theme.Elevated,
			BorderSizePixel = 0,
			ZIndex = 801,
			Parent = overlay,
		})
		Util.Corner(16, card)
		Util.Stroke(Util.Theme.StrokeBright, 1, 0.35, card)
		Util.Padding(18, card)
		Util.List({ Padding = UDim.new(0, 10), Parent = card })
		Util.Themable(card, "BackgroundColor3", "Elevated")

		local scale = Util.Scale(card)
		scale.Scale = 0.94
		Util.Tween(scale, { Scale = 1 }, "Spring")
		Util.Tween(catcher, { BackgroundTransparency = 0.45 }, "Fast")

		local titleLabel = Util.Text({
			Text = modalConfig.Title or "Confirm",
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextColor3 = Util.Theme.Text,
			Size = UDim2.new(1, 0, 0, 20),
			Parent = card,
		})
		Util.Themable(titleLabel, "TextColor3", "Text")

		if modalConfig.Body then
			local bodyLabel = Util.Text({
				Text = modalConfig.Body,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Util.Theme.TextMuted,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = card,
			})
			Util.Themable(bodyLabel, "TextColor3", "TextMuted")
		end

		local actions = Util.New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 34),
			Parent = card,
		})
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			Parent = actions,
		})

		local function destroy()
			Util.Tween(scale, { Scale = 0.94 }, "Fast")
			Util.Tween(catcher, { BackgroundTransparency = 1 }, "Fast")
			Util.Fade(card, 1, "Fast")
			task.delay(0.16, function()
				card:Destroy()
				catcher:Destroy()
			end)
		end

		dialog.Close = destroy

		local cancel = Util.New("Frame", {
			Name = "Cancel",
			BackgroundColor3 = Util.Theme.Surface,
			Size = UDim2.fromOffset(86, 32),
			BorderSizePixel = 0,
			Parent = actions,
		})
		Util.Corner(9, cancel)
		Util.Stroke(Util.Theme.Stroke, 1, 0, cancel)
		Util.Themable(cancel, "BackgroundColor3", "Surface")
		local cancelLabel = Util.Text({
			Text = modalConfig.CancelText or "Cancel",
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Util.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = cancel,
		})
		Util.Themable(cancelLabel, "TextColor3", "Text")
		Util.OnClick(cancel, destroy)

		local confirm = Util.New("Frame", {
			Name = "Confirm",
			BackgroundColor3 = Util.Theme.Accent,
			Size = UDim2.fromOffset(96, 32),
			BorderSizePixel = 0,
			Parent = actions,
		})
		Util.Corner(9, confirm)
		Util.Gradient(ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2), 0, confirm)
		local confirmLabel = Util.Text({
			Text = modalConfig.ConfirmText or "Confirm",
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Util.Theme.AccentText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = confirm,
		})
		Util.OnClick(confirm, function()
			destroy()
			Util.SafeCall(modalConfig.OnConfirm)
		end)

		Util.OnClick(catcher, destroy)

		return dialog
	end

	------------------------------------------------------------------
	-- Mobile: floating toggle button
	-- Phones have no RightShift, so touch devices get a draggable FAB
	-- instead (and the keybind listener is simply never used).
	------------------------------------------------------------------
	if config.MobileButton ~= false and UserInputService.TouchEnabled then
		local fab = Util.New("Frame", {
			Name = "MobileToggle",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16, 0.5, -60),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = Util.Theme.Accent,
			BorderSizePixel = 0,
			ZIndex = 40,
			Visible = false,
			Parent = gui,
		})
		Util.Corner(999, fab)

		local fabGradient = Util.Gradient(
			ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2),
			45,
			fab
		)
		Util.Themable(fab, "BackgroundColor3", "Accent")
		Util.Themable(fabGradient, "Color", function(palette)
			return ColorSequence.new(palette.Accent, palette.Accent2)
		end)

		local fabStroke = Util.Stroke(Util.Theme.AccentText, 1.5, 0.75, fab)
		Util.Themable(fabStroke, "Color", "AccentText")

		local fabScaleReference = Util.Scale(fab)

		local fabIcon = Icons.Get(config.Icon or "sparkle", fab, {
			Size = 20,
			Color = Util.Theme.AccentText,
			Mask = Util.Theme.Accent,
		})
		fabIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		fabIcon.Position = UDim2.fromScale(0.5, 0.5)

		fab:SetAttribute("Tooltip", config.Title or "Menu")

		-- Drag to reposition (tap still opens the window).
		local fabStart, fabPosition, moved = nil, nil, false
		Util.Drag(fab, function(deltaX, deltaY)
			if math.abs(deltaX) + math.abs(deltaY) > 6 then
				moved = true
			end
			if not fabStart then
				return
			end
			local viewport = Util.Viewport()
			local x = math.clamp(fabPosition.X + deltaX, 0, viewport.X - fab.AbsoluteSize.X)
			local y = math.clamp(fabPosition.Y + deltaY, 0, viewport.Y - fab.AbsoluteSize.Y)
			fab.Position = UDim2.fromOffset(x, y)
		end, function()
			fabPosition = fab.AbsolutePosition
			moved = false
			Util.Tween(fabScaleReference, { Scale = 0.94 }, "Fast")
		end, function()
			Util.Tween(fabScaleReference, { Scale = 1 }, "Spring")
			if not moved then
				self:Open()
			end
		end)

		self._mobileToggle = fab
	end

	------------------------------------------------------------------
	-- Open / close
	------------------------------------------------------------------
	local function animateOpen()
		main.Visible = true
		fitToViewport()
		mainScale.Scale = baseScale * 0.94
		scaleTo(1, "Spring")

		-- The style's motion profile decides how the contents arrive: the
		-- chrome is already in place, the body staggers in behind it.
		if self._anim then
			self._anim.Entrance(body, motion, 12)
			self._anim.Entry(self._tabBar or sidebar, motion, 0)
		end
		if blur then
			blur.Size = 0
			TweenService:Create(
				blur,
				TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Size = Util.Theme.Glass > 0 and 14 or 0 }
			):Play()
		end
	end

	local open = true
	function self:Open()
		if open then
			return
		end
		open = true
		blocker.Visible = true
		if self._mobileToggle then
			self._mobileToggle.Visible = false
		end
		animateOpen()
	end

	function self:Close()
		if not open then
			return
		end
		open = false
		scaleTo(0.94, "Fast")
		task.delay(0.14, function()
			if not open then
				main.Visible = false
				blocker.Visible = false
				if self._mobileToggle then
					self._mobileToggle.Visible = true
				end
				if blur then
					TweenService:Create(blur, TweenInfo.new(0.25), { Size = 0 }):Play()
				end
			end
		end)
	end

	function self:Toggle()
		if open then
			self:Close()
		else
			self:Open()
		end
	end

	function self:IsOpen(): boolean
		return open
	end

	function self:Destroy()
		self.Alive = false
		if blur then
			blur:Destroy()
		end
		gui:Destroy()
	end

	self.Open = self.Open
	animateOpen()

	-- Global keybind ----------------------------------------------------
	if config.Keybind then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			if input.KeyCode == config.Keybind then
				self:Toggle()
			end
		end)
	end

	-- Re-fit on rotation / window resize / studio emulation change.
	local viewportConnection
	viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if self.Alive then
			fitToViewport()
		end
	end)

	Tooltip.Init(self)

	Util.SafeCall(config.OnBuilt, self)
	return self
end

return Window
