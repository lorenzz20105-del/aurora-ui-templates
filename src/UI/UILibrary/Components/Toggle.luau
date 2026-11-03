--[[
	Aurora UI  •  Toggle.luau
	------------------------------------------------------------------
	Pill switch with a gradient fill, spring-animated knob and an
	optional description line. The entire row is clickable.
--]]

local Util = require(script.Parent.Parent.Util)
local Row = require(script.Parent.Row)

local Toggle = {}

local TRACK_W, TRACK_H, KNOB = 46, 26, 20
local PAD = (TRACK_H - KNOB) / 2

function Toggle.New(window, parent: Instance, config: { [string]: any })
	config = config or {}

	local row = Row.Create(parent, {
		Name = config.Name,
		Description = config.Description,
		Height = config.Height,
	})

	-- Track -----------------------------------------------------------
	local track = Util.New("Frame", {
		Name = "Track",
		BackgroundColor3 = Util.Theme.SurfaceActive,
		Size = UDim2.fromOffset(TRACK_W, TRACK_H),
		BorderSizePixel = 0,
		Parent = row.Right,
	})
	Util.Corner(999, track)
	Util.Stroke(Util.Theme.Stroke, 1, 0, track)

	local fill = Util.Gradient(
		ColorSequence.new(Util.Theme.Accent, Util.Theme.Accent2),
		0,
		track
	)
	fill.Enabled = false

	Util.Themable(track, "BackgroundColor3", function(palette)
		return track:GetAttribute("On") and palette.Accent or palette.SurfaceActive
	end)
	Util.Themable(fill, "Color", function(palette)
		return ColorSequence.new(palette.Accent, palette.Accent2)
	end)

	local stroke = track:FindFirstChildOfClass("UIStroke")
	if stroke then
		Util.Themable(stroke, "Color", function(palette)
			return track:GetAttribute("On") and palette.Accent or palette.Stroke
		end)
		Util.Themable(stroke, "Transparency", function(palette)
			return track:GetAttribute("On") and 1 or 0
		end)
	end

	-- Knob ------------------------------------------------------------
	local knob = Util.New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, PAD, 0.5, 0),
		Size = UDim2.fromOffset(KNOB, KNOB),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = track.ZIndex + 1,
		Parent = track,
	})
	Util.Corner(999, knob)

	local knobHold = Util.New("Frame", {
		Name = "KnobGrip",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Util.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = knob,
	})
	Util.Corner(999, knobHold)

	-- State -----------------------------------------------------------
	local state = config.Default == true
	local enabled = config.Disabled ~= true
	local object = { Instance = row.Frame, Kind = "Toggle" }
	object.Value = state

	local function render(animated: boolean)
		track:SetAttribute("On", state)
		fill.Enabled = state
		knobHold.BackgroundColor3 = state and Util.Theme.AccentText or Util.Theme.TextDim
		local target = UDim2.new(0, state and (TRACK_W - KNOB - PAD) or PAD, 0.5, 0)

		if animated then
			Util.Tween(knob, { Position = target }, "Spring")
			Util.Tween(track, { BackgroundColor3 = state and Util.Theme.Accent or Util.Theme.SurfaceActive }, "Fast")
		else
			knob.Position = target
			track.BackgroundColor3 = state and Util.Theme.Accent or Util.Theme.SurfaceActive
		end
	end

	local function set(value: boolean, silent: boolean?)
		if not enabled then
			return
		end
		state = value and true or false
		object.Value = state
		render(true)
		if not silent then
			Util.SafeCall(config.Callback, state)
			if window then
				window:_flash(row.Frame)
			end
		end
	end

	render(false)

	Util.OnClick(row.Frame, function()
		set(not state)
	end)

	track.MouseEnter:Connect(function()
		Util.Tween(knob, { BackgroundTransparency = 0 }, "Fast")
	end)

	if config.Tooltip then
		row.Frame:SetAttribute("Tooltip", config.Tooltip)
	end

	function object.Get(self): boolean
		return state
	end

	function object.Set(self, value: boolean, silent: boolean?)
		set(value, silent)
	end

	function object.Toggle(self)
		set(not state)
	end

	function object.SetEnabled(self, value: boolean)
		enabled = value
		Util.Tween(row.Frame, { BackgroundTransparency = value and 1 or 0.72 }, "Fast")
	end

	function object.Destroy(self)
		row.Frame:Destroy()
	end

	return object
end

return Toggle
