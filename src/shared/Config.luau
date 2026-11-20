-- Config: every tuning number for Brainrot School in one place.
-- Both server and client read this; the server is the only one that acts on it.

local Config = {}

-- The walkable ground is the top of the grass slab WorldBuilder lays down.
Config.GROUND_Y = 0.4

-- Starting money for a new student.
Config.START_CASH = 100

-- The 16-tier ladder, weakest first. Income and cost live in BrainrotCatalog.
-- Tier 8 used to be called Secret; it is Hidden now, and Secret is the new
-- top tier, home to the twenty rarest brainrots in the school.
Config.RARITY_ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Divine",
	"Hidden",
	"Celestial",
	"Galactic",
	"Eternal",
	"Godly",
	"Supreme",
	"Ultimate",
	"PRINCIPAL",
	"Secret",
}

-- One readable colour per tier, used for labels, pedestal rings and the Report Card.
Config.RARITY_COLORS = {
	Common = Color3.fromRGB(120, 200, 90),
	Uncommon = Color3.fromRGB(80, 170, 235),
	Rare = Color3.fromRGB(150, 90, 230),
	Epic = Color3.fromRGB(235, 90, 180),
	Legendary = Color3.fromRGB(245, 180, 30),
	Mythic = Color3.fromRGB(235, 70, 60),
	Divine = Color3.fromRGB(60, 230, 210),
	Hidden = Color3.fromRGB(200, 200, 220),
	Celestial = Color3.fromRGB(150, 225, 255),
	Galactic = Color3.fromRGB(130, 90, 255),
	Eternal = Color3.fromRGB(50, 210, 140),
	Godly = Color3.fromRGB(255, 225, 100),
	Supreme = Color3.fromRGB(255, 70, 150),
	Ultimate = Color3.fromRGB(255, 120, 50),
	PRINCIPAL = Color3.fromRGB(255, 255, 255),
	Secret = Color3.fromRGB(255, 85, 255),
}

-- Parade spawn weights. Luck upgrades tilt these toward the rare end.
Config.RARITY_WEIGHTS = {
	Common = 45,
	Uncommon = 25,
	Rare = 13,
	Epic = 7,
	Legendary = 4,
	Mythic = 2.2,
	Divine = 1.3,
	Hidden = 0.8,
	Celestial = 0.55,
	Galactic = 0.35,
	Eternal = 0.22,
	Godly = 0.14,
	Supreme = 0.09,
	Ultimate = 0.05,
	PRINCIPAL = 0.02,
	Secret = 0.005,
}

-- Gacha weights: a little kinder than the parade, so a roll feels worth $1,000.
Config.GACHA_WEIGHTS = {
	Common = 30,
	Uncommon = 24,
	Rare = 16,
	Epic = 10,
	Legendary = 7,
	Mythic = 4.5,
	Divine = 3,
	Hidden = 2,
	Celestial = 1.4,
	Galactic = 0.9,
	Eternal = 0.6,
	Godly = 0.35,
	Supreme = 0.15,
	Ultimate = 0.08,
	PRINCIPAL = 0.02,
	Secret = 0.01,
}

-- High-pad weights: only Mythic and better ever appear on the high places.
Config.HIGH_PAD_WEIGHTS = {
	Mythic = 34,
	Divine = 22,
	Hidden = 15,
	Celestial = 11,
	Galactic = 8,
	Eternal = 5,
	Godly = 3,
	Supreme = 1.5,
	Ultimate = 0.5,
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

-- The Gacha Machine: one flat price per roll, whatever tier comes out.
Config.GACHA_COST = 1000

-- Sitting on a bench or swing: a Fresh buff, then a long cooldown.
Config.SIT_BUFF_MULTIPLIER = 1.1
Config.SIT_BUFF_DURATION = 60
Config.SIT_COOLDOWN = 180

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
