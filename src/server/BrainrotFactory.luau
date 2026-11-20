-- BrainrotFactory: builds every brainrot's 3D model from Parts, in code.
-- A body in the character's own shape, big googly eyes, a grin, little feet
-- and arms, a school prop picked from its name (pencil, book, bag, ruler,
-- globe), a graduation cap or a crown, and a floating name/rarity/$ label.
-- No downloaded meshes or decals, so every model renders for every reviewer.
-- Also attaches the Press [E] prompts: Buy, Grab, Steal (thief) and Sell (owner).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.BrainrotCatalog)

local BrainrotFactory = {}

local DARK = Color3.fromRGB(25, 25, 35)
local WHITE = Color3.fromRGB(255, 255, 255)

-- Body size and centre height per shape, at scale 1. Feet occupy y 0..0.5.
local BODY = {
	Ball = { size = Vector3.new(2.8, 2.8, 2.8), y = 1.9 },
	Block = { size = Vector3.new(2.6, 2.4, 2.2), y = 1.7 },
	Cylinder = { size = Vector3.new(2.4, 2.8, 2.4), y = 1.9 },
	Wedge = { size = Vector3.new(2.4, 2.2, 2.6), y = 1.6 },
}

-- Which school prop a brainrot holds, from a word in its name.
local PROP_WORDS = {
	{ "Pensil", "pencil" }, { "Pencil", "pencil" }, { "Spidol", "pencil" }, { "Kapur", "pencil" },
	{ "Buku", "book" }, { "Pustaka", "book" }, { "Perpustakaan", "book" }, { "Rapor", "book" },
	{ "Arsip", "book" }, { "Ujian", "book" }, { "Tas", "bag" }, { "Backpack", "bag" },
	{ "Lunchbox", "bag" }, { "Mistar", "ruler" }, { "Penggaris", "ruler" }, { "Globe", "globe" },
	{ "Astronomi", "globe" }, { "Lonceng", "bell" }, { "Jam", "bell" },
}

local function propFor(name)
	for _, pair in ipairs(PROP_WORDS) do
		if string.find(name, pair[1], 1, true) then
			return pair[2]
		end
	end
	return nil
end

local function newPart(model, name, shape, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CastShadow = true
	part.Parent = model
	return part
end

-- The floating plate: name, tier and dollars a second, plus a status line
-- (price on the parade, STEAL on a rival base). Sized in studs so it shrinks
-- with distance instead of covering the screen; hidden past 80 studs.
local function buildLabel(entry, mutation, statusText, height)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(7, 0, 2.7, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.7, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false

	local rarityColor = Config.RARITY_COLORS[entry.rarity] or WHITE
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLine"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = WHITE
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = DARK
	nameLabel.Text = entry.name
	nameLabel.Parent = gui

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLine"
	infoLabel.Size = UDim2.fromScale(1, 0.3)
	infoLabel.Position = UDim2.fromScale(0, 0.4)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Font = Enum.Font.GothamBlack
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = rarityColor
	infoLabel.TextStrokeTransparency = 0
	infoLabel.TextStrokeColor3 = DARK
	local infoText = string.upper(entry.rarity) .. "  " .. Config.FormatMoney(Catalog.MutatedIncome(entry, mutation)) .. "/s"
	if mutation then
		infoText = mutation .. " " .. infoText
	end
	infoLabel.Text = infoText
	infoLabel.Parent = gui

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLine"
	statusLabel.Size = UDim2.fromScale(1, 0.28)
	statusLabel.Position = UDim2.fromScale(0, 0.71)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBlack
	statusLabel.TextScaled = true
	statusLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	statusLabel.TextStrokeTransparency = 0
	statusLabel.TextStrokeColor3 = DARK
	statusLabel.Text = statusText or ""
	statusLabel.Parent = gui
	return gui
end

local function addProp(model, kind, at, s, body, color)
	local halfW = body.size.X / 2
	local function v(x, y, z)
		return Vector3.new(x, y, z) * s
	end
	if kind == "pencil" then
		local pencilCf = at(Vector3.new(halfW + 0.55, body.y + 0.2, -0.3)) * CFrame.Angles(math.rad(-20), 0, 0)
		newPart(model, "PropPencil", Enum.PartType.Cylinder, v(2.6, 0.45, 0.45), pencilCf * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 205, 50))
		newPart(model, "PropEraser", Enum.PartType.Cylinder, v(0.4, 0.47, 0.47), pencilCf * CFrame.new(0, 1.45 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 140, 170))
		newPart(model, "PropTip", Enum.PartType.Ball, v(0.4, 0.4, 0.4), pencilCf * CFrame.new(0, -1.35 * s, 0), DARK)
	elseif kind == "book" then
		newPart(model, "PropBook", Enum.PartType.Block, v(0.5, 1.5, 1.1), at(Vector3.new(halfW + 0.3, body.y - 0.2, -0.2)), Color3.fromRGB(220, 60, 60))
		newPart(model, "PropPages", Enum.PartType.Block, v(0.52, 1.35, 0.9), at(Vector3.new(halfW + 0.3, body.y - 0.2, -0.32)), WHITE)
	elseif kind == "bag" then
		newPart(model, "PropBag", Enum.PartType.Block, v(1.8, 1.8, 0.8), at(Vector3.new(0, body.y, body.size.Z / 2 + 0.35)), color)
		newPart(model, "PropBagFlap", Enum.PartType.Block, v(1.82, 0.6, 0.84), at(Vector3.new(0, body.y + 0.63, body.size.Z / 2 + 0.36)), DARK)
	elseif kind == "ruler" then
		newPart(model, "PropRuler", Enum.PartType.Block, v(0.25, 3.2, 0.6), at(Vector3.new(halfW + 0.4, body.y + 0.3, -0.2)) * CFrame.Angles(0, 0, math.rad(-15)), Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
	elseif kind == "globe" then
		newPart(model, "PropGlobe", Enum.PartType.Ball, v(1.3, 1.3, 1.3), at(Vector3.new(halfW + 0.7, body.y - 0.1, -0.2)), Color3.fromRGB(70, 140, 230))
		newPart(model, "PropLand", Enum.PartType.Ball, v(0.7, 0.6, 0.6), at(Vector3.new(halfW + 0.85, body.y + 0.15, -0.55)), Color3.fromRGB(90, 200, 100))
	elseif kind == "bell" then
		newPart(model, "PropBell", Enum.PartType.Cylinder, v(1.1, 1.2, 1.2), at(Vector3.new(halfW + 0.65, body.y - 0.1, -0.2)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	end
end

-- Builds the model at `origin` (its feet; facing -Z). `opts`: scale, status
-- (label status line), noLabel. The model's WorldPivot is its feet, so
-- PivotTo(pedestalTop) stands it exactly on the pedestal.
function BrainrotFactory.Build(entry, mutation, uid, opts)
	opts = opts or {}
	local scale = opts.scale or 1
	local origin = opts.origin or CFrame.new()
	local model = Instance.new("Model")
	model.Name = entry.name
	local shapeKey = BODY[entry.shape] and entry.shape or "Block"
	local body = BODY[shapeKey]
	local function at(localPosition)
		return origin * CFrame.new(localPosition * scale)
	end
	local function sized(size)
		return size * scale
	end
	local bodySize = body.size
	local frontZ = -bodySize.Z / 2

	-- Body.
	local bodyPart
	if shapeKey == "Cylinder" then
		bodyPart = newPart(model, "Body", Enum.PartType.Cylinder, sized(Vector3.new(bodySize.Y, bodySize.X, bodySize.Z)), at(Vector3.new(0, body.y, 0)) * CFrame.Angles(0, 0, math.rad(90)), entry.body)
	elseif shapeKey == "Ball" then
		bodyPart = newPart(model, "Body", Enum.PartType.Ball, sized(bodySize), at(Vector3.new(0, body.y, 0)), entry.body)
	else
		bodyPart = newPart(model, "Body", Enum.PartType.Block, sized(bodySize), at(Vector3.new(0, body.y, 0)), entry.body)
	end
	model.PrimaryPart = bodyPart
	if shapeKey == "Wedge" then
		-- A dorsal fin on top: sharks, snakes and birds read as such.
		local fin = Instance.new("WedgePart")
		fin.Name = "Fin"
		fin.Size = sized(Vector3.new(0.5, 1.2, 1.6))
		fin.CFrame = at(Vector3.new(0, body.y + bodySize.Y / 2 + 0.6, 0.3))
		fin.Color = entry.accent
		fin.Material = Enum.Material.SmoothPlastic
		fin.Anchored = true
		fin.CanCollide = false
		fin.CanTouch = false
		fin.Parent = model
	end

	-- Belly patch, feet and stubby arms.
	newPart(model, "Belly", Enum.PartType.Ball, sized(Vector3.new(1.6, 1.4, 0.4)), at(Vector3.new(0, body.y - 0.45, frontZ + 0.08)), entry.accent)
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Foot", Enum.PartType.Ball, sized(Vector3.new(0.9, 0.5, 1.1)), at(Vector3.new(side * 0.65, 0.25, -0.15)), entry.accent)
		newPart(model, "Arm", Enum.PartType.Ball, sized(Vector3.new(0.5, 1.1, 0.5)), at(Vector3.new(side * (bodySize.X / 2 + 0.1), body.y - 0.2, -0.1)) * CFrame.Angles(0, 0, math.rad(side * 25)), entry.body)
	end

	-- Big googly eyes and a grin on the front face.
	local eyeY = body.y + 0.35
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Eye", Enum.PartType.Ball, sized(Vector3.new(0.85, 0.85, 0.5)), at(Vector3.new(side * 0.55, eyeY, frontZ - 0.05)), WHITE)
		newPart(model, "Pupil", Enum.PartType.Ball, sized(Vector3.new(0.42, 0.42, 0.25)), at(Vector3.new(side * 0.5, eyeY - 0.05, frontZ - 0.28)), DARK)
	end
	newPart(model, "Mouth", Enum.PartType.Block, sized(Vector3.new(1.0, 0.2, 0.12)), at(Vector3.new(0, eyeY - 0.7, frontZ - 0.02)), DARK)

	-- Hat: a mortarboard for students, a crown for the Godly tier and up.
	local topY = body.y + bodySize.Y / 2
	local rank = Config.RARITY_RANK[entry.rarity] or 1
	local mutationInfo = mutation and Config.MUTATIONS[mutation]
	local hatColor = mutationInfo and mutationInfo.color or entry.accent
	local hatMaterial = mutationInfo and Enum.Material.Neon or Enum.Material.SmoothPlastic
	if rank >= 12 then
		newPart(model, "Crown", Enum.PartType.Cylinder, sized(Vector3.new(0.7, 1.6, 1.6)), at(Vector3.new(0, topY + 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), mutationInfo and hatColor or Color3.fromRGB(255, 210, 40), Enum.Material.Neon)
		for i = 0, 3 do
			local angle = math.rad(i * 90 + 45)
			newPart(model, "CrownSpike", Enum.PartType.Ball, sized(Vector3.new(0.4, 0.4, 0.4)), at(Vector3.new(math.cos(angle) * 0.65, topY + 0.8, math.sin(angle) * 0.65)), WHITE, Enum.Material.Neon)
		end
	else
		newPart(model, "CapBase", Enum.PartType.Block, sized(Vector3.new(1.1, 0.5, 1.1)), at(Vector3.new(0, topY + 0.2, 0)), DARK)
		newPart(model, "CapBoard", Enum.PartType.Block, sized(Vector3.new(2.0, 0.15, 2.0)), at(Vector3.new(0, topY + 0.5, 0)) * CFrame.Angles(0, math.rad(45), 0), hatColor, hatMaterial)
		newPart(model, "CapTassel", Enum.PartType.Ball, sized(Vector3.new(0.3, 0.3, 0.3)), at(Vector3.new(0.75, topY + 0.35, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	end

	local prop = propFor(entry.name)
	if prop then
		local propModel = Instance.new("Model")
		propModel.Name = "Prop"
		propModel.Parent = model
		addProp(propModel, prop, at, scale, body, entry.accent)
	end

	-- Mutated brainrots sparkle in their mutation colour.
	if mutationInfo then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "MutationSparkle"
		sparkle.Color = ColorSequence.new(mutationInfo.color)
		sparkle.LightEmission = 1
		sparkle.Rate = 6
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Speed = NumberRange.new(1, 2)
		sparkle.Size = NumberSequence.new(0.35 * scale)
		sparkle.Parent = bodyPart
	end

	if not opts.noLabel then
		buildLabel(entry, mutation, opts.status, (topY + 0.6) * scale - body.y * scale).Parent = bodyPart
	end

	model.WorldPivot = origin
	model:SetAttribute("Uid", uid or "")
	model:SetAttribute("CatalogId", entry.id)
	model:SetAttribute("Mutation", mutation or "")
	model:SetAttribute("Rarity", entry.rarity)
	return model
end

-- Sets the label's third line, e.g. "BUY $60" or "HOLD [E] STEAL".
function BrainrotFactory.SetStatus(model, text, color)
	local body = model.PrimaryPart
	local label = body and body:FindFirstChild("Label")
	local line = label and label:FindFirstChild("StatusLine")
	if line then
		line.Text = text
		if color then
			line.TextColor3 = color
		end
	end
end

local function newPrompt(model, name, actionText, objectText, holdDuration, range)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = range
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = model.PrimaryPart
	return prompt
end

function BrainrotFactory.DescribeRecord(record)
	local entry = Catalog.ById[record.catalogId]
	local mutationText = record.mutation and (record.mutation .. " ") or ""
	return record.name .. " · " .. mutationText .. record.rarity .. " · " .. Config.FormatMoney(Catalog.MutatedIncome(entry, record.mutation)) .. "/s"
end

-- Press [E] Steal for thieves, Press [E] Sell for the owner. The client hides
-- whichever prompt is not for you (OwnerUserId / OwnerOnly attributes).
function BrainrotFactory.AttachBasePrompts(model, record, ownerUserId, ownerIsBot)
	local steal = newPrompt(model, "StealPrompt", "Steal", BrainrotFactory.DescribeRecord(record), Config.STEAL_HOLD, Config.STEAL_RANGE)
	steal:SetAttribute("OwnerUserId", ownerUserId)
	local sell = nil
	if not ownerIsBot then
		sell = newPrompt(model, "SellPrompt", "Sell", record.name .. " · +" .. Config.FormatMoney(BrainrotFactory.SellValue(record)), 0.8, 9)
		sell:SetAttribute("OwnerUserId", ownerUserId)
		sell:SetAttribute("OwnerOnly", true)
	end
	BrainrotFactory.SetStatus(model, "HOLD [E] STEAL", Color3.fromRGB(255, 110, 110))
	return steal, sell
end

function BrainrotFactory.AttachBuyPrompt(model, entry)
	return newPrompt(model, "BuyPrompt", "Buy", entry.name .. " · " .. Config.FormatMoney(entry.cost), 0, 12)
end

function BrainrotFactory.AttachGrabPrompt(model, objectText)
	return newPrompt(model, "GrabPrompt", "Grab", objectText, 0.2, 10)
end

function BrainrotFactory.SellValue(record)
	local entry = Catalog.ById[record.catalogId]
	return math.floor((entry and entry.cost or 0) * Config.SELL_REFUND)
end

return BrainrotFactory
