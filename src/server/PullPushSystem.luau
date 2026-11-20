-- PullPushSystem: Tarik [Q] and Dorong [F]. The server picks or checks the
-- target (any student or rival thief in range, carriers first), spends the
-- cooldown only on a hit, and sends a short clamped knockback to the target's
-- own client (characters are client-owned, so server velocity would not
-- replicate). Carriers stagger and may drop what they carry.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local PullPushSystem = {}

local G
local rng = Random.new()

local MOVES = {
	pull = {
		range = Config.PULL_RANGE,
		cooldown = Config.PULL_COOLDOWN,
		speed = Config.PULL_SPEED,
		time = Config.PULL_TIME,
		loose = Config.PULL_LOOSE_CHANCE,
		readyKey = "pullReadyAt",
		quest = "pull",
		word = "PULLED!",
		color = Color3.fromRGB(255, 170, 60),
	},
	push = {
		range = Config.PUSH_RANGE,
		cooldown = Config.PUSH_COOLDOWN,
		speed = Config.PUSH_SPEED,
		time = Config.PUSH_TIME,
		loose = Config.PUSH_LOOSE_CHANCE,
		readyKey = "pushReadyAt",
		quest = "push",
		word = "PUSHED!",
		color = Color3.fromRGB(90, 190, 255),
	},
}

local function now()
	return Workspace:GetServerTimeNow()
end

local function horizontal(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- Can this state be hit right now? Not while immune, and not inside their
-- own locked classroom (the shield protects its owner too).
local function canHit(target, t)
	if target.immuneUntil > t then
		return false
	end
	local root = G.State.RootOf(target)
	if not root then
		return false
	end
	if target.baseIndex and G.State.IsLocked(target, t) and G.World.BaseAtPosition(root.Position) == target.baseIndex then
		return false
	end
	return true
end

-- Nearest valid target in range; carriers win ties within 6 studs.
local function findTarget(attacker, move, hint, t)
	local origin = G.State.RootOf(attacker)
	if not origin then
		return nil
	end
	local best, bestScore = nil, math.huge
	for _, state in pairs(G.State.All()) do
		if state ~= attacker and canHit(state, t) then
			local root = G.State.RootOf(state)
			local distance = (root.Position - origin.Position).Magnitude
			if distance <= move.range + 2 then
				local score = distance - (#state.carrying > 0 and 6 or 0)
				if hint and G.State.CharacterOf(state) == hint then
					score -= 1000
				end
				if score < bestScore then
					best, bestScore = state, score
				end
			end
		end
	end
	return best
end

-- Knockback velocity: horizontal, clamped, plus a small hop.
local function knockVelocity(moveName, attackerRoot, targetRoot, move)
	local direction = horizontal(targetRoot.Position - attackerRoot.Position)
	if direction.Magnitude < 0.1 then
		direction = horizontal(attackerRoot.CFrame.LookVector)
	end
	direction = direction.Unit
	if moveName == "pull" then
		direction = -direction
		-- Never pull further than the gap between the two of them.
		local gap = horizontal(targetRoot.Position - attackerRoot.Position).Magnitude
		local speed = math.min(move.speed, math.max(0, gap - 4) / move.time)
		return direction * speed + Vector3.new(0, Config.KNOCK_LIFT, 0)
	end
	return direction * move.speed + Vector3.new(0, Config.KNOCK_LIFT, 0)
end

function PullPushSystem.Hit(attacker, target, moveName, velocity, duration)
	local t = now()
	target.immuneUntil = t + Config.HIT_IMMUNITY
	target.staggerUntil = t + Config.STAGGER_TIME
	if target.isBot then
		G.Rivals.Knock(target, velocity, duration)
	else
		G.Remotes.Knockback:FireClient(target.player, velocity, duration, Config.STAGGER_TIME)
		G.Economy.ApplyWalkSpeed(target)
		task.delay(Config.STAGGER_TIME + 0.05, function()
			if G.State.Get(target.key) then
				G.Economy.ApplyWalkSpeed(target)
			end
		end)
	end
end

local function perform(attacker, moveName, hint)
	local move = MOVES[moveName]
	local t = now()
	if t < attacker[move.readyKey] then
		return
	end
	local target = findTarget(attacker, move, typeof(hint) == "Instance" and hint or nil, t)
	local attackerRoot = G.State.RootOf(attacker)
	if not target or not attackerRoot then
		G.notify(attacker, "No one in range (" .. move.range .. " studs)", Color3.fromRGB(200, 200, 220))
		return -- no cooldown spent on a miss
	end
	local targetRoot = G.State.RootOf(target)
	attacker[move.readyKey] = t + move.cooldown
	local velocity = knockVelocity(moveName, attackerRoot, targetRoot, move)
	PullPushSystem.Hit(attacker, target, moveName, velocity, move.time)
	G.Quests.OnEvent(attacker, move.quest, 1)
	G.fx(moveName, attackerRoot, targetRoot)
	G.fx("text", targetRoot.Position + Vector3.new(0, 4, 0), move.word, move.color)
	-- A carrier may lose a brainrot: a pull drops it at the puller's feet.
	if #target.carrying > 0 and rng:NextNumber() < move.loose then
		local record = target.carrying[#target.carrying]
		local dropAt = moveName == "pull" and attackerRoot.Position:Lerp(targetRoot.Position, 0.35) or targetRoot.Position + horizontal(velocity).Unit * 4
		G.Carry.Drop(record, dropAt, target)
		G.Quests.OnEvent(attacker, "knockLoose", 1)
		G.notify(attacker, "Knocked loose: " .. record.name .. "! Grab it [E]", Color3.fromRGB(255, 220, 90))
		G.notify(target, attacker.name .. " knocked your " .. record.name .. " loose!", Color3.fromRGB(255, 120, 120))
		G.fx("sound", "loose", targetRoot.Position)
	elseif not target.isBot then
		G.notify(target, attacker.name .. " " .. string.lower(move.word), move.color)
	end
	G.State.Changed(attacker)
end

function PullPushSystem.Init(context)
	G = context
	G.Remotes.PullPlayer.OnServerEvent:Connect(function(player, hint)
		local state = G.State.Get(player)
		if state then
			perform(state, "pull", hint)
		end
	end)
	G.Remotes.PushPlayer.OnServerEvent:Connect(function(player, hint)
		local state = G.State.Get(player)
		if state then
			perform(state, "push", hint)
		end
	end)
end

return PullPushSystem
