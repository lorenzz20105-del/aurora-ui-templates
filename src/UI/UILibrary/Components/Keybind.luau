--[[
	Aurora UI  •  Keybind.luau
	------------------------------------------------------------------
	Click to record a keyboard or mouse binding (with modifier display),
	press Backspace to clear and Escape to cancel. Registers a global
	listener so `Callback` fires whenever the binding is pressed.

	Common uses: binding a menu hotkey, a screenshot key, or an
	accessibility shortcut.
--]]

local Util = require(script.Parent.Parent.Util)
local Row = require(script.Parent.Row)
local UserInputService = game:GetService("UserInputService")

local Keybind = {}

function Keybind.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local row = Row.Create(parent, {
		Name = config.Name,
		Description = config.Description,
		Height = config.Height,
	})

	local pill = Util.New("Frame", {
		Name = "KeyPill",
		BackgroundColor3 = Util.Theme.Surface,
		Size = UDim2.fromOffset(config.Width or 96, 28),
		BorderSizePixel = 0,
		Parent = row.Right,
	})
	Util.Corner(7, pill)
	local stroke = Util.Stroke(Util.Theme.Stroke, 1, 0, pill)
	Util.Themable(pill, "BackgroundColor3", "Surface")
	Util.Themable(stroke, "Color", "Stroke")

	local label = Util.Text({
		Name = "KeyLabel",
		Text = "None",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = Util.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = pill,
	})
	Util.Themable(label, "TextColor3", "TextMuted")

	local key: Enum.KeyCode? = config.Default
	local mouseButton: Enum.UserInputType? = config.MouseButton
	local listening = false
	local enabled = config.Disabled ~= true
	local object = { Instance = row.Frame, Kind = "Keybind" }

	local function comboLabel(): string
		if mouseButton then
			if mouseButton == Enum.UserInputType.MouseButton1 then
				return "Mouse Left"
			elseif mouseButton == Enum.UserInputType.MouseButton2 then
				return "Mouse Right"
			elseif mouseButton == Enum.UserInputType.MouseButton3 then
				return "Mouse Middle"
			end
			return "Mouse"
		end
		if not key then
			return config.Placeholder or "None"
		end
		return Util.KeyLabel(key, {
			LeftControl = config.Modifiers and config.Modifiers.Control,
			LeftShift = config.Modifiers and config.Modifiers.Shift,
			LeftAlt = config.Modifiers and config.Modifiers.Alt,
		})
	end

	local function render()
		label.Text = listening and "Press a key…" or comboLabel()
		label.TextColor3 = listening and Util.Theme.Accent or Util.Theme.TextMuted
	end

	local connection
	local function stopListening()
		listening = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
		Util.Tween(pill, { BackgroundColor3 = Util.Theme.Surface }, "Fast")
		Util.Tween(stroke, { Color = Util.Theme.Stroke, Transparency = 0 }, "Fast")
		render()
	end

	local function startListening()
		if not enabled or listening then
			return
		end
		listening = true
		render()
		Util.Tween(pill, { BackgroundColor3 = Util.Theme.AccentSoft }, "Fast")
		Util.Tween(stroke, { Color = Util.Theme.Accent, Transparency = 0 }, "Fast")

		connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not listening then
				return
			end
			if gameProcessed then
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				stopListening()
				return
			elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
				key, mouseButton = nil, nil
				stopListening()
				Util.SafeCall(config.Callback, nil)
				return
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseButton, key = Enum.UserInputType.MouseButton1, nil
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				mouseButton, key = Enum.UserInputType.MouseButton2, nil
			elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
				mouseButton, key = Enum.UserInputType.MouseButton3, nil
			elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				key, mouseButton = input.KeyCode, nil
				config.Modifiers = {
					Control = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl),
					Shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift),
					Alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt),
				}
			else
				return
			end

			stopListening()
			Util.SafeCall(config.Callback, key, mouseButton, config.Modifiers)
		end)
	end

	Util.OnClick(pill, startListening)
	Util.OnClick(row.Frame, startListening)

	-- Global trigger ---------------------------------------------------
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or listening or not enabled then
			return
		end
		if config.RequireNoModifiers ~= false and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
			return
		end

		local pressed = false
		if mouseButton and input.UserInputType == mouseButton then
			pressed = true
		elseif key and input.KeyCode == key then
			pressed = true
				and (not config.Modifiers or (
					(not config.Modifiers.Control or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))
					and (not config.Modifiers.Shift or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
					and (not config.Modifiers.Alt or UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt))
				))
		end

		if pressed then
			Util.SafeCall(config.OnPressed)
		end
	end)

	render()

	function object.Get(self): (Enum.KeyCode?, Enum.UserInputType?)
		return key, mouseButton
	end

	function object.Set(self, nextKey: Enum.KeyCode?, nextButton: Enum.UserInputType?, silent: boolean?)
		key, mouseButton = nextKey, nextButton
		render()
		if not silent then
			Util.SafeCall(config.Callback, key, mouseButton)
		end
	end

	function object.SetEnabled(self, value: boolean)
		enabled = value
		Util.Tween(row.Frame, { BackgroundTransparency = value and 1 or 0.6 }, "Fast")
	end

	function object.Destroy(self)
		stopListening()
		row.Frame:Destroy()
	end

	return object
end

return Keybind
