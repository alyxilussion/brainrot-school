-- StealSystem: Press [E] Steal on every brainrot in someone else's base,
-- Press [E] Sell on your own, and the base lock [L] with its shield, laser
-- gate and countdown. A locked base keeps its prompts visible, reading
-- "Locked 42s", so a thief always knows why the steal is refused.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local StealSystem = {}

local G

local function now()
	return Workspace:GetServerTimeNow()
end

local function secondsLeft(state)
	return math.max(0, math.ceil(state.lockEndsAt - now()))
end

-- Owner alert: banner, toast and an alarm sound on the owner's screen only.
local function alertOwner(owner, thiefName, record)
	if owner.isBot then
		return
	end
	G.notify(owner, thiefName .. " is stealing your " .. record.name .. "!", Color3.fromRGB(255, 90, 90))
	G.banner("THIEF IN YOUR CLASSROOM! PULL [Q] or PUSH [F] them to get it back", Color3.fromRGB(230, 60, 70), 5, owner)
	G.fx("sound", "alarm", nil, owner)
end

-- A thief (player or rival) takes a placed brainrot. Returns true on success.
function StealSystem.TrySteal(thief, record)
	local owner = record.owner
	if record.status ~= "placed" or not owner or owner == thief then
		return false
	end
	local root = G.State.RootOf(thief)
	local body = record.model and record.model.PrimaryPart
	if not root or not body or (root.Position - body.Position).Magnitude > Config.STEAL_RANGE + 6 then
		return false
	end
	if G.State.IsLocked(owner, now()) then
		G.notify(thief, "Locked for " .. secondsLeft(owner) .. "s — come back later!", Color3.fromRGB(120, 200, 255))
		return false
	end
	local name = record.name
	-- TakeIntoHands checks capacity before it touches the base, so a full
	-- pair of hands never deletes the brainrot.
	if not G.Carry.TakeIntoHands(thief, record) then
		return false
	end
	record.stolenFrom = owner
	alertOwner(owner, thief.name, record)
	G.notify(thief, "Stole " .. name .. "! Run it home!", Color3.fromRGB(255, 220, 90))
	G.Quests.OnEvent(thief, "steal", 1)
	G.fx("sound", "steal", record.model.PrimaryPart.Position)
	G.fx("text", record.model.PrimaryPart.Position, "STOLEN!", Color3.fromRGB(255, 90, 90))
	return true
end

local function refreshStealPrompt(record)
	local prompt = record.stealPrompt
	if not prompt or not prompt.Parent or not record.owner then
		return
	end
	if G.State.IsLocked(record.owner, now()) then
		prompt.ActionText = "Locked " .. secondsLeft(record.owner) .. "s"
	else
		prompt.ActionText = "Steal"
	end
end

-- Called by CarrySystem.Place: Steal for everyone else, Sell for the owner.
function StealSystem.AttachPrompts(record)
	local owner = record.owner
	local steal, sell = G.Factory.AttachBasePrompts(record.model, record, owner.userId, owner.isBot)
	record.stealPrompt = steal
	refreshStealPrompt(record)
	table.insert(record.connections, steal.Triggered:Connect(function(player)
		local thief = G.State.Get(player)
		if thief then
			StealSystem.TrySteal(thief, record)
		end
	end))
	if sell then
		table.insert(record.connections, sell.Triggered:Connect(function(player)
			local state = G.State.Get(player)
			if state and state == record.owner and record.status == "placed" then
				local value = G.Factory.SellValue(record)
				local position = record.model.PrimaryPart.Position
				G.Carry.Destroy(record)
				G.Economy.AddCash(state, value, "sell")
				G.notify(state, "Sold for " .. Config.FormatMoney(value), Color3.fromRGB(120, 255, 150))
				G.fx("text", position, "+" .. Config.FormatMoney(value), Color3.fromRGB(120, 255, 150))
				G.fx("sound", "coin", position)
			end
		end))
	end
end

-- [L]: shield the base. Recharges after it runs out.
function StealSystem.ToggleLock(state)
	local t = now()
	if G.State.IsLocked(state, t) then
		G.notify(state, "Already locked: " .. secondsLeft(state) .. "s left", Color3.fromRGB(120, 200, 255))
		return
	end
	if t < state.lockReadyAt then
		G.notify(state, "Lock recharging: " .. math.ceil(state.lockReadyAt - t) .. "s", Color3.fromRGB(255, 180, 90))
		return
	end
	if not state.baseIndex then
		return
	end
	local duration = G.State.LockDuration(state)
	state.lockEndsAt = t + duration
	state.lockReadyAt = t + duration + Config.LOCK_RECHARGE
	G.notify(state, "Classroom locked for " .. duration .. "s", Color3.fromRGB(120, 200, 255))
	G.fx("sound", "lock", G.World.GetBase(state.baseIndex).center)
	G.Quests.OnEvent(state, "lock", 1)
	StealSystem.RefreshBase(state)
	G.State.Changed(state)
end

-- Shield visuals, sign text and every Steal prompt in the base.
function StealSystem.RefreshBase(state)
	local base = state.baseIndex and G.World.GetBase(state.baseIndex)
	if not base then
		return
	end
	local locked = G.State.IsLocked(state, now())
	G.World.SetBaseLockVisual(base, locked, secondsLeft(state))
	for _, record in pairs(state.placed) do
		refreshStealPrompt(record)
	end
end

function StealSystem.Unlock(state)
	state.lockEndsAt = 0
	StealSystem.RefreshBase(state)
end

function StealSystem.Init(context)
	G = context
	G.Remotes.ToggleLock.OnServerEvent:Connect(function(player)
		local state = G.State.Get(player)
		if state then
			StealSystem.ToggleLock(state)
		end
	end)
	-- Countdown tick: the shield drops by itself when time runs out.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, state in pairs(G.State.All()) do
				if state.baseIndex and (state.lockEndsAt > 0) then
					StealSystem.RefreshBase(state)
					if state.lockEndsAt <= now() then
						state.lockEndsAt = 0
						G.notify(state, "Your lock wore off!", Color3.fromRGB(255, 180, 90))
						G.State.Changed(state)
					end
				end
			end
		end
	end)
end

return StealSystem
