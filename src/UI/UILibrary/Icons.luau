--[[
	Aurora UI  •  Icons.luau
	------------------------------------------------------------------
	Zero-asset icon system. Every glyph is built from Frames, UICorners
	and UIStrokes on a 20×20 design grid, so nothing has to be uploaded
	and everything recolors with the active theme.

	Using your own icon pack? Drop ImageIds into Icons.Assets and the
	library will use the image instead of the vector fallback:

		Icons.Assets.home = "rbxassetid://123456789"
--]]

local Util = require(script.Parent.Util)

local Icons = {}
Icons.Size = 20
Icons.Assets = {}

------------------------------------------------------------------
-- Primitives (design-space coordinates, 20×20 grid)
------------------------------------------------------------------

local function part(root, x, y, w, h, rotation, color, radius)
	local frame = Util.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Rotation = rotation or 0,
		Parent = root,
	})
	Util.Corner(radius or math.min(w, h) / 2, frame)
	frame:SetAttribute("AuroraTintable", true)
	return frame
end

local function circle(root, x, y, diameter, color)
	local frame = Util.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(diameter, diameter),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = root,
	})
	Util.Corner(999, frame)
	frame:SetAttribute("AuroraTintable", true)
	return frame
end

local function ring(root, x, y, diameter, color, thickness)
	local frame = circle(root, x, y, diameter, color)
	frame.BackgroundTransparency = 1
	Util.Stroke(color, thickness or 2, 0, frame)
	frame:SetAttribute("AuroraTintable", true)
	return frame
end

local function clip(root, y, height)
	return Util.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(10, y),
		Size = UDim2.fromOffset(20, height),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = root,
	})
end

------------------------------------------------------------------
-- Glyphs
------------------------------------------------------------------

local Builders = {}

Builders.home = function(root, color)
	part(root, 6.6, 5.6, 10.2, 2.1, -45, color)
	part(root, 13.4, 5.6, 10.2, 2.1, 45, color)
	part(root, 10, 13, 12, 8, 0, color, 2.5)
	part(root, 10, 15.4, 3.4, 5.6, 0, Color3.new(0, 0, 0), 1.5)
end

Builders.grid = function(root, color)
	part(root, 6.4, 6.4, 6.6, 6.6, 0, color, 2)
	part(root, 13.6, 6.4, 6.6, 6.6, 0, color, 2)
	part(root, 6.4, 13.6, 6.6, 6.6, 0, color, 2)
	part(root, 13.6, 13.6, 6.6, 6.6, 0, color, 2)
end

Builders.user = function(root, color)
	circle(root, 10, 6.6, 6.4, color)
	part(root, 10, 15, 12.4, 7.4, 0, color, 3.7)
end

Builders.gear = function(root, color)
	for index = 0, 7 do
		local angle = math.rad(index * 45)
		part(root, 10 + math.cos(angle) * 7.4, 10 + math.sin(angle) * 7.4, 3.0, 5.2, index * 45, color, 1.3)
	end
	circle(root, 10, 10, 14.4, color)
	circle(root, 10, 10, 8.4, Color3.new(0, 0, 0))
end

Builders.sliders = function(root, color)
	part(root, 10, 5, 14, 2, 0, color)
	part(root, 10, 10, 14, 2, 0, color)
	part(root, 10, 15, 14, 2, 0, color)
	circle(root, 13.4, 5, 4.2, color)
	circle(root, 6.4, 10, 4.2, color)
	circle(root, 15, 15, 4.2, color)
end

Builders.search = function(root, color)
	ring(root, 9, 9, 11, color, 2)
	part(root, 15.2, 15.2, 7, 2.1, 45, color, 1)
end

Builders.close = function(root, color)
	part(root, 10, 10, 12, 2.1, 45, color, 1)
	part(root, 10, 10, 12, 2.1, -45, color, 1)
end

Builders.check = function(root, color)
	part(root, 7.4, 11.6, 6.4, 2.1, 45, color, 1)
	part(root, 12.8, 8.4, 10.6, 2.1, -48, color, 1)
end

Builders.chevronDown = function(root, color)
	part(root, 7.2, 9.8, 6.6, 2.1, 45, color, 1)
	part(root, 12.8, 9.8, 6.6, 2.1, -45, color, 1)
end

Builders.chevronUp = function(root, color)
	part(root, 7.2, 10.2, 6.6, 2.1, -45, color, 1)
	part(root, 12.8, 10.2, 6.6, 2.1, 45, color, 1)
end

Builders.chevronRight = function(root, color)
	part(root, 9.6, 6.8, 6.6, 2.1, 45, color, 1)
	part(root, 9.6, 13.2, 6.6, 2.1, -45, color, 1)
end

Builders.chevronLeft = function(root, color)
	part(root, 10.4, 6.8, 6.6, 2.1, -45, color, 1)
	part(root, 10.4, 13.2, 6.6, 2.1, 45, color, 1)
end

Builders.plus = function(root, color)
	part(root, 10, 10, 12, 2.1, 0, color, 1)
	part(root, 10, 10, 2.1, 12, 0, color, 1)
end

Builders.minus = function(root, color)
	part(root, 10, 10, 12, 2.1, 0, color, 1)
end

Builders.sparkle = function(root, color)
	part(root, 10, 10, 9, 9, 45, color, 2.2)
	part(root, 10, 10, 9, 9, 0, color, 2.2)
	circle(root, 16, 5, 3, color)
end

Builders.bolt = function(root, color)
	part(root, 11.4, 6.4, 9.4, 2.4, 62, color, 1.2)
	part(root, 8.6, 13.6, 9.4, 2.4, 62, color, 1.2)
	part(root, 9.2, 10, 3.2, 2.4, 0, color, 1.2)
end

Builders.shield = function(root, color)
	part(root, 10, 7.6, 13.2, 8.8, 0, color, 3.8)
	part(root, 10, 12.9, 9.4, 9.4, 45, color, 2.2)
	part(root, 10, 8.1, 8.6, 5.4, 0, Color3.new(0, 0, 0), 2.4)
	part(root, 10, 12.7, 5.4, 5.4, 45, Color3.new(0, 0, 0), 1.3)
end

Builders.chart = function(root, color)
	part(root, 5.6, 13.4, 3.2, 7, 0, color, 1.4)
	part(root, 10, 10.4, 3.2, 12.6, 0, color, 1.4)
	part(root, 5.6, 10.4, 3.2, 0.1, 0, color, 1.4)
	part(root, 14.4, 6.6, 3.2, 18, 0, color, 1.4)
end

Builders.bell = function(root, color)
	part(root, 10, 9, 11, 9, 0, color, 4.6)
	part(root, 10, 14.6, 13.4, 1.9, 0, color, 1)
	circle(root, 10, 17.4, 2.6, color)
end

Builders.layers = function(root, color)
	part(root, 10, 5.4, 7.4, 7.4, 45, color, 1.8)
	part(root, 10, 11, 7.4, 7.4, 45, color, 1.8)
	part(root, 10, 16.2, 7.4, 7.4, 45, color, 1.8)
end

Builders.code = function(root, color)
	part(root, 6.4, 7.2, 6, 2, -45, color, 1)
	part(root, 6.4, 12.8, 6, 2, 45, color, 1)
	part(root, 13.6, 7.2, 6, 2, 45, color, 1)
	part(root, 13.6, 12.8, 6, 2, -45, color, 1)
end

Builders.lock = function(root, color)
	local arch = clip(root, 3.4, 6)
	ring(arch, 10, -2.2, 9.4, color, 2)
	part(root, 10, 14, 11.6, 8, 0, color, 2.6)
	circle(root, 10, 13.4, 2.2, Color3.new(0, 0, 0))
end

Builders.dot = function(root, color)
	circle(root, 10, 10, 6, color)
end

Builders.sun = function(root, color)
	circle(root, 10, 10, 7.6, color)
	for index = 0, 7 do
		local angle = math.rad(index * 45)
		part(root, 10 + math.cos(angle) * 8.4, 10 + math.sin(angle) * 8.4, 2.6, 2.6, index * 45, color, 1)
	end
end

Builders.moon = function(root, color, mask)
	circle(root, 10, 10, 12.4, color)
	circle(root, 13.6, 7.4, 11.2, mask or Color3.new(0, 0, 0))
end

Builders.info = function(root, color)
	ring(root, 10, 10, 15, color or Color3.new(1, 1, 1), 2)
	circle(root, 10, 6.4, 2.2, color)
	part(root, 10, 11.6, 2.2, 6.4, 0, color, 1)
end

Builders.warning = function(root, color)
	part(root, 10, 5.6, 2.4, 8, 0, color, 1.2)
	circle(root, 10, 15.4, 2.4, color)
	part(root, 10, 12.6, 15.4, 2.2, 0, color, 1.1)
end

Builders.eye = function(root, color)
	part(root, 10, 10, 16.2, 10.2, 0, color, 5.1)
	circle(root, 10, 10, 5.2, Color3.new())
	circle(root, 10, 10, 2.2, color)
end

Builders.trash = function(root, color)
	part(root, 10, 4.4, 11, 2, 0, color, 1)
	part(root, 9.4, 2.8, 4, 2, 0, color, 1)
	part(root, 10, 12.6, 9.4, 10.6, 0, color, 2.4)
	part(root, 10, 12.6, 1.6, 7, 0, Color3.new(0, 0, 0), 0.8)
end

Builders.cloud = function(root, color)
	circle(root, 7.4, 11, 7.4, color)
	circle(root, 12.4, 9, 9, color)
	part(root, 10, 14.6, 13.4, 5.2, 0, color, 2.6)
end

Builders.play = function(root, color)
	part(root, 10, 10, 3, 12.4, 45, color, 1.4)
	part(root, 10, 10, 3, 12.4, -45, color, 1.4)
end

------------------------------------------------------------------
-- Public API
------------------------------------------------------------------

--- Build an icon. Returns a Frame sized to `opts.Size` pixels.
-- opts = { Size = number, Color = Color3, Mask = Color3 }
function Icons.Get(name: string, parent: Instance, opts: { [string]: any }?): Frame
	opts = opts or {}

	local size = opts.Size or 18
	local color = opts.Color or Util.Theme.Text or Color3.new(1, 1, 1)
	local mask = opts.Mask or Util.Theme.Surface or Color3.new(0, 0, 0)

	local root = Util.New("Frame", {
		Name = "Icon_" .. tostring(name),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})

	local asset = Icons.Assets[name]
	if asset then
		local image = Util.New("ImageLabel", {
			Name = "AssetIcon",
			BackgroundTransparency = 1,
			Image = asset,
			ImageColor3 = color,
			ImageTransparency = 0,
			Size = UDim2.fromScale(1, 1),
			Parent = root,
		})
		image:SetAttribute("AuroraTintable", true)
		root:SetAttribute("AuroraIconName", name)
		return root
	end

	local holder = Util.New("Frame", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = root,
	})
	Util.New("UIScale", { Scale = size / 20, Parent = holder })

	local builder = Builders[name] or Builders.dot
	builder(holder, color, mask)

	-- Any piece painted pure black is a "hole" punched out of the glyph;
	-- paint it with the surface color behind the icon instead of tinting it.
	for _, piece in ipairs(holder:GetDescendants()) do
		if piece:IsA("Frame") and piece.BackgroundColor3 == Color3.new(0, 0, 0) then
			piece:SetAttribute("AuroraTintable", nil)
			piece:SetAttribute("AuroraHole", true)
			piece.BackgroundColor3 = mask
		end
	end

	root:SetAttribute("AuroraIconName", name)
	return root
end

--- Recolor every tintable piece of an icon (including holes).
function Icons.Tint(root: Instance, color: Color3, mask: Color3?)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("AuroraTintable") then
			if descendant:IsA("ImageLabel") then
				descendant.ImageColor3 = color
			elseif descendant:IsA("Frame") then
				descendant.BackgroundColor3 = color
			end
		end
	end
end

--- Recolor icon "holes" (the punched-out shapes) to match the surface
--- behind them; call whenever the container color changes.
function Icons.Mask(root: Instance, mask: Color3)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("AuroraHole") then
			descendant.BackgroundColor3 = mask
		end
	end
end

--- Repaint every icon "hole" in a subtree to match whatever surface is
--- behind it. Call after a theme swap.
function Icons.RefreshAll(root: Instance, fallback: Color3?)
	local default = fallback or Util.Theme.Surface or Color3.new(0, 0, 0)

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:GetAttribute("AuroraHole") and descendant:IsA("Frame") then
			local color = default
			local ancestor = descendant.Parent
			while ancestor and ancestor ~= root do
				if ancestor:IsA("GuiObject") and ancestor.BackgroundTransparency < 0.86 then
					color = ancestor.BackgroundColor3
					break
				end
				ancestor = ancestor.Parent
			end
			descendant.BackgroundColor3 = color
		end
	end
end

Icons.List = {}
for name in pairs(Builders) do
	table.insert(Icons.List, name)
end
table.sort(Icons.List)

return Icons
