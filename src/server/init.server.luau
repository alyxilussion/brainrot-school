-- Server: boots Brainrot School: Enchanted Academy. Builds the remotes and
-- the school, wires every system to one shared context, gives each student
-- a classroom (taking one back from a rival when needed), spawns and
-- respawns them there, and streams each student's state to their Hud.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local WorldBuilder = require(script.WorldBuilder)
local BrainrotFactory = require(script.BrainrotFactory)
local PlayerState = require(script.PlayerState)
local CarrySystem = require(script.CarrySystem)
local StealSystem = require(script.StealSystem)
local PullPushSystem = require(script.PullPushSystem)
local QuestSystem = require(script.QuestSystem)
local ParadeSpawner = require(script.ParadeSpawner)
local EconomySystem = require(script.EconomySystem)
local ThreatSystem = require(script.ThreatSystem)
local RivalSystem = require(script.RivalSystem)

Players.CharacterAutoLoads = true
Players.RespawnTime = 3

-- Remotes: exactly the names in Config.REMOTES.
local function createRemotes()
	local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	local remotes = {}
	for _, group in pairs(Config.REMOTES) do
		for _, name in ipairs(group) do
			local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
			remotes[name] = remote
		end
	end
	folder.Parent = ReplicatedStorage
	return remotes
end

local remotes = createRemotes()
WorldBuilder.SetupLighting(Lighting)
WorldBuilder.Build(Workspace)

-- The shared context every system receives in Init.
local G = {
	Remotes = remotes,
	World = WorldBuilder,
	Factory = BrainrotFactory,
	State = PlayerState,
	Carry = CarrySystem,
	Steal = StealSystem,
	PullPush = PullPushSystem,
	Quests = QuestSystem,
	Parade = ParadeSpawner,
	Economy = EconomySystem,
	Threats = ThreatSystem,
	Rivals = RivalSystem,
}

function G.notify(state, text, color)
	if state and not state.isBot and state.player and state.player.Parent then
		remotes.Notify:FireClient(state.player, text, color)
	end
end

-- Full-width event banner, for everyone or for one student.
function G.banner(text, color, seconds, state)
	if state then
		if not state.isBot and state.player and state.player.Parent then
			remotes.EventBanner:FireClient(state.player, text, color, seconds)
		end
		return
	end
	remotes.EventBanner:FireAllClients(text, color, seconds)
end

-- Effects: tether, shockwave, floating text, sounds. A sound may be private.
function G.fx(kind, a, b, c)
	if kind == "sound" and type(c) == "table" then
		if not c.isBot and c.player and c.player.Parent then
			remotes.Fx:FireClient(c.player, kind, a, b)
		end
		return
	end
	remotes.Fx:FireAllClients(kind, a, b, c)
end

local systems: { any } = { CarrySystem, StealSystem, PullPushSystem, QuestSystem, EconomySystem, ParadeSpawner, ThreatSystem, RivalSystem }
for _, system in ipairs(systems) do
	system.Init(G)
end

local function now()
	return Workspace:GetServerTimeNow()
end

-- Everything the Hud draws, in one table.
local function buildStatePayload(state)
	local t = now()
	local base = state.baseIndex and WorldBuilder.GetBase(state.baseIndex)
	local carrying = {}
	for _, record in ipairs(state.carrying) do
		table.insert(carrying, { name = record.name, rarity = record.rarity, mutation = record.mutation })
	end
	local placed, tierCounts = {}, {}
	for _, record in pairs(state.placed) do
		table.insert(placed, { id = record.catalogId, mutation = record.mutation })
		tierCounts[record.rarity] = (tierCounts[record.rarity] or 0) + 1
	end
	local owned = {}
	for id in pairs(state.owned) do
		table.insert(owned, id)
	end
	local upgradeCosts = {}
	for id, level in pairs(state.upgrades) do
		upgradeCosts[id] = Config.NextUpgradeCost(id, level) or 0
	end
	return {
		cash = state.cash,
		income = PlayerState.IncomePerSecond(state, t),
		multiplier = PlayerState.Multiplier(state, t),
		rebirths = state.rebirths,
		rebirthCost = PlayerState.RebirthCost(state),
		upgrades = state.upgrades,
		upgradeCosts = upgradeCosts,
		carrying = carrying,
		capacity = PlayerState.CarryCapacity(state),
		baseIndex = state.baseIndex,
		baseCenter = base and base.center or nil,
		placedCount = #placed,
		slotCount = base and #base.pedestals or 0,
		tierCounts = tierCounts,
		owned = owned,
		ownedCount = state.ownedCount,
		catalogCount = Catalog.Count,
		lockEndsAt = state.lockEndsAt,
		lockReadyAt = state.lockReadyAt,
		pullReadyAt = state.pullReadyAt,
		pushReadyAt = state.pushReadyAt,
		buffUntil = state.buffUntil,
		quest = QuestSystem.View(state),
	}
end

local function sendState(state)
	state.dirty = false
	remotes.StateUpdate:FireClient(state.player, buildStatePayload(state))
end

-- A classroom for a new student: a free one, else one taken back from a rival.
local function assignBase(state)
	for index = 1, Config.BASE_COUNT do
		local base = WorldBuilder.GetBase(index)
		if not base.owner then
			return index
		end
	end
	return RivalSystem.ReleaseBase()
end

local function spawnAtBase(state, character)
	local base = state.baseIndex and WorldBuilder.GetBase(state.baseIndex)
	if not base then
		return
	end
	local stand = (base.cframe * CFrame.new(0, 3.5, -6)).Position
	local door = base.door + Vector3.new(0, 3.5, 0)
	character:PivotTo(CFrame.lookAt(stand, door))
end

local function onCharacterAdded(state, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait()
	spawnAtBase(state, character)
	EconomySystem.ApplyWalkSpeed(state)
	if humanoid then
		humanoid.Died:Connect(function()
			CarrySystem.DropAll(state, state.lastPosition)
		end)
	end
end

local function onPlayerAdded(player)
	local state = PlayerState.Create(player, { player = player, userId = player.UserId, name = player.DisplayName })
	QuestSystem.Setup(state)
	local index = assignBase(state)
	if index then
		local base = WorldBuilder.GetBase(index)
		state.baseIndex = index
		base.owner = state
		WorldBuilder.SetBaseOwnerName(base, player.DisplayName)
		StealSystem.RefreshBase(state)
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(state, character)
	end)
	player.CharacterRemoving:Connect(function()
		if #state.carrying > 0 then
			CarrySystem.DropAll(state, state.lastPosition)
		end
	end)
	if player.Character then
		task.spawn(onCharacterAdded, state, player.Character)
	end
	sendState(state)
	G.notify(state, "Welcome to Classroom " .. tostring(index or "?") .. "! Buy a brainrot on the Parade Lane.", Color3.fromRGB(255, 220, 90))
end

local function onPlayerRemoving(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	CarrySystem.DropAll(state, state.lastPosition)
	for _, record in pairs(table.clone(state.placed)) do
		CarrySystem.Destroy(record)
	end
	local base = state.baseIndex and WorldBuilder.GetBase(state.baseIndex)
	if base then
		base.owner = nil
		WorldBuilder.ResetPedestalRows(base)
		WorldBuilder.SetBaseOwnerName(base, nil)
		WorldBuilder.SetBaseLockVisual(base, false, 0)
	end
	PlayerState.Remove(player)
	task.defer(RivalSystem.FillFreeBases, #Players:GetPlayers())
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Stream state: changed students at once, everyone at least once a second.
task.spawn(function()
	local tick = 0
	while true do
		task.wait(0.25)
		tick += 1
		for _, state in pairs(PlayerState.All()) do
			if not state.isBot and state.player.Parent and (state.dirty or tick % 4 == 0) then
				sendState(state)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		RivalSystem.FillFreeBases(#Players:GetPlayers())
	end
end)
