--[[
	Minimal Roblox API mock — TEST ONLY.
	Enough surface to construct the entire Aurora UI tree headlessly so
	typos, nil indexes and bad property names surface as real errors.
	Not shipped; not a runtime dependency.
--]]

--====================== roblox globals ======================
local function makeSignal(name)
	local signal = { _name = name, _cbs = {} }
	function signal:Connect(fn)
		table.insert(self._cbs, fn)
		return {
			Disconnect = function() end,
			Connected = true,
		}
	end
	signal.Once = signal.Connect
	function signal:Wait() end
	function signal:Fire(...)
		for _, fn in ipairs(self._cbs) do
			local ok, err = pcall(fn, ...)
			if not ok then
				error("[signal:" .. tostring(self._name) .. "] " .. tostring(err), 0)
			end
		end
	end
	return signal
end

--====================== datatypes ===========================
local function class(name)
	local t = {}
	t.__typename = name
	return t
end

UDim = class("UDim")
function UDim.new(scale, offset)
	return { Scale = scale or 0, Offset = offset or 0 }
end

UDim2 = class("UDim2")
function UDim2.new(xs, xo, ys, yo)
	return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end

Vector2 = class("Vector2")
local function v2(x, y)
	local vec = { X = x or 0, Y = y or 0 }
	setmetatable(vec, {
		__sub = function(a, b)
			return v2(a.X - b.X, a.Y - b.Y)
		end,
		__add = function(a, b)
			return v2(a.X + b.X, a.Y + b.Y)
		end,
		__mul = function(a, b)
			if type(b) == "number" then
				return v2(a.X * b, a.Y * b)
			end
			return v2(a.X * b.X, a.Y * b.Y)
		end,
		__tostring = function(a)
			return string.format("%.1f, %.1f", a.X, a.Y)
		end,
	})
	return vec
end
Vector2.new = v2
Vector2.zero = v2(0, 0)
Vector2.one = v2(1, 1)

Color3 = class("Color3")
-- Color3 values compare by component (Luau's real Color3 does), so
-- code such as `piece.BackgroundColor3 == Color3.new(0, 0, 0)` works.
local Color3_mt = {
	__tostring = function(self)
		return string.format("%.3f, %.3f, %.3f", self.R or 0, self.G or 0, self.B or 0)
	end,
	__eq = function(a, b)
		return (a.R or 0) == (b.R or 0) and (a.G or 0) == (b.G or 0) and (a.B or 0) == (b.B or 0)
	end,
}
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3_mt)
end
function Color3.fromRGB(r, g, b)
	return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end
function Color3.fromHex(hex)
	local h = string.gsub(hex or "000000", "#", "")
	if #h < 6 then
		h = "000000"
	end
	return Color3.fromRGB(tonumber(string.sub(h, 1, 2), 16) or 0, tonumber(string.sub(h, 3, 4), 16) or 0, tonumber(string.sub(h, 5, 6), 16) or 0)
end
function Color3.fromHSV(h, s, v)
	local i = math.floor((h or 0) * 6)
	local f = (h or 0) * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return Color3.new(v, t, p) end
	if i == 1 then return Color3.new(q, v, p) end
	if i == 2 then return Color3.new(p, v, t) end
	if i == 3 then return Color3.new(p, q, v) end
	if i == 4 then return Color3.new(t, p, v) end
	return Color3.new(v, p, q)
end
function Color3.toHSV(color)
	local r, g, b = color.R or 0, color.G or 0, color.B or 0
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local d = max - min
	local h = 0
	if d > 0 then
		if max == r then
			h = ((g - b) / d) % 6
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
	end
	return h, (max > 0 and d / max or 0), max
end
function Color3.fromHSV(h, s, v)
	local i = math.floor((h or 0) * 6) % 6
	local f = (h or 0) * 6 - math.floor((h or 0) * 6)
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	if i == 0 then return Color3.new(v, t, p) end
	if i == 1 then return Color3.new(q, v, p) end
	if i == 2 then return Color3.new(p, v, t) end
	if i == 3 then return Color3.new(p, q, v) end
	if i == 4 then return Color3.new(t, p, v) end
	return Color3.new(v, p, q)
end

local function withLerp(color)
	color.Lerp = function(self, other, alpha)
		return Color3.new(
			self.R + (other.R - self.R) * alpha,
			self.G + (other.G - self.G) * alpha,
			self.B + (other.B - self.B) * alpha
		)
	end
	return color
end
local rawColorNew = Color3.new
Color3.new = function(r, g, b)
	return withLerp(rawColorNew(r, g, b))
end
local rawFromRGB = Color3.fromRGB
Color3.fromRGB = function(r, g, b)
	return withLerp(rawFromRGB(r, g, b))
end

ColorSequenceKeypoint = { new = function(time, value) return { Time = time, Value = value } end }
ColorSequence = { new = function(a, b)
	if type(a) == "table" and a[1] then
		return { Keypoints = a }
	end
	return { Keypoints = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b) } }
end }

NumberSequenceKeypoint = { new = function(time, value) return { Time = time, Value = value } end }
NumberSequence = { new = function(a, b)
	if type(a) == "table" and a[1] then
		return { Keypoints = a }
	end
	return { Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) } }
end }

TweenInfo = { new = function(...) return { Args = { ... } } end }
Font = { new = function(...) return { Args = { ... } } end }
Rect = { new = function() return {} end }
CFrame = { new = function() return {} end }

--====================== Enum ================================
local enumCache = {}
local function enumCategory(name)
	local category = {}
	setmetatable(category, {
		__index = function(self, key)
			local item = { Name = key, Value = 0, EnumType = name }
			rawset(self, key, item)
			return item
		end,
	})
	return category
end
Enum = setmetatable({}, {
	__index = function(self, key)
		local existing = enumCache[key]
		if existing then
			return existing
		end
		local category = enumCategory(key)
		enumCache[key] = category
		return category
	end,
})

--====================== Instances ===========================
local EVENT_NAMES = {
	MouseEnter = true, MouseLeave = true, InputBegan = true, InputEnded = true,
	InputChanged = true, MouseMoved = true, MouseWheelForward = true,
	MouseWheelBackward = true, Focused = true, FocusLost = true,
	ReturnPressed = true, Activated = true, Changed = true, Destroying = true,
	TouchTap = true, TouchLongPress = true, SelectionChanged = true,
}

local CLASS_DEFAULTS = {
	Frame = {
		BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(100, 40), Position = UDim2.fromOffset(0, 0),
		BorderSizePixel = 1, Visible = true, ZIndex = 1, ClipsDescendants = false,
		LayoutOrder = 0, Rotation = 0, BackgroundColor = Color3.new(1, 1, 1),
		AutomaticSize = Enum.AutomaticSize.None,
		AbsoluteSize = Vector2.new(180, 40), AbsolutePosition = Vector2.new(120, 240),
	},
	TextLabel = {
		BackgroundTransparency = 1, Text = "", TextSize = 14, TextTransparency = 0,
		TextColor3 = Color3.new(1, 1, 1), TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None, RichText = false,
		Size = UDim2.fromOffset(100, 20), Position = UDim2.fromOffset(0, 0),
		Visible = true, ZIndex = 1, LayoutOrder = 0, Font = Enum.Font.Gotham,
		AutomaticSize = Enum.AutomaticSize.None,
		AbsoluteSize = Vector2.new(100, 20), AbsolutePosition = Vector2.new(120, 240),
		BackgroundColor3 = Color3.new(1, 1, 1),
	},
	TextButton = {
		BackgroundTransparency = 1, Text = "", TextSize = 14, TextTransparency = 0,
		TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true, Visible = true,
		ZIndex = 1, Size = UDim2.fromOffset(100, 40), Position = UDim2.fromOffset(0, 0),
		AbsoluteSize = Vector2.new(180, 40), AbsolutePosition = Vector2.new(120, 240),
		BackgroundColor3 = Color3.new(1, 1, 1),
	},
	TextBox = {
		BackgroundTransparency = 1, Text = "", PlaceholderText = "", TextSize = 14,
		ClearTextOnFocus = false, TextEditable = true, TextTransparency = 0,
		TextColor3 = Color3.new(1, 1, 1), PlaceholderColor3 = Color3.new(0.5, 0.5, 0.5),
		MultiLine = false, Visible = true, ZIndex = 1,
		Size = UDim2.fromOffset(100, 30), Position = UDim2.fromOffset(0, 0),
		AbsoluteSize = Vector2.new(120, 30), AbsolutePosition = Vector2.new(120, 240),
		BackgroundColor3 = Color3.new(1, 1, 1),
	},
	ImageLabel = {
		BackgroundTransparency = 1, Image = "", ImageColor3 = Color3.new(1, 1, 1),
		ImageTransparency = 0, Visible = true, ZIndex = 1,
		Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(0, 0),
		AbsoluteSize = Vector2.new(40, 40), AbsolutePosition = Vector2.new(120, 240),
		BackgroundColor3 = Color3.new(1, 1, 1),
	},
	ScrollingFrame = {
		BackgroundTransparency = 1, CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.None, ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0, ScrollBarImageColor3 = Color3.new(1, 1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasPosition = Vector2.zero,
		Visible = true, ZIndex = 1, Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0), AbsoluteSize = Vector2.new(600, 400),
		AbsolutePosition = Vector2.new(80, 120), BackgroundColor3 = Color3.new(1, 1, 1),
	},
	UIStroke = { Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
	UICorner = { CornerRadius = UDim.new(0, 8) },
	UIPadding = { PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0) },
	UIListLayout = { Padding = UDim.new(0, 0), FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top, HorizontalAlignment = Enum.HorizontalAlignment.Left },
	UIGridLayout = { CellSize = UDim2.fromOffset(100, 100), CellPadding = UDim2.fromOffset(0, 0), FillDirectionMaxCells = 0, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, StartCorner = Enum.StartCorner.TopLeft },
	UIScale = { Scale = 1 },
	UIGradient = { Enabled = true, Rotation = 0, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0, 0), Offset = Vector2.zero },
	ScreenGui = { ResetOnSpawn = true, IgnoreGuiInset = false, DisplayOrder = 0, Enabled = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling },
	BlurEffect = { Size = 0, Enabled = true },
	ObjectValue = { Value = nil },
}

local METHOD_NAMES = {
	FindFirstChild = true, FindFirstChildOfClass = true, FindFirstChildWhichIsA = true,
	FindFirstAncestorOfClass = true, GetChildren = true, GetDescendants = true,
	IsA = true, Destroy = true, Clone = true, SetAttribute = true, GetAttribute = true,
	GetAttributes = true, WaitForChild = true, GetPropertyChangedSignal = true,
	GetAttributeChangedSignal = true, CaptureFocus = true, ReleaseFocus = true,
	ClearAllChildren = true, GetFullName = true, GetDebugId = true,
}

local Instance_ = {}
Instance_.__index = function(self, key)
	local value = self._props[key]
	if value ~= nil then
		return value
	end

	local defaults = CLASS_DEFAULTS[self.ClassName]
	if defaults and defaults[key] ~= nil then
		return defaults[key]
	end

	if key == "Parent" or key == "Name" or key == "ClassName" then
		return nil
	end

	if EVENT_NAMES[key] then
		local signal = makeSignal(self.ClassName .. "." .. key)
		self._props[key] = signal
		return signal
	end

	local method = Instance_[key]
	if method then
		return method
	end

	return nil
end

Instance_.__newindex = function(self, key, value)
	if key == "Parent" then
		local old = self._props.Parent
		if old and old._children then
			for index, child in ipairs(old._children) do
				if child == self then
					table.remove(old._children, index)
					break
				end
			end
		end
		self._props.Parent = value
		if value and value._children then
			table.insert(value._children, self)
		end
		return
	end
	self._props[key] = value
end

function Instance_.IsA(self, className)
	return self.ClassName == className
end

function Instance_.FindFirstChild(self, name, recursive)
	for _, child in ipairs(self._children) do
		if child._props.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in ipairs(self._children) do
			local found = Instance_.FindFirstChild(child, name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function Instance_.FindFirstChildOfClass(self, className)
	for _, child in ipairs(self._children) do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

Instance_.FindFirstChildWhichIsA = Instance_.FindFirstChildOfClass

function Instance_.GetChildren(self)
	local list = {}
	for index, child in ipairs(self._children) do
		list[index] = child
	end
	return list
end

function Instance_.GetDescendants(self)
	local list = {}
	local function walk(node)
		for _, child in ipairs(node._children) do
			table.insert(list, child)
			walk(child)
		end
	end
	walk(self)
	return list
end

function Instance_.WaitForChild(self, name)
	local found = Instance_.FindFirstChild(self, name)
	if found then
		return found
	end
	local child = Instance.new("Folder")
	child.Name = name
	child.Parent = self
	return child
end

function Instance_.Destroy(self)
	self.Parent = nil
	self._destroyed = true
end

function Instance_.SetAttribute(self, key, value)
	self._props["__attr_" .. key] = value
end

function Instance_.GetAttribute(self, key)
	return self._props["__attr_" .. key]
end

function Instance_.GetAttributes(self)
	local out = {}
	for key, value in pairs(self._props) do
		local attr = string.match(key, "^__attr_(.+)$")
		if attr then
			out[attr] = value
		end
	end
	return out
end

function Instance_.GetPropertyChangedSignal(self, property)
	return makeSignal("changed:" .. tostring(property))
end

Instance_.GetAttributeChangedSignal = Instance_.GetPropertyChangedSignal
function Instance_.CaptureFocus(self) end
function Instance_.ReleaseFocus(self) end
function Instance_.ClearAllChildren(self) end
function Instance_.GetFullName(self) return self._props.Name or "Instance" end
function Instance_.GetDebugId(self) return "mock" end

Instance = {}
function Instance.new(className, parent)
	local object = setmetatable({
		ClassName = className,
		_children = {},
		_props = { Name = className },
	}, Instance_)
	object._isInstance = true
	if parent then
		object.Parent = parent
	end
	return object
end

function typeof(value)
	if type(value) == "table" and value._isInstance then
		return "Instance"
	end
	return type(value)
end

function warn(...)
	local parts = {}
	for _, value in ipairs({ ... }) do
		table.insert(parts, tostring(value))
	end
	print("[warn] " .. table.concat(parts, " "))
end

--====================== task ================================
local queue = {}
task = {
	wait = function() end,
	spawn = function(fn, ...) table.insert(queue, { fn, { ... } }) end,
	defer = function(fn, ...) table.insert(queue, { fn, { ... } }) end,
	delay = function(_, fn, ...) table.insert(queue, { fn, { ... } }) end,
	cancel = function() end,
	__flush = function()
		local guard = 0
		while #queue > 0 and guard < 200 do
			guard += 1
			local item = table.remove(queue, 1)
			local ok, err = pcall(item[1], table.unpack(item[2]))
			if not ok then
				error("[queued task] " .. tostring(err), 0)
			end
		end
	end,
}

--====================== services ============================
local playerGui = Instance.new("ScreenGui")
playerGui.Name = "PlayerGui"

local localPlayer = {
	UserId = 1,
	Name = "Tester",
	ClassName = "Player",
	WaitForChild = function(self, name)
		if name == "PlayerGui" then
			return playerGui
		end
		return Instance.new("Folder")
	end,
	FindFirstChildOfClass = function()
		return playerGui
	end,
}

local services = {}

local function buildService(name)
	local service = { ClassName = name }

	if name == "Players" then
		service.LocalPlayer = localPlayer
		service.GetUserThumbnailAsync = function()
			error("thumbnail blocked in mock")
		end
		service.PlayerAdded = makeSignal("PlayerAdded")
	elseif name == "UserInputService" then
		service.InputBegan = makeSignal("InputBegan")
		service.InputChanged = makeSignal("InputChanged")
		service.InputEnded = makeSignal("InputEnded")
		service.TouchEnabled = false
		service.MouseEnabled = true
		service.KeyboardEnabled = true
		service.GamepadEnabled = false
		service.WindowFocused = makeSignal("WindowFocused")
		service.WindowFocusReleased = makeSignal("WindowFocusReleased")
		service.IsKeyDown = function() return false end
		service.GetKeysPressed = function() return {} end
		service.GetMouseLocation = function() return Vector2.new(640, 360) end
	elseif name == "RunService" then
		service.RenderStepped = makeSignal("RenderStepped")
		service.Heartbeat = makeSignal("Heartbeat")
		service.Stepped = makeSignal("Stepped")
		service.IsStudio = function() return true end
	elseif name == "TweenService" then
		service.Create = function(_, instance, info, props)
			return {
				Play = function() end,
				Cancel = function() end,
				Pause = function() end,
				Completed = makeSignal("Completed"),
			}
		end
	elseif name == "TextService" then
		service.GetTextBoundsAsync = function()
			error("text bounds blocked in mock")
		end
	elseif name == "Lighting" then
		service.ClassName = "Lighting"
	elseif name == "CoreGui" then
		service.ClassName = "CoreGui"
	end

	return service
end

game = {
	GetService = function(_, name)
		local existing = services[name]
		if existing then
			return existing
		end
		local service = buildService(name)
		services[name] = service
		return service
	end,
	FindService = function(_, name)
		return services[name]
	end,
	PlaceId = 0,
	JobId = "mock",
}

workspace = {
	CurrentCamera = {
		ViewportSize = Vector2.new(1280, 720),
		FieldOfView = 70,
		GetPropertyChangedSignal = function()
			return makeSignal("viewport")
		end,
	},
}

script = Instance.new("ModuleScript")
script.Name = "MockScript"
