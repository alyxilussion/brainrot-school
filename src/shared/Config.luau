-- Config: every tuning number for Brainrot School in one place.
-- Both server and client read this; the server is the only one that acts on it.

local Config = {}

-- The walkable ground is the top of the grass slab WorldBuilder lays down.
Config.GROUND_Y = 0.4

-- Starting money for a new student.
Config.START_CASH = 100

-- Rarity ladder, weakest first. Income and cost live in BrainrotCatalog.
Config.RARITY_ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Divine",
	"Secret",
}

-- One readable colour per rarity, used for labels, pedestal rings and the Report Card.
Config.RARITY_COLORS = {
	Common = Color3.fromRGB(120, 200, 90),
	Uncommon = Color3.fromRGB(80, 170, 235),
	Rare = Color3.fromRGB(150, 90, 230),
	Epic = Color3.fromRGB(235, 90, 180),
	Legendary = Color3.fromRGB(245, 180, 30),
	Mythic = Color3.fromRGB(235, 70, 60),
	Divine = Color3.fromRGB(60, 230, 210),
	Secret = Color3.fromRGB(255, 255, 255),
}

-- Parade spawn weights. Luck upgrades tilt these toward the rare end.
Config.RARITY_WEIGHTS = {
	Common = 50,
	Uncommon = 28,
	Rare = 12,
	Epic = 6,
	Legendary = 2.5,
	Mythic = 1,
	Divine = 0.35,
	Secret = 0.15,
}

-- Mutations: a brainrot that spawns mutated earns its income times this.
-- Rolls are checked rarest first, so a single roll can only win one mutation.
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

-- Parade Lane: a new brainrot walks in this often, and takes this long to cross.
Config.PARADE_SPAWN_INTERVAL = 4
Config.PARADE_WALK_TIME = 45

-- High pads (gym wall top, big tree top, academy tower): a Mythic-or-better
-- brainrot appears here this often when the pad is empty. Free to grab.
Config.HIGH_PAD_INTERVAL = 45
Config.HIGH_PAD_RARITIES = { "Mythic", "Divine", "Secret" }

-- Lunch Rush hazard: every interval, a countdown, then the stampede sweeps the field.
Config.HAZARD_INTERVAL = 90
Config.HAZARD_COUNTDOWN = 15
Config.HAZARD_SWEEP_TIME = 6

-- Gagak Nakal, the crow thief, visits an unlocked base this often.
Config.CROW_INTERVAL = 120

-- Base lock: shields the base this long, then must recharge before the next lock.
Config.LOCK_DURATION = 60
Config.LOCK_RECHARGE = 30
Config.LOCK_DURATION_UPGRADED = 120

-- PvP: pull reaches far and slows, push is close and can knock a brainrot loose.
Config.PULL_RANGE = 30
Config.PULL_COOLDOWN = 8
Config.PULL_SLOW_TIME = 3
Config.PULL_SLOW_SPEED = 8
Config.PUSH_RANGE = 12
Config.PUSH_COOLDOWN = 6
Config.PUSH_DROP_CHANCE = 0.6
Config.PUSH_FLING_SPEED = 55

-- A dropped brainrot lies on the field this long before it wanders off.
Config.DROPPED_LIFETIME = 60

-- Carrying: one brainrot at a time, two with the Big Bag upgrade.
Config.CARRY_CAPACITY_BASE = 1

-- Rebirth: costs this times two to the power of rebirths owned, and adds +1x income.
Config.REBIRTH_BASE_COST = 25000

-- Report Card: every unique brainrot owned adds this much income, on top of rebirth.
Config.REPORT_CARD_BONUS_PER_ENTRY = 0.02

-- Pedestals per classroom base at the start; the Extra Slot upgrade adds four each level.
Config.BASE_PEDESTALS = 8

return Config
