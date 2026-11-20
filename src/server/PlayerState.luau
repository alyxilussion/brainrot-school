-- PlayerState: the single store for everything about a player.
-- The server owns this table; the client only ever sees a snapshot through
-- StateUpdate. No other module keeps its own copy of money, brainrots or quests.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local RemoteHub = require(script.Parent.RemoteHub)

local PlayerState = {}

local states = {}

-- A fresh student's record. baseIndex is assigned by the bootstrap.
local function newState(player, baseIndex)
	return {
		player = player,
		cash = Config.START_CASH,
		multiplier = 1,
		rebirths = 0,
		baseIndex = baseIndex,
		carried = {}, -- list of brainrot records the player is holding
		placed = {}, -- [pedestalId] = brainrot record earning money
		owned = {}, -- [catalogId] = true, for the Report Card
		upgrades = { speed = 0, bag = 0, lock = 0, slot = 0, luck = 0 },
		lockUntil = 0, -- os.clock() timestamp; base is locked while this is in the future
		lockReadyAt = 0, -- lock can be used again after this timestamp
		shieldUntil = 0, -- pull/push immunity while in the future
		slowUntil = 0, -- pull slow effect while in the future
		freshUntil = 0, -- Fresh buff (from sitting) while in the future
		freshReadyAt = 0, -- the Fresh buff can be earned again after this timestamp
		lastPullAt = -100,
		lastPushAt = -100,
		questChapter = 1,
		questStep = 1,
		questProgress = {}, -- [questKey] = count so far
		dailyProgress = {}, -- [dailyKey] = count so far
		dailyDone = {}, -- [dailyKey] = true once its reward is paid
		dailyDay = tonumber(os.date("%j")), -- day-of-year the daily quests belong to
	}
end

function PlayerState.Create(player, baseIndex)
	local state = newState(player, baseIndex)
	states[player] = state
	return state
end

function PlayerState.Remove(player)
	states[player] = nil
end

function PlayerState.Get(player)
	return states[player]
end

function PlayerState.All()
	return states
end

function PlayerState.AddCash(state, amount)
	state.cash += amount
end

-- Spends cash when the player can afford it; returns true on success.
function PlayerState.TrySpend(state, amount)
	if state.cash < amount then
		return false
	end
	state.cash -= amount
	return true
end

function PlayerState.GetCarryCapacity(state)
	return Config.CARRY_CAPACITY_BASE + state.upgrades.bag
end

function PlayerState.GetLockDuration(state)
	if state.upgrades.lock > 0 then
		return Config.LOCK_DURATION_UPGRADED
	end
	return Config.LOCK_DURATION
end

function PlayerState.IsLocked(state)
	return os.clock() < state.lockUntil
end

function PlayerState.IsShielded(state)
	return os.clock() < state.shieldUntil
end

function PlayerState.CountOwned(state)
	local count = 0
	for _ in pairs(state.owned) do
		count += 1
	end
	return count
end

-- Dollars per second the player's placed brainrots earn right now, before the
-- income tick adds it. Mutation, rebirth, Report Card and Fresh bonuses apply.
function PlayerState.ComputeIncome(state)
	local base = 0
	for _, record in pairs(state.placed) do
		base += Catalog.MutatedIncome(Catalog.ById[record.catalogId], record.mutation)
	end
	local reportBonus = 1 + PlayerState.CountOwned(state) * Config.REPORT_CARD_BONUS_PER_ENTRY
	local freshBonus = 1
	if os.clock() < state.freshUntil then
		freshBonus = Config.SIT_BUFF_MULTIPLIER
	end
	return math.floor(base * state.multiplier * reportBonus * freshBonus)
end

function PlayerState.IsFresh(state)
	return os.clock() < state.freshUntil
end

-- The snapshot the HUD needs. Sent every income tick and after every action.
function PlayerState.Snapshot(state)
	local carriedNames = {}
	for _, record in ipairs(state.carried) do
		table.insert(carriedNames, record.name)
	end
	local placedCount = 0
	for _ in pairs(state.placed) do
		placedCount += 1
	end
	-- The Fuse UI needs the placed brainrots themselves, not just the count.
	local placedList = {}
	for pedestalId, record in pairs(state.placed) do
		table.insert(placedList, {
			pedestalId = pedestalId,
			catalogId = record.catalogId,
			name = record.name,
			rarity = record.rarity,
			mutation = record.mutation,
		})
	end
	return {
		cash = state.cash,
		income = PlayerState.ComputeIncome(state),
		multiplier = state.multiplier,
		rebirths = state.rebirths,
		carried = carriedNames,
		carriedCount = #state.carried,
		carryCapacity = PlayerState.GetCarryCapacity(state),
		placedCount = placedCount,
		placed = placedList,
		ownedCount = PlayerState.CountOwned(state),
		ownedTotal = Catalog.Count,
		owned = state.owned,
		upgrades = state.upgrades,
		locked = PlayerState.IsLocked(state),
		lockSecondsLeft = math.max(0, math.ceil(state.lockUntil - os.clock())),
		lockReadyIn = math.max(0, math.ceil(state.lockReadyAt - os.clock())),
		fresh = PlayerState.IsFresh(state),
		freshSecondsLeft = math.max(0, math.ceil(state.freshUntil - os.clock())),
		freshReadyIn = math.max(0, math.ceil(state.freshReadyAt - os.clock())),
		questChapter = state.questChapter,
		questStep = state.questStep,
		questProgress = state.questProgress,
		dailyProgress = state.dailyProgress,
		dailyDone = state.dailyDone,
		dailyDay = state.dailyDay,
	}
end

-- Sends a fresh snapshot to the player's HUD. Called after every action that
-- changes money, brainrots, quests or the lock, and once a second by the
-- income ticker. Safe to call before the remotes exist: it just skips.
function PlayerState.PushUpdate(state)
	local event = RemoteHub.Get("StateUpdate")
	if event and state.player then
		event:FireClient(state.player, PlayerState.Snapshot(state))
	end
end

return PlayerState
