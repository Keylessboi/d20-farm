--[[
    CoinService.lua
    Server-side service that manages player coin balances.

    Responsibilities:
    - Track per-player coin balances in an in-memory dictionary
    - Add coins (e.g., from dice rolls, rewards)
    - Deduct coins (e.g., for shop purchases)
    - Notify clients of balance changes via Remotes.CoinUpdated
    - Clean up data when players leave to prevent memory leaks

    This is an in-memory-only implementation (no DataStore persistence).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CoinService = {}

-- In-memory dictionary: [userId] = number
-- Stores each player's current coin balance.
local playerCoins = {}

--[[
    addCoins(player, amount)
    Adds coins to the player's balance and fires CoinUpdated to the client.

    @param player Player - The player to add coins to
    @param amount number - The number of coins to add (must be positive)
    @return number - The player's new coin balance
]]
function CoinService.addCoins(player, amount)
    assert(amount > 0, "Amount must be positive")
    local userId = player.UserId
    playerCoins[userId] = (playerCoins[userId] or 0) + amount
    Remotes.CoinUpdated:FireClient(player, playerCoins[userId])
    return playerCoins[userId]
end

--[[
    getCoins(player)
    Returns the player's current coin balance.

    @param player Player - The player to query
    @return number - The player's current coin count (0 if no record)
]]
function CoinService.getCoins(player)
    return playerCoins[player.UserId] or 0
end

--[[
    deductCoins(player, amount)
    Deducts coins from the player's balance if they have enough.
    Fires CoinUpdated on success. Returns false on insufficient funds.

    @param player Player - The player to deduct coins from
    @param amount number - The number of coins to deduct
    @return boolean - true if deduction succeeded, false if insufficient funds
]]
function CoinService.deductCoins(player, amount)
    local userId = player.UserId
    local current = playerCoins[userId] or 0
    if current < amount then
        return false
    end
    playerCoins[userId] = current - amount
    Remotes.CoinUpdated:FireClient(player, playerCoins[userId])
    return true
end

-- Clean up when player leaves to prevent memory leaks
Players.PlayerRemoving:Connect(function(player)
    playerCoins[player.UserId] = nil
end)

return CoinService
