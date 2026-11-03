--[[
	Aurora UI  •  Notification.luau
	------------------------------------------------------------------
	Stacked toast cards with type theming, an icon, auto-dismiss timer
	and a shrinking progress bar. Toasts slide in with a scale/fade so
	the list layout can keep reflowing without fighting tweens.
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)

local Notification = {}

local TYPE_MAP = {
	info = { Token = "Info", Icon = "info" },
	success = { Token = "Success", Icon = "check" },
	warning = { Token = "Warning", Icon = "warning" },
	error = { Token = "Danger", Icon = "close" },
	default = { Token = "Accent", Icon = "sparkle" },
}

local function resolveType(config): (string, string)
	local entry = TYPE_MAP[config.Type or "default"] or TYPE_MAP.default
	return entry.Token, config.Icon or entry.Icon
end

function Notification.New(window, config: { [string]: any })
	config = config or {}
	local token, iconName = resolveType(config)
	local accent: Color3 = Util.Theme[token] or Util.Theme.Accent
	local duration = config.Duration or 4.5

	local holder = window:_notificationHolder()

	local card = Util.New("Frame", {
		Name = "Toast",
		BackgroundColor3 = Util.Theme.Elevated,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	})
	Util.Corner(12, card)
	local cardStroke = Util.Stroke(Util.Theme.StrokeBright, 1, 0.45, card)
	Util.Padding({ X = 14, Y = 12 }, card)
	Util.Themable(card, "BackgroundColor3", "Elevated")

	local scale = Util.Scale(card)
	scale.Scale = 0.94

	local content = Util.New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = content,
	})

	-- Accent rail ------------------------------------------------------
	local rail = Util.New("Frame", {
		Name = "Rail",
		BackgroundColor3 = accent,
		Size = UDim2.fromOffset(3, 30),
		BorderSizePixel = 0,
		Parent = card,
	})
	Util.Corner(999, rail)
	rail.AnchorPoint = Vector2.new(0, 0)
	rail.Position = UDim2.new(0, 0, 0, 12)
	rail.Size = UDim2.new(0, 3, 1, -24)

	-- Icon badge -------------------------------------------------------
	local badge = Util.New("Frame", {
		Name = "Badge",
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.84,
		Size = UDim2.fromOffset(26, 26),
		BorderSizePixel = 0,
		Parent = content,
	})
	Util.Corner(8, badge)

	local icon = Icons.Get(iconName, badge, {
		Size = 13,
		Color = accent,
		Mask = Util.Theme.Elevated,
	})
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)

	-- Text -------------------------------------------------------------
	local textHolder = Util.New("Frame", {
		Name = "Text",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -74, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = content,
	})
	Util.List({ Padding = UDim.new(0, 2), Parent = textHolder })

	if config.Title then
		local title = Util.Text({
			Name = "Title",
			Text = config.Title,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Util.Theme.Text,
			Size = UDim2.new(1, 0, 0, 17),
			Parent = textHolder,
		})
		Util.Themable(title, "TextColor3", "Text")
	end

	if config.Body then
		local body = Util.Text({
			Name = "Body",
			Text = config.Body,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = Util.Theme.TextMuted,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = textHolder,
		})
		Util.Themable(body, "TextColor3", "TextMuted")
	end

	-- Close ------------------------------------------------------------
	local closeButton = Util.New("Frame", {
		Name = "Close",
		BackgroundColor3 = Util.Theme.SurfaceHover,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
		BorderSizePixel = 0,
		Parent = card,
	})
	Util.Corner(6, closeButton)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, 0, 0, 0)

	local closeIcon = Icons.Get("close", closeButton, {
		Size = 9,
		Color = Util.Theme.TextDim,
		Mask = Util.Theme.Elevated,
	})
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)

	closeButton.MouseEnter:Connect(function()
		Util.Tween(closeButton, { BackgroundTransparency = 0 }, "Fast")
	end)
	closeButton.MouseLeave:Connect(function()
		Util.Tween(closeButton, { BackgroundTransparency = 1 }, "Fast")
	end)

	-- Progress ---------------------------------------------------------
	local progressTrack = Util.New("Frame", {
		Name = "ProgressTrack",
		BackgroundColor3 = Util.Theme.StrokeSoft,
		Size = UDim2.new(1, -28, 0, 2),
		BorderSizePixel = 0,
		Parent = card,
	})
	Util.Corner(999, progressTrack)
	progressTrack.AnchorPoint = Vector2.new(0, 1)
	progressTrack.Position = UDim2.new(0, 14, 1, -4)
	Util.Themable(progressTrack, "BackgroundColor3", "StrokeSoft")

	local progress = Util.New("Frame", {
		Name = "Progress",
		BackgroundColor3 = accent,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = progressTrack,
	})
	Util.Corner(999, progress)

	-- Lifecycle --------------------------------------------------------
	local object = { Instance = card, Kind = "Notification" }
	local dismissed = false

	local function dismiss()
		if dismissed or not card.Parent then
			return
		end
		dismissed = true
		Util.Tween(scale, { Scale = 0.9 }, "Fast")
		Util.Tween(card, { Size = UDim2.new(1, 0, 0, 0) }, "Fast")
		task.delay(0.2, function()
			if card then
				card:Destroy()
			end
		end)
		Util.SafeCall(config.OnDismiss)
	end

	Util.OnClick(closeButton, dismiss)
	Util.OnClick(card, function()
		if config.ClickToDismiss ~= false then
			dismiss()
		end
	end)

	-- Entrance ---------------------------------------------------------
	task.defer(function()
		Util.Tween(scale, { Scale = 1 }, "Spring")
	end)

	if duration > 0 then
		Util.Tween(progress, { Size = UDim2.fromScale(0, 1) }, duration)
		task.delay(duration, dismiss)
	end

	function object.Dismiss(self)
		dismiss()
	end

	return object
end

return Notification
