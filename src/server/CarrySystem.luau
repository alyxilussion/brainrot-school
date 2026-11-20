-- CarrySystem: every brainrot record and where it is: walking the parade,
-- on a pad, carried overhead, dropped on the grass or on a pedestal.
-- Carriers auto-deposit by walking into their own classroom; a death, a
-- reset or a knock drops what you carry so nothing is ever lost or ghosted.

local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local CarrySystem = {}
CarrySystem.records = {}

local G -- game context, set in Init
local folder
local uidCounter = 0
local rng = Random.new()

local function now()
	return Workspace:GetServerTimeNow()
end

-- A new record plus its model. status: parade | pad | carried | dropped | placed.
function CarrySystem.NewRecord(entry, mutation, cframe, status, opts)
	uidCounter += 1
	local uid = "r" .. uidCounter
	local record = {
		uid = uid,
		catalogId = entry.id,
		name = entry.name,
		rarity = entry.rarity,
		mutation = mutation,
		status = status,
		carrier = nil,
		owner = nil,
		pedestal = nil,
		connections = {},
	}
	opts = opts or {}
	opts.origin = cframe
	record.model = G.Factory.Build(entry, mutation, uid, opts)
	record.model.Parent = folder
	CarrySystem.records[uid] = record
	return record
end

-- Prompts and their connections belong to one status; clear them on change.
function CarrySystem.ClearPrompts(record)
	for _, connection in ipairs(record.connections) do
		connection:Disconnect()
	end
	record.connections = {}
	if record.model then
		for _, descendant in ipairs(record.model:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then
				descendant:Destroy()
			end
		end
	end
end

function CarrySystem.Destroy(record)
	CarrySystem.ClearPrompts(record)
	if record.carrier then
		CarrySystem.Release(record)
	end
	if record.owner and record.pedestal then
		record.owner.placed[record.pedestal.id] = nil
		G.State.Changed(record.owner)
	end
	CarrySystem.records[record.uid] = nil
	if record.model then
		record.model:Destroy()
		record.model = nil
	end
end

-- Welding: the model rides above the carrier's head and moves with them.
local function setPhysical(model, carried)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = not carried
			part.Massless = carried
			part.CanCollide = false
			part.CanQuery = not carried
		end
	end
end

local function weldTo(record, root)
	local model = record.model
	local primary = model.PrimaryPart
	local welds = Instance.new("Folder")
	welds.Name = "CarryWelds"
	welds.Parent = model
	model:PivotTo(root.CFrame * CFrame.new(0, 3 + #record.carrier.carrying * 3.6, 0.4))
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = welds
		end
	end
	setPhysical(model, true)
	local hold = Instance.new("WeldConstraint")
	hold.Name = "HoldWeld"
	hold.Part0 = root
	hold.Part1 = primary
	hold.Parent = welds
end

local function unweld(record)
	local welds = record.model and record.model:FindFirstChild("CarryWelds")
	if welds then
		welds:Destroy()
	end
	if record.model then
		setPhysical(record.model, false)
	end
end

-- Pick up a brainrot. Fails without side effects when hands are full.
function CarrySystem.TakeIntoHands(state, record)
	if #state.carrying >= G.State.CarryCapacity(state) then
		G.notify(state, "Your hands are full! Bring it home first.", Color3.fromRGB(255, 120, 120))
		return false
	end
	local root = G.State.RootOf(state)
	if not root or not record.model then
		return false
	end
	CarrySystem.ClearPrompts(record)
	if record.owner and record.pedestal then
		record.owner.placed[record.pedestal.id] = nil
		G.State.Changed(record.owner)
	end
	record.owner = nil
	record.pedestal = nil
	record.status = "carried"
	record.carrier = state
	record.droppedAt = nil
	weldTo(record, root)
	table.insert(state.carrying, record)
	G.Factory.SetStatus(record.model, "CARRIED BY " .. string.upper(state.name), Color3.fromRGB(255, 220, 90))
	G.State.MarkOwned(state, record.catalogId)
	G.Quests.SyncCounters(state)
	G.Economy.ApplyWalkSpeed(state)
	G.State.Changed(state)
	return true
end

-- Take a record out of its carrier's hands (no placement yet).
function CarrySystem.Release(record)
	local carrier = record.carrier
	if not carrier then
		return
	end
	local index = table.find(carrier.carrying, record)
	if index then
		table.remove(carrier.carrying, index)
	end
	record.carrier = nil
	unweld(record)
	G.Economy.ApplyWalkSpeed(carrier)
	G.State.Changed(carrier)
end

-- Drop on the ground: anyone can press [E] Grab for a while, then it wanders off.
function CarrySystem.Drop(record, position, lastCarrier)
	CarrySystem.Release(record)
	CarrySystem.ClearPrompts(record)
	if not record.model then
		return
	end
	-- Land on whatever is below: grass, a roof, the tree platform.
	local x = math.clamp(position.X, -185, 185)
	local z = math.clamp(position.Z, -185, 185)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { G.World.GetWorld().root }
	local hit = Workspace:Raycast(Vector3.new(x, position.Y + 2, z), Vector3.new(0, -120, 0), params)
	local y = hit and hit.Position.Y or G.World.GroundHeightAt(x, z)
	record.model:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	record.status = "dropped"
	record.droppedAt = now()
	record.lastCarrier = lastCarrier
	G.Factory.SetStatus(record.model, "DROPPED · [E] GRAB", Color3.fromRGB(255, 220, 90))
	local prompt = G.Factory.AttachGrabPrompt(record.model, G.Factory.DescribeRecord(record))
	table.insert(record.connections, prompt.Triggered:Connect(function(player)
		local state = G.State.Get(player)
		if state and record.status == "dropped" and CarrySystem.TakeIntoHands(state, record) then
			if record.lastCarrier ~= state then
				G.Quests.OnEvent(state, "recover", 1)
			end
			G.fx("text", record.model.PrimaryPart.Position, "GRABBED!", Color3.fromRGB(255, 220, 90))
		end
	end))
	G.fx("text", Vector3.new(x, y + 5, z), "DROPPED!", Color3.fromRGB(255, 150, 90))
end

-- Everything someone carries hits the floor (death, reset, Lunch Rush).
function CarrySystem.DropAll(state, position)
	local root = G.State.RootOf(state)
	position = position or (root and root.Position) or (state.lastPosition or Vector3.new(0, 1, 100))
	for i = #state.carrying, 1, -1 do
		local record = state.carrying[i]
		local spread = Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
		CarrySystem.Drop(record, position + spread, state)
	end
end

-- Put a record on a pedestal of a base and hand it the Steal/Sell prompts.
function CarrySystem.Place(state, record, pedestal)
	CarrySystem.Release(record)
	CarrySystem.ClearPrompts(record)
	local base = G.World.GetBase(state.baseIndex)
	local facing = base.cframe - base.cframe.Position
	record.model:PivotTo(CFrame.new(pedestal.position) * facing)
	record.status = "placed"
	record.owner = state
	record.pedestal = pedestal
	state.placed[pedestal.id] = record
	G.State.MarkOwned(state, record.catalogId)
	G.Quests.SyncCounters(state)
	G.Steal.AttachPrompts(record)
	G.State.Changed(state)
end

-- Place on the first free pedestal; returns false when the base is full.
function CarrySystem.PlaceAnywhere(state, record)
	local base = state.baseIndex and G.World.GetBase(state.baseIndex)
	local pedestal = base and G.World.GetFreePedestal(base, state.placed)
	if not pedestal then
		return false
	end
	CarrySystem.Place(state, record, pedestal)
	return true
end

-- Walk into your own classroom with brainrots in hand: they hop onto pedestals.
local fullWarnings = {}
local function depositCarried(state)
	local root = G.State.RootOf(state)
	if not root or not state.baseIndex or #state.carrying == 0 then
		return
	end
	if G.World.BaseAtPosition(root.Position) ~= state.baseIndex then
		return
	end
	for i = #state.carrying, 1, -1 do
		local record = state.carrying[i]
		local stolenFrom = record.stolenFrom
		if CarrySystem.PlaceAnywhere(state, record) then
			G.Quests.OnEvent(state, "place", 1)
			if stolenFrom and stolenFrom ~= state then
				G.notify(state, "Stolen " .. record.name .. " is yours now!", Color3.fromRGB(120, 255, 150))
			end
			record.stolenFrom = nil
			G.fx("text", record.model.PrimaryPart.Position, "+ " .. Config.FormatMoney(Catalog.MutatedIncome(Catalog.ById[record.catalogId], record.mutation)) .. "/s", Color3.fromRGB(120, 255, 150))
			G.fx("sound", "place", record.model.PrimaryPart.Position)
		elseif (fullWarnings[state] or 0) < os.clock() then
			fullWarnings[state] = os.clock() + 4
			G.notify(state, "Classroom full! Sell one [E] or buy Extra Slot.", Color3.fromRGB(255, 180, 90))
			break
		end
	end
end

-- Click a pedestal of your own base while carrying: place exactly there.
local function onPedestalAdded(base, pedestal)
	pedestal.clicker.MouseClick:Connect(function(player)
		local state = G.State.Get(player)
		if not state or state.baseIndex ~= base.index or #state.carrying == 0 or state.placed[pedestal.id] then
			return
		end
		local root = G.State.RootOf(state)
		if root and (root.Position - pedestal.position).Magnitude < 30 then
			local record = state.carrying[#state.carrying]
			CarrySystem.Place(state, record, pedestal)
			G.Quests.OnEvent(state, "place", 1)
		end
	end)
end

function CarrySystem.Init(context)
	G = context
	folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	folder.Parent = Workspace
	G.World.OnPedestalAdded = onPedestalAdded
	for _, base in ipairs(G.World.GetBases()) do
		for _, pedestal in ipairs(base.pedestals) do
			onPedestalAdded(base, pedestal)
		end
	end
	-- Deposit check and dropped-brainrot expiry, four times a second.
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, state in pairs(G.State.All()) do
				if not state.isBot then
					depositCarried(state)
					local root = G.State.RootOf(state)
					if root then
						state.lastPosition = root.Position
					end
				end
			end
			local t = now()
			for _, record in pairs(CarrySystem.records) do
				if record.status == "dropped" and record.droppedAt and t - record.droppedAt > Config.DROPPED_LIFETIME then
					if record.model and record.model.PrimaryPart then
						G.fx("text", record.model.PrimaryPart.Position, record.name .. " wandered off", Color3.fromRGB(200, 200, 220))
					end
					CarrySystem.Destroy(record)
				end
			end
		end
	end)
end

return CarrySystem
