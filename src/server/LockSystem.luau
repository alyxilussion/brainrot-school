-- LockSystem: the base lock. Press LOCK and a blue shield covers your
-- classroom for a minute: steal prompts read LOCKED and refuse to fire, and
-- Gagak Nakal skips you. Then the lock must recharge before you can raise it
-- again, so timing it around the crow and the Lunch Rush matters.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local StealSystem = require(script.Parent.StealSystem)
local WorldBuilder = require(script.Parent.WorldBuilder)
local QuestSystem = require(script.Parent.QuestSystem)

local LockSystem = {}

function LockSystem.TryToggleLock(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local event = RemoteHub.Get("Notify")
	local now = os.clock()
	if PlayerState.IsLocked(state) then
		if event then
			event:FireClient(player, "Your base is already locked (" .. math.ceil(state.lockUntil - now) .. "s left).", "warn")
		end
		return
	end
	if now < state.lockReadyAt then
		if event then
			event:FireClient(player, "Lock is recharging (" .. math.ceil(state.lockReadyAt - now) .. "s).", "warn")
		end
		return
	end
	local duration = PlayerState.GetLockDuration(state)
	state.lockUntil = now + duration
	state.lockReadyAt = state.lockUntil + Config.LOCK_RECHARGE
	local base = WorldBuilder.GetBase(state.baseIndex)
	if base then
		WorldBuilder.SetBaseLockVisual(base, true)
	end
	StealSystem.SetPromptsForBase(state.baseIndex, true)
	PlayerState.PushUpdate(state)
	if event then
		event:FireClient(player, "Base LOCKED for " .. duration .. "s — nobody can steal from you!", "good")
	end
	QuestSystem.OnEvent(player, "locked", {})
end

return LockSystem
