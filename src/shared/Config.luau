-- Config: every tuning number for Brainrot School: Enchanted Academy.
-- Server and client both read it; only the server acts on it. Remote names
-- live here too, so the two sides can never disagree on a name.

local Config = {}

Config.GAME_TITLE = "BRAINROT SCHOOL"
Config.GAME_SUBTITLE = "ENCHANTED ACADEMY"

-- The walkable ground: the top face of the grass slab WorldBuilder lays down.
Config.GROUND_Y = 0

-- Every RemoteEvent the game uses. RemoteHub builds exactly these.
Config.REMOTES = {
	requests = { "PullPlayer", "PushPlayer", "ToggleLock", "DoRebirth", "BuyUpgrade", "RollGacha", "FuseBrainrots" },
	broadcasts = { "StateUpdate", "Notify", "EventBanner", "Fx", "Knockback", "OpenPanel" },
}

Config.START_CASH = 100

-- The 16-tier ladder, weakest first. Income and cost live in BrainrotCatalog.
-- Tier 8 used to be called Secret; it is Hidden now, and Secret is the new
-- top tier (tier 16) with twenty entries.
Config.RARITY_ORDER = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Hidden",
	"Celestial", "Galactic", "Eternal", "Godly", "Supreme", "Ultimate", "PRINCIPAL", "Secret",
}

Config.RARITY_RANK = {}
for rank, rarity in ipairs(Config.RARITY_ORDER) do
	Config.RARITY_RANK[rarity] = rank
end

-- One readable colour per tier: labels, pedestal rings and the Report Card.
Config.RARITY_COLORS = {
	Common = Color3.fromRGB(150, 220, 110),
	Uncommon = Color3.fromRGB(90, 185, 255),
	Rare = Color3.fromRGB(170, 110, 255),
	Epic = Color3.fromRGB(255, 100, 200),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 80, 70),
	Divine = Color3.fromRGB(70, 240, 220),
	Hidden = Color3.fromRGB(230, 230, 245),
	Celestial = Color3.fromRGB(160, 230, 255),
	Galactic = Color3.fromRGB(150, 110, 255),
	Eternal = Color3.fromRGB(60, 225, 150),
	Godly = Color3.fromRGB(255, 235, 110),
	Supreme = Color3.fromRGB(255, 80, 160),
	Ultimate = Color3.fromRGB(255, 135, 60),
	PRINCIPAL = Color3.fromRGB(255, 255, 255),
	Secret = Color3.fromRGB(255, 85, 255),
}

-- Parade spawn weights. The Lucky Charm tilts these toward the rare end.
Config.RARITY_WEIGHTS = {
	Common = 45, Uncommon = 25, Rare = 13, Epic = 7, Legendary = 4, Mythic = 2.2,
	Divine = 1.3, Hidden = 0.8, Celestial = 0.55, Galactic = 0.35, Eternal = 0.22,
	Godly = 0.14, Supreme = 0.09, Ultimate = 0.05, PRINCIPAL = 0.02, Secret = 0.005,
}

-- Gacha weights: kinder than the parade, so a $1,000 roll feels worth it.
Config.GACHA_WEIGHTS = {
	Common = 30, Uncommon = 24, Rare = 16, Epic = 10, Legendary = 7, Mythic = 4.5,
	Divine = 3, Hidden = 2, Celestial = 1.4, Galactic = 0.9, Eternal = 0.6,
	Godly = 0.35, Supreme = 0.15, Ultimate = 0.08, PRINCIPAL = 0.02, Secret = 0.01,
}

-- High pads and the Arena Drop: only Mythic and better appear there.
Config.HIGH_PAD_WEIGHTS = {
	Mythic = 34, Divine = 22, Hidden = 15, Celestial = 11, Galactic = 8,
	Eternal = 5, Godly = 3, Supreme = 1.5, Ultimate = 0.5,
}

-- Mutations multiply a brainrot's income. Rolled rarest first.
Config.MUTATIONS = {
	GOLD = { multiplier = 2, color = Color3.fromRGB(255, 215, 0) },
	DIAMOND = { multiplier = 3, color = Color3.fromRGB(170, 235, 255) },
	LAVA = { multiplier = 4, color = Color3.fromRGB(255, 90, 30) },
	RAINBOW = { multiplier = 6, color = Color3.fromRGB(255, 120, 220) },
	GLITCH = { multiplier = 10, color = Color3.fromRGB(140, 60, 255) },
}
Config.MUTATION_ROLLS = {
	{ name = "GLITCH", chance = 0.005 },
	{ name = "RAINBOW", chance = 0.01 },
	{ name = "LAVA", chance = 0.02 },
	{ name = "DIAMOND", chance = 0.04 },
	{ name = "GOLD", chance = 0.08 },
}

-- Parade Lane: a brainrot walks in this often and takes this long to cross.
Config.PARADE_SPAWN_INTERVAL = 4
Config.PARADE_WALK_TIME = 48

-- High pads (climbing wall, big tree, tower): a free Mythic-or-better.
Config.HIGH_PAD_INTERVAL = 45
-- Arena Drop: a rare brainrot lands on the arena crest, first grab wins.
Config.ARENA_DROP_INTERVAL = 75
Config.ARENA_DROP_WARNING = 10

Config.GACHA_COST = 1000
Config.SELL_REFUND = 0.5 -- selling your own brainrot returns half its price

-- Sitting on a bench or swing: the Fresh buff, then a cooldown.
Config.SIT_BUFF_MULTIPLIER = 1.1
Config.SIT_BUFF_DURATION = 60
Config.SIT_COOLDOWN = 120

-- Lunch Rush: countdown, then a stampede sweeps the school north to south.
Config.HAZARD_INTERVAL = 100
Config.HAZARD_COUNTDOWN = 15
Config.HAZARD_SWEEP_TIME = 9

-- The Naughty Crow, the crow thief, raids an unlocked base this often.
Config.CROW_INTERVAL = 130

-- Rival classmates: NPC students who own bases and send thieves.
Config.RIVAL_THIEF_INTERVAL = 45
Config.RIVAL_WALK_SPEED = 11
Config.RIVAL_STAGGER_TIME = 2.5

-- Base lock: shields the base this long, then recharges.
Config.LOCK_DURATION = 60
Config.LOCK_DURATION_UPGRADED = 120
Config.LOCK_RECHARGE = 30

-- Steal prompt (Press E): hold time and reach.
Config.STEAL_HOLD = 0.35
Config.STEAL_RANGE = 11

-- PULL (Q, Tarik) and PUSH (F, Dorong).
Config.PULL_RANGE = 28
Config.PULL_COOLDOWN = 6
Config.PULL_SPEED = 48 -- studs per second toward the puller
Config.PULL_TIME = 0.28
Config.PULL_LOOSE_CHANCE = 0.5 -- a pulled carrier may lose their brainrot
Config.PUSH_RANGE = 14
Config.PUSH_COOLDOWN = 5
Config.PUSH_SPEED = 62
Config.PUSH_TIME = 0.24
Config.PUSH_LOOSE_CHANCE = 0.8
Config.KNOCK_LIFT = 12 -- small hop, never a launch
Config.STAGGER_TIME = 1.2
Config.STAGGER_SPEED = 7
Config.HIT_IMMUNITY = 2.5 -- no stun-lock: a hit target is immune this long

-- A dropped brainrot lies on the field this long before it wanders off.
Config.DROPPED_LIFETIME = 45
Config.CARRY_CAPACITY_BASE = 1
Config.REBIRTH_BASE_COST = 25000
Config.REPORT_CARD_BONUS_PER_ENTRY = 0.02
Config.QUEST_CHAPTER_BONUS = 0.05

Config.BASE_COUNT = 8
Config.PEDESTALS_PER_ROW = 4
Config.MAX_PEDESTAL_ROWS = 4
Config.START_PEDESTAL_ROWS = 2

-- Upgrades bought with cash.
Config.UPGRADES = {
	speed = { name = "Speed Shoes", desc = "+4 walk speed per level", costs = { 500, 1500, 4000 } },
	bag = { name = "Big Bag", desc = "Carry 2 brainrots at once", costs = { 2000 } },
	lock = { name = "Long Lock", desc = "Base lock lasts 120s", costs = { 1500 } },
	slot = { name = "Extra Slot", desc = "+4 pedestals in your classroom", costs = { 3000, 8000 } },
	luck = { name = "Lucky Charm", desc = "Rarer parade + gacha rolls", costs = { 5000, 15000 } },
}
Config.UPGRADE_ORDER = { "speed", "bag", "lock", "slot", "luck" }

function Config.NextUpgradeCost(upgradeId, level)
	local upgrade = Config.UPGRADES[upgradeId]
	return upgrade and upgrade.costs[level + 1] or nil
end

-- "$1.2K", "$3.4M": short money for labels read at thumbnail size.
function Config.FormatMoney(amount)
	amount = math.floor(tonumber(amount) or 0)
	local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, pair in ipairs(suffixes) do
		if math.abs(amount) >= pair[1] then
			local value = amount / pair[1]
			local text = value >= 100 and string.format("%d", math.floor(value)) or string.format("%.1f", value)
			return "$" .. text .. pair[2]
		end
	end
	return "$" .. tostring(amount)
end

return Config
