-- UpgradeCatalog: the five upgrades, shared so the server can charge for them
-- and the client can render the upgrade panel from the same data.

local UpgradeCatalog = {}

UpgradeCatalog.UPGRADES = {
	speed = {
		name = "Speed Shoes",
		desc = "+4 walk speed per level",
		costs = { 500, 1500, 4000 },
	},
	bag = {
		name = "Big Bag",
		desc = "Carry 2 brainrots at once",
		costs = { 2000 },
	},
	lock = {
		name = "Long Lock",
		desc = "Base lock lasts 120s",
		costs = { 1500 },
	},
	slot = {
		name = "Extra Slot",
		desc = "+4 pedestals in your classroom",
		costs = { 3000, 8000 },
	},
	luck = {
		name = "Lucky Charm",
		desc = "Rarer brainrots on the parade",
		costs = { 5000, 15000 },
	},
}

UpgradeCatalog.ORDER = { "speed", "bag", "lock", "slot", "luck" }

function UpgradeCatalog.MaxLevel(upgradeId)
	local upgrade = UpgradeCatalog.UPGRADES[upgradeId]
	return upgrade and #upgrade.costs or 0
end

-- Cost of the next level, or nil when the upgrade is maxed out.
function UpgradeCatalog.NextCost(upgradeId, currentLevel)
	local upgrade = UpgradeCatalog.UPGRADES[upgradeId]
	if not upgrade then
		return nil
	end
	return upgrade.costs[currentLevel + 1]
end

return UpgradeCatalog
