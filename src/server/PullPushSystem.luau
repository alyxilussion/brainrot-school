-- PullPushSystem: player-versus-player grabbing, the game's differentiator.
-- PULL [Q] yanks a nearby carrier toward you and slows them for a few seconds.
-- PUSH [F] shoves a carrier at close range: their brainrot may DROP, and
-- anyone nearby can grab it. A Shield blocks both; your own base is a safe
-- zone where neither can touch you.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local CarrySystem = require(script.Parent.CarrySystem)
local QuestSystem = require(script.Parent.QuestSystem)
local UpgradeSystem = require(script.Parent.UpgradeSystem)
local WorldBuilder = require(script.Parent.WorldBuilder)

local PullPushSystem = {}

local rng = Random.new(os.time() + 7)

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function humanoidOf(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

-- The nearest other player in range who is carrying at least one brainrot.
local function findCarrierTarget(player, range)
	local myRoot = rootOf(player)
	if not myRoot then
		return nil
	end
	local best = nil
	local bestDistance = range
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherState = PlayerState.Get(other)
			if otherState and #otherState.carried > 0 then
				local otherRoot = rootOf(other)
				if otherRoot then
					local distance = (otherRoot.Position - myRoot.Position).Magnitude
					if distance <= bestDistance then
						best = other
						bestDistance = distance
					end
				end
			end
		end
	end
	return best
end

-- A player standing inside their own classroom cannot be pulled or pushed.
local function isInOwnBase(player)
	local state = PlayerState.Get(player)
	local root = rootOf(player)
	if not state or not root then
		return false
	end
	return WorldBuilder.BaseAtPosition(root.Position) == state.baseIndex
end

function PullPushSystem.TryPull(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local now = os.clock()
	if now - state.lastPullAt < Config.PULL_COOLDOWN then
		notify(player, "Pull is recharging (" .. math.ceil(Config.PULL_COOLDOWN - (now - state.lastPullAt)) .. "s).", "warn")
		return
	end
	state.lastPullAt = now
	local target = findCarrierTarget(player, Config.PULL_RANGE)
	if not target then
		notify(player, "No carrier in pull range.", "warn")
		return
	end
	if isInOwnBase(target) then
		notify(player, target.Name .. " is safe inside their classroom.", "warn")
		return
	end
	local targetState = PlayerState.Get(target)
	if PlayerState.IsShielded(targetState) then
		notify(player, target.Name .. " is shielded!", "warn")
		return
	end
	-- Yank the carrier toward the puller and slow their run.
	local myRoot = rootOf(player)
	local targetRoot = rootOf(target)
	local direction = (myRoot.Position - targetRoot.Position)
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude > 0.1 then
		local tug = targetRoot.Position + direction.Unit * 6
		targetRoot.CFrame = CFrame.new(tug.X, targetRoot.Position.Y, tug.Z)
	end
	targetState.slowUntil = now + Config.PULL_SLOW_TIME
	local humanoid = humanoidOf(target)
	if humanoid then
		humanoid.WalkSpeed = Config.PULL_SLOW_SPEED
		task.delay(Config.PULL_SLOW_TIME, function()
			if target.Parent and os.clock() >= targetState.slowUntil then
				local fresh = humanoidOf(target)
				if fresh then
					fresh.WalkSpeed = UpgradeSystem.GetWalkSpeed(targetState)
				end
			end
		end)
	end
	notify(player, "You pulled " .. target.Name .. "!", "good")
	notify(target, player.Name .. " pulled you!", "alert")
	QuestSystem.OnEvent(player, "pulled", {})
	PlayerState.PushUpdate(state)
end

function PullPushSystem.TryPush(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local now = os.clock()
	if now - state.lastPushAt < Config.PUSH_COOLDOWN then
		notify(player, "Push is recharging (" .. math.ceil(Config.PUSH_COOLDOWN - (now - state.lastPushAt)) .. "s).", "warn")
		return
	end
	state.lastPushAt = now
	local target = findCarrierTarget(player, Config.PUSH_RANGE)
	if not target then
		notify(player, "No carrier in push range.", "warn")
		return
	end
	if isInOwnBase(target) then
		notify(player, target.Name .. " is safe inside their classroom.", "warn")
		return
	end
	local targetState = PlayerState.Get(target)
	if PlayerState.IsShielded(targetState) then
		notify(player, target.Name .. " is shielded!", "warn")
		return
	end
	-- Shove the carrier away from the pusher.
	local myRoot = rootOf(player)
	local targetRoot = rootOf(target)
	local direction = (targetRoot.Position - myRoot.Position)
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(0, 0, 1)
	end
	direction = direction.Unit
	targetRoot.AssemblyLinearVelocity = direction * Config.PUSH_FLING_SPEED + Vector3.new(0, 25, 0)
	-- The shove may knock their brainrot loose for anyone to grab.
	if #targetState.carried > 0 and rng:NextNumber() < Config.PUSH_DROP_CHANCE then
		local droppedRecord = targetState.carried[1]
		CarrySystem.DropCarried(target, droppedRecord, targetRoot.Position + direction * 4)
		notify(player, "DROPPED! " .. target.Name .. " lost " .. droppedRecord.name .. "!", "good")
		notify(target, "DROPPED! Your " .. droppedRecord.name .. " fell!", "alert")
	else
		notify(player, "You pushed " .. target.Name .. "!", "good")
		notify(target, player.Name .. " pushed you!", "alert")
	end
	QuestSystem.OnEvent(player, "pushed", {})
	PlayerState.PushUpdate(state)
end

return PullPushSystem
