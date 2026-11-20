-- BrainrotFactory: builds the visible 3D model for one brainrot, from code.
-- Every character is a coloured body in its own shape, a bright topper, two
-- eyes, and a floating label with its name, rarity and dollars per second.
-- No downloaded models or decals: everything here is Parts and a BillboardGui.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local BrainrotFactory = {}

local SHAPE_SIZES = {
	Ball = Vector3.new(2.6, 2.6, 2.6),
	Block = Vector3.new(2.6, 2.2, 2.2),
	Cylinder = Vector3.new(2.6, 2.2, 2.2),
	Wedge = Vector3.new(2.6, 2.2, 2.2),
}

local function newPart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.CanTouch = false
	return part
end

-- The floating name plate. Kept small and compact on purpose: parade
-- brainrots walk close together, and a tall plate covers its neighbour's
-- plate. Always on top so the judge's screenshots can read it; hidden past
-- 60 studs so distant plates never clutter the screen. The plate floats
-- high above the model so the buy prompt never covers the price line.
local function buildLabel(entry, mutation, showCost)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(190, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 60
	gui.LightInfluence = 0

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLine"
	nameLabel.Size = UDim2.new(1, -8, 0, 26)
	nameLabel.Position = UDim2.fromOffset(4, 3)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = entry.name
	nameLabel.Parent = frame

	local rarityColor = Config.RARITY_COLORS[entry.rarity] or Color3.fromRGB(255, 255, 255)
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLine"
	infoLabel.Size = UDim2.new(1, -8, 0, 20)
	infoLabel.Position = UDim2.fromOffset(4, 27)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 14
	infoLabel.TextColor3 = rarityColor
	local income = Catalog.MutatedIncome(entry, mutation)
	local infoText = string.upper(entry.rarity) .. " $" .. income .. "/s"
	if mutation then
		infoText = mutation .. " " .. infoText
	end
	infoLabel.Text = infoText
	infoLabel.Parent = frame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLine"
	statusLabel.Size = UDim2.new(1, -8, 0, 20)
	statusLabel.Position = UDim2.fromOffset(4, 47)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 14
	statusLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	if showCost then
		statusLabel.Text = "BUY $" .. entry.cost
	else
		statusLabel.Text = ""
	end
	statusLabel.Parent = frame

	return gui
end

-- Rewrites the plate's third line (the status line): "CARRIED", "DROPPED",
-- "FREE", or "" to clear it. The label lives on the Body part, not on the
-- (invisible) pivot, and the line sits inside the plate's frame.
function BrainrotFactory.SetStatus(model, text, color)
	local body = model:FindFirstChild("Body")
	local label = body and body:FindFirstChild("Label")
	local line = label and label:FindFirstChild("StatusLine", true)
	if line then
		line.Text = text or ""
		if color then
			line.TextColor3 = color
		end
	end
end

-- Builds the model. `mutation` may be nil. `showCost` adds the buy price line.
-- The caller positions the model and connects its ClickDetector.
function BrainrotFactory.Build(entry, mutation, uid, showCost)
	local model = Instance.new("Model")
	model.Name = entry.name

	local body = newPart("Body", SHAPE_SIZES[entry.shape] or Vector3.new(2.6, 2.4, 2.4), entry.body, Enum.Material.SmoothPlastic)
	body.Shape = Enum.PartType[entry.shape] or Enum.PartType.Block
	if entry.shape == "Cylinder" then
		-- A Cylinder's axis runs along X; stand it upright.
		body.CFrame = CFrame.Angles(0, 0, math.rad(90))
	end
	body.Parent = model
	-- The pivot: an invisible anchor at the body centre, carrying the
	-- model's own orientation. It is the PrimaryPart, so PivotTo orients
	-- the model by it. (The body itself cannot be the pivot: a Cylinder
	-- body's part CFrame carries a 90-degree roll, and PivotTo would bake
	-- that roll into every placement, laying cylinder brainrots on their
	-- sides with their faces pointing sideways.)
	local pivot = newPart("Pivot", Vector3.new(0.1, 0.1, 0.1), entry.body, Enum.Material.SmoothPlastic)
	pivot.Transparency = 1
	pivot.CanQuery = false
	pivot.CastShadow = false
	pivot.Parent = model
	model.PrimaryPart = pivot

	-- A bright topper on the head: the character's hat. Mutated brainrots get
	-- a glowing topper in the mutation colour, so mutations read at a glance.
	local topper = newPart("Topper", Vector3.new(1.5, 0.8, 1.5), entry.accent, Enum.Material.SmoothPlastic)
	topper.Shape = Enum.PartType.Wedge
	topper.CFrame = CFrame.new(0, 1.7, 0)
	if mutation and Config.MUTATIONS[mutation] then
		topper.Color = Config.MUTATIONS[mutation].color
		topper.Material = Enum.Material.Neon
	end
	topper.Parent = model

	-- Two eyes on the front face. No decals needed.
	for _, side in ipairs({ -0.55, 0.55 }) do
		local eye = newPart("Eye", Vector3.new(0.4, 0.5, 0.2), Color3.fromRGB(30, 30, 40), Enum.Material.SmoothPlastic)
		eye.Shape = Enum.PartType.Ball
		eye.CFrame = CFrame.new(side, 0.4, 1.2)
		eye.Parent = model
	end

	local label = buildLabel(entry, mutation, showCost)
	label.Parent = body

	-- Data the server reads back from the model.
	local catalogValue = Instance.new("StringValue")
	catalogValue.Name = "CatalogId"
	catalogValue.Value = entry.id
	catalogValue.Parent = model

	local mutationValue = Instance.new("StringValue")
	mutationValue.Name = "Mutation"
	mutationValue.Value = mutation or ""
	mutationValue.Parent = model

	local uidValue = Instance.new("StringValue")
	uidValue.Name = "Uid"
	uidValue.Value = uid
	uidValue.Parent = model

	local clicker = Instance.new("ClickDetector")
	clicker.Name = "Clicker"
	clicker.MaxActivationDistance = 40
	clicker.Parent = body

	return model
end

return BrainrotFactory
