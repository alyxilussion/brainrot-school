-- SitSystem: benches and swings in the schoolyard arena. Press [E] SIT to sit
-- down; press again, or jump, to stand. Sitting rests the student: the first
-- sit after the cooldown grants the Fresh buff, +10% income for 60 seconds.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local RemoteHub = require(script.Parent.RemoteHub)
local WorldBuilder = require(script.Parent.WorldBuilder)

local SitSystem = {}

local sitting = {} -- [player] = seat they are sitting on

local function notify(player, text, kind)
	local event = RemoteHub.Get("Notify")
	if event then
		event:FireClient(player, text, kind or "info")
	end
end

function SitSystem.ToggleSit(player, seat)
	local state = PlayerState.Get(player)
	if not state then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end
	if sitting[player] then
		-- Stand up: rise and step forward off the seat.
		sitting[player] = nil
		humanoid.Sit = false
		root.CFrame = root.CFrame + root.CFrame.LookVector * 3
		return
	end
	-- Sit down on this seat, facing the field.
	sitting[player] = seat
	root.CFrame = CFrame.lookAt(seat.sitPosition, seat.sitPosition + seat.sitLook)
	humanoid.Sit = true
	-- The Fresh buff, if its cooldown has passed.
	local now = os.clock()
	if now >= state.freshReadyAt then
		state.freshUntil = now + Config.SIT_BUFF_DURATION
		state.freshReadyAt = now + Config.SIT_COOLDOWN
		PlayerState.PushUpdate(state)
		notify(player, "Fresh! +10% income for 60s. Enjoy the rest!", "good")
	else
		notify(player, "You sit and rest. (Fresh buff recharges in " .. math.ceil(state.freshReadyAt - now) .. "s)", "info")
	end
	-- Jumping or being pushed off the seat stands the player back up.
	local connection
	connection = humanoid.Seated:Connect(function(active)
		if not active then
			if sitting[player] == seat then
				sitting[player] = nil
			end
			connection:Disconnect()
		end
	end)
	-- Dying while seated clears the seat too: without this, the first
	-- sit press after respawning would run the stand-up branch instead.
	humanoid.Died:Connect(function()
		if sitting[player] == seat then
			sitting[player] = nil
		end
	end)
end

function SitSystem.Start()
	for _, seat in ipairs(WorldBuilder.GetSeats()) do
		seat.prompt.Triggered:Connect(function(player)
			SitSystem.ToggleSit(player, seat)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		sitting[player] = nil
	end)
end

return SitSystem
