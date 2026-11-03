--[[
	Aurora UI  •  Row.luau
	------------------------------------------------------------------
	The settings-row shell every control sits inside: title, optional
	description, hover highlight and a right-aligned control slot.
--]]

local Util = require(script.Parent.Parent.Util)

local Row = {}

export type RowConfig = {
	Name: string?,
	Description: string?,
	Height: number?,
	Padding: number?,
	OnClick: (() -> ())?,
	Clickable: boolean?,
}

--- Creates a row and returns a controller table.
-- fields: Frame, Right, Label, Description, Height, SetLabel, SetDescription
function Row.Create(parent: Instance, config: RowConfig?)
	config = config or {}

	local hasDescription = config.Description ~= nil and config.Description ~= ""
	-- density lets a style breathe (arcade) or pack rows tighter (executive)
	local density = Util.M("Density", 1)
	local height = config.Height or math.floor((hasDescription and 52 or 44) * density + 0.5)
	local sidePadding = config.Padding or 12

	local frame = Util.New("Frame", {
		Name = "Row_" .. (config.Name or "Control"),
		BackgroundColor3 = Util.Theme.SurfaceHover,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(10, frame)

	-- Hover highlight -------------------------------------------------
	local hovered = false
	Util.Themable(frame, "BackgroundColor3", function(palette)
		return hovered and palette.SurfaceHover or palette.Surface
	end)

	local function setHover(value: boolean)
		hovered = value
		Util.Tween(frame, { BackgroundTransparency = value and 0.35 or 1 }, "Fast")
	end

	frame.MouseEnter:Connect(function()
		setHover(true)
	end)
	frame.MouseLeave:Connect(function()
		setHover(false)
	end)

	-- Text ------------------------------------------------------------
	local labelWidth = UDim.new(1, -(sidePadding * 2) - 60)

	local label = Util.Text({
		Name = "Label",
		Text = config.Name or "",
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Util.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, hasDescription and 0 or 0.5),
		Position = hasDescription and UDim2.new(0, sidePadding, 0, 9) or UDim2.new(0, sidePadding, 0.5, 0),
		Size = UDim2.new(labelWidth.Scale, labelWidth.Offset, 0, 17),
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
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, sidePadding, 0, 27),
			Size = UDim2.new(labelWidth.Scale, labelWidth.Offset, 0, 16),
			Parent = frame,
		})
		Util.Themable(description, "TextColor3", "TextMuted")
	end

	-- Right-side control slot -----------------------------------------
	local right = Util.New("Frame", {
		Name = "Control",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -sidePadding, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = frame,
	})

	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		Parent = right,
	})

	local row = {
		Frame = frame,
		Right = right,
		Label = label,
		Description = description,
		Height = height,
		Hovered = false,
	}

	function row.SetHover(self, value: boolean)
		setHover(value)
	end

	function row.SetLabel(self, text: string)
		label.Text = text
	end

	function row.SetDescription(self, text: string?)
		if description then
			description.Text = text or ""
		end
	end

	function row.SetTooltip(self, text: string)
		frame:SetAttribute("Tooltip", text)
	end

	if config.Clickable and config.OnClick then
		Util.OnClick(frame, function()
			Util.SafeCall(config.OnClick)
		end)
	end

	return row
end

return Row
