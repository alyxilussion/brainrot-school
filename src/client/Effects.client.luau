-- Effects: everything the world shows on this screen. The tether beam for
-- PULL, the shockwave for PUSH, floating words, sounds (built-in Roblox
-- sounds only, so they play for every reviewer), confetti, the Arena Drop
-- light, the clamped knockback on your own character, and Press [E] prompts
-- filtered to you: Steal on others' brainrots, Sell on your own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local SOUNDS = {
	pull = "rbxasset://sounds/swordlunge.wav",
	push = "rbxasset://sounds/swordlunge.wav",
	coin = "rbxasset://sounds/electronicpingshort.wav",
	quest = "rbxasset://sounds/electronicpingshort.wav",
	upgrade = "rbxasset://sounds/electronicpingshort.wav",
	rebirth = "rbxasset://sounds/electronicpingshort.wav",
	place = "rbxasset://sounds/button.wav",
	lock = "rbxasset://sounds/clickfast.wav",
	steal = "rbxasset://sounds/clickfast.wav",
	loose = "rbxasset://sounds/action_jump.mp3",
	knock = "rbxasset://sounds/action_jump.mp3",
	alarm = "rbxasset://sounds/uuhhh.mp3",
	bell = "rbxasset://sounds/electronicpingshort.wav",
}

local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalEffects"
fxFolder.Parent = Workspace

local function playSound(name, position)
	local id = SOUNDS[name]
	if not id then
		return
	end
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = name == "alarm" and 0.9 or 0.6
		sound.PlaybackSpeed = name == "rebirth" and 0.7 or (name == "quest" and 1.2 or 1)
		if position then
			local holder = Instance.new("Part")
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.Transparency = 1
			holder.Size = Vector3.new(0.2, 0.2, 0.2)
			holder.CFrame = CFrame.new(position)
			holder.Parent = fxFolder
			sound.RollOffMaxDistance = 140
			sound.Parent = holder
			Debris:AddItem(holder, 4)
		else
			sound.Parent = Workspace.CurrentCamera
			Debris:AddItem(sound, 4)
		end
		sound:Play()
	end)
end

local function floatingText(position, text, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = fxFolder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(8, 0, 2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 30)
	label.Parent = gui
	TweenService:Create(gui, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1.5)
end

-- PULL: an orange tether from the puller to the target.
local function tether(fromPart, toPart)
	if not (fromPart and toPart and fromPart.Parent and toPart.Parent) then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Parent = fromPart
	local a1 = Instance.new("Attachment")
	a1.Parent = toPart
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.8
	beam.Width1 = 0.4
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Segments = 12
	beam.CurveSize0 = 2
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 110, 40))
	beam.Parent = a0
	Debris:AddItem(a0, 0.45)
	Debris:AddItem(a1, 0.45)
	playSound("pull", toPart.Position)
end

-- PUSH: a blue ring that bursts out from the target.
local function shockwave(position)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(90, 190, 255)
	ring.Size = Vector3.new(0.3, 2, 2)
	ring.CFrame = CFrame.new(position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.2
	ring.Parent = fxFolder
	TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, 16, 16), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.5)
	playSound("push", position)
end

local function confetti(position)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = fxFolder
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 190, 255)),
	})
	emitter.Size = NumberSequence.new(0.5)
	emitter.Speed = NumberRange.new(12, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(60)
	Debris:AddItem(anchor, 2)
	playSound("quest", position)
end

-- Arena Drop: a column of light on the crest for a few seconds.
local function dropLight(position)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(190, 140, 255)
	beam.Transparency = 0.5
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(80, 6, 6)
	beam.CFrame = CFrame.new(position + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = fxFolder
	TweenService:Create(beam, TweenInfo.new(4), { Transparency = 1 }):Play()
	Debris:AddItem(beam, 4.2)
	confetti(position + Vector3.new(0, 3, 0))
end

remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "pull" then
		tether(a, b)
	elseif kind == "push" then
		if typeof(b) == "Instance" and b:IsA("BasePart") and b.Parent then
			shockwave(b.Position)
		end
	elseif kind == "text" then
		floatingText(a, b, c)
	elseif kind == "sound" then
		playSound(a, b)
	elseif kind == "confetti" then
		confetti(a)
	elseif kind == "drop" then
		dropLight(a)
	end
end)

-- Knockback on my own character: a short, clamped push the server asked for.
remotes:WaitForChild("Knockback").OnClientEvent:Connect(function(velocity, duration)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or typeof(velocity) ~= "Vector3" then
		return
	end
	if velocity.Magnitude > 75 then
		velocity = velocity.Unit * 75
	end
	duration = math.clamp(tonumber(duration) or 0.25, 0.05, 0.4)
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockAttachment"
	attachment.Parent = root
	local mover = Instance.new("LinearVelocity")
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	mover.VectorVelocity = velocity
	mover.MaxForce = root.AssemblyMass * 900
	mover.Parent = root
	Debris:AddItem(mover, duration)
	Debris:AddItem(attachment, duration)
	playSound("knock", nil)
end)

-- Press [E]: show Steal only on other people's brainrots, Sell only on mine.
local function filterPrompt(prompt)
	local ownerId = prompt:GetAttribute("OwnerUserId")
	if prompt.Name == "StealPrompt" then
		prompt.Enabled = ownerId ~= player.UserId
	elseif prompt.Name == "SellPrompt" then
		prompt.Enabled = ownerId == player.UserId
	end
end

local function watchPrompt(prompt)
	if prompt:IsA("ProximityPrompt") and (prompt.Name == "StealPrompt" or prompt.Name == "SellPrompt") then
		filterPrompt(prompt)
		prompt:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			filterPrompt(prompt)
		end)
	end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
	watchPrompt(descendant)
end
Workspace.DescendantAdded:Connect(watchPrompt)
