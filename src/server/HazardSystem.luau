-- HazardSystem: the LUNCH RUSH! Every couple of minutes the lunch bell rings,
-- a 15-second countdown runs on every HUD, and then a stampede of students
-- and lunch trays sweeps the field from the academy to the far fence. Anyone
-- caught outside a classroom is knocked flat and drops what they were
-- carrying. Inside a classroom, you are safe — so the rush forces a dash home.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local RemoteHub = require(script.Parent.RemoteHub)
local PlayerState = require(script.Parent.PlayerState)
local CarrySystem = require(script.Parent.CarrySystem)
local WorldBuilder = require(script.Parent.WorldBuilder)

local HazardSystem = {}

local TRAY_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 200, 120),
	Color3.fromRGB(90, 150, 255),
	Color3.fromRGB(255, 150, 200),
}

local function broadcast(phase, secondsLeft)
	local event = RemoteHub.Get("HazardAlert")
	if event then
		event:FireAllClients(phase, secondsLeft)
	end
end

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

-- The stampede itself: a row of lunch trays and tumbling students sweeping
-- across the field, built from Parts and moved in one straight run.
local function runStampede()
	local wave = Instance.new("Folder")
	wave.Name = "LunchRushWave"
	wave.Parent = workspace
	local pieces = {}
	for i = 1, 14 do
		local tray = Instance.new("Part")
		tray.Name = "Tray"
		tray.Size = Vector3.new(5, 0.6, 3.5)
		tray.Color = TRAY_COLORS[(i - 1) % #TRAY_COLORS + 1]
		tray.Material = Enum.Material.SmoothPlastic
		tray.Anchored = true
		tray.CanCollide = false
		tray.Position = Vector3.new(-70 + (i - 1) * 10.5, Config.GROUND_Y + 3, -170)
		tray.Parent = wave
		table.insert(pieces, tray)
		local student = Instance.new("Part")
		student.Name = "Student"
		student.Size = Vector3.new(2, 3.5, 1.5)
		student.Color = TRAY_COLORS[i % #TRAY_COLORS + 1]
		student.Material = Enum.Material.SmoothPlastic
		student.Anchored = true
		student.CanCollide = false
		student.Position = Vector3.new(-70 + (i - 1) * 10.5, Config.GROUND_Y + 1.8, -166)
		student.Parent = wave
		table.insert(pieces, student)
	end
	local startTime = os.clock()
	while os.clock() - startTime < Config.HAZARD_SWEEP_TIME do
		local alpha = (os.clock() - startTime) / Config.HAZARD_SWEEP_TIME
		local z = -170 + alpha * 340
		for _, piece in ipairs(pieces) do
			piece.Position = Vector3.new(piece.Position.X, piece.Position.Y, z + (piece.Name == "Student" and 4 or 0))
		end
		task.wait(0.05)
	end
	wave:Destroy()
end

-- Knocks down every player caught outside a classroom and spills their carry.
local function tramplePlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.Get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if state and root then
			if WorldBuilder.BaseAtPosition(root.Position) == nil then
				root.AssemblyLinearVelocity = Vector3.new(0, 30, 40)
				CarrySystem.DropAllCarried(player)
				notify(player, "LUNCH RUSH! You were trampled — your brainrots dropped!", "alert")
			end
		end
	end
end

function HazardSystem.Start()
	task.spawn(function()
		while true do
			task.wait(Config.HAZARD_INTERVAL)
			-- Countdown on every HUD.
			for secondsLeft = Config.HAZARD_COUNTDOWN, 1, -1 do
				broadcast("countdown", secondsLeft)
				task.wait(1)
			end
			broadcast("rush", 0)
			tramplePlayers()
			runStampede()
			broadcast("clear", 0)
		end
	end)
end

return HazardSystem
