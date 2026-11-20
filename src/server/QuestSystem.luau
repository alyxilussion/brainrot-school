-- QuestSystem: chapters and daily quests. Other systems report events here
-- (bought, placed, stole, pulled, pushed, locked, rebirthed, earned) and this
-- module counts them, pays rewards, and tells the player with a QUEST DONE!
-- banner. Chapter progress lives in PlayerState; definitions in QuestCatalog.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local QuestCatalog = require(Shared.QuestCatalog)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)

local QuestSystem = {}

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

local function dayOfYear()
	return tonumber(os.date("%j"))
end

-- Resets the daily counters when the calendar day has changed.
local function ensureDailyDay(state)
	local today = dayOfYear()
	if state.dailyDay ~= today then
		state.dailyDay = today
		state.dailyProgress = {}
		state.dailyDone = {}
	end
end

local function currentStep(state)
	local chapter = QuestCatalog.CHAPTERS[state.questChapter]
	if not chapter then
		return nil
	end
	return chapter.steps[state.questStep]
end

local function payReward(player, state, amount, label)
	PlayerState.AddCash(state, amount)
	notify(player, "QUEST DONE! " .. label .. "  +$" .. amount, "quest")
end

-- Checks the current chapter step and all of today's daily quests for
-- completion. Called after every event; loops so a big jump pays each step.
local function checkCompletions(player, state)
	ensureDailyDay(state)
	-- Chapter steps.
	while true do
		local step = currentStep(state)
		if not step then
			break
		end
		local progress = state.questProgress[step.key] or 0
		if step.key == "ownedCount" then
			progress = PlayerState.CountOwned(state)
		end
		if progress < step.target then
			break
		end
		payReward(player, state, step.reward, step.text)
		state.questStep += 1
		local chapter = QuestCatalog.CHAPTERS[state.questChapter]
		if state.questStep > #chapter.steps then
			state.questChapter += 1
			state.questStep = 1
			if state.questChapter > #QuestCatalog.CHAPTERS then
				notify(player, "You finished every chapter! School Star!", "quest")
				state.questChapter = #QuestCatalog.CHAPTERS
				state.questStep = #chapter.steps + 1
				break
			else
				local nextChapter = QuestCatalog.CHAPTERS[state.questChapter]
				notify(player, "Chapter " .. state.questChapter .. ": " .. nextChapter.title .. "!", "quest")
			end
		end
	end
	-- Daily quests.
	for _, daily in ipairs(QuestCatalog.GetDailyQuests(dayOfYear())) do
		if not state.dailyDone[daily.key] then
			local progress = state.dailyProgress[daily.key] or 0
			if progress >= daily.target then
				state.dailyDone[daily.key] = true
				payReward(player, state, daily.reward, daily.text)
			end
		end
	end
end

-- One game event. `data` carries extras: amount for "earned", rarity for "bought".
function QuestSystem.OnEvent(player, event, data)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	data = data or {}
	ensureDailyDay(state)

	-- Chapter counters.
	if event == "earned" then
		state.questProgress.earned = (state.questProgress.earned or 0) + (data.amount or 0)
	else
		state.questProgress[event] = (state.questProgress[event] or 0) + 1
	end
	if event == "pulled" or event == "pushed" then
		state.questProgress.grappled = (state.questProgress.grappled or 0) + 1
	end

	-- Daily counters mirror the chapter ones under daily keys.
	if event == "bought" then
		state.dailyProgress.dailyBuy = (state.dailyProgress.dailyBuy or 0) + 1
		local rank = QuestCatalog.RARITY_RANK[data.rarity] or 1
		if rank >= QuestCatalog.RARITY_RANK.Rare then
			state.dailyProgress.dailyRare = (state.dailyProgress.dailyRare or 0) + 1
		end
	elseif event == "placed" then
		state.dailyProgress.dailyPlace = (state.dailyProgress.dailyPlace or 0) + 1
	elseif event == "stole" then
		state.dailyProgress.dailySteal = (state.dailyProgress.dailySteal or 0) + 1
	elseif event == "earned" then
		state.dailyProgress.dailyEarn = (state.dailyProgress.dailyEarn or 0) + (data.amount or 0)
	elseif event == "pulled" or event == "pushed" then
		state.dailyProgress.dailyGrapple = (state.dailyProgress.dailyGrapple or 0) + 1
	end

	checkCompletions(player, state)
end

return QuestSystem
