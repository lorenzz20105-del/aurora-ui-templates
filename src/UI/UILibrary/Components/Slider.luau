--[[
	Aurora UI  •  Slider.luau
	------------------------------------------------------------------
	Full-width gradient slider with draggable knob, live value pill and
	step snapping. Designed as a two-line row so long labels never get
	squeezed by the control.
--]]

local Util = require(script.Parent.Parent.Util)
local UserInputService = game:GetService("UserInputService")

local Slider = {}

function Slider.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local min = config.Min or 0
	local max = config.Max or 100
	local step = config.Step or 1
	local decimals = config.Decimals or (step < 1 and 2 or 0)
	local suffix = config.Suffix or ""
	local prefix = config.Prefix or ""
	local hasDescription = config.Description ~= nil and config.Description ~= ""
	local height = config.Height or (hasDescription and 68 or 54)

	local value = math.clamp(config.Default or min, min, max)
	local dragging = false
	local object = {}

	-- Shell -----------------------------------------------------------
	local frame = Util.New("Frame", {
		Name = "Slider_" .. (config.Name or "Value"),
		BackgroundColor3 = Util.Theme.Surface,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(10, frame)

	local hovered = false
	Util.Themable(frame, "BackgroundColor3", function(palette)
		return hovered and palette.SurfaceHover or palette.Surface
	end)

	frame.MouseEnter:Connect(function()
		hovered = true
		Util.Tween(frame, { BackgroundTransparency = 0.35 }, "Fast")
	end)
	frame.MouseLeave:Connect(function()
		hovered = false
		if not dragging then
			Util.Tween(frame, { BackgroundTransparency = 1 }, "Fast")
		end
	end)

	local label = Util.Text({
		Name = "Label",
		Text = config.Name or "",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Util.Theme.Text,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -110, 0, 17),
		Parent = frame,
	})
	Util.Themable(label, "TextColor3", "Text")

	local description
	if hasDescription then
		description = Util.Text({
			Name = "Description",
			Text = config.Description,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = Util.Theme.TextMuted,
			Position = UDim2.new(0, 12, 0, 25),
			Size = UDim2.new(1, -110, 0, 15),
			Parent = frame,
		})
		Util.Themable(description, "TextColor3", "TextMuted")
	end

	-- Value pill ------------------------------------------------------
	local valuePill = Util.New("Frame", {
		Name = "ValuePill",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Util.Theme.AccentSoft,
		BorderSizePixel = 0,
		Parent = frame,
	})
	Util.Corner(6, valuePill)
	Util.Padding({ X = 8 }, valuePill)
	Util.Themable(valuePill, "BackgroundColor3", "AccentSoft")

	local valueLabel = Util.Text({
		Name = "Value",
		Text = "0",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Util.Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = valuePill,
	})
	Util.Themable(valueLabel, "TextColor3", "Accent")

	-- Track -----------------------------------------------------------
	local trackY = hasDescription and 47 or 35

	local hitbox = Util.New("Frame", {
		Name = "Hitbox",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, trackY - 8),
		Size = UDim2.new(1, -24, 0, 22),
		Parent = frame,
	})

	local track = Util.New("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Util.Theme.SurfaceActive,
		BorderSizePixel = 0,
		Parent = hitbox,
	})
	Util.Corner(999, track)
	Util.Themable(track, "BackgroundColor3", "SurfaceActive")

	local fillGradient
	local fill = Util.New("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Util.Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Util.Corner(999, fill)
	fillGradient = Util.Gradient(ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2), 0, fill)
	Util.Themable(fill, "BackgroundColor3", "Accent")
	Util.Themable(fillGradient, "Color", function(palette)
		return ColorSequence.new(palette.Accent, palette.Accent2)
	end)

	local knob = Util.New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = track.ZIndex + 2,
		Parent = track,
	})
	Util.Corner(999, knob)
	local knobStroke = Util.Stroke(Util.Theme.Accent, 2, 0, knob)

	local knobHalo = Util.New("Frame", {
		Name = "Halo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Util.Theme.Accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = knob.ZIndex - 1,
		Parent = knob,
	})
	Util.Corner(999, knobHalo)
	knobHalo.Size = UDim2.fromOffset(26, 26)
	knobHalo.BackgroundTransparency = 0.86
	Util.Themable(knobHalo, "BackgroundColor3", "Accent")
	Util.Themable(knobStroke, "Color", "Accent")

	-- Formatting ------------------------------------------------------
	local function format(current: number): string
		if config.Format then
			local ok, text = pcall(config.Format, current)
			if ok then
				return tostring(text)
			end
		end
		return prefix .. Util.TrimNumber(current, decimals) .. suffix
	end

	local function alphaOf(current: number): number
		if max == min then
			return 0
		end
		return (current - min) / (max - min)
	end

	local function render()
		local alpha = alphaOf(value)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = format(value)
	end

	local function commit(nextValue: number, fireCallback: boolean?)
		local snapped = nextValue
		if step and step > 0 then
			snapped = math.floor((nextValue - min) / step + 0.5) * step + min
		end
		snapped = math.clamp(Util.Round(snapped, decimals + 2), min, max)
		if snapped == value and fireCallback ~= true then
			return
		end
		value = snapped
		object.Value = value
		render()
		if fireCallback ~= false then
			Util.SafeCall(config.Callback, value)
		end
	end

	local function setFromX(x: number)
		local left = track.AbsolutePosition.X
		local width = math.max(track.AbsoluteSize.X, 1)
		local alpha = math.clamp((x - left) / width, 0, 1)
		commit(min + (max - min) * alpha, true)
	end

	-- Input -----------------------------------------------------------
	local function endDrag()
		if not dragging then
			return
		end
		dragging = false
		Util.Tween(frame, { BackgroundTransparency = hovered and 0.35 or 1 }, "Fast")
		Util.Tween(knob, { Size = UDim2.fromOffset(14, 14) }, "Spring")
		Util.Tween(knobHalo, { Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 0.86 }, "Fast")
		Util.SafeCall(config.OnRelease, value)
	end

	hitbox.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		dragging = true
		Util.Tween(knob, { Size = UDim2.fromOffset(17, 17) }, "Spring")
		Util.Tween(knobHalo, { Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 0.72 }, "Fast")
		setFromX(input.Position.X)
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			endDrag()
		end
	end)

	-- Scroll wheel nudge while hovering -------------------------------
	hitbox.MouseWheelForward:Connect(function()
		if hovered then
			commit(value + (step or 1), true)
		end
	end)
	hitbox.MouseWheelBackward:Connect(function()
		if hovered then
			commit(value - (step or 1), true)
		end
	end)

	render()

	object.Instance = frame
	object.Kind = "Slider"
	object.Value = value

	function object.Get(self): number
		return value
	end

	function object.Set(self, nextValue: number, silent: boolean?)
		commit(nextValue, not silent)
	end

	function object.SetRange(self, nextMin: number, nextMax: number)
		min, max = nextMin, nextMax
		commit(value, false)
	end

	if config.Tooltip then
		frame:SetAttribute("Tooltip", config.Tooltip)
	end

	return object
end

return Slider
