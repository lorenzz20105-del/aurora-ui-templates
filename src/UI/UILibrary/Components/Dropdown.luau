--[[
	Aurora UI  •  Dropdown.luau
	------------------------------------------------------------------
	Searchable, animated select menu. Supports single and multi select,
	opens upward when there isn't room below, and renders on the window
	overlay so it is never clipped by the scrolling page.
--]]

local Util = require(script.Parent.Parent.Util)
local Icons = require(script.Parent.Parent.Icons)
local Row = require(script.Parent.Row)
local UserInputService = game:GetService("UserInputService")

local Dropdown = {}

function Dropdown.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local options = {}
	for index, option in ipairs(config.Options or {}) do
		if type(option) == "table" then
			table.insert(options, { Value = option.Value or option[1], Label = option.Label or option[1] })
		else
			table.insert(options, { Value = option, Label = tostring(option) })
		end
	end

	local multi = config.Multi == true
	local selected = {}

	local function findOption(value)
		for _, option in ipairs(options) do
			if option.Value == value then
				return option
			end
		end
		return nil
	end

	if multi then
		for _, value in ipairs(config.Default or {}) do
			table.insert(selected, value)
		end
	else
		selected[1] = config.Default ~= nil and config.Default or (options[1] and options[1].Value)
	end

	local row = Row.Create(parent, {
		Name = config.Name,
		Description = config.Description,
		Height = config.Height,
	})

	-- Trigger ---------------------------------------------------------
	local trigger = Util.New("Frame", {
		Name = "Trigger",
		BackgroundColor3 = Util.Theme.Surface,
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		Parent = row.Right,
	})
	Util.Corner(8, trigger)
	Util.Stroke(Util.Theme.Stroke, 1, 0, trigger)
	Util.Padding({ X = 10 }, trigger)
	Util.List({
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = trigger,
	})

	local triggerLabel = Util.Text({
		Name = "Value",
		Text = "Select",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Util.Theme.Text,
		Size = UDim2.fromOffset(112, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = trigger,
	})
	Util.Themable(triggerLabel, "TextColor3", "Text")

	local chevron = Icons.Get("chevronDown", trigger, {
		Size = 12,
		Color = Util.Theme.TextMuted,
		Mask = Util.Theme.Surface,
	})
	Util.Themable(chevron, "BackgroundColor3", "Surface")

	local triggerStroke = trigger:FindFirstChildOfClass("UIStroke")
	local hovered = false

	trigger.MouseEnter:Connect(function()
		hovered = true
		Util.Tween(trigger, { BackgroundColor3 = Util.Theme.SurfaceHover }, "Fast")
		if triggerStroke then
			Util.Tween(triggerStroke, { Color = Util.Theme.StrokeBright }, "Fast")
		end
	end)
	trigger.MouseLeave:Connect(function()
		hovered = false
		Util.Tween(trigger, { BackgroundColor3 = Util.Theme.Surface }, "Fast")
		if triggerStroke then
			Util.Tween(triggerStroke, { Color = Util.Theme.Stroke }, "Fast")
		end
	end)

	-- State -----------------------------------------------------------
	local object = { Instance = row.Frame, Kind = "Dropdown" }
	local popup, clickcatcher
	local isOpen = false

	local function summary(): string
		if multi then
			if #selected == 0 then
				return config.Placeholder or "None"
			elseif #selected == 1 then
				local option = findOption(selected[1])
				return option and option.Label or tostring(selected[1])
			end
			return string.format("%d selected", #selected)
		end
		local option = findOption(selected[1])
		return option and option.Label or (config.Placeholder or "Select")
	end

	local function refreshTrigger()
		triggerLabel.Text = summary()
	end

	local function isSelected(value): boolean
		for _, entry in ipairs(selected) do
			if entry == value then
				return true
			end
		end
		return false
	end

	local function close()
		if not isOpen then
			return
		end
		isOpen = false
		row:SetHover(false)

		local dying = popup
		popup = nil
		if clickcatcher then
			clickcatcher:Destroy()
			clickcatcher = nil
		end
		if dying then
			local scaleInstance = dying:FindFirstChildOfClass("UIScale")
			if scaleInstance then
				Util.Tween(scaleInstance, { Scale = 0.96 }, "Fast")
			end
			Util.Tween(dying, { BackgroundTransparency = 1 }, "Fast")
			for _, descendant in ipairs(dying:GetDescendants()) do
				if descendant:IsA("TextLabel") then
					Util.Tween(descendant, { TextTransparency = 1 }, "Fast")
				elseif descendant:IsA("Frame") then
					Util.Tween(descendant, { BackgroundTransparency = 1 }, "Fast")
				elseif descendant:IsA("UIStroke") then
					Util.Tween(descendant, { Transparency = 1 }, "Fast")
				end
			end
			task.delay(0.16, function()
				if dying then
					dying:Destroy()
				end
			end)
		end
	end

	local function select(value)
		if multi then
			if isSelected(value) then
				for index, entry in ipairs(selected) do
					if entry == value then
						table.remove(selected, index)
						break
					end
				end
			else
				if config.Max and #selected >= config.Max then
					return
				end
				table.insert(selected, value)
			end
			refreshTrigger()
			Util.SafeCall(config.Callback, table.clone(selected))
		else
			selected = { value }
			refreshTrigger()
			Util.SafeCall(config.Callback, value)
			close()
		end
	end

	-- Popup -----------------------------------------------------------
	local function buildPopup()
		local overlay = window:_overlay()
		local width = math.max(trigger.AbsoluteSize.X, config.MenuWidth or 180)

		clickcatcher = Util.New("Frame", {
			Name = "DropdownCatcher",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 900,
			Parent = overlay,
		})
		Util.OnClick(clickcatcher, close)

		popup = Util.New("Frame", {
			Name = "DropdownMenu",
			BackgroundColor3 = Util.Theme.Elevated,
			Size = UDim2.fromOffset(width, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 901,
			Parent = overlay,
		})
		Util.Corner(10, popup)
		Util.Stroke(Util.Theme.StrokeBright, 1, 0.4, popup)
		Util.Padding({ Y = 6, X = 6 }, popup)
		Util.Themable(popup, "BackgroundColor3", "Elevated")

		local scaleInstance = Util.Scale(popup)
		scaleInstance.Scale = 0.96
		Util.Tween(scaleInstance, { Scale = 1 }, "Fast")

		local content = Util.New("Frame", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = popup,
		})
		Util.List({ Padding = UDim.new(0, 2), Parent = content })

		-- Optional search ---------------------------------------------
		local query = ""
		local optionsHolder = content

		if #options > 6 then
			local searchBox = Util.New("Frame", {
				Name = "Search",
				BackgroundColor3 = Util.Theme.Surface,
				Size = UDim2.new(1, 0, 0, 30),
				BorderSizePixel = 0,
				LayoutOrder = -1,
				Parent = content,
			})
			Util.Corner(7, searchBox)
			Util.Padding({ X = 8 }, searchBox)
			Util.Themable(searchBox, "BackgroundColor3", "Surface")

			local searchIcon = Icons.Get("search", searchBox, {
				Size = 12,
				Color = Util.Theme.TextDim,
				Mask = Util.Theme.Surface,
			})
			searchIcon.Position = UDim2.fromOffset(0, 9)

			local input = Util.New("TextBox", {
				Name = "Input",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(20, 0),
				Size = UDim2.new(1, -20, 1, 0),
				Font = Enum.Font.Gotham,
				TextSize = 12,
				PlaceholderText = "Search…",
				PlaceholderColor3 = Util.Theme.TextDim,
				TextColor3 = Util.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Text = "",
				Parent = searchBox,
			})
			Util.Themable(input, "TextColor3", "Text")
			Util.Themable(input, "PlaceholderColor3", "TextDim")

			optionsHolder = Util.New("Frame", {
				Name = "Options",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = content,
			})
			Util.List({ Padding = UDim.new(0, 2), Parent = optionsHolder })

			input:GetPropertyChangedSignal("Text"):Connect(function()
				query = string.lower(input.Text)
				for _, item in ipairs(optionsHolder:GetChildren()) do
					if item:IsA("Frame") then
						local haystack = string.lower(item:GetAttribute("Label") or "")
						item.Visible = query == "" or string.find(haystack, query, 1, true) ~= nil
					end
				end
			end)
		end

		local list = optionsHolder
		for index, option in ipairs(options) do
			local item = Util.New("Frame", {
				Name = "Option_" .. tostring(option.Value),
				BackgroundColor3 = Util.Theme.Surface,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				BorderSizePixel = 0,
				LayoutOrder = index,
				Parent = list,
			})
			Util.Corner(7, item)
			item:SetAttribute("Label", option.Label)

			local text = Util.Text({
				Name = "Label",
				Text = option.Label,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Util.Theme.Text,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Parent = item,
			})
			Util.Themable(text, "TextColor3", "Text")

			if isSelected(option.Value) then
				local check = Icons.Get("check", item, {
					Size = 12,
					Color = Util.Theme.Accent,
					Mask = Util.Theme.Surface,
				})
				check.AnchorPoint = Vector2.new(1, 0.5)
				check.Position = UDim2.new(1, -8, 0.5, 0)
			end

			item.MouseEnter:Connect(function()
				if item.Visible then
					Util.Tween(item, { BackgroundTransparency = 0, BackgroundColor3 = Util.Theme.SurfaceHover }, "Fast")
				end
			end)
			item.MouseLeave:Connect(function()
				Util.Tween(item, { BackgroundTransparency = 1 }, "Fast")
			end)
			Util.OnClick(item, function()
				select(option.Value)
			end)
		end

		-- Position: below the trigger, or above when space is tight -----
		local overlayY = overlay.AbsolutePosition.Y
		local overlayHeight = overlay.AbsoluteSize.Y
		local triggerTop = trigger.AbsolutePosition.Y - overlayY
		local triggerBottom = triggerTop + trigger.AbsoluteSize.Y
		local estimated = math.min(#options * 32 + (#options > 6 and 36 or 0) + 12, 260)
		local opensUp = triggerBottom + estimated > overlayHeight - 8

		local x = math.clamp(
			trigger.AbsolutePosition.X - overlay.AbsolutePosition.X + trigger.AbsoluteSize.X - width,
			8,
			math.max(8, overlay.AbsoluteSize.X - width - 8)
		)

		popup.Position = UDim2.fromOffset(
			x,
			opensUp and (triggerTop - estimated - 6) or (triggerBottom + 6)
		)
		if opensUp then
			popup.AnchorPoint = Vector2.new(0, 0)
		end
	end

	local function open()
		if isOpen then
			return
		end
		isOpen = true
		row:SetHover(true)
		buildPopup()
	end

	Util.OnClick(trigger, function()
		if isOpen then
			close()
		else
			open()
		end
	end)
	trigger.MouseEnter:Connect(function()
		Util.Tween(chevron, { Rotation = 180 }, "Fast")
	end)
	trigger.MouseLeave:Connect(function()
		if not isOpen then
			Util.Tween(chevron, { Rotation = 0 }, "Fast")
		end
	end)

	refreshTrigger()

	object.Value = multi and selected or selected[1]

	function object.Get(self)
		if multi then
			return table.clone(selected)
		end
		return selected[1]
	end

	function object.Set(self, value, silent: boolean?)
		if multi and type(value) == "table" then
			selected = table.clone(value)
		else
			selected = { value }
		end
		refreshTrigger()
		if not silent then
			Util.SafeCall(config.Callback, object:Get())
		end
	end

	function object.SetOptions(self, nextOptions)
		options = nextOptions
		refreshTrigger()
	end

	function object.Destroy(self)
		close()
		row.Frame:Destroy()
	end

	return object
end

return Dropdown
