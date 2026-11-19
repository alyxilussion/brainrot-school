-- Spawner: brings brainrots into the world two ways.
-- 1. The Parade Lane: a brainrot walks in every few seconds, crosses the lane
--    in front of the academy, and leaves if nobody buys it.
-- 2. The high pads: a Mythic-or-better brainrot appears on the gym wall top,
--    the big tree or the tower top, free to the first player who grabs it.
-- Buying and grabbing live in CarrySystem; Spawner only owns the parade walk
-- and the pad registry, and calls the handlers CarrySystem registers.

local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local WorldBuilder = require(script.Parent.WorldBuilder)

local Spawner = {}

local rng = Random.new(os.time())
local parade = {} -- [uid] = parade record
local highPadRecords = {} -- [uid] = high pad record
local paradeFolder = nil
local buyHandler = nil
local grabHandler = nil

function Spawner.RegisterBuyHandler(handler)
	buyHandler = handler
end

function Spawner.RegisterGrabHandler(handler)
	grabHandler = handler
end

function Spawner.GetParade(uid)
	return parade[uid]
end

function Spawner.GetHighPad(uid)
	return highPadRecords[uid]
end

-- Unregisters a parade brainrot without destroying its model: the buyer takes it.
function Spawner.RemoveParade(uid)
	local record = parade[uid]
	if record then
		record.alive = false
		parade[uid] = nil
	end
end

-- Unregisters a high-pad brainrot; the pad frees up for the next spawn.
function Spawner.RemoveHighPad(uid)
	local record = highPadRecords[uid]
	if record and record.pad then
		record.pad.occupiedUid = nil
	end
	highPadRecords[uid] = nil
end

local function walkParade(record)
	local world = WorldBuilder.GetWorld()
	local startTime = os.clock()
	while record.alive and record.model.Parent do
		local elapsed = os.clock() - startTime
		local alpha = math.min(1, elapsed / Config.PARADE_WALK_TIME)
		local position = world.paradeStart:Lerp(world.paradeEnd, alpha)
		record.model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0))
		if alpha >= 1 then
			break
		end
		task.wait(0.1)
	end
	-- Walked the whole lane unbought: it wanders off.
	if record.alive then
		parade[record.uid] = nil
		record.model:Destroy()
	end
end

local function spawnParadeBrainrot()
	local rarity = Catalog.RollRarity(rng, 0)
	local entry = Catalog.GetRandomOfRarity(rarity, rng)
	local mutation = Catalog.RollMutation(rng, 0)
	local uid = HttpService:GenerateGUID(false)

	local model = BrainrotFactory.Build(entry, mutation, uid, true)
	local world = WorldBuilder.GetWorld()
	model:PivotTo(CFrame.new(world.paradeStart))
	model.Parent = paradeFolder

	local record = {
		uid = uid,
		catalogId = entry.id,
		name = entry.name,
		rarity = rarity,
		mutation = mutation,
		model = model,
		alive = true,
	}
	parade[uid] = record

	local clicker = model.PrimaryPart:FindFirstChild("Clicker")
	if clicker then
		clicker.MouseClick:Connect(function(player)
			if buyHandler then
				buyHandler(player, uid)
			end
		end)
	end

	task.spawn(walkParade, record)
end

local function spawnHighPadBrainrot(pad)
	local rarity = Catalog.RollTier(rng, Config.HIGH_PAD_WEIGHTS)
	local entry = Catalog.GetRandomOfRarity(rarity, rng)
	local mutation = Catalog.RollMutation(rng, 0)
	local uid = HttpService:GenerateGUID(false)

	local model = BrainrotFactory.Build(entry, mutation, uid, false)
	model:PivotTo(CFrame.new(pad.position + Vector3.new(0, 1.6, 0)))
	model.Parent = paradeFolder

	local record = {
		uid = uid,
		catalogId = entry.id,
		name = entry.name,
		rarity = rarity,
		mutation = mutation,
		model = model,
		pad = pad,
	}
	highPadRecords[uid] = record
	pad.occupiedUid = uid

	local clicker = model.PrimaryPart:FindFirstChild("Clicker")
	if clicker then
		clicker.MouseClick:Connect(function(player)
			if grabHandler then
				grabHandler(player, uid)
			end
		end)
	end
end

function Spawner.Start()
	paradeFolder = Instance.new("Folder")
	paradeFolder.Name = "ParadeBrainrots"
	paradeFolder.Parent = workspace

	task.spawn(function()
		while true do
			spawnParadeBrainrot()
			task.wait(Config.PARADE_SPAWN_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.HIGH_PAD_INTERVAL)
			local world = WorldBuilder.GetWorld()
			for _, pad in ipairs(world.highPads) do
				if not pad.occupiedUid and rng:NextNumber() < 0.7 then
					spawnHighPadBrainrot(pad)
				end
			end
		end
	end)
end

return Spawner
