--[[
	Aurora UI  •  Tab.luau
	------------------------------------------------------------------
	One sidebar rail button + one scrolling page. Tabs animate their
	icon, carry an optional notification badge, and expose the layout
	helpers the demo uses (sections, grids, stat cards).
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)
local Section = require(script.Parent.Section)
local StatCard = require(script.Parent.StatCard)

local Tab = {}

function Tab.New(window, config: { [string]: any }, order: number?)
	config = config or {}

	local tab = {
		Name = config.Name or "Tab",
		Index = order or 1,
		Window = window,
		Active = false,
	}

	-- Rail geometry depends on the active style: an icon rail, a horizontal
	-- tab bar with labels, or a wide labelled sidebar.
	local railKind = Util.M("Rail", "rail")
	local tabShape = Util.M("TabShape", "rounded")
	local labelled = railKind == "tabs" or railKind == "sidebar"

	local size
	if railKind == "sidebar" then
		size = UDim2.new(1, 0, 0, 36)
	elseif railKind == "tabs" then
		size = UDim2.fromOffset(0, 38)
	else
		size = UDim2.fromOffset(52, 52)
	end

	local radius
	if tabShape == "square" then
		radius = 0
	elseif tabShape == "pill" then
		radius = 999
	elseif railKind == "sidebar" then
		radius = 10
	else
		radius = 15
	end

	-- Rail button ------------------------------------------------------
	local button = Util.New("Frame", {
		Name = "Tab_" .. tab.Name,
		BackgroundColor3 = Util.Theme.SurfaceHover,
		BackgroundTransparency = 1,
		Size = size,
		AutomaticSize = labelled and railKind == "tabs" and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
		BorderSizePixel = 0,
		LayoutOrder = order or 1,
		Parent = window._rail,
	})
	Util.Corner(radius, button)
	button.ClipsDescendants = labelled or false

	local fill = Util.Gradient(
		ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2),
		45,
		button
	)
	fill.Enabled = false
	Util.Themable(fill, "Color", function(palette)
		return ColorSequence.new(palette.Accent, palette.Accent2)
	end)

	local stroke = Util.Stroke(Util.Theme.Accent, 1, 1, button)
	Util.Themable(stroke, "Color", "Accent")

	-- Labelled variants keep the icon and the title in a padded content frame,
	-- so list layout never sees the full-size background layers.
	local content, label
	if labelled then
		content = Util.New("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = button,
		})
		Util.Padding({ Left = 14, Right = 14 }, content)
		Util.List({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = railKind == "sidebar" and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 9),
			Parent = content,
		})

	end

	local icon = Icons.Get(config.Icon or "dot", content or button, {
		Size = labelled and 15 or 20,
		Color = Util.Theme.TextMuted,
		Mask = Util.Theme.Surface,
	})
	if not labelled then
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
	end

	if labelled then
		label = Util.Text({
			Name = "Label",
			Text = Util.M("HeaderCase", "normal") == "upper" and string.upper(config.Name or "") or (config.Name or ""),
			Font = Util.M("Mono", false) and Enum.Font.Code or Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Util.Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = content,
		})

		if railKind == "tabs" then
			-- a horizontal tab bar needs a real width: AutomaticSize cannot
			-- resolve through a full-size content frame, so measure the label
			local textWidth = Util.TextWidth(label.Text, 12)
			if not textWidth or textWidth <= 0 then
				-- TextService is unavailable (or the measurement failed): fall back
				-- to an average glyph width so labels are never clipped
				textWidth = #label.Text * 7.4
			end
			button.Size = UDim2.fromOffset(math.max(88, math.floor(textWidth + 64)), 38)
			button.AutomaticSize = Enum.AutomaticSize.None
		end
	end

	button:SetAttribute("Tooltip", config.Name or "Tab")

	-- Badge ------------------------------------------------------------
	local badge
	if config.Badge then
		badge = Util.New("Frame", {
			Name = "Badge",
			BackgroundColor3 = Util.Theme.Danger,
			Size = UDim2.fromOffset(0, 15),
			AutomaticSize = Enum.AutomaticSize.X,
			BorderSizePixel = 0,
			AnchorPoint = labelled and Vector2.new(1, 0.5) or Vector2.new(1, 0),
			Position = labelled and UDim2.new(1, -8, 0.5, 0) or UDim2.new(1, 2, 0, -2),
			ZIndex = button.ZIndex + 3,
			Parent = button,
		})
		Util.Corner(999, badge)
		Util.Padding({ X = 4 }, badge)
		Util.Themable(badge, "BackgroundColor3", "Danger")

		local badgeLabel = Util.Text({
			Name = "Count",
			Text = tostring(config.Badge),
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromOffset(0, 15),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = badge,
		})
		tab.BadgeLabel = badgeLabel
	end

	-- Page -------------------------------------------------------------
	local page = Util.New("ScrollingFrame", {
		Name = "Page_" .. tab.Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Visible = false,
		ScrollBarThickness = Util.IsTouch() and 6 or 3,
		ScrollBarImageColor3 = Util.Theme.StrokeBright,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = window._pages,
	})
	Util.Padding({ Left = 2, Right = 8, Top = 2, Bottom = 12 }, page)
	Util.List({ Padding = UDim.new(0, 10), Parent = page })
	Util.Themable(page, "ScrollBarImageColor3", "StrokeBright")

	tab.Instance = button
	tab.Page = page
	tab.Icon = icon
	tab.Label = label
	tab.RailKind = railKind

	-- Hover / active visuals -------------------------------------------
	local hovered = false

	local function paint(animated: boolean)
		local palette = Util.Theme
		local active = tab.Active
		local background = active and palette.Accent or palette.SurfaceHover
		local transparency = active and 0 or (hovered and 0.35 or 1)
		local iconColor = active and palette.AccentText or (hovered and palette.Text or palette.TextMuted)

		fill.Enabled = active

		if animated then
			Util.Tween(button, { BackgroundTransparency = transparency }, "Fast")
			Util.Tween(stroke, { Transparency = active and 1 or 1 }, "Fast")
		else
			button.BackgroundTransparency = transparency
		end

		button.BackgroundColor3 = background
		Icons.Tint(icon, iconColor)
		Icons.Mask(icon, active and palette.Accent or palette.SurfaceHover)
		if label then
			label.TextColor3 = iconColor
		end
	end

	button.MouseEnter:Connect(function()
		hovered = true
		paint(true)
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		paint(true)
	end)
	Util.OnClick(button, function()
		window:SelectTab(tab)
	end)

	paint(false)
	tab._paint = paint

	-- Layout helpers ---------------------------------------------------
	function tab.CreateSection(self, sectionConfig)
		return Section.New(window, page, sectionConfig)
	end

	--- Evenly spaced grid used by dashboards.
	function tab.AddGrid(self, gridConfig)
		gridConfig = gridConfig or {}
		local columns = gridConfig.Columns or 3
		local gap = gridConfig.Gap or 10
		local cellHeight = gridConfig.CellHeight or 96

		local grid = Util.New("Frame", {
			Name = "Grid",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = page,
		})

		Util.New("UIGridLayout", {
			CellSize = UDim2.new(1 / columns, -(gap * (columns - 1) / columns), 0, cellHeight),
			CellPadding = UDim2.fromOffset(gap, gap),
			FillDirectionMaxCells = columns,
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			StartCorner = Enum.StartCorner.TopLeft,
			Parent = grid,
		})

		return grid
	end

	--- Convenience: grid of stat cards in one call.
	function tab.AddStats(self, cards: { { [string]: any } }, gridConfig: { [string]: any }?)
		local grid = tab:AddGrid(gridConfig or { Columns = #cards, CellHeight = 92 })
		local built = {}
		for index, cardConfig in ipairs(cards) do
			local card = StatCard.New(window, grid, cardConfig)
			card.Instance.LayoutOrder = index
			table.insert(built, card)
		end
		return built, grid
	end

	function tab.AddSpacer(self, height: number)
		return Util.New("Frame", {
			Name = "Spacer",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, height),
			Parent = page,
		})
	end

	-- Public API -------------------------------------------------------
	function tab.SetActive(self, value: boolean)
		tab.Active = value
		page.Visible = value
		paint(true)
		if value then
			page.CanvasPosition = Vector2.new(0, 0)
		end
	end

	function tab.Select(self)
		window:SelectTab(tab)
	end

	function tab.SetBadge(self, value: number?)
		if not badge then
			return
		end
		if value == nil then
			badge.Visible = false
			return
		end
		badge.Visible = true
		tab.BadgeLabel.Text = tostring(value)
	end

	function tab.ScrollTo(self, instance: GuiObject)
		local pageTop = page.AbsolutePosition.Y
		local offset = instance.AbsolutePosition.Y - pageTop + page.CanvasPosition.Y
		Util.Tween(page, { CanvasPosition = Vector2.new(0, math.max(0, offset - 24)) }, "Smooth")
	end

	return tab
end

return Tab
