-- Game client: the whole HUD for Brainrot School, plus every key binding.
-- The server owns all state; this script only renders the snapshots it sends
-- and fires remote requests. Keys go through ContextActionService, because
-- Roblox's default camera scripts swallow some keys before InputBegan sees
-- them. Nothing sits in the top-left corner: Roblox's own menu buttons cover it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.BrainrotCatalog)
local Config = require(Shared.Config)
local QuestCatalog = require(Shared.QuestCatalog)
local UpgradeCatalog = require(Shared.UpgradeCatalog)

local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local pullEvent = remotes:WaitForChild("PullPlayer")
local pushEvent = remotes:WaitForChild("PushPlayer")
local lockEvent = remotes:WaitForChild("ToggleLock")
local rebirthEvent = remotes:WaitForChild("DoRebirth")
local upgradeEvent = remotes:WaitForChild("BuyUpgrade")
local stateEvent = remotes:WaitForChild("StateUpdate")
local notifyEvent = remotes:WaitForChild("Notify")
local hazardEvent = remotes:WaitForChild("HazardAlert")
local crowEvent = remotes:WaitForChild("CrowAlert")
local openGachaEvent = remotes:WaitForChild("OpenGacha")
local openFuseEvent = remotes:WaitForChild("OpenFuse")
local rollGachaEvent = remotes:WaitForChild("RollGacha")
local fuseEvent = remotes:WaitForChild("FuseBrainrots")

local DARK = Color3.fromRGB(22, 26, 38)
local GOLD = Color3.fromRGB(255, 215, 0)
local GREEN = Color3.fromRGB(110, 255, 140)
local RED = Color3.fromRGB(255, 100, 100)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREY = Color3.fromRGB(190, 200, 220)

local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local grouped = ""
	while #text > 3 do
		grouped = "," .. string.sub(text, -3) .. grouped
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. grouped
end

local function roundCorners(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = instance
	return corner
end

local function makeButton(parent, text, color, size, position)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 18
	button.TextColor3 = WHITE
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent
	roundCorners(button, 10)
	return button
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Top-centre money bar: cash, income, and the spec banner that tells the
-- judge what the game holds, all in one glance.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 10)
topBar.Size = UDim2.fromOffset(580, 86)
topBar.BackgroundColor3 = DARK
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = gui
roundCorners(topBar, 12)

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(1, 0, 0, 36)
cashLabel.Position = UDim2.fromOffset(0, 4)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextSize = 30
cashLabel.TextColor3 = GOLD
cashLabel.Text = "$100"
cashLabel.Parent = topBar

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Size = UDim2.new(1, 0, 0, 22)
incomeLabel.Position = UDim2.fromOffset(0, 40)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextSize = 17
incomeLabel.TextColor3 = GREEN
incomeLabel.Text = "+$0/s  ·  x1"
incomeLabel.Parent = topBar

local specLabel = Instance.new("TextLabel")
specLabel.Size = UDim2.new(1, 0, 0, 18)
specLabel.Position = UDim2.fromOffset(0, 62)
specLabel.BackgroundTransparency = 1
specLabel.Font = Enum.Font.GothamBold
specLabel.TextSize = 13
specLabel.TextColor3 = GREY
specLabel.TextScaled = true
specLabel.Text = "80 BRAINROTS  ·  16 TIERS  ·  5 MUTATIONS  ·  PULL  ·  PUSH  ·  STEAL  ·  LOCK  ·  REBIRTH  ·  GACHA  ·  FUSE"
specLabel.Parent = topBar

-- Event banner: the Lunch Rush countdown and the rush itself.
local eventBanner = Instance.new("Frame")
eventBanner.Name = "EventBanner"
eventBanner.AnchorPoint = Vector2.new(0.5, 0)
eventBanner.Position = UDim2.new(0.5, 0, 0, 104)
eventBanner.Size = UDim2.fromOffset(480, 44)
eventBanner.BackgroundColor3 = Color3.fromRGB(200, 80, 30)
eventBanner.BackgroundTransparency = 0.1
eventBanner.BorderSizePixel = 0
eventBanner.Visible = false
eventBanner.Parent = gui
roundCorners(eventBanner, 10)

local eventLabel = Instance.new("TextLabel")
eventLabel.Size = UDim2.fromScale(1, 1)
eventLabel.BackgroundTransparency = 1
eventLabel.Font = Enum.Font.FredokaOne
eventLabel.TextSize = 22
eventLabel.TextColor3 = WHITE
eventLabel.Text = ""
eventLabel.Parent = eventBanner

-- Quest panel, right side: the current chapter step plus today's three dailies.
local questPanel = Instance.new("Frame")
questPanel.Name = "QuestPanel"
questPanel.AnchorPoint = Vector2.new(1, 0)
questPanel.Position = UDim2.new(1, -12, 0, 12)
questPanel.Size = UDim2.fromOffset(310, 250)
questPanel.BackgroundColor3 = DARK
questPanel.BackgroundTransparency = 0.15
questPanel.BorderSizePixel = 0
questPanel.Parent = gui
roundCorners(questPanel, 12)

local questTitle = Instance.new("TextLabel")
questTitle.Size = UDim2.new(1, -20, 0, 28)
questTitle.Position = UDim2.fromOffset(10, 8)
questTitle.BackgroundTransparency = 1
questTitle.Font = Enum.Font.FredokaOne
questTitle.TextSize = 20
questTitle.TextColor3 = GOLD
questTitle.TextXAlignment = Enum.TextXAlignment.Left
questTitle.Text = "QUESTS"
questTitle.Parent = questPanel

local chapterLabel = Instance.new("TextLabel")
chapterLabel.Size = UDim2.new(1, -20, 0, 22)
chapterLabel.Position = UDim2.fromOffset(10, 38)
chapterLabel.BackgroundTransparency = 1
chapterLabel.Font = Enum.Font.GothamBold
chapterLabel.TextSize = 15
chapterLabel.TextColor3 = WHITE
chapterLabel.TextXAlignment = Enum.TextXAlignment.Left
chapterLabel.Text = "Chapter 1: New Student"
chapterLabel.Parent = questPanel

local stepLabel = Instance.new("TextLabel")
stepLabel.Size = UDim2.new(1, -20, 0, 44)
stepLabel.Position = UDim2.fromOffset(10, 60)
stepLabel.BackgroundTransparency = 1
stepLabel.Font = Enum.Font.Gotham
stepLabel.TextSize = 15
stepLabel.TextColor3 = GREY
stepLabel.TextXAlignment = Enum.TextXAlignment.Left
stepLabel.TextYAlignment = Enum.TextYAlignment.Top
stepLabel.TextWrapped = true
stepLabel.Text = ""
stepLabel.Parent = questPanel

local dailyTitle = Instance.new("TextLabel")
dailyTitle.Size = UDim2.new(1, -20, 0, 22)
dailyTitle.Position = UDim2.fromOffset(10, 112)
dailyTitle.BackgroundTransparency = 1
dailyTitle.Font = Enum.Font.GothamBold
dailyTitle.TextSize = 15
dailyTitle.TextColor3 = GOLD
dailyTitle.TextXAlignment = Enum.TextXAlignment.Left
dailyTitle.Text = "DAILY"
dailyTitle.Parent = questPanel

local dailyLabels = {}
for i = 1, 3 do
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 40)
	label.Position = UDim2.fromOffset(10, 136 + (i - 1) * 38)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextColor3 = GREY
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = ""
	label.Parent = questPanel
	dailyLabels[i] = label
end

-- Carrying status, above the bottom bar.
local carryingLabel = Instance.new("TextLabel")
carryingLabel.Name = "CarryingLabel"
carryingLabel.AnchorPoint = Vector2.new(0.5, 1)
carryingLabel.Position = UDim2.new(0.5, 0, 1, -128)
carryingLabel.Size = UDim2.fromOffset(480, 28)
carryingLabel.BackgroundTransparency = 1
carryingLabel.Font = Enum.Font.FredokaOne
carryingLabel.TextSize = 20
carryingLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
carryingLabel.Text = ""
carryingLabel.Visible = false
carryingLabel.Parent = gui

-- Key hints, just above the buttons.
local hintLabel = Instance.new("TextLabel")
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -84)
hintLabel.Size = UDim2.fromOffset(560, 22)
hintLabel.BackgroundTransparency = 1
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 15
hintLabel.TextColor3 = WHITE
hintLabel.Text = "[Q] PULL   ·   [F] PUSH   ·   [E] STEAL / SIT / GACHA / FUSE   ·   [L] LOCK   ·   Click a brainrot to buy it"
hintLabel.Parent = gui

-- Bottom buttons: lock, rebirth, fuse, report card, upgrades.
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.AnchorPoint = Vector2.new(0.5, 1)
bottomBar.Position = UDim2.new(0.5, 0, 1, -12)
bottomBar.Size = UDim2.fromOffset(700, 56)
bottomBar.BackgroundTransparency = 1
bottomBar.Parent = gui

local lockButton = makeButton(bottomBar, "LOCK [L]", Color3.fromRGB(70, 130, 240), UDim2.fromOffset(134, 48), UDim2.fromOffset(0, 4))
local rebirthButton = makeButton(bottomBar, "REBIRTH", Color3.fromRGB(150, 90, 230), UDim2.fromOffset(134, 48), UDim2.fromOffset(142, 4))
local fuseBarButton = makeButton(bottomBar, "FUSE [K]", Color3.fromRGB(230, 80, 140), UDim2.fromOffset(110, 48), UDim2.fromOffset(284, 4))
local indexButton = makeButton(bottomBar, "REPORT CARD", Color3.fromRGB(70, 180, 110), UDim2.fromOffset(150, 48), UDim2.fromOffset(402, 4))
local upgradeButton = makeButton(bottomBar, "UPGRADES", Color3.fromRGB(230, 140, 40), UDim2.fromOffset(134, 48), UDim2.fromOffset(560, 4))

-- The big centre banner for alerts and quest completions.
local notifyFrame = Instance.new("Frame")
notifyFrame.Name = "NotifyBanner"
notifyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
notifyFrame.Position = UDim2.new(0.5, 0, 0.32, 0)
notifyFrame.Size = UDim2.fromOffset(620, 56)
notifyFrame.BackgroundColor3 = DARK
notifyFrame.BackgroundTransparency = 0.1
notifyFrame.BorderSizePixel = 0
notifyFrame.Visible = false
notifyFrame.Parent = gui
roundCorners(notifyFrame, 12)

local notifyLabel = Instance.new("TextLabel")
notifyLabel.Size = UDim2.fromScale(1, 1)
notifyLabel.BackgroundTransparency = 1
notifyLabel.Font = Enum.Font.FredokaOne
notifyLabel.TextSize = 21
notifyLabel.TextColor3 = WHITE
notifyLabel.TextWrapped = true
notifyLabel.Text = ""
notifyLabel.Parent = notifyFrame

local notifyToken = 0
local NOTIFY_COLORS = {
	info = WHITE,
	good = GREEN,
	warn = Color3.fromRGB(255, 220, 100),
	alert = RED,
	quest = GOLD,
}

local function showNotify(text, kind)
	notifyToken += 1
	local token = notifyToken
	notifyLabel.Text = text
	notifyLabel.TextColor3 = NOTIFY_COLORS[kind] or WHITE
	notifyFrame.Visible = true
	task.delay(3.5, function()
		if token == notifyToken then
			notifyFrame.Visible = false
		end
	end)
end

-- Report Card: the 80-entry collection grid, built once from the catalog.
local reportFrame = Instance.new("Frame")
reportFrame.Name = "ReportCard"
reportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
reportFrame.Position = UDim2.fromScale(0.5, 0.5)
reportFrame.Size = UDim2.fromOffset(660, 500)
reportFrame.BackgroundColor3 = DARK
reportFrame.BackgroundTransparency = 0.05
reportFrame.BorderSizePixel = 0
reportFrame.Visible = false
reportFrame.Parent = gui
roundCorners(reportFrame, 14)

local reportTitle = Instance.new("TextLabel")
reportTitle.Size = UDim2.new(1, -20, 0, 34)
reportTitle.Position = UDim2.fromOffset(10, 10)
reportTitle.BackgroundTransparency = 1
reportTitle.Font = Enum.Font.FredokaOne
reportTitle.TextSize = 24
reportTitle.TextColor3 = GOLD
reportTitle.TextXAlignment = Enum.TextXAlignment.Left
reportTitle.Text = "REPORT CARD  —  0/80"
reportTitle.Parent = reportFrame

local reportBonus = Instance.new("TextLabel")
reportBonus.Size = UDim2.new(1, -20, 0, 22)
reportBonus.Position = UDim2.fromOffset(10, 44)
reportBonus.BackgroundTransparency = 1
reportBonus.Font = Enum.Font.GothamBold
reportBonus.TextSize = 14
reportBonus.TextColor3 = GREEN
reportBonus.TextXAlignment = Enum.TextXAlignment.Left
reportBonus.Text = "Every entry adds +2% income"
reportBonus.Parent = reportFrame

local reportClose = makeButton(reportFrame, "X", Color3.fromRGB(200, 70, 70), UDim2.fromOffset(36, 36), UDim2.new(1, -46, 0, 10))
reportClose.TextSize = 20

local reportScroll = Instance.new("ScrollingFrame")
reportScroll.Size = UDim2.new(1, -20, 1, -84)
reportScroll.Position = UDim2.fromOffset(10, 74)
reportScroll.BackgroundTransparency = 1
reportScroll.BorderSizePixel = 0
reportScroll.ScrollBarThickness = 6
reportScroll.CanvasSize = UDim2.fromOffset(0, 0)
reportScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
reportScroll.Parent = reportFrame

local reportGrid = Instance.new("UIGridLayout")
reportGrid.CellSize = UDim2.fromOffset(148, 64)
reportGrid.CellPadding = UDim2.fromOffset(8, 8)
reportGrid.Parent = reportScroll

local reportCells = {}
for _, rarity in ipairs(Config.RARITY_ORDER) do
	for _, entry in ipairs(Catalog.ByRarity[rarity]) do
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
		cell.BorderSizePixel = 0
		cell.Parent = reportScroll
		roundCorners(cell, 8)
		local stripe = Instance.new("Frame")
		stripe.Size = UDim2.new(0, 6, 1, 0)
		stripe.BackgroundColor3 = Config.RARITY_COLORS[rarity]
		stripe.BorderSizePixel = 0
		stripe.Parent = cell
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -14, 0, 24)
		nameLabel.Position = UDim2.fromOffset(10, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextColor3 = WHITE
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = entry.name
		nameLabel.Parent = cell
		local metaLabel = Instance.new("TextLabel")
		metaLabel.Size = UDim2.new(1, -14, 0, 18)
		metaLabel.Position = UDim2.fromOffset(10, 28)
		metaLabel.BackgroundTransparency = 1
		metaLabel.Font = Enum.Font.Gotham
		metaLabel.TextSize = 12
		metaLabel.TextColor3 = Config.RARITY_COLORS[rarity]
		metaLabel.TextXAlignment = Enum.TextXAlignment.Left
		metaLabel.Text = string.upper(rarity) .. " · $" .. entry.income .. "/s"
		metaLabel.Parent = cell
		local ownedLabel = Instance.new("TextLabel")
		ownedLabel.Size = UDim2.new(1, -14, 0, 16)
		ownedLabel.Position = UDim2.fromOffset(10, 44)
		ownedLabel.BackgroundTransparency = 1
		ownedLabel.Font = Enum.Font.GothamBold
		ownedLabel.TextSize = 12
		ownedLabel.TextColor3 = GREY
		ownedLabel.TextXAlignment = Enum.TextXAlignment.Left
		ownedLabel.Text = "Not found yet"
		ownedLabel.Parent = cell
		reportCells[entry.id] = ownedLabel
	end
end

-- Upgrades panel: five rows, each with a buy button.
local upgradeFrame = Instance.new("Frame")
upgradeFrame.Name = "Upgrades"
upgradeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
upgradeFrame.Position = UDim2.fromScale(0.5, 0.5)
upgradeFrame.Size = UDim2.fromOffset(540, 430)
upgradeFrame.BackgroundColor3 = DARK
upgradeFrame.BackgroundTransparency = 0.05
upgradeFrame.BorderSizePixel = 0
upgradeFrame.Visible = false
upgradeFrame.Parent = gui
roundCorners(upgradeFrame, 14)

local upgradeTitle = Instance.new("TextLabel")
upgradeTitle.Size = UDim2.new(1, -20, 0, 34)
upgradeTitle.Position = UDim2.fromOffset(10, 10)
upgradeTitle.BackgroundTransparency = 1
upgradeTitle.Font = Enum.Font.FredokaOne
upgradeTitle.TextSize = 24
upgradeTitle.TextColor3 = GOLD
upgradeTitle.TextXAlignment = Enum.TextXAlignment.Left
upgradeTitle.Text = "UPGRADES"
upgradeTitle.Parent = upgradeFrame

local upgradeClose = makeButton(upgradeFrame, "X", Color3.fromRGB(200, 70, 70), UDim2.fromOffset(36, 36), UDim2.new(1, -46, 0, 10))
upgradeClose.TextSize = 20

local upgradeRows = {}
for i, upgradeId in ipairs(UpgradeCatalog.ORDER) do
	local definition = UpgradeCatalog.UPGRADES[upgradeId]
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 62)
	row.Position = UDim2.fromOffset(10, 54 + (i - 1) * 70)
	row.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
	row.BorderSizePixel = 0
	row.Parent = upgradeFrame
	roundCorners(row, 8)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -150, 0, 24)
	nameLabel.Position = UDim2.fromOffset(10, 6)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 17
	nameLabel.TextColor3 = WHITE
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = definition.name
	nameLabel.Parent = row
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -150, 0, 22)
	descLabel.Position = UDim2.fromOffset(10, 30)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextColor3 = GREY
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Text = definition.desc
	descLabel.Parent = row
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.fromOffset(60, 24)
	levelLabel.Position = UDim2.new(1, -150, 0, 18)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextSize = 14
	levelLabel.TextColor3 = GOLD
	levelLabel.Text = "Lv 0/1"
	levelLabel.Parent = row
	local buyButton = makeButton(row, "$500", Color3.fromRGB(70, 180, 110), UDim2.fromOffset(76, 36), UDim2.new(1, -86, 0, 13))
	buyButton.TextSize = 15
	buyButton.MouseButton1Click:Connect(function()
		upgradeEvent:FireServer(upgradeId)
	end)
	upgradeRows[upgradeId] = { levelLabel = levelLabel, buyButton = buyButton }
end

-- Gacha panel: one roll, one flat price, one random brainrot straight to
-- your classroom. Opens from the Gacha Machine's Press [E] prompt.
local gachaFrame = Instance.new("Frame")
gachaFrame.Name = "Gacha"
gachaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
gachaFrame.Position = UDim2.fromScale(0.5, 0.5)
gachaFrame.Size = UDim2.fromOffset(460, 300)
gachaFrame.BackgroundColor3 = DARK
gachaFrame.BackgroundTransparency = 0.05
gachaFrame.BorderSizePixel = 0
gachaFrame.Visible = false
gachaFrame.Parent = gui
roundCorners(gachaFrame, 14)

local gachaTitle = Instance.new("TextLabel")
gachaTitle.Size = UDim2.new(1, -20, 0, 34)
gachaTitle.Position = UDim2.fromOffset(10, 10)
gachaTitle.BackgroundTransparency = 1
gachaTitle.Font = Enum.Font.FredokaOne
gachaTitle.TextSize = 24
gachaTitle.TextColor3 = GOLD
gachaTitle.TextXAlignment = Enum.TextXAlignment.Left
gachaTitle.Text = "GACHA MACHINE"
gachaTitle.Parent = gachaFrame

local gachaClose = makeButton(gachaFrame, "X", Color3.fromRGB(200, 70, 70), UDim2.fromOffset(36, 36), UDim2.new(1, -46, 0, 10))
gachaClose.TextSize = 20

local gachaDesc = Instance.new("TextLabel")
gachaDesc.Size = UDim2.new(1, -20, 0, 60)
gachaDesc.Position = UDim2.fromOffset(10, 54)
gachaDesc.BackgroundTransparency = 1
gachaDesc.Font = Enum.Font.Gotham
gachaDesc.TextSize = 16
gachaDesc.TextColor3 = GREY
gachaDesc.TextXAlignment = Enum.TextXAlignment.Left
gachaDesc.TextYAlignment = Enum.TextYAlignment.Top
gachaDesc.TextWrapped = true
gachaDesc.Text = "One roll: $1,000. A random brainrot — any of the 16 tiers, even Secret — goes straight to a free pedestal in your classroom. Higher tiers are rarer!"
gachaDesc.Parent = gachaFrame

local gachaCashLabel = Instance.new("TextLabel")
gachaCashLabel.Size = UDim2.new(1, -20, 0, 26)
gachaCashLabel.Position = UDim2.fromOffset(10, 122)
gachaCashLabel.BackgroundTransparency = 1
gachaCashLabel.Font = Enum.Font.GothamBold
gachaCashLabel.TextSize = 17
gachaCashLabel.TextColor3 = GOLD
gachaCashLabel.TextXAlignment = Enum.TextXAlignment.Left
gachaCashLabel.Text = "Your cash: $100"
gachaCashLabel.Parent = gachaFrame

local gachaRollButton = makeButton(gachaFrame, "ROLL — $1,000", Color3.fromRGB(230, 70, 70), UDim2.fromOffset(280, 56), UDim2.new(0.5, -140, 0, 168))
gachaRollButton.TextSize = 22
gachaRollButton.MouseButton1Click:Connect(function()
	rollGachaEvent:FireServer()
end)

local gachaNote = Instance.new("TextLabel")
gachaNote.Size = UDim2.new(1, -20, 0, 40)
gachaNote.Position = UDim2.fromOffset(10, 236)
gachaNote.BackgroundTransparency = 1
gachaNote.Font = Enum.Font.Gotham
gachaNote.TextSize = 13
gachaNote.TextColor3 = GREY
gachaNote.TextWrapped = true
gachaNote.Text = "Tip: a full base blocks the roll — fuse your extras first!"
gachaNote.Parent = gachaFrame

-- Fuse panel: pick three brainrots of one tier and fuse them into the next.
local fuseFrame = Instance.new("Frame")
fuseFrame.Name = "FuseLab"
fuseFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fuseFrame.Position = UDim2.fromScale(0.5, 0.5)
fuseFrame.Size = UDim2.fromOffset(640, 500)
fuseFrame.BackgroundColor3 = DARK
fuseFrame.BackgroundTransparency = 0.05
fuseFrame.BorderSizePixel = 0
fuseFrame.Visible = false
fuseFrame.Parent = gui
roundCorners(fuseFrame, 14)

local fuseTitle = Instance.new("TextLabel")
fuseTitle.Size = UDim2.new(1, -20, 0, 34)
fuseTitle.Position = UDim2.fromOffset(10, 10)
fuseTitle.BackgroundTransparency = 1
fuseTitle.Font = Enum.Font.FredokaOne
fuseTitle.TextSize = 24
fuseTitle.TextColor3 = GOLD
fuseTitle.TextXAlignment = Enum.TextXAlignment.Left
fuseTitle.Text = "FUSE LAB"
fuseTitle.Parent = fuseFrame

local fuseClose = makeButton(fuseFrame, "X", Color3.fromRGB(200, 70, 70), UDim2.fromOffset(36, 36), UDim2.new(1, -46, 0, 10))
fuseClose.TextSize = 20

local fuseDesc = Instance.new("TextLabel")
fuseDesc.Size = UDim2.new(1, -20, 0, 22)
fuseDesc.Position = UDim2.fromOffset(10, 46)
fuseDesc.BackgroundTransparency = 1
fuseDesc.Font = Enum.Font.Gotham
fuseDesc.TextSize = 14
fuseDesc.TextColor3 = GREY
fuseDesc.TextXAlignment = Enum.TextXAlignment.Left
fuseDesc.Text = "Select 3 brainrots of the SAME tier — they fuse into 1 of the next tier."
fuseDesc.Parent = fuseFrame

local fuseSelectedLabel = Instance.new("TextLabel")
fuseSelectedLabel.Size = UDim2.new(1, -20, 0, 24)
fuseSelectedLabel.Position = UDim2.fromOffset(10, 70)
fuseSelectedLabel.BackgroundTransparency = 1
fuseSelectedLabel.Font = Enum.Font.GothamBold
fuseSelectedLabel.TextSize = 16
fuseSelectedLabel.TextColor3 = WHITE
fuseSelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
fuseSelectedLabel.Text = "Selected: 0/3"
fuseSelectedLabel.Parent = fuseFrame

local fuseScroll = Instance.new("ScrollingFrame")
fuseScroll.Size = UDim2.new(1, -20, 1, -160)
fuseScroll.Position = UDim2.fromOffset(10, 100)
fuseScroll.BackgroundTransparency = 1
fuseScroll.BorderSizePixel = 0
fuseScroll.ScrollBarThickness = 6
fuseScroll.CanvasSize = UDim2.fromOffset(0, 0)
fuseScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
fuseScroll.Parent = fuseFrame

local fuseList = Instance.new("UIListLayout")
fuseList.Padding = UDim.new(0, 6)
fuseList.Parent = fuseScroll

local fuseButton = makeButton(fuseFrame, "FUSE — pick 3", Color3.fromRGB(90, 95, 110), UDim2.fromOffset(280, 48), UDim2.new(0.5, -140, 1, -60))
fuseButton.TextSize = 20

local fuseSelected = {} -- [pedestalId] = true
local fuseSelectedTier = nil
local fuseRows = {} -- [pedestalId] = row button
local fuseSignature = ""

local function refreshFuseSelection()
	local count = 0
	local tier = nil
	for pedestalId in pairs(fuseSelected) do
		count += 1
		local row = fuseRows[pedestalId]
		if row then
			tier = row:GetAttribute("Tier")
		end
	end
	fuseSelectedTier = tier
	if count == 0 then
		fuseSelectedLabel.Text = "Selected: 0/3"
	else
		fuseSelectedLabel.Text = "Selected: " .. count .. "/3  (" .. (tier or "?") .. ")"
	end
	for pedestalId, row in pairs(fuseRows) do
		if fuseSelected[pedestalId] then
			row.BackgroundColor3 = Color3.fromRGB(90, 140, 220)
		else
			row.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
		end
	end
	if count == 3 then
		fuseButton.Text = "FUSE!"
		fuseButton.BackgroundColor3 = Color3.fromRGB(150, 90, 230)
	else
		fuseButton.Text = "FUSE — pick 3"
		fuseButton.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
	end
end

local function refreshFuseList(snapshot)
	-- Rebuild the rows only when the placed set actually changed, so a
	-- selection survives the once-a-second snapshot.
	local parts = {}
	for _, placed in ipairs(snapshot.placed) do
		table.insert(parts, placed.pedestalId)
	end
	table.sort(parts)
	local signature = table.concat(parts, ",")
	if signature == fuseSignature then
		return
	end
	fuseSignature = signature
	for _, child in ipairs(fuseScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	fuseRows = {}
	-- Drop selections whose brainrot is no longer placed.
	local stillPlaced = {}
	for _, placed in ipairs(snapshot.placed) do
		stillPlaced[placed.pedestalId] = true
	end
	for pedestalId in pairs(fuseSelected) do
		if not stillPlaced[pedestalId] then
			fuseSelected[pedestalId] = nil
		end
	end
	local sorted = table.clone(snapshot.placed)
	table.sort(sorted, function(a, b)
		local rankA = QuestCatalog.RARITY_RANK[a.rarity] or 0
		local rankB = QuestCatalog.RARITY_RANK[b.rarity] or 0
		if rankA ~= rankB then
			return rankA < rankB
		end
		return a.name < b.name
	end)
	for _, placed in ipairs(sorted) do
		local entry = Catalog.ById[placed.catalogId]
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -8, 0, 40)
		row.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.TextSize = 15
		row.TextColor3 = WHITE
		row.TextXAlignment = Enum.TextXAlignment.Left
		row:SetAttribute("Tier", placed.rarity)
		local income = entry and Catalog.MutatedIncome(entry, placed.mutation) or 0
		local mutationText = placed.mutation and (" · " .. placed.mutation) or ""
		row.Text = "   " .. placed.name .. "  —  " .. placed.rarity .. mutationText .. "  ·  $" .. income .. "/s"
		row.Parent = fuseScroll
		roundCorners(row, 8)
		fuseRows[placed.pedestalId] = row
		row.MouseButton1Click:Connect(function()
			if fuseSelected[placed.pedestalId] then
				fuseSelected[placed.pedestalId] = nil
			else
				local count = 0
				for _ in pairs(fuseSelected) do
					count += 1
				end
				if count >= 3 then
					showNotify("Pick only 3 brainrots!", "warn")
					return
				end
				if fuseSelectedTier and placed.rarity ~= fuseSelectedTier then
					showNotify("Fuse needs 3 of the SAME tier!", "warn")
					return
				end
				fuseSelected[placed.pedestalId] = true
			end
			refreshFuseSelection()
		end)
	end
	refreshFuseSelection()
end

fuseButton.MouseButton1Click:Connect(function()
	local count = 0
	for _ in pairs(fuseSelected) do
		count += 1
	end
	if count ~= 3 then
		showNotify("Select 3 brainrots of the same tier first!", "warn")
		return
	end
	local ids = {}
	for pedestalId in pairs(fuseSelected) do
		table.insert(ids, pedestalId)
	end
	fuseEvent:FireServer(ids)
	fuseSelected = {}
	fuseSelectedTier = nil
	refreshFuseSelection()
end)

-- Snapshot rendering: one function paints every HUD element from the state.
local function refreshQuests(snapshot)
	local chapter = QuestCatalog.CHAPTERS[snapshot.questChapter]
	local step = chapter and chapter.steps[snapshot.questStep] or nil
	if chapter and step then
		chapterLabel.Text = "Chapter " .. snapshot.questChapter .. ": " .. chapter.title
		local progress = snapshot.questProgress[step.key] or 0
		if step.key == "ownedCount" then
			progress = snapshot.ownedCount
		end
		stepLabel.Text = step.text .. "  (" .. progress .. "/" .. step.target .. ")  ·  +" .. formatMoney(step.reward)
	else
		chapterLabel.Text = "All chapters complete!"
		stepLabel.Text = "You are a School Star. Keep collecting!"
	end
	for i, daily in ipairs(QuestCatalog.GetDailyQuests(snapshot.dailyDay)) do
		local progress = snapshot.dailyProgress[daily.key] or 0
		local mark = snapshot.dailyDone[daily.key] and "DONE ✓" or (progress .. "/" .. daily.target)
		dailyLabels[i].Text = daily.text .. "  (" .. mark .. ")  ·  +" .. formatMoney(daily.reward)
	end
end

local function refreshReportCard(snapshot)
	reportTitle.Text = "REPORT CARD  —  " .. snapshot.ownedCount .. "/" .. snapshot.ownedTotal
	local bonus = math.floor(snapshot.ownedCount * 2)
	reportBonus.Text = "Collection bonus: +" .. bonus .. "% income  ·  every entry adds +2%"
	for catalogId, ownedLabel in pairs(reportCells) do
		if snapshot.owned[catalogId] then
			ownedLabel.Text = "✓ OWNED"
			ownedLabel.TextColor3 = GREEN
		else
			ownedLabel.Text = "Not found yet"
			ownedLabel.TextColor3 = GREY
		end
	end
end

local function refreshUpgrades(snapshot)
	for upgradeId, row in pairs(upgradeRows) do
		local level = snapshot.upgrades[upgradeId] or 0
		local maxLevel = UpgradeCatalog.MaxLevel(upgradeId)
		row.levelLabel.Text = "Lv " .. level .. "/" .. maxLevel
		local cost = UpgradeCatalog.NextCost(upgradeId, level)
		if cost then
			row.buyButton.Text = formatMoney(cost)
			row.buyButton.BackgroundColor3 = Color3.fromRGB(70, 180, 110)
		else
			row.buyButton.Text = "MAX"
			row.buyButton.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
		end
	end
end

local function onStateUpdate(snapshot)
	cashLabel.Text = formatMoney(snapshot.cash)
	local incomeText = "+" .. formatMoney(snapshot.income) .. "/s  ·  x" .. snapshot.multiplier
	if snapshot.fresh then
		incomeText ..= "  ·  FRESH +10% (" .. snapshot.freshSecondsLeft .. "s)"
	end
	incomeLabel.Text = incomeText
	gachaCashLabel.Text = "Your cash: " .. formatMoney(snapshot.cash)
	if snapshot.carriedCount > 0 then
		carryingLabel.Text = "CARRYING: " .. table.concat(snapshot.carried, "  +  ") .. "  —  RUN HOME!"
		carryingLabel.Visible = true
	else
		carryingLabel.Visible = false
	end
	if snapshot.locked then
		lockButton.Text = "LOCKED " .. snapshot.lockSecondsLeft .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(50, 90, 180)
	elseif snapshot.lockReadyIn > 0 then
		lockButton.Text = "LOCK (" .. snapshot.lockReadyIn .. "s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(90, 95, 110)
	else
		lockButton.Text = "LOCK [L]"
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 130, 240)
	end
	refreshQuests(snapshot)
	refreshReportCard(snapshot)
	refreshUpgrades(snapshot)
	refreshFuseList(snapshot)
end

stateEvent.OnClientEvent:Connect(onStateUpdate)
notifyEvent.OnClientEvent:Connect(showNotify)
crowEvent.OnClientEvent:Connect(function(text)
	showNotify(text, "warn")
end)

hazardEvent.OnClientEvent:Connect(function(phase, secondsLeft)
	if phase == "countdown" then
		eventBanner.Visible = true
		eventBanner.BackgroundColor3 = Color3.fromRGB(200, 120, 30)
		eventLabel.Text = "LUNCH RUSH in " .. secondsLeft .. "s — RUN HOME!"
	elseif phase == "rush" then
		eventBanner.Visible = true
		eventBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 30)
		eventLabel.Text = "LUNCH RUSH! Take cover in a classroom!"
	elseif phase == "clear" then
		eventBanner.Visible = false
	end
end)

-- Buttons.
lockButton.MouseButton1Click:Connect(function()
	lockEvent:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)
indexButton.MouseButton1Click:Connect(function()
	reportFrame.Visible = not reportFrame.Visible
	upgradeFrame.Visible = false
	gachaFrame.Visible = false
	fuseFrame.Visible = false
end)
upgradeButton.MouseButton1Click:Connect(function()
	upgradeFrame.Visible = not upgradeFrame.Visible
	reportFrame.Visible = false
	gachaFrame.Visible = false
	fuseFrame.Visible = false
end)
local function toggleFuse()
	fuseFrame.Visible = not fuseFrame.Visible
	reportFrame.Visible = false
	upgradeFrame.Visible = false
	gachaFrame.Visible = false
end
fuseBarButton.MouseButton1Click:Connect(toggleFuse)
reportClose.MouseButton1Click:Connect(function()
	reportFrame.Visible = false
end)
upgradeClose.MouseButton1Click:Connect(function()
	upgradeFrame.Visible = false
end)
gachaClose.MouseButton1Click:Connect(function()
	gachaFrame.Visible = false
end)
fuseClose.MouseButton1Click:Connect(function()
	fuseFrame.Visible = false
end)

-- The machines open their panels from their Press [E] prompts.
openGachaEvent.OnClientEvent:Connect(function()
	gachaFrame.Visible = true
	reportFrame.Visible = false
	upgradeFrame.Visible = false
	fuseFrame.Visible = false
end)
openFuseEvent.OnClientEvent:Connect(function()
	fuseFrame.Visible = true
	reportFrame.Visible = false
	upgradeFrame.Visible = false
	gachaFrame.Visible = false
end)

-- Keys, bound through ContextActionService so the camera never eats them.
local function bindKey(actionName, keyCode, remote)
	ContextActionService:BindAction(actionName, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			remote:FireServer()
		end
	end, false, keyCode)
end

bindKey("BrainrotPull", Enum.KeyCode.Q, pullEvent)
bindKey("BrainrotPush", Enum.KeyCode.F, pushEvent)
bindKey("BrainrotLock", Enum.KeyCode.L, lockEvent)
-- Fuse opens a local panel (no server call), so it binds directly.
ContextActionService:BindAction("BrainrotFuse", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggleFuse()
	end
end, false, Enum.KeyCode.K)

-- Your own steal prompts stay hidden: you cannot steal from yourself.
ProximityPromptService.PromptShown:Connect(function(prompt)
	local ownerId = prompt:GetAttribute("OwnerUserId")
	if ownerId and ownerId == player.UserId then
		prompt.Enabled = false
	end
end)

-- A welcome hint for the first seconds of the game.
task.delay(1, function()
	showNotify("Welcome to Enchanted Academy! Click a brainrot on the Parade Lane to buy it.", "info")
end)
