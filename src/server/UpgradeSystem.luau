-- UpgradeSystem: five permanent upgrades bought with cash.
-- Speed Shoes make you faster, the Big Bag lets you carry two brainrots, the
-- Long Lock doubles your lock time, Extra Slot adds pedestal rows to your
-- classroom, and the Lucky Charm tilts parade spawns toward rare brainrots.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local UpgradeCatalog = require(Shared.UpgradeCatalog)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local WorldBuilder = require(script.Parent.WorldBuilder)

local UpgradeSystem = {}

function UpgradeSystem.GetWalkSpeed(state)
	return 16 + 4 * state.upgrades.speed
end

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

local function applySpeed(player, state)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = UpgradeSystem.GetWalkSpeed(state)
	end
end

function UpgradeSystem.TryBuyUpgrade(player, upgradeId)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local definition = UpgradeCatalog.UPGRADES[upgradeId]
	if not definition then
		return
	end
	local level = state.upgrades[upgradeId] or 0
	local cost = UpgradeCatalog.NextCost(upgradeId, level)
	if not cost then
		notify(player, definition.name .. " is already maxed out!", "warn")
		return
	end
	if not PlayerState.TrySpend(state, cost) then
		notify(player, "Not enough cash for " .. definition.name .. " ($" .. cost .. ").", "warn")
		return
	end
	state.upgrades[upgradeId] = level + 1
	if upgradeId == "speed" then
		applySpeed(player, state)
	elseif upgradeId == "slot" then
		local base = WorldBuilder.GetBase(state.baseIndex)
		if base then
			WorldBuilder.AddPedestalRow(base)
		end
	end
	PlayerState.PushUpdate(state)
	notify(player, definition.name .. " upgraded to level " .. (level + 1) .. "!", "good")
end

return UpgradeSystem
