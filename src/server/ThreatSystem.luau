-- ThreatSystem: the two school dangers. Lunch Rush: after a countdown a
-- stampede of hungry students sweeps the yard north to south and tramples
-- whoever it reaches (high ground and your own classroom are safe), so
-- carriers drop their loot. Gagak Nakal: the crow thief circles an unlocked
-- classroom, warns its owner, then snatches a brainrot to the Big Tree nest.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local ThreatSystem = {}

local G
local rng = Random.new()
local WAVE_FROM, WAVE_TO = -195, 195

local function now()
	return Workspace:GetServerTimeNow()
end

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

-- The stampede: a line of blocky students in uniform plus a dust wall.
local function buildStampede()
	local model = Instance.new("Model")
	model.Name = "LunchRushStampede"
	local dust = part(model, "Dust", Vector3.new(390, 7, 3), CFrame.new(0, 3.5, 0), Color3.fromRGB(235, 220, 190), Enum.Material.SmoothPlastic)
	dust.Transparency = 0.55
	model.PrimaryPart = dust
	local shirt = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(230, 80, 80), Color3.fromRGB(90, 150, 255) }
	for i = -19, 19 do
		local x = i * 10 + rng:NextNumber(-2, 2)
		local color = shirt[(i % 3) + 1]
		part(model, "Runner", Vector3.new(2, 2.4, 1.2), CFrame.new(x, 2.6, -1.4), color)
		part(model, "RunnerHead", Vector3.new(1.4, 1.4, 1.4), CFrame.new(x, 4.5, -1.4), Color3.fromRGB(255, 205, 160))
		part(model, "RunnerLegs", Vector3.new(2, 1.4, 1), CFrame.new(x, 0.7, -1.4), Color3.fromRGB(40, 50, 90))
		local tray = part(model, "LunchTray", Vector3.new(1.8, 0.2, 1.2), CFrame.new(x, 3.6, -2.4), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
		tray.Name = "LunchTray"
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(230, 210, 170))
	emitter.Size = NumberSequence.new(3, 6)
	emitter.Transparency = NumberSequence.new(0.4, 1)
	emitter.Rate = 60
	emitter.Lifetime = NumberRange.new(1, 1.6)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Parent = dust
	return model
end

-- Safe spots: up high (pads, tower, tree, gym roof) or inside your own base.
local function isSafe(state, root)
	if root.Position.Y > 12 then
		return true
	end
	return state.baseIndex ~= nil and G.World.BaseAtPosition(root.Position) == state.baseIndex
end

local function trample(state, root)
	G.Carry.DropAll(state, root.Position)
	local velocity = Vector3.new(rng:NextNumber(-8, 8), Config.KNOCK_LIFT, 40)
	G.PullPush.Hit(nil, state, "push", velocity, 0.3)
	G.notify(state, "Trampled by the Lunch Rush!", Color3.fromRGB(255, 150, 90))
	G.fx("text", root.Position + Vector3.new(0, 4, 0), "TRAMPLED!", Color3.fromRGB(255, 150, 90))
end

function ThreatSystem.RunLunchRush()
	for seconds = Config.HAZARD_COUNTDOWN, 1, -1 do
		if seconds == Config.HAZARD_COUNTDOWN or seconds <= 5 then
			G.banner("LUNCH RUSH IN " .. seconds .. "s · RUN TO YOUR CLASSROOM OR HIGH GROUND!", Color3.fromRGB(255, 140, 40), 1.2)
		end
		task.wait(1)
	end
	G.fx("sound", "bell", Vector3.new(-60, 10, -120))
	G.banner("LUNCH RUSH!", Color3.fromRGB(255, 90, 40), Config.HAZARD_SWEEP_TIME)
	local stampede = buildStampede()
	stampede:PivotTo(CFrame.new(0, 0, WAVE_FROM))
	stampede.Parent = Workspace
	local hit = {}
	local started = now()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.min(1, (now() - started) / Config.HAZARD_SWEEP_TIME)
		local waveZ = WAVE_FROM + (WAVE_TO - WAVE_FROM) * alpha
		stampede:PivotTo(CFrame.new(0, 0, waveZ) * CFrame.new(0, math.abs(math.sin(alpha * 60)) * 0.4, 0))
		for _, state in pairs(G.State.All()) do
			local root = G.State.RootOf(state)
			if root and not hit[state] and math.abs(root.Position.Z - waveZ) < 5 then
				hit[state] = true
				if not isSafe(state, root) then
					trample(state, root)
				end
			end
		end
	end)
	task.wait(Config.HAZARD_SWEEP_TIME)
	connection:Disconnect()
	stampede:Destroy()
	for _, state in pairs(G.State.All()) do
		local root = G.State.RootOf(state)
		if root and not state.isBot and state.baseIndex and G.World.BaseAtPosition(root.Position) == state.baseIndex then
			G.Quests.OnEvent(state, "rush", 1)
		end
	end
	G.banner("The Lunch Rush passed. Back to stealing!", Color3.fromRGB(120, 255, 150), 3)
end

-- Gagak Nakal: a crow built from parts, flapping between the nest and a base.
local function buildCrow()
	local model = Instance.new("Model")
	model.Name = "GagakNakal"
	local body = part(model, "Body", Vector3.new(2.4, 2, 3.6), CFrame.new(), Color3.fromRGB(30, 30, 40))
	model.PrimaryPart = body
	part(model, "Head", Vector3.new(1.6, 1.6, 1.6), CFrame.new(0, 0.8, -2.2), Color3.fromRGB(35, 35, 45))
	part(model, "Beak", Vector3.new(0.5, 0.5, 1.2), CFrame.new(0, 0.6, -3.4), Color3.fromRGB(255, 190, 40))
	for _, side in ipairs({ -1, 1 }) do
		part(model, "Wing", Vector3.new(4, 0.3, 2.2), CFrame.new(side * 3, 0.3, 0), Color3.fromRGB(45, 45, 60))
		part(model, "Eye", Vector3.new(0.4, 0.4, 0.2), CFrame.new(side * 0.45, 1.1, -3.0), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(8, 0, 1.6, 0)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeTransparency = 0
	label.Text = "GAGAK NAKAL"
	label.Parent = gui
	gui.Parent = body
	return model
end

local function fly(crow, from, to, seconds)
	local started = now()
	while true do
		local alpha = math.min(1, (now() - started) / seconds)
		local position = from:Lerp(to, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * 18, 0)
		local flap = math.sin(now() * 14) * 0.25
		crow:PivotTo(CFrame.lookAt(position, position + (to - from) * Vector3.new(1, 0, 1)) * CFrame.Angles(0, 0, flap))
		if alpha >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

function ThreatSystem.RunCrowRaid()
	local candidates = {}
	local t = now()
	for _, state in pairs(G.State.All()) do
		if state.baseIndex and not G.State.IsLocked(state, t) and next(state.placed) then
			table.insert(candidates, state)
		end
	end
	if #candidates == 0 then
		return
	end
	-- Real students first: the crow is a threat for them, not for bots.
	table.sort(candidates, function(a, b)
		return (a.isBot and 1 or 0) < (b.isBot and 1 or 0)
	end)
	local victim = candidates[1]
	if not candidates[1].isBot then
		local players = {}
		for _, state in ipairs(candidates) do
			if not state.isBot then
				table.insert(players, state)
			end
		end
		victim = players[rng:NextInteger(1, #players)]
	end
	local base = G.World.GetBase(victim.baseIndex)
	local world = G.World.GetWorld()
	G.banner("GAGAK NAKAL IS FLYING TO " .. string.upper(victim.name) .. "'S CLASSROOM!", Color3.fromRGB(200, 80, 255), 5)
	if not victim.isBot then
		G.notify(victim, "The crow is coming! LOCK [L] your classroom NOW!", Color3.fromRGB(255, 90, 90))
		G.fx("sound", "alarm", nil, victim)
	end
	local crow = buildCrow()
	crow:PivotTo(CFrame.new(world.treeTop + Vector3.new(0, 4, 0)))
	crow.Parent = Workspace
	fly(crow, world.treeTop + Vector3.new(0, 4, 0), base.center + Vector3.new(0, 10, 0), 8)
	-- Re-check everything after the flight: the base may be locked, the
	-- owner gone, or the brainrot already stolen or sold.
	local target = nil
	if G.State.Get(victim.key) == victim and victim.baseIndex == base.index and not G.State.IsLocked(victim, now()) then
		local best = nil
		for _, record in pairs(victim.placed) do
			if record.status == "placed" and (not best or Config.RARITY_RANK[record.rarity] > Config.RARITY_RANK[best.rarity]) then
				best = record
			end
		end
		target = best
	end
	if not target then
		G.banner("Gagak Nakal found nothing to take!", Color3.fromRGB(120, 255, 150), 3)
		fly(crow, base.center + Vector3.new(0, 10, 0), world.treeTop + Vector3.new(0, 4, 0), 6)
		crow:Destroy()
		return
	end
	G.Carry.ClearPrompts(target)
	victim.placed[target.pedestal.id] = nil
	target.owner = nil
	target.pedestal = nil
	target.status = "crow"
	G.State.Changed(victim)
	local beak = crow.PrimaryPart
	local carried = target.model
	local connection = RunService.Heartbeat:Connect(function()
		if carried.Parent then
			carried:PivotTo(beak.CFrame * CFrame.new(0, -4.5, 0))
		end
	end)
	G.banner("GAGAK NAKAL STOLE " .. string.upper(target.name) .. "! IT'S IN THE BIG TREE NEST!", Color3.fromRGB(200, 80, 255), 5)
	fly(crow, base.center + Vector3.new(0, 10, 0), world.treeTop + Vector3.new(0, 4, 0), 8)
	connection:Disconnect()
	crow:Destroy()
	G.Carry.Drop(target, world.nestDrop, victim)
end

function ThreatSystem.Init(context)
	G = context
	task.spawn(function()
		while true do
			task.wait(Config.HAZARD_INTERVAL - Config.HAZARD_COUNTDOWN)
			ThreatSystem.RunLunchRush()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.CROW_INTERVAL)
			local ok, err = pcall(ThreatSystem.RunCrowRaid)
			if not ok then
				warn("Crow raid failed: " .. tostring(err))
			end
		end
	end)
end

return ThreatSystem
