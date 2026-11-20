-- FuseSystem: the Fuse Lab by the gym. Pick three brainrots of the same tier
-- from your classroom and fuse them into one random brainrot of the next tier.
-- The three brainrots are the cost — the fuse itself is free. Three PRINCIPAL
-- brainrots fuse into a random Secret, and three Secret fuse into a random
-- Secret with a random mutation: Secret is the top of the ladder.

local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.BrainrotCatalog)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local CarrySystem = require(script.Parent.CarrySystem)
local StealSystem = require(script.Parent.StealSystem)
local WorldBuilder = require(script.Parent.WorldBuilder)

local FuseSystem = {}

local rng = Random.new(os.time() + 33)

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

function FuseSystem.Start()
	local prompt = WorldBuilder.GetFusePrompt()
	if prompt then
		prompt.Triggered:Connect(function(player)
			local event = RemoteHub.Get("OpenFuse")
			if event then
				event:FireClient(player)
			end
		end)
	end
end

function FuseSystem.TryFuse(player, pedestalIds)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	if type(pedestalIds) ~= "table" or #pedestalIds ~= 3 then
		return
	end
	-- All three must be distinct pedestals holding brainrots of one tier.
	if pedestalIds[1] == pedestalIds[2] or pedestalIds[1] == pedestalIds[3] or pedestalIds[2] == pedestalIds[3] then
		notify(player, "Pick three different brainrots!", "warn")
		return
	end
	local tier = nil
	for _, pedestalId in ipairs(pedestalIds) do
		local record = state.placed[pedestalId]
		if not record then
			notify(player, "One of those brainrots is gone.", "warn")
			return
		end
		if tier and record.rarity ~= tier then
			notify(player, "Fuse needs 3 brainrots of the SAME tier!", "warn")
			return
		end
		tier = record.rarity
	end
	-- The result: one tier up, or a mutated Secret at the top of the ladder.
	local nextTier = Catalog.NextTier(tier)
	local entry
	local mutation = nil
	if nextTier then
		entry = Catalog.GetRandomOfRarity(nextTier, rng)
	else
		entry = Catalog.GetRandomOfRarity(tier, rng)
		mutation = Catalog.RandomMutation(rng)
	end
	-- Consume the three inputs, prompts included.
	for _, pedestalId in ipairs(pedestalIds) do
		local record = state.placed[pedestalId]
		if record then
			StealSystem.RemovePrompt(record.uid)
		end
		CarrySystem.RemovePlaced(player, pedestalId, true)
	end
	-- The result lands on one of the freed pedestals.
	local base = WorldBuilder.GetBase(state.baseIndex)
	local pedestal = WorldBuilder.GetFreePedestal(base, state.placed)
	local uid = HttpService:GenerateGUID(false)
	local model = BrainrotFactory.Build(entry, mutation, uid, false)
	local resultRecord = {
		uid = uid,
		catalogId = entry.id,
		name = entry.name,
		rarity = entry.rarity,
		mutation = mutation,
		model = model,
	}
	CarrySystem.PlaceRecordOnPedestal(player, state, resultRecord, base, pedestal, true)
	state.owned[entry.id] = true
	PlayerState.PushUpdate(state)
	local resultText = "FUSE! 3x " .. tier .. " became " .. entry.name .. " (" .. entry.rarity .. ")"
	if mutation then
		resultText ..= " · " .. mutation
	end
	resultText ..= " — $" .. Catalog.MutatedIncome(entry, mutation) .. "/s!"
	notify(player, resultText, "quest")
end

return FuseSystem
