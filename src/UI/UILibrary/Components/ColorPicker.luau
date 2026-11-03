--[[
	Aurora UI  •  ColorPicker.luau
	------------------------------------------------------------------
	Swatch trigger + floating picker with:
	  • saturation / value area
	  • hue strip
	  • live hex field
	  • preset palette
	Fires Callback(Color3) live while dragging.
--]]

local Util = require(script.Parent.Parent.Util)
local Row = require(script.Parent.Row)
local UserInputService = game:GetService("UserInputService")

local ColorPicker = {}

local PRESETS = {
	"#7C5CFF", "#22D3EE", "#34D399", "#FBBF24",
	"#FB7185", "#F472B6", "#60A5FA", "#E5E7EB",
}

local function hueSequence(): ColorSequence
	local keys = {}
	for index = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1)))
	end
	return ColorSequence.new(keys)
end

function ColorPicker.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local h, s, v = Color3.toHSV(config.Default or Color3.fromHex("#7C5CFF"))
	local color = Color3.fromHSV(h, s, v)

	local row = Row.Create(parent, {
		Name = config.Name,
		Description = config.Description,
		Height = config.Height,
	})

	-- Trigger ---------------------------------------------------------
	local trigger = Util.New("Frame", {
		Name = "Trigger",
		BackgroundColor3 = Util.Theme.Surface,
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		Parent = row.Right,
	})
	Util.Corner(7, trigger)
	Util.Stroke(Util.Theme.Stroke, 1, 0, trigger)
	Util.Padding({ X = 8 }, trigger)
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 7),
		Parent = trigger,
	})
	Util.Themable(trigger, "BackgroundColor3", "Surface")

	local swatch = Util.New("Frame", {
		Name = "Swatch",
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(16, 16),
		BorderSizePixel = 0,
		Parent = trigger,
	})
	Util.Corner(5, swatch)
	Util.Stroke(Color3.new(0, 0, 0), 1, 0.7, swatch)

	local hexLabel = Util.Text({
		Name = "Hex",
		Text = "#" .. Util.ToHex(color),
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Util.Theme.Text,
		Size = UDim2.fromOffset(60, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = trigger,
	})
	Util.Themable(hexLabel, "TextColor3", "Text")

	local object = { Instance = row.Frame, Kind = "ColorPicker" }
	local popup, catcher, isOpen = nil, nil, false
	local close

	local function renderTrigger()
		swatch.BackgroundColor3 = color
		hexLabel.Text = "#" .. Util.ToHex(color)
		object.Value = color
	end

	-- Picker ----------------------------------------------------------
	local function build()
		local overlay = window:_overlay()
		local width = 236

		catcher = Util.New("Frame", {
			Name = "ColorCatcher",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 900,
			Parent = overlay,
		})

		popup = Util.New("Frame", {
			Name = "ColorPicker",
			BackgroundColor3 = Util.Theme.Elevated,
			Size = UDim2.fromOffset(width, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = 901,
			Parent = overlay,
		})
		Util.Corner(12, popup)
		Util.Stroke(Util.Theme.StrokeBright, 1, 0.4, popup)
		Util.Padding(10, popup)
		Util.List({ Padding = UDim.new(0, 8), Parent = popup })
		Util.Themable(popup, "BackgroundColor3", "Elevated")

		-- Saturation / value area -------------------------------------
		local sv = Util.New("Frame", {
			Name = "SV",
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Size = UDim2.new(1, 0, 0, 108),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = popup,
		})
		Util.Corner(8, sv)

		Util.Gradient(
			ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
			0,
			sv
		).Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})

		local shade = Util.New("Frame", {
			Name = "Shade",
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0,
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			Parent = sv,
		})
		Util.Corner(8, shade)
		Util.Gradient(
			ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
			90,
			shade
		).Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})

		local cursor = Util.New("Frame", {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = sv,
		})
		Util.Corner(999, cursor)
		Util.Stroke(Color3.new(1, 1, 1), 2, 0, cursor)

		-- Hue strip ----------------------------------------------------
		local hueStrip = Util.New("Frame", {
			Name = "Hue",
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 0, 12),
			BorderSizePixel = 0,
			Parent = popup,
		})
		Util.Corner(999, hueStrip)
		Util.Gradient(hueSequence(), 0, hueStrip)

		local hueKnob = Util.New("Frame", {
			Name = "HueKnob",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(h, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = hueStrip,
		})
		Util.Corner(999, hueKnob)
		Util.Stroke(Color3.new(0, 0, 0), 1, 0.6, hueKnob)

		-- Hex row ------------------------------------------------------
		local bottom = Util.New("Frame", {
			Name = "Bottom",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			Parent = popup,
		})
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			Parent = bottom,
		})

		local field = Util.New("Frame", {
			Name = "HexField",
			BackgroundColor3 = Util.Theme.Surface,
			Size = UDim2.new(1, -108, 1, 0),
			BorderSizePixel = 0,
			Parent = bottom,
		})
		Util.Corner(7, field)
		Util.Padding({ X = 8 }, field)
		Util.Themable(field, "BackgroundColor3", "Surface")

		local hexInput = Util.New("TextBox", {
			Name = "Hex",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.Code,
			TextSize = 12,
			Text = "#" .. Util.ToHex(color),
			TextColor3 = Util.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = field,
		})
		Util.Themable(hexInput, "TextColor3", "Text")

		local preview = Util.New("Frame", {
			Name = "Preview",
			BackgroundColor3 = color,
			Size = UDim2.fromOffset(100, 30),
			BorderSizePixel = 0,
			Parent = bottom,
		})
		Util.Corner(7, preview)
		Util.Stroke(Color3.new(1, 1, 1), 1, 0.85, preview)

		-- Preset swatches ----------------------------------------------
		local presetRow = Util.New("Frame", {
			Name = "Presets",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Parent = popup,
		})
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			Parent = presetRow,
		})

		-- Rendering ----------------------------------------------------
		local function apply(nextColor: Color3, fireCallback: boolean?)
			color = nextColor
			h, s, v = Color3.toHSV(color)
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			cursor.Position = UDim2.new(s, 0, 1 - v, 0)
			cursor.BackgroundColor3 = color
			hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
			preview.BackgroundColor3 = color
			hexInput.Text = "#" .. Util.ToHex(color)
			swatch.BackgroundColor3 = color
			hexLabel.Text = "#" .. Util.ToHex(color)
			object.Value = color
			if fireCallback ~= false then
				Util.SafeCall(config.Callback, color)
			end
		end

		local function pickSV(x: number, y: number)
			local sx = math.clamp((x - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
			local sy = math.clamp((y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
			apply(Color3.fromHSV(h, sx, 1 - sy))
		end

		apply(color, false)

		local svDragging, hueDragging = false, false

		sv.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				svDragging = true
				pickSV(input.Position.X, input.Position.Y)
			end
		end)

		hueStrip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				hueDragging = true
				local nx = math.clamp((input.Position.X - hueStrip.AbsolutePosition.X) / math.max(hueStrip.AbsoluteSize.X, 1), 0, 1)
				apply(Color3.fromHSV(nx, math.max(s, 0.01), math.max(v, 0.01)))
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not popup or not popup.Parent then
				return
			end
			if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				pickSV(input.Position.X, input.Position.Y)
			elseif hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local nx = math.clamp((input.Position.X - hueStrip.AbsolutePosition.X) / math.max(hueStrip.AbsoluteSize.X, 1), 0, 1)
				h = nx
				apply(Color3.fromHSV(h, math.max(s, 0.01), math.max(v, 0.01)))
			end
		end)

		UserInputService.InputEnded:Connect(function()
			svDragging, hueDragging = false, false
		end)

		hexInput.FocusLost:Connect(function()
			local text = string.gsub(hexInput.Text, "#", "")
			if #text == 6 and string.match(text, "^%x+$") then
				apply(Color3.fromHex(text))
			else
				hexInput.Text = "#" .. Util.ToHex(color)
			end
		end)

		for _, preset in ipairs(PRESETS) do
			local dot = Util.New("Frame", {
				Name = "Preset",
				BackgroundColor3 = Color3.fromHex(preset),
				Size = UDim2.fromOffset(20, 20),
				BorderSizePixel = 0,
				Parent = presetRow,
			})
			Util.Corner(6, dot)
			Util.Stroke(Color3.new(1, 1, 1), 1, 0.88, dot)
			Util.OnClick(dot, function()
				apply(Color3.fromHex(preset))
			end)
			dot.MouseEnter:Connect(function()
				Util.Tween(dot, { Size = UDim2.fromOffset(22, 22) }, "Fast")
			end)
			dot.MouseLeave:Connect(function()
				Util.Tween(dot, { Size = UDim2.fromOffset(20, 20) }, "Fast")
			end)
		end

		-- Position -----------------------------------------------------
		local overlayPos = overlay.AbsolutePosition
		local triggerTop = trigger.AbsolutePosition.Y - overlayPos.Y
		local triggerBottom = triggerTop + trigger.AbsoluteSize.Y
		local estimated = 214
		local x = math.clamp(
			trigger.AbsolutePosition.X - overlayPos.X + trigger.AbsoluteSize.X - width,
			8,
			math.max(8, overlay.AbsoluteSize.X - width - 8)
		)
		popup.Position = UDim2.fromOffset(
			x,
			(triggerBottom + estimated > overlay.AbsoluteSize.Y - 8) and math.max(8, triggerTop - estimated - 6) or (triggerBottom + 6)
		)

		local scale = Util.Scale(popup)
		scale.Scale = 0.96
		Util.Tween(scale, { Scale = 1 }, "Fast")

		Util.OnClick(catcher, close)
	end

	close = function()
		if not isOpen then
			return
		end
		isOpen = false
		if catcher then
			catcher:Destroy()
			catcher = nil
		end
		if popup then
			local dying = popup
			popup = nil
			Util.Fade(dying, 1, "Fast")
			task.delay(0.16, function()
				if dying then
					dying:Destroy()
				end
			end)
		end
	end

	Util.OnClick(trigger, function()
		if isOpen then
			close()
		else
			isOpen = true
			build()
		end
	end)
	Util.OnClick(row.Frame, function()
		if not isOpen then
			isOpen = true
			build()
		end
	end)

	renderTrigger()

	function object.Get(self): Color3
		return color
	end

	function object.Set(self, nextColor: Color3, silent: boolean?)
		color = nextColor
		h, s, v = Color3.toHSV(color)
		renderTrigger()
		if not silent then
			Util.SafeCall(config.Callback, color)
		end
	end

	function object.Destroy(self)
		close()
		row.Frame:Destroy()
	end

	return object
end

return ColorPicker
