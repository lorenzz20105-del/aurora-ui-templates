--[[
	Aurora UI  •  tools/dump-tree.luau
	==================================================================
	Serialises the window the real components built to JSON so it can be
	rendered outside Roblox (docs/real-ui.html).

	Appended after:
		robloxmock.luau             (fake Roblox API)
		tween patch                 (entrance tweens land on final values)
		dist/AuroraUI.luau          (the real library)
		src/Client/Main.client.luau (the real demo, exposes DumpWindow)
--]]

local GUI_CLASSES = {
	Frame = true,
	TextButton = true,
	TextLabel = true,
	ImageLabel = true,
	ImageButton = true,
	ScrollingFrame = true,
	TextBox = true,
	CanvasGroup = true,
}

local PLAIN_PROPS = {
	"Name", "Visible", "Position", "Size", "AnchorPoint", "Rotation",
	"BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "BorderColor3",
	"ZIndex", "ClipsDescendants", "LayoutOrder", "Text", "TextSize", "TextColor3",
	"TextTransparency", "TextWrapped", "TextScaled", "RichText", "Image",
	"ImageColor3", "ImageTransparency", "CanvasPosition", "ScrollBarThickness",
	"TextStrokeTransparency", "LineHeight", "Font", "TextXAlignment",
	"TextYAlignment", "TextTruncate", "AutomaticSize", "TextDirection",
	"PlaceholderText", "PlaceholderColor3", "TextEditable", "ClearTextOnFocus",
}

--- The headless mock only implements typeof() for Instances, so datatypes are
--- classified structurally instead.
local function kind(value: any): string?
	local valueType = type(value)
	if valueType == "string" or valueType == "number" or valueType == "boolean" then
		return valueType
	end
	if valueType ~= "table" then
		return nil
	end
	if value.EnumType then
		return "enum"
	end
	if type(value.R) == "number" and type(value.G) == "number" and type(value.B) == "number" then
		return "color"
	end
	if value.X ~= nil and value.Y ~= nil then
		if type(value.X) == "table" and value.X.Scale ~= nil then
			return "udim2"
		end
		if type(value.X) == "number" and type(value.Y) == "number" then
			return "vector2"
		end
	end
	if value.Scale ~= nil and value.Offset ~= nil then
		return "udim"
	end
	return nil
end

local function num(value: number): string
	if type(value) ~= "number" or value ~= value then
		return "0"
	end
	if value == math.floor(value) and math.abs(value) < 1e9 then
		return string.format("%d", value)
	end
	return string.format("%.3f", value)
end

local function escape(text: string): string
	local out = tostring(text):gsub('[%c"\\]', function(char)
		if char == '"' then
			return '\\"'
		elseif char == "\\" then
			return "\\\\"
		elseif char == "\n" then
			return "\\n"
		elseif char == "\t" then
			return "\\t"
		end
		return string.format("\\u%04x", string.byte(char))
	end)
	return '"' .. out .. '"'
end

local function encode(value: any): string?
	local valueKind = kind(value)
	if valueKind == "string" then
		return escape(value)
	elseif valueKind == "boolean" then
		return tostring(value)
	elseif valueKind == "number" then
		return num(value)
	elseif valueKind == "enum" then
		return escape(value.Name or "None")
	elseif valueKind == "color" then
		return string.format(
			'"%d,%d,%d"',
			math.floor(math.clamp(value.R, 0, 1) * 255 + 0.5),
			math.floor(math.clamp(value.G, 0, 1) * 255 + 0.5),
			math.floor(math.clamp(value.B, 0, 1) * 255 + 0.5)
		)
	elseif valueKind == "udim2" then
		return string.format(
			'{"x":[%s,%s],"y":[%s,%s]}',
			num(value.X.Scale), num(value.X.Offset), num(value.Y.Scale), num(value.Y.Offset)
		)
	elseif valueKind == "udim" then
		return string.format("[%s,%s]", num(value.Scale), num(value.Offset))
	elseif valueKind == "vector2" then
		return string.format("[%s,%s]", num(value.X), num(value.Y))
	end
	return nil
end

local function colorSequence(value: any): string
	if type(value) ~= "table" or not value.Keypoints then
		return "null"
	end
	local parts = {}
	for _, keypoint in ipairs(value.Keypoints) do
		local stop = keypoint.Value
		table.insert(parts, string.format(
			"[%s,%d,%d,%d]",
			num(keypoint.Time),
			math.floor(stop.R * 255 + 0.5),
			math.floor(stop.G * 255 + 0.5),
			math.floor(stop.B * 255 + 0.5)
		))
	end
	return "[" .. table.concat(parts, ",") .. "]"
end

local function firstChildOfClass(instance, className)
	for _, child in ipairs(instance:GetChildren()) do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

local function readProp(instance, prop)
	local ok, value = pcall(function()
		return instance[prop]
	end)
	if not ok then
		return nil
	end
	return value
end

local function serialize(instance)
	local parts = { '"class":' .. escape(instance.ClassName) }

	for _, prop in ipairs(PLAIN_PROPS) do
		local encoded = encode(readProp(instance, prop))
		if encoded then
			parts[#parts + 1] = escape(prop) .. ":" .. encoded
		end
	end

	-- modifiers are folded into the element they decorate
	local gradient = firstChildOfClass(instance, "UIGradient")
	if gradient then
		local stops = colorSequence(gradient.Color or gradient.ColorSequence)
		local fade = "null"
		local sequence = gradient.Transparency
		if type(sequence) == "table" and sequence.Keypoints then
			local points = {}
			for _, keypoint in ipairs(sequence.Keypoints) do
				table.insert(points, string.format("[%s,%s]", num(keypoint.Time), num(keypoint.Value)))
			end
			fade = "[" .. table.concat(points, ",") .. "]"
		end
		parts[#parts + 1] = '"gradient":{"colors":' .. stops
			.. ',"transparency":' .. fade
			.. ',"rotation":' .. num(gradient.Rotation or 0) .. "}"
	end

	local corner = firstChildOfClass(instance, "UICorner")
	if corner then
		parts[#parts + 1] = '"radius":' .. (encode(corner.CornerRadius) or "null")
	end

	local stroke = firstChildOfClass(instance, "UIStroke")
	if stroke then
		parts[#parts + 1] = '"stroke":{"color":' .. (encode(stroke.Color) or "null")
			.. ',"thickness":' .. num(stroke.Thickness or 1)
			.. ',"transparency":' .. num(stroke.Transparency or 0) .. "}"
	end

	local padding = firstChildOfClass(instance, "UIPadding")
	if padding then
		parts[#parts + 1] = '"padding":{"t":' .. (encode(padding.PaddingTop) or "null")
			.. ',"r":' .. (encode(padding.PaddingRight) or "null")
			.. ',"b":' .. (encode(padding.PaddingBottom) or "null")
			.. ',"l":' .. (encode(padding.PaddingLeft) or "null") .. "}"
	end

	local list = firstChildOfClass(instance, "UIListLayout")
	if list then
		parts[#parts + 1] = '"list":{"padding":' .. (encode(list.Padding) or "[0,0]")
			.. ',"direction":' .. (encode(list.FillDirection) or '"Vertical"')
			.. ',"vAlign":' .. (encode(list.VerticalAlignment) or '"Top"')
			.. ',"hAlign":' .. (encode(list.HorizontalAlignment) or '"Left"') .. "}"
	end

	local grid = firstChildOfClass(instance, "UIGridLayout")
	if grid then
		parts[#parts + 1] = '"grid":{"cellSize":' .. (encode(grid.CellSize) or "null")
			.. ',"padding":' .. (encode(grid.CellPadding) or "null") .. "}"
	end

	local flex = firstChildOfClass(instance, "UIFlexItem")
	if flex then
		parts[#parts + 1] = '"flex":' .. (encode(flex.FlexMode) or '"Fill"')
	end

	local scaleMod = firstChildOfClass(instance, "UIScale")
	if scaleMod then
		parts[#parts + 1] = '"uiScale":' .. num(scaleMod.Scale or 1)
	end

	local children = {}
	for _, child in ipairs(instance:GetChildren()) do
		if GUI_CLASSES[child.ClassName] then
			table.insert(children, serialize(child))
		end
	end
	if #children > 0 then
		parts[#parts + 1] = '"children":[' .. table.concat(children, ",") .. "]"
	end

	return "{" .. table.concat(parts, ",") .. "}"
end

--====================== driver ==============================
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = DumpWindow and DumpWindow.Instance
if not mainFrame then
	for _, child in ipairs(PlayerGui:GetChildren()) do
		if child.ClassName == "ScreenGui" then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant.Name == "Main" and GUI_CLASSES[descendant.ClassName] then
					mainFrame = descendant
					break
				end
			end
		end
	end
end
assert(mainFrame, "no Main window frame found")

-- Let frame-driven animations (counters, fades) settle before serialising.
local RunService = game:GetService("RunService")
task.__flush()

-- Every tab page is serialised with real geometry: an invisible GuiObject
-- still gets sized by its layouts, and the viewer needs all of them so it
-- can emulate tab switching without re-running Luau.
local function revealPages(instance)
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("GuiObject") and typeof(child.Name) == "string" and string.sub(child.Name, 1, 5) == "Page_" then
			child.Visible = true
		end
		revealPages(child)
	end
end
pcall(function()
	if DumpWindow and DumpWindow.Instance then
		revealPages(DumpWindow.Instance)
	end
end)
task.__flush()

-- Step the demo's own update loop a few times...
for _ = 1, 12 do
	pcall(function()
		RunService.Heartbeat:Fire(0.1)
	end)
	task.__flush()
end

-- ...then let the value tweens finish without restarting them.
for _ = 1, 40 do
	pcall(function()
		RunService.RenderStepped:Fire(0.1)
	end)
	task.__flush()
end

print("###DUMP###")
print("{\"window\":" .. serialize(mainFrame) .. "}")
print("###END###")
