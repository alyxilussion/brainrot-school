-- IncomeTicker: the heartbeat of the game's economy. Once a second, every
-- player's placed brainrots pay out at their mutated rate, times the rebirth
-- multiplier and the Report Card bonus, and every HUD gets a fresh snapshot.
-- The same tick notices when a base lock has expired and drops its shield.

local Players = game:GetService("Players")

local PlayerState = require(script.Parent.PlayerState)
local QuestSystem = require(script.Parent.QuestSystem)
local StealSystem = require(script.Parent.StealSystem)
local WorldBuilder = require(script.Parent.WorldBuilder)

local IncomeTicker = {}

-- Tracks which bases currently show their lock shield, so the tick can drop
-- the shield the moment the lock runs out.
local shieldShown = {}

function IncomeTicker.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = PlayerState.Get(player)
				if state then
					local income = PlayerState.ComputeIncome(state)
					if income > 0 then
						PlayerState.AddCash(state, income)
						QuestSystem.OnEvent(player, "earned", { amount = income })
					end
					-- Lock expiry: drop the shield and re-enable the steal prompts.
					local locked = PlayerState.IsLocked(state)
					if shieldShown[player] and not locked then
						shieldShown[player] = false
						local base = WorldBuilder.GetBase(state.baseIndex)
						if base then
							WorldBuilder.SetBaseLockVisual(base, false)
						end
						StealSystem.SetPromptsForBase(state.baseIndex, false)
					elseif locked then
						shieldShown[player] = true
					end
					PlayerState.PushUpdate(state)
				end
			end
		end
	end)
end

return IncomeTicker
