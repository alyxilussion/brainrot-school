-- RebirthSystem: trade everything you have for a permanent income multiplier.
-- A rebirth clears your cash and every brainrot you placed or carry, and adds
-- +1x to all future income. The cost doubles with every rebirth, so each one
-- is a real decision: cash out now, or grow a little more first.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local CarrySystem = require(script.Parent.CarrySystem)
local StealSystem = require(script.Parent.StealSystem)
local QuestSystem = require(script.Parent.QuestSystem)

local RebirthSystem = {}

function RebirthSystem.GetCost(state)
	return Config.REBIRTH_BASE_COST * (2 ^ state.rebirths)
end

function RebirthSystem.TryRebirth(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local cost = RebirthSystem.GetCost(state)
	if not PlayerState.TrySpend(state, cost) then
		local event = RemoteHub.Get("Notify")
		if event then
			event:FireClient(player, "Rebirth costs $" .. cost .. " — you have $" .. state.cash .. ".", "warn")
		end
		return
	end
	-- Everything on the pedestals goes, prompts included.
	for pedestalId, record in pairs(table.clone(state.placed)) do
		StealSystem.RemovePrompt(record.uid)
		CarrySystem.RemovePlaced(player, pedestalId, true)
	end
	-- Everything in hand goes too.
	for _, record in ipairs(table.clone(state.carried)) do
		if record.model then
			record.model:Destroy()
		end
	end
	state.carried = {}
	state.cash = 0
	state.rebirths += 1
	state.multiplier += 1
	PlayerState.PushUpdate(state)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, "REBIRTH! Income is now x" .. state.multiplier .. " forever!", "quest")
	end
	QuestSystem.OnEvent(player, "rebirthed", {})
end

return RebirthSystem
