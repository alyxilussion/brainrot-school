-- StealSystem: the "Press [E] STEAL" prompt on every placed brainrot.
-- Walk up to a brainrot on a rival's unlocked base and the prompt appears;
-- press E and it is yours to carry home, while its owner gets an alert.
-- A locked base shows LOCKED instead, and the prompt refuses to fire.

local Players = game:GetService("Players")

local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local CarrySystem = require(script.Parent.CarrySystem)
local QuestSystem = require(script.Parent.QuestSystem)

local StealSystem = {}

local prompts = {} -- [uid] = { prompt, owner, record }

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

local function baseIndexOfPedestal(pedestalId)
	local basePart = string.match(pedestalId, "^b(%d+)p%d+$")
	return basePart and tonumber(basePart) or nil
end

-- Attaches the steal prompt to a newly placed brainrot.
function StealSystem.CreatePrompt(model, owner, record)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "STEAL"
	prompt.ObjectText = record.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	-- The client reads this to hide your own prompts from you: you cannot
	-- steal from yourself, so your own brainrots stay uncluttered.
	prompt:SetAttribute("OwnerUserId", owner.UserId)
	prompts[record.uid] = { prompt = prompt, owner = owner, record = record }
	prompt.Triggered:Connect(function(player)
		StealSystem.TrySteal(player, record.uid)
	end)
end

function StealSystem.RemovePrompt(uid)
	local entry = prompts[uid]
	if entry then
		entry.prompt:Destroy()
		prompts[uid] = nil
	end
end

-- Locks or unlocks every prompt on one base: locked prompts read LOCKED and
-- cannot fire, unlocked ones read STEAL again.
function StealSystem.SetPromptsForBase(baseIndex, locked)
	for _, entry in pairs(prompts) do
		local record = entry.record
		if record.pedestalId and baseIndexOfPedestal(record.pedestalId) == baseIndex then
			entry.prompt.Enabled = not locked
			entry.prompt.ActionText = locked and "LOCKED" or "STEAL"
		end
	end
end

function StealSystem.TrySteal(player, uid)
	local entry = prompts[uid]
	if not entry then
		return
	end
	local owner = entry.owner
	local record = entry.record
	if player == owner then
		return
	end
	local ownerState = PlayerState.Get(owner)
	local thiefState = PlayerState.Get(player)
	if not ownerState or not thiefState then
		return
	end
	if PlayerState.IsLocked(ownerState) then
		notify(player, "That base is locked!", "warn")
		return
	end
	if #thiefState.carried >= PlayerState.GetCarryCapacity(thiefState) then
		notify(player, "Your hands are full! Place a brainrot first.", "warn")
		return
	end
	if not ownerState.placed[record.pedestalId] or ownerState.placed[record.pedestalId].uid ~= uid then
		return
	end
	-- The thief needs a character to carry it: without one the brainrot
	-- would leave its pedestal and belong to nobody.
	local thiefCharacter = player.Character
	if not thiefCharacter or not thiefCharacter:FindFirstChild("HumanoidRootPart") then
		return
	end
	-- Take it off the pedestal, keep the model, and put it in the thief's hands.
	CarrySystem.RemovePlaced(owner, record.pedestalId, false)
	StealSystem.RemovePrompt(uid)
	if not CarrySystem.TakeIntoHands(player, thiefState, record) then
		return
	end
	PlayerState.PushUpdate(thiefState)
	PlayerState.PushUpdate(ownerState)
	notify(player, "You stole " .. record.name .. "! Run home!", "good")
	notify(owner, "Brainrot-mu dicuri! " .. player.Name .. " stole your " .. record.name .. "!", "alert")
	QuestSystem.OnEvent(player, "stole", { rarity = record.rarity })
end

return StealSystem
