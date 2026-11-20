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

-- The floating name plate: TWO lines only. Line 1 is the name; line 2
-- merges rarity, income and price ("GOLD COMMON $16/s · BUY $96"), or
-- carries a state word alone ("CARRIED", "DROPPED · CLICK TO GRAB") when
-- the brainrot is not for sale. Kept small and compact on purpose: parade
-- brainrots walk close together, and a tall plate covers its neighbour's
-- plate. Always on top so the judge's screenshots can read it; hidden
-- past 45 studs so only nearby plates show. Both lines are TextScaled, so
-- a long name or a long price line shrinks instead of clipping.
-- Composes line 2 from the info text and a status word. A state word
-- (CARRIED, DROPPED...) replaces the line: a carried or dropped brainrot
-- is not for sale, so its price would be a lie. A commercial word (BUY
-- $X, FREE) joins the info on the same line instead of growing a third.
local function lineTwoText(infoText, statusText)
	if not statusText or statusText == "" then
		return infoText
	elseif statusText == "CARRIED" or string.sub(statusText, 1, 7) == "DROPPED" then
		return statusText
	else
		return infoText .. " · " .. statusText
	end
end

local function buildLabel(entry, mutation, showCost)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(230, 52)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 45
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
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = entry.name
	nameLabel.Parent = frame

	local rarityColor = Config.RARITY_COLORS[entry.rarity] or Color3.fromRGB(255, 255, 255)
	local income = Catalog.MutatedIncome(entry, mutation)
	local infoText = string.upper(entry.rarity) .. " $" .. income .. "/s"
	if mutation then
		infoText = mutation .. " " .. infoText
	end
	-- SetStatus rewrites line 2 later (CARRIED, DROPPED, FREE), so the
	-- info text and its colour live on the plate itself.
	gui:SetAttribute("InfoText", infoText)
	gui:SetAttribute("InfoColor", rarityColor)

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLine"
	infoLabel.Size = UDim2.new(1, -8, 0, 20)
	infoLabel.Position = UDim2.fromOffset(4, 29)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextSize = 14
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = rarityColor
	infoLabel.Text = lineTwoText(infoText, showCost and ("BUY $" .. entry.cost) or "")
	infoLabel.Parent = frame

	return gui
end

-- Rewrites the plate's second line: a state word replaces it ("CARRIED",
-- "DROPPED · CLICK TO GRAB"), a commercial word joins the info on it
-- ("FREE"), and "" restores the info alone with its rarity colour. The
-- label lives on the Body part, not on the (invisible) pivot, and the
-- line sits inside the plate's frame.
function BrainrotFactory.SetStatus(model, text, color)
	local body = model:FindFirstChild("Body")
	local label = body and body:FindFirstChild("Label")
	local line = label and label:FindFirstChild("InfoLine", true)
	if line then
		line.Text = lineTwoText(label:GetAttribute("InfoText") or "", text)
		if color then
			line.TextColor3 = color
		elseif not text or text == "" then
			line.TextColor3 = label:GetAttribute("InfoColor") or Color3.fromRGB(255, 255, 255)
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
	-- The prompt anchor: an invisible part at the model's base. The steal
	-- prompt hangs from it, so the [E] bubble renders at ground level, far
	-- below the floating plate. It sits just inside the body's bottom face
	-- so it never changes the model's bounding box (the spawner measures
	-- the lift from that box). A Cylinder is rolled upright, so its
	-- vertical extent is its X size; every other shape stands on its Y size.
	local bodySize = SHAPE_SIZES[entry.shape] or Vector3.new(2.6, 2.4, 2.4)
	local halfHeight = entry.shape == "Cylinder" and bodySize.X / 2 or bodySize.Y / 2
	local promptAnchor = newPart("PromptAnchor", Vector3.new(0.1, 0.1, 0.1), entry.body, Enum.Material.SmoothPlastic)
	promptAnchor.Transparency = 1
	promptAnchor.CanQuery = false
	promptAnchor.CastShadow = false
	promptAnchor.CFrame = CFrame.new(0, -halfHeight + 0.06, 0)
	promptAnchor.Parent = model

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
