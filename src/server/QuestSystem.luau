-- QuestSystem: four story chapters (each step counts from when it starts)
-- and a three-slot Bonus Board that refills with harder quests. Events come
-- in from every system through QuestSystem.OnEvent(state, key, amount); the
-- Hud gets a ready-to-draw view inside StateUpdate.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local QuestCatalog = require(Shared.QuestCatalog)

local QuestSystem = {}

local G

function QuestSystem.Setup(state)
	local bonus = {}
	for slot = 1, QuestCatalog.BONUS_SLOTS do
		bonus[slot] = { poolIndex = slot, progress = 0 }
	end
	state.quest = {
		chapter = 1,
		step = 1,
		progress = 0,
		bonus = bonus,
		nextPool = QuestCatalog.BONUS_SLOTS + 1,
	}
	QuestSystem.SyncCounters(state)
end

local function currentStep(quest)
	local chapter = QuestCatalog.CHAPTERS[quest.chapter]
	return chapter and chapter.steps[quest.step] or nil, chapter
end

-- Counters that are a level, not an event, read straight from state.
function QuestSystem.SyncCounters(state)
	local quest = state.quest
	local step = quest and currentStep(quest)
	if step and step.key == "ownedCount" then
		quest.progress = state.ownedCount
		QuestSystem.CheckChapter(state)
	end
end

local function reward(state, amount, title)
	G.Economy.AddCash(state, amount, "quest")
	G.notify(state, "Quest done: " .. title .. "  +" .. Config.FormatMoney(amount), Color3.fromRGB(255, 220, 90))
	G.fx("sound", "quest", nil, state)
end

function QuestSystem.CheckChapter(state)
	local quest = state.quest
	local step, chapter = currentStep(quest)
	while step and quest.progress >= step.target do
		reward(state, step.reward, step.text)
		quest.step += 1
		quest.progress = 0
		if quest.step > #chapter.steps then
			state.chaptersDone += 1
			G.banner("CHAPTER COMPLETE: " .. string.upper(chapter.title) .. " · +5% INCOME FOREVER", Color3.fromRGB(255, 190, 40), 5, state)
			quest.chapter += 1
			quest.step = 1
		end
		step, chapter = currentStep(quest)
		if step and step.key == "ownedCount" then
			quest.progress = state.ownedCount
		end
	end
end

function QuestSystem.OnEvent(state, key, amount)
	if not state or state.isBot or not state.quest then
		return
	end
	local quest = state.quest
	local step = currentStep(quest)
	if step and step.key == key then
		quest.progress += amount
		QuestSystem.CheckChapter(state)
	end
	for slot, entry in ipairs(quest.bonus) do
		local definition = QuestCatalog.GetBonusQuest(entry.poolIndex)
		if definition.key == key then
			entry.progress += amount
			if entry.progress >= definition.target then
				reward(state, definition.reward, definition.text)
				quest.bonus[slot] = { poolIndex = quest.nextPool, progress = 0 }
				quest.nextPool += 1
			end
		end
	end
	QuestSystem.SyncCounters(state)
	G.State.Changed(state)
end

-- What the Hud draws: the live chapter step and the three bonus quests.
function QuestSystem.View(state)
	local quest = state.quest
	if not quest then
		return nil
	end
	local step, chapter = currentStep(quest)
	local view = {
		chapterIndex = quest.chapter,
		chapterCount = #QuestCatalog.CHAPTERS,
		chaptersDone = state.chaptersDone,
		bonus = {},
	}
	if step then
		view.chapterTitle = chapter.title
		view.stepIndex = quest.step
		view.stepCount = #chapter.steps
		view.text = step.text
		view.progress = math.min(quest.progress, step.target)
		view.target = step.target
		view.reward = step.reward
	else
		view.chapterTitle = "Graduated!"
		view.text = "All chapters done. Bonus Board keeps going."
		view.done = true
	end
	for _, entry in ipairs(quest.bonus) do
		local definition = QuestCatalog.GetBonusQuest(entry.poolIndex)
		table.insert(view.bonus, {
			text = definition.text,
			progress = math.min(entry.progress, definition.target),
			target = definition.target,
			reward = definition.reward,
		})
	end
	return view
end

function QuestSystem.Init(context)
	G = context
end

return QuestSystem
