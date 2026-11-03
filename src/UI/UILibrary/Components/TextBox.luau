--[[
	Aurora UI  •  TextBox.luau
	------------------------------------------------------------------
	Text input with placeholder, optional leading icon, clear button,
	numeric filtering, validation hook and focus ring animation.
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)
local Row = require(script.Parent.Row)

local TextBox = {}

function TextBox.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local row = Row.Create(parent, {
		Name = config.Name,
		Description = config.Description,
		Height = config.Height or (config.FullWidth and 56 or nil),
	})

	local width = config.Width or 180
	local height = config.Height or 30

	local wrapper = Util.New("Frame", {
		Name = "Input",
		BackgroundColor3 = Util.Theme.Surface,
		Size = config.FullWidth and UDim2.new(1, 0, 0, 32) or UDim2.fromOffset(width, height),
		BorderSizePixel = 0,
		Parent = row.Right,
	})
	Util.Corner(8, wrapper)
	local stroke = Util.Stroke(Util.Theme.Stroke, 1, 0, wrapper)
	Util.Padding({ X = config.Icon and 30 or 10 }, wrapper)
	Util.Themable(wrapper, "BackgroundColor3", "Surface")
	Util.Themable(stroke, "Color", "Stroke")

	if config.Icon then
		local icon = Icons.Get(config.Icon, wrapper, {
			Size = 13,
			Color = Util.Theme.TextDim,
			Mask = Util.Theme.Surface,
		})
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, -22, 0.5, 0)
		Util.Themable(icon, "BackgroundColor3", "Surface")
	end

	local input = Util.New("TextBox", {
		Name = "Field",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, config.ClearButton and -18 or 0, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		PlaceholderColor3 = Util.Theme.TextDim,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		MultiLine = false,
		Parent = wrapper,
	})
	Util.Themable(input, "TextColor3", "Text")
	Util.Themable(input, "PlaceholderColor3", "TextDim")

	if config.MaxLength then
		input:GetPropertyChangedSignal("Text"):Connect(function()
			if #input.Text > config.MaxLength then
				input.Text = string.sub(input.Text, 1, config.MaxLength)
			end
		end)
	end

	-- Clear button ----------------------------------------------------
	local clearIcon
	if config.ClearButton ~= false then
		clearIcon = Icons.Get("close", wrapper, {
			Size = 10,
			Color = Util.Theme.TextDim,
			Mask = Util.Theme.Surface,
		})
		clearIcon.AnchorPoint = Vector2.new(1, 0.5)
		clearIcon.Position = UDim2.new(1, 2, 0.5, 0)
		clearIcon.BackgroundTransparency = 1
		Util.New("Frame", {
			Name = "Hitbox",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Parent = clearIcon,
		})
		local function updateVisibility()
			clearIcon.Visible = input.Text ~= ""
		end
		updateVisibility()
		input:GetPropertyChangedSignal("Text"):Connect(updateVisibility)
		Util.OnClick(clearIcon:FindFirstChildOfClass("Frame") or clearIcon, function()
			input.Text = ""
			Util.SafeCall(config.Callback, "")
		end)
	end

	-- Focus ring ------------------------------------------------------
	local focused = false
	input.Focused:Connect(function()
		focused = true
		Util.Tween(stroke, { Color = Util.Theme.Accent, Thickness = 1.5, Transparency = 0 }, "Fast")
		Util.Tween(wrapper, { BackgroundColor3 = Util.Theme.SurfaceHover }, "Fast")
	end)
	input.FocusLost:Connect(function(enterPressed)
		focused = false
		Util.Tween(stroke, { Color = Util.Theme.Stroke, Thickness = 1 }, "Fast")
		Util.Tween(wrapper, { BackgroundColor3 = Util.Theme.Surface }, "Fast")

		if config.Validate then
			local ok, valid, message = pcall(config.Validate, input.Text)
			if ok and valid == false then
				local original = input.Text
				Util.Tween(wrapper, { BackgroundColor3 = Util.Theme.Danger }, "Fast")
				Util.Tween(stroke, { Color = Util.Theme.Danger }, "Fast")
				task.delay(0.8, function()
					if wrapper.Parent then
						Util.Tween(wrapper, { BackgroundColor3 = Util.Theme.Surface }, "Fast")
						Util.Tween(stroke, { Color = Util.Theme.Stroke }, "Fast")
					end
				end)
				if window and message then
					window:Notify({ Title = "Invalid input", Body = message, Type = "error" })
				end
				input.Text = config.RevertOnInvalid and original or input.Text
				return
			end
		end

		Util.SafeCall(config.Callback, input.Text)
		if enterPressed then
			Util.SafeCall(config.OnEnter, input.Text)
		end
	end)

	-- Numeric guard ---------------------------------------------------
	if config.Numeric then
		local allowed = config.AllowNegative and "^[-%d%.]*$" or "^[%d%.]*$"
		input:GetPropertyChangedSignal("Text"):Connect(function()
			if string.match(input.Text, allowed) == nil then
				input.Text = string.gsub(input.Text, "[^%d%.%-]", "")
			end
		end)
	end

	local object = { Instance = row.Frame, Kind = "TextBox", Input = input }

	function object.Get(self): string
		return input.Text
	end

	function object.Set(self, text: string, silent: boolean?)
		input.Text = text or ""
		if not silent then
			Util.SafeCall(config.Callback, input.Text)
		end
	end

	function object.Focus(self)
		input:CaptureFocus()
	end

	function object.SetEnabled(self, value: boolean)
		input.TextEditable = value
		Util.Tween(wrapper, { BackgroundTransparency = value and 0 or 0.5 }, "Fast")
		Util.Tween(input, { TextTransparency = value and 0 or 0.45 }, "Fast")
	end

	return object
end

return TextBox
