--[[
	Aurora UI  •  Section.luau
	------------------------------------------------------------------
	A titled card that groups controls. Every Add* method forwards to
	the matching component module and registers the row with the
	window's search index so Ctrl+F / the title-bar search can find it.
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)

local Button = require(script.Parent.Button)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local Dropdown = require(script.Parent.Dropdown)
local TextBox = require(script.Parent.TextBox)
local Keybind = require(script.Parent.Keybind)
local ColorPicker = require(script.Parent.ColorPicker)

local Section = {}

function Section.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local section = {}
	local collapsed = config.Collapsed == true
	local chevron

	-- Card -------------------------------------------------------------
	-- Five card treatments, chosen by the active style:
	--   glass    transparent tinted panel (Midnight, Frost, Solar)
	--   elevated solid panel + drop shadow (Daylight, Material You)
	--   outline  no fill, bright hairline (Neon Grid, Executive)
	--   flat     solid panel, no border (Terminal)
	--   brutal   paper fill, heavy border, hard offset shadow (Brutalist, Arcade)
	local cardKind = config.Card or Util.M("Card", "glass")
	local cardColor, cardTransparency = Util.Theme.Surface, 0
	local strokeColor, strokeThickness, strokeAlpha = Util.Theme.StrokeSoft, 1, 0

	if cardKind == "glass" then
		cardTransparency = math.clamp((Util.Theme.Glass or 0) + 0.06, 0, 0.9)
	elseif cardKind == "elevated" then
		cardColor = Util.Theme.Elevated
	elseif cardKind == "outline" then
		cardTransparency = 1
		strokeColor, strokeThickness, strokeAlpha = Util.Theme.StrokeBright, 1.2, 0.25
	elseif cardKind == "brutal" then
		cardColor = Util.Theme.PanelSolid
		strokeColor, strokeThickness, strokeAlpha = Util.Theme.Text, 2, 0
	end

	local card = Util.New("Frame", {
		Name = "Section_" .. (config.Name or "Group"),
		BackgroundColor3 = cardColor,
		BackgroundTransparency = cardTransparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(14, card)
	Util.Stroke(strokeColor, strokeThickness, strokeAlpha, card)
	Util.Padding({ X = 10, Y = 10 }, card)
	Util.List({ Padding = UDim.new(0, 4), Parent = card })
	Util.Themable(card, "BackgroundColor3", cardKind == "elevated" and "Elevated" or "Surface")

	if cardKind == "elevated" then
		-- clean hairline instead of a drop shadow: the card is auto-sized,
		-- and a sibling shadow would have nothing to measure at build time
		Util.Stroke(Util.Theme.Stroke, 1, 0.45, card)
	elseif cardKind == "brutal" then
		local backerStroke = Util.Stroke(Util.Theme.Text, 2, 0, card)
		backerStroke:SetAttribute("AuroraBrutal", true)
	end

	-- Header -----------------------------------------------------------
	-- Positioned by hand rather than with a UIListLayout: the optional
	-- description occupies a second line, which a horizontal list cannot
	-- express (and a full-size spacer would push the chevron off the card).
	if config.Name or config.Icon then
		local hasDescription = config.Description ~= nil
		local rowHeight = hasDescription and 18 or 26
		local iconSize = 14
		local textLeft = config.Icon and (iconSize + 8) or 0

		local header = Util.New("Frame", {
			Name = "Header",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, hasDescription and 38 or 26),
			Parent = card,
		})

		if config.Icon then
			local icon = Icons.Get(config.Icon, header, {
				Size = iconSize,
				Color = Util.Theme.Accent,
				Mask = Util.Theme.Surface,
			})
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 0, 0, hasDescription and 8 or 13)
		end

		local titleText = config.Name or ""
		if Util.M("HeaderCase", "normal") == "upper" then
			titleText = string.upper(titleText)
		end

		local title = Util.Text({
			Name = "Title",
			Text = titleText,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Util.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, hasDescription and 0 or 0.5),
			Position = UDim2.new(0, textLeft, 0, hasDescription and 0 or 13),
			Size = UDim2.fromOffset(0, rowHeight),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = header,
		})
		Util.Themable(title, "TextColor3", "Text")

		local titleWidth = Util.TextWidth(titleText, 13)

		if config.Badge then
			local badge = Util.New("Frame", {
				Name = "Badge",
				BackgroundColor3 = Util.Theme.AccentSoft,
				AnchorPoint = Vector2.new(0, hasDescription and 0 or 0.5),
				Position = UDim2.new(0, textLeft + titleWidth + 8, 0, hasDescription and 1 or 13),
				Size = UDim2.fromOffset(0, 17),
				AutomaticSize = Enum.AutomaticSize.X,
				BorderSizePixel = 0,
				Parent = header,
			})
			Util.Corner(5, badge)
			Util.Padding({ X = 6 }, badge)
			Util.Themable(badge, "BackgroundColor3", "AccentSoft")
			local badgeLabel = Util.Text({
				Text = tostring(config.Badge),
				Font = Enum.Font.GothamBold,
				TextSize = 9,
				TextColor3 = Util.Theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.fromOffset(0, 17),
				AutomaticSize = Enum.AutomaticSize.X,
				Parent = badge,
			})
			Util.Themable(badgeLabel, "TextColor3", "Accent")
		end

		if config.Collapsible ~= false then
			chevron = Icons.Get("chevronDown", header, {
				Size = 12,
				Color = Util.Theme.TextDim,
				Mask = Util.Theme.Surface,
			})
			chevron.Rotation = collapsed and -90 or 0
			chevron.AnchorPoint = Vector2.new(1, 0.5)
			chevron.Position = UDim2.new(1, 0, 0, hasDescription and 9 or 13)

			local hitbox = Util.New("Frame", {
				Name = "CollapseHitbox",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(22, 22),
				Parent = header,
			})
			hitbox.AnchorPoint = Vector2.new(1, 0.5)
			hitbox.Position = UDim2.new(1, 0, 0, hasDescription and 9 or 13)

			Util.OnClick(hitbox, function()
				section:SetCollapsed(not collapsed)
			end)
		end

		if hasDescription then
			local description = Util.Text({
				Name = "Description",
				Text = config.Description,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				TextColor3 = Util.Theme.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, textLeft, 0, 20),
				Size = UDim2.new(1, -(textLeft + 26), 0, 15),
				Parent = header,
			})
			Util.Themable(description, "TextColor3", "TextMuted")
		end
	end

	-- Body -------------------------------------------------------------
	local body = Util.New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = not collapsed,
		Parent = card,
	})
	Util.List({ Padding = UDim.new(0, 2), Parent = body })

	section.Instance = card
	section.Body = body
	section.Collapsed = collapsed

	--- Collapse / expand the card body.
	function section:SetCollapsed(value: boolean)
		collapsed = value == true
		section.Collapsed = collapsed
		body.Visible = not collapsed
		if chevron then
			Util.Tween(chevron, { Rotation = collapsed and -90 or 0 }, "Fast")
		end
	end

	function section:ToggleCollapsed()
		section:SetCollapsed(not collapsed)
	end
	section.Name = config.Name
	section.Window = window

	local function register(component, controlConfig)
		if window then
			window:_registerSearch({
				Name = controlConfig.Name or "Control",
				Section = config.Name,
				Kind = component.Kind or "Control",
				Frame = component.Instance,
				Object = component,
			})
		end
		return component
	end

	function section.AddToggle(self, controlConfig)
		return register(Toggle.New(window, body, controlConfig), controlConfig)
	end

	function section.AddSlider(self, controlConfig)
		return register(Slider.New(window, body, controlConfig), controlConfig)
	end

	function section.AddDropdown(self, controlConfig)
		return register(Dropdown.New(window, body, controlConfig), controlConfig)
	end

	function section.AddTextBox(self, controlConfig)
		return register(TextBox.New(window, body, controlConfig), controlConfig)
	end

	function section.AddKeybind(self, controlConfig)
		return register(Keybind.New(window, body, controlConfig), controlConfig)
	end

	function section.AddColorPicker(self, controlConfig)
		return register(ColorPicker.New(window, body, controlConfig), controlConfig)
	end

	function section.AddButton(self, controlConfig)
		controlConfig.FullWidth = controlConfig.FullWidth == nil or controlConfig.FullWidth
		local component = Button.New(window, body, controlConfig)
		if controlConfig.Name then
			window:_registerSearch({
				Name = controlConfig.Name,
				Section = config.Name,
				Kind = "Button",
				Frame = component.Instance,
				Object = component,
			})
		end
		return component
	end

	--- Plain paragraph inside the card.
	function section.AddLabel(self, text: string, opts: { [string]: any }?)
		opts = opts or {}
		local label = Util.Text({
			Name = "Paragraph",
			Text = text,
			Font = opts.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
			TextSize = opts.TextSize or 12,
			TextColor3 = Util.Theme[opts.Token or "TextMuted"],
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.fromOffset(8, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = body,
		})
		Util.Themable(label, "TextColor3", opts.Token or "TextMuted")
		return label
	end

	--- Hairline divider.
	function section.AddDivider(self, opts: { [string]: any }?)
		opts = opts or {}
		local divider = Util.New("Frame", {
			Name = "Divider",
			BackgroundColor3 = Util.Theme.StrokeSoft,
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			Parent = body,
		})
		Util.Themable(divider, "BackgroundColor3", "StrokeSoft")
		if opts.Spacing then
			Util.New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, opts.Spacing),
				Parent = body,
			})
		end
		return divider
	end

	--- Escape hatch: hand the raw body frame to your own code.
	function section.AddRow(self, configFactory)
		return configFactory(body)
	end

	function section.SetVisible(self, value: boolean)
		card.Visible = value
	end

	return section
end

return Section
