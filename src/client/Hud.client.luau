-- Hud: the student's screen. Centered cash and $/s with the spec strip
-- under it, a full-width event banner, the quest card on the right, the
-- classroom card on the left, the bottom action bar (PULL Q, PUSH F, LOCK L,
-- SHOP U, REBIRTH R, QUESTS J, FUSE K, INDEX B) with cooldowns, the CARRYING ->
-- RETURN TO BASE bar, toasts, the target highlight for PULL/PUSH, and the
-- Shop, Quest, Rebirth, Gacha, Fuse and Report Card panels. Scales with the
-- screen; nothing sits under the Roblox menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local QuestCatalog = require(Shared.QuestCatalog)
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local state = nil -- latest StateUpdate payload

local DARK = Color3.fromRGB(24, 22, 40)
local PANEL = Color3.fromRGB(38, 34, 64)
local GOLD = Color3.fromRGB(255, 205, 70)
local WHITE = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(190, 185, 215)
local GREEN = Color3.fromRGB(110, 230, 130)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

---------------------------------------------------------------------------
-- UI helpers.
---------------------------------------------------------------------------
local function new(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function round(target, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, target)
end

local function stroke(target, color, thickness)
	return new("UIStroke", { Color = color or WHITE, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, target)
end

local function card(parent, name, size, position, anchor, color)
	local frame = new("Frame", {
		Name = name,
		Size = size,
		Position = position,
		AnchorPoint = anchor or Vector2.new(0, 0),
		BackgroundColor3 = color or DARK,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
	}, parent)
	round(frame, 14)
	return frame
end

local function label(parent, name, text, size, position, color, font, align)
	return new("TextLabel", {
		Name = name,
		Text = text,
		Size = size,
		Position = position,
		BackgroundTransparency = 1,
		TextColor3 = color or WHITE,
		Font = font or Enum.Font.FredokaOne,
		TextScaled = true,
		TextXAlignment = align or Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.6,
		TextStrokeColor3 = DARK,
	}, parent)
end

local function button(parent, name, text, size, position, color)
	local b = new("TextButton", {
		Name = name,
		Text = text,
		Size = size,
		Position = position,
		BackgroundColor3 = color or GREEN,
		TextColor3 = WHITE,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		AutoButtonColor = true,
		BorderSizePixel = 0,
	}, parent)
	round(b, 10)
	stroke(b, DARK, 2)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, b)
	return b
end

local function progressBar(parent, name, size, position, color)
	local back = new("Frame", { Name = name, Size = size, Position = position, BackgroundColor3 = Color3.fromRGB(15, 14, 26), BorderSizePixel = 0 }, parent)
	round(back, 6)
	local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = color or GOLD, BorderSizePixel = 0 }, back)
	round(fill, 6)
	return back, fill
end

local function now()
	return Workspace:GetServerTimeNow()
end

---------------------------------------------------------------------------
-- Screen and scale.
---------------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "Hud", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))
local uiScale = new("UIScale", {}, gui)
local function rescale()
	local size = Workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.55, 1.25)
end
rescale()
Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

---------------------------------------------------------------------------
-- Top centre: cash and income.
---------------------------------------------------------------------------
local cashCard = card(gui, "CashPanel", UDim2.fromOffset(330, 84), UDim2.new(0.5, 0, 0, 6), Vector2.new(0.5, 0))
stroke(cashCard, GOLD, 3)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(70, 50, 120), Color3.fromRGB(30, 26, 52)), Rotation = 90 }, cashCard)
local cashLabel = label(cashCard, "Cash", "$0", UDim2.new(1, -20, 0, 50), UDim2.fromOffset(10, 4), GOLD)
local incomeLabel = label(cashCard, "Income", "+$0/s", UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 54), GREEN)

---------------------------------------------------------------------------
-- Spec strip: one thin line under the cash bar, naming the whole game.
---------------------------------------------------------------------------
local specStrip = card(gui, "SpecStrip", UDim2.fromOffset(700, 22), UDim2.new(0.5, 0, 0, 92), Vector2.new(0.5, 0))
specStrip.BackgroundTransparency = 0.35
specStrip.ZIndex = 5
local specText = label(specStrip, "Spec", "80 BRAINROTS  ·  16 TIERS  ·  5 MUTATIONS  ·  PULL  ·  PUSH  ·  STEAL  ·  LOCK  ·  REBIRTH  ·  GACHA  ·  FUSE", UDim2.new(1, -16, 1, -4), UDim2.fromOffset(8, 2), WHITE, Enum.Font.GothamBold)
specText.ZIndex = 5

---------------------------------------------------------------------------
-- Event banner: full width, under the spec strip (y 120, the strip ends
-- at y 114, so the two never overlap).
---------------------------------------------------------------------------
local banner = new("Frame", { Name = "EventBanner", Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 120), BackgroundColor3 = Color3.fromRGB(230, 60, 70), BorderSizePixel = 0, Visible = false }, gui)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.85, 0.1), NumberSequenceKeypoint.new(1, 1) }) }, banner)
local bannerText = label(banner, "Text", "", UDim2.new(0.8, 0, 0.8, 0), UDim2.fromScale(0.1, 0.1), WHITE)
bannerText.TextStrokeTransparency = 0
local bannerToken = 0

local function showBanner(text, color, seconds)
	bannerToken += 1
	local token = bannerToken
	banner.BackgroundColor3 = color or Color3.fromRGB(230, 60, 70)
	bannerText.Text = text
	banner.Visible = true
	task.delay(seconds or 3, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

---------------------------------------------------------------------------
-- Toasts: short messages under the banner.
---------------------------------------------------------------------------
local toastHolder = new("Frame", { Name = "Toasts", Size = UDim2.fromOffset(460, 160), Position = UDim2.new(0.5, 0, 0, 170), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1 }, gui)
new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)
local toastOrder = 0

local function toast(text, color)
	toastOrder += 1
	local children = {}
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(children, child)
		end
	end
	if #children >= 3 then
		children[1]:Destroy()
	end
	local frame = card(toastHolder, "Toast", UDim2.fromOffset(440, 36), UDim2.new(), nil, DARK)
	frame.LayoutOrder = toastOrder
	stroke(frame, color or WHITE, 2)
	local text_ = label(frame, "Text", text, UDim2.new(1, -16, 1, -8), UDim2.fromOffset(8, 4), color or WHITE)
	task.delay(3.2, function()
		if frame.Parent then
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(text_, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.wait(0.45)
			frame:Destroy()
		end
	end)
end

---------------------------------------------------------------------------
-- Right: quest card, below the event banner so the two never overlap.
---------------------------------------------------------------------------
local questCard = card(gui, "QuestCard", UDim2.fromOffset(280, 212), UDim2.new(1, -10, 0, 170), Vector2.new(1, 0))
stroke(questCard, GOLD, 2)
local questHeader = label(questCard, "Header", "QUESTS", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 6), GOLD, Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
local questText = label(questCard, "Step", "", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 34), WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
local _, questFill = progressBar(questCard, "StepBar", UDim2.new(1, -20, 0, 14), UDim2.fromOffset(10, 62), GOLD)
local questCount = label(questCard, "Count", "", UDim2.new(1, -20, 0, 16), UDim2.fromOffset(10, 78), MUTED, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
label(questCard, "BonusTitle", "BONUS BOARD", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 100), Color3.fromRGB(170, 140, 255), Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
local bonusRows = {}
for i = 1, QuestCatalog.BONUS_SLOTS do
	local y = 120 + (i - 1) * 28
	local row = label(questCard, "Bonus" .. i, "", UDim2.new(1, -20, 0, 16), UDim2.fromOffset(10, y), WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
	local _, fill = progressBar(questCard, "BonusBar" .. i, UDim2.new(1, -20, 0, 6), UDim2.fromOffset(10, y + 18), Color3.fromRGB(170, 140, 255))
	bonusRows[i] = { row = row, fill = fill }
end
label(questCard, "Hint", "[J] all quests", UDim2.new(1, -20, 0, 12), UDim2.fromOffset(10, 196), MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Right)

---------------------------------------------------------------------------
-- Left: classroom card (below the Roblox menu buttons).
---------------------------------------------------------------------------
local baseCard = card(gui, "ClassroomCard", UDim2.fromOffset(240, 158), UDim2.new(0, 10, 0.5, -40), Vector2.new(0, 0.5))
-- More see-through than the other cards on purpose: the parade lane runs
-- behind this corner of the screen, and a nearly-opaque panel hides the
-- brainrot plates walking past it. At 0.3 the plate text stays readable
-- through the panel while the card's own text keeps its contrast.
baseCard.BackgroundTransparency = 0.3
stroke(baseCard, Color3.fromRGB(120, 200, 255), 2)
local baseTitle = label(baseCard, "Title", "CLASSROOM", UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 6), Color3.fromRGB(120, 200, 255), Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
local baseLines = {}
for i, name in ipairs({ "Slots", "Index", "Multiplier", "Lock", "Buff" }) do
	baseLines[name] = label(baseCard, name, "", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 34 + (i - 1) * 24), WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
end

---------------------------------------------------------------------------
-- Bottom: carrying bar and the action bar.
---------------------------------------------------------------------------
local carryBar = card(gui, "CarryingBar", UDim2.fromOffset(560, 46), UDim2.new(0.5, 0, 1, -118), Vector2.new(0.5, 1), Color3.fromRGB(255, 190, 40))
carryBar.BackgroundTransparency = 0
carryBar.Visible = false
stroke(carryBar, DARK, 3)
local carryText = label(carryBar, "Text", "", UDim2.new(1, -20, 1, -10), UDim2.fromOffset(10, 5), DARK)
carryText.TextStrokeTransparency = 1

local actionBar = new("Frame", { Name = "ActionBar", Size = UDim2.fromOffset(736, 96), Position = UDim2.new(0.5, 0, 1, -10), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1 }, gui)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, actionBar)

local actionButtons = {}
local function actionButton(order, id, title, key, color)
	local b = new("TextButton", { Name = id, Text = "", Size = UDim2.fromOffset(84, 92), BackgroundColor3 = color, AutoButtonColor = true, BorderSizePixel = 0, LayoutOrder = order }, actionBar)
	round(b, 14)
	stroke(b, DARK, 3)
	new("UIGradient", { Color = ColorSequence.new(WHITE, Color3.fromRGB(190, 190, 190)), Rotation = 90 }, b)
	label(b, "Title", title, UDim2.new(1, -8, 0, 30), UDim2.new(0, 4, 0.5, -6), WHITE)
	local badge = new("Frame", { Name = "KeyBadge", Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(-6, -6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, b)
	round(badge, 15)
	stroke(badge, DARK, 2)
	local keyLabel = label(badge, "Key", key, UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1), DARK)
	keyLabel.ZIndex = 3
	keyLabel.TextStrokeTransparency = 1
	local cooldown = new("Frame", { Name = "Cooldown", Size = UDim2.fromScale(1, 0), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = DARK, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2 }, b)
	round(cooldown, 14)
	local cooldownText = label(b, "CooldownText", "", UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0.5, -17), WHITE)
	cooldownText.ZIndex = 4
	actionButtons[id] = { button = b, cooldown = cooldown, cooldownText = cooldownText }
	return b
end

---------------------------------------------------------------------------
-- Panels (one open at a time).
---------------------------------------------------------------------------
local panel = card(gui, "Panel", UDim2.fromOffset(600, 420), UDim2.fromScale(0.5, 0.52), Vector2.new(0.5, 0.5), PANEL)
panel.BackgroundTransparency = 0.03
panel.Visible = false
panel.ZIndex = 10
stroke(panel, GOLD, 3)
local panelTitle = label(panel, "Title", "", UDim2.new(1, -90, 0, 40), UDim2.fromOffset(20, 10), GOLD, Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
local closeButton = button(panel, "Close", "X", UDim2.fromOffset(44, 40), UDim2.new(1, -56, 0, 10), Color3.fromRGB(230, 80, 90))
local panelBody = new("ScrollingFrame", { Name = "Body", Size = UDim2.new(1, -30, 1, -70), Position = UDim2.fromOffset(15, 58), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, panel)
local openPanel = nil
local panelExtra = nil

local function clearBody()
	for _, child in ipairs(panelBody:GetChildren()) do
		child:Destroy()
	end
end

local function rowList(gap)
	new("UIListLayout", { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder }, panelBody)
end

local function row(order, height)
	local r = new("Frame", { Name = "Row", Size = UDim2.new(1, -10, 0, height or 56), BackgroundColor3 = DARK, BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = order }, panelBody)
	round(r, 10)
	return r
end

local PANELS = {}

PANELS.upgrades = function()
	panelTitle.Text = "UPGRADE SHOP"
	rowList()
	for i, id in ipairs(Config.UPGRADE_ORDER) do
		local upgrade = Config.UPGRADES[id]
		local level = state and state.upgrades[id] or 0
		local cost = Config.NextUpgradeCost(id, level)
		local r = row(i, 60)
		label(r, "Name", upgrade.name .. "  ·  Lv " .. level .. "/" .. #upgrade.costs, UDim2.new(0.62, 0, 0, 28), UDim2.fromOffset(12, 4), WHITE, Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
		label(r, "Desc", upgrade.desc, UDim2.new(0.62, 0, 0, 20), UDim2.fromOffset(12, 34), MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Left)
		local affordable = cost and state and state.cash >= cost
		local b = button(r, "Buy", cost and ("BUY " .. Config.FormatMoney(cost)) or "MAX", UDim2.new(0.3, 0, 0, 40), UDim2.new(0.68, 0, 0, 10), cost and (affordable and GREEN or Color3.fromRGB(110, 105, 130)) or Color3.fromRGB(90, 90, 110))
		b.MouseButton1Click:Connect(function()
			if cost then
				remotes.BuyUpgrade:FireServer(id)
			end
		end)
	end
end

PANELS.quests = function()
	panelTitle.Text = "QUESTS · 4 CHAPTERS + BONUS BOARD"
	rowList(6)
	local view = state and state.quest
	local order = 0
	for chapterIndex, chapter in ipairs(QuestCatalog.CHAPTERS) do
		order += 1
		local done = view and chapterIndex < view.chapterIndex
		local current = view and chapterIndex == view.chapterIndex
		local header = row(order, 30)
		header.BackgroundColor3 = done and Color3.fromRGB(40, 90, 60) or (current and Color3.fromRGB(90, 70, 30) or DARK)
		label(header, "Title", "CHAPTER " .. chapterIndex .. ": " .. string.upper(chapter.title) .. (done and "  ✓" or ""), UDim2.new(1, -20, 1, -6), UDim2.fromOffset(10, 3), done and GREEN or GOLD, Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
		for stepIndex, step in ipairs(chapter.steps) do
			order += 1
			local r = row(order, 26)
			local status
			if done or (current and stepIndex < view.stepIndex) then
				status = "✓"
			elseif current and stepIndex == view.stepIndex then
				status = view.progress .. "/" .. view.target
			else
				status = "·"
			end
			label(r, "Step", step.text, UDim2.new(0.7, 0, 1, -6), UDim2.fromOffset(14, 3), WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
			label(r, "Status", status .. "   +" .. Config.FormatMoney(step.reward), UDim2.new(0.28, 0, 1, -6), UDim2.new(0.7, 0, 0, 3), MUTED, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
		end
	end
	if view then
		order += 1
		local header = row(order, 30)
		label(header, "Title", "BONUS BOARD (refills, gets harder)", UDim2.new(1, -20, 1, -6), UDim2.fromOffset(10, 3), Color3.fromRGB(170, 140, 255), Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
		for _, bonus in ipairs(view.bonus) do
			order += 1
			local r = row(order, 26)
			label(r, "Step", bonus.text, UDim2.new(0.7, 0, 1, -6), UDim2.fromOffset(14, 3), WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
			label(r, "Status", bonus.progress .. "/" .. bonus.target .. "   +" .. Config.FormatMoney(bonus.reward), UDim2.new(0.28, 0, 1, -6), UDim2.new(0.7, 0, 0, 3), MUTED, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
		end
	end
end

PANELS.rebirth = function()
	panelTitle.Text = "REBIRTH ALTAR"
	rowList(10)
	local cost = state and state.rebirthCost or Config.REBIRTH_BASE_COST
	local rebirths = state and state.rebirths or 0
	local info = row(1, 150)
	label(info, "Now", "Rebirths: " .. rebirths .. "   ·   Income x" .. string.format("%.1f", 1 + 0.5 * rebirths) .. "  →  x" .. string.format("%.1f", 1 + 0.5 * (rebirths + 1)), UDim2.new(1, -20, 0, 34), UDim2.fromOffset(10, 10), GOLD, Enum.Font.FredokaOne)
	label(info, "Cost", "Cost: " .. Config.FormatMoney(cost), UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 52), WHITE, Enum.Font.FredokaOne)
	label(info, "Warn", "Your cash and upgrades reset (Extra Slots stay). Every brainrot stays in your classroom.", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 92), MUTED, Enum.Font.GothamBold)
	local r = row(2, 64)
	r.BackgroundTransparency = 1
	local affordable = state and state.cash >= cost
	local b = button(r, "Confirm", affordable and "CONFIRM REBIRTH" or ("NEED " .. Config.FormatMoney(cost - (state and state.cash or 0)) .. " MORE"), UDim2.new(0.6, 0, 0, 54), UDim2.new(0.2, 0, 0, 5), affordable and Color3.fromRGB(230, 90, 200) or Color3.fromRGB(110, 105, 130))
	b.MouseButton1Click:Connect(function()
		if affordable then
			remotes.DoRebirth:FireServer()
		end
	end)
end

PANELS.gacha = function()
	panelTitle.Text = "GACHA MACHINE · " .. Config.FormatMoney(Config.GACHA_COST) .. " A ROLL"
	rowList(10)
	local result = row(1, 150)
	if panelExtra then
		local color = Config.RARITY_COLORS[panelExtra.rarity] or WHITE
		stroke(result, color, 3)
		label(result, "Name", panelExtra.name, UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 8), color, Enum.Font.FredokaOne)
		label(result, "Tier", string.upper((panelExtra.mutation and panelExtra.mutation .. " " or "") .. panelExtra.rarity) .. "  ·  " .. Config.FormatMoney(panelExtra.income) .. "/s", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 56), WHITE, Enum.Font.FredokaOne)
		label(result, "Blurb", "\"" .. (panelExtra.blurb or "") .. "\"  ·  sent to your classroom", UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 104), MUTED, Enum.Font.GothamBold)
	else
		label(result, "Hint", "Kinder odds than the Parade. The prize goes straight onto a free pedestal. Lucky Charm helps.", UDim2.new(1, -20, 0, 80), UDim2.fromOffset(10, 35), MUTED, Enum.Font.GothamBold)
	end
	local r = row(2, 64)
	r.BackgroundTransparency = 1
	local b = button(r, "Roll", "ROLL  " .. Config.FormatMoney(Config.GACHA_COST), UDim2.new(0.5, 0, 0, 54), UDim2.new(0.25, 0, 0, 5), Color3.fromRGB(230, 70, 80))
	b.MouseButton1Click:Connect(function()
		remotes.RollGacha:FireServer()
	end)
end

PANELS.fuse = function()
	panelTitle.Text = "FUSE LAB · 3 OF A TIER = 1 OF THE NEXT"
	rowList(6)
	local any = false
	for i, rarity in ipairs(Config.RARITY_ORDER) do
		local count = state and state.tierCounts[rarity] or 0
		local nextTier = Catalog.NextTier(rarity)
		if count > 0 and nextTier then
			any = true
			local r = row(i, 44)
			local color = Config.RARITY_COLORS[rarity]
			label(r, "Tier", rarity .. "  x" .. count .. "  →  " .. nextTier, UDim2.new(0.6, 0, 1, -10), UDim2.fromOffset(12, 5), color, Enum.Font.FredokaOne, Enum.TextXAlignment.Left)
			local b = button(r, "Fuse", count >= 3 and "FUSE 3" or "NEED 3", UDim2.new(0.3, 0, 1, -10), UDim2.new(0.68, 0, 0, 5), count >= 3 and Color3.fromRGB(90, 190, 255) or Color3.fromRGB(110, 105, 130))
			b.MouseButton1Click:Connect(function()
				if count >= 3 then
					remotes.FuseBrainrots:FireServer(rarity)
				end
			end)
		end
	end
	if not any then
		local r = row(1, 60)
		label(r, "Empty", "Place brainrots in your classroom first.", UDim2.new(1, -20, 1, -16), UDim2.fromOffset(10, 8), MUTED, Enum.Font.GothamBold)
	end
end

PANELS.index = function()
	local ownedSet = {}
	for _, id in ipairs(state and state.owned or {}) do
		ownedSet[id] = true
	end
	panelTitle.Text = "REPORT CARD · " .. (state and state.ownedCount or 0) .. "/" .. Catalog.Count .. "  (+2% income each)"
	new("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0, 64), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, panelBody)
	for i, entry in ipairs(Catalog.Entries) do
		local owned = ownedSet[entry.id]
		local color = Config.RARITY_COLORS[entry.rarity]
		local cell = new("Frame", { Name = entry.id, BackgroundColor3 = owned and DARK or Color3.fromRGB(28, 26, 40), BorderSizePixel = 0, LayoutOrder = i }, panelBody)
		round(cell, 10)
		stroke(cell, owned and color or Color3.fromRGB(70, 66, 90), 2)
		label(cell, "Name", owned and entry.name or "???", UDim2.new(1, -10, 0, 26), UDim2.fromOffset(5, 6), owned and WHITE or MUTED, Enum.Font.FredokaOne)
		label(cell, "Tier", entry.rarity .. " · " .. Config.FormatMoney(entry.income) .. "/s", UDim2.new(1, -10, 0, 20), UDim2.fromOffset(5, 36), color, Enum.Font.GothamBold)
	end
end

local function showPanel(name, extra)
	if extra ~= nil then
		panelExtra = extra
	end
	if openPanel == name and extra == nil then
		openPanel = nil
		panel.Visible = false
		return
	end
	openPanel = name
	clearBody()
	PANELS[name]()
	panel.Visible = true
end

local function refreshPanel()
	if openPanel then
		clearBody()
		PANELS[openPanel]()
	end
end

closeButton.MouseButton1Click:Connect(function()
	openPanel = nil
	panel.Visible = false
end)

---------------------------------------------------------------------------
-- PULL / PUSH targeting: nearest student or rival, highlighted.
---------------------------------------------------------------------------
local highlight = new("Highlight", { Name = "TargetHighlight", FillTransparency = 0.7, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, gui)
local targetTag = new("BillboardGui", { Name = "TargetTag", Size = UDim2.fromOffset(170, 34), StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0), AlwaysOnTop = true, Enabled = false }, gui)
local targetTagText = label(targetTag, "Text", "", UDim2.fromScale(1, 1), UDim2.new(), WHITE)
targetTagText.TextStrokeTransparency = 0
local currentTarget = nil

local function myRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function candidates()
	local list = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
			local humanoid = other.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				table.insert(list, { model = other.Character, root = other.Character.HumanoidRootPart })
			end
		end
	end
	for _, model in ipairs(CollectionService:GetTagged("RivalStudent")) do
		local root = model:FindFirstChild("Root")
		if root then
			table.insert(list, { model = model, root = root })
		end
	end
	return list
end

local function updateTarget()
	local root = myRoot()
	local best, bestDistance = nil, Config.PULL_RANGE
	if root then
		for _, candidate in ipairs(candidates()) do
			local distance = (candidate.root.Position - root.Position).Magnitude
			if distance <= bestDistance then
				best, bestDistance = candidate, distance
			end
		end
	end
	currentTarget = best and best.model or nil
	if best then
		local inPush = bestDistance <= Config.PUSH_RANGE
		highlight.Adornee = best.model
		highlight.FillColor = inPush and Color3.fromRGB(90, 190, 255) or Color3.fromRGB(255, 170, 60)
		highlight.OutlineColor = highlight.FillColor
		highlight.Enabled = true
		targetTag.Adornee = best.root
		targetTag.Enabled = true
		targetTagText.Text = inPush and "[Q] PULL · [F] PUSH" or "[Q] PULL"
		targetTagText.TextColor3 = highlight.FillColor
	else
		highlight.Enabled = false
		targetTag.Enabled = false
	end
end

---------------------------------------------------------------------------
-- Actions: keyboard and gamepad via ContextActionService, taps on the bar.
---------------------------------------------------------------------------
local ACTIONS = {
	pull = function()
		remotes.PullPlayer:FireServer(currentTarget)
	end,
	push = function()
		remotes.PushPlayer:FireServer(currentTarget)
	end,
	lock = function()
		remotes.ToggleLock:FireServer()
	end,
	shop = function()
		showPanel("upgrades")
	end,
	rebirth = function()
		showPanel("rebirth")
	end,
	quests = function()
		showPanel("quests")
	end,
	fuse = function()
		showPanel("fuse")
	end,
	index = function()
		showPanel("index")
	end,
}

local BAR = {
	{ "pull", "PULL", "Q", Color3.fromRGB(255, 150, 50), { Enum.KeyCode.Q, Enum.KeyCode.ButtonL1 } },
	{ "push", "PUSH", "F", Color3.fromRGB(70, 160, 255), { Enum.KeyCode.F, Enum.KeyCode.ButtonR1 } },
	{ "lock", "LOCK", "L", Color3.fromRGB(80, 200, 220), { Enum.KeyCode.L, Enum.KeyCode.ButtonY } },
	{ "shop", "SHOP", "U", Color3.fromRGB(90, 200, 110), { Enum.KeyCode.U } },
	{ "rebirth", "REBIRTH", "R", Color3.fromRGB(230, 90, 200), { Enum.KeyCode.R } },
	{ "quests", "QUESTS", "J", Color3.fromRGB(240, 180, 40), { Enum.KeyCode.J } },
	{ "fuse", "FUSE", "K", Color3.fromRGB(255, 90, 120), { Enum.KeyCode.K } },
	{ "index", "INDEX", "B", Color3.fromRGB(150, 110, 255), { Enum.KeyCode.B } },
}

for order, spec in ipairs(BAR) do
	local id = spec[1]
	local b = actionButton(order, id, spec[2], spec[3], spec[4])
	b.Activated:Connect(ACTIONS[id])
	ContextActionService:BindAction("Hud_" .. id, function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			ACTIONS[id]()
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(spec[5]))
end

local function setCooldown(id, readyAt, total)
	local entry = actionButtons[id]
	local left = (readyAt or 0) - now()
	if left > 0 then
		entry.cooldown.Size = UDim2.fromScale(1, math.clamp(left / total, 0, 1))
		entry.cooldownText.Text = tostring(math.ceil(left))
	else
		entry.cooldown.Size = UDim2.fromScale(1, 0)
		entry.cooldownText.Text = ""
	end
end

---------------------------------------------------------------------------
-- Drawing the state.
---------------------------------------------------------------------------
local function drawQuest(view)
	if not view then
		return
	end
	if view.done then
		questHeader.Text = "GRADUATED! ★ " .. view.chaptersDone .. "/" .. view.chapterCount
		questText.Text = view.text
		questFill.Size = UDim2.fromScale(1, 1)
		questCount.Text = "Bonus Board keeps going"
	else
		questHeader.Text = "CH " .. view.chapterIndex .. "/" .. view.chapterCount .. " · " .. string.upper(view.chapterTitle) .. " · " .. view.stepIndex .. "/" .. view.stepCount
		questText.Text = view.text
		questFill.Size = UDim2.fromScale(math.clamp(view.progress / view.target, 0, 1), 1)
		questCount.Text = Config.FormatMoney(view.progress):gsub("%$", "") .. " / " .. Config.FormatMoney(view.target):gsub("%$", "") .. "   ·   reward +" .. Config.FormatMoney(view.reward)
	end
	for i, rowInfo in ipairs(bonusRows) do
		local bonus = view.bonus[i]
		if bonus then
			rowInfo.row.Text = bonus.text .. "  " .. bonus.progress .. "/" .. bonus.target
			rowInfo.fill.Size = UDim2.fromScale(math.clamp(bonus.progress / bonus.target, 0, 1), 1)
		end
	end
end

local function drawTimers()
	if not state then
		return
	end
	local t = now()
	setCooldown("pull", state.pullReadyAt, Config.PULL_COOLDOWN)
	setCooldown("push", state.pushReadyAt, Config.PUSH_COOLDOWN)
	local lockEntry = actionButtons.lock
	if state.lockEndsAt > t then
		baseLines.Lock.Text = "LOCKED  " .. math.ceil(state.lockEndsAt - t) .. "s"
		baseLines.Lock.TextColor3 = Color3.fromRGB(120, 200, 255)
		lockEntry.cooldown.Size = UDim2.fromScale(1, 0)
		lockEntry.cooldownText.Text = math.ceil(state.lockEndsAt - t) .. "s"
	elseif state.lockReadyAt > t then
		baseLines.Lock.Text = "Lock recharging  " .. math.ceil(state.lockReadyAt - t) .. "s"
		baseLines.Lock.TextColor3 = Color3.fromRGB(255, 180, 90)
		setCooldown("lock", state.lockReadyAt, Config.LOCK_RECHARGE)
	else
		baseLines.Lock.Text = "OPEN · press [L] to lock"
		baseLines.Lock.TextColor3 = Color3.fromRGB(255, 130, 130)
		setCooldown("lock", 0, 1)
	end
	if state.buffUntil > t then
		baseLines.Buff.Text = "FRESH +10%  " .. math.ceil(state.buffUntil - t) .. "s"
		baseLines.Buff.TextColor3 = Color3.fromRGB(120, 230, 255)
	else
		baseLines.Buff.Text = "Sit on a bench/swing: +10%"
		baseLines.Buff.TextColor3 = MUTED
	end
	-- Carrying bar with the distance home.
	if #state.carrying > 0 then
		local names = {}
		for _, carried in ipairs(state.carrying) do
			table.insert(names, carried.name)
		end
		local root = myRoot()
		local distance = (root and state.baseCenter) and math.floor((root.Position - state.baseCenter).Magnitude) or 0
		carryText.Text = "CARRYING " .. table.concat(names, " + ") .. "  →  RETURN TO BASE · " .. distance .. "m"
		carryBar.Visible = true
	else
		carryBar.Visible = false
	end
end

local function drawState()
	if not state then
		return
	end
	cashLabel.Text = Config.FormatMoney(state.cash)
	incomeLabel.Text = "+" .. Config.FormatMoney(state.income) .. "/s   ·   x" .. string.format("%.2f", state.multiplier)
	baseTitle.Text = state.baseIndex and ("CLASSROOM " .. state.baseIndex) or "NO CLASSROOM"
	baseLines.Slots.Text = "Pedestals  " .. state.placedCount .. "/" .. state.slotCount .. "   ·   Hands " .. #state.carrying .. "/" .. state.capacity
	baseLines.Index.Text = "Report Card  " .. state.ownedCount .. "/" .. state.catalogCount
	baseLines.Multiplier.Text = "Rebirths " .. state.rebirths .. "   ·   Income x" .. string.format("%.2f", state.multiplier)
	drawQuest(state.quest)
	drawTimers()
end

---------------------------------------------------------------------------
-- Home marker: a big "YOUR CLASS" sign over your base, bigger while carrying.
---------------------------------------------------------------------------
local homeAnchor = new("Part", { Name = "HomeMarker", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(1, 1, 1) }, Workspace)
local homeGui = new("BillboardGui", { Size = UDim2.fromOffset(180, 50), AlwaysOnTop = true, StudsOffsetWorldSpace = Vector3.new(0, 16, 0), Enabled = false }, homeAnchor)
local homeText = label(homeGui, "Text", "▼ YOUR CLASS", UDim2.fromScale(1, 1), UDim2.new(), GOLD)
homeText.TextStrokeTransparency = 0

---------------------------------------------------------------------------
-- Title splash: the game's name and how to play, for the first seconds.
---------------------------------------------------------------------------
local splash = new("Frame", { Name = "TitleSplash", Size = UDim2.fromOffset(720, 230), Position = UDim2.fromScale(0.5, 0.42), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = DARK, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 20 }, gui)
round(splash, 20)
stroke(splash, GOLD, 4)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(90, 60, 160), Color3.fromRGB(30, 26, 52)), Rotation = 90 }, splash)
local splashTitle = label(splash, "Title", Config.GAME_TITLE, UDim2.new(1, -40, 0, 90), UDim2.fromOffset(20, 14), GOLD)
splashTitle.TextStrokeTransparency = 0
splashTitle.ZIndex = 21
local splashSub = label(splash, "Subtitle", Config.GAME_SUBTITLE, UDim2.new(1, -40, 0, 40), UDim2.fromOffset(20, 104), Color3.fromRGB(200, 170, 255))
splashSub.ZIndex = 21
local splashTips = label(splash, "Tips", "Buy on the Parade · carry it home · Press [E] to Steal · [Q] Pull · [F] Push · [L] Lock", UDim2.new(1, -40, 0, 30), UDim2.fromOffset(20, 168), WHITE, Enum.Font.GothamBold)
splashTips.ZIndex = 21
task.delay(6, function()
	for _, object in ipairs(splash:GetDescendants()) do
		if object:IsA("TextLabel") then
			TweenService:Create(object, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif object:IsA("UIStroke") then
			TweenService:Create(object, TweenInfo.new(0.6), { Transparency = 1 }):Play()
		end
	end
	TweenService:Create(splash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	task.wait(0.7)
	splash:Destroy()
end)

---------------------------------------------------------------------------
-- Remotes.
---------------------------------------------------------------------------
local lastPanelRefresh = 0
remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(payload)
	state = payload
	drawState()
	if state.baseCenter then
		homeAnchor.CFrame = CFrame.new(state.baseCenter)
		homeGui.Enabled = true
		homeGui.Size = #state.carrying > 0 and UDim2.fromOffset(260, 70) or UDim2.fromOffset(160, 44)
	end
	if openPanel and os.clock() - lastPanelRefresh > 0.9 then
		lastPanelRefresh = os.clock()
		refreshPanel()
	end
end)

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text, color)
	toast(text, color)
end)

remotes:WaitForChild("EventBanner").OnClientEvent:Connect(function(text, color, seconds)
	showBanner(text, color, seconds)
end)

remotes:WaitForChild("OpenPanel").OnClientEvent:Connect(function(name, extra)
	if name == "gachaResult" then
		showPanel("gacha", extra)
	elseif PANELS[name] then
		if name == "gacha" then
			panelExtra = nil
		end
		openPanel = nil
		showPanel(name)
	end
end)

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
	accumulator += dt
	if accumulator >= 0.1 then
		accumulator = 0
		updateTarget()
		drawTimers()
	end
end)
