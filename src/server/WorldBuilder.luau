-- WorldBuilder: builds the whole Enchanted Academy in 3D from code, on a clean
-- grid. North: the Academy, Big Tree and Wizard Tower behind the Parade Lane.
-- Centre: the Arena Playground with its crest mural, art panels, arches and
-- mascot statues. West and east: eight classroom bases facing the arena.
-- South: the spawn plaza and the station row (Gacha, Upgrades, Quest Board,
-- Rebirth Altar, Fuse Lab), with the Cafeteria and Gym in the corners.
-- Only Instance.new and CFrame math are used, so the same code also prebuilds
-- the static preview saved in the place file.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local WorldBuilder = {}

WorldBuilder.ROOT_NAME = "EnchantedAcademy"
WorldBuilder.OnPedestalAdded = nil -- set by CarrySystem for Extra Slot rows

local G = Config.GROUND_Y
local WHITE = Color3.fromRGB(255, 255, 255)
local DARK = Color3.fromRGB(28, 26, 44)
local GOLD = Color3.fromRGB(255, 205, 60)
local CREAM = Color3.fromRGB(244, 228, 196)
local WOOD = Color3.fromRGB(150, 100, 60)
local WOOD_DARK = Color3.fromRGB(110, 72, 44)
local STONE = Color3.fromRGB(176, 170, 186)
local PATH = Color3.fromRGB(214, 200, 172)
local PURPLE = Color3.fromRGB(120, 80, 200)
local VIOLET = Color3.fromRGB(165, 110, 245)

local BASE_COLORS = {
	Color3.fromRGB(255, 110, 110), Color3.fromRGB(255, 185, 60), Color3.fromRGB(120, 215, 100), Color3.fromRGB(80, 170, 255),
	Color3.fromRGB(185, 115, 255), Color3.fromRGB(255, 140, 200), Color3.fromRGB(80, 215, 205), Color3.fromRGB(255, 140, 70),
}

-- Layout grid (studs). Every structure below is placed from these numbers.
local LAYOUT = {
	arenaRadius = 39,
	baseHalf = 14,
	baseRowX = 130,
	baseRowZ = { -51, -17, 17, 51 },
	walkwayX = 109,
	laneZ = -96,
	laneHalfLength = 160,
	academyZ = -150,
	stationZ = 124,
	spawnZ = 100,
	fence = 190,
}
WorldBuilder.LAYOUT = LAYOUT

local world = nil

---------------------------------------------------------------------------
-- Part helpers: every part is anchored, sized and placed by CFrame only.
---------------------------------------------------------------------------
local function make(className, parent, name, size, cframe, color, material)
	local p = Instance.new(className)
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function block(parent, name, size, cframe, color, material)
	return make("Part", parent, name, size, cframe, color, material)
end

-- A cylinder standing upright: `height` along world Y, `diameter` across.
local function cylinder(parent, name, height, diameter, cframe, color, material)
	local p = make("Part", parent, name, Vector3.new(height, diameter, diameter), cframe * CFrame.Angles(0, 0, math.rad(90)), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(parent, name, diameter, cframe, color, material)
	local p = make("Part", parent, name, Vector3.new(diameter, diameter, diameter), cframe, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function folderIn(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Sits a part's bottom exactly on height y.
local function onGround(x, y, z, height)
	return CFrame.new(x, y + height / 2, z)
end

-- A SurfaceGui canvas sized to the face in pixels-per-stud, so text never stretches.
local function canvas(target, face, pixelsPerStud)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Canvas" .. face.Name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 30
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = target
	return gui
end

local function frame(parent, name, size, position, color, radius, transparency)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	if radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = radius
		corner.Parent = f
	end
	return f
end

local function circle(parent, name, diameterScale, cx, cy, color)
	local f = frame(parent, name, UDim2.fromScale(diameterScale, diameterScale), UDim2.fromScale(cx, cy), color, UDim.new(0.5, 0))
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = f
	return f
end

local function gradient(target, fromColor, toColor, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(fromColor, toColor)
	g.Rotation = rotation or 90
	g.Parent = target
	return g
end

local function text(parent, name, content, size, position, color, font)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Size = size
	t.Position = position
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.BackgroundTransparency = 1
	t.Font = font or Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color or WHITE
	t.TextStrokeColor3 = DARK
	t.TextStrokeTransparency = 0.15
	t.Text = content
	t.Parent = parent
	return t
end

-- A sign: a board with a text face. Returns the board and its label.
local function signText(board, face, content, color, backColor)
	local gui = canvas(board, face, 30)
	local bg = frame(gui, "Back", UDim2.fromScale(0.96, 0.86), UDim2.fromScale(0.5, 0.5), backColor or DARK, UDim.new(0.12, 0), 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 4
	stroke.Parent = bg
	local label = text(bg, "Label", content, UDim2.fromScale(0.92, 0.8), UDim2.fromScale(0.5, 0.5), color or GOLD)
	return label, gui
end

local function prompt(parent, actionText, objectText, range, hold)
	local p = Instance.new("ProximityPrompt")
	p.Name = actionText .. "Prompt"
	p.ActionText = actionText
	p.ObjectText = objectText
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = range or 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function lamp(parent, x, z, color)
	block(parent, "LampPole", Vector3.new(0.6, 10, 0.6), onGround(x, G, z, 10), DARK, Enum.Material.Metal)
	local head = ball(parent, "LampHead", 1.8, CFrame.new(x, G + 10.9, z), color or Color3.fromRGB(255, 230, 150), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = color or Color3.fromRGB(255, 220, 160)
	light.Range = 18
	light.Brightness = 1.2
	light.Parent = head
end

local function tree(parent, x, z, height, leafColor)
	cylinder(parent, "TreeTrunk", height, 2.4, onGround(x, G, z, height), WOOD, Enum.Material.Wood)
	local leaves = ball(parent, "TreeLeaves", 10, CFrame.new(x, G + height + 3.5, z), leafColor, Enum.Material.Grass)
	leaves.CanCollide = false
	leaves.CanQuery = false
	local top = ball(parent, "TreeLeavesTop", 6.5, CFrame.new(x, G + height + 8.5, z), leafColor:Lerp(WHITE, 0.15), Enum.Material.Grass)
	top.CanCollide = false
	top.CanQuery = false
end

---------------------------------------------------------------------------
-- Ground, paths, fence and the invisible boundary.
---------------------------------------------------------------------------
local function buildGround(root)
	local f = folderIn(root, "Grounds")
	block(f, "Grass", Vector3.new(520, 4, 520), CFrame.new(0, G - 2, 0), Color3.fromRGB(104, 190, 92), Enum.Material.Grass)
	local pathHeight = 0.2
	local function path(name, sizeX, sizeZ, x, z)
		block(f, name, Vector3.new(sizeX, pathHeight, sizeZ), onGround(x, G, z, pathHeight), PATH, Enum.Material.Slate)
	end
	local r = LAYOUT.arenaRadius
	path("PathNorth", 10, 90 - r, 0, -(r + 90) / 2)
	path("PathSouth", 10, 94 - r, 0, (r + 94) / 2)
	path("PathSpawnLink", 10, 5, 0, 108.5)
	for _, side in ipairs({ -1, 1 }) do
		path(side < 0 and "PathWest" or "PathEast", 105 - r, 10, side * (r + 105) / 2, 0)
		path(side < 0 and "WalkwayWest" or "WalkwayEast", 8, 132, side * LAYOUT.walkwayX, 0)
	end
	path("PathStations", 190, 6, 0, 114)
	-- Fence posts and rails around the yard.
	local fence = folderIn(f, "Fence")
	local edge = LAYOUT.fence
	local spacing = edge / 10
	for i = -10, 10 do
		local t = i * spacing
		local posts = { { t, -edge }, { t, edge } }
		if math.abs(i) < 10 then -- corner posts are already placed by the rows above
			table.insert(posts, { -edge, t })
			table.insert(posts, { edge, t })
		end
		for _, post in ipairs(posts) do
			block(fence, "FencePost", Vector3.new(1, 5, 1), onGround(post[1], G, post[2], 5), WOOD_DARK, Enum.Material.Wood)
		end
		if i < 10 then
			local mid = t + spacing / 2
			local rail = spacing - 1
			for _, railY in ipairs({ 1.6, 3.6 }) do
				block(fence, "FenceRail", Vector3.new(rail, 0.4, 0.4), CFrame.new(mid, G + railY, -edge), CREAM, Enum.Material.Wood)
				block(fence, "FenceRail", Vector3.new(rail, 0.4, 0.4), CFrame.new(mid, G + railY, edge), CREAM, Enum.Material.Wood)
				block(fence, "FenceRail", Vector3.new(0.4, 0.4, rail), CFrame.new(-edge, G + railY, mid), CREAM, Enum.Material.Wood)
				block(fence, "FenceRail", Vector3.new(0.4, 0.4, rail), CFrame.new(edge, G + railY, mid), CREAM, Enum.Material.Wood)
			end
		end
	end
	-- Invisible walls: nobody is pushed or pulled out of the school.
	local walls = folderIn(f, "BoundaryWalls")
	for _, wall in ipairs({
		{ Vector3.new(2, 120, 388), Vector3.new(-edge - 3, G + 60, 0) },
		{ Vector3.new(2, 120, 388), Vector3.new(edge + 3, G + 60, 0) },
		{ Vector3.new(388, 120, 2), Vector3.new(0, G + 60, -edge - 3) },
		{ Vector3.new(388, 120, 2), Vector3.new(0, G + 60, edge + 3) },
	}) do
		local w = block(walls, "BoundaryWall", wall[1], CFrame.new(wall[2]), WHITE)
		w.Transparency = 1
		w.CastShadow = false
	end
	-- Forest outside the fence: a square band of trees, two rows deep.
	local forest = folderIn(f, "Forest")
	for i = -7, 7 do
		local t = i * 32
		local depth = 212 + (i % 2) * 20
		local spots = { { t, -depth }, { t, depth } }
		if math.abs(i) < 7 then -- the corner trees come from the rows above
			table.insert(spots, { -depth, t })
			table.insert(spots, { depth, t })
		end
		for k, spot in ipairs(spots) do
			local shade = (i + k) % 3
			tree(forest, spot[1], spot[2], 14 + shade * 3, Color3.fromRGB(70 + shade * 14, 165, 80))
		end
	end
	-- Quadrant gardens between the spines: a tree and two flower beds each.
	local gardens = folderIn(f, "Gardens")
	local flowerColors = { Color3.fromRGB(255, 120, 180), Color3.fromRGB(255, 215, 80), Color3.fromRGB(180, 120, 255), Color3.fromRGB(255, 255, 255) }
	for _, qx in ipairs({ -70, 70 }) do
		for _, qz in ipairs({ -50, 50 }) do
			tree(gardens, qx, qz, 13, Color3.fromRGB(80, 175, 85))
			for bed = -1, 1, 2 do
				local bx = qx + bed * 14
				block(gardens, "FlowerBed", Vector3.new(8, 0.6, 4), onGround(bx, G, qz, 0.6), WOOD_DARK, Enum.Material.Wood)
				for k = 0, 3 do
					ball(gardens, "Flower", 1.1, CFrame.new(bx - 3 + k * 2, G + 0.6 + 0.55, qz), flowerColors[k + 1], Enum.Material.Neon)
				end
			end
		end
	end
	-- Lamps along the spines, mirrored on both sides.
	local lamps = folderIn(f, "Lamps")
	for _, z in ipairs({ -78, -55, 52, 76 }) do
		lamp(lamps, -8, z)
		lamp(lamps, 8, z)
	end
	for _, x in ipairs({ -98, -75, -52, 52, 75, 98 }) do
		lamp(lamps, x, -8)
		lamp(lamps, x, 8)
	end
end

---------------------------------------------------------------------------
-- North side: the Academy, the Big Tree, the Wizard Tower, bus and bell.
---------------------------------------------------------------------------
local function buildAcademy(root)
	local f = folderIn(root, "Academy")
	local z = LAYOUT.academyZ
	local front = z + 14
	block(f, "Hall", Vector3.new(64, 24, 28), onGround(0, G, z, 24), CREAM, Enum.Material.Brick)
	block(f, "Roof", Vector3.new(66, 1.5, 30), CFrame.new(0, G + 24.75, z), PURPLE, Enum.Material.SmoothPlastic)
	block(f, "RoofTrim", Vector3.new(66, 0.6, 0.6), CFrame.new(0, G + 25.8, front + 0.7), GOLD, Enum.Material.Neon)
	block(f, "Door", Vector3.new(10, 13, 0.6), onGround(0, G, front + 0.3, 13), WOOD_DARK, Enum.Material.Wood)
	block(f, "DoorArch", Vector3.new(12, 1.2, 0.8), CFrame.new(0, G + 13.6, front + 0.4), GOLD, Enum.Material.Neon)
	for _, x in ipairs({ -24, -14, 14, 24 }) do
		for _, y in ipairs({ 7, 16 }) do
			block(f, "Window", Vector3.new(6, 5, 0.4), CFrame.new(x, G + y, front + 0.2), Color3.fromRGB(255, 225, 140), Enum.Material.Neon)
			block(f, "WindowSill", Vector3.new(7, 0.5, 0.9), CFrame.new(x, G + y - 2.75, front + 0.45), WHITE)
		end
	end
	local sign = block(f, "AcademySign", Vector3.new(20, 4.5, 0.6), CFrame.new(0, G + 19.5, front + 0.3), DARK)
	signText(sign, Enum.NormalId.Back, Config.GAME_SUBTITLE, GOLD)
	-- Clock tower on the roof with a stepped spire.
	block(f, "ClockTower", Vector3.new(10, 12, 10), onGround(0, G + 25.5, z, 12), CREAM, Enum.Material.Brick)
	local clock = block(f, "ClockFace", Vector3.new(7, 7, 0.3), CFrame.new(0, G + 31.5, z + 5.15), WHITE)
	local clockGui = canvas(clock, Enum.NormalId.Back, 40)
	local dial = circle(clockGui, "Dial", 0.95, 0.5, 0.5, WHITE)
	local ring = Instance.new("UIStroke")
	ring.Color = PURPLE
	ring.Thickness = 10
	ring.Parent = dial
	for hour = 0, 11 do
		local a = math.rad(hour * 30)
		circle(clockGui, "Tick", 0.07, 0.5 + math.sin(a) * 0.38, 0.5 - math.cos(a) * 0.38, PURPLE)
	end
	local hand1 = frame(clockGui, "HourHand", UDim2.fromScale(0.06, 0.3), UDim2.fromScale(0.5, 0.38), DARK, UDim.new(0.5, 0))
	hand1.Rotation = 0
	local hand2 = frame(clockGui, "MinuteHand", UDim2.fromScale(0.05, 0.4), UDim2.fromScale(0.62, 0.5), DARK, UDim.new(0.5, 0))
	hand2.Rotation = 90
	local spireY = G + 37.5
	for i, step in ipairs({ { 11, 1.5 }, { 8, 1.5 }, { 5, 1.5 }, { 2.4, 2.5 } }) do
		cylinder(f, "Spire" .. i, step[2], step[1], onGround(0, spireY, z, step[2]), i == 4 and GOLD or PURPLE, i == 4 and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		spireY += step[2]
	end
	-- Lockers along the front, mirrored either side of the door.
	local lockerColors = { Color3.fromRGB(255, 95, 95), Color3.fromRGB(255, 200, 60), Color3.fromRGB(95, 200, 120), Color3.fromRGB(95, 150, 255) }
	for i = 0, 6 do
		for _, side in ipairs({ -1, 1 }) do
			block(f, "Locker", Vector3.new(2.4, 5.5, 1.6), onGround(side * (12 + i * 2.6), G, front + 3, 5.5), lockerColors[i % 4 + 1], Enum.Material.Metal)
		end
	end
	-- The yellow school bus parked east of the plaza.
	local bus = folderIn(f, "SchoolBus")
	block(bus, "BusBody", Vector3.new(22, 7, 8), onGround(60, G + 1.2, -120, 7), Color3.fromRGB(255, 205, 40))
	block(bus, "BusHood", Vector3.new(4, 4, 7.6), onGround(73, G + 1.2, -120, 4), Color3.fromRGB(255, 205, 40))
	block(bus, "BusStripe", Vector3.new(22.2, 0.6, 8.2), CFrame.new(60, G + 4.4, -120), DARK)
	for i = 0, 4 do
		block(bus, "BusWindow", Vector3.new(3, 2.4, 0.3), CFrame.new(52 + i * 4, G + 6.3, -115.85), Color3.fromRGB(140, 205, 245), Enum.Material.Glass)
	end
	for _, wx in ipairs({ 53, 67 }) do
		for _, wz in ipairs({ -124.5, -115.5 }) do
			local wheel = make("Part", bus, "Wheel", Vector3.new(1, 2.4, 2.4), CFrame.new(wx, G + 1.2, wz), DARK)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CFrame = CFrame.new(wx, G + 1.2, wz) * CFrame.Angles(0, math.rad(90), 0)
		end
	end
	local busSign = block(bus, "BusSign", Vector3.new(10, 1.8, 0.3), CFrame.new(60, G + 2.9, -115.85), WHITE)
	signText(busSign, Enum.NormalId.Back, "SCHOOL BUS", DARK, WHITE)
	-- The school bell on its frame, mirroring the bus to the west.
	local bell = folderIn(f, "SchoolBell")
	for _, bx in ipairs({ -66, -54 }) do
		block(bell, "BellPost", Vector3.new(1, 12, 1), onGround(bx, G, -120, 12), WOOD_DARK, Enum.Material.Wood)
	end
	block(bell, "BellBeam", Vector3.new(13, 1, 1.2), CFrame.new(-60, G + 12.5, -120), WOOD_DARK, Enum.Material.Wood)
	cylinder(bell, "Bell", 4, 4.5, CFrame.new(-60, G + 10, -120), GOLD, Enum.Material.Metal)
	ball(bell, "BellClapper", 1, CFrame.new(-60, G + 7.6, -120), DARK)
	local bellSign = block(bell, "BellSign", Vector3.new(10, 2.4, 0.4), onGround(-60, G, -116, 2.4), DARK)
	signText(bellSign, Enum.NormalId.Back, "LUNCH BELL", GOLD)
end

local function buildTower(root)
	local f = folderIn(root, "WizardTower")
	local x, z = LAYOUT.baseRowX, LAYOUT.academyZ
	cylinder(f, "TowerBody", 44, 14, onGround(x, G, z, 44), STONE, Enum.Material.Slate)
	cylinder(f, "Balcony", 1, 14, onGround(x, G + 44, z, 1), Color3.fromRGB(150, 140, 165), Enum.Material.Slate)
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		if i ~= 1 and i ~= 2 then -- the gap faces the truss on the south side
			block(f, "Parapet", Vector3.new(2.2, 1.6, 1), onGround(x + math.cos(a) * 6.4, G + 45, z + math.sin(a) * 6.4, 1.6) * CFrame.Angles(0, -a + math.rad(90), 0), STONE, Enum.Material.Slate)
		end
	end
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		block(f, "RoofPost", Vector3.new(0.8, 7, 0.8), onGround(x + math.cos(a) * 5, G + 45, z + math.sin(a) * 5, 7), WOOD_DARK, Enum.Material.Wood)
	end
	local roofY = G + 52
	for i, step in ipairs({ { 15, 1 }, { 11, 2 }, { 7, 2 }, { 3.5, 2 }, { 1.4, 2 } }) do
		cylinder(f, "TowerRoof" .. i, step[2], step[1], onGround(x, roofY, z, step[2]), i == 5 and GOLD or VIOLET, i == 5 and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		roofY += step[2]
	end
	for _, y in ipairs({ 14, 28 }) do
		block(f, "TowerWindow", Vector3.new(3, 5, 0.6), CFrame.new(x - 3.2, G + y, z + 6.3), Color3.fromRGB(255, 225, 140), Enum.Material.Neon)
	end
	-- A truss up the south face: climbable, unlike loose rungs.
	local truss = make("TrussPart", f, "TowerTruss", Vector3.new(2, 46, 2), onGround(x, G, z + 8, 46), DARK, Enum.Material.Metal)
	truss.Style = Enum.Style.AlternatingSupports
	return Vector3.new(x, G + 45, z)
end

local function buildBigTree(root)
	local f = folderIn(root, "BigTree")
	local x, z = -LAYOUT.baseRowX, LAYOUT.academyZ
	cylinder(f, "Trunk", 30, 8, onGround(x, G, z, 30), WOOD, Enum.Material.Wood)
	block(f, "TreePlatform", Vector3.new(10, 1, 10), onGround(x, G + 30, z, 1), Color3.fromRGB(170, 120, 70), Enum.Material.WoodPlanks)
	make("TrussPart", f, "TreeTruss", Vector3.new(2, 32, 2), onGround(x, G, z + 6, 32), WOOD_DARK, Enum.Material.Wood)
	-- Canopy: four leaf clusters on branches from the trunk, and a crown
	-- resting on them, high enough to stand under on the platform.
	for _, dir in ipairs({ Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), Vector3.new(0, 0, 1) }) do
		local from = Vector3.new(x, G + 27, z) + dir * 2.5
		local to = Vector3.new(x, G + 39, z) + dir * 11
		local branch = cylinder(f, "Branch", (to - from).Magnitude, 1.8, CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, math.rad(90), 0), WOOD, Enum.Material.Wood)
		branch.CanCollide = false
		local l = ball(f, "Leaves", 12, CFrame.new(to), Color3.fromRGB(80, 175, 85), Enum.Material.Grass)
		l.CanCollide = false
		l.CanQuery = false
	end
	local crown = ball(f, "LeavesCrown", 14, CFrame.new(x, G + 45, z), Color3.fromRGB(95, 185, 90), Enum.Material.Grass)
	crown.CanCollide = false
	crown.CanQuery = false
	cylinder(f, "CrowNest", 1.5, 2, onGround(x - 4, G + 31, z - 4, 1.5), WOOD_DARK, Enum.Material.Wood)
	return Vector3.new(x, G + 31, z)
end

---------------------------------------------------------------------------
-- The Parade Lane: brainrots walk east along it, waiting to be bought.
---------------------------------------------------------------------------
local function buildParadeLane(root)
	local f = folderIn(root, "ParadeLane")
	local z, half = LAYOUT.laneZ, LAYOUT.laneHalfLength
	block(f, "Lane", Vector3.new(half * 2, 0.2, 12), onGround(0, G, z, 0.2), Color3.fromRGB(235, 200, 140), Enum.Material.Sand)
	block(f, "LaneStripe", Vector3.new(half * 2, 0.05, 1), onGround(0, G + 0.2, z, 0.05), WHITE, Enum.Material.SmoothPlastic)
	-- The arena path meets the lane from the south, so the south curb has a gap.
	block(f, "CurbNorth", Vector3.new(half * 2, 0.6, 0.6), onGround(0, G, z - 6.3, 0.6), Color3.fromRGB(230, 80, 80))
	for _, side in ipairs({ -1, 1 }) do
		local length = half - 5
		block(f, "CurbSouth", Vector3.new(length, 0.6, 0.6), onGround(side * (5 + length / 2), G, z + 6.3, 0.6), Color3.fromRGB(230, 80, 80))
	end
	local flagColors = { Color3.fromRGB(255, 95, 95), Color3.fromRGB(255, 205, 60), Color3.fromRGB(95, 205, 125), Color3.fromRGB(95, 155, 255) }
	for i = 0, 7 do
		local x = -140 + i * 40
		block(f, "FlagPole", Vector3.new(0.4, 9, 0.4), onGround(x, G, z - 9, 9), WHITE, Enum.Material.Metal)
		block(f, "Flag", Vector3.new(3.6, 2.4, 0.2), CFrame.new(x + 2, G + 7.6, z - 9), flagColors[i % 4 + 1])
	end
	for _, side in ipairs({ -1, 1 }) do
		local ax = side * (half - 4)
		for _, pz in ipairs({ z - 7.5, z + 7.5 }) do
			block(f, "ArchPillar", Vector3.new(1.6, 12, 1.6), onGround(ax, G, pz, 12), Color3.fromRGB(255, 110, 110))
		end
		local beam = block(f, "ArchBeam", Vector3.new(1.6, 2.4, 16.6), CFrame.new(ax, G + 13.2, z), GOLD)
		signText(beam, side < 0 and Enum.NormalId.Right or Enum.NormalId.Left, "PARADE LANE", DARK, GOLD)
	end
	return Vector3.new(-half + 10, G + 0.2, z), Vector3.new(half - 10, G + 0.2, z)
end

---------------------------------------------------------------------------
-- The Arena Playground: crest mural, art panels, arches, benches, statues.
---------------------------------------------------------------------------
-- The crest mural: the academy emblem painted with layered vector Frames.
local function paintCrest(gui)
	local bg = circle(gui, "CrestDisc", 1, 0.5, 0.5, PURPLE)
	gradient(bg, Color3.fromRGB(70, 40, 150), Color3.fromRGB(40, 120, 210), 45)
	local rim = Instance.new("UIStroke")
	rim.Color = GOLD
	rim.Thickness = 18
	rim.Parent = bg
	-- Sun rays behind the book.
	for i = 0, 11 do
		local ray = frame(gui, "Ray", UDim2.fromScale(0.05, 0.86), UDim2.fromScale(0.5, 0.5), GOLD, UDim.new(0.5, 0), 0.55)
		ray.Rotation = i * 15
	end
	circle(gui, "InnerDisc", 0.62, 0.5, 0.5, Color3.fromRGB(60, 40, 120))
	-- A ring of the 15 rarity gems.
	for i, rarity in ipairs(Config.RARITY_ORDER) do
		local a = math.rad((i - 1) * 24)
		local gem = circle(gui, "Gem" .. rarity, 0.055, 0.5 + math.sin(a) * 0.4, 0.5 - math.cos(a) * 0.4, Config.RARITY_COLORS[rarity])
		local glow = Instance.new("UIStroke")
		glow.Color = WHITE
		glow.Thickness = 3
		glow.Parent = gem
	end
	-- The open spellbook.
	local leftPage = frame(gui, "PageLeft", UDim2.fromScale(0.24, 0.3), UDim2.fromScale(0.385, 0.6), CREAM, UDim.new(0.12, 0))
	leftPage.Rotation = -8
	local rightPage = frame(gui, "PageRight", UDim2.fromScale(0.24, 0.3), UDim2.fromScale(0.615, 0.6), CREAM, UDim.new(0.12, 0))
	rightPage.Rotation = 8
	frame(gui, "Spine", UDim2.fromScale(0.02, 0.3), UDim2.fromScale(0.5, 0.61), Color3.fromRGB(170, 60, 60), UDim.new(0.5, 0))
	for line = 0, 3 do
		frame(leftPage, "Line", UDim2.fromScale(0.7, 0.05), UDim2.fromScale(0.5, 0.3 + line * 0.15), Color3.fromRGB(150, 130, 200), UDim.new(0.5, 0))
		frame(rightPage, "Line", UDim2.fromScale(0.7, 0.05), UDim2.fromScale(0.5, 0.3 + line * 0.15), Color3.fromRGB(150, 130, 200), UDim.new(0.5, 0))
	end
	-- The brainrot mascot popping out of the book: Pensil Penguin.
	local head = circle(gui, "MascotHead", 0.26, 0.5, 0.36, Color3.fromRGB(90, 130, 200))
	gradient(head, Color3.fromRGB(120, 160, 235), Color3.fromRGB(60, 90, 170), 90)
	circle(gui, "MascotBelly", 0.15, 0.5, 0.42, WHITE)
	for _, side in ipairs({ -1, 1 }) do
		circle(gui, "EyeWhite", 0.075, 0.5 + side * 0.05, 0.31, WHITE)
		circle(gui, "EyePupil", 0.035, 0.5 + side * 0.045, 0.315, DARK)
	end
	frame(gui, "Beak", UDim2.fromScale(0.06, 0.03), UDim2.fromScale(0.5, 0.365), Color3.fromRGB(255, 170, 40), UDim.new(0.5, 0))
	local cap = frame(gui, "Cap", UDim2.fromScale(0.2, 0.035), UDim2.fromScale(0.5, 0.235), DARK, UDim.new(0.2, 0))
	cap.Rotation = -6
	frame(gui, "CapTassel", UDim2.fromScale(0.012, 0.06), UDim2.fromScale(0.585, 0.265), GOLD, UDim.new(0.5, 0))
	local pencil = frame(gui, "Pencil", UDim2.fromScale(0.03, 0.2), UDim2.fromScale(0.65, 0.36), Color3.fromRGB(255, 205, 50), UDim.new(0.3, 0))
	pencil.Rotation = 25
	-- Ribbon banner with the school name.
	local ribbon = frame(gui, "Ribbon", UDim2.fromScale(0.78, 0.1), UDim2.fromScale(0.5, 0.82), Color3.fromRGB(220, 60, 70), UDim.new(0.3, 0))
	local ribbonStroke = Instance.new("UIStroke")
	ribbonStroke.Color = GOLD
	ribbonStroke.Thickness = 6
	ribbonStroke.Parent = ribbon
	text(ribbon, "RibbonText", Config.GAME_TITLE, UDim2.fromScale(0.94, 0.82), UDim2.fromScale(0.5, 0.5), WHITE)
	text(gui, "ArenaWord", "ARENA PLAYGROUND", UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.5, 0.14), GOLD)
end

-- An art panel: a framed picture of one brainrot, drawn with Frames.
local function paintBrainrotArt(gui, entry, caption)
	local sky = frame(gui, "Sky", UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(120, 190, 255), UDim.new(0.04, 0))
	gradient(sky, Color3.fromRGB(255, 200, 230), Color3.fromRGB(110, 170, 255), 90)
	for i = 0, 2 do
		circle(gui, "Cloud", 0.16, 0.15 + i * 0.35, 0.16 + (i % 2) * 0.06, WHITE).BackgroundTransparency = 0.25
	end
	frame(gui, "Hill", UDim2.fromScale(1.2, 0.5), UDim2.fromScale(0.5, 0.95), Color3.fromRGB(100, 200, 110), UDim.new(0.5, 0))
	local shadow = frame(gui, "Shadow", UDim2.fromScale(0.36, 0.06), UDim2.fromScale(0.5, 0.86), Color3.fromRGB(60, 120, 70), UDim.new(0.5, 0))
	shadow.BackgroundTransparency = 0.3
	local body = circle(gui, "Body", 0.5, 0.5, 0.56, entry.body)
	gradient(body, entry.body:Lerp(WHITE, 0.25), entry.body:Lerp(DARK, 0.2), 90)
	local outline = Instance.new("UIStroke")
	outline.Color = DARK
	outline.Thickness = 5
	outline.Parent = body
	circle(gui, "Belly", 0.26, 0.5, 0.66, entry.accent)
	for _, side in ipairs({ -1, 1 }) do
		circle(gui, "EyeWhite", 0.13, 0.5 + side * 0.08, 0.47, WHITE)
		circle(gui, "EyePupil", 0.06, 0.5 + side * 0.075, 0.48, DARK)
		circle(gui, "Cheek", 0.06, 0.5 + side * 0.15, 0.56, Color3.fromRGB(255, 130, 160))
		local foot = frame(gui, "Foot", UDim2.fromScale(0.1, 0.05), UDim2.fromScale(0.5 + side * 0.08, 0.83), entry.accent, UDim.new(0.5, 0))
		foot.ZIndex = 0
	end
	frame(gui, "Grin", UDim2.fromScale(0.14, 0.04), UDim2.fromScale(0.5, 0.58), DARK, UDim.new(0.5, 0))
	local cap = frame(gui, "Cap", UDim2.fromScale(0.3, 0.05), UDim2.fromScale(0.5, 0.31), DARK, UDim.new(0.2, 0))
	cap.Rotation = -5
	frame(gui, "CapTassel", UDim2.fromScale(0.015, 0.09), UDim2.fromScale(0.63, 0.35), GOLD, UDim.new(0.5, 0))
	local tag = frame(gui, "NameTag", UDim2.fromScale(0.8, 0.14), UDim2.fromScale(0.5, 0.1), DARK, UDim.new(0.3, 0), 0.1)
	local tagStroke = Instance.new("UIStroke")
	tagStroke.Color = Config.RARITY_COLORS[entry.rarity]
	tagStroke.Thickness = 5
	tagStroke.Parent = tag
	text(tag, "Name", entry.name, UDim2.fromScale(0.94, 0.8), UDim2.fromScale(0.5, 0.5), WHITE)
	text(gui, "Caption", caption, UDim2.fromScale(0.9, 0.09), UDim2.fromScale(0.5, 0.93), Config.RARITY_COLORS[entry.rarity])
end

local function buildArena(root)
	local f = folderIn(root, "ArenaPlayground")
	local r = LAYOUT.arenaRadius
	cylinder(f, "ArenaFloor", 0.4, r * 2, onGround(0, G, 0, 0.4), Color3.fromRGB(96, 74, 170), Enum.Material.SmoothPlastic)
	local mural = block(f, "CrestMural", Vector3.new(44, 0.1, 44), onGround(0, G + 0.4, 0, 0.1), Color3.fromRGB(60, 40, 120))
	paintCrest(canvas(mural, Enum.NormalId.Top, 20))
	-- The Arena Drop pad at the crest's heart.
	cylinder(f, "DropRing", 0.3, 8.4, onGround(0, G + 0.5, 0, 0.3), GOLD, Enum.Material.Neon)
	local dropPad = cylinder(f, "DropPad", 0.5, 7, onGround(0, G + 0.5, 0, 0.5), Color3.fromRGB(255, 240, 200), Enum.Material.Marble)
	-- A low wall of 40 segments with four gaps for the entrances.
	local wallColors = { Color3.fromRGB(255, 110, 110), Color3.fromRGB(255, 200, 60), Color3.fromRGB(100, 210, 130), Color3.fromRGB(90, 160, 255) }
	local wallRadius = r + 0.5
	for i = 0, 39 do
		local deg = i * 9 + 4.5
		local nearest = (deg + 45) % 90 - 45
		if math.abs(nearest) > 10 then
			local a = math.rad(deg)
			local cf = CFrame.new(math.sin(a) * wallRadius, G, -math.cos(a) * wallRadius) * CFrame.Angles(0, -a, 0)
			block(f, "ArenaWall", Vector3.new(6, 1.6, 1), cf * CFrame.new(0, 0.8, 0), CREAM, Enum.Material.SmoothPlastic)
			block(f, "ArenaWallCap", Vector3.new(6, 0.3, 1.1), cf * CFrame.new(0, 1.75, 0), wallColors[i % 4 + 1], Enum.Material.Neon)
		end
	end
	-- Entrance arches on the four axes, each naming the arena.
	for i = 0, 3 do
		local a = math.rad(i * 90)
		local outward = Vector3.new(math.sin(a), 0, -math.cos(a))
		local centre = outward * (r + 2.5)
		local arch = CFrame.lookAt(Vector3.new(centre.X, G, centre.Z), Vector3.new(0, G, 0))
		for _, side in ipairs({ -1, 1 }) do
			block(f, "ArchPillar", Vector3.new(1.6, 12, 1.6), arch * CFrame.new(side * 7, 6, 0), VIOLET, Enum.Material.SmoothPlastic)
		end
		local beam = block(f, "ArchBeam", Vector3.new(16, 2.4, 1.6), arch * CFrame.new(0, 13.2, 0), DARK)
		signText(beam, Enum.NormalId.Back, "ARENA", GOLD)
		signText(beam, Enum.NormalId.Front, "PULL [Q] · PUSH [F]", WHITE)
		ball(f, "ArchOrb", 2.2, arch * CFrame.new(0, 15.5, 0), GOLD, Enum.Material.Neon)
	end
	-- Four framed art panels on the diagonals, facing the crest.
	local artPicks = {
		{ "pensil-penguin", "COMMON · $5/s" },
		{ "lunchbox-lion", "RARE · $28/s" },
		{ "pencil-shark", "LEGENDARY · $80/s" },
		{ "ujian-unicorn", "SECRET · $1K/s" },
	}
	for i, pick in ipairs(artPicks) do
		local a = math.rad((i - 1) * 90 + 45)
		local spot = Vector3.new(math.sin(a) * (r + 8), G, -math.cos(a) * (r + 8))
		local cf = CFrame.lookAt(spot, Vector3.new(0, G, 0))
		block(f, "ArtFrame", Vector3.new(17, 11, 0.6), cf * CFrame.new(0, 7.5, 0.5), GOLD, Enum.Material.SmoothPlastic)
		local board = block(f, "ArtBoard", Vector3.new(16, 10, 0.4), cf * CFrame.new(0, 7.5, 0), DARK)
		paintBrainrotArt(canvas(board, Enum.NormalId.Front, 32), Catalog.ById[pick[1]], pick[2])
		local back = canvas(block(f, "ArtBack", Vector3.new(16, 10, 0.2), cf * CFrame.new(0, 7.5, 0.9), DARK), Enum.NormalId.Back, 24)
		text(back, "BackText", "ENCHANTED ACADEMY\nARENA PLAYGROUND", UDim2.fromScale(0.9, 0.7), UDim2.fromScale(0.5, 0.5), GOLD)
		for _, side in ipairs({ -1, 1 }) do
			block(f, "ArtPost", Vector3.new(1, 13, 1), cf * CFrame.new(side * 9, 6.5, 0.5), WOOD_DARK, Enum.Material.Wood)
		end
	end
	-- Spectator benches inside the wall, on the diagonals.
	local seats = {}
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		local spot = Vector3.new(math.sin(a) * 34, G + 0.4, -math.cos(a) * 34)
		local cf = CFrame.lookAt(spot, Vector3.new(0, G + 0.4, 0))
		local seat = make("Seat", f, "BenchSeat", Vector3.new(5, 0.5, 2), cf * CFrame.new(0, 1.45, 0), Color3.fromRGB(190, 135, 75), Enum.Material.WoodPlanks)
		seat.Disabled = true
		block(f, "BenchBack", Vector3.new(5, 2, 0.4), cf * CFrame.new(0, 2.7, 0.8), WOOD_DARK, Enum.Material.Wood)
		for _, legX in ipairs({ -2, 2 }) do
			block(f, "BenchLeg", Vector3.new(0.5, 1.2, 1.8), cf * CFrame.new(legX, 0.6, 0), DARK, Enum.Material.Metal)
		end
		table.insert(seats, { kind = "Bench", seat = seat, prompt = prompt(seat, "Sit", "Bench · Fresh buff", 8) })
	end
	-- Mascot statues flanking the north path, built by BrainrotFactory at x3.
	for i, pick in ipairs({ { "pensil-penguin", -20 }, { "lunchbox-lion", 20 } }) do
		local entry = Catalog.ById[pick[1]]
		local plinth = block(f, "StatuePlinth", Vector3.new(8, 2, 8), onGround(pick[2], G, -62, 2), STONE, Enum.Material.Marble)
		signText(plinth, Enum.NormalId.Back, entry.name, GOLD)
		local statue = BrainrotFactory.Build(entry, i == 2 and "GOLD" or nil, "statue" .. i, {
			scale = 2.6,
			origin = CFrame.new(pick[2], G + 2, -62) * CFrame.Angles(0, math.rad(180), 0),
			noLabel = true,
		})
		statue.Name = "Statue_" .. entry.name
		statue.Parent = f
	end
	-- The playground: two swing sets south of the arena, facing it.
	for _, sx in ipairs({ -26, 26 }) do
		local z = 58
		for _, px in ipairs({ -5, 5 }) do
			block(f, "SwingPole", Vector3.new(0.6, 8, 0.6), onGround(sx + px, G, z, 8), Color3.fromRGB(230, 80, 80), Enum.Material.Metal)
		end
		block(f, "SwingBar", Vector3.new(10.6, 0.5, 0.5), CFrame.new(sx, G + 8.25, z), Color3.fromRGB(230, 80, 80), Enum.Material.Metal)
		for _, offset in ipairs({ -2.2, 2.2 }) do
			for _, chain in ipairs({ -0.9, 0.9 }) do
				block(f, "SwingChain", Vector3.new(0.15, 5.6, 0.15), CFrame.new(sx + offset + chain, G + 5.2, z), Color3.fromRGB(190, 190, 200), Enum.Material.Metal)
			end
			local seat = make("Seat", f, "SwingSeat", Vector3.new(2.2, 0.4, 1.4), CFrame.new(sx + offset, G + 2.2, z) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(90, 160, 255), Enum.Material.SmoothPlastic)
			seat.Disabled = true
			table.insert(seats, { kind = "Swing", seat = seat, prompt = prompt(seat, "Sit", "Swing · Fresh buff", 8) })
		end
	end
	return dropPad, seats
end

---------------------------------------------------------------------------
-- Classroom bases: a platform, three walls, an arch with the owner's name,
-- pedestal rows, a lock shield and a laser gate. All in the base's frame:
-- local -Z faces the arena.
---------------------------------------------------------------------------
function WorldBuilder.BaseLayout(index)
	local side = index <= 4 and -1 or 1
	local z = LAYOUT.baseRowZ[(index - 1) % 4 + 1]
	local centre = Vector3.new(side * LAYOUT.baseRowX, G, z)
	local cf = CFrame.lookAt(centre, centre + Vector3.new(-side, 0, 0))
	return cf, side
end

function WorldBuilder.PedestalLocal(slot)
	local row = math.floor((slot - 1) / Config.PEDESTALS_PER_ROW)
	local col = (slot - 1) % Config.PEDESTALS_PER_ROW
	return Vector3.new(-8.25 + col * 5.5, 0, 9 - row * 5.5)
end

local function buildBase(root, index)
	local cf, side = WorldBuilder.BaseLayout(index)
	local color = BASE_COLORS[index]
	local f = folderIn(root, "Classroom" .. index)
	local half = LAYOUT.baseHalf
	local floorTop = 0.6
	block(f, "Platform", Vector3.new(half * 2, floorTop, half * 2), cf * CFrame.new(0, floorTop / 2, 0), color, Enum.Material.SmoothPlastic)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "Ramp"
	ramp.Size = Vector3.new(12, floorTop, 3)
	ramp.CFrame = cf * CFrame.new(0, floorTop / 2, -half - 1.5)
	ramp.Color = color
	ramp.Material = Enum.Material.SmoothPlastic
	ramp.Anchored = true
	ramp.Parent = f
	local wallHeight = 5
	block(f, "BackWall", Vector3.new(half * 2, wallHeight, 1), cf * CFrame.new(0, floorTop + wallHeight / 2, half - 0.5), CREAM, Enum.Material.Brick)
	for _, sx in ipairs({ -1, 1 }) do
		block(f, "SideWall", Vector3.new(1, wallHeight, half * 2 - 1), cf * CFrame.new(sx * (half - 0.5), floorTop + wallHeight / 2, -0.5), CREAM, Enum.Material.Brick)
		block(f, "SideTrim", Vector3.new(1.2, 0.4, half * 2 - 1.1), cf * CFrame.new(sx * (half - 0.5), floorTop + wallHeight + 0.2, -0.55), color, Enum.Material.Neon)
	end
	block(f, "BackTrim", Vector3.new(half * 2, 0.4, 1.2), cf * CFrame.new(0, floorTop + wallHeight + 0.2, half - 0.5), color, Enum.Material.Neon)
	-- Chalkboard on the back wall: the classroom look.
	local board = block(f, "Chalkboard", Vector3.new(14, 3, 0.2), cf * CFrame.new(0, floorTop + 3, half - 1.1), Color3.fromRGB(40, 75, 55))
	local chalk = canvas(board, Enum.NormalId.Front, 30)
	text(chalk, "Chalk", "KELAS " .. index .. "  ·  2 + 2 = BRAINROT", UDim2.fromScale(0.92, 0.6), UDim2.fromScale(0.5, 0.5), WHITE, Enum.Font.PatrickHand)
	-- Entrance arch carrying the owner sign.
	for _, sx in ipairs({ -1, 1 }) do
		block(f, "ArchPillar", Vector3.new(1.5, 8, 1.5), cf * CFrame.new(sx * 12, floorTop + 4, -half + 1), WOOD_DARK, Enum.Material.Wood)
	end
	local beam = block(f, "ArchBeam", Vector3.new(26, 2.6, 1.5), cf * CFrame.new(0, floorTop + 8 + 1.3, -half + 1), DARK)
	local gui = canvas(beam, Enum.NormalId.Front, 30)
	local back = frame(gui, "Back", UDim2.fromScale(0.98, 0.9), UDim2.fromScale(0.5, 0.5), DARK, UDim.new(0.2, 0))
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 5
	stroke.Parent = back
	local nameLabel = text(back, "OwnerName", "CLASSROOM " .. index .. " · FREE", UDim2.fromScale(0.95, 0.56), UDim2.fromScale(0.5, 0.33), WHITE)
	local statusLabel = text(back, "Status", "OPEN · HOLD [E] TO STEAL", UDim2.fromScale(0.95, 0.36), UDim2.fromScale(0.5, 0.76), Color3.fromRGB(255, 130, 130), Enum.Font.GothamBlack)
	-- Lock shield and laser gate: invisible until the base is locked.
	local shield = block(f, "LockShield", Vector3.new(30, 14, 30), cf * CFrame.new(0, floorTop + 7, 0), Color3.fromRGB(90, 170, 255), Enum.Material.ForceField)
	shield.Transparency = 1
	shield.CanCollide = false
	shield.CanQuery = false
	shield.CanTouch = false
	shield.CastShadow = false
	local gate = block(f, "LaserGate", Vector3.new(22.5, 7.6, 0.3), cf * CFrame.new(0, floorTop + 3.8, -half + 1), Color3.fromRGB(255, 70, 90), Enum.Material.Neon)
	gate.Transparency = 1
	gate.CanCollide = false
	gate.CanQuery = false
	gate.CanTouch = false
	gate.CastShadow = false

	local base = {
		index = index,
		side = side,
		cframe = cf,
		center = (cf * CFrame.new(0, floorTop, 0)).Position,
		door = (cf * CFrame.new(0, 0, -half - 4)).Position,
		floorTop = G + floorTop,
		folder = f,
		nameLabel = nameLabel,
		statusLabel = statusLabel,
		color = color,
		shield = shield,
		gate = gate,
		owner = nil,
		pedestals = {},
		pedestalRows = 0,
	}
	for _ = 1, Config.START_PEDESTAL_ROWS do
		WorldBuilder.AddPedestalRow(base)
	end
	return base
end

-- Adds one row of four pedestals. Rows 3 and 4 come from Extra Slot.
function WorldBuilder.AddPedestalRow(base)
	if base.pedestalRows >= Config.MAX_PEDESTAL_ROWS then
		return
	end
	base.pedestalRows += 1
	for col = 1, Config.PEDESTALS_PER_ROW do
		local slot = (base.pedestalRows - 1) * Config.PEDESTALS_PER_ROW + col
		local localPosition = WorldBuilder.PedestalLocal(slot)
		local floorTop = 0.6
		local columnCf = base.cframe * CFrame.new(localPosition.X, floorTop, localPosition.Z)
		local column = cylinder(base.folder, "Pedestal", 1.4, 3.6, columnCf * CFrame.new(0, 0.7, 0), Color3.fromRGB(245, 245, 250), Enum.Material.Marble)
		column:SetAttribute("Slot", slot)
		local ring = cylinder(base.folder, "PedestalRing", 0.2, 3.9, columnCf * CFrame.new(0, 1.5, 0), Color3.fromRGB(200, 200, 210), Enum.Material.Neon)
		local clicker = Instance.new("ClickDetector")
		clicker.Name = "PlaceClicker"
		clicker.MaxActivationDistance = 30
		clicker.Parent = column
		local record = {
			id = "b" .. base.index .. "p" .. slot,
			slot = slot,
			part = column,
			ring = ring,
			clicker = clicker,
			top = columnCf * CFrame.new(0, 1.6, 0),
		}
		record.position = record.top.Position
		table.insert(base.pedestals, record)
		if WorldBuilder.OnPedestalAdded then
			WorldBuilder.OnPedestalAdded(base, record)
		end
	end
end

-- Back to two rows: a base changing hands never keeps bought slots.
function WorldBuilder.ResetPedestalRows(base)
	local keep = Config.START_PEDESTAL_ROWS * Config.PEDESTALS_PER_ROW
	for i = #base.pedestals, keep + 1, -1 do
		local record = base.pedestals[i]
		record.part:Destroy()
		record.ring:Destroy()
		table.remove(base.pedestals, i)
	end
	base.pedestalRows = Config.START_PEDESTAL_ROWS
end

---------------------------------------------------------------------------
-- South side: the station row, the spawn plaza, Cafeteria and Gym.
---------------------------------------------------------------------------
local function buildStations(root)
	local f = folderIn(root, "Stations")
	local z = LAYOUT.stationZ
	local stations = {}
	-- Gacha Machine.
	local gacha = folderIn(f, "GachaMachine")
	local gx = -90
	local gachaBody = block(gacha, "GachaBody", Vector3.new(6, 7, 5), onGround(gx, G, z, 7), Color3.fromRGB(230, 70, 80))
	signText(gachaBody, Enum.NormalId.Front, "GACHA $1K", WHITE, Color3.fromRGB(150, 30, 50))
	local dome = ball(gacha, "GachaDome", 5.4, CFrame.new(gx, G + 9.7, z), Color3.fromRGB(210, 235, 255), Enum.Material.Glass)
	dome.Transparency = 0.35
	local capsuleColors = { Color3.fromRGB(255, 95, 95), Color3.fromRGB(255, 205, 60), Color3.fromRGB(95, 205, 125), Color3.fromRGB(95, 155, 255), Color3.fromRGB(205, 125, 255) }
	for i, capsuleColor in ipairs(capsuleColors) do
		local a = math.rad(i * 72)
		ball(gacha, "Capsule", 1.2, CFrame.new(gx + math.cos(a) * 1.2, G + 8.6 + (i % 2) * 0.9, z + math.sin(a) * 1.2), capsuleColor, Enum.Material.Neon)
	end
	ball(gacha, "DomeStar", 1.2, CFrame.new(gx, G + 13, z), GOLD, Enum.Material.Neon)
	stations.gacha = prompt(gachaBody, "Gacha", "Gacha Machine · $1,000", 12)
	-- Upgrade Shop kiosk.
	local shop = folderIn(f, "UpgradeShop")
	local sx = -45
	local counter = block(shop, "Counter", Vector3.new(10, 3.5, 3), onGround(sx, G, z - 1.5, 3.5), Color3.fromRGB(255, 160, 50), Enum.Material.WoodPlanks)
	block(shop, "BackPanel", Vector3.new(10, 8, 1), onGround(sx, G, z + 2.5, 8), WOOD_DARK, Enum.Material.Wood)
	for _, px in ipairs({ -4.5, 4.5 }) do
		block(shop, "AwningPost", Vector3.new(0.6, 4.5, 0.6), onGround(sx + px, G + 3.5, z - 2.5, 4.5), WHITE, Enum.Material.Metal)
	end
	for i = 0, 4 do
		block(shop, "Awning", Vector3.new(2, 0.4, 6), CFrame.new(sx - 4 + i * 2, G + 8.2, z - 0.5), i % 2 == 0 and Color3.fromRGB(255, 160, 50) or WHITE)
	end
	local shopSign = block(shop, "ShopSign", Vector3.new(9, 2.2, 0.3), CFrame.new(sx, G + 6.5, z + 1.85), DARK)
	signText(shopSign, Enum.NormalId.Front, "UPGRADES", GOLD)
	stations.upgrades = prompt(counter, "Shop", "Upgrade Shop", 12)
	-- Quest Board.
	local board = folderIn(f, "QuestBoard")
	for _, px in ipairs({ -10, 10 }) do
		block(board, "BoardPost", Vector3.new(1, 13, 1), onGround(px, G, z + 4, 13), WOOD_DARK, Enum.Material.Wood)
	end
	local questBoard = block(board, "Board", Vector3.new(19, 9, 0.6), CFrame.new(0, G + 7.5, z + 4), Color3.fromRGB(60, 40, 110))
	local qgui = canvas(questBoard, Enum.NormalId.Front, 30)
	local qbg = frame(qgui, "Back", UDim2.fromScale(0.96, 0.92), UDim2.fromScale(0.5, 0.5), DARK, UDim.new(0.08, 0))
	local qstroke = Instance.new("UIStroke")
	qstroke.Color = GOLD
	qstroke.Thickness = 6
	qstroke.Parent = qbg
	text(qbg, "Title", "QUEST BOARD", UDim2.fromScale(0.9, 0.22), UDim2.fromScale(0.5, 0.16), GOLD)
	for i, line in ipairs({ "1  Buy · Place · Earn · Lock", "2  PULL [Q] · PUSH [F] · STEAL [E]", "3  Survive the Lunch Rush", "4  Fuse · Collect · Rebirth" }) do
		text(qbg, "Line" .. i, line, UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0.5, 0.34 + (i - 1) * 0.17), WHITE, Enum.Font.GothamBold)
	end
	stations.quests = prompt(questBoard, "Quests", "Quest Board", 14)
	-- Rebirth Altar.
	local altar = folderIn(f, "RebirthAltar")
	local ax = 45
	local dais = cylinder(altar, "Dais", 0.8, 10, onGround(ax, G, z, 0.8), STONE, Enum.Material.Marble)
	cylinder(altar, "AltarStone", 3, 3.5, onGround(ax, G + 0.8, z, 3), Color3.fromRGB(120, 100, 150), Enum.Material.Slate)
	local crystal = block(altar, "RebirthCrystal", Vector3.new(2.6, 2.6, 2.6), CFrame.new(ax, G + 7.2, z) * CFrame.Angles(math.rad(45), 0, math.rad(45)), VIOLET, Enum.Material.Neon)
	crystal:SetAttribute("Floating", true)
	local glow = Instance.new("PointLight")
	glow.Color = VIOLET
	glow.Range = 16
	glow.Brightness = 2
	glow.Parent = crystal
	local altarSign = block(altar, "AltarSign", Vector3.new(9, 2.2, 0.4), onGround(ax, G + 0.8, z + 3.6, 2.2), DARK)
	signText(altarSign, Enum.NormalId.Front, "REBIRTH", VIOLET)
	stations.rebirth = prompt(dais, "Rebirth", "Rebirth Altar", 12)
	-- Fuse Lab.
	local lab = folderIn(f, "FuseLab")
	local lx = 90
	local hall = block(lab, "LabHall", Vector3.new(12, 9, 9), onGround(lx, G, z + 1.5, 9), Color3.fromRGB(240, 240, 248))
	block(lab, "LabRoof", Vector3.new(13, 1, 10), onGround(lx, G + 9, z + 1.5, 1), PURPLE)
	local tube = cylinder(lab, "FusionTube", 7, 3.5, onGround(lx, G, z - 5.2, 7), Color3.fromRGB(170, 90, 255), Enum.Material.Neon)
	tube.Transparency = 0.25
	for _, bx in ipairs({ -4, 4 }) do
		block(lab, "BeakerStand", Vector3.new(1.6, 2, 1.6), onGround(lx + bx, G, z - 4.5, 2), Color3.fromRGB(200, 200, 215), Enum.Material.Metal)
		cylinder(lab, "Beaker", 2, 1.2, onGround(lx + bx, G + 2, z - 4.5, 2), bx < 0 and Color3.fromRGB(90, 230, 120) or Color3.fromRGB(90, 180, 255), Enum.Material.Neon)
	end
	local labSign = block(lab, "LabSign", Vector3.new(10, 2.2, 0.3), CFrame.new(lx, G + 7.4, z - 3.15), DARK)
	signText(labSign, Enum.NormalId.Front, "FUSE LAB", Color3.fromRGB(210, 170, 255))
	stations.fuse = prompt(hall, "Fuse", "Fuse Lab · 3 same tier = 1 higher", 12)
	return stations
end

local function buildCorners(root)
	-- Cafeteria (south-west).
	local cafe = folderIn(root, "Cafeteria")
	local cx, cz = -140, 150
	block(cafe, "CafeHall", Vector3.new(30, 14, 20), onGround(cx, G, cz, 14), Color3.fromRGB(255, 222, 165), Enum.Material.Brick)
	block(cafe, "CafeRoof", Vector3.new(32, 1.5, 22), onGround(cx, G + 14, cz, 1.5), Color3.fromRGB(220, 85, 85))
	for i = 0, 5 do
		block(cafe, "Awning", Vector3.new(4.5, 0.4, 4), CFrame.new(cx - 11.25 + i * 4.5, G + 10.2, cz - 12), i % 2 == 0 and Color3.fromRGB(230, 80, 80) or WHITE)
	end
	local cafeSign = block(cafe, "CafeSign", Vector3.new(20, 3.5, 0.4), CFrame.new(cx, G + 12.2, cz - 10.2), WHITE)
	signText(cafeSign, Enum.NormalId.Front, "CAFETERIA", Color3.fromRGB(200, 60, 60), WHITE)
	for _, tx in ipairs({ -150, -140, -130 }) do
		block(cafe, "TableTop", Vector3.new(6, 0.5, 3), CFrame.new(tx, G + 2.75, 128), Color3.fromRGB(185, 135, 75), Enum.Material.WoodPlanks)
		block(cafe, "TableLeg", Vector3.new(0.8, 2.5, 0.8), onGround(tx, G, 128, 2.5), WOOD_DARK, Enum.Material.Wood)
	end
	-- Gym (south-east) with the climbing truss to its roof pad.
	local gym = folderIn(root, "Gym")
	local gx, gz = 140, 150
	block(gym, "GymHall", Vector3.new(36, 18, 24), onGround(gx, G, gz, 18), Color3.fromRGB(95, 145, 230))
	block(gym, "GymRoof", Vector3.new(38, 1.5, 26), onGround(gx, G + 18, gz, 1.5), Color3.fromRGB(60, 100, 190))
	block(gym, "GymDoor", Vector3.new(8, 10, 0.4), onGround(gx, G, gz - 12.2, 10), Color3.fromRGB(40, 60, 120))
	local gymSign = block(gym, "GymSign", Vector3.new(16, 3.5, 0.4), CFrame.new(gx, G + 14, gz - 12.2), WHITE)
	signText(gymSign, Enum.NormalId.Front, "GYM", Color3.fromRGB(40, 80, 180), WHITE)
	block(gym, "ClimbWall", Vector3.new(0.5, 18, 14), onGround(gx - 18.25, G, gz, 18), Color3.fromRGB(205, 175, 135), Enum.Material.Sand)
	local holdColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 120), Color3.fromRGB(90, 150, 255) }
	for row = 1, 5 do
		for col = 0, 2 do
			block(gym, "Hold", Vector3.new(0.6, 1, 1.4), CFrame.new(gx - 18.8, G + row * 3, gz - 4 + col * 4 + (row % 2)), holdColors[(row + col) % 4 + 1], Enum.Material.Neon)
		end
	end
	make("TrussPart", gym, "GymTruss", Vector3.new(2, 20, 2), onGround(gx - 20, G, gz - 6, 20), DARK, Enum.Material.Metal)
	return Vector3.new(gx - 13, G + 19.5, gz - 6)
end

-- High pads: the free Mythic-or-better perches up high.
local function buildHighPads(root, spots)
	local f = folderIn(root, "HighPads")
	local pads = {}
	for _, spot in ipairs(spots) do
		local pad = cylinder(f, "HighPad", 0.6, 6, onGround(spot.position.X, spot.position.Y, spot.position.Z, 0.6), GOLD, Enum.Material.Neon)
		table.insert(pads, { name = spot.name, padPart = pad, top = CFrame.new(spot.position + Vector3.new(0, 0.6, 0)), occupiedUid = nil })
	end
	return pads
end

---------------------------------------------------------------------------
-- Lighting: warm afternoon with atmosphere, bloom and colour grading.
---------------------------------------------------------------------------
function WorldBuilder.SetupLighting(lighting)
	lighting.ClockTime = 14.6
	lighting.Brightness = 2.6
	lighting.Ambient = Color3.fromRGB(110, 104, 132)
	lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 165)
	lighting.EnvironmentDiffuseScale = 0.6
	lighting.EnvironmentSpecularScale = 0.6
	lighting.GlobalShadows = true
	local function ensure(className, name)
		local existing = lighting:FindFirstChild(name)
		if existing then
			return existing
		end
		local effect = Instance.new(className)
		effect.Name = name
		effect.Parent = lighting
		return effect
	end
	local atmosphere = ensure("Atmosphere", "AcademyAtmosphere")
	atmosphere.Density = 0.27
	atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(205, 195, 235)
	atmosphere.Decay = Color3.fromRGB(125, 110, 175)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.1
	local bloom = ensure("BloomEffect", "AcademyBloom")
	bloom.Intensity = 0.55
	bloom.Size = 24
	bloom.Threshold = 1.5
	local grade = ensure("ColorCorrectionEffect", "AcademyGrade")
	grade.Saturation = 0.18
	grade.Contrast = 0.08
	grade.Brightness = 0.02
	grade.TintColor = Color3.fromRGB(255, 249, 242)
	local rays = ensure("SunRaysEffect", "AcademySunRays")
	rays.Intensity = 0.05
	rays.Spread = 0.6
end

---------------------------------------------------------------------------
-- Build: everything under one root folder. The edit-time preview saved in
-- the place is replaced by a fresh build, so the records below always point
-- at live parts.
---------------------------------------------------------------------------
function WorldBuilder.Build(parent)
	if world then
		return world
	end
	parent = parent or workspace
	local old = parent:FindFirstChild(WorldBuilder.ROOT_NAME)
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = WorldBuilder.ROOT_NAME
	buildGround(root)
	buildAcademy(root)
	local towerTop = buildTower(root)
	local treeTop = buildBigTree(root)
	local paradeStart, paradeEnd = buildParadeLane(root)
	local dropPad, seats = buildArena(root)
	local stations = buildStations(root)
	local gymTop = buildCorners(root)
	local bases = {}
	local basesFolder = folderIn(root, "Classrooms")
	for i = 1, Config.BASE_COUNT do
		bases[i] = buildBase(basesFolder, i)
	end
	local highPads = buildHighPads(root, {
		{ name = "Wizard Tower", position = towerTop },
		{ name = "Big Tree", position = treeTop },
		{ name = "Gym Roof", position = gymTop },
	})
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StudentSpawn"
	spawn.Size = Vector3.new(12, 0.6, 12)
	spawn.CFrame = onGround(0, G, LAYOUT.spawnZ, 0.6)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(120, 220, 110)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = root
	root.Parent = parent

	world = {
		root = root,
		bases = bases,
		highPads = highPads,
		arenaPad = { name = "Arena Crest", padPart = dropPad, top = CFrame.new(0, G + 1, 0), occupiedUid = nil },
		stations = stations,
		seats = seats,
		paradeStart = paradeStart,
		paradeEnd = paradeEnd,
		treeTop = treeTop + Vector3.new(-4, 3, -4),
		nestDrop = treeTop + Vector3.new(3, 0, 3),
		spawn = spawn,
	}
	return world
end

function WorldBuilder.GetWorld()
	return world
end

function WorldBuilder.GetBases()
	return world and world.bases or {}
end

function WorldBuilder.GetBase(index)
	return world and world.bases[index] or nil
end

-- Which base a point stands in (platform footprint, up to the shield top).
function WorldBuilder.BaseAtPosition(position)
	if not world then
		return nil
	end
	for _, base in ipairs(world.bases) do
		local offset = base.cframe:PointToObjectSpace(position)
		if math.abs(offset.X) <= LAYOUT.baseHalf + 0.5 and math.abs(offset.Z) <= LAYOUT.baseHalf + 0.5 and offset.Y < 16 then
			return base.index
		end
	end
	return nil
end

function WorldBuilder.GetFreePedestal(base, placed)
	for _, pedestal in ipairs(base.pedestals) do
		if not placed[pedestal.id] then
			return pedestal
		end
	end
	return nil
end

-- Ground height under a point, for NPCs walking the yard.
function WorldBuilder.GroundHeightAt(x, z)
	local distance = math.sqrt(x * x + z * z)
	if distance <= 3.5 then
		return G + 1 -- the Arena Drop pad
	elseif math.abs(x) <= 22 and math.abs(z) <= 22 then
		return G + 0.5
	elseif distance <= LAYOUT.arenaRadius then
		return G + 0.4
	end
	local index = WorldBuilder.BaseAtPosition(Vector3.new(x, G + 1, z))
	if index then
		return G + 0.6
	end
	return G + 0.2
end

-- Owner sign and lock visuals.
function WorldBuilder.SetBaseOwnerName(base, ownerName)
	base.nameLabel.Text = ownerName and (string.upper(ownerName) .. "'S CLASS") or ("CLASSROOM " .. base.index .. " · FREE")
end

function WorldBuilder.SetBaseLockVisual(base, locked, secondsLeft)
	base.shield.Transparency = locked and 0.6 or 1
	base.gate.Transparency = locked and 0.35 or 1
	if locked then
		base.statusLabel.Text = "LOCKED " .. (secondsLeft or 0) .. "s"
		base.statusLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
	else
		base.statusLabel.Text = "OPEN · HOLD [E] TO STEAL"
		base.statusLabel.TextColor3 = Color3.fromRGB(255, 130, 130)
	end
end

return WorldBuilder
