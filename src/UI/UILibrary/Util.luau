--[[
	Aurora UI  •  Util.luau
	------------------------------------------------------------------
	Low-level helpers shared by every component:
	  • instance construction + styling (corner, stroke, gradient, shadow)
	  • motion presets and a tiny tween wrapper
	  • pointer helpers (hover, ripple, drag)
	  • a live theme registry so palette swaps re-paint everything
	  • formatting utilities (numbers, colors, key names)
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Util = {}

Util.Version = "4.1.0"
Util.Theme = {} -- populated through Util.ApplyTheme / Util.SetPalette
Util.Style = {} -- active style metrics (radius, borders, rail geometry …)

--- Read a style metric, with a fallback for the stock Midnight look.
function Util.M(key: string, fallback: any)
	local style = Util.Style
	if style and style[key] ~= nil then
		return style[key]
	end
	return fallback
end

--- Adopt a style's metrics. Called by Window when CreateWindow gets a Style.
function Util.ApplyStyle(metrics: { [string]: any }?)
	Util.Style = metrics or {}
end

--- Resolve a design-grid radius against the active style. Styles can scale
--- every corner in the kit at once and clamp it (0 = perfectly square).
function Util.ShapeRadius(radius: any): number
	local style = Util.Style or {}
	local value = tonumber(radius) or 8
	local maxRadius = style.MaxRadius

	if value >= 900 then
		-- pill shapes stay pills unless a style is deliberately square
		if maxRadius and maxRadius < 100 then
			return maxRadius
		end
		return 999
	end

	value = value * (style.RadiusScale or 1)
	if maxRadius then
		value = math.min(value, maxRadius)
	end
	return math.max(0, math.floor(value + 0.5))
end
Util._themables = {}
Util._tweenPresets = {
	Instant = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Fast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Spring = TweenInfo.new(0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Linear = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
}

------------------------------------------------------------------
-- ENVIRONMENT
------------------------------------------------------------------

--- Current viewport size, safe on every device (incl. mobile clients
--- where ViewportSize can briefly be zero on the first frame).
function Util.Viewport(): Vector2
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	if size.X < 1 or size.Y < 1 then
		size = Vector2.new(1280, 720)
	end
	return size
end

--- True on phones / tablets (no mouse, touch input available).
function Util.IsTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

--- True when a physical keyboard is present (keybinds are usable).
function Util.HasKeyboard(): boolean
	return UserInputService.KeyboardEnabled
end

------------------------------------------------------------------
-- INSTANCE CONSTRUCTION
------------------------------------------------------------------

--- Create an instance and apply a property table.
-- @param className Roblox class name
-- @param props     dictionary of properties
-- @param children  optional Instance or array of Instances
function Util.New(className: string, props: { [string]: any }?, children: any?): Instance
	local instance = Instance.new(className)

	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				(instance :: any)[key] = value
			end
		end
	end

	if children then
		if typeof(children) == "Instance" then
			children.Parent = instance
		elseif type(children) == "table" then
			for _, child in ipairs(children) do
				if child then
					child.Parent = instance
				end
			end
		end
	end

	if props and props.Parent then
		instance.Parent = props.Parent
	end

	return instance
end

--- Convenience: TextLabel with sensible defaults.
function Util.Text(props: { [string]: any }?, parent: Instance?): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(235, 238, 249),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = false,
	}
	for key, value in pairs(props or {}) do
		defaults[key] = value
	end
	if parent then
		defaults.Parent = parent
	end
	return Util.New("TextLabel", defaults) :: TextLabel
end

--- Rounded corners helper.
function Util.Corner(radius: number, parent: Instance?): UICorner
	return Util.New("UICorner", {
		CornerRadius = UDim.new(0, Util.ShapeRadius(radius or 8)),
		Parent = parent,
	}) :: UICorner
end

--- Border helper. Returns the UIStroke for later mutation.
function Util.Stroke(color: Color3, thickness: number?, transparency: number?, parent: Instance?): UIStroke
	local style = Util.Style or {}
	-- styles scale border weight and opacity; a fully transparent stroke
	-- (used for hover states) must stay invisible
	local bottom = transparency or 0
	local scaled = math.clamp(bottom * (style.BorderAlphaScale or 1), 0, 1)
	if bottom >= 0.99 then
		scaled = 1
	end
	return Util.New("UIStroke", {
		Color = color or Color3.new(1, 1, 1),
		Thickness = (thickness or 1) * (style.BorderScale or 1),
		Transparency = scaled,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	}) :: UIStroke
end

--- UIGradient helper.
function Util.Gradient(sequence: ColorSequence, rotation: number?, parent: Instance?): UIGradient
	return Util.New("UIGradient", {
		Color = sequence,
		Rotation = rotation or 0,
		Parent = parent,
	}) :: UIGradient
end

--- Padding helper. Accepts a number (uniform) or a table of sides.
function Util.Padding(value: any, parent: Instance?): UIPadding
	local pad = { Top = 0, Right = 0, Bottom = 0, Left = 0 }

	if type(value) == "number" then
		pad.Top, pad.Right, pad.Bottom, pad.Left = value, value, value, value
	elseif type(value) == "table" then
		pad.Top = value.Top or value.Y or 0
		pad.Bottom = value.Bottom or value.Y or 0
		pad.Left = value.Left or value.X or 0
		pad.Right = value.Right or value.X or 0
	end

	return Util.New("UIPadding", {
		PaddingTop = UDim.new(0, pad.Top),
		PaddingRight = UDim.new(0, pad.Right),
		PaddingBottom = UDim.new(0, pad.Bottom),
		PaddingLeft = UDim.new(0, pad.Left),
		Parent = parent,
	}) :: UIPadding
end

--- UIListLayout helper.
function Util.List(props: { [string]: any }?, parent: Instance?): UIListLayout
	local defaults = {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}
	for key, value in pairs(props or {}) do
		defaults[key] = value
	end
	-- parent may be given positionally or as props.Parent; both must work
	defaults.Parent = parent or defaults.Parent
	return Util.New("UIListLayout", defaults) :: UIListLayout
end

--- UIPadding-free margin helper using UIListLayout on a wrapper.
function Util.Gap(px: number)
	return UDim.new(0, px)
end

--- Soft drop shadow built from stacked translucent rounded frames.
-- The shadow is parented next to `target` (one ZIndex below) so the
-- default Sibling ZIndexBehaviour keeps it behind the panel.
function Util.Shadow(target: GuiObject, opts: { [string]: any }?): Frame
	opts = opts or {}
	local color = opts.Color or Color3.new(0, 0, 0)
	local strength = (opts.Strength or 1) * (Util.Style.Shadow or 1)
	local layers = opts.Layers or 5
	local spread = opts.Spread or 22
	local radius = opts.Radius or 22
	local offsetY = opts.OffsetY or 6

	-- An auto-sized target has no measurable size at build time, so a
	-- sibling shadow collapses into a 0-height sliver. Callers that need an
	-- edge on an auto-sized card get a stroke instead (see Section).
	local autoSized = target.AutomaticSize ~= nil and target.AutomaticSize ~= Enum.AutomaticSize.None

	local holder = Util.New("Frame", {
		Name = "AuroraShadow",
		BackgroundTransparency = 1,
		AnchorPoint = target.AnchorPoint,
		Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset, target.Position.Y.Scale, target.Position.Y.Offset + offsetY),
		Size = UDim2.new(target.Size.X.Scale, target.Size.X.Offset, target.Size.Y.Scale, target.Size.Y.Offset),
		ZIndex = math.max(0, (target.ZIndex or 1) - 1),
		Parent = target.Parent,
	})

	for index = 1, (autoSized and 0 or layers) do
		local t = index / layers
		local grow = spread * t
		local alpha = (1 - t) * 0.13 * strength + 0.012
		local layer = Util.New("Frame", {
			Name = "Layer" .. index,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, grow * 2, 1, grow * 2),
			BackgroundColor3 = color,
			BackgroundTransparency = 1 - alpha,
			BorderSizePixel = 0,
			Parent = holder,
		})
		Util.Corner(radius + grow, layer)
	end

	return holder
end

--- Adds a UIScale and returns it (used for press / pop animations).
function Util.Scale(parent: Instance): UIScale
	return Util.New("UIScale", { Scale = 1, Parent = parent }) :: UIScale
end

--- Rounded background with optional stroke + corner in one call.
function Util.Surface(parent: Instance, opts: { [string]: any }): Frame
	opts = opts or {}
	local frame = Util.New("Frame", {
		Name = opts.Name or "Surface",
		BackgroundColor3 = opts.Color or Color3.fromRGB(22, 26, 38),
		BackgroundTransparency = opts.Transparency or 0,
		BorderSizePixel = 0,
		Size = opts.Size or UDim2.fromScale(1, 1),
		Position = opts.Position,
		AnchorPoint = opts.AnchorPoint,
		ZIndex = opts.ZIndex or 1,
		ClipsDescendants = opts.ClipsDescendants or false,
		Parent = parent,
	})
	Util.Corner(opts.Radius or 12, frame)
	if opts.Stroke then
		Util.Stroke(opts.Stroke, opts.StrokeThickness or 1, opts.StrokeTransparency or 0, frame)
	end
	return frame
end

------------------------------------------------------------------
-- MOTION
------------------------------------------------------------------

--- Tween wrapper. `preset` may be a named preset or a number.
function Util.Tween(instance: Instance, props: { [string]: any }, preset: any?, delayTime: number?): Tween
	local info
	if type(preset) == "number" then
		info = TweenInfo.new(preset, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	else
		info = Util._tweenPresets[preset or "Smooth"] or Util._tweenPresets.Smooth
	end

	local tween = TweenService:Create(instance, info, props)
	if delayTime then
		task.delay(delayTime, function()
			if instance and instance.Parent then
				tween:Play()
			end
		end)
	else
		tween:Play()
	end
	return tween
end

--- Scale-pop animation used by buttons on press.
function Util.Pop(uiScale: UIScale, pressed: boolean)
	if not uiScale or not uiScale.Parent then
		return
	end
	Util.Tween(uiScale, { Scale = pressed and 0.95 or 1 }, pressed and "Instant" or "Spring")
end

--- Fade a frame + all descendants in or out.
function Util.Fade(root: Instance, target: number, preset: string?, ignore: { Instance }?)
	local skip = {}
	if ignore then
		for _, instance in ipairs(ignore) do
			skip[instance] = true
		end
	end

	local function walk(instance: Instance)
		if skip[instance] then
			return
		end
		if instance:IsA("GuiObject") then
			Util.Tween(instance, { BackgroundTransparency = target }, preset)
		elseif instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			Util.Tween(instance, { TextTransparency = target }, preset)
		elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			Util.Tween(instance, { ImageTransparency = target }, preset)
		elseif instance:IsA("UIStroke") then
			Util.Tween(instance, { Transparency = target }, preset)
		end
		for _, child in ipairs(instance:GetChildren()) do
			walk(child)
		end
	end

	walk(root)
end

------------------------------------------------------------------
-- POINTER HELPERS
------------------------------------------------------------------

--- MouseEnter / MouseLeave shorthand.
function Util.OnHover(gui: GuiObject, enter: () -> (), leave: (() -> ())?): { RBXScriptConnection }
	local connections = {
		gui.MouseEnter:Connect(enter),
		gui.MouseLeave:Connect(function()
			if leave then
				leave()
			end
		end),
	}
	return connections
end

--- Click handler that ignores non-primary inputs and swallows errors.
function Util.OnClick(gui: GuiObject, callback: (InputObject) -> ()): RBXScriptConnection
	return gui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Util.SafeCall(callback, input)
		end
	end)
end

--- Ripple burst on click. Requires the host frame to clip descendants.
function Util.Ripple(button: GuiObject, color: Color3, maxScale: number?)
	button.ClipsDescendants = true

	return button.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local position = Vector2.new(input.Position.X, input.Position.Y) - button.AbsolutePosition
		local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * (maxScale or 2.2)

		local ripple = Util.New("Frame", {
			Name = "Ripple",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(position.X, position.Y),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.62,
			BorderSizePixel = 0,
			ZIndex = (button.ZIndex or 1) + 5,
			Parent = button,
		})
		Util.Corner(999, ripple)

		Util.Tween(ripple, { Size = UDim2.fromOffset(diameter, diameter), BackgroundTransparency = 1 }, 0.42)
		task.delay(0.45, function()
			ripple:Destroy()
		end)
	end)
end

--- Generic drag behaviour.
-- @param gui     the grab handle
-- @param onMove  function(deltaX, deltaY, input)
-- @param onStart / onEnd optional lifecycle hooks
function Util.Drag(gui: GuiObject, onMove: (number, number, InputObject) -> (), onStart: (() -> ())?, onEnd: (() -> ())?)
	local dragging = false
	local dragStart = Vector2.zero
	local activeInput: InputObject? = nil

	gui.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			activeInput = input
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			if onStart then
				Util.SafeCall(onStart)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not gui.Parent then
			return
		end
		if
			input == activeInput
			or input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local position = Vector2.new(input.Position.X, input.Position.Y)
			local delta = position - dragStart
			Util.SafeCall(onMove, delta.X, delta.Y, input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if dragging then
				dragging = false
				activeInput = nil
				if onEnd then
					Util.SafeCall(onEnd)
				end
			end
		end
	end)
end

--- Glowing hover interaction with theme-aware colors.
-- opts: { Base, Hover, StrokeBase, StrokeHover, Radius, Scale }
function Util.Interact(gui: GuiObject, opts: { [string]: any }?): (boolean) -> ()
	opts = opts or {}
	local hovered = false

	local baseToken = opts.Base or "Surface"
	local hoverToken = opts.Hover or "SurfaceHover"
	local strokeBase = opts.StrokeBase
	local strokeHover = opts.StrokeHover

	local stroke: UIStroke? = nil
	if strokeBase then
		stroke = Util.Stroke(Util.Theme[strokeBase] or Color3.new(1, 1, 1), 1, 0, gui)
	end

	local function apply(animated: boolean)
		local palette = Util.Theme
		local color = hovered and (palette[hoverToken] or palette.SurfaceHover) or (palette[baseToken] or palette.Surface)
		if animated then
			Util.Tween(gui, { BackgroundColor3 = color }, "Fast")
			if stroke and strokeHover then
				Util.Tween(stroke, { Color = hovered and (palette[strokeHover] or palette.StrokeBright) or (palette[strokeBase] or palette.Stroke) }, "Fast")
			end
		else
			gui.BackgroundColor3 = color
			if stroke and strokeHover then
				stroke.Color = hovered and (palette[strokeHover] or palette.StrokeBright) or (palette[strokeBase] or palette.Stroke)
			end
		end
	end

	Util.Themable(gui, "BackgroundColor3", function(palette)
		return hovered and (palette[hoverToken] or palette.SurfaceHover) or (palette[baseToken] or palette.Surface)
	end)
	if stroke and strokeHover then
		Util.Themable(stroke, "Color", function(palette)
			return hovered and (palette[strokeHover] or palette.StrokeBright) or (palette[strokeBase] or palette.Stroke)
		end)
	end

	gui.MouseEnter:Connect(function()
		hovered = true
		apply(true)
	end)
	gui.MouseLeave:Connect(function()
		hovered = false
		apply(true)
	end)

	apply(false)
	return function(value: boolean)
		hovered = value
		apply(true)
	end
end

------------------------------------------------------------------
-- THEME REGISTRY
------------------------------------------------------------------

--- Register an instance property as theme-driven.
-- `token` is either a palette key ("Accent") or a resolver function.
function Util.Themable(instance: Instance, property: string, token: any)
	table.insert(Util._themables, { instance = instance, property = property, token = token })
	instance[property] = Util.Resolve(token)
	return instance
end

--- Resolve a token against the current palette.
function Util.Resolve(token: any)
	local palette = Util.Theme
	if type(token) == "function" then
		local ok, value = pcall(token, palette)
		if ok then
			return value
		end
		return nil
	end
	return palette[token]
end

--- Apply a palette and re-paint every registered instance.
function Util.ApplyTheme(palette: { [string]: any })
	Util.Theme = palette

	local alive = {}
	for _, entry in ipairs(Util._themables) do
		local instance = entry.instance
		if instance and instance.Parent ~= nil then
			local ok, value = pcall(function()
				return Util.Resolve(entry.token)
			end)
			if ok and value ~= nil then
				-- Guard against tweens fighting the swap.
				pcall(function()
					instance[entry.property] = value
				end)
			end
			table.insert(alive, entry)
		end
	end

	Util._themables = alive
end

--- Force-refresh the registry without changing palette (e.g. after
--- programmatically mutating Util.Theme).
function Util.Refresh()
	Util.ApplyTheme(Util.Theme)
end

------------------------------------------------------------------
-- COLOR HELPERS
------------------------------------------------------------------

function Util.FromHex(hex: string): Color3
	return Color3.fromHex(hex)
end

function Util.ToHex(color: Color3): string
	local r = math.floor(math.clamp(color.R, 0, 1) * 255 + 0.5)
	local g = math.floor(math.clamp(color.G, 0, 1) * 255 + 0.5)
	local b = math.floor(math.clamp(color.B, 0, 1) * 255 + 0.5)
	return string.format("%02X%02X%02X", r, g, b)
end

--- Mix two colors by `alpha` (0 = a, 1 = b).
function Util.Mix(a: Color3, b: Color3, alpha: number): Color3
	return a:Lerp(b, math.clamp(alpha, 0, 1))
end

--- Lighten (positive) or darken (negative) toward white/black.
function Util.Shade(color: Color3, amount: number): Color3
	if amount >= 0 then
		return color:Lerp(Color3.new(1, 1, 1), math.clamp(amount, 0, 1))
	end
	return color:Lerp(Color3.new(0, 0, 0), math.clamp(-amount, 0, 1))
end

--- Readable text color for a given background.
function Util.Contrast(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return luminance > 0.6 and Color3.fromHex("#0B0D14") or Color3.new(1, 1, 1)
end

--- Shift hue while preserving saturation/value (used by accent pickers).
function Util.Hue(color: Color3, hue: number): Color3
	local h, s, v = Color3.toHSV(color)
	return Color3.fromHSV(hue % 1, s, v)
end

function Util.HSV(h: number, s: number, v: number): Color3
	return Color3.fromHSV(math.clamp(h, 0, 1), math.clamp(s, 0, 1), math.clamp(v, 0, 1))
end

------------------------------------------------------------------
-- NUMBER + TEXT HELPERS
------------------------------------------------------------------

--- 1234 -> "1.2K", 1500000 -> "1.5M".
function Util.FormatNumber(value: number?, precision: number?): string
	value = value or 0
	local decimals = precision or 1
	local negative = value < 0
	local n = math.abs(value)
	local out

	if n >= 1e12 then
		out = string.format("%." .. decimals .. "fT", n / 1e12)
	elseif n >= 1e9 then
		out = string.format("%." .. decimals .. "fB", n / 1e9)
	elseif n >= 1e6 then
		out = string.format("%." .. decimals .. "fM", n / 1e6)
	elseif n >= 1e3 then
		out = string.format("%." .. decimals .. "fK", n / 1e3)
	else
		out = string.format("%d", n)
	end

	out = string.gsub(out, "%.0(%a)", "%1")
	return (negative and "-" .. out) or out
end

--- 1234567 -> "1,234,567".
function Util.Commas(value: number): string
	local formatted = tostring(math.floor(value))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

function Util.Round(value: number, decimals: number?): number
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

--- Trim trailing zeros: 12.0 -> "12", 12.50 -> "12.5".
function Util.TrimNumber(value: number, decimals: number?): string
	local text = string.format("%." .. (decimals or 0) .. "f", value or 0)
	-- only trim inside the fractional part: "60" must never become "6"
	if not string.find(text, "%.") then
		return text
	end
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

function Util.SafeCall(callback: any, ...)
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[Aurora UI] callback error: " .. tostring(err))
	end
end

--- Normalize an input object into a human key label, incl. modifiers.
function Util.KeyLabel(keyCode: Enum.KeyCode, modifiers: { [string]: boolean }?): string
	local name = string.gsub(keyCode.Name, "KeyCode", "")
	local parts = {}

	if modifiers then
		if modifiers.LeftControl or modifiers.RightControl then
			table.insert(parts, "Ctrl")
		end
		if modifiers.LeftShift or modifiers.RightShift then
			table.insert(parts, "Shift")
		end
		if modifiers.LeftAlt or modifiers.RightAlt then
			table.insert(parts, "Alt")
		end
	end

	table.insert(parts, string.upper(string.sub(name, 1, 3)) == "KEY" and string.sub(name, 4) or name)
	return table.concat(parts, " + ")
end

--- Short label for a user input object (mouse buttons included).
function Util.InputLabel(input: InputObject): string
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		return "Mouse Left"
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		return "Mouse Right"
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		return "Mouse Middle"
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		return "Wheel"
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		return "Gamepad"
	elseif input.KeyCode ~= Enum.KeyCode.Unknown then
		return Util.KeyLabel(input.KeyCode, {
			LeftControl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl),
			RightControl = UserInputService:IsKeyDown(Enum.KeyCode.RightControl),
			LeftShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift),
			RightShift = UserInputService:IsKeyDown(Enum.KeyCode.RightShift),
			LeftAlt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt),
			RightAlt = UserInputService:IsKeyDown(Enum.KeyCode.RightAlt),
		})
	end
	return "—"
end

--- Text width estimate, handy for auto-sizing pills.
--- Wrapped in pcall: some sandboxed/mobile clients block the async
--- TextService call, and a rough estimate is good enough as a fallback.
function Util.TextWidth(text: string, size: number): number
	local ok, width = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = Font.new("rbxasset://fonts/families/GothamSSm.json")
		params.Size = size
		return game:GetService("TextService"):GetTextBoundsAsync(params).X
	end)
	if ok and type(width) == "number" then
		return width
	end
	-- ~0.55em average glyph width for Gotham Medium.
	return #text * size * 0.55
end

--- Configure a ScrollingFrame for auto-height content.
function Util.AutoCanvas(scrolling: ScrollingFrame, padding: number?)
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrolling.ScrollBarThickness = 3
	scrolling.ScrollBarImageTransparency = 0.6
	scrolling.ScrollingDirection = Enum.ScrollingDirection.Y
	if padding then
		Util.Padding(padding, scrolling)
	end
end

--- Debounce wrapper.
function Util.Debounce(delay: number, callback: (...any) -> ())
	local token = 0
	return function(...)
		token += 1
		local current = token
		local args = table.pack(...)
		task.delay(delay, function()
			if current == token then
				Util.SafeCall(callback, table.unpack(args, 1, args.n))
			end
		end)
	end
end

--- Heartbeat-independent lerp loop; returns a cancel function.
function Util.Animate(seconds: number, onStep: (alpha: number) -> ()): () -> ()
	local elapsed = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / seconds, 0, 1)
		Util.SafeCall(onStep, alpha)
		if alpha >= 1 then
			connection:Disconnect()
		end
	end)
	return function(self)
		if connection then
			connection:Disconnect()
		end
	end
end

return Util
