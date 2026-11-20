-- BrainrotCatalog: the 80 brainrots of Brainrot School.
-- 15 tiers x 4 plus 20 Secret, every name a school pun in English
-- (Chalk Turtle, Compass Giraffe, Mystery Manta), every character built
-- from code (no downloaded models). Income is dollars per second at 1x and
-- $786,432/s at tier 16; the buy price is twelve times the income. The
-- client reads this too, for the Report Card grid and the HUD.

local Config = require(script.Parent.Config)

local Catalog = {}

-- id, name, rarity (tier), income per second, buy cost, body colour, accent
-- colour, body shape, and one funny line for the Report Card.
local ENTRIES = {
	-- Tier 1: Common
	{ id = "pensil-penguin", name = "Pencil Penguin", rarity = "Common", income = 5, cost = 60, body = Color3.fromRGB(90, 130, 200), accent = Color3.fromRGB(255, 210, 60), shape = "Ball", blurb = "Writes his homework in the snow." },
	{ id = "buku-bebek", name = "Book Duck", rarity = "Common", income = 6, cost = 72, body = Color3.fromRGB(255, 220, 80), accent = Color3.fromRGB(255, 140, 60), shape = "Block", blurb = "Quacks every page out loud." },
	{ id = "tas-tupai", name = "Bag Squirrel", rarity = "Common", income = 7, cost = 84, body = Color3.fromRGB(200, 130, 70), accent = Color3.fromRGB(120, 200, 90), shape = "Ball", blurb = "Stores snacks in his cheeks and his bag." },
	{ id = "kapur-kura", name = "Chalk Turtle", rarity = "Common", income = 8, cost = 96, body = Color3.fromRGB(140, 220, 160), accent = Color3.fromRGB(255, 255, 255), shape = "Cylinder", blurb = "Slow to class, first to nap." },
	-- Tier 2: Uncommon
	{ id = "penghapus-kelinci", name = "Eraser Rabbit", rarity = "Uncommon", income = 10, cost = 120, body = Color3.fromRGB(255, 180, 210), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Erases mistakes and hops away." },
	{ id = "rautan-rusa", name = "Sharpener Deer", rarity = "Uncommon", income = 12, cost = 144, body = Color3.fromRGB(190, 150, 90), accent = Color3.fromRGB(255, 90, 90), shape = "Block", blurb = "Sharpens pencils with his antlers." },
	{ id = "mistar-musang", name = "Ruler Ferret", rarity = "Uncommon", income = 14, cost = 168, body = Color3.fromRGB(150, 110, 200), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Measures everything twice, steals once." },
	{ id = "jangka-jerapah", name = "Compass Giraffe", rarity = "Uncommon", income = 16, cost = 192, body = Color3.fromRGB(255, 200, 90), accent = Color3.fromRGB(150, 90, 40), shape = "Cylinder", blurb = "Draws circles taller than the gym." },
	-- Tier 3: Rare
	{ id = "lem-landak", name = "Glue Porcupine", rarity = "Rare", income = 20, cost = 240, body = Color3.fromRGB(120, 180, 120), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Sticks to every group project." },
	{ id = "spidol-sapi", name = "Marker Cow", rarity = "Rare", income = 24, cost = 288, body = Color3.fromRGB(255, 255, 255), accent = Color3.fromRGB(60, 60, 60), shape = "Block", blurb = "Moos in permanent marker." },
	{ id = "lunchbox-lion", name = "Lunchbox Lion", rarity = "Rare", income = 28, cost = 336, body = Color3.fromRGB(255, 170, 40), accent = Color3.fromRGB(255, 90, 90), shape = "Ball", blurb = "King of the cafeteria line." },
	{ id = "globe-gajah", name = "Globe Elephant", rarity = "Rare", income = 32, cost = 384, body = Color3.fromRGB(100, 160, 220), accent = Color3.fromRGB(120, 200, 90), shape = "Ball", blurb = "Knows every country, forgets his lunch." },
	-- Tier 4: Epic
	{ id = "seragam-serigala", name = "Uniform Wolf", rarity = "Epic", income = 40, cost = 480, body = Color3.fromRGB(140, 150, 170), accent = Color3.fromRGB(40, 90, 180), shape = "Block", blurb = "Howls the school anthem at dawn." },
	{ id = "tas-tikus", name = "Bag Rat", rarity = "Epic", income = 48, cost = 576, body = Color3.fromRGB(200, 170, 140), accent = Color3.fromRGB(255, 210, 60), shape = "Ball", blurb = "Chews through homework, literally." },
	{ id = "meja-meerkat", name = "Desk Meerkat", rarity = "Epic", income = 56, cost = 672, body = Color3.fromRGB(210, 170, 110), accent = Color3.fromRGB(120, 200, 90), shape = "Cylinder", blurb = "Stands guard over the front row." },
	{ id = "backpack-turtle", name = "Backpack Turtle", rarity = "Epic", income = 64, cost = 768, body = Color3.fromRGB(90, 180, 110), accent = Color3.fromRGB(255, 150, 50), shape = "Ball", blurb = "Carries the whole library on his back." },
	-- Tier 5: Legendary
	{ id = "pencil-shark", name = "Pencil Shark", rarity = "Legendary", income = 80, cost = 960, body = Color3.fromRGB(255, 210, 60), accent = Color3.fromRGB(255, 90, 90), shape = "Wedge", blurb = "The sharpest predator in class." },
	{ id = "penggaris-python", name = "Ruler Python", rarity = "Legendary", income = 96, cost = 1152, body = Color3.fromRGB(60, 200, 140), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Thirty centimetres of pure menace." },
	{ id = "kapur-kucing", name = "Chalk Cat", rarity = "Legendary", income = 112, cost = 1344, body = Color3.fromRGB(255, 255, 255), accent = Color3.fromRGB(255, 150, 200), shape = "Ball", blurb = "Sketches on every blackboard at midnight." },
	{ id = "buku-beruang", name = "Book Bear", rarity = "Legendary", income = 128, cost = 1536, body = Color3.fromRGB(150, 100, 60), accent = Color3.fromRGB(255, 90, 90), shape = "Block", blurb = "Reads three books before breakfast." },
	-- Tier 6: Mythic
	{ id = "penghapus-panda", name = "Eraser Panda", rarity = "Mythic", income = 160, cost = 1920, body = Color3.fromRGB(240, 240, 240), accent = Color3.fromRGB(60, 60, 60), shape = "Ball", blurb = "Erases the whole exam, eats bamboo." },
	{ id = "rautan-rakun", name = "Sharpener Raccoon", rarity = "Mythic", income = 192, cost = 2304, body = Color3.fromRGB(130, 140, 160), accent = Color3.fromRGB(60, 60, 60), shape = "Block", blurb = "Washes every pencil before sharpening." },
	{ id = "mistar-monyet", name = "Ruler Monkey", rarity = "Mythic", income = 224, cost = 2688, body = Color3.fromRGB(180, 130, 80), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "Swings from ruler to ruler." },
	{ id = "jangka-jaguar", name = "Compass Jaguar", rarity = "Mythic", income = 256, cost = 3072, body = Color3.fromRGB(255, 180, 60), accent = Color3.fromRGB(60, 60, 60), shape = "Wedge", blurb = "Draws the fastest circles in the jungle." },
	-- Tier 7: Divine
	{ id = "lem-llama", name = "Glue Llama", rarity = "Divine", income = 320, cost = 3840, body = Color3.fromRGB(230, 200, 170), accent = Color3.fromRGB(255, 120, 180), shape = "Cylinder", blurb = "Glues the class together, spits at none." },
	{ id = "spidol-singa", name = "Marker Lion", rarity = "Divine", income = 384, cost = 4608, body = Color3.fromRGB(255, 170, 40), accent = Color3.fromRGB(90, 60, 200), shape = "Ball", blurb = "Roars in twelve colours at once." },
	{ id = "bus-buaya", name = "Bus Crocodile", rarity = "Divine", income = 448, cost = 5376, body = Color3.fromRGB(255, 215, 0), accent = Color3.fromRGB(60, 180, 90), shape = "Block", blurb = "Drives the school bus, eats the route." },
	{ id = "kantin-kuda", name = "Canteen Horse", rarity = "Divine", income = 512, cost = 6144, body = Color3.fromRGB(190, 140, 90), accent = Color3.fromRGB(255, 255, 255), shape = "Cylinder", blurb = "Gallops to lunch before the bell." },
	-- Tier 8: Hidden
	{ id = "pustaka-paus", name = "Library Whale", rarity = "Hidden", income = 640, cost = 7680, body = Color3.fromRGB(80, 140, 220), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Swallows whole shelves of stories." },
	{ id = "kepala-harimau", name = "Principal Tiger", rarity = "Hidden", income = 768, cost = 9216, body = Color3.fromRGB(255, 140, 40), accent = Color3.fromRGB(60, 60, 60), shape = "Wedge", blurb = "Principal of the forest, stripes and all." },
	{ id = "rapor-rajawali", name = "Report-Card Eagle", rarity = "Hidden", income = 896, cost = 10752, body = Color3.fromRGB(200, 170, 120), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Delivers straight-A report cards from the sky." },
	{ id = "ujian-unicorn", name = "Exam Unicorn", rarity = "Hidden", income = 1024, cost = 12288, body = Color3.fromRGB(255, 200, 230), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "Every exam is magically already passed." },
	-- Tier 9: Celestial
	{ id = "wisuda-walrus", name = "Graduation Walrus", rarity = "Celestial", income = 1280, cost = 15360, body = Color3.fromRGB(160, 130, 110), accent = Color3.fromRGB(40, 90, 180), shape = "Cylinder", blurb = "Graduated with honours in naps." },
	{ id = "beasiswa-badak", name = "Scholarship Rhino", rarity = "Celestial", income = 1536, cost = 18432, body = Color3.fromRGB(150, 160, 180), accent = Color3.fromRGB(120, 230, 210), shape = "Block", blurb = "Charges through tuition fees." },
	{ id = "guru-gajah-emas", name = "Golden Teacher Elephant", rarity = "Celestial", income = 1792, cost = 21504, body = Color3.fromRGB(255, 215, 0), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "The golden teacher never forgets a name." },
	{ id = "hantu-perpustakaan", name = "Library Ghost", rarity = "Celestial", income = 2048, cost = 24576, body = Color3.fromRGB(220, 230, 255), accent = Color3.fromRGB(150, 120, 255), shape = "Ball", blurb = "Shushes the whole school at midnight." },
	-- Tier 10: Galactic
	{ id = "lonceng-legendaris", name = "Legendary Bell", rarity = "Galactic", income = 2560, cost = 30720, body = Color3.fromRGB(255, 215, 0), accent = Color3.fromRGB(255, 90, 90), shape = "Cylinder", blurb = "Its ring ends every lesson at once." },
	{ id = "pohon-phoenix", name = "Tree Phoenix", rarity = "Galactic", income = 3072, cost = 36864, body = Color3.fromRGB(255, 120, 40), accent = Color3.fromRGB(120, 200, 90), shape = "Wedge", blurb = "Burns down and regrows before recess." },
	{ id = "kepala-akademi-naga", name = "Dragon Academy Principal", rarity = "Galactic", income = 3584, cost = 43008, body = Color3.fromRGB(60, 200, 140), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Runs the academy, breathes homework fire." },
	{ id = "roh-akademi", name = "Academy Spirit", rarity = "Galactic", income = 4096, cost = 49152, body = Color3.fromRGB(180, 220, 255), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "The spirit of the school itself. Good luck." },
	-- Tier 11: Eternal
	{ id = "jam-abadi-jalak", name = "Eternal Clock Starling", rarity = "Eternal", income = 5120, cost = 61440, body = Color3.fromRGB(60, 160, 170), accent = Color3.fromRGB(255, 215, 0), shape = "Cylinder", blurb = "Time stops when the bell rings twice." },
	{ id = "perpustakaan-pelikan", name = "Library Pelican", rarity = "Eternal", income = 6144, cost = 73728, body = Color3.fromRGB(210, 225, 255), accent = Color3.fromRGB(150, 110, 70), shape = "Ball", blurb = "Carries a thousand books in his beak." },
	{ id = "arsip-albatros", name = "Archive Albatross", rarity = "Eternal", income = 7168, cost = 86016, body = Color3.fromRGB(150, 170, 200), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Files every memory ever made." },
	{ id = "memori-merak", name = "Memory Peacock", rarity = "Eternal", income = 8192, cost = 98304, body = Color3.fromRGB(40, 180, 160), accent = Color3.fromRGB(180, 100, 255), shape = "Ball", blurb = "Remembers every lesson, ever." },
	-- Tier 12: Godly
	{ id = "dewa-disiplin-dingo", name = "Dingo God of Discipline", rarity = "Godly", income = 10240, cost = 122880, body = Color3.fromRGB(255, 210, 80), accent = Color3.fromRGB(255, 255, 255), shape = "Block", blurb = "The god of showing up on time." },
	{ id = "dewi-dongeng-duyung", name = "Mermaid Goddess of Tales", rarity = "Godly", income = 12288, cost = 147456, body = Color3.fromRGB(80, 220, 190), accent = Color3.fromRGB(255, 150, 200), shape = "Ball", blurb = "Every story she tells comes true." },
	{ id = "titan-tata-tertib", name = "Titan of Order", rarity = "Godly", income = 14336, cost = 172032, body = Color3.fromRGB(170, 165, 155), accent = Color3.fromRGB(230, 70, 60), shape = "Block", blurb = "He wrote the rules. All of them." },
	{ id = "raja-raport-elang", name = "Eagle King of Report Cards", rarity = "Godly", income = 16384, cost = 196608, body = Color3.fromRGB(190, 150, 90), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Delivers grades from the highest sky." },
	-- Tier 13: Supreme
	{ id = "maharaja-matematika", name = "Math Maharaja", rarity = "Supreme", income = 20480, cost = 245760, body = Color3.fromRGB(140, 80, 220), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "Counts faster than the school bell." },
	{ id = "kaisar-kimia-kancil", name = "Chemistry Emperor Mousedeer", rarity = "Supreme", income = 24576, cost = 294912, body = Color3.fromRGB(90, 200, 120), accent = Color3.fromRGB(255, 150, 50), shape = "Cylinder", blurb = "His potions always pass the test." },
	{ id = "sultan-sejarah-sanca", name = "History Sultan Python", rarity = "Supreme", income = 28672, cost = 344064, body = Color3.fromRGB(220, 190, 130), accent = Color3.fromRGB(230, 70, 60), shape = "Wedge", blurb = "Remembers when the school was a forest." },
	{ id = "ratu-robotika-rubah", name = "Robotics Queen Fox", rarity = "Supreme", income = 32768, cost = 393216, body = Color3.fromRGB(200, 205, 215), accent = Color3.fromRGB(90, 220, 255), shape = "Block", blurb = "Builds robots that do her homework." },
	-- Tier 14: Ultimate
	{ id = "ultima-ujian-ular", name = "Ultima Exam Snake", rarity = "Ultimate", income = 40960, cost = 491520, body = Color3.fromRGB(40, 140, 90), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "The final exam, with fangs." },
	{ id = "omega-olahraga-orangutan", name = "Omega Sports Orangutan", rarity = "Ultimate", income = 49152, cost = 589824, body = Color3.fromRGB(240, 140, 60), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Wins every race before it starts." },
	{ id = "alpha-astronomi-aligator", name = "Alpha Astronomy Alligator", rarity = "Ultimate", income = 57344, cost = 688128, body = Color3.fromRGB(50, 70, 160), accent = Color3.fromRGB(200, 205, 215), shape = "Block", blurb = "Counts stars instead of sheep." },
	{ id = "zenith-zoologi-zebra", name = "Zenith Zoology Zebra", rarity = "Ultimate", income = 65536, cost = 786432, body = Color3.fromRGB(245, 245, 245), accent = Color3.fromRGB(50, 50, 60), shape = "Cylinder", blurb = "Knows every animal by first name." },
	-- Tier 15: PRINCIPAL
	{ id = "kepala-sekolah-kosmik", name = "Cosmic Principal", rarity = "PRINCIPAL", income = 81920, cost = 983040, body = Color3.fromRGB(120, 80, 255), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "Runs the school across the galaxy." },
	{ id = "principal-primordial", name = "Primordial Principal", rarity = "PRINCIPAL", income = 98304, cost = 1179648, body = Color3.fromRGB(230, 190, 90), accent = Color3.fromRGB(255, 255, 255), shape = "Wedge", blurb = "The first principal. Still on duty." },
	{ id = "pendiri-akademi", name = "Academy Founder", rarity = "PRINCIPAL", income = 114688, cost = 1376256, body = Color3.fromRGB(60, 160, 100), accent = Color3.fromRGB(255, 215, 0), shape = "Block", blurb = "Planted the first tree of the school." },
	{ id = "roh-principal-abadi", name = "Eternal Principal Spirit", rarity = "PRINCIPAL", income = 131072, cost = 1572864, body = Color3.fromRGB(220, 235, 255), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "The eternal spirit of the academy." },
	-- Tier 16: Secret — the top of the ladder. Twenty entries, each one a
	-- school secret with a name of its own. The tier base doubles from
	-- PRINCIPAL ($81,920/s) to $163,840/s, and entries climb in steps of
	-- $32,768/s, the same 20%-of-base step every other tier uses.
	{ id = "loker-laba-laba", name = "Locker Spider", rarity = "Secret", income = 163840, cost = 1966080, body = Color3.fromRGB(90, 90, 110), accent = Color3.fromRGB(200, 200, 220), shape = "Ball", blurb = "Every locker hides a web of secrets." },
	{ id = "brankas-bunglon", name = "Vault Chameleon", rarity = "Secret", income = 196608, cost = 2359296, body = Color3.fromRGB(60, 180, 120), accent = Color3.fromRGB(255, 215, 0), shape = "Block", blurb = "The vault that changes colour with the code." },
	{ id = "kode-kodok", name = "Code Toad", rarity = "Secret", income = 229376, cost = 2752512, body = Color3.fromRGB(120, 200, 90), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Croaks the password once, then forgets it." },
	{ id = "sandi-siput", name = "Cipher Snail", rarity = "Secret", income = 262144, cost = 3145728, body = Color3.fromRGB(220, 170, 130), accent = Color3.fromRGB(150, 110, 70), shape = "Cylinder", blurb = "Carries the cipher slowly, never drops it." },
	{ id = "dokumen-capung", name = "Document Dragonfly", rarity = "Secret", income = 294912, cost = 3538944, body = Color3.fromRGB(120, 200, 255), accent = Color3.fromRGB(255, 255, 255), shape = "Wedge", blurb = "Files fly faster than the eye can read." },
	{ id = "ijazah-iguana", name = "Diploma Iguana", rarity = "Secret", income = 327680, cost = 3932160, body = Color3.fromRGB(90, 160, 90), accent = Color3.fromRGB(255, 215, 0), shape = "Block", blurb = "Graduated in secret, diploma and all." },
	{ id = "transkrip-tokek", name = "Transcript Gecko", rarity = "Secret", income = 360448, cost = 4325376, body = Color3.fromRGB(140, 140, 160), accent = Color3.fromRGB(255, 120, 120), shape = "Ball", blurb = "Every grade, gecko-sealed and classified." },
	{ id = "absen-anoa", name = "Attendance Anoa", rarity = "Secret", income = 393216, cost = 4718592, body = Color3.fromRGB(150, 120, 90), accent = Color3.fromRGB(240, 240, 240), shape = "Cylinder", blurb = "Present in every class, recorded in none." },
	{ id = "piket-pipit", name = "Duty Sparrow", rarity = "Secret", income = 425984, cost = 5111808, body = Color3.fromRGB(255, 200, 90), accent = Color3.fromRGB(120, 90, 60), shape = "Wedge", blurb = "On duty at dawn, gone before the bell." },
	{ id = "kurikulum-kupu", name = "Curriculum Butterfly", rarity = "Secret", income = 458752, cost = 5505024, body = Color3.fromRGB(255, 150, 220), accent = Color3.fromRGB(255, 215, 0), shape = "Ball", blurb = "The syllabus, rewritten by butterflies." },
	{ id = "mikroskop-marmot", name = "Microscope Marmot", rarity = "Secret", income = 491520, cost = 5898240, body = Color3.fromRGB(180, 150, 110), accent = Color3.fromRGB(120, 220, 255), shape = "Block", blurb = "Sees secrets too small for the principal." },
	{ id = "teleskop-tapir", name = "Telescope Tapir", rarity = "Secret", income = 524288, cost = 6291456, body = Color3.fromRGB(100, 100, 130), accent = Color3.fromRGB(200, 200, 255), shape = "Cylinder", blurb = "Watches the stars during night class." },
	{ id = "kalkulator-kelelawar", name = "Calculator Bat", rarity = "Secret", income = 557056, cost = 6684672, body = Color3.fromRGB(70, 70, 90), accent = Color3.fromRGB(255, 215, 0), shape = "Wedge", blurb = "Adds up the night shift in the dark." },
	{ id = "kompas-kepiting", name = "Compass Crab", rarity = "Secret", income = 589824, cost = 7077888, body = Color3.fromRGB(255, 120, 90), accent = Color3.fromRGB(255, 255, 255), shape = "Ball", blurb = "Always points to the hidden classroom." },
	{ id = "origami-gurita", name = "Origami Octopus", rarity = "Secret", income = 622592, cost = 7471104, body = Color3.fromRGB(200, 120, 220), accent = Color3.fromRGB(255, 255, 255), shape = "Block", blurb = "Folds eight secrets at once." },
	{ id = "kaligrafi-kakatua", name = "Calligraphy Cockatoo", rarity = "Secret", income = 655360, cost = 7864320, body = Color3.fromRGB(255, 255, 255), accent = Color3.fromRGB(255, 180, 60), shape = "Ball", blurb = "Writes in beautiful, unreadable script." },
	{ id = "olimpiade-owa", name = "Olympiad Gibbon", rarity = "Secret", income = 688128, cost = 8257536, body = Color3.fromRGB(200, 170, 140), accent = Color3.fromRGB(255, 215, 0), shape = "Cylinder", blurb = "Wins gold in every secret subject." },
	{ id = "catur-cacing", name = "Chess Worm", rarity = "Secret", income = 720896, cost = 8650752, body = Color3.fromRGB(220, 180, 160), accent = Color3.fromRGB(60, 60, 60), shape = "Wedge", blurb = "Checkmates from underneath the board." },
	{ id = "rahasia-rayap", name = "Secret Termite", rarity = "Secret", income = 753664, cost = 9043968, body = Color3.fromRGB(190, 160, 110), accent = Color3.fromRGB(120, 90, 50), shape = "Ball", blurb = "Eats the evidence, keeps the secret." },
	{ id = "misteri-manta", name = "Mystery Manta", rarity = "Secret", income = 786432, cost = 9437184, body = Color3.fromRGB(80, 110, 180), accent = Color3.fromRGB(200, 230, 255), shape = "Wedge", blurb = "Glides through the school's deepest secret." },
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

-- The tier above this one, or nil at the top of the ladder (Secret).
function Catalog.NextTier(rarity)
	local index = table.find(Config.RARITY_ORDER, rarity)
	if not index then
		return nil
	end
	return Config.RARITY_ORDER[index + 1]
end

-- Picks a random brainrot of one tier, using the caller's Random.
function Catalog.GetRandomOfRarity(rarity, rng)
	local pool = byRarity[rarity]
	if not pool or #pool == 0 then
		return ENTRIES[1]
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Weighted tier roll against any weights table (parade, gacha, high pads).
function Catalog.RollTier(rng, weights)
	local total = 0
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		total += weights[rarity] or 0
	end
	local roll = rng:NextNumber(0, total)
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		roll -= weights[rarity] or 0
		if roll <= 0 then
			return rarity
		end
	end
	return "Common"
end

-- Weighted rarity roll for the parade. Luck levels shift weight from Common
-- toward the rare end; the top tier is never boosted.
function Catalog.RollRarity(rng, luckLevels)
	local weights = {}
	for _, rarity in ipairs(Config.RARITY_ORDER) do
		local weight = Config.RARITY_WEIGHTS[rarity]
		if rarity == "Common" then
			weight = weight * math.max(0.2, 1 - 0.25 * luckLevels)
		elseif rarity ~= "Secret" then
			weight = weight * (1 + 0.3 * luckLevels)
		end
		weights[rarity] = weight
	end
	return Catalog.RollTier(rng, weights)
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

-- A uniformly random mutation name, for a tier-16 fuse result.
function Catalog.RandomMutation(rng)
	local names = {}
	for name in pairs(Config.MUTATIONS) do
		table.insert(names, name)
	end
	return names[rng:NextInteger(1, #names)]
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
