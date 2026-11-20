-- CarrySystem: everything about holding a brainrot in your hands.
-- Buying from the parade, grabbing a dropped or high-pad brainrot, carrying it
-- welded to your character, dropping it, and placing it on a pedestal in your
-- own classroom. The steal prompt is attached by StealSystem through the
-- OnPlaced callback the bootstrap wires up, so this module never requires it.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local Spawner = require(script.Parent.Spawner)
local WorldBuilder = require(script.Parent.WorldBuilder)
local QuestSystem = require(script.Parent.QuestSystem)

local CarrySystem = {}

-- Set by the bootstrap: StealSystem.CreatePrompt(model, owner, record).
CarrySystem.OnPlaced = nil

local dropped = {} -- [uid] = record lying on the field
local pedestalBase = {} -- [pedestalId] = base index

local CARRY_OFFSETS = {
	CFrame.new(0, 3.4, 0),
	CFrame.new(0, 1.4, 3.4),
}

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

-- A buy or grab without a character would take the cash and strand the
-- brainrot, so every entry point checks this before anything changes.
local function hasCharacter(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") ~= nil
end

-- Welds every part of the model together, then welds the body to the
-- character's root so the brainrot rides along. Massless so it never drags.
local function weldToCharacter(model, character, slotIndex)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local body = model.PrimaryPart
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CanCollide = false
			if descendant ~= body then
				local constraint = Instance.new("WeldConstraint")
				constraint.Part0 = body
				constraint.Part1 = descendant
				constraint.Parent = body
			end
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = CARRY_OFFSETS[slotIndex] or CARRY_OFFSETS[1]
	weld.Parent = body
	return true
end

local function unweldModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
			descendant:Destroy()
		end
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.Massless = false
		end
	end
end

local function takeIntoHands(player, state, record)
	local character = player.Character
	if not character then
		return false
	end
	local slotIndex = #state.carried + 1
	if not weldToCharacter(record.model, character, slotIndex) then
		return false
	end
	table.insert(state.carried, record)
	state.owned[record.catalogId] = true
	return true
end

-- Public so StealSystem can hand a stolen brainrot to its new carrier with
-- the exact same weld, instead of duplicating the weld code.
function CarrySystem.TakeIntoHands(player, state, record)
	return takeIntoHands(player, state, record)
end

-- Buys a parade brainrot: cash check, then it goes into the player's hands.
function CarrySystem.TryBuyParade(player, uid)
	local record = Spawner.GetParade(uid)
	if not record then
		return
	end
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	if not hasCharacter(player) then
		return
	end
	if #state.carried >= PlayerState.GetCarryCapacity(state) then
		notify(player, "Your hands are full! Place a brainrot first.", "warn")
		return
	end
	local entry = Catalog.ById[record.catalogId]
	if not PlayerState.TrySpend(state, entry.cost) then
		notify(player, "Not enough cash for " .. record.name .. " ($" .. entry.cost .. ").", "warn")
		return
	end
	Spawner.RemoveParade(uid)
	if takeIntoHands(player, state, record) then
		PlayerState.PushUpdate(state)
		notify(player, "You bought " .. record.name .. "! Carry it home to your classroom.", "good")
		QuestSystem.OnEvent(player, "bought", { rarity = record.rarity })
	end
end

-- Grabs a free brainrot from a high pad (gym wall, big tree, tower top).
function CarrySystem.TryGrabHighPad(player, uid)
	local record = Spawner.GetHighPad(uid)
	if not record then
		return
	end
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	if not hasCharacter(player) then
		return
	end
	if #state.carried >= PlayerState.GetCarryCapacity(state) then
		notify(player, "Your hands are full! Place a brainrot first.", "warn")
		return
	end
	Spawner.RemoveHighPad(uid)
	if takeIntoHands(player, state, record) then
		PlayerState.PushUpdate(state)
		notify(player, "You grabbed " .. record.name .. " from the heights!", "good")
		QuestSystem.OnEvent(player, "bought", { rarity = record.rarity })
	end
end

-- Grabs a brainrot lying dropped on the field. Anyone can take it.
function CarrySystem.TryGrabDropped(player, uid)
	local record = dropped[uid]
	if not record then
		return
	end
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	if not hasCharacter(player) then
		return
	end
	if #state.carried >= PlayerState.GetCarryCapacity(state) then
		notify(player, "Your hands are full! Place a brainrot first.", "warn")
		return
	end
	dropped[uid] = nil
	if takeIntoHands(player, state, record) then
		PlayerState.PushUpdate(state)
		notify(player, "You grabbed the dropped " .. record.name .. "!", "good")
	end
end

-- Drops one carried brainrot on the ground where the player stands.
function CarrySystem.DropCarried(player, record, atPosition)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	for i, carried in ipairs(state.carried) do
		if carried.uid == record.uid then
			table.remove(state.carried, i)
			break
		end
	end
	unweldModel(record.model)
	local spot = atPosition or Vector3.new(0, Config.GROUND_Y + 2, 0)
	record.model:PivotTo(CFrame.new(spot.X, Config.GROUND_Y + 1.6, spot.Z))
	record.model.Parent = workspace
	dropped[record.uid] = record
	-- The ClickDetector lives on the Body part, not on the (invisible) pivot.
	local bodyPart = record.model:FindFirstChild("Body")
	local clicker = bodyPart and bodyPart:FindFirstChild("Clicker")
	if clicker then
		clicker.MouseClick:Connect(function(grabber)
			CarrySystem.TryGrabDropped(grabber, record.uid)
		end)
	end
	-- A dropped brainrot wanders off after a while. The generation stamp
	-- ties the timer to this drop: if the brainrot is grabbed and dropped
	-- again, the old timer must not destroy the fresh drop.
	record.dropGeneration = (record.dropGeneration or 0) + 1
	local generation = record.dropGeneration
	task.delay(Config.DROPPED_LIFETIME, function()
		if dropped[record.uid] and record.dropGeneration == generation then
			dropped[record.uid] = nil
			record.model:Destroy()
		end
	end)
	PlayerState.PushUpdate(state)
end

function CarrySystem.DropAllCarried(player)
	local state = PlayerState.Get(player)
	if not state or #state.carried == 0 then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local basePosition = root and root.Position or Vector3.new(0, Config.GROUND_Y, 0)
	local copy = table.clone(state.carried)
	for i, record in ipairs(copy) do
		local offset = Vector3.new((i - 1) * 4 - 2, 0, 4)
		CarrySystem.DropCarried(player, record, basePosition + offset)
	end
end

-- Puts a brainrot record on one pedestal: positions the model, registers it
-- as placed, tints the pedestal ring, and attaches the steal prompt. Shared
-- by hand placement, the Gacha Machine and the Fuse Lab. Silent skips the
-- "Placed" message so the caller can announce its own result instead.
function CarrySystem.PlaceRecordOnPedestal(player, state, record, base, pedestal, silent)
	unweldModel(record.model)
	record.model:PivotTo(CFrame.new(pedestal.position + Vector3.new(0, 1.6, 0)))
	record.model.Parent = workspace
	record.pedestalId = pedestal.id
	state.placed[pedestal.id] = record
	pedestal.top.Color = Config.RARITY_COLORS[record.rarity] or Color3.fromRGB(200, 200, 200)
	if CarrySystem.OnPlaced then
		CarrySystem.OnPlaced(record.model, player, record)
	end
	PlayerState.PushUpdate(state)
	if not silent then
		local entry = Catalog.ById[record.catalogId]
		notify(player, "Placed " .. record.name .. " — earning $" .. Catalog.MutatedIncome(entry, record.mutation) .. "/s!", "good")
	end
	QuestSystem.OnEvent(player, "placed", { rarity = record.rarity })
end

-- Places the first carried brainrot on one of the player's own pedestals.
function CarrySystem.TryPlace(player, pedestalId, base)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	if state.baseIndex ~= base.index then
		notify(player, "That's not your classroom!", "warn")
		return
	end
	if #state.carried == 0 then
		notify(player, "You're not carrying a brainrot.", "warn")
		return
	end
	if state.placed[pedestalId] then
		notify(player, "That pedestal is taken.", "warn")
		return
	end
	local pedestal = nil
	for _, candidate in ipairs(base.pedestals) do
		if candidate.id == pedestalId then
			pedestal = candidate
			break
		end
	end
	if not pedestal then
		return
	end
	local record = table.remove(state.carried, 1)
	CarrySystem.PlaceRecordOnPedestal(player, state, record, base, pedestal, false)
end

-- Removes a placed brainrot: clears the pedestal tint and optionally destroys
-- the model (a steal keeps the model; a rebirth or crow theft destroys it).
function CarrySystem.RemovePlaced(player, pedestalId, destroyModel)
	local state = PlayerState.Get(player)
	if not state then
		return nil
	end
	local record = state.placed[pedestalId]
	if not record then
		return nil
	end
	state.placed[pedestalId] = nil
	local base = WorldBuilder.GetBase(state.baseIndex)
	if base then
		for _, pedestal in ipairs(base.pedestals) do
			if pedestal.id == pedestalId then
				pedestal.top.Color = Color3.fromRGB(200, 200, 200)
			end
		end
	end
	if destroyModel and record.model then
		record.model:Destroy()
	end
	PlayerState.PushUpdate(state)
	return record
end

-- Cleans up when a player leaves: their brainrots go with them.
function CarrySystem.CleanupPlayer(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	for _, record in ipairs(state.carried) do
		if record.model then
			record.model:Destroy()
		end
	end
	for pedestalId in pairs(state.placed) do
		CarrySystem.RemovePlaced(player, pedestalId, true)
	end
end

function CarrySystem.Start()
	for _, base in ipairs(WorldBuilder.GetBases()) do
		for _, pedestal in ipairs(base.pedestals) do
			pedestalBase[pedestal.id] = base.index
			pedestal.clicker.MouseClick:Connect(function(player)
				CarrySystem.TryPlace(player, pedestal.id, base)
			end)
		end
	end
	-- Pedestals bought later (Extra Slot upgrade) get wired when they are added.
	WorldBuilder.OnPedestalAdded = function(base, pedestal)
		pedestalBase[pedestal.id] = base.index
		pedestal.clicker.MouseClick:Connect(function(player)
			CarrySystem.TryPlace(player, pedestal.id, base)
		end)
	end
end

return CarrySystem
