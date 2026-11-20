-- GachaSystem: the Gacha Machine by the cafeteria. Press [E] to open the
-- gacha panel; one roll costs a flat $1,000 and drops a random brainrot
-- straight onto a free pedestal in your classroom. No free pedestal, no roll:
-- the machine tells you the base is full before it takes your cash.

local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local CarrySystem = require(script.Parent.CarrySystem)
local WorldBuilder = require(script.Parent.WorldBuilder)

local GachaSystem = {}

local rng = Random.new(os.time() + 21)

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

function GachaSystem.Start()
	local prompt = WorldBuilder.GetGachaPrompt()
	if prompt then
		prompt.Triggered:Connect(function(player)
			local event = RemoteHub.Get("OpenGacha")
			if event then
				event:FireClient(player)
			end
		end)
	end
end

function GachaSystem.TryRoll(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local base = WorldBuilder.GetBase(state.baseIndex)
	if not base then
		return
	end
	-- A full base blocks the roll before any cash changes hands.
	local pedestal = WorldBuilder.GetFreePedestal(base, state.placed)
	if not pedestal then
		notify(player, "Base full! Place or fuse some brainrots first.", "warn")
		return
	end
	if not PlayerState.TrySpend(state, Config.GACHA_COST) then
		notify(player, "A gacha roll costs $" .. Config.GACHA_COST .. " — you have $" .. state.cash .. ".", "warn")
		return
	end
	local rarity = Catalog.RollTier(rng, Config.GACHA_WEIGHTS)
	local entry = Catalog.GetRandomOfRarity(rarity, rng)
	local mutation = Catalog.RollMutation(rng, 0)
	local uid = HttpService:GenerateGUID(false)
	local model = BrainrotFactory.Build(entry, mutation, uid, false)
	local record = {
		uid = uid,
		catalogId = entry.id,
		name = entry.name,
		rarity = rarity,
		mutation = mutation,
		model = model,
	}
	CarrySystem.PlaceRecordOnPedestal(player, state, record, base, pedestal, true)
	state.owned[entry.id] = true
	PlayerState.PushUpdate(state)
	local resultText = "GACHA! You rolled " .. entry.name .. " (" .. rarity .. ")"
	if mutation then
		resultText ..= " · " .. mutation
	end
	resultText ..= " — $" .. Catalog.MutatedIncome(entry, mutation) .. "/s!"
	notify(player, resultText, "quest")
end

return GachaSystem
