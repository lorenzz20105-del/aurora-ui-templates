--[[
	Aurora UI  •  init.luau
	==================================================================
	A modern Roblox interface kit.

	Quick start
	-----------
		local UI = require(game.ReplicatedStorage.UI.UILibrary)

		local window = UI.CreateWindow({
			Title = "Aurora",
			Subtitle = "v2.0.0  •  ready",
			Keybind = Enum.KeyCode.RightShift,
		})

		local tab = window:CreateTab({ Name = "Main", Icon = "home" })
		local section = tab:CreateSection({ Name = "Gameplay", Icon = "shield" })
		section:AddToggle({ Name = "Enable feature", Default = true, Callback = print })

	Everything is themed through Theme.luau, every control is documented
	in the README, and the demo in StarterPlayerScripts shows real use.
--]]

local Theme = require(script.Theme)
local Util = require(script.Util)
local Icons = require(script.Icons)
local Styles = require(script.Styles)
local Window = require(script.Components.Window)

local UILibrary = {}

UILibrary.Version = "4.2.3"
UILibrary.Theme = Theme
UILibrary.Util = Util
UILibrary.Icons = Icons
UILibrary.Styles = Styles

--- Create the main window. Returns a window object with :CreateTab,
--- :Notify, :Modal, :SetTheme, :Open, :Close and :Toggle.
function UILibrary.CreateWindow(config: { [string]: any }?)
	return Window.New(config)
end

--- Apply a palette globally (affects every open window).
function UILibrary.SetTheme(name: string)
	Util.ApplyTheme(Theme.Get(name))
	Icons.RefreshAll(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"), Util.Theme.Surface)
	Theme.Name = name
end

--- Returns every palette name (sorted).
function UILibrary.GetThemes(): { string }
	return Theme.List()
end

--- Returns a palette table without applying it.
function UILibrary.GetTheme(name: string)
	return Theme.Get(name)
end

--- Convenience: format a number the way Aurora does ("1.2K").
function UILibrary.Format(value: number, precision: number?): string
	return Util.FormatNumber(value, precision)
end

return UILibrary
