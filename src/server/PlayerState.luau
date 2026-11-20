-- PlayerState: one record per base owner, a real Player or an NPC rival.
-- Cash, upgrades, the Report Card, placed and carried brainrots, the base
-- lock, cooldowns and buffs. Keyed by the Player instance or the rival table.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local PlayerState = {}

local states = {}
PlayerState.OnChanged = nil -- set by the Server: flushes StateUpdate to the owner

function PlayerState.Create(key, info)
	local upgrades = {}
	for _, id in ipairs(Config.UPGRADE_ORDER) do
		upgrades[id] = 0
	end
	local state = {
		key = key,
		isBot = info.isBot == true,
		player = info.player,
		userId = info.userId or -1,
		name = info.name or "Student",
		cash = info.cash or Config.START_CASH,
		rebirths = 0,
		upgrades = upgrades,
		owned = {}, -- Report Card: catalogId -> true, ever owned
		ownedCount = 0,
		baseIndex = nil,
		placed = {}, -- pedestal id -> brainrot record
		carrying = {}, -- brainrot records in hands, in pickup order
		lockEndsAt = 0,
		lockReadyAt = 0,
		pullReadyAt = 0,
		pushReadyAt = 0,
		immuneUntil = 0,
		staggerUntil = 0,
		buffUntil = 0,
		sitReadyAt = 0,
		chaptersDone = 0,
		quest = nil, -- filled by QuestSystem
	}
	states[key] = state
	return state
end

function PlayerState.Get(key)
	return states[key]
end

function PlayerState.Remove(key)
	states[key] = nil
end

function PlayerState.All()
	return states
end

-- The state whose character or puppet this model is, if any.
function PlayerState.FromCharacter(model)
	for _, state in pairs(states) do
		local character = PlayerState.CharacterOf(state)
		if character and character == model then
			return state
		end
	end
	return nil
end

function PlayerState.CharacterOf(state)
	if state.isBot then
		return state.key.model
	end
	return state.player and state.player.Character or nil
end

function PlayerState.RootOf(state)
	local character = PlayerState.CharacterOf(state)
	if not character then
		return nil
	end
	if state.isBot then
		return state.key.root
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

function PlayerState.MarkOwned(state, catalogId)
	if not state.owned[catalogId] then
		state.owned[catalogId] = true
		state.ownedCount += 1
	end
end

function PlayerState.CarryCapacity(state)
	return Config.CARRY_CAPACITY_BASE + (state.upgrades.bag or 0)
end

function PlayerState.LockDuration(state)
	return (state.upgrades.lock or 0) > 0 and Config.LOCK_DURATION_UPGRADED or Config.LOCK_DURATION
end

function PlayerState.IsLocked(state, now)
	return state.lockEndsAt > now
end

function PlayerState.RebirthCost(state)
	return Config.REBIRTH_BASE_COST * 3 ^ state.rebirths
end

-- Income multiplier: rebirths, Report Card, quest chapters and the Fresh buff.
function PlayerState.Multiplier(state, now)
	local multiplier = 1 + 0.5 * state.rebirths
	multiplier *= 1 + Config.REPORT_CARD_BONUS_PER_ENTRY * state.ownedCount
	multiplier *= 1 + Config.QUEST_CHAPTER_BONUS * state.chaptersDone
	if state.buffUntil > now then
		multiplier *= Config.SIT_BUFF_MULTIPLIER
	end
	return multiplier
end

function PlayerState.IncomePerSecond(state, now)
	local total = 0
	for _, record in pairs(state.placed) do
		total += Catalog.MutatedIncome(Catalog.ById[record.catalogId], record.mutation)
	end
	return total * PlayerState.Multiplier(state, now)
end

function PlayerState.PlacedCount(state)
	local count = 0
	for _ in pairs(state.placed) do
		count += 1
	end
	return count
end

function PlayerState.Changed(state)
	if not state.isBot then
		state.dirty = true
	end
end

return PlayerState
