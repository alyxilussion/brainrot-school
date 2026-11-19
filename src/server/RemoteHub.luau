-- RemoteHub: creates every RemoteEvent the game uses, in one folder the
-- client can find. Client-to-server events carry player actions; the server
-- always validates them. Server-to-client events carry state and alerts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteHub = {}

-- Client -> server: the player asks to do something.
-- Only key-press actions travel by remote. Buying, grabbing and placing use
-- ClickDetectors, and stealing uses a ProximityPrompt: both fire on the
-- server directly, so they need no remote at all.
local REQUESTS = {
	"PullPlayer",
	"PushPlayer",
	"ToggleLock",
	"DoRebirth",
	"BuyUpgrade",
}

-- Server -> client: the server tells the player something changed.
local BROADCASTS = {
	"StateUpdate",
	"Notify",
	"HazardAlert",
	"CrowAlert",
}

local remotes = nil

function RemoteHub.Build()
	if remotes then
		return remotes
	end
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotRemotes"
	folder.Parent = ReplicatedStorage

	remotes = {}
	for _, name in ipairs(REQUESTS) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		remotes[name] = event
	end
	for _, name in ipairs(BROADCASTS) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		remotes[name] = event
	end
	return remotes
end

function RemoteHub.Get(name)
	return remotes and remotes[name] or nil
end

return RemoteHub
