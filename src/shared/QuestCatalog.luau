-- QuestCatalog: the quest chapters and the rotating Bonus Board.
-- Each quest watches one event counter (see QuestSystem.OnEvent). Chapter
-- steps run in order and count from the moment the step begins; the Bonus
-- Board keeps three quests live and refills a finished slot with a harder one.

local QuestCatalog = {}

-- key: the event counter the quest watches. target: how many. reward: cash.
QuestCatalog.CHAPTERS = {
	{
		title = "Murid Baru",
		steps = {
			{ key = "buy", target = 1, text = "Buy a brainrot from the Parade", reward = 150 },
			{ key = "place", target = 1, text = "Bring it home to your classroom", reward = 200 },
			{ key = "earn", target = 300, text = "Earn $300 from your brainrots", reward = 250 },
			{ key = "lock", target = 1, text = "Lock your base once [L]", reward = 300 },
		},
	},
	{
		title = "Anak Nakal",
		steps = {
			{ key = "pull", target = 1, text = "PULL a student or thief [Q]", reward = 500 },
			{ key = "push", target = 1, text = "PUSH a student or thief [F]", reward = 500 },
			{ key = "knockLoose", target = 1, text = "Knock a carried brainrot loose", reward = 800 },
			{ key = "steal", target = 1, text = "Press [E] to STEAL from a rival", reward = 1000 },
		},
	},
	{
		title = "Juara Kelas",
		steps = {
			{ key = "rush", target = 1, text = "Survive a Lunch Rush in your base", reward = 1500 },
			{ key = "upgrade", target = 1, text = "Buy any upgrade", reward = 1500 },
			{ key = "gacha", target = 1, text = "Roll the Gacha Machine", reward = 2000 },
			{ key = "earn", target = 10000, text = "Earn $10K", reward = 3000 },
		},
	},
	{
		title = "Bintang Sekolah",
		steps = {
			{ key = "steal", target = 3, text = "Steal 3 brainrots", reward = 5000 },
			{ key = "fuse", target = 1, text = "Fuse 3 brainrots in the Fuse Lab", reward = 5000 },
			{ key = "ownedCount", target = 20, text = "Collect 20 different brainrots", reward = 8000 },
			{ key = "rebirth", target = 1, text = "Rebirth once", reward = 10000 },
		},
	},
}

-- The Bonus Board pool. A finished slot draws the next quest in the pool,
-- one tier harder each lap: target x2, reward x2.
QuestCatalog.BONUS_POOL = {
	{ key = "buy", target = 3, text = "Buy %d brainrots", reward = 400 },
	{ key = "pull", target = 2, text = "Pull %d students or thieves", reward = 500 },
	{ key = "earn", target = 2000, text = "Earn $%d", reward = 500 },
	{ key = "push", target = 2, text = "Push %d students or thieves", reward = 500 },
	{ key = "recover", target = 1, text = "Grab %d dropped brainrots", reward = 600 },
	{ key = "steal", target = 1, text = "Steal %d brainrots", reward = 900 },
	{ key = "arenaDrop", target = 1, text = "Win %d Arena Drops", reward = 1200 },
	{ key = "sit", target = 1, text = "Rest on a bench or swing %dx", reward = 300 },
	{ key = "knockLoose", target = 2, text = "Knock %d brainrots loose", reward = 900 },
}
QuestCatalog.BONUS_SLOTS = 3

-- The Bonus Board quest at a pool position. Lap 0 is the base target.
function QuestCatalog.GetBonusQuest(poolIndex)
	local count = #QuestCatalog.BONUS_POOL
	local definition = QuestCatalog.BONUS_POOL[(poolIndex - 1) % count + 1]
	local lap = math.floor((poolIndex - 1) / count)
	local scale = 2 ^ lap
	local target = math.floor(definition.target * scale)
	return {
		key = definition.key,
		target = target,
		text = string.format(definition.text, target),
		reward = math.floor(definition.reward * scale),
	}
end

return QuestCatalog
