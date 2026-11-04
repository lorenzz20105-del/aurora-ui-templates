
--====================== SMOKE TEST ==========================
local UI = Aurora
assert(UI.Version, "version missing")

local window = UI.CreateWindow({
	Title = "Aurora", Subtitle = "smoke", Icon = "sparkle",
	Keybind = Enum.KeyCode.RightShift, Width = 900, Height = 580,
	OnBuilt = function() end,
})
assert(window.Instance, "window instance missing")

local home = window:CreateTab({ Name = "Home", Icon = "home" })
local gameplay = window:CreateTab({ Name = "Gameplay", Icon = "shield", Badge = 2 })
local misc = window:CreateTab({ Name = "Misc", Icon = "gear" })

local section = home:CreateSection({ Name = "Gameplay", Description = "desc", Icon = "shield", Badge = "NEW" })
local toggle = section:AddToggle({ Name = "Auto sprint", Description = "d", Default = true, Callback = function() end })
local slider = section:AddSlider({ Name = "FOV", Min = 5, Max = 180, Default = 65, Step = 1, Suffix = " deg" })
local drop = section:AddDropdown({ Name = "Camera mode", Options = { "First person", "Third person" }, Default = "First person" })
local multi = section:AddDropdown({ Name = "Weather", Options = { "Rain","Snow","Fog","Leaves","Sparks","Dust","Haze" }, Multi = true, Default = { "Fog" } })
local box = section:AddTextBox({ Name = "Code", Placeholder = "abc", Icon = "lock", MaxLength = 12 })
local key = section:AddKeybind({ Name = "Panic", Default = Enum.KeyCode.F })
local picker = section:AddColorPicker({ Name = "Color", Default = Color3.fromHex("#7C5CFF") })
local button = section:AddButton({ Name = "Run", Icon = "bolt", Style = "primary", FullWidth = true })
local confirmButton = section:AddButton({ Name = "Reset", Style = "danger", Confirm = true })
section:AddLabel("hello world")
section:AddDivider()
section:AddButton({ Name = "Compact", Style = "ghost" })

local cards = gameplay:AddStats({
	{ Title = "One", Value = 1840, Delta = 12.4, Icon = "cloud", Data = { 4, 6, 5, 8, 11, 9, 13, 12, 15 } },
	{ Title = "Two", Value = 12480, Delta = -3.1, Icon = "bolt", Token = "Success", Data = { 8, 9, 7, 12 } },
}, { Columns = 2, CellHeight = 96 })
assert(#cards == 2, "AddStats returned " .. tostring(#cards) .. " cards")

assert(misc:AddGrid({ Columns = 3 }), "grid missing")

-- API round-trips --------------------------------------------
toggle:Set(false, true)
assert(toggle:Get() == false, "toggle Set(false) failed")
toggle:Toggle()
assert(toggle:Get() == true, "toggle Toggle failed")
slider:Set(120, true)
assert(math.abs(slider:Get() - 120) < 0.001, "slider Set failed: " .. tostring(slider:Get()))
drop:Set("Torso", true)
assert(drop:Get() == "Torso", "dropdown Set failed")
multi:Set({ "Rain", "Fog" }, true)
assert(#multi:Get() == 2, "multi Set failed")
box:Set("abc123", true)
assert(box:Get() == "abc123", "textbox Set failed")
picker:Set(Color3.fromHex("#22D3EE"), true)
assert(UI.Util.ToHex(picker:Get()) == "22D3EE", "picker Set failed")
key:Set(Enum.KeyCode.G, nil, true)
button:SetText("Running"); button:SetLoading(true); button:SetLoading(false); button:SetEnabled(false)
confirmButton:SetEnabled(true)
cards[1]:SetValue(2000, { 1, 2, 3, 4 })
cards[2]:SetData({ 5, 4, 3, 2, 1 }); cards[2]:SetDelta(-1.5)

-- Window surface ---------------------------------------------
window:Notify({ Title = "Hi", Body = "there", Type = "success" })
window:Notify("string toast")
window:Notify({ Title = "Warn", Type = "warning", Duration = 2 })
window:SetStatus("connected", true)
window:SetSubtitle("sub")
window:SelectTab(gameplay)
assert(window.ActiveTab == gameplay, "tab switch failed")
window:SetTheme("Nebula")
window:CycleTheme()
window:Modal({ Title = "T", Body = "B", ConfirmText = "Y", CancelText = "N", OnConfirm = function() end })
window:Toggle(); window:Toggle(); window:Close(); window:Open()
window:SetTheme("Daylight"); window:SetTheme("Emerald"); window:SetTheme("Midnight")

-- Launcher: closing must never be a dead end ------------------
-- The mock reports TouchEnabled = false, so this also proves the logo is not
-- gated on touch any more.
assert(window.Launcher, "launcher missing: closing the menu would be a dead end")
assert(window.Instance and window.Launcher.Name == "Launcher", "launcher name")
window:Close()
task.__flush()
assert(window.Launcher.Visible == true, "launcher hidden after Close")
assert(window.Launcher.AbsoluteSize.X >= 44, "launcher smaller than a touch target")
window:Open()
task.__flush()
assert(window.Launcher.Visible == false, "launcher still showing while the menu is open")
window:SetLauncherVisible(true)
assert(window.Launcher.Visible == true, "SetLauncherVisible(true) failed")
window:SetLauncherVisible(false)
window:Close(); task.__flush(); window:Open(); task.__flush()
assert(window:IsOpen() == true, "reopen failed")

-- Newer API surface ------------------------------------------
window:SetAccent(Color3.fromHex("#22D3EE"))
assert(UI.Util.ToHex(UI.Util.Theme.Accent) == "22D3EE", "SetAccent failed")
window:SetTheme("Nebula")
assert(UI.Util.ToHex(UI.Util.Theme.Accent) == "22D3EE", "accent lost across theme swap")
window:SetAccent(nil)
window:SetScale(1.15)
assert(math.abs(window:GetScale() - 1.15) < 0.001, "SetScale failed")
window:SetScale(1)
section:SetCollapsed(true); section:SetCollapsed(false); section:ToggleCollapsed(); section:SetCollapsed(false)
for index = 1, 8 do window:Notify({ Title = "Toast " .. index, Duration = 0 }) end
window:ClearNotifications()
assert(#window._toasts <= 4, "toast stack cap failed")

-- Util --------------------------------------------------------
assert(UI.Util.FormatNumber(12480) == "12.5K", "FormatNumber: " .. tostring(UI.Util.FormatNumber(12480)))
assert(UI.Util.ToHex(Color3.fromHex("#7C5CFF")) == "7C5CFF", "ToHex failed")
assert(type(UI.Util.Viewport().X) == "number", "Viewport failed")
assert(type(UI.Util.IsTouch()) == "boolean", "IsTouch failed")
for _, iconName in ipairs(UI.Icons.List) do
	assert(UI.Icons.Get(iconName, window.Instance, { Size = 16 }), "icon failed: " .. iconName)
end
assert(UI.GetThemes()[1] ~= nil and UI.GetTheme("Missing") ~= nil, "theme helpers failed")

task.__flush()
print("SMOKE OK — " .. #UI.Icons.List .. " icons, " .. #window.Tabs .. " tabs, all setters round-tripped")
