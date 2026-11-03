--[[
	Aurora UI  •  Demo (StarterPlayerScripts/Main.client.luau)
	==================================================================
	A full walkthrough of the kit: dashboard, toggles, sliders,
	dropdowns, keybinds, color pickers, text boxes, notifications,
	modals, live status and theme switching.

	Drop this in StarterPlayer ▸ StarterPlayerScripts and press
	Right Shift in game.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("UI"):WaitForChild("UILibrary"))

------------------------------------------------------------------
-- Style
------------------------------------------------------------------
-- One demo, ten designs. Change this line (or the AuroraStyle attribute)
-- to rebuild the same menu in another language:
--
--   midnight · daylight · neon · terminal · brutalist
--   frost · material · arcade · executive · solar
local STYLE = "Midnight"
if typeof(_G) == "table" and _G.AURORA_DUMP_STYLE then
	STYLE = _G.AURORA_DUMP_STYLE
end

------------------------------------------------------------------
-- Window
------------------------------------------------------------------
local window = UI.CreateWindow({
	Title = "Aurora",
	Subtitle = "v" .. UI.Version .. "  •  " .. STYLE .. " template",
	Icon = "sparkle",
	Style = STYLE,
	Keybind = Enum.KeyCode.RightShift,
	Width = 900,
	Height = 580,
	Status = "Connected  •  62 ms",
	OnThemeChanged = function(name)
		print("[Aurora] theme ->", name)
	end,
})

------------------------------------------------------------------
-- HOME
------------------------------------------------------------------
local home = window:CreateTab({ Name = "Home", Icon = "home" })

local stats = home:AddStats({
	{
		Title = "Session time",
		Value = 1840,
		Delta = 12.4,
		Icon = "cloud",
		Token = "Accent",
		Data = { 4, 6, 5, 8, 7, 11, 9, 13, 12, 15, 14, 18, 17, 20, 19, 24 },
		Format = function(value)
			local minutes = math.floor(value / 60)
			local seconds = math.floor(value % 60)
			return string.format("%d:%02d", minutes, seconds)
		end,
	},
	{
		Title = "Actions fired",
		Value = 12480,
		Delta = 4.8,
		Icon = "bolt",
		Token = "Success",
		Data = { 8, 9, 7, 12, 10, 13, 11, 15, 14, 12, 16, 18, 15, 19, 22, 21 },
	},
	{
		Title = "Memory",
		Value = 68.4,
		Delta = -3.1,
		Icon = "chart",
		Token = "Warning",
		Data = { 20, 18, 19, 17, 16, 18, 15, 14, 16, 13, 12, 14, 11, 12, 10, 9 },
		Format = function(value)
			return string.format("%.1f MB", value)
		end,
	},
}, { Columns = 3, CellHeight = 96 })

local quick = home:CreateSection({
	Name = "Quick actions",
	Description = "The three things you will use most often.",
	Icon = "sparkle",
})

quick:AddButton({
	Name = "Run optimizer",
	Icon = "bolt",
	Style = "block",
	Callback = function()
		window:Notify({
			Title = "Optimizer finished",
			Body = "Freed 214 MB and rebuilt 4 caches in 1.8 s.",
			Type = "success",
		})
	end,
})

quick:AddButton({
	Name = "Reset everything",
	Icon = "trash",
	Style = "secondary",
	Confirm = true,
	ConfirmText = "Tap again to confirm",
	Callback = function()
		window:Notify({
			Title = "Configuration reset",
			Body = "All modules returned to their defaults.",
			Type = "warning",
		})
	end,
})

local overview = home:CreateSection({
	Name = "Live overview",
	Description = "Streams values while the menu is open.",
	Icon = "eye",
})

local fpsSlider = overview:AddSlider({
	Name = "Target FPS",
	Description = "Frame cap applied while the menu is open.",
	Min = 30,
	Max = 240,
	Default = 120,
	Step = 10,
	Suffix = " fps",
	Callback = function(value)
		window:SetStatus(string.format("FPS cap  •  %d", value), true)
	end,
})

local streamToggle = overview:AddToggle({
	Name = "Stream metrics",
	Description = "Updates the cards above every second.",
	Default = true,
})

overview:AddDivider()

local uptimeLabel = overview:AddLabel("Waiting for first sample…")

------------------------------------------------------------------
-- COMBAT
------------------------------------------------------------------
local gameplay = window:CreateTab({ Name = "Gameplay", Icon = "shield", Badge = 2 })

local targeting = gameplay:CreateSection({
	Name = "Movement",
	Description = "Sprint behaviour and camera feel.",
	Icon = "shield",
})

targeting:AddToggle({
	Name = "Auto sprint",
	Description = "Sprints while the move stick is held forward.",
	Default = true,
	Callback = function(value)
		if value then
			window:Notify({ Title = "Auto sprint on", Type = "success", Duration = 2.2 })
		end
	end,
})

targeting:AddToggle({
	Name = "Sprint lock",
	Description = "Keeps your speed while turning corners.",
	Default = false,
})

targeting:AddSlider({
	Name = "Field of view",
	Description = "Camera field of view while sprinting.",
	Min = 5,
	Max = 180,
	Default = 65,
	Step = 1,
	Suffix = "°",
})

targeting:AddDropdown({
	Name = "Camera mode",
	Description = "How the camera follows your character.",
	Options = { "First person", "Third person", "Orbit", "Shoulder", "Auto" },
	Default = "First person",
	Callback = function(value)
		window:Notify({ Title = "Camera mode", Body = tostring(value), Type = "info", Duration = 2 })
	end,
})

targeting:AddKeybind({
	Name = "Quick menu key",
	Description = "Opens this menu from anywhere.",
	Default = Enum.KeyCode.F,
	OnPressed = function()
		window:Notify({
			Title = "Quick menu bound",
			Body = "Press it any time to reopen this menu.",
			Type = "info",
		})
	end,
})

local indicators = gameplay:CreateSection({
	Name = "HUD",
	Icon = "eye",
})

indicators:AddColorPicker({
	Name = "HUD accent",
	Description = "Applied to markers and waypoints.",
	Default = Color3.fromHex("#7C5CFF"),
})

indicators:AddToggle({
	Name = "Waypoint markers",
	Default = true,
})

indicators:AddToggle({
	Name = "Distance labels",
	Default = true,
})

------------------------------------------------------------------
-- VISUALS
------------------------------------------------------------------
local visuals = window:CreateTab({ Name = "Visuals", Icon = "eye" })

local world = visuals:CreateSection({
	Name = "World",
	Description = "Lighting and atmosphere tweaks.",
	Icon = "sun",
})

world:AddToggle({ Name = "Brighter lighting", Default = true })
world:AddSlider({
	Name = "Brightness",
	Min = 0,
	Max = 5,
	Default = 2,
	Step = 0.1,
	Decimals = 1,
})

world:AddDropdown({
	Name = "Weather effects",
	Multi = true,
	Max = 3,
	Description = "Layer up to three effects.",
	Options = { "Rain", "Snow", "Fog", "Leaves", "Sparks", "Heat haze", "Dust" },
	Default = { "Fog" },
	Callback = function(values)
		print("[Aurora] weather:", table.concat(values, ", "))
	end,
})

world:AddDivider()

world:AddSlider({
	Name = "Camera FOV",
	Min = 40,
	Max = 120,
	Default = 70,
	Suffix = "°",
	Callback = function(value)
		workspace.CurrentCamera.FieldOfView = value
	end,
})

local nameplates = visuals:CreateSection({
	Name = "Nameplates",
	Description = "Names, team colors and health bars.",
	Icon = "user",
})

nameplates:AddToggle({ Name = "Show nameplates", Default = false })
nameplates:AddToggle({ Name = "Team colors", Default = true })
nameplates:AddToggle({ Name = "Player names", Default = true })
nameplates:AddToggle({ Name = "Health bars", Default = true })
nameplates:AddColorPicker({
	Name = "Hostile color",
	Default = Color3.fromHex("#FB7185"),
})
nameplates:AddColorPicker({
	Name = "Friendly color",
	Default = Color3.fromHex("#34D399"),
})

------------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------------
local misc = window:CreateTab({ Name = "Utilities", Icon = "sliders", Badge = 3 })

local tools = misc:CreateSection({
	Name = "Server",
	Description = "Region selection and queue behaviour.",
	Icon = "cloud",
})

tools:AddDropdown({
	Name = "Region",
	Options = {
		"Singapore",
		"Tokyo",
		"Frankfurt",
		"Virginia",
		"Sydney",
		"São Paulo",
		"Dubai",
		"Mumbai",
		"Miami",
	},
	Default = "Singapore",
})

tools:AddTextBox({
	Name = "Server code",
	Description = "Join a private server directly.",
	Placeholder = "abc-123",
	Icon = "lock",
	MaxLength = 12,
	Callback = function(text)
		if text ~= "" then
			window:Notify({ Title = "Server code set", Body = text, Type = "info" })
		end
	end,
})

tools:AddSlider({
	Name = "Rejoin delay",
	Min = 0,
	Max = 30,
	Default = 4,
	Suffix = " s",
})

local commands = misc:CreateSection({
	Name = "Chat commands",
	Icon = "code",
})

commands:AddTextBox({
	Name = "Command prefix",
	Default = "!",
	Placeholder = "!",
	Width = 90,
	ClearButton = false,
})

commands:AddTextBox({
	Name = "Webhook URL",
	Description = "Optional. Used for log mirroring.",
	Placeholder = "https://discord.com/api/…",
	Width = 200,
	Validate = function(text)
		if text == "" then
			return true
		end
		return string.sub(text, 1, 8) == "https://", "URL must start with https://"
	end,
})

local notifyDemo = misc:CreateSection({
	Name = "Notification lab",
	Description = "Fire each toast type.",
	Icon = "bell",
})

for _, entry in ipairs({
	{ Name = "Success toast", Type = "success", Icon = "check" },
	{ Name = "Warning toast", Type = "warning", Icon = "warning" },
	{ Name = "Error toast", Type = "error", Icon = "close" },
	{ Name = "Info toast", Type = "info", Icon = "info" },
}) do
	notifyDemo:AddButton({
		Name = entry.Name,
		Style = "secondary",
		Callback = function()
			window:Notify({
				Title = entry.Name,
				Body = "This is a live " .. entry.Type .. " notification with a progress bar.",
				Type = entry.Type,
				Icon = entry.Icon,
				Duration = 4,
			})
		end,
	})
end

notifyDemo:AddButton({
	Name = "Stack three toasts",
	Style = "primary",
	FullWidth = true,
	Callback = function()
		for index = 1, 3 do
			task.delay(index * 0.12, function()
				window:Notify({
					Title = "Toast " .. index,
					Body = "Queued with a staggered entrance.",
					Type = ({ "info", "success", "warning" })[index],
					Duration = 4,
				})
			end)
		end
	end,
})

------------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------------
local settings = window:CreateTab({ Name = "Settings", Icon = "gear" })

local appearance = settings:CreateSection({
	Name = "Appearance",
	Description = "Themes are data, so any palette you add shows up here.",
	Icon = "sun",
})

appearance:AddDropdown({
	Name = "Theme",
	Options = UI.GetThemes(),
	Default = "Midnight",
	Callback = function(name)
		window:SetTheme(name)
	end,
})

appearance:AddColorPicker({
	Name = "Accent override",
	Description = "Replaces the palette accent everywhere.",
	Default = Color3.fromHex("#7C5CFF"),
	Callback = function(color)
		local palette = UI.GetTheme(window.ThemeName)
		local override = table.clone(palette)
		override.Accent = color
		override.Accent2 = color:Lerp(Color3.new(1, 1, 1), 0.35)
		override.AccentSoft = color:Lerp(UI.GetTheme(window.ThemeName).Panel, 0.75)
		UI.Util.ApplyTheme(override)
	end,
})

appearance:AddSlider({
	Name = "Menu scale",
	Min = 80,
	Max = 115,
	Default = 100,
	Step = 1,
	Suffix = "%",
	Callback = function(value)
		local scale = window.Instance:FindFirstChildOfClass("UIScale")
		if scale then
			UI.Util.Tween(scale, { Scale = value / 100 }, "Fast")
		end
	end,
})

appearance:AddToggle({
	Name = "Background blur",
	Description = "Blurs the game world behind the menu.",
	Default = true,
	Callback = function(value)
		if window.Blur then
			UI.Util.Tween(window.Blur, { Size = value and 14 or 0 }, "Smooth")
		end
	end,
})

appearance:AddToggle({
	Name = "Hover highlights",
	Default = true,
})

local behaviour = settings:CreateSection({
	Name = "Behaviour",
	Icon = "sliders",
})

behaviour:AddKeybind({
	Name = "Toggle menu",
	Default = Enum.KeyCode.RightShift,
	OnPressed = function()
		window:Toggle()
	end,
})

behaviour:AddToggle({
	Name = "Block game input",
	Description = "Prevents clicks behind the window.",
	Default = true,
})

behaviour:AddButton({
	Name = "Close menu",
	Style = "ghost",
	Callback = function()
		window:Close()
	end,
})

behaviour:AddButton({
	Name = "Factory reset",
	Style = "danger",
	Confirm = true,
	Callback = function()
		window:Modal({
			Title = "Delete all settings?",
			Body = "This clears every saved toggle, slider value and keybind for this game.",
			ConfirmText = "Delete",
			CancelText = "Keep",
			OnConfirm = function()
				window:Notify({ Title = "Settings deleted", Type = "error" })
			end,
		})
	end,
})

local about = settings:CreateSection({
	Name = "About",
	Icon = "info",
})

about:AddLabel(
	"Aurora UI v" .. UI.Version .. "  —  a modern interface kit for Roblox: glass panels, animated rail, themable controls and zero image assets."
)

about:AddDivider()

about:AddLabel("Right Shift toggles this window. Click any theme chip in the footer to cycle palettes.", {
	TextSize = 11,
})

about:AddButton({
	Name = "Show changelog",
	Style = "secondary",
	Callback = function()
		window:Modal({
			Title = "What's new in 2.0",
			Body = "• Four palettes with live re-theming\n• Global search with jump-to-setting\n• Sparkline stat cards\n• Rewritten drag & resize\n• Accessible focus rings everywhere",
			ConfirmText = "Nice",
			CancelText = "Close",
		})
	end,
})

------------------------------------------------------------------
-- Live values
------------------------------------------------------------------
local sessionStart = os.clock()
local actions = 12480
local samples = {}
local lastSample = 0

local smoothDelta = 1 / 60

RunService.Heartbeat:Connect(function(deltaTime)
	smoothDelta = smoothDelta * 0.9 + deltaTime * 0.1

	if not streamToggle:Get() then
		return
	end

	local now = os.clock()
	if now - lastSample < 1 then
		return
	end
	lastSample = now

	local elapsed = now - sessionStart
	actions += math.random(3, 14)

	stats[1]:SetValue(1000 + elapsed)
	stats[2]:SetValue(actions)
	stats[3]:SetValue(52 + math.sin(elapsed / 5) * 6 + math.random() * 3)

	table.insert(samples, 60 + math.sin(elapsed / 3) * 8 + math.random() * 4)
	if #samples > 16 then
		table.remove(samples, 1)
	end
	stats[3]:SetData(samples)

	uptimeLabel.Text = string.format(
		"Session %dm %02ds  •  %d actions  •  %.0f fps",
		math.floor(elapsed / 60),
		math.floor(elapsed % 60),
		actions,
		math.floor(1 / math.max(smoothDelta, 0.001))
	)

	window:SetStatus(string.format("Connected  •  %d ms", math.random(38, 86)), true)

	fpsSlider:Set(math.clamp(math.floor(60 + math.sin(elapsed / 4) * 30), 30, 240), true)
end)

-- Keep the window alive across respawns and greet the player.
task.spawn(function()
	task.wait(0.6)
	window:Notify({
		Title = "Aurora UI loaded",
		Body = "Press Right Shift to toggle. Try the search box or the footer theme chip.",
		Type = "success",
		Duration = 6,
		Icon = "sparkle",
	})
	window:Notify({
		Title = "Tip",
		Body = "Every panel is drag-and-resizable from the bottom-right corner.",
		Type = "info",
		Duration = 6,
	})
end)

UserInputService.WindowFocused:Connect(function()
	window:SetSubtle("v" .. UI.Version .. "  •  focused")
end)

UserInputService.WindowFocusReleased:Connect(function()
	window:SetSubtle("v" .. UI.Version .. "  •  idle")
end)

print("[Aurora] demo ready — press Right Shift")
