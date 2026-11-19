-- CrowThiefSystem: Gagak Nakal, the naughty crow who lives in the big tree.
-- Every couple of minutes he picks a random unlocked classroom that has
-- brainrots, swoops down, snatches the richest one, and flies home to his
-- nest. The owner gets an alert. A locked base is never a target — locking
-- is the only defence, which is exactly why the lock button matters.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local CarrySystem = require(script.Parent.CarrySystem)
local StealSystem = require(script.Parent.StealSystem)
local WorldBuilder = require(script.Parent.WorldBuilder)

local CrowThiefSystem = {}

local rng = Random.new(os.time() + 13)

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

-- The crow, built from Parts: a black body, two flat wings, an orange beak.
local function buildCrow()
	local crow = Instance.new("Model")
	crow.Name = "GagakNakal"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.2, 2.2, 3)
	body.Color = Color3.fromRGB(35, 35, 45)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = crow
	crow.PrimaryPart = body
	for _, side in ipairs({ -1, 1 }) do
		local wing = Instance.new("Part")
		wing.Name = "Wing"
		wing.Size = Vector3.new(3, 0.3, 1.6)
		wing.Color = Color3.fromRGB(55, 55, 70)
		wing.Material = Enum.Material.SmoothPlastic
		wing.Anchored = true
		wing.CanCollide = false
		wing.CFrame = CFrame.new(side * 2.4, 0.3, 0) * CFrame.Angles(0, 0, side * -0.4)
		wing.Parent = crow
	end
	local beak = Instance.new("Part")
	beak.Name = "Beak"
	beak.Shape = Enum.PartType.Wedge
	beak.Size = Vector3.new(0.8, 0.8, 1.4)
	beak.Color = Color3.fromRGB(255, 170, 40)
	beak.Material = Enum.Material.SmoothPlastic
	beak.Anchored = true
	beak.CanCollide = false
	beak.CFrame = CFrame.new(0, 0.2, 2)
	beak.Parent = crow
	return crow
end

local function flyTo(model, destination, seconds)
	local start = model:GetPivot().Position
	local startTime = os.clock()
	while os.clock() - startTime < seconds do
		local alpha = (os.clock() - startTime) / seconds
		-- A gentle arc: rise in the middle of the flight.
		local lift = math.sin(alpha * math.pi) * 8
		local position = start:Lerp(destination, alpha) + Vector3.new(0, lift, 0)
		-- lookAt points -Z at its target, so look from the destination back
		-- at the crow: the crow's beak (+Z) then faces where it flies.
		local facing = CFrame.lookAt(destination, position)
		model:PivotTo(CFrame.new(position) * facing.Rotation)
		task.wait(0.05)
	end
	model:PivotTo(CFrame.new(destination))
end

-- The richest brainrot on the victim's pedestals is the one the crow wants.
local function richestPlaced(state)
	local best = nil
	local bestIncome = -1
	for pedestalId, record in pairs(state.placed) do
		local income = Catalog.MutatedIncome(Catalog.ById[record.catalogId], record.mutation)
		if income > bestIncome then
			best = record
			bestIncome = income
			best.pedestalId = pedestalId
		end
	end
	return best
end

local function pickVictim()
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.Get(player)
		if state and not PlayerState.IsLocked(state) then
			local placedCount = 0
			for _ in pairs(state.placed) do
				placedCount += 1
			end
			if placedCount > 0 then
				table.insert(candidates, player)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

local function crowRaid()
	local victim = pickVictim()
	if not victim then
		return
	end
	local state = PlayerState.Get(victim)
	local target = richestPlaced(state)
	if not target then
		return
	end
	local world = WorldBuilder.GetWorld()
	local base = WorldBuilder.GetBase(state.baseIndex)
	if not base then
		return
	end
	local crowAlert = RemoteHub.Get("CrowAlert")
	if crowAlert then
		crowAlert:FireAllClients("Gagak Nakal is circling the school!")
	end

	local crow = buildCrow()
	crow:PivotTo(CFrame.new(world.treeTop))
	crow.Parent = workspace
	local perch = base.center + Vector3.new(0, 12, 0)
	flyTo(crow, perch, 4)
	-- Snatch: the brainrot leaves the pedestal and rides under the crow.
	local pedestalId = target.pedestalId
	CarrySystem.RemovePlaced(victim, pedestalId, false)
	StealSystem.RemovePrompt(target.uid)
	local stolen = target.model
	if stolen then
		for _, descendant in ipairs(stolen:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		stolen:PivotTo(crow:GetPivot() * CFrame.new(0, -2.5, 0))
		stolen.Parent = crow
	end
	notify(victim, "Gagak Nakal stole your " .. target.name .. "! Lock your base next time!", "alert")
	flyTo(crow, world.treeTop, 4)
	crow:Destroy()
end

function CrowThiefSystem.Start()
	task.spawn(function()
		while true do
			task.wait(Config.CROW_INTERVAL)
			local ok, err = pcall(crowRaid)
			if not ok then
				warn("Crow raid failed: " .. tostring(err))
			end
		end
	end)
end

return CrowThiefSystem
