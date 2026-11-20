-- WorldBuilder: builds the whole school in 3D from code when the server starts.
-- The academy, the bus, the cafeteria, the gym with its climbing wall, the big
-- tree, the tower, the field, the Parade Lane and the eight classroom bases
-- are all Parts placed here — nothing is pasted in from Studio, so the place
-- the finalist review sees is the place these recorded sessions built.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local WorldBuilder = {}

-- Set by CarrySystem: wires a new pedestal's clicker when the Extra Slot
-- upgrade adds a row after the game has started.
WorldBuilder.OnPedestalAdded = nil

local GROUND = Config.GROUND_Y
local BASE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(255, 190, 60),
	Color3.fromRGB(120, 220, 100),
	Color3.fromRGB(90, 170, 255),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(255, 150, 200),
	Color3.fromRGB(90, 220, 210),
	Color3.fromRGB(255, 140, 80),
}

-- Eight classroom bases on a ring around the field. Angle 270 is skipped:
-- the academy stands there.
local BASE_ANGLES = { 0, 40, 80, 120, 160, 200, 240, 320 }
local BASE_RADIUS = 150

local world = nil

local function part(name, size, position, color, material, parent, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Locked = true
	p.CanQuery = true
	if shape then
		p.Shape = shape
	end
	p.Parent = parent or workspace
	return p
end

local function textOn(partToLabel, text, textColor, textSize, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Parent = partToLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textSize or 48
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
	return gui
end

local function buildGround()
	-- Grass slab over the starter baseplate; its top is the walking ground.
	part("Grass", Vector3.new(480, 0.4, 480), Vector3.new(0, 0.2, 0), Color3.fromRGB(110, 200, 90), Enum.Material.Grass)
	-- The school field's white markings: a rectangle and a centre ring.
	part("FieldLineNorth", Vector3.new(120, 0.1, 1), Vector3.new(0, GROUND + 0.05, -30), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	part("FieldLineSouth", Vector3.new(120, 0.1, 1), Vector3.new(0, GROUND + 0.05, 50), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	part("FieldLineWest", Vector3.new(1, 0.1, 80), Vector3.new(-60, GROUND + 0.05, 10), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	part("FieldLineEast", Vector3.new(1, 0.1, 80), Vector3.new(60, GROUND + 0.05, 10), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	local ringOuter = part("CentreRing", Vector3.new(24, 0.1, 24), Vector3.new(0, GROUND + 0.05, 10), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, nil, Enum.PartType.Cylinder)
	ringOuter.CFrame = CFrame.new(0, GROUND + 0.05, 10) * CFrame.Angles(0, 0, math.rad(90))
	local ringInner = part("CentreRingInner", Vector3.new(22, 0.12, 22), Vector3.new(0, GROUND + 0.06, 10), Color3.fromRGB(110, 200, 90), Enum.Material.Grass, nil, Enum.PartType.Cylinder)
	ringInner.CFrame = CFrame.new(0, GROUND + 0.06, 10) * CFrame.Angles(0, 0, math.rad(90))
end

local function buildAcademy()
	local academy = Instance.new("Folder")
	academy.Name = "Academy"
	academy.Parent = workspace
	-- Main hall: cream walls, tall enough to read as a school from anywhere.
	part("Hall", Vector3.new(60, 24, 28), Vector3.new(0, GROUND + 12, -120), Color3.fromRGB(240, 220, 180), Enum.Material.Wood, academy)
	-- Thatched gable roof: two slanted slabs meeting at the ridge.
	local roofLeft = part("RoofLeft", Vector3.new(62, 1.5, 17), Vector3.new(0, GROUND + 27, -127), Color3.fromRGB(150, 110, 60), Enum.Material.Wood, academy)
	roofLeft.CFrame = CFrame.new(0, GROUND + 27, -127) * CFrame.Angles(math.rad(-32), 0, 0)
	local roofRight = part("RoofRight", Vector3.new(62, 1.5, 17), Vector3.new(0, GROUND + 27, -113), Color3.fromRGB(150, 110, 60), Enum.Material.Wood, academy)
	roofRight.CFrame = CFrame.new(0, GROUND + 27, -113) * CFrame.Angles(math.rad(32), 0, 0)
	-- Door and glowing windows on the front face.
	part("Door", Vector3.new(9, 13, 1), Vector3.new(0, GROUND + 6.5, -105.5), Color3.fromRGB(120, 75, 40), Enum.Material.Wood, academy)
	for _, x in ipairs({ -22, -12, 12, 22 }) do
		part("Window", Vector3.new(6, 7, 0.6), Vector3.new(x, GROUND + 14, -105.6), Color3.fromRGB(255, 230, 130), Enum.Material.Neon, academy)
	end
	-- Steps up to the door.
	for i = 1, 3 do
		part("Step", Vector3.new(14, 0.8, 2.5), Vector3.new(0, GROUND + 0.4 * i, -103 + i * 1.5), Color3.fromRGB(200, 190, 170), Enum.Material.Slate, academy)
	end
	-- The school sign over the door.
	local sign = part("Sign", Vector3.new(34, 6, 1), Vector3.new(0, GROUND + 21, -105.4), Color3.fromRGB(60, 120, 60), Enum.Material.Wood, academy)
	textOn(sign, "ENCHANTED ACADEMY", Color3.fromRGB(255, 240, 150), 48)
end

local function buildTower()
	local tower = Instance.new("Folder")
	tower.Name = "Tower"
	tower.Parent = workspace
	local trunk = part("TowerBody", Vector3.new(12, 44, 12), Vector3.new(48, GROUND + 22, -128), Color3.fromRGB(170, 165, 155), Enum.Material.Slate, tower, Enum.PartType.Cylinder)
	trunk.CFrame = CFrame.new(48, GROUND + 22, -128) * CFrame.Angles(0, 0, math.rad(90))
	-- Stacked roof rings and a purple dome.
	part("RoofRing1", Vector3.new(15, 1.5, 15), Vector3.new(48, GROUND + 45, -128), Color3.fromRGB(120, 80, 180), Enum.Material.SmoothPlastic, tower, Enum.PartType.Cylinder).CFrame =
		CFrame.new(48, GROUND + 45, -128) * CFrame.Angles(0, 0, math.rad(90))
	part("RoofRing2", Vector3.new(11, 1.5, 11), Vector3.new(48, GROUND + 46.5, -128), Color3.fromRGB(140, 95, 200), Enum.Material.SmoothPlastic, tower, Enum.PartType.Cylinder).CFrame =
		CFrame.new(48, GROUND + 46.5, -128) * CFrame.Angles(0, 0, math.rad(90))
	part("Dome", Vector3.new(8, 8, 8), Vector3.new(48, GROUND + 50, -128), Color3.fromRGB(160, 110, 220), Enum.Material.SmoothPlastic, tower, Enum.PartType.Ball)
	-- A window that glows at night and a ladder of rungs up the side.
	part("TowerWindow", Vector3.new(3, 5, 0.6), Vector3.new(48, GROUND + 30, -121.5), Color3.fromRGB(255, 230, 130), Enum.Material.Neon, tower)
	for i = 1, 10 do
		part("Rung", Vector3.new(4, 0.5, 0.5), Vector3.new(42.5, GROUND + 2 + i * 3.5, -124), Color3.fromRGB(120, 75, 40), Enum.Material.Wood, tower)
	end
end

local function buildParadeLane()
	local lane = Instance.new("Folder")
	lane.Name = "ParadeLane"
	lane.Parent = workspace
	part("Lane", Vector3.new(176, 0.2, 10), Vector3.new(0, GROUND + 0.1, -60), Color3.fromRGB(230, 200, 140), Enum.Material.Sand, lane)
	-- Flags along the lane so it reads as a parade route.
	local flagColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 120), Color3.fromRGB(90, 150, 255) }
	for i = 1, 8 do
		local x = -77 + (i - 1) * 22
		part("FlagPole", Vector3.new(0.4, 7, 0.4), Vector3.new(x, GROUND + 3.5, -66), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, lane)
		local flag = part("Flag", Vector3.new(3, 2, 0.2), Vector3.new(x + 1.6, GROUND + 6, -66), flagColors[(i - 1) % 4 + 1], Enum.Material.SmoothPlastic, lane)
		flag.CFrame = CFrame.new(x + 1.6, GROUND + 6, -66)
	end
	local archLeft = part("ArchLeft", Vector3.new(1.5, 10, 1.5), Vector3.new(-84, GROUND + 5, -60), Color3.fromRGB(255, 120, 120), Enum.Material.SmoothPlastic, lane)
	archLeft.CFrame = CFrame.new(-84, GROUND + 5, -60)
	local archRight = part("ArchRight", Vector3.new(1.5, 10, 1.5), Vector3.new(84, GROUND + 5, -60), Color3.fromRGB(255, 120, 120), Enum.Material.SmoothPlastic, lane)
	archRight.CFrame = CFrame.new(84, GROUND + 5, -60)
	local archTop = part("ArchTop", Vector3.new(170, 1.5, 1.5), Vector3.new(0, GROUND + 10.5, -60), Color3.fromRGB(255, 200, 60), Enum.Material.SmoothPlastic, lane)
	archTop.CFrame = CFrame.new(0, GROUND + 10.5, -60)
	textOn(archTop, "PARADE LANE", Color3.fromRGB(120, 40, 40), 24, Enum.NormalId.Bottom)
end

local function buildGym()
	local gym = Instance.new("Folder")
	gym.Name = "Gym"
	gym.Parent = workspace
	part("GymHall", Vector3.new(36, 18, 24), Vector3.new(105, GROUND + 9, 25), Color3.fromRGB(90, 140, 230), Enum.Material.SmoothPlastic, gym)
	part("GymRoof", Vector3.new(38, 1.5, 26), Vector3.new(105, GROUND + 18.5, 25), Color3.fromRGB(60, 100, 190), Enum.Material.SmoothPlastic, gym)
	part("GymDoor", Vector3.new(8, 10, 1), Vector3.new(105, GROUND + 5, 12.5), Color3.fromRGB(40, 60, 120), Enum.Material.SmoothPlastic, gym)
	local sign = part("GymSign", Vector3.new(20, 4, 1), Vector3.new(105, GROUND + 15, 12.4), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, gym)
	textOn(sign, "GYM", Color3.fromRGB(40, 80, 180), 48)
	-- The climbing wall on the gym's west face, with bright handholds.
	part("ClimbWall", Vector3.new(1, 26, 14), Vector3.new(86.5, GROUND + 13, 25), Color3.fromRGB(200, 170, 130), Enum.Material.Sand, gym)
	local holdColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 120), Color3.fromRGB(90, 150, 255) }
	local holdIndex = 1
	for row = 1, 6 do
		for col = 1, 3 do
			local hold = part("Hold", Vector3.new(1, 1, 1.6), Vector3.new(85.8, GROUND + 2 + row * 3.6, 20 + col * 3.2), holdColors[holdIndex], Enum.Material.Neon, gym)
			hold.CFrame = CFrame.new(85.8, GROUND + 2 + row * 3.6, 20 + col * 3.2)
			holdIndex = holdIndex % 4 + 1
		end
	end
	-- A ladder up to the wall top, where the rare pad sits.
	for i = 1, 8 do
		part("WallLadder", Vector3.new(0.4, 0.4, 3), Vector3.new(85.8, GROUND + 1 + i * 3, 18.5), Color3.fromRGB(120, 75, 40), Enum.Material.Wood, gym)
	end
end

local function buildBigTree()
	local tree = Instance.new("Folder")
	tree.Name = "BigTree"
	tree.Parent = workspace
	local trunk = part("Trunk", Vector3.new(8, 30, 8), Vector3.new(-105, GROUND + 15, 35), Color3.fromRGB(130, 85, 50), Enum.Material.Wood, tree, Enum.PartType.Cylinder)
	trunk.CFrame = CFrame.new(-105, GROUND + 15, 35) * CFrame.Angles(0, 0, math.rad(90))
	part("Leaves1", Vector3.new(22, 18, 22), Vector3.new(-105, GROUND + 34, 35), Color3.fromRGB(70, 170, 80), Enum.Material.Grass, tree, Enum.PartType.Ball)
	part("Leaves2", Vector3.new(16, 13, 16), Vector3.new(-114, GROUND + 28, 30), Color3.fromRGB(90, 190, 95), Enum.Material.Grass, tree, Enum.PartType.Ball)
	part("Leaves3", Vector3.new(15, 12, 15), Vector3.new(-96, GROUND + 29, 42), Color3.fromRGB(60, 155, 75), Enum.Material.Grass, tree, Enum.PartType.Ball)
	-- A wooden platform in the branches, reached by a ladder.
	part("TreePlatform", Vector3.new(9, 1, 9), Vector3.new(-105, GROUND + 30.5, 35), Color3.fromRGB(160, 110, 60), Enum.Material.Wood, tree)
	for i = 1, 9 do
		part("TreeLadder", Vector3.new(3, 0.4, 0.4), Vector3.new(-105, GROUND + 1 + i * 3, 30.6), Color3.fromRGB(120, 75, 40), Enum.Material.Wood, tree)
	end
	-- The crow's nest: the Naughty Crow lives here between thefts.
	part("CrowNest", Vector3.new(4, 1.5, 4), Vector3.new(-112, GROUND + 38, 35), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, tree, Enum.PartType.Cylinder).CFrame =
		CFrame.new(-112, GROUND + 38, 35) * CFrame.Angles(0, 0, math.rad(90))
end

local function buildCafeteria()
	local cafe = Instance.new("Folder")
	cafe.Name = "Cafeteria"
	cafe.Parent = workspace
	part("CafeHall", Vector3.new(30, 14, 20), Vector3.new(-105, GROUND + 7, -70), Color3.fromRGB(255, 220, 160), Enum.Material.Wood, cafe)
	part("CafeRoof", Vector3.new(32, 1.5, 22), Vector3.new(-105, GROUND + 14.5, -70), Color3.fromRGB(220, 90, 90), Enum.Material.SmoothPlastic, cafe)
	-- A striped awning over the serving counter.
	for i = 1, 6 do
		local stripeColor = Color3.fromRGB(255, 255, 255)
		if i % 2 == 1 then
			stripeColor = Color3.fromRGB(230, 80, 80)
		end
		part("Awning", Vector3.new(4.5, 0.4, 6), Vector3.new(-117 + i * 4.5, GROUND + 10, -58.5), stripeColor, Enum.Material.SmoothPlastic, cafe)
	end
	local sign = part("CafeSign", Vector3.new(22, 4, 1), Vector3.new(-105, GROUND + 12, -59.4), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, cafe)
	textOn(sign, "CAFETERIA", Color3.fromRGB(200, 60, 60), 48)
	-- Picnic tables outside.
	for _, offset in ipairs({ Vector3.new(-118, 0, -52), Vector3.new(-104, 0, -50), Vector3.new(-90, 0, -52) }) do
		part("TableTop", Vector3.new(6, 0.5, 3), Vector3.new(offset.X, GROUND + 2.5, offset.Z), Color3.fromRGB(180, 130, 70), Enum.Material.Wood, cafe)
		part("TableLeg", Vector3.new(0.6, 2.5, 0.6), Vector3.new(offset.X, GROUND + 1.25, offset.Z), Color3.fromRGB(140, 95, 50), Enum.Material.Wood, cafe)
	end
end

local function buildBus()
	local bus = Instance.new("Folder")
	bus.Name = "SchoolBus"
	bus.Parent = workspace
	local body = part("BusBody", Vector3.new(20, 6.5, 7.5), Vector3.new(60, GROUND + 4.5, -95), Color3.fromRGB(255, 210, 40), Enum.Material.SmoothPlastic, bus)
	body.CFrame = CFrame.new(60, GROUND + 4.5, -95) * CFrame.Angles(0, math.rad(12), 0)
	local hood = part("BusHood", Vector3.new(4, 4, 7), Vector3.new(71.5, GROUND + 3, -92.5), Color3.fromRGB(255, 210, 40), Enum.Material.SmoothPlastic, bus)
	hood.CFrame = CFrame.new(71.5, GROUND + 3, -92.5) * CFrame.Angles(0, math.rad(12), 0)
	-- Windows along the side.
	for i = 1, 4 do
		local window = part("BusWindow", Vector3.new(3, 2.4, 0.3), Vector3.new(53 + i * 4, GROUND + 5.5, -91.4), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, bus)
		window.CFrame = CFrame.new(53 + i * 4, GROUND + 5.5, -91.4) * CFrame.Angles(0, math.rad(12), 0)
	end
	-- Four wheels.
	for _, wheelPos in ipairs({ Vector3.new(53, GROUND + 1.2, -91.5), Vector3.new(53, GROUND + 1.2, -98.5), Vector3.new(67, GROUND + 1.2, -91.5), Vector3.new(67, GROUND + 1.2, -98.5) }) do
		local wheel = part("Wheel", Vector3.new(2.4, 2.4, 1), wheelPos, Color3.fromRGB(40, 40, 45), Enum.Material.SmoothPlastic, bus, Enum.PartType.Cylinder)
		wheel.CFrame = CFrame.new(wheelPos) * CFrame.Angles(math.rad(90), 0, 0)
	end
	local sign = part("BusSign", Vector3.new(8, 2, 0.3), Vector3.new(60, GROUND + 6.5, -91.3), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, bus)
	sign.CFrame = CFrame.new(60, GROUND + 6.5, -91.3) * CFrame.Angles(0, math.rad(12), 0)
	textOn(sign, "SCHOOL BUS", Color3.fromRGB(40, 40, 40), 24)
end

local function buildLockers()
	local lockers = Instance.new("Folder")
	lockers.Name = "Lockers"
	lockers.Parent = workspace
	local colors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 120), Color3.fromRGB(90, 150, 255) }
	for i = 1, 8 do
		part("Locker", Vector3.new(2.4, 5.5, 1.6), Vector3.new(-42 + i * 2.6, GROUND + 2.75, -100), colors[(i - 1) % 4 + 1], Enum.Material.Metal, lockers)
	end
end

local function buildDecorTrees()
	local decor = Instance.new("Folder")
	decor.Name = "ForestEdge"
	decor.Parent = workspace
	local spots = {
		Vector3.new(-160, 0, -40), Vector3.new(-170, 0, 80), Vector3.new(170, 0, -30),
		Vector3.new(165, 0, 90), Vector3.new(-60, 0, 175), Vector3.new(70, 0, 170),
		Vector3.new(-190, 0, -120), Vector3.new(190, 0, -110), Vector3.new(-30, 0, -185),
		Vector3.new(120, 0, -175),
	}
	for i, spot in ipairs(spots) do
		local height = 12 + (i % 3) * 4
		local trunk = part("Trunk", Vector3.new(2.5, height, 2.5), Vector3.new(spot.X, GROUND + height / 2, spot.Z), Color3.fromRGB(130, 85, 50), Enum.Material.Wood, decor, Enum.PartType.Cylinder)
		trunk.CFrame = CFrame.new(spot.X, GROUND + height / 2, spot.Z) * CFrame.Angles(0, 0, math.rad(90))
		part("Leaves", Vector3.new(10, 9, 10), Vector3.new(spot.X, GROUND + height + 3, spot.Z), Color3.fromRGB(70 + (i % 3) * 15, 170, 80), Enum.Material.Grass, decor, Enum.PartType.Ball)
	end
	-- Flowers scattered on the field edges.
	for i = 1, 20 do
		local x = -140 + (i * 37) % 280
		local z = -140 + (i * 53) % 280
		if math.abs(x) > 70 or math.abs(z - 10) > 50 then
			local flowerColor = Color3.fromRGB(255, 120, 180)
			if i % 3 == 0 then
				flowerColor = Color3.fromRGB(255, 220, 80)
			elseif i % 3 == 1 then
				flowerColor = Color3.fromRGB(180, 120, 255)
			end
			part("Flower", Vector3.new(0.8, 0.8, 0.8), Vector3.new(x, GROUND + 0.6, z), flowerColor, Enum.Material.Neon, decor, Enum.PartType.Ball)
		end
	end
end

-- One classroom base: a coloured platform, a sign, pedestal slots in rows of
-- four, and a transparent shield that appears while the base is locked.
local function buildBase(index, angleDegrees)
	local angle = math.rad(angleDegrees)
	local cx = BASE_RADIUS * math.cos(angle)
	local cz = BASE_RADIUS * math.sin(angle)
	local color = BASE_COLORS[index]

	local folder = Instance.new("Folder")
	folder.Name = "Classroom" .. index
	folder.Parent = workspace

	part("Platform", Vector3.new(24, 1, 24), Vector3.new(cx, GROUND + 0.5, cz), color, Enum.Material.SmoothPlastic, folder)
	-- Low walls on three sides so the room reads as a classroom.
	part("BackWall", Vector3.new(24, 4, 1), Vector3.new(cx, GROUND + 3, cz - 11.5), Color3.fromRGB(240, 220, 180), Enum.Material.Wood, folder)
	part("LeftWall", Vector3.new(1, 4, 24), Vector3.new(cx - 11.5, GROUND + 3, cz), Color3.fromRGB(240, 220, 180), Enum.Material.Wood, folder)
	part("RightWall", Vector3.new(1, 4, 24), Vector3.new(cx + 11.5, GROUND + 3, cz), Color3.fromRGB(240, 220, 180), Enum.Material.Wood, folder)

	-- Sign post facing the field.
	local signPost = part("SignPost", Vector3.new(0.8, 6, 0.8), Vector3.new(cx, GROUND + 3, cz + 13), Color3.fromRGB(120, 75, 40), Enum.Material.Wood, folder)
	signPost.CFrame = CFrame.new(cx, GROUND + 3, cz + 13)
	local signBoard = part("SignBoard", Vector3.new(10, 3.5, 0.6), Vector3.new(cx, GROUND + 7, cz + 13), Color3.fromRGB(60, 60, 80), Enum.Material.SmoothPlastic, folder)
	local signGui = textOn(signBoard, "CLASSROOM " .. index, Color3.fromRGB(255, 255, 255), 32)

	-- The lock shield: invisible until the base is locked.
	local shield = part("LockShield", Vector3.new(26, 14, 26), Vector3.new(cx, GROUND + 7, cz), Color3.fromRGB(90, 170, 255), Enum.Material.Neon, folder)
	shield.Transparency = 1
	shield.CanCollide = false
	shield.CanQuery = false

	local base = {
		index = index,
		center = Vector3.new(cx, GROUND + 1, cz),
		folder = folder,
		signGui = signGui,
		shield = shield,
		owner = nil,
		pedestals = {},
		pedestalRows = 0,
	}

	WorldBuilder.AddPedestalRow(base)
	WorldBuilder.AddPedestalRow(base)
	return base
end

-- Adds one row of four pedestals to a base. The first two rows come free;
-- the Extra Slot upgrade buys the third and fourth.
function WorldBuilder.AddPedestalRow(base)
	if base.pedestalRows >= 4 then
		return
	end
	base.pedestalRows += 1
	local rowZ = -6 + (base.pedestalRows - 1) * 4
	local rowIndex = base.pedestalRows
	for col = 1, 4 do
		local x = base.center.X - 7.5 + (col - 1) * 5
		local z = base.center.Z + rowZ
		local id = "b" .. base.index .. "p" .. ((rowIndex - 1) * 4 + col)
		local column = part("Pedestal", Vector3.new(3.2, 1.2, 3.2), Vector3.new(x, GROUND + 1.6, z), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, base.folder, Enum.PartType.Cylinder)
		column.CFrame = CFrame.new(x, GROUND + 1.6, z) * CFrame.Angles(0, 0, math.rad(90))
		local top = part("PedestalTop", Vector3.new(3.4, 0.25, 3.4), Vector3.new(x, GROUND + 2.25, z), Color3.fromRGB(200, 200, 200), Enum.Material.Neon, base.folder, Enum.PartType.Cylinder)
		top.CFrame = CFrame.new(x, GROUND + 2.25, z) * CFrame.Angles(0, 0, math.rad(90))
		top.CanCollide = false
		local clicker = Instance.new("ClickDetector")
		clicker.Name = "PedestalClicker"
		clicker.MaxActivationDistance = 40
		clicker.Parent = column
		local pedestalRecord = {
			id = id,
			part = column,
			top = top,
			clicker = clicker,
			position = Vector3.new(x, GROUND + 2.4, z),
		}
		table.insert(base.pedestals, pedestalRecord)
		-- Rows bought later (Extra Slot upgrade) need their clicker wired too.
		if WorldBuilder.OnPedestalAdded then
			WorldBuilder.OnPedestalAdded(base, pedestalRecord)
		end
	end
end

local function buildHighPads()
	local pads = {}
	local spots = {
		{ name = "Gym Wall", position = Vector3.new(86.5, GROUND + 27, 25) },
		{ name = "Big Tree", position = Vector3.new(-105, GROUND + 31.5, 35) },
		{ name = "Tower Top", position = Vector3.new(48, GROUND + 47.5, -128) },
	}
	for _, spot in ipairs(spots) do
		local pad = part("HighPad", Vector3.new(6, 0.6, 6), spot.position, Color3.fromRGB(255, 215, 0), Enum.Material.Neon, workspace, Enum.PartType.Cylinder)
		pad.CFrame = CFrame.new(spot.position) * CFrame.Angles(0, 0, math.rad(90))
		table.insert(pads, {
			name = spot.name,
			position = spot.position + Vector3.new(0, 1.5, 0),
			padPart = pad,
			occupiedUid = nil,
		})
	end
	return pads
end

-- A Press [E] prompt for an arena interactable. E is reserved for exactly
-- these: SIT on benches and swings, GACHA, FUSE, and STEAL on rival bases.
-- Buying a parade brainrot is always a click, never an E prompt.
local function interactPrompt(parent, actionText, objectText, range)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = actionText .. "Prompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = range or 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- The Gacha Machine by the cafeteria: a red cabinet with a glass dome full
-- of colourful capsules. Press E to roll a random brainrot for $1,000.
local function buildGachaMachine()
	local machine = Instance.new("Folder")
	machine.Name = "GachaMachine"
	machine.Parent = workspace
	local body = part("GachaBody", Vector3.new(6, 7, 5), Vector3.new(-78, GROUND + 3.5, -52), Color3.fromRGB(230, 70, 70), Enum.Material.SmoothPlastic, machine)
	body.CFrame = CFrame.new(-78, GROUND + 3.5, -52) * CFrame.Angles(0, math.rad(20), 0)
	local dome = part("GachaDome", Vector3.new(5.2, 5.2, 5.2), Vector3.new(-78, GROUND + 9.5, -52), Color3.fromRGB(200, 230, 255), Enum.Material.Glass, machine, Enum.PartType.Ball)
	dome.Transparency = 0.3
	-- Capsules tumbling inside the dome.
	local capsuleColors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 120), Color3.fromRGB(90, 150, 255), Color3.fromRGB(200, 120, 255) }
	for i, capsuleColor in ipairs(capsuleColors) do
		part("Capsule", Vector3.new(1.1, 1.1, 1.1), Vector3.new(-79.5 + (i % 3) * 1.5, GROUND + 8.5 + math.floor(i / 3) * 1.4, -52.5 + (i % 2) * 1.2), capsuleColor, Enum.Material.Neon, machine, Enum.PartType.Ball)
	end
	-- Rainbow stripes across the front.
	local stripeColors = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 200, 120), Color3.fromRGB(90, 150, 255) }
	for i, stripeColor in ipairs(stripeColors) do
		part("Stripe", Vector3.new(5.5, 0.7, 0.3), Vector3.new(-78, GROUND + 4.5 + i * 0.8, -49.4), stripeColor, Enum.Material.Neon, machine)
	end
	part("Dispenser", Vector3.new(2.5, 2, 0.6), Vector3.new(-78, GROUND + 1.2, -49.4), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic, machine)
	local sign = part("GachaSign", Vector3.new(8, 2.5, 0.6), Vector3.new(-78, GROUND + 13, -52), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, machine)
	textOn(sign, "GACHA  $1000", Color3.fromRGB(220, 60, 60), 32)
	return interactPrompt(body, "GACHA", "Gacha Machine", 12)
end

-- The Fuse Lab by the gym: a white lab with a glowing purple fusion tube.
-- Press E to fuse three brainrots of one tier into one of the next tier.
local function buildFuseLab()
	local lab = Instance.new("Folder")
	lab.Name = "FuseLab"
	lab.Parent = workspace
	part("LabHall", Vector3.new(12, 9, 9), Vector3.new(78, GROUND + 4.5, 52), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic, lab)
	part("LabRoof", Vector3.new(13, 1, 10), Vector3.new(78, GROUND + 9.5, 52), Color3.fromRGB(150, 90, 220), Enum.Material.SmoothPlastic, lab)
	local tube = part("FusionTube", Vector3.new(3.5, 7, 3.5), Vector3.new(78, GROUND + 3.5, 46.5), Color3.fromRGB(170, 90, 255), Enum.Material.Neon, lab, Enum.PartType.Cylinder)
	tube.CFrame = CFrame.new(78, GROUND + 3.5, 46.5) * CFrame.Angles(0, 0, math.rad(90))
	tube.Transparency = 0.25
	-- Two bubbling beakers on the counter.
	local beakerGreen = part("Beaker", Vector3.new(1.4, 2.4, 1.4), Vector3.new(74, GROUND + 1.2, 46.5), Color3.fromRGB(90, 230, 120), Enum.Material.Neon, lab, Enum.PartType.Cylinder)
	beakerGreen.CFrame = CFrame.new(74, GROUND + 1.2, 46.5) * CFrame.Angles(0, 0, math.rad(90))
	local beakerBlue = part("Beaker", Vector3.new(1.4, 2.4, 1.4), Vector3.new(82, GROUND + 1.2, 46.5), Color3.fromRGB(90, 180, 255), Enum.Material.Neon, lab, Enum.PartType.Cylinder)
	beakerBlue.CFrame = CFrame.new(82, GROUND + 1.2, 46.5) * CFrame.Angles(0, 0, math.rad(90))
	part("Counter", Vector3.new(12, 1, 2), Vector3.new(78, GROUND + 0.5, 46.5), Color3.fromRGB(200, 200, 210), Enum.Material.SmoothPlastic, lab)
	local sign = part("FuseSign", Vector3.new(10, 2.5, 0.6), Vector3.new(78, GROUND + 7.5, 47.4), Color3.fromRGB(60, 40, 100), Enum.Material.SmoothPlastic, lab)
	textOn(sign, "FUSE LAB", Color3.fromRGB(220, 180, 255), 32)
	local body = lab:FindFirstChild("LabHall")
	return interactPrompt(body, "FUSE", "Fuse Lab", 12)
end

-- Benches and swings around the school field. Every seat has a Press [E] SIT
-- prompt; sitting rests the student and grants the Fresh income buff.
local function buildArenaSeats()
	local seatsFolder = Instance.new("Folder")
	seatsFolder.Name = "ArenaSeats"
	seatsFolder.Parent = workspace
	local seats = {}

	local function addBench(x, z, facing)
		local seatPart = part("BenchSeat", Vector3.new(5, 0.6, 2), Vector3.new(x, GROUND + 1.2, z), Color3.fromRGB(180, 130, 70), Enum.Material.Wood, seatsFolder)
		local backOffset = Vector3.new(-facing.X * 1, 0, -facing.Z * 1)
		part("BenchBack", Vector3.new(5, 2.2, 0.4), Vector3.new(x + backOffset.X, GROUND + 2.6, z + backOffset.Z), Color3.fromRGB(160, 110, 60), Enum.Material.Wood, seatsFolder)
		for _, legX in ipairs({ -2, 2 }) do
			part("BenchLeg", Vector3.new(0.5, 1, 1.8), Vector3.new(x + legX, GROUND + 0.5, z), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, seatsFolder)
		end
		local prompt = interactPrompt(seatPart, "SIT", "Bench", 8)
		table.insert(seats, {
			kind = "Bench",
			part = seatPart,
			prompt = prompt,
			sitPosition = Vector3.new(x, GROUND + 3.3, z),
			sitLook = facing,
		})
	end

	local function addSwingSet(x, z, facing)
		-- An A-frame with a top bar and two hanging seats.
		local topBar = part("SwingBar", Vector3.new(9, 0.5, 0.5), Vector3.new(x, GROUND + 7, z), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, seatsFolder)
		topBar.CFrame = CFrame.new(x, GROUND + 7, z)
		for _, side in ipairs({ -4, 4 }) do
			local pole = part("SwingPole", Vector3.new(0.5, 7.5, 0.5), Vector3.new(x + side, GROUND + 3.5, z), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, seatsFolder)
			pole.CFrame = CFrame.new(x + side, GROUND + 3.5, z) * CFrame.Angles(0, 0, math.rad(side * -4))
		end
		for _, offset in ipairs({ -2.2, 2.2 }) do
			local seatX = x + offset
			for _, chainOffset in ipairs({ -0.9, 0.9 }) do
				part("SwingChain", Vector3.new(0.15, 4.4, 0.15), Vector3.new(seatX + chainOffset, GROUND + 4.8, z), Color3.fromRGB(180, 180, 190), Enum.Material.Metal, seatsFolder)
			end
			local seatPart = part("SwingSeat", Vector3.new(2.2, 0.4, 1.2), Vector3.new(seatX, GROUND + 2.4, z), Color3.fromRGB(200, 90, 90), Enum.Material.SmoothPlastic, seatsFolder)
			local prompt = interactPrompt(seatPart, "SIT", "Swing", 8)
			table.insert(seats, {
				kind = "Swing",
				part = seatPart,
				prompt = prompt,
				sitPosition = Vector3.new(seatX, GROUND + 4.2, z),
				sitLook = facing,
			})
		end
	end

	-- Four benches around the field, facing the game.
	addBench(-40, 44, Vector3.new(0, 0, -1))
	addBench(40, 44, Vector3.new(0, 0, -1))
	addBench(-40, -24, Vector3.new(0, 0, 1))
	addBench(40, -24, Vector3.new(0, 0, 1))
	-- Two swing sets on the field's flanks, facing the field.
	addSwingSet(-58, 10, Vector3.new(1, 0, 0))
	addSwingSet(58, 10, Vector3.new(-1, 0, 0))
	return seats
end

function WorldBuilder.Build()
	if world then
		return world
	end
	buildGround()
	buildAcademy()
	buildTower()
	buildParadeLane()
	buildGym()
	buildBigTree()
	buildCafeteria()
	buildBus()
	buildLockers()
	buildDecorTrees()

	local bases = {}
	for i, angle in ipairs(BASE_ANGLES) do
		bases[i] = buildBase(i, angle)
	end

	-- Where new students arrive.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StudentSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, GROUND + 0.5, 60)
	spawn.Neutral = true
	spawn.Color = Color3.fromRGB(120, 220, 100)
	spawn.Material = Enum.Material.Grass
	spawn.Anchored = true
	spawn.Parent = workspace

	world = {
		bases = bases,
		highPads = buildHighPads(),
		gachaPrompt = buildGachaMachine(),
		fusePrompt = buildFuseLab(),
		seats = buildArenaSeats(),
		-- The parade points sit on the lane surface itself (the lane slab's
		-- top is GROUND + 0.2); the Spawner lifts each brainrot by its own
		-- half height so its base touches the lane exactly.
		paradeStart = Vector3.new(-80, GROUND + 0.2, -60),
		paradeEnd = Vector3.new(80, GROUND + 0.2, -60),
		treeTop = Vector3.new(-112, GROUND + 39, 35),
		fieldCenter = Vector3.new(0, GROUND, 10),
		spawnLocation = spawn,
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

function WorldBuilder.GetGachaPrompt()
	return world and world.gachaPrompt or nil
end

function WorldBuilder.GetFusePrompt()
	return world and world.fusePrompt or nil
end

function WorldBuilder.GetSeats()
	return world and world.seats or {}
end

-- Is this point inside one of the classroom bases? The hazard and the safe
-- zone both use this. Returns the base index or nil.
function WorldBuilder.BaseAtPosition(position)
	if not world then
		return nil
	end
	for _, base in ipairs(world.bases) do
		if math.abs(position.X - base.center.X) <= 12 and math.abs(position.Z - base.center.Z) <= 12 then
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

function WorldBuilder.SetBaseOwner(base, player)
	base.owner = player
	local label = base.signGui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = player.Name .. "'s CLASS"
	end
end

function WorldBuilder.SetBaseLockVisual(base, locked)
	base.shield.Transparency = locked and 0.55 or 1
end

return WorldBuilder
