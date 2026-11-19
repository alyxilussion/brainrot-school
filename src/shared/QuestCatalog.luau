-- QuestCatalog: the quest text and rewards, shared so the server can score
-- progress and the client can render the QUEST panel from the same data.
-- Chapters run in order; each step pays cash when its counter reaches its target.

local QuestCatalog = {}

-- key: the event counter this step watches. target: how many. reward: cash.
QuestCatalog.CHAPTERS = {
	{
		title = "Murid Baru",
		steps = {
			{ key = "bought", target = 1, text = "Buy your first brainrot", reward = 150 },
			{ key = "placed", target = 1, text = "Place a brainrot in your classroom", reward = 200 },
			{ key = "locked", target = 1, text = "Lock your base once", reward = 250 },
		},
	},
	{
		title = "Naik Kelas",
		steps = {
			{ key = "stole", target = 1, text = "Steal a brainrot from a rival", reward = 800 },
			{ key = "grappled", target = 1, text = "Pull or push a carrier", reward = 600 },
			{ key = "placed", target = 5, text = "Place 5 brainrots in total", reward = 1000 },
		},
	},
	{
		title = "Bintang Sekolah",
		steps = {
			{ key = "rebirthed", target = 1, text = "Rebirth once", reward = 3000 },
			{ key = "ownedCount", target = 30, text = "Own 30 different brainrots", reward = 5000 },
			{ key = "stole", target = 3, text = "Steal 3 brainrots in total", reward = 4000 },
		},
	},
}

-- Daily quests rotate by day of year: three a day, drawn from this pool.
QuestCatalog.DAILY_POOL = {
	{ key = "dailyBuy", target = 3, text = "Buy 3 brainrots", reward = 500 },
	{ key = "dailySteal", target = 1, text = "Steal 1 brainrot", reward = 1000 },
	{ key = "dailyEarn", target = 5000, text = "Earn $5,000", reward = 600 },
	{ key = "dailyPlace", target = 3, text = "Place 3 brainrots", reward = 600 },
	{ key = "dailyGrapple", target = 3, text = "Pull or push 3 times", reward = 700 },
	{ key = "dailyRare", target = 1, text = "Buy a Rare brainrot or better", reward = 1200 },
}

-- The three daily quests for a given day of year. Deterministic, so the
-- server and the client always agree without an extra remote call.
function QuestCatalog.GetDailyQuests(dayOfYear)
	local picked = {}
	for i = 1, 3 do
		local index = (dayOfYear + i * 2 - 1) % #QuestCatalog.DAILY_POOL + 1
		table.insert(picked, QuestCatalog.DAILY_POOL[index])
	end
	return picked
end

-- Tier ranks, for the "Rare or better" daily quest.
QuestCatalog.RARITY_RANK = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Divine = 7,
	Secret = 8,
	Celestial = 9,
	Galactic = 10,
	Eternal = 11,
	Godly = 12,
	Supreme = 13,
	Ultimate = 14,
	PRINCIPAL = 15,
}

return QuestCatalog
