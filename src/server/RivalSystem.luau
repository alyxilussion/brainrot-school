-- RivalSystem: NPC rival classmates (Budi, Siti, Joko) who own classrooms,
-- fill them with brainrots you can Press [E] Steal, and send a thief across
-- the yard to rob an unlocked classroom. Thieves can be PULLED and PUSHED,
-- stagger, and drop their loot, so the whole loop is playable solo. A rival
-- hands its classroom over when a real student needs one.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local RivalSystem = {}

local G
local rng = Random.new()
local rivals = {} -- rival key tables
local NAMES = { "Budi", "Siti", "Joko" }
local SHIRTS = { Color3.fromRGB(230, 90, 80), Color3.fromRGB(110, 170, 255), Color3.fromRGB(120, 205, 110) }
local WALKWAY_X = 109
local ROOT_HEIGHT = 3
local REFILL_WEIGHTS = { Common = 40, Uncommon = 30, Rare = 18, Epic = 9, Legendary = 3 }

local function now()
	return Workspace:GetServerTimeNow()
end

local function part(model, name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Parent = model
	return p
end

-- A blocky student puppet in school uniform with a name tag.
local function buildPuppet(name, shirt)
	local model = Instance.new("Model")
	model.Name = "Rival_" .. name
	local root = part(model, "Root", Vector3.new(2, 2, 1), shirt)
	root.Transparency = 1
	model.PrimaryPart = root
	local pieces = {
		{ part(model, "Torso", Vector3.new(2, 2, 1), shirt), CFrame.new(0, 0, 0) },
		{ part(model, "Tie", Vector3.new(0.4, 1.2, 0.1), Color3.fromRGB(200, 40, 50)), CFrame.new(0, 0.2, -0.55) },
		{ part(model, "Head", Vector3.new(1.3, 1.3, 1.3), Color3.fromRGB(240, 195, 150)), CFrame.new(0, 1.65, 0) },
		{ part(model, "Hair", Vector3.new(1.4, 0.5, 1.4), Color3.fromRGB(40, 30, 25)), CFrame.new(0, 2.35, 0.05) },
		{ part(model, "Mask", Vector3.new(1.32, 0.35, 0.1), Color3.fromRGB(25, 25, 35)), CFrame.new(0, 1.75, -0.66) },
		{ part(model, "Backpack", Vector3.new(1.6, 1.6, 0.7), Color3.fromRGB(60, 60, 75)), CFrame.new(0, 0.1, 0.85) },
	}
	local legs, arms = {}, {}
	for _, side in ipairs({ -1, 1 }) do
		local leg = part(model, "Leg", Vector3.new(0.9, 2, 0.9), Color3.fromRGB(45, 55, 95))
		table.insert(legs, { leg, side })
		local arm = part(model, "Arm", Vector3.new(0.7, 1.9, 0.7), shirt)
		table.insert(arms, { arm, side })
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.new(7, 0, 1.8, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(1, 0.6)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Text = "RIVAL " .. string.upper(name)
	label.Parent = gui
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.fromScale(1, 0.4)
	status.Position = UDim2.fromScale(0, 0.6)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBlack
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(255, 200, 90)
	status.TextStrokeTransparency = 0
	status.Text = "IN CLASS"
	status.Parent = gui
	gui.Parent = root
	CollectionService:AddTag(model, "RivalStudent")
	return model, root, pieces, legs, arms, status
end

-- Pose every piece around the root; legs and arms swing while walking.
local function pose(rival, cf, swing)
	rival.root.CFrame = cf
	for _, piece in ipairs(rival.pieces) do
		piece[1].CFrame = cf * piece[2]
	end
	for _, leg in ipairs(rival.legs) do
		leg[1].CFrame = cf * CFrame.new(leg[2] * 0.5, -1, 0) * CFrame.Angles(swing * leg[2], 0, 0) * CFrame.new(0, -1, 0)
	end
	for _, arm in ipairs(rival.arms) do
		arm[1].CFrame = cf * CFrame.new(arm[2] * 1.35, 0.9, 0) * CFrame.Angles(-swing * arm[2], 0, 0) * CFrame.new(0, -0.95, 0)
	end
end

local function groundPoint(x, z)
	return Vector3.new(x, G.World.GroundHeightAt(x, z) + ROOT_HEIGHT, z)
end

-- Waypoints from anywhere to a point inside a classroom, along the
-- walkways and the east-west spine through the arena.
local function routeTo(from, base, inside)
	local route = {}
	local fromBase = G.World.BaseAtPosition(from)
	if fromBase then
		local door = G.World.GetBase(fromBase).door
		table.insert(route, groundPoint(door.X, door.Z))
	end
	local fromSide = math.abs(from.X) > 100 and math.sign(from.X) or 0
	local fromZ = fromBase and G.World.GetBase(fromBase).door.Z or from.Z
	if fromSide ~= base.side then
		if fromSide ~= 0 then
			table.insert(route, groundPoint(fromSide * WALKWAY_X, fromZ))
			table.insert(route, groundPoint(fromSide * WALKWAY_X, 0))
		else
			table.insert(route, groundPoint(from.X, 0))
		end
		table.insert(route, groundPoint(base.side * WALKWAY_X, 0))
	end
	table.insert(route, groundPoint(base.side * WALKWAY_X, base.door.Z))
	table.insert(route, groundPoint(base.door.X, base.door.Z))
	table.insert(route, groundPoint(inside.X, inside.Z))
	return route
end

-- Standing spot two and a half studs in front of a pedestal (toward the door).
local function besidePedestal(base, pedestal)
	return (CFrame.new(pedestal.position) * (base.cframe - base.cframe.Position) * CFrame.new(0, 0, -2.6)).Position
end

local function homeSpot(rival)
	local base = G.World.GetBase(rival.state.baseIndex)
	return (base.cframe * CFrame.new(rival.homeOffset, 0, -10)).Position
end

local function setStatus(rival, text, color)
	rival.statusLabel.Text = text
	rival.statusLabel.TextColor3 = color or Color3.fromRGB(255, 200, 90)
end

local function goHome(rival)
	local base = G.World.GetBase(rival.state.baseIndex)
	rival.mission = "returning"
	rival.route = routeTo(rival.root.Position, base, homeSpot(rival))
	rival.routeIndex = 1
	setStatus(rival, #rival.state.carrying > 0 and "RUNNING HOME!" or "GOING BACK", Color3.fromRGB(255, 120, 120))
end

-- Fill a rival's classroom with brainrots for students to steal.
local function refill(rival, count)
	local state = rival.state
	local base = G.World.GetBase(state.baseIndex)
	for _ = 1, count do
		local pedestal = G.World.GetFreePedestal(base, state.placed)
		if not pedestal then
			return
		end
		local entry = Catalog.GetRandomOfRarity(Catalog.RollTier(rng, REFILL_WEIGHTS), rng)
		local record = G.Carry.NewRecord(entry, Catalog.RollMutation(rng, 0), CFrame.new(pedestal.position), "placed")
		G.Carry.Place(state, record, pedestal)
	end
end

function RivalSystem.Spawn(baseIndex, nameIndex)
	local base = G.World.GetBase(baseIndex)
	local name = NAMES[nameIndex]
	local model, root, pieces, legs, arms, status = buildPuppet(name, SHIRTS[nameIndex])
	local rival = {
		name = name,
		nameIndex = nameIndex,
		model = model,
		root = root,
		pieces = pieces,
		legs = legs,
		arms = arms,
		statusLabel = status,
		mission = "home",
		route = nil,
		routeIndex = 1,
		walkPhase = 0,
		homeOffset = rng:NextNumber(-6, 6),
		knock = nil,
	}
	rival.state = G.State.Create(rival, { isBot = true, name = "Rival " .. name, userId = -1 })
	rival.state.baseIndex = baseIndex
	base.owner = rival.state
	G.World.SetBaseOwnerName(base, "Rival " .. name)
	local spot = homeSpot(rival)
	pose(rival, CFrame.lookAt(groundPoint(spot.X, spot.Z), groundPoint(base.door.X, base.door.Z)), 0)
	model.Parent = Workspace
	table.insert(rivals, rival)
	refill(rival, 5)
	G.Steal.RefreshBase(rival.state)
	return rival
end

-- Hand a rival's classroom to a real student: the rival leaves with its loot.
function RivalSystem.ReleaseBase()
	table.sort(rivals, function(a, b)
		return a.state.baseIndex < b.state.baseIndex
	end)
	local rival = table.remove(rivals, 1)
	if not rival then
		return nil
	end
	local state = rival.state
	for _, record in ipairs(table.clone(state.carrying)) do
		G.Carry.Destroy(record)
	end
	for _, record in pairs(table.clone(state.placed)) do
		G.Carry.Destroy(record)
	end
	rival.model:Destroy()
	G.State.Remove(rival)
	local base = G.World.GetBase(state.baseIndex)
	base.owner = nil
	G.World.ResetPedestalRows(base)
	G.World.SetBaseOwnerName(base, nil)
	G.World.SetBaseLockVisual(base, false, 0)
	return state.baseIndex
end

-- Knockback on a puppet: slide along the hit for a moment, then stagger.
function RivalSystem.Knock(state, velocity, duration)
	local rival = state.key
	local flat = Vector3.new(velocity.X, 0, velocity.Z) * duration
	local from = rival.root.Position
	local to = from + flat
	to = Vector3.new(math.clamp(to.X, -185, 185), 0, math.clamp(to.Z, -185, 185))
	rival.knock = { from = from, to = groundPoint(to.X, to.Z), started = now(), duration = 0.3 }
	rival.staggerUntil = now() + Config.RIVAL_STAGGER_TIME
	setStatus(rival, "DIZZY!", Color3.fromRGB(120, 200, 255))
end

local function arrive(rival)
	local state = rival.state
	if rival.mission == "stealing" then
		local victim = rival.victim
		local record = rival.targetRecord
		local stolen = false
		if victim and G.State.Get(victim.key) == victim and record and record.owner == victim and record.status == "placed" then
			if G.State.IsLocked(victim, now()) then
				setStatus(rival, "LOCKED OUT!", Color3.fromRGB(120, 200, 255))
				if not victim.isBot then
					G.notify(victim, "Your lock stopped Rival " .. rival.name .. "!", Color3.fromRGB(120, 200, 255))
				end
			else
				stolen = G.Steal.TrySteal(state, record)
			end
		end
		if not stolen and victim and not victim.isBot then
			G.notify(victim, "Rival " .. rival.name .. " left empty-handed.", Color3.fromRGB(120, 255, 150))
		end
		goHome(rival)
	elseif rival.mission == "returning" then
		for _, record in ipairs(table.clone(state.carrying)) do
			local from = record.stolenFrom
			if not G.Carry.PlaceAnywhere(state, record) then
				G.Carry.Destroy(record)
			elseif from and not from.isBot and G.State.Get(from.key) == from then
				G.notify(from, "Rival " .. rival.name .. " got away with " .. record.name .. "! Steal it back from Classroom " .. state.baseIndex .. ".", Color3.fromRGB(255, 120, 120))
			end
			record.stolenFrom = nil
		end
		rival.mission = "home"
		rival.route = nil
		setStatus(rival, "IN CLASS")
	end
end

local function stepRival(rival, dt, t)
	if rival.knock then
		local knock = rival.knock
		local alpha = math.min(1, (t - knock.started) / knock.duration)
		local position = knock.from:Lerp(knock.to, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * 1.5, 0)
		pose(rival, CFrame.new(position) * (rival.root.CFrame - rival.root.Position) * CFrame.Angles(0, 0, math.sin(t * 20) * 0.3), 0)
		if alpha >= 1 then
			rival.knock = nil
		end
		return
	end
	if (rival.staggerUntil or 0) > t then
		local cf = rival.root.CFrame
		pose(rival, CFrame.new(cf.Position) * CFrame.Angles(0, t * 6, 0), 0)
		return
	elseif rival.staggerUntil then
		rival.staggerUntil = nil
		if rival.mission ~= "home" then
			-- Dizzy thieves give up and head home, with or without loot.
			goHome(rival)
		end
	end
	local route = rival.route
	if not route then
		return
	end
	local target = route[rival.routeIndex]
	if not target then
		rival.route = nil
		arrive(rival)
		return
	end
	local position = rival.root.Position
	local offset = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
	local step = Config.RIVAL_WALK_SPEED * dt
	if offset.Magnitude <= step then
		rival.routeIndex += 1
		position = target
	else
		position += offset.Unit * step
	end
	local ground = groundPoint(position.X, position.Z)
	rival.walkPhase += dt * 9
	local facing = offset.Magnitude > 0.05 and offset.Unit or rival.root.CFrame.LookVector
	pose(rival, CFrame.lookAt(ground, ground + facing), math.sin(rival.walkPhase) * 0.6)
end

-- Every so often one rival at home picks a victim and sets out.
local function sendThief()
	local idle = {}
	for _, rival in ipairs(rivals) do
		if rival.mission == "home" then
			table.insert(idle, rival)
		end
	end
	if #idle == 0 then
		return
	end
	local rival = idle[rng:NextInteger(1, #idle)]
	local t = now()
	local victims, botVictims = {}, {}
	for _, state in pairs(G.State.All()) do
		if state ~= rival.state and state.baseIndex and next(state.placed) and not G.State.IsLocked(state, t) then
			table.insert(state.isBot and botVictims or victims, state)
		end
	end
	if #victims == 0 then
		victims = botVictims
	end
	if #victims == 0 then
		return
	end
	local victim = victims[rng:NextInteger(1, #victims)]
	local best = nil
	for _, record in pairs(victim.placed) do
		if not best or Config.RARITY_RANK[record.rarity] > Config.RARITY_RANK[best.rarity] then
			best = record
		end
	end
	local base = G.World.GetBase(victim.baseIndex)
	rival.mission = "stealing"
	rival.victim = victim
	rival.targetRecord = best
	rival.route = routeTo(rival.root.Position, base, besidePedestal(base, best.pedestal))
	rival.routeIndex = 1
	setStatus(rival, "SNEAKING TO " .. string.upper(victim.name), Color3.fromRGB(255, 120, 120))
	if not victim.isBot then
		G.notify(victim, "Rival " .. rival.name .. " is sneaking to your classroom! LOCK [L] or PULL [Q] / PUSH [F] him!", Color3.fromRGB(255, 90, 90))
		G.banner("RIVAL " .. string.upper(rival.name) .. " IS COMING FOR YOUR " .. string.upper(best.name) .. "!", Color3.fromRGB(230, 60, 70), 4, victim)
	end
end

function RivalSystem.Count()
	return #rivals
end

-- Bring rivals back into free classrooms while the server is small.
function RivalSystem.FillFreeBases(playerCount)
	if playerCount > Config.BASE_COUNT - 3 then
		return
	end
	local used = {}
	for _, rival in ipairs(rivals) do
		used[rival.nameIndex] = true
	end
	for index = Config.BASE_COUNT, 1, -1 do
		if #rivals >= #NAMES then
			return
		end
		local base = G.World.GetBase(index)
		if not base.owner then
			for nameIndex = 1, #NAMES do
				if not used[nameIndex] then
					used[nameIndex] = true
					RivalSystem.Spawn(index, nameIndex)
					break
				end
			end
		end
	end
end

function RivalSystem.Init(context)
	G = context
	for i, baseIndex in ipairs({ 8, 7, 6 }) do
		RivalSystem.Spawn(baseIndex, i)
	end
	RunService.Heartbeat:Connect(function(dt)
		local t = now()
		for _, rival in ipairs(rivals) do
			stepRival(rival, dt, t)
		end
	end)
	task.spawn(function()
		task.wait(20)
		while true do
			pcall(sendThief)
			task.wait(Config.RIVAL_THIEF_INTERVAL)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(40)
			for _, rival in ipairs(rivals) do
				if G.State.PlacedCount(rival.state) < 4 then
					refill(rival, 1)
				end
			end
		end
	end)
end

return RivalSystem
