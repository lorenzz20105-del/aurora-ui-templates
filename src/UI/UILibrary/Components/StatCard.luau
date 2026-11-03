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

function StatCard.New(window, parent: Instance, config: { [string]: any })
	config = config or {}
	local token = config.Token or "Accent"

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
