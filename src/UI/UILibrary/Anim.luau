--[[
	Aurora UI  •  Anim.luau
	==================================================================
	Motion profiles. Every style carries one, so "Arcade" bounces and
	"Executive" barely moves — without a single component knowing which
	style is active.

		A style's Motion table:
			Entry    rise | pop | fade | glitch | type | snap | bounce
			Hover    glow | lift | press | none
			Idle     shimmer | pulse | blink | scan | none
			Duration seconds for one entrance step
			Stagger  seconds between siblings
			Easing   Linear | Sine | Quad | Quint | Back | Bounce | Elastic

	Everything here is engine-safe: no asset ids, no TextService, no
	keyboard, and every tween is 0.1–0.4 s so it stays smooth on a phone.

		Anim.Entrance(container, motion)     stagger the children in
		Anim.Entry(instance, motion, index)  animate one instance
		Anim.Hover(instance, motion)         attach hover feedback
		Anim.Idle(instance, motion)          attach the idle loop
--]]

local TweenService = game:GetService("TweenService")

local Anim = {}
Anim.Version = "4.2.3"

------------------------------------------------------------------
-- easing lookup
------------------------------------------------------------------

local EASING = {
	Linear = Enum.EasingStyle.Linear,
	Sine = Enum.EasingStyle.Sine,
	Quad = Enum.EasingStyle.Quad,
	Quint = Enum.EasingStyle.Quint,
	Back = Enum.EasingStyle.Back,
	Bounce = Enum.EasingStyle.Bounce,
	Elastic = Enum.EasingStyle.Elastic,
}

local function easing(name: any): Enum.EasingStyle
	if typeof(name) == "EnumItem" then
		return name
	end
	return EASING[name] or Enum.EasingStyle.Quint
end

------------------------------------------------------------------
-- entry profiles
------------------------------------------------------------------

-- `From`  : starting UIScale
-- `Spin`  : starting rotation, degrees
-- `Fade`  : also slide background/TextTransparency up and back
-- `Snap`  : duration multiplier (1 = use the style's duration)
local ENTRY = {
	rise = { From = 0.955, Lift = 10 },
	pop = { From = 0.86 },
	fade = { From = 1, Fade = true, Snap = 1.4 },
	glitch = { From = 0.98, Spin = 1.8 },
	type = { From = 1, Fade = true, Snap = 0.6 },
	snap = { From = 0.9, Snap = 0.35 },
	bounce = { From = 0.66, Snap = 1.2 },
}

--- The UIScale every animated instance carries. Named so callers (and the
--- dumper) can tell it apart from a layout scale.
local function scaleOf(instance: GuiObject): UIScale
	local existing = instance:FindFirstChild("MotionScale")
	if existing and existing:IsA("UIScale") then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = "MotionScale"
	scale.Scale = 1
	scale.Parent = instance
	return scale
end

local function tween(instance, seconds, props, style, direction)
	if not instance or not instance.Parent then
		return nil
	end
	local info = TweenInfo.new(
		math.max(0.01, seconds),
		easing(style or "Quint"),
		direction or Enum.EasingDirection.Out
	)
	local created = TweenService:Create(instance, info, props)
	created:Play()
	return created
end

local function faded(instance: GuiObject): boolean
	return instance.BackgroundTransparency < 1
		or (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox"))
end

------------------------------------------------------------------
-- public: entry
------------------------------------------------------------------

--- Animate one instance in. `index` staggers it behind its siblings.
function Anim.Entry(instance: GuiObject, motion: { [string]: any }?, index: number?, delay: number?)
	if not instance or not instance.Parent then
		return
	end
	motion = motion or {}
	local profile = ENTRY[motion.Entry or "rise"] or ENTRY.rise
	local duration = (motion.Duration or 0.3) * (profile.Snap or 1)
	local step = (motion.Stagger or 0.03) * (index or 0) + (delay or 0)

	local scale = scaleOf(instance)
	scale.Scale = profile.From or 1

	local startSpin = instance.Rotation
	if profile.Spin then
		instance.Rotation = startSpin + profile.Spin
	end

	local originals = {}
	if profile.Fade and faded(instance) then
		originals.BackgroundTransparency = instance.BackgroundTransparency
		if instance.BackgroundTransparency < 1 then
			instance.BackgroundTransparency = math.min(1, instance.BackgroundTransparency + 0.85)
		end
		if instance:IsA("TextLabel") or instance:IsA("TextBox") then
			originals.TextTransparency = instance.TextTransparency
			instance.TextTransparency = math.min(1, instance.TextTransparency + 0.85)
		end
	end

	task.delay(step, function()
		if not instance.Parent then
			return
		end
		tween(scale, duration, { Scale = 1 }, motion.Easing)
		if profile.Spin then
			tween(instance, duration, { Rotation = startSpin }, "Sine")
		end
		if originals.BackgroundTransparency then
			tween(instance, duration * 1.1, { BackgroundTransparency = originals.BackgroundTransparency }, "Sine")
		end
		if originals.TextTransparency then
			tween(instance, duration * 1.1, { TextTransparency = originals.TextTransparency }, "Sine")
		end
	end)
end

--- Stagger every direct GuiObject child of `container` in reading order.
function Anim.Entrance(container: Instance?, motion: { [string]: any }?, limit: number?)
	if not container then
		return
	end
	local children = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			table.insert(children, child)
		end
	end
	local count = math.min(#children, limit or 14)
	for index = 1, count do
		Anim.Entry(children[index], motion, index - 1)
	end
end

------------------------------------------------------------------
-- public: hover
------------------------------------------------------------------

--- Hover feedback driven by the style: glow, lift, press or nothing at all.
--- Safe on touch: it also fires on tap-start through MouseEnter emulation.
function Anim.Hover(instance: GuiObject, motion: { [string]: any }?)
	if not instance then
		return
	end
	motion = motion or {}
	local kind = motion.Hover or "lift"
	if kind == "none" then
		return
	end

	local scale = scaleOf(instance)
	local stroke = instance:FindFirstChildOfClass("UIStroke")
	local baseStroke = stroke and stroke.Color or nil
	local baseTransparency = stroke and stroke.Transparency or 0

	instance.MouseEnter:Connect(function()
		if kind == "lift" then
			tween(scale, 0.14, { Scale = 1.025 }, "Quad")
		elseif kind == "press" then
			tween(scale, 0.1, { Scale = 0.975 }, "Quad")
		end
		if kind == "glow" and stroke then
			tween(stroke, 0.16, { Transparency = 0 }, "Sine")
		end
	end)

	instance.MouseLeave:Connect(function()
		tween(scale, 0.18, { Scale = 1 }, "Quad")
		if kind == "glow" and stroke then
			tween(stroke, 0.24, { Transparency = baseTransparency }, "Sine")
		end
	end)

	return { Stroke = baseStroke }
end

------------------------------------------------------------------
-- public: idle
------------------------------------------------------------------

local REPEAT_FOREVER = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

--- The idle loop: what the UI does when nobody is touching it.
function Anim.Idle(instance: GuiObject, motion: { [string]: any }?)
	if not instance or not instance.Parent then
		return
	end
	motion = motion or {}
	local kind = motion.Idle or "none"
	local seconds = (motion.Duration or 0.3) * 5

	if kind == "pulse" then
		local scale = scaleOf(instance)
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local created = TweenService:Create(scale, info, { Scale = 1.035 })
		created:Play()
		return created
	elseif kind == "shimmer" then
		local gradient = instance:FindFirstChildOfClass("UIGradient")
		if not gradient then
			gradient = Instance.new("UIGradient")
			gradient.Parent = instance
		end
		gradient.Offset = Vector2.new(-1, 0)
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
		local created = TweenService:Create(gradient, info, { Offset = Vector2.new(1, 0) })
		created:Play()
		return created
	elseif kind == "blink" then
		local base = instance.BackgroundTransparency
		local info = TweenInfo.new(math.max(0.35, seconds * 0.3), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
		local created = TweenService:Create(instance, info, {
			BackgroundTransparency = math.min(1, base + 0.6),
		})
		created:Play()
		return created
	elseif kind == "scan" then
		-- a thin accent line that walks down the container
		local line = Instance.new("Frame")
		line.Name = "ScanLine"
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BackgroundTransparency = 0.88
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.fromScale(0, 0)
		line.ZIndex = 2
		line.Parent = instance
		local info = TweenInfo.new(math.max(2.4, seconds), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
		local created = TweenService:Create(line, info, { Position = UDim2.fromScale(0, 1) })
		created:Play()
		return created
	end

	return REPEAT_FOREVER
end

--- Apply the whole profile to a control: hover + idle, and return it.
function Anim.Adopt(instance: GuiObject, motion: { [string]: any }?)
	Anim.Hover(instance, motion)
	if motion and (motion.Idle or "none") ~= "none" then
		Anim.Idle(instance, motion)
	end
	return instance
end

return Anim
