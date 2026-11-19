-- Bootstrap for Brainrot School: Enchanted Academy.
-- Builds the remotes, builds the world from code, wires the systems together,
-- starts every loop, and hands each joining student a classroom. The server
-- owns all state; the client only renders and asks.

local Players = game:GetService("Players")

local RemoteHub = require(script.RemoteHub)
local WorldBuilder = require(script.WorldBuilder)
local PlayerState = require(script.PlayerState)
local Spawner = require(script.Spawner)
local CarrySystem = require(script.CarrySystem)
local StealSystem = require(script.StealSystem)
local PullPushSystem = require(script.PullPushSystem)
local QuestSystem = require(script.QuestSystem)
local HazardSystem = require(script.HazardSystem)
local CrowThiefSystem = require(script.CrowThiefSystem)
local RebirthSystem = require(script.RebirthSystem)
local UpgradeSystem = require(script.UpgradeSystem)
local LockSystem = require(script.LockSystem)
local IncomeTicker = require(script.IncomeTicker)
local SitSystem = require(script.SitSystem)
local GachaSystem = require(script.GachaSystem)
local FuseSystem = require(script.FuseSystem)

-- Order matters: remotes first (systems fetch them on use), then the world
-- (systems read bases and pads from it), then the wiring, then the loops.
local remotes = RemoteHub.Build()
WorldBuilder.Build()

-- A placed brainrot gets its steal prompt from StealSystem, wired here so
-- CarrySystem never has to require StealSystem back (no require cycle).
CarrySystem.OnPlaced = StealSystem.CreatePrompt
Spawner.RegisterBuyHandler(CarrySystem.TryBuyParade)
Spawner.RegisterGrabHandler(CarrySystem.TryGrabHighPad)

Spawner.Start()
CarrySystem.Start()
HazardSystem.Start()
CrowThiefSystem.Start()
IncomeTicker.Start()
SitSystem.Start()
GachaSystem.Start()
FuseSystem.Start()

-- Key-press actions arrive by remote; clicks and prompts fire server-side.
remotes.PullPlayer.OnServerEvent:Connect(function(player)
	PullPushSystem.TryPull(player)
end)
remotes.PushPlayer.OnServerEvent:Connect(function(player)
	PullPushSystem.TryPush(player)
end)
remotes.ToggleLock.OnServerEvent:Connect(function(player)
	LockSystem.TryToggleLock(player)
end)
remotes.DoRebirth.OnServerEvent:Connect(function(player)
	RebirthSystem.TryRebirth(player)
end)
remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	UpgradeSystem.TryBuyUpgrade(player, upgradeId)
end)
remotes.RollGacha.OnServerEvent:Connect(function(player)
	GachaSystem.TryRoll(player)
end)
remotes.FuseBrainrots.OnServerEvent:Connect(function(player, pedestalIds)
	FuseSystem.TryFuse(player, pedestalIds)
end)

local function firstFreeBase()
	for _, base in ipairs(WorldBuilder.GetBases()) do
		if not base.owner then
			return base
		end
	end
	return nil
end

local function onPlayerAdded(player)
	local base = firstFreeBase() or WorldBuilder.GetBase(1)
	local state = PlayerState.Create(player, base.index)
	WorldBuilder.SetBaseOwner(base, player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = UpgradeSystem.GetWalkSpeed(state)
	end)
	-- CharacterAutoLoads is off in the project, so the server loads the
	-- character once the student's record and classroom exist.
	player:LoadCharacter()
	task.delay(1, function()
		if PlayerState.Get(player) then
			PlayerState.PushUpdate(state)
		end
	end)
end

local function onPlayerRemoving(player)
	local state = PlayerState.Get(player)
	CarrySystem.CleanupPlayer(player)
	if state then
		local base = WorldBuilder.GetBase(state.baseIndex)
		if base and base.owner == player then
			base.owner = nil
			WorldBuilder.SetBaseLockVisual(base, false)
			local label = base.signGui:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = "CLASSROOM " .. base.index
			end
		end
	end
	PlayerState.Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
-- Studio playtests sometimes start with a player already in the game.
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("Brainrot School is open for students.")
