--[[
	Aurora UI  •  Button.luau
	------------------------------------------------------------------
	Two flavours, one implementation:
	  • compact  — sits on the right of a settings row
	  • block    — full-width call-to-action with gradient fill

	Styles: primary | secondary | ghost | danger
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)
local Row = require(script.Parent.Row)

local Button = {}

local STYLES = {
	primary = { Height = 34, Radius = 9 },
	secondary = { Height = 30, Radius = 8 },
	ghost = { Height = 30, Radius = 8 },
	danger = { Height = 30, Radius = 8 },
	block = { Height = 38, Radius = 10 },
}

--- Internal: build the visual shell of a button.
local function buildShell(parent: Instance, config): (Frame, TextLabel, Frame?)
	local style = config.Style or "secondary"
	local metrics = STYLES[style] or STYLES.secondary
	local gradient = style == "primary" or style == "block"

	-- Template style decides how a primary button looks: gradient, flat
	-- accent, outlined accent, or a bordered block.
	local variant = Util.M("Button", "gradient")
	local primaryText = (gradient and variant == "outline") and Util.Theme.Accent or Util.Theme.AccentText

	local button = Util.New("Frame", {
		Name = "Button_" .. (config.Name or "Action"),
		BackgroundColor3 = Util.Theme.Surface,
		BackgroundTransparency = 0,
		AnchorPoint = config.AnchorPoint,
		Position = config.Position,
		Size = config.FullWidth and UDim2.new(1, 0, 0, metrics.Height)
			or UDim2.fromOffset(config.Width or 0, metrics.Height),
		AutomaticSize = (config.FullWidth and Enum.AutomaticSize.None) or Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = parent,
	})
	Util.Corner(config.Radius or metrics.Radius, button)
	-- Content wrapper: keeps the sheen and ripple frames out of the list layout,
	-- otherwise a full-size decorative child would push the label off the button.
	local content = Util.New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 1,
		Parent = button,
	})
	Util.Padding({ X = 12 }, content)
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 7),
		Parent = content,
	})

	-- Base colors -----------------------------------------------------
	if gradient then
		if variant == "gradient" then
			Util.Gradient(
				ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2),
				0,
				button
			)
			Util.Themable(button, "BackgroundColor3", "Accent")
		elseif variant == "solid" then
			Util.Themable(button, "BackgroundColor3", "Accent")
		elseif variant == "outline" then
			button.BackgroundTransparency = 1
			Util.Themable(button, "BackgroundColor3", "Accent")
			Util.Stroke(Util.Theme.Accent, 1.6, 0, button)
		elseif variant == "brutal" then
			Util.Themable(button, "BackgroundColor3", "Accent")
			Util.Stroke(Util.Theme.Text, 2, 0, button)
		end
	elseif style == "danger" then
		Util.Themable(button, "BackgroundColor3", "Surface")
		Util.Stroke(Util.Theme.Danger, 1, 0.55, button)
		button.BackgroundTransparency = 0.86
	elseif style == "ghost" then
		button.BackgroundTransparency = 1
		Util.Themable(button, "BackgroundColor3", "SurfaceHover")
	else
		Util.Themable(button, "BackgroundColor3", "Surface")
		Util.Stroke(Util.Theme.Stroke, 1, 0, button)
	end

	-- Hover sheen (style agnostic) ------------------------------------
	local sheen = Util.New("Frame", {
		Name = "Sheen",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 2,
		Parent = button,
	})
	Util.Corner(config.Radius or metrics.Radius, sheen)

	button.MouseEnter:Connect(function()
		Util.Tween(sheen, { BackgroundTransparency = gradient and 0.88 or 0.94 }, "Fast")
	end)
	button.MouseLeave:Connect(function()
		Util.Tween(sheen, { BackgroundTransparency = 1 }, "Fast")
	end)

	-- Icon + label ----------------------------------------------------
	local icon
	if config.Icon then
		local iconColor
		if gradient then
			iconColor = primaryText
		elseif style == "danger" then
			iconColor = Util.Theme.Danger
		elseif style == "ghost" then
			iconColor = Util.Theme.TextMuted
		else
			iconColor = Util.Theme.Text
		end
		icon = Icons.Get(config.Icon, content, {
			Size = config.IconSize or 14,
			Color = iconColor,
			Mask = gradient and (variant == "outline" and Util.Theme.Surface or Util.Theme.Accent) or Util.Theme.Surface,
		})
		icon.ZIndex = button.ZIndex + 1
	end

	local label = Util.Text({
		Name = "Label",
		Text = config.Name or "Button",
		Font = Enum.Font.GothamMedium,
		TextSize = config.TextSize or 12,
		TextColor3 = gradient and primaryText
			or (style == "danger" and Util.Theme.Danger)
			or (style == "ghost" and Util.Theme.TextMuted)
			or Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(0, metrics.Height),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = button.ZIndex + 1,
		Parent = content,
	})
	if not gradient then
		Util.Themable(label, "TextColor3", style == "danger" and "Danger" or (style == "ghost" and "TextMuted" or "Text"))
	end

	return button, label, icon
end

--- Public constructor.
function Button.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local container = parent
	local row
	if not config.FullWidth then
		row = Row.Create(parent, {
			Name = config.Name,
			Description = config.Description,
			Height = config.RowHeight,
		})
		container = row.Right
	end

	local style
	if config.FullWidth then
		style = config.Style or "block"
	else
		style = config.Style or "secondary"
	end
	local button, label, icon = buildShell(container, {
		Name = config.Name,
		Icon = config.Icon,
		Style = style,
		FullWidth = config.FullWidth,
		Width = config.Width,
		TextSize = config.TextSize,
		IconSize = config.IconSize,
	})

	local enabled = config.Enabled ~= false
	local armed = false
	local object = { Instance = button, Row = row, Label = label, Icon = icon }

	Util.Scale(button)
	local scale = button:FindFirstChildOfClass("UIScale")
	Util.Ripple(button, gradient and Color3.new(1, 1, 1) or Util.Theme.Text, 2.6)

	Util.OnClick(button, function()
		if not enabled or button:GetAttribute("Loading") then
			return
		end

		if config.Confirm and not armed then
			armed = true
			label.Text = config.ConfirmText or "Are you sure?"
			task.delay(2.4, function()
				if button.Parent and armed then
					armed = false
					label.Text = config.Name or "Button"
				end
			end)
			return
		end

		armed = false
		if config.Confirm then
			label.Text = config.Name or "Button"
		end

		Util.SafeCall(config.Callback)
		if window and config.Notify then
			window:Notify(config.Notify)
		end
	end)

	if config.Tooltip then
		button:SetAttribute("Tooltip", config.Tooltip)
	end

	function object.SetText(self, text: string)
		label.Text = text
	end

	function object.GetText(self): string
		return label.Text
	end

	function object.SetEnabled(self, value: boolean)
		enabled = value
		Util.Tween(button, { BackgroundTransparency = value and (gradient and 0 or (style == "ghost" and 1 or 0.86)) or 0.6 }, "Fast")
		Util.Tween(label, { TextTransparency = value and 0 or 0.5 }, "Fast")
		if icon then
			Util.Fade(icon, value and 0 or 0.45, "Fast")
		end
	end

	function object.SetLoading(self, value: boolean)
		button:SetAttribute("Loading", value)
		label.Text = value and (config.LoadingText or "Working…") or (config.Name or "Button")
	end

	function object.Destroy(self)
		if row then
			row.Frame:Destroy()
		else
			button:Destroy()
		end
	end

	return object
end

return Button
