-- Remotes.lua
-- Shared module that creates and manages all RemoteEvent/RemoteFunction
-- instances used for client-server communication in the D20 idle dice game.
--
-- Server-authoritative design:
--   Client calls RollDice (RemoteFunction) to request a roll.
--   Server processes the roll and fires RollResult (RemoteEvent) back to the client.
--   Other events (CoinUpdated, ShopUpdated, DiceAdded) notify clients of state changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Create or get the Remotes folder
local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "Remotes"
    folder.Parent = ReplicatedStorage
end

-- Helper to create or get a remote
local function getOrCreate(className, name)
    local existing = folder:FindFirstChild(name)
    if existing then return existing end
    local remote = Instance.new(className)
    remote.Name = name
    remote.Parent = folder
    return remote
end

-- RollDice: Client calls server to request a roll (RemoteFunction)
Remotes.RollDice = getOrCreate("RemoteFunction", "RollDice")

-- RollResult: Server fires client with roll results (RemoteEvent)
Remotes.RollResult = getOrCreate("RemoteEvent", "RollResult")

-- CoinUpdated: Server fires client when coins change (RemoteEvent)
Remotes.CoinUpdated = getOrCreate("RemoteEvent", "CoinUpdated")

-- ShopUpdated: Server fires client when shop state changes (RemoteEvent)
Remotes.ShopUpdated = getOrCreate("RemoteEvent", "ShopUpdated")

-- DiceAdded: Server fires client when a new dice is purchased (RemoteEvent)
Remotes.DiceAdded = getOrCreate("RemoteEvent", "DiceAdded")

return Remotes
