-- ParadeSpawner: where brainrots come from. A new one walks the Parade Lane
-- every few seconds (Press [E] Buy), a free Mythic-or-better lands on a high
-- pad (tower, tree, gym roof) and the Arena Drop puts a rare one on the
-- arena crest for whoever grabs it first. Lucky Charm tilts every roll.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local ParadeSpawner = {}

local G
local rng = Random.new()
local walkers = {} -- parade records in flight

-- The best Lucky Charm level among the students here: one charm helps all.
local function serverLuck()
	local luck = 0
	for _, state in pairs(G.State.All()) do
		if not state.isBot then
			luck = math.max(luck, state.upgrades.luck or 0)
		end
	end
	return luck
end

local function rollEntry(weights, luck)
	local rarity = Catalog.RollTier(rng, Catalog.ApplyLuck(weights, luck))
	return Catalog.GetRandomOfRarity(rarity, rng)
end

local function spawnWalker()
	local world = G.World.GetWorld()
	local luck = serverLuck()
	local entry = rollEntry(Config.RARITY_WEIGHTS, luck)
	local mutation = Catalog.RollMutation(rng, luck)
	local facing = CFrame.lookAt(world.paradeStart, world.paradeEnd)
	local record = G.Carry.NewRecord(entry, mutation, facing, "parade", { scale = 1.15, status = "BUY " .. Config.FormatMoney(entry.cost) })
	-- Lift the model so its base rests exactly on the lane: without this
	-- the pivot sits on the surface and the lower half of the brainrot
	-- sinks into the ground.
	record.lift = G.Carry.PivotToBaseLift(record.model)
	record.model:PivotTo(facing + Vector3.new(0, record.lift, 0))
	record.walkStart = Workspace:GetServerTimeNow()
	record.walkOffset = rng:NextNumber(-2.5, 2.5)
	local prompt = G.Factory.AttachBuyPrompt(record.model, entry)
	table.insert(record.connections, prompt.Triggered:Connect(function(player)
		ParadeSpawner.Buy(player, record)
	end))
	walkers[record] = true
	if Config.RARITY_RANK[entry.rarity] >= Config.RARITY_RANK.Legendary or mutation then
		G.banner(string.upper((mutation and mutation .. " " or "") .. entry.rarity) .. " ON THE PARADE: " .. entry.name, Config.RARITY_COLORS[entry.rarity], 4)
	end
end

function ParadeSpawner.Buy(player, record)
	local state = G.State.Get(player)
	local entry = Catalog.ById[record.catalogId]
	if not state or record.status ~= "parade" or not entry then
		return
	end
	if state.cash < entry.cost then
		G.notify(state, "Need " .. Config.FormatMoney(entry.cost - state.cash) .. " more for " .. entry.name, Color3.fromRGB(255, 120, 120))
		return
	end
	if #state.carrying >= G.State.CarryCapacity(state) then
		G.notify(state, "Hands full! Bring it home first.", Color3.fromRGB(255, 120, 120))
		return
	end
	walkers[record] = nil
	state.cash -= entry.cost
	if G.Carry.TakeIntoHands(state, record) then
		G.Quests.OnEvent(state, "buy", 1)
		G.notify(state, "Bought " .. entry.name .. "! Carry it to your classroom.", Color3.fromRGB(120, 255, 150))
		G.fx("sound", "coin", nil, state)
	else
		state.cash += entry.cost
		walkers[record] = true
	end
	G.State.Changed(state)
end

-- One loop moves every parade walker with a little waddle.
local function stepWalkers()
	local world = G.World.GetWorld()
	local t = Workspace:GetServerTimeNow()
	for record in pairs(walkers) do
		if record.status ~= "parade" or not record.model then
			walkers[record] = nil
		else
			local alpha = (t - record.walkStart) / Config.PARADE_WALK_TIME
			if alpha >= 1 then
				walkers[record] = nil
				G.Carry.Destroy(record)
			else
				local position = world.paradeStart:Lerp(world.paradeEnd, alpha) + Vector3.new(0, record.lift or 0, record.walkOffset)
				local waddle = math.sin(t * 9 + record.walkOffset) * 0.12
				record.model:PivotTo(CFrame.lookAt(position, position + (world.paradeEnd - world.paradeStart)) * CFrame.Angles(0, 0, waddle))
			end
		end
	end
end

-- A free brainrot sits on a pad until someone grabs it.
local function spawnOnPad(pad, weights, label, questKey)
	if pad.occupiedUid and G.Carry.records[pad.occupiedUid] then
		local existing = G.Carry.records[pad.occupiedUid]
		if existing.status == "pad" then
			return nil
		end
	end
	local entry = rollEntry(weights, serverLuck())
	local mutation = Catalog.RollMutation(rng, serverLuck() + 1)
	local record = G.Carry.NewRecord(entry, mutation, pad.top * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), "pad", { scale = 1.2, status = "FREE · [E] GRAB" })
	pad.occupiedUid = record.uid
	local prompt = G.Factory.AttachGrabPrompt(record.model, G.Factory.DescribeRecord(record))
	table.insert(record.connections, prompt.Triggered:Connect(function(player)
		local state = G.State.Get(player)
		if state and record.status == "pad" and G.Carry.TakeIntoHands(state, record) then
			pad.occupiedUid = nil
			if questKey then
				G.Quests.OnEvent(state, questKey, 1)
			end
			G.banner(string.upper(state.name) .. " GRABBED THE " .. string.upper(label) .. " BRAINROT!", Color3.fromRGB(255, 220, 90), 3)
		end
	end))
	return record
end

local function highPadLoop()
	while true do
		task.wait(Config.HIGH_PAD_INTERVAL)
		local pads = G.World.GetWorld().highPads
		local pad = pads[rng:NextInteger(1, #pads)]
		local record = spawnOnPad(pad, Config.HIGH_PAD_WEIGHTS, pad.name, nil)
		if record then
			G.banner(string.upper(record.rarity) .. " " .. record.name .. " landed on the " .. pad.name .. "! Climb up!", Config.RARITY_COLORS[record.rarity], 5)
		end
	end
end

local function arenaDropLoop()
	while true do
		task.wait(Config.ARENA_DROP_INTERVAL - Config.ARENA_DROP_WARNING)
		G.banner("ARENA DROP IN " .. Config.ARENA_DROP_WARNING .. "s · GET TO THE CREST!", Color3.fromRGB(170, 110, 255), Config.ARENA_DROP_WARNING)
		task.wait(Config.ARENA_DROP_WARNING)
		local pad = G.World.GetWorld().arenaPad
		local record = spawnOnPad(pad, Config.HIGH_PAD_WEIGHTS, "Arena Drop", "arenaDrop")
		if record then
			G.fx("drop", pad.top.Position)
			G.banner("ARENA DROP: " .. string.upper(record.rarity) .. " " .. record.name .. "! PULL & PUSH FOR IT!", Config.RARITY_COLORS[record.rarity], 5)
		end
	end
end

function ParadeSpawner.Init(context)
	G = context
	RunService.Heartbeat:Connect(stepWalkers)
	task.spawn(function()
		-- A full lane from the first second: pre-walk a few.
		for i = 1, 8 do
			spawnWalker()
		end
		local offset = 0
		for record in pairs(walkers) do
			offset += 1
			record.walkStart -= offset * Config.PARADE_SPAWN_INTERVAL
		end
		while true do
			task.wait(Config.PARADE_SPAWN_INTERVAL)
			spawnWalker()
		end
	end)
	task.spawn(highPadLoop)
	task.spawn(arenaDropLoop)
	-- One high pad starts filled so the climb has a reason on minute one.
	task.defer(function()
		local pads = G.World.GetWorld().highPads
		spawnOnPad(pads[1], Config.HIGH_PAD_WEIGHTS, pads[1].name, nil)
	end)
end

return ParadeSpawner
