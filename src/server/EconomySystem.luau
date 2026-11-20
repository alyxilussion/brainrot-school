-- EconomySystem: money in and out. The income tick pays every placed
-- brainrot each second; the Upgrade Shop, Gacha Machine, Fuse Lab and Rebirth
-- Altar spend it; benches and swings give the Fresh buff. Station prompts
-- open the matching Hud panel, and every purchase is checked here.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local EconomySystem = {}

local G
local rng = Random.new()

local function now()
	return Workspace:GetServerTimeNow()
end

-- Every cash change goes through here; income counts toward "earn" quests.
function EconomySystem.AddCash(state, amount, reason)
	state.cash += amount
	if reason == "income" then
		G.Quests.OnEvent(state, "earn", amount)
	end
	G.State.Changed(state)
end

-- Walk speed from Speed Shoes, slowed while carrying or staggered.
function EconomySystem.ApplyWalkSpeed(state)
	if state.isBot then
		return
	end
	local character = state.player and state.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local speed = 16 + 4 * (state.upgrades.speed or 0)
	if #state.carrying > 0 then
		speed *= 0.85
	end
	if state.staggerUntil > now() then
		speed = Config.STAGGER_SPEED
	end
	humanoid.WalkSpeed = speed
end

local function incomeTick()
	local t = now()
	for _, state in pairs(G.State.All()) do
		local income = G.State.IncomePerSecond(state, t)
		if income > 0 then
			EconomySystem.AddCash(state, math.floor(income + 0.5), "income")
		end
	end
end

function EconomySystem.BuyUpgrade(state, upgradeId)
	local level = state.upgrades[upgradeId]
	local cost = level and Config.NextUpgradeCost(upgradeId, level)
	if not cost then
		G.notify(state, "Already maxed!", Color3.fromRGB(200, 200, 220))
		return
	end
	if state.cash < cost then
		G.notify(state, "Need " .. Config.FormatMoney(cost - state.cash) .. " more", Color3.fromRGB(255, 120, 120))
		return
	end
	state.cash -= cost
	state.upgrades[upgradeId] = level + 1
	if upgradeId == "slot" and state.baseIndex then
		G.World.AddPedestalRow(G.World.GetBase(state.baseIndex))
	end
	EconomySystem.ApplyWalkSpeed(state)
	G.notify(state, Config.UPGRADES[upgradeId].name .. " level " .. (level + 1) .. "!", Color3.fromRGB(120, 255, 150))
	G.fx("sound", "upgrade", nil, state)
	G.Quests.OnEvent(state, "upgrade", 1)
	G.State.Changed(state)
end

-- Rebirth: cash and upgrades reset, brainrots stay, income x1.5 more.
function EconomySystem.Rebirth(state)
	local cost = G.State.RebirthCost(state)
	if state.cash < cost then
		G.notify(state, "Rebirth needs " .. Config.FormatMoney(cost), Color3.fromRGB(255, 120, 120))
		return
	end
	state.rebirths += 1
	state.cash = Config.START_CASH
	for id in pairs(state.upgrades) do
		if id ~= "slot" then
			state.upgrades[id] = 0
		end
	end
	EconomySystem.ApplyWalkSpeed(state)
	G.banner(string.upper(state.name) .. " REBIRTHED! x" .. string.format("%.1f", 1 + 0.5 * state.rebirths) .. " INCOME", Color3.fromRGB(255, 120, 220), 4)
	G.fx("sound", "rebirth", nil, state)
	G.Quests.OnEvent(state, "rebirth", 1)
	G.State.Changed(state)
end

-- Gacha: $1,000 for a roll on kinder odds; the prize goes straight home.
function EconomySystem.RollGacha(state)
	if state.cash < Config.GACHA_COST then
		G.notify(state, "Gacha costs " .. Config.FormatMoney(Config.GACHA_COST), Color3.fromRGB(255, 120, 120))
		return
	end
	local base = state.baseIndex and G.World.GetBase(state.baseIndex)
	local pedestal = base and G.World.GetFreePedestal(base, state.placed)
	if not pedestal then
		G.notify(state, "Classroom full! Sell one or buy Extra Slot first.", Color3.fromRGB(255, 180, 90))
		return
	end
	state.cash -= Config.GACHA_COST
	local luck = state.upgrades.luck or 0
	local rarity = Catalog.RollTier(rng, Catalog.ApplyLuck(Config.GACHA_WEIGHTS, luck))
	local entry = Catalog.GetRandomOfRarity(rarity, rng)
	local mutation = Catalog.RollMutation(rng, luck)
	local record = G.Carry.NewRecord(entry, mutation, CFrame.new(pedestal.position), "placed")
	G.Carry.Place(state, record, pedestal)
	G.Quests.OnEvent(state, "gacha", 1)
	G.Remotes.OpenPanel:FireClient(state.player, "gachaResult", {
		name = entry.name,
		rarity = entry.rarity,
		mutation = mutation,
		income = Catalog.MutatedIncome(entry, mutation),
		blurb = entry.blurb,
	})
	G.fx("confetti", pedestal.position + Vector3.new(0, 3, 0))
	if Config.RARITY_RANK[rarity] >= Config.RARITY_RANK.Mythic then
		G.banner(string.upper(state.name) .. " PULLED A " .. string.upper(rarity) .. " FROM THE GACHA!", Config.RARITY_COLORS[rarity], 4)
	end
	G.State.Changed(state)
end

-- Fuse Lab: three placed brainrots of one tier become one of the next tier.
-- Three PRINCIPAL fuse into a random Secret; Secret is the top of the
-- ladder and cannot fuse further.
function EconomySystem.Fuse(state, rarity)
	local nextRarity = typeof(rarity) == "string" and Catalog.NextTier(rarity)
	if not nextRarity then
		G.notify(state, "Pick a tier below Secret", Color3.fromRGB(255, 120, 120))
		return
	end
	local picks = {}
	for _, record in pairs(state.placed) do
		if record.rarity == rarity and #picks < 3 then
			table.insert(picks, record)
		end
	end
	table.sort(picks, function(a, b)
		return a.pedestal.slot < b.pedestal.slot
	end)
	if #picks < 3 then
		G.notify(state, "Need 3 " .. rarity .. " brainrots in your classroom", Color3.fromRGB(255, 120, 120))
		return
	end
	local pedestal = picks[1].pedestal
	for _, record in ipairs(picks) do
		G.Carry.Destroy(record)
	end
	local entry = Catalog.GetRandomOfRarity(nextRarity, rng)
	local mutation = Config.RARITY_RANK[nextRarity] >= Config.RARITY_RANK.Ultimate and Catalog.RandomMutation(rng) or Catalog.RollMutation(rng, 1)
	local record = G.Carry.NewRecord(entry, mutation, CFrame.new(pedestal.position), "placed")
	G.Carry.Place(state, record, pedestal)
	G.fx("confetti", pedestal.position + Vector3.new(0, 3, 0))
	G.notify(state, "FUSED! " .. entry.name .. " (" .. nextRarity .. ")", Config.RARITY_COLORS[nextRarity])
	G.Quests.OnEvent(state, "fuse", 1)
	G.State.Changed(state)
end

-- Benches and swings: the prompt sits you down; sitting gives the buff.
local function setupSeat(seatInfo)
	local seat = seatInfo.seat
	seatInfo.prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not seat.Occupant and humanoid.Health > 0 then
			seat.Disabled = false
			seat:Sit(humanoid)
		end
	end)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local humanoid = seat.Occupant
		seatInfo.prompt.Enabled = humanoid == nil
		if not humanoid then
			seat.Disabled = true
			return
		end
		local player = game:GetService("Players"):GetPlayerFromCharacter(humanoid.Parent)
		local state = player and G.State.Get(player)
		if not state then
			return
		end
		local t = now()
		if t >= state.sitReadyAt then
			state.buffUntil = t + Config.SIT_BUFF_DURATION
			state.sitReadyAt = t + Config.SIT_COOLDOWN
			G.notify(state, "FRESH! +10% income for " .. Config.SIT_BUFF_DURATION .. "s", Color3.fromRGB(120, 230, 255))
			G.Quests.OnEvent(state, "sit", 1)
			G.State.Changed(state)
		else
			G.notify(state, "Fresh buff recharging: " .. math.ceil(state.sitReadyAt - t) .. "s", Color3.fromRGB(200, 200, 220))
		end
	end)
end

function EconomySystem.Init(context)
	G = context
	local remotes = G.Remotes
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
		local state = G.State.Get(player)
		if state and typeof(upgradeId) == "string" and Config.UPGRADES[upgradeId] then
			EconomySystem.BuyUpgrade(state, upgradeId)
		end
	end)
	remotes.DoRebirth.OnServerEvent:Connect(function(player)
		local state = G.State.Get(player)
		if state then
			EconomySystem.Rebirth(state)
		end
	end)
	remotes.RollGacha.OnServerEvent:Connect(function(player)
		local state = G.State.Get(player)
		if state then
			EconomySystem.RollGacha(state)
		end
	end)
	remotes.FuseBrainrots.OnServerEvent:Connect(function(player, rarity)
		local state = G.State.Get(player)
		if state then
			EconomySystem.Fuse(state, rarity)
		end
	end)
	-- Station prompts open their panel on the Hud.
	local panels = { gacha = "gacha", upgrades = "upgrades", quests = "quests", rebirth = "rebirth", fuse = "fuse" }
	for stationName, panel in pairs(panels) do
		local prompt = G.World.GetWorld().stations[stationName]
		if prompt then
			prompt.Triggered:Connect(function(player)
				remotes.OpenPanel:FireClient(player, panel)
			end)
		end
	end
	for _, seatInfo in ipairs(G.World.GetWorld().seats) do
		setupSeat(seatInfo)
	end
	task.spawn(function()
		while true do
			task.wait(1)
			incomeTick()
		end
	end)
end

return EconomySystem
