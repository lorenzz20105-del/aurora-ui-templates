--[[
	Aurora UI  •  Tooltip.luau
	------------------------------------------------------------------
	One shared tooltip layer. Anything can opt in by tagging itself:

		someRow:SetAttribute("Tooltip", "Explained here")

	The layer samples the GUI objects under the cursor a few times per
	second (cheap) and walks up the hierarchy looking for the tag.
--]]

local Util = require(script.Parent.Parent.Util)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Tooltip = {}

local player = Players.LocalPlayer

function Tooltip.Init(window)
	if Tooltip._initialized then
		return
	end

	-- Phones have no cursor, so the whole layer is pointless there.
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return
	end

	Tooltip._initialized = true

	local gui = Util.New("ScreenGui", {
		Name = "AuroraTooltip",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 300,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local bubble = Util.New("Frame", {
		Name = "Bubble",
		BackgroundColor3 = Util.Theme.Elevated,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	Util.Corner(7, bubble)
	local stroke = Util.Stroke(Util.Theme.StrokeBright, 1, 1, bubble)
	Util.Padding({ X = 9, Y = 5 }, bubble)
	Util.Themable(bubble, "BackgroundColor3", "Elevated")
	Util.Themable(stroke, "Color", "StrokeBright")

	local label = Util.Text({
		Name = "Text",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Util.Theme.Text,
		TextTransparency = 1,
		Size = UDim2.fromOffset(0, 14),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = bubble,
	})
	Util.Themable(label, "TextColor3", "Text")

	local currentTarget, currentText, shown = nil, nil, false
	local accumulator = 0

	local function hide()
		if not shown then
			return
		end
		shown = false
		Util.Tween(bubble, { BackgroundTransparency = 1 }, "Fast")
		Util.Tween(stroke, { Transparency = 1 }, "Fast")
		Util.Tween(label, { TextTransparency = 1 }, "Fast")
		task.delay(0.16, function()
			if not shown then
				bubble.Visible = false
			end
		end)
	end

	local function show(text: string)
		label.Text = text
		bubble.Visible = true
		shown = true
		Util.Tween(bubble, { BackgroundTransparency = 0.02 }, "Fast")
		Util.Tween(stroke, { Transparency = 0.45 }, "Fast")
		Util.Tween(label, { TextTransparency = 0 }, "Fast")
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local canHitTest = playerGui ~= nil and type(playerGui.GetGuiObjectsAtPosition) == "function"

	local function findTarget(x: number, y: number)
		if not canHitTest or not playerGui then
			return nil, nil
		end
		local ok, objects = pcall(function()
			return playerGui:GetGuiObjectsAtPosition(x, y)
		end)
		if not ok or type(objects) ~= "table" then
			canHitTest = false
			return nil, nil
		end
		for _, object in ipairs(objects) do
			local cursor = object
			while cursor and cursor ~= playerGui do
				local text = cursor:GetAttribute("Tooltip")
				if text then
					return cursor, text
				end
				cursor = cursor.Parent
			end
		end
		return nil, nil
	end

	RunService.RenderStepped:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.06 then
			return
		end
		accumulator = 0

		if not gui.Parent then
			return
		end

		local position = UserInputService:GetMouseLocation()
		local target, text = findTarget(position.X, position.Y)

		if target and text then
			if target ~= currentTarget or text ~= currentText then
				currentTarget, currentText = target, text
				show(text)
			end
			local viewport = workspace.CurrentCamera.ViewportSize
			local width = bubble.AbsoluteSize.X
			local x = math.clamp(position.X + 14, 8, viewport.X - width - 8)
			local y = position.Y + 22
			if y + bubble.AbsoluteSize.Y > viewport.Y - 8 then
				y = position.Y - bubble.AbsoluteSize.Y - 10
			end
			bubble.Position = UDim2.fromOffset(x, y)
		elseif shown then
			currentTarget, currentText = nil, nil
			hide()
		end
	end)

	Tooltip.Bubble = bubble
end

return Tooltip
