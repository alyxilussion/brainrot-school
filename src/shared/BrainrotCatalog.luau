-- BrainrotCatalog: the 40 original brainrots of Brainrot School.
-- 8 rarities x 5, every name school- or forest-themed, every character built
-- from code (no downloaded models). Income is dollars per second at 1x.
-- The client reads this too, for the Report Card grid and the HUD.

local Config = require(script.Parent.Config)

local Catalog = {}

-- id, name, rarity, income per second, buy cost, body colour, accent colour,
-- body shape, and one funny line for the Report Card.
local ENTRIES = {
	-- Common
	{ id = "pensil-penguin", name = "Pensil Penguin", rarity = "Common", income = 2, cost = 25, body = Color3.fromRGB(90, 130, 200), accent = Color3.fromRGB(255, 210, 60), shape = "Ball", blurb = "Writes his homework in the snow." },
	{ id = "buku-bebek", name = "Buku Bebek", rarity = "Common", income = 3, cost = 40, body = Color3.fromRGB(255, 220, 80), accent = Color3.fromRGB(255, 140, 60), shape = "Block", blurb = "Quacks every page out loud." },
	{ id = "tas-tupai", name = "Tas Tupai", rarity = "Common", income = 4, cost = 60, body = Color3.fromRGB(200, 130, 70), accent = Color3.fromRGB(120, 200, 90), shape = "Ball", blurb = "Stores snacks in his cheeks and his bag." },
	{ id = "kapur-kura", name = "Kapur Kura", rarity = "Common", income = 6, cost = 80, body = Color3.fromRGB(140, 220, 160), accent = Color3.fromRGB(255, 255, 255), shape = "Cylinder", blurb = "Slow to class, first to nap." },
	{ id = "penghapus-kelinci", name = "Penghapus Kelinci", rarity = "Common", income = 8, cost = 100, body = Color3.fromRGB(255, 180, 210), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Erases mistakes and hops away." },
	-- Uncommon
	{ id = "rautan-rusa", name = "Rautan Rusa", rarity = "Uncommon", income = 12, cost = 180, body = Color3.fromRGB(190, 150, 90), accent = Color3.fromRGB(255, 90, 90), shape = "Block", blurb = "Sharpens pencils with his antlers." },
	{ id = "mistar-musang", name = "Mistar Musang", rarity = "Uncommon", income = 16, cost = 260, body = Color3.fromRGB(150, 110, 200), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Measures everything twice, steals once." },
	{ id = "jangka-jerapah", name = "Jangka Jerapah", rarity = "Uncommon", income = 20, cost = 340, body = Color3.fromRGB(255, 200, 90), accent = Color3.fromRGB(150, 90, 40), shape = "Cylinder", blurb = "Draws circles taller than the gym." },
	{ id = "lem-landak", name = "Lem Landak", rarity = "Uncommon", income = 24, cost = 420, body = Color3.fromRGB(120, 180, 120), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Sticks to every group project." },
	{ id = "spidol-sapi", name = "Spidol Sapi", rarity = "Uncommon", income = 28, cost = 500, body = Color3.fromRGB(255, 255, 255), accent = Color3.fromRGB(60, 60, 60), shape = "Block", blurb = "Moos in permanent marker." },
	-- Rare
	{ id = "lunchbox-lion", name = "Lunchbox Lion", rarity = "Rare", income = 35, cost = 700, body = Color3.fromRGB(255, 170, 40), accent = Color3.fromRGB(255, 90, 90), shape = "Ball", blurb = "King of the cafeteria line." },
	{ id = "globe-gajah", name = "Globe Gajah", rarity = "Rare", income = 45, cost = 950, body = Color3.fromRGB(100, 160, 220), accent = Color3.fromRGB(120, 200, 90), shape = "Ball", blurb = "Knows every country, forgets his lunch." },
	{ id = "seragam-serigala", name = "Seragam Serigala", rarity = "Rare", income = 55, cost = 1200, body = Color3.fromRGB(140, 150, 170), accent = Color3.fromRGB(40, 90, 180), shape = "Block", blurb = "Howls the school anthem at dawn." },
	{ id = "tas-tikus", name = "Tas Tikus", rarity = "Rare", income = 65, cost = 1500, body = Color3.fromRGB(200, 170, 140), accent = Color3.fromRGB(255, 210, 60), shape = "Ball", blurb = "Chews through homework, literally." },
	{ id = "meja-meerkat", name = "Meja Meerkat", rarity = "Rare", income = 80, cost = 1900, body = Color3.fromRGB(210, 170, 110), accent = Color3.fromRGB(120, 200, 90), shape = "Cylinder", blurb = "Stands guard over the front row." },
	-- Epic
	{ id = "backpack-turtle", name = "Backpack Turtle", rarity = "Epic", income = 100, cost = 2600, body = Color3.fromRGB(90, 180, 110), accent = Color3.fromRGB(255, 150, 50), shape = "Ball", blurb = "Carries the whole library on his back." },
	{ id = "penggaris-python", name = "Penggaris Python", rarity = "Epic", income = 130, cost = 3400, body = Color3.fromRGB(60, 200, 140), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Thirty centimetres of pure menace." },
	{ id = "kapur-kucing", name = "Kapur Kucing", rarity = "Epic", income = 160, cost = 4300, body = Color3.fromRGB(255, 255, 255), accent = Color3.fromRGB(255, 150, 200), shape = "Ball", blurb = "Sketches on every blackboard at midnight." },
	{ id = "buku-beruang", name = "Buku Beruang", rarity = "Epic", income = 190, cost = 5200, body = Color3.fromRGB(150, 100, 60), accent = Color3.fromRGB(255, 90, 90), shape = "Block", blurb = "Reads three books before breakfast." },
	{ id = "penghapus-panda", name = "Penghapus Panda", rarity = "Epic", income = 220, cost = 6200, body = Color3.fromRGB(240, 240, 240), accent = Color3.fromRGB(60, 60, 60), shape = "Ball", blurb = "Erases the whole exam, eats bamboo." },
	-- Legendary
	{ id = "pencil-shark", name = "Pencil Shark", rarity = "Legendary", income = 300, cost = 10000, body = Color3.fromRGB(255, 210, 60), accent = Color3.fromRGB(255, 90, 90), shape = "Wedge", blurb = "The sharpest predator in class." },
	{ id = "rautan-rakun", name = "Rautan Rakun", rarity = "Legendary", income = 380, cost = 13000, body = Color3.fromRGB(130, 140, 160), accent = Color3.fromRGB(60, 60, 60), shape = "Block", blurb = "Washes every pencil before sharpening." },
	{ id = "mistar-monyet", name = "Mistar Monyet", rarity = "Legendary", income = 450, cost = 16000, body = Color3.fromRGB(180, 130, 80), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "Swings from ruler to ruler." },
	{ id = "jangka-jaguar", name = "Jangka Jaguar", rarity = "Legendary", income = 520, cost = 20000, body = Color3.fromRGB(255, 180, 60), accent = Color3.fromRGB(60, 60, 60), shape = "Wedge", blurb = "Draws the fastest circles in the jungle." },
	{ id = "lem-llama", name = "Lem Llama", rarity = "Legendary", income = 600, cost = 24000, body = Color3.fromRGB(230, 200, 170), accent = Color3.fromRGB(255, 120, 180), shape = "Cylinder", blurb = "Glues the class together, spits at none." },
	-- Mythic
	{ id = "spidol-singa", name = "Spidol Singa", rarity = "Mythic", income = 800, cost = 40000, body = Color3.fromRGB(255, 170, 40), accent = Color3.fromRGB(90, 60, 200), shape = "Ball", blurb = "Roars in twelve colours at once." },
	{ id = "bus-buaya", name = "Bus Buaya", rarity = "Mythic", income = 1000, cost = 50000, body = Color3.fromRGB(255, 215, 0), accent = Color3.fromRGB(60, 180, 90), shape = "Block", blurb = "Drives the school bus, eats the route." },
	{ id = "kantin-kuda", name = "Kantin Kuda", rarity = "Mythic", income = 1200, cost = 62000, body = Color3.fromRGB(190, 140, 90), accent = Color3.fromRGB(255, 255, 255), shape = "Cylinder", blurb = "Gallops to lunch before the bell." },
	{ id = "pustaka-paus", name = "Pustaka Paus", rarity = "Mythic", income = 1400, cost = 75000, body = Color3.fromRGB(80, 140, 220), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Swallows whole shelves of stories." },
	{ id = "kepala-harimau", name = "Kepala Harimau", rarity = "Mythic", income = 1600, cost = 90000, body = Color3.fromRGB(255, 140, 40), accent = Color3.fromRGB(60, 60, 60), shape = "Wedge", blurb = "Principal of the forest, stripes and all." },
	-- Divine
	{ id = "rapor-rajawali", name = "Rapor Rajawali", rarity = "Divine", income = 2500, cost = 150000, body = Color3.fromRGB(200, 170, 120), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Delivers straight-A report cards from the sky." },
	{ id = "ujian-unicorn", name = "Ujian Unicorn", rarity = "Divine", income = 3200, cost = 200000, body = Color3.fromRGB(255, 200, 230), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "Every exam is magically already passed." },
	{ id = "wisuda-walrus", name = "Wisuda Walrus", rarity = "Divine", income = 4000, cost = 260000, body = Color3.fromRGB(160, 130, 110), accent = Color3.fromRGB(40, 90, 180), shape = "Cylinder", blurb = "Graduated with honours in naps." },
	{ id = "beasiswa-badak", name = "Beasiswa Badak", rarity = "Divine", income = 5000, cost = 330000, body = Color3.fromRGB(150, 160, 180), accent = Color3.fromRGB(120, 230, 210), shape = "Block", blurb = "Charges through tuition fees." },
	{ id = "guru-gajah-emas", name = "Guru Gajah Emas", rarity = "Divine", income = 6000, cost = 400000, body = Color3.fromRGB(255, 215, 0), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "The golden teacher never forgets a name." },
	-- Secret
	{ id = "hantu-perpustakaan", name = "Hantu Perpustakaan", rarity = "Secret", income = 10000, cost = 750000, body = Color3.fromRGB(220, 230, 255), accent = Color3.fromRGB(150, 120, 255), shape = "Ball", blurb = "Shushes the whole school at midnight." },
	{ id = "lonceng-legendaris", name = "Lonceng Legendaris", rarity = "Secret", income = 15000, cost = 1100000, body = Color3.fromRGB(255, 215, 0), accent = Color3.fromRGB(255, 90, 90), shape = "Cylinder", blurb = "Its ring ends every lesson at once." },
	{ id = "pohon-phoenix", name = "Pohon Phoenix", rarity = "Secret", income = 20000, cost = 1500000, body = Color3.fromRGB(255, 120, 40), accent = Color3.fromRGB(120, 200, 90), shape = "Wedge", blurb = "Burns down and regrows before recess." },
	{ id = "kepala-akademi-naga", name = "Kepala Akademi Naga", rarity = "Secret", income = 25000, cost = 2000000, body = Color3.fromRGB(60, 200, 140), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Runs the academy, breathes homework fire." },
	{ id = "roh-akademi", name = "Roh Akademi", rarity = "Secret", income = 30000, cost = 3000000, body = Color3.fromRGB(180, 220, 255), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "The spirit of the school itself. Good luck." },
}

Catalog.Entries = ENTRIES
Catalog.Count = #ENTRIES

local byId = {}
local byRarity = {}
for _, entry in ipairs(ENTRIES) do
	byId[entry.id] = entry
	byRarity[entry.rarity] = byRarity[entry.rarity] or {}
	table.insert(byRarity[entry.rarity], entry)
end

Catalog.ById = byId
Catalog.ByRarity = byRarity

-- Picks a random brainrot of one rarity, using the caller's Random.
function Catalog.GetRandomOfRarity(rarity, rng)
	local pool = byRarity[rarity]
	if not pool or #pool == 0 then
		return ENTRIES[1]
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Weighted rarity roll. Luck levels shift weight from Common toward the rare end.
function Catalog.RollRarity(rng, luckLevels)
	local weights = {}
	local total = 0
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		local weight = Config.RARITY_WEIGHTS[rarity]
		if rarity == "Common" then
			weight = weight * math.max(0.2, 1 - 0.25 * luckLevels)
		elseif rarity ~= "Secret" then
			weight = weight * (1 + 0.3 * luckLevels)
		end
		weights[rarity] = weight
		total += weight
	end
	local roll = rng:NextNumber(0, total)
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		roll -= weights[rarity]
		if roll <= 0 then
			return rarity
		end
	end
	return "Common"
end

-- Mutation roll, rarest first. Returns nil for a plain brainrot.
function Catalog.RollMutation(rng, luckLevels)
	for _, roll in ipairs(Config.MUTATION_ROLLS) do
		local chance = roll.chance * (1 + 0.5 * luckLevels)
		if rng:NextNumber() < chance then
			return roll.name
		end
	end
	return nil
end

-- The income a brainrot actually pays, after its mutation multiplier.
function Catalog.MutatedIncome(entry, mutation)
	local mult = 1
	if mutation and Config.MUTATIONS[mutation] then
		mult = Config.MUTATIONS[mutation].multiplier
	end
	return entry.income * mult
end

return Catalog
