--[[
	Aurora UI  •  Preview.luau
	==================================================================
	A one-call live preview of the REAL kit — no mock, no HTML, no
	screenshots. Every pixel you see is produced by the same components
	you ship, running in your own game.

		local Preview = require(game.ReplicatedStorage.UI.UILibrary.Preview)
		Preview.Mount()

	What you get
	------------
		Gallery       every component, wired to a live event log
		Appearance    palette / accent / scale, changed at runtime
		Events        toasts, modal, and the log itself
		Reference     the public API on one screen

	Every callback writes to the log, so "did my Callback fire?" is a
	question you can answer by clicking, not by reading source.

	Single-file build: dist/AuroraPreview.luau — paste and run.
--]]

local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)
local Window = require(script.Parent.Components.Window)

local Preview = {}

Preview.Version = "4.2.0"
Preview.Window = nil

local LOG_LIMIT = 9

------------------------------------------------------------------
-- helpers
------------------------------------------------------------------

--- HH:MM:SS, safe on runtimes without a full `os` library.
local function Clock(): string
	local ok, now = pcall(function()
		return os.date("*t")
	end)
	if ok and type(now) == "table" then
		return string.format("%02d:%02d:%02d", now.hour or 0, now.min or 0, now.sec or 0)
	end
	return "00:00:00"
end

--- A tiny append-only log rendered as labels inside a Section.
local function CreateLog()
	local log = {
		Entries = {},
		Labels = {},
		Section = nil,
	}

	--- Rebuild the visible rows (newest first).
	function log:Render()
		if not self.Section then
			return
		end
		local card = self.Section.Instance
		if not card or not card.Parent then
			self.Section = nil
			self.Labels = {}
			return
		end
		for _, label in ipairs(self.Labels) do
			label:Destroy()
		end
		self.Labels = {}
		for _, line in ipairs(self.Entries) do
			local label = self.Section:AddLabel(line, { TextSize = 11 })
			table.insert(self.Labels, label)
		end
	end

	--- Attach the section that displays the log.
	function log:Attach(section)
		self.Section = section
		self:Render()
	end

	--- Add a line: log:Write("toggle", "Auto sprint → true")
	function log:Write(tag: string, message: string)
		table.insert(self.Entries, 1, string.format("%s  %-9s %s", Clock(), tag, message))
		while #self.Entries > LOG_LIMIT do
			table.remove(self.Entries)
		end
		self:Render()
	end

	function log:Clear()
		self.Entries = {}
		self:Render()
	end

	return log
end

------------------------------------------------------------------
-- Gallery tab
------------------------------------------------------------------

local function BuildGallery(window, log)
	local tab = window:CreateTab({ Name = "Gallery", Icon = "layers" })

	tab:AddStats({
		{
			Title = "Components",
			Value = 14,
			Delta = 0,
			Icon = "layers",
			Token = "Accent",
			Data = { 4, 5, 6, 6, 7, 8, 9, 9, 10, 11, 12, 12, 13, 14, 14, 14 },
			Format = function(value)
				return string.format("%d", value)
			end,
		},
		{
			Title = "Icons",
			Value = 31,
			Delta = 0,
			Icon = "sparkle",
			Token = "Success",
			Data = { 12, 14, 15, 17, 18, 20, 21, 23, 24, 26, 27, 28, 29, 30, 31, 31 },
			Format = function(value)
				return string.format("%d", value)
			end,
		},
		{
			Title = "Palettes",
			Value = 4,
			Delta = 0,
			Icon = "sun",
			Token = "Info",
			Data = { 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4 },
			Format = function(value)
				return string.format("%d", value)
			end,
		},
	}, { Columns = 3, CellHeight = 92 })

	--------------------------------------------------------------- buttons
	local buttons = tab:CreateSection({
		Name = "Buttons",
		Description = "Four styles, two layouts.",
		Icon = "bolt",
	})

	buttons:AddButton({
		Name = "Primary",
		Style = "primary",
		Callback = function()
			log:Write("button", "Primary clicked")
		end,
	})

	buttons:AddButton({
		Name = "Secondary",
		Style = "secondary",
		Callback = function()
			log:Write("button", "Secondary clicked")
		end,
	})

	buttons:AddButton({
		Name = "Danger",
		Style = "danger",
		Callback = function()
			log:Write("button", "Danger clicked")
		end,
	})

	buttons:AddButton({
		Name = "Two-step confirm",
		Style = "secondary",
		Confirm = true,
		ConfirmText = "Tap again to commit",
		Callback = function()
			log:Write("button", "Confirmed after the second click")
		end,
	})

	buttons:AddButton({
		Name = "Full-width action",
		Icon = "sparkle",
		Style = "block",
		FullWidth = true,
		Callback = function()
			log:Write("button", "Full-width action clicked")
		end,
	})

	--------------------------------------------------------------- inputs
	local inputs = tab:CreateSection({
		Name = "Inputs",
		Description = "Every control reports through the log.",
		Icon = "sliders",
	})

	inputs:AddToggle({
		Name = "Toggle",
		Description = "State is persisted by the caller, not the kit.",
		Default = true,
		Callback = function(value)
			log:Write("toggle", "value = " .. tostring(value))
		end,
	})

	inputs:AddSlider({
		Name = "Slider",
		Description = "Keyboard, mouse and touch all supported.",
		Min = 0,
		Max = 100,
		Default = 42,
		Step = 1,
		Suffix = "%",
		Callback = function(value)
			log:Write("slider", string.format("%d%%", value))
		end,
	})

	inputs:AddDropdown({
		Name = "Dropdown",
		Description = "Single choice.",
		Options = { "Compact", "Comfortable", "Spacious" },
		Default = "Comfortable",
		Callback = function(value)
			log:Write("dropdown", tostring(value))
		end,
	})

	inputs:AddDropdown({
		Name = "Multi dropdown",
		Description = "Up to three picks.",
		Multi = true,
		Max = 3,
		Options = { "Rain", "Snow", "Fog", "Leaves", "Sparks", "Dust" },
		Default = { "Fog" },
		Callback = function(values)
			log:Write("dropdown", table.concat(values, ", "))
		end,
	})

	inputs:AddTextBox({
		Name = "Text box",
		Description = "Placeholder, length limit, live callback.",
		Placeholder = "Type anything…",
		MaxLength = 32,
		Callback = function(text)
			log:Write("textbox", text == "" and "(empty)" or text)
		end,
	})

	inputs:AddKeybind({
		Name = "Keybind",
		Description = "Click, then press a key.",
		Default = Enum.KeyCode.G,
		OnPressed = function()
			log:Write("keybind", "bound key pressed")
		end,
	})

	inputs:AddColorPicker({
		Name = "Color picker",
		Description = "HSV square plus hue rail.",
		Default = Color3.fromHex("#7C5CFF"),
		Callback = function(color)
			log:Write("color", "#" .. Util.ToHex(color))
		end,
	})

	-------------------------------------------------------------- structure
	local structure = tab:CreateSection({
		Name = "Structure",
		Description = "Cards, labels, dividers — all collapsible.",
		Icon = "layers",
	})

	structure:AddLabel("Aurora builds its layout from Sections. Each card can collapse, and everything inside it re-themes instantly.")

	structure:AddDivider({ Spacing = 4 })

	structure:AddButton({
		Name = "Collapse this card",
		Style = "secondary",
		Callback = function()
			structure:SetCollapsed(true)
			log:Write("section", "collapsed programmatically")
		end,
	})

	return tab
end

------------------------------------------------------------------
-- Appearance tab
------------------------------------------------------------------

local function BuildAppearance(window, log)
	local tab = window:CreateTab({ Name = "Appearance", Icon = "sun" })

	local palette = tab:CreateSection({
		Name = "Palette",
		Description = "Four palettes ship with the kit. Add your own in Theme.luau.",
		Icon = "sun",
	})

	local themeNames = Theme.List()
	local themeDropdown = palette:AddDropdown({
		Name = "Theme",
		Options = themeNames,
		Default = window.ThemeName or "Midnight",
		Callback = function(name)
			window:SetTheme(name)
			log:Write("theme", name)
		end,
	})

	palette:AddButton({
		Name = "Cycle palette",
		Style = "primary",
		Callback = function()
			window:CycleTheme()
			if themeDropdown and themeDropdown.Set then
				themeDropdown:Set(window.ThemeName, true)
			end
			log:Write("theme", window.ThemeName or "?")
		end,
	})

	local accent = tab:CreateSection({
		Name = "Accent",
		Description = "Recolors gradients, icons and focus rings.",
		Icon = "sparkle",
	})

	local accentPicker = accent:AddColorPicker({
		Name = "Accent color",
		Description = "Applies instantly across the window.",
		Default = Util.Theme.Accent,
		Callback = function(color)
			window:SetAccent(color)
			log:Write("accent", "#" .. Util.ToHex(color))
		end,
	})

	local scale = tab:CreateSection({
		Name = "Layout",
		Description = "Auto-fit keeps the window usable on phones.",
		Icon = "sliders",
	})

	scale:AddSlider({
		Name = "UI scale",
		Description = "100% is the design size.",
		Min = 75,
		Max = 135,
		Default = 100,
		Step = 5,
		Suffix = "%",
		Callback = function(value)
			window:SetScale(value / 100)
			log:Write("scale", string.format("%d%%", value))
		end,
	})

	scale:AddTextBox({
		Name = "Subtitle",
		Description = "Updates the text under the title.",
		Placeholder = "v" .. Preview.Version .. "  •  ready",
		MaxLength = 40,
		Callback = function(text)
			window:SetSubtle(text == "" and "v" .. Preview.Version .. "  •  ready" or text)
		end,
	})

	scale:AddTextBox({
		Name = "Status line",
		Description = "Bottom bar message.",
		Placeholder = "Connected  •  42 ms",
		MaxLength = 48,
		Callback = function(text)
			window:SetStatus(text == "" and "Previewing every component" or text, true)
		end,
	})

	scale:AddButton({
		Name = "Reset appearance",
		Style = "secondary",
		Confirm = true,
		ConfirmText = "Tap again to reset",
		Callback = function()
			window:SetAccent(nil)
			window:SetScale(1)
			window:SetTheme("Midnight")
			if accentPicker and accentPicker.Set then
				accentPicker:Set(Theme.Get("Midnight").Accent)
			end
			if themeDropdown and themeDropdown.Set then
				themeDropdown:Set("Midnight", true)
			end
			log:Write("appearance", "reset to defaults")
		end,
	})

	return tab
end

------------------------------------------------------------------
-- Events tab
------------------------------------------------------------------

local function BuildEvents(window, log, galleryLogSection)
	local tab = window:CreateTab({ Name = "Events", Icon = "bell" })

	local lab = tab:CreateSection({
		Name = "Notifications",
		Description = "Four tones, capped at four visible toasts.",
		Icon = "bell",
	})

	for _, entry in ipairs({
		{ Name = "Success", Type = "success", Icon = "check" },
		{ Name = "Warning", Type = "warning", Icon = "warning" },
		{ Name = "Error", Type = "error", Icon = "close" },
		{ Name = "Info", Type = "info", Icon = "info" },
	}) do
		lab:AddButton({
			Name = entry.Name,
			Style = "secondary",
			Callback = function()
				window:Notify({
					Title = entry.Name .. " toast",
					Body = "Fired from the preview at " .. Clock() .. ".",
					Type = entry.Type,
					Icon = entry.Icon,
					Duration = 4,
				})
				log:Write("notify", entry.Type)
			end,
		})
	end

	lab:AddButton({
		Name = "Fire six at once",
		Style = "primary",
		FullWidth = true,
		Callback = function()
			for index = 1, 6 do
				task.delay(index * 0.1, function()
					window:Notify({
						Title = "Burst " .. index,
						Body = "Oldest toast is dropped when the stack is full.",
						Type = ({ "info", "success", "warning" })[(index - 1) % 3 + 1],
						Duration = 4,
					})
				end)
			end
			log:Write("notify", "burst of six")
		end,
	})

	lab:AddButton({
		Name = "Clear toasts",
		Style = "secondary",
		Callback = function()
			window:ClearNotifications()
			log:Write("notify", "stack cleared")
		end,
	})

	local dialogs = tab:CreateSection({
		Name = "Dialogs",
		Description = "Modals render above every layer of the window.",
		Icon = "lock",
	})

	dialogs:AddButton({
		Name = "Open modal",
		Style = "secondary",
		Callback = function()
			window:Modal({
				Title = "Preview modal",
				Body = "This dialog is part of the kit, themed and scaled like everything else.",
				ConfirmText = "Got it",
				OnConfirm = function()
					log:Write("modal", "confirmed")
				end,
			})
		end,
	})

	dialogs:AddButton({
		Name = "Close window",
		Style = "danger",
		Callback = function()
			window:Close()
			log:Write("window", "closed — reopen with the bind or the FAB")
		end,
	})

	local logSection = tab:CreateSection({
		Name = "Event log",
		Description = "Newest first. Every control in this preview writes here.",
		Icon = "code",
	})

	logSection:AddButton({
		Name = "Clear log",
		Style = "secondary",
		Callback = function()
			log:Clear()
			log:Write("log", "cleared")
		end,
	})

	log:Attach(logSection)

	if galleryLogSection then
		galleryLogSection:AddLabel("Every control above also writes to the Events → Event log tab.")
	end

	return tab
end

------------------------------------------------------------------
-- Reference tab
------------------------------------------------------------------

local function BuildReference(window, log)
	local tab = window:CreateTab({ Name = "Reference", Icon = "code" })

	local api = tab:CreateSection({
		Name = "Window",
		Description = "Returned by UI.CreateWindow(config).",
		Icon = "layers",
	})

	for _, line in ipairs({
		"window:CreateTab{ Name, Icon, Badge }",
		"window:Notify{ Title, Body, Type, Icon, Duration }",
		"window:Modal{ Title, Body, ConfirmText, OnConfirm }",
		"window:SetTheme(name)          window:CycleTheme()",
		"window:SetAccent(color|nil)    window:SetScale(0.75 → 1.35)",
		"window:SetStatus(text, ok?)    window:SetSubtle(text)",
		"window:Open()  Close()  Toggle()  Destroy()",
		"window:SelectTab(tab)          window:ClearNotifications()",
	}) do
		api:AddLabel(line, { TextSize = 12, Token = "Text" })
	end

	local sections = tab:CreateSection({
		Name = "Section",
		Description = "Returned by tab:CreateSection(config).",
		Icon = "sliders",
	})

	for _, line in ipairs({
		"section:AddToggle{ Name, Description, Default, Callback }",
		"section:AddSlider{ Min, Max, Default, Step, Suffix, Decimals }",
		"section:AddDropdown{ Options, Default, Multi, Max }",
		"section:AddTextBox{ Placeholder, MaxLength, Validate }",
		"section:AddKeybind{ Default, OnPressed }",
		"section:AddColorPicker{ Default, Callback }",
		"section:AddButton{ Name, Style, Icon, Confirm, FullWidth }",
		"section:AddLabel(text, { Bold, TextSize, Token })",
		"section:AddDivider{ Spacing }   section:AddRow(fn)",
		"section:SetCollapsed(bool)      section:SetVisible(bool)",
	}) do
		sections:AddLabel(line, { TextSize = 12, Token = "Text" })
	end

	local tabs = tab:CreateSection({
		Name = "Tab",
		Description = "Returned by window:CreateTab(config). Starts collapsed.",
		Icon = "chart",
		Collapsed = true,
	})

	for _, line in ipairs({
		"tab:CreateSection(config)       tab:AddStats(cards, grid)",
		"tab:AddGrid{ Columns, CellHeight }",
		"tab:SetBadge(number)            tab:SetActive(bool)",
		"tab:Select()                    tab:ScrollTo(instance)",
	}) do
		tabs:AddLabel(line, { TextSize = 12, Token = "Text" })
	end

	local palettes = tab:CreateSection({
		Name = "Palettes",
		Description = "Theme tokens are plain Color3 values.",
		Icon = "sun",
	})

	for _, name in ipairs(Theme.List()) do
		local palette = Theme.Get(name)
		local hex = "#" .. Util.ToHex(palette.Accent)
		palettes:AddButton({
			Name = name .. "  •  " .. hex,
			Style = "secondary",
			Callback = function()
				window:SetTheme(name)
				log:Write("theme", name)
			end,
		})
	end

	return tab
end

------------------------------------------------------------------
-- Mount / Unmount
------------------------------------------------------------------

--- Build and show the preview window.
--- @param config? { GuiParent, Theme, Keybind, Width, Height, Title }
--- @return the window object
function Preview.Mount(config)
	config = config or {}

	Preview.Unmount()

	local window = Window.New({
		Title = config.Title or "Aurora UI",
		Subtitle = "v" .. Preview.Version .. "  •  live preview",
		Icon = "sparkle",
		Theme = config.Theme or "Midnight",
		Keybind = config.Keybind or Enum.KeyCode.RightShift,
		Width = config.Width or 900,
		Height = config.Height or 580,
		Status = "Previewing every component",
		GuiParent = config.GuiParent,
		OnThemeChanged = function(name)
			Preview.Theme = name
		end,
	})

	Preview.Window = window
	Preview.Theme = window.ThemeName

	local log = CreateLog()
	Preview.Log = log

	BuildGallery(window, log)
	BuildAppearance(window, log)
	BuildEvents(window, log)
	BuildReference(window, log)

	window:SelectTab(window.Tabs[1])
	window:SetStatus("Previewing every component  •  v" .. Preview.Version, true)
	log:Write("system", "mounted " .. Preview.Version)

	print("[Aurora] preview ready — " .. #window.Tabs .. " tabs, press the bind to toggle")
	return window
end

--- Destroy the preview window, if one is open.
function Preview.Unmount()
	if Preview.Window then
		pcall(function()
			Preview.Window:Destroy()
		end)
		Preview.Window = nil
	end
end

--- True when a preview window exists and is still parented.
function Preview.IsMounted(): boolean
	local window = Preview.Window
	if not window or not window.Instance then
		return false
	end
	return window.Instance.Parent ~= nil
end

return Preview
