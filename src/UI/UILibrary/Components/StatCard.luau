--[[
	Aurora UI  •  StatCard.luau
	------------------------------------------------------------------
	Dashboard metric card: label, animated counter, delta pill and a
	live sparkline built from bars. Meant to sit inside a UIGridLayout
	grid (see Tab:AddGrid).
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)

local StatCard = {}

local BAR_COUNT = 16

------------------------------------------------------------------
-- formatting shared by every variant
------------------------------------------------------------------

local function makeFormatter(config)
	return function(value: number): string
		if config.Format then
			local ok, text = pcall(config.Format, value)
			if ok then
				return tostring(text)
			end
		end
		return Util.FormatNumber(value)
	end
end

local function deltaText(config): string?
	if config.Delta == nil then
		return nil
	end
	local delta = config.Delta
	return string.format("%s%.1f%%", delta >= 0 and "+" or "", delta)
end

local function deltaColor(config): Color3
	if (config.Delta or 0) >= 0 then
		return Util.Theme.Success
	end
	return Util.Theme.Danger
end

------------------------------------------------------------------
-- variant: rows -- one line per metric, like a table row
------------------------------------------------------------------

local function buildRow(parent, config, token)
	local format = makeFormatter(config)

	local row = Util.New("Frame", {
		Name = "StatRow_" .. (config.Title or "Metric"),
		BackgroundColor3 = Util.Theme.Surface,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(8, row)
	Util.Padding({ X = 10 }, row)

	local line = Util.New("Frame", {
		Name = "Line",
		BackgroundColor3 = Util.Theme.StrokeSoft,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		Parent = row,
	})
	Util.Themable(line, "BackgroundColor3", "StrokeSoft")

	if config.Icon then
		local icon = Icons.Get(config.Icon, row, {
			Size = 13,
			Color = Util.Theme[token],
			Mask = Util.Theme.Surface,
		})
		Util.Themable(icon, "ImageColor3", token)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 0, 0.5, 0)
	end

	local title = Util.Text({
		Name = "Title",
		Text = config.Title or "Metric",
		Font = Util.M("Mono", false) and Enum.Font.Code or Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Util.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(config.Icon and 20 or 0, 0),
		Size = UDim2.new(0.5, -(config.Icon and 20 or 0), 1, 0),
		Parent = row,
	})
	Util.Themable(title, "TextColor3", "TextMuted")

	local value = Util.Text({
		Name = "Value",
		Text = format(config.Value or 0),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, config.Delta ~= nil and -46 or 0, 0, 0),
		Size = UDim2.fromOffset(80, 18),
		Parent = row,
	})
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.new(1, config.Delta ~= nil and -46 or 0, 0.5, 0)
	Util.Themable(value, "TextColor3", "Text")

	if config.Delta ~= nil then
		local delta = Util.Text({
			Name = "Delta",
			Text = deltaText(config),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = deltaColor(config),
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(42, 16),
			Parent = row,
		})
		Util.Themable(delta, "TextColor3", (config.Delta or 0) >= 0 and "Success" or "Danger")
	end

	return {
		Instance = row,
		Kind = "StatCard",
		SetValue = function(self, nextValue: number)
			value.Text = format(nextValue)
		end,
		SetData = function() end,
		SetDelta = function() end,
		Destroy = function(self)
			row:Destroy()
		end,
	}
end

------------------------------------------------------------------
-- variant: chips -- a compact pill, for dense dashboards
------------------------------------------------------------------

local function buildChip(parent, config, token)
	local format = makeFormatter(config)

	local chip = Util.New("Frame", {
		Name = "StatChip_" .. (config.Title or "Metric"),
		BackgroundColor3 = Util.Theme.Surface,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(999, chip)
	Util.Stroke(Util.Theme.StrokeSoft, 1, 0.2, chip)
	Util.Padding({ X = 12 }, chip)
	Util.Themable(chip, "BackgroundColor3", "Surface")

	local dot = Util.New("Frame", {
		Name = "Dot",
		BackgroundColor3 = Util.Theme[token],
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BorderSizePixel = 0,
		Parent = chip,
	})
	Util.Corner(999, dot)
	Util.Themable(dot, "BackgroundColor3", token)

	local value = Util.Text({
		Name = "Value",
		Text = format(config.Value or 0),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0.55, -16, 1, 0),
		Parent = chip,
	})
	Util.Themable(value, "TextColor3", "Text")

	local title = Util.Text({
		Name = "Title",
		Text = string.upper(config.Title or "Metric"),
		Font = Enum.Font.GothamMedium,
		TextSize = 9,
		TextColor3 = Util.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		Parent = chip,
	})
	Util.Themable(title, "TextColor3", "TextDim")

	return {
		Instance = chip,
		Kind = "StatCard",
		SetValue = function(self, nextValue: number)
			value.Text = format(nextValue)
		end,
		SetData = function() end,
		SetDelta = function() end,
		Destroy = function(self)
			chip:Destroy()
		end,
	}
end

------------------------------------------------------------------
-- variant: headline -- one big number, thin fill bar underneath
------------------------------------------------------------------

local function buildHeadline(parent, config, token)
	local format = makeFormatter(config)

	local card = Util.New("Frame", {
		Name = "StatHeadline_" .. (config.Title or "Metric"),
		BackgroundColor3 = Util.Theme.Surface,
		BackgroundTransparency = 0.06,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(16, card)
	Util.Padding({ X = 14, Y = 10 }, card)
	Util.Themable(card, "BackgroundColor3", "Surface")

	local label = Util.Text({
		Name = "Label",
		Text = string.upper(config.Title or "Metric"),
		Font = Enum.Font.GothamMedium,
		TextSize = 9,
		TextColor3 = Util.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 12),
		Parent = card,
	})
	Util.Themable(label, "TextColor3", "TextDim")

	local value = Util.Text({
		Name = "Value",
		Text = format(config.Value or 0),
		Font = Enum.Font.GothamBlack,
		TextSize = 27,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, -46, 0, 32),
		Parent = card,
	})
	Util.Themable(value, "TextColor3", "Text")

	if config.Delta ~= nil then
		local delta = Util.Text({
			Name = "Delta",
			Text = deltaText(config),
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = deltaColor(config),
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 22),
			Size = UDim2.fromOffset(44, 16),
			Parent = card,
		})
		Util.Themable(delta, "TextColor3", (config.Delta or 0) >= 0 and "Success" or "Danger")
	end

	-- fill bar: the only chart this variant has
	local track = Util.New("Frame", {
		Name = "Track",
		BackgroundColor3 = Util.Theme.StrokeSoft,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 3),
		BorderSizePixel = 0,
		Parent = card,
	})
	Util.Corner(999, track)
	Util.Themable(track, "BackgroundColor3", "StrokeSoft")

	local peak = config.Max or ((config.Value or 0) * 1.32)
	local fill = Util.New("Frame", {
		Name = "Fill",
		BackgroundColor3 = Util.Theme[token],
		Size = UDim2.fromScale(math.clamp((config.Value or 0) / math.max(peak, 0.001), 0.05, 1), 1),
		BorderSizePixel = 0,
		Parent = track,
	})
	Util.Corner(999, fill)
	Util.Gradient(ColorSequence.new(Util.Theme[token], Util.Theme.Accent2), 0, fill)
	Util.Themable(fill, "BackgroundColor3", token)

	return {
		Instance = card,
		Kind = "StatCard",
		SetValue = function(self, nextValue: number)
			value.Text = format(nextValue)
			fill.Size = UDim2.fromScale(math.clamp(nextValue / math.max(peak, 0.001), 0.05, 1), 1)
		end,
		SetData = function() end,
		SetDelta = function() end,
		Destroy = function(self)
			card:Destroy()
		end,
	}
end

------------------------------------------------------------------
-- variant: dials -- a ring of segments, no chart, no numbers row
------------------------------------------------------------------

local SEGMENTS = 14
local DIAL_SIZE = 64

local function buildDial(parent, config, token)
	local format = makeFormatter(config)

	local card = Util.New("Frame", {
		Name = "StatDial_" .. (config.Title or "Metric"),
		BackgroundColor3 = Util.Theme.Surface,
		BackgroundTransparency = 0.08,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(16, card)
	Util.Themable(card, "BackgroundColor3", "Surface")

	local dial = Util.New("Frame", {
		Name = "Dial",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(DIAL_SIZE, DIAL_SIZE),
		Parent = card,
	})

	local samples = config.Data or {}
	local peak = config.Max or 0
	if peak <= 0 then
		for _, sample in ipairs(samples) do
			peak = math.max(peak, sample)
		end
		peak = math.max(peak, (config.Value or 0) * 1.25, 1)
	end
	local fraction = math.clamp((config.Value or 0) / peak, 0, 1)
	local lit = math.max(1, math.round(fraction * SEGMENTS))

	local radius = DIAL_SIZE / 2 - 3
	for index = 1, SEGMENTS do
		local angle = math.rad(-90 + (index - 1) * (360 / SEGMENTS))
		local dot = Util.New("Frame", {
			Name = "Seg" .. index,
			BackgroundColor3 = index <= lit and Util.Theme[token] or Util.Theme.Stroke,
			BackgroundTransparency = index <= lit and 0 or 0.65,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(
				0.5,
				math.cos(angle) * radius,
				0.5,
				math.sin(angle) * radius
			),
			Size = UDim2.fromOffset(4, 4),
			BorderSizePixel = 0,
			Parent = dial,
		})
		Util.Corner(999, dot)
		Util.Themable(dot, "BackgroundColor3", index <= lit and token or "Stroke")
	end

	local value = Util.Text({
		Name = "Value",
		Text = format(config.Value or 0),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.fromScale(0.78, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = dial,
	})
	Util.Themable(value, "TextColor3", "Text")

	local title = Util.Text({
		Name = "Title",
		Text = config.Title or "Metric",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Util.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(DIAL_SIZE + 22, 14),
		Size = UDim2.new(1, -(DIAL_SIZE + 34), 0, 16),
		Parent = card,
	})
	Util.Themable(title, "TextColor3", "TextMuted")

	local sub = Util.Text({
		Name = "Sub",
		Text = deltaText(config) or string.format("%d%% of %s", math.round(fraction * 100), format(peak)),
		Font = Util.M("Mono", false) and Enum.Font.Code or Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = deltaColor(config),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(DIAL_SIZE + 22, 32),
		Size = UDim2.new(1, -(DIAL_SIZE + 34), 0, 14),
		Parent = card,
	})
	Util.Themable(sub, "TextColor3", (config.Delta or 0) >= 0 and "Success" or "Danger")

	return {
		Instance = card,
		Kind = "StatCard",
		SetValue = function(self, nextValue: number)
			value.Text = format(nextValue)
			local now = math.max(1, math.round(math.clamp(nextValue / peak, 0, 1) * SEGMENTS))
			for index = 1, SEGMENTS do
				local seg = dial:FindFirstChild("Seg" .. index)
				if seg then
					seg.BackgroundTransparency = index <= now and 0 or 0.65
				end
			end
		end,
		SetData = function() end,
		SetDelta = function() end,
		Destroy = function(self)
			card:Destroy()
		end,
	}
end

function StatCard.New(window, parent: Instance, config: { [string]: any })
	config = config or {}
	local token = config.Token or "Accent"

	-- The style's blueprint picks the presentation: three cards, a table of
	-- rows, a row of pills, one hero number, or a ring of dials.
	local variant = config.Variant or Util.M("Stats", "cards")
	if variant == "rows" then
		return buildRow(parent, config, token)
	elseif variant == "chips" then
		return buildChip(parent, config, token)
	elseif variant == "headline" then
		return buildHeadline(parent, config, token)
	elseif variant == "dials" then
		return buildDial(parent, config, token)
	end

	local card = Util.New("Frame", {
		Name = "Stat_" .. (config.Title or "Metric"),
		BackgroundColor3 = Util.Theme.Surface,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = parent,
	})
	Util.Corner(14, card)
	Util.Stroke(Util.Theme.StrokeSoft, 1, 0, card)
	Util.Padding(12, card)
	Util.Themable(card, "BackgroundColor3", "Surface")

	-- Header -----------------------------------------------------------
	local header = Util.New("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = card,
	})
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 7),
		Parent = header,
	})

	if config.Icon then
		local badge = Util.New("Frame", {
			Name = "Badge",
			BackgroundColor3 = Util.Theme[token],
			BackgroundTransparency = 0.85,
			Size = UDim2.fromOffset(20, 20),
			BorderSizePixel = 0,
			Parent = header,
		})
		Util.Corner(6, badge)
		Util.Themable(badge, "BackgroundColor3", function(palette)
			return palette[token]
		end)
		badge.BackgroundTransparency = 0.85

		local icon = Icons.Get(config.Icon, badge, {
			Size = 11,
			Color = Util.Theme[token],
			Mask = Util.Theme.Surface,
		})
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
	end

	local title = Util.Text({
		Name = "Title",
		Text = config.Title or "Metric",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Util.Theme.TextMuted,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = header,
	})
	Util.Themable(title, "TextColor3", "TextMuted")

	-- Value ------------------------------------------------------------
	local valueRow = Util.New("Frame", {
		Name = "ValueRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = card,
	})
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = valueRow,
	})

	local valueLabel = Util.Text({
		Name = "Value",
		Text = "0",
		Font = Enum.Font.GothamBold,
		TextSize = 21,
		TextColor3 = Util.Theme.Text,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = valueRow,
	})
	Util.Themable(valueLabel, "TextColor3", "Text")

	local deltaPill = Util.New("Frame", {
		Name = "Delta",
		BackgroundColor3 = Util.Theme.Success,
		BackgroundTransparency = 0.85,
		Size = UDim2.fromOffset(0, 19),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		Parent = valueRow,
	})
	Util.Corner(999, deltaPill)
	Util.Padding({ X = 6 }, deltaPill)
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
		Parent = deltaPill,
	})

	local deltaIconUp = Icons.Get("chevronUp", deltaPill, {
		Size = 9,
		Color = Util.Theme.Success,
		Mask = Util.Theme.Surface,
	})
	local deltaIconDown = Icons.Get("chevronDown", deltaPill, {
		Size = 9,
		Color = Util.Theme.Danger,
		Mask = Util.Theme.Surface,
	})
	deltaIconDown.Visible = false

	local deltaLabel = Util.Text({
		Name = "DeltaText",
		Text = "0%",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = Util.Theme.Success,
		Size = UDim2.fromOffset(0, 19),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = deltaPill,
	})
	Util.Themable(deltaLabel, "TextColor3", "Success")

	-- Sparkline --------------------------------------------------------
	local chart = Util.New("Frame", {
		Name = "Chart",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 26),
		Parent = card,
	})

	local bars = {}
	for index = 1, BAR_COUNT do
		local bar = Util.New("Frame", {
			Name = "Bar" .. index,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new((index - 1) / BAR_COUNT, 0, 1, 0),
			Size = UDim2.new((1 / BAR_COUNT) - 0.012, 0, 0.05, 0),
			BackgroundColor3 = Util.Theme[token],
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Parent = chart,
		})
		Util.Corner(2, bar)
		Util.Themable(bar, "BackgroundColor3", function(palette)
			return palette[token]
		end)
		bars[index] = bar
	end

	-- State ------------------------------------------------------------
	local displayed = 0
	local target = config.Value or 0
	local data = config.Data or {}

	local function format(value: number): string
		if config.Format then
			local ok, text = pcall(config.Format, value)
			if ok then
				return tostring(text)
			end
		end
		return Util.FormatNumber(value)
	end

	local function renderBars(animate: boolean)
		local samples = {}
		if #data == 0 then
			for index = 1, BAR_COUNT do
				samples[index] = 0.15
			end
		else
			for index = 1, BAR_COUNT do
				local sourceIndex = math.clamp(
					math.floor(((index - 1) / (BAR_COUNT - 1)) * (#data - 1)) + 1,
					1,
					#data
				)
				samples[index] = data[sourceIndex]
			end
		end

		local maxValue = 0.0001
		for _, sample in ipairs(samples) do
			maxValue = math.max(maxValue, sample)
		end

		for index, bar in ipairs(bars) do
			local height = math.clamp(samples[index] / maxValue, 0.08, 1)
			local size = UDim2.new((1 / BAR_COUNT) - 0.012, 0, height, 0)
			if animate then
				Util.Tween(bar, { Size = size }, 0.35 + index * 0.012)
				Util.Tween(bar, { BackgroundTransparency = 0.25 + (1 - height) * 0.45 }, "Fast")
			else
				bar.Size = size
			end
		end
	end

	local function renderDelta()
		local delta = config.Delta or 0
		local positive = delta >= 0
		local palette = Util.Theme
		local color = positive and palette.Success or palette.Danger

		deltaPill.Visible = config.Delta ~= nil
		deltaLabel.Text = string.format("%s%.1f%%", positive and "+" or "", delta)
		deltaLabel.TextColor3 = color
		deltaPill.BackgroundColor3 = color
		deltaPill.BackgroundTransparency = 0.85
		deltaIconUp.Visible = positive
		deltaIconDown.Visible = not positive
		Icons.Tint(deltaIconUp, color)
		Icons.Tint(deltaIconDown, color)
	end

	local function countUp(to: number)
		local from = displayed
		Util.Animate(0.55, function(alpha)
			displayed = from + (to - from) * alpha
			valueLabel.Text = format(displayed)
		end)
	end

	local object = { Instance = card, Kind = "StatCard" }

	renderDelta()
	renderBars(false)
	countUp(target)

	function object.SetValue(self, value: number, nextData: { number }?, animate: boolean?)
		target = value
		if nextData then
			data = nextData
			renderBars(animate ~= false)
		end
		countUp(value)
	end

	function object.SetData(self, nextData: { number })
		data = nextData
		renderBars(true)
	end

	function object.SetDelta(self, delta: number)
		config.Delta = delta
		renderDelta()
	end

	function object.Destroy(self)
		card:Destroy()
	end

	return object
end

return StatCard
