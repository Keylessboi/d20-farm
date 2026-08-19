--[[
    init.server.luau
    Server entry point for D20 idle dice game.
    Wires up DiceService, CoinService, and handles roll requests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DiceService = require(script.Parent.Services.DiceService)
local CoinService = require(script.Parent.Services.CoinService)

-- Handle roll requests from clients
Remotes.RollDice.OnServerInvoke = function(player)
    -- Get player's owned dice (for now, everyone has 1 Wooden D20)
    local ownedDice = {
        { name = "Wooden D20", color = Color3.fromRGB(139, 90, 43), cost = 0, multiplier = 1.0, owned = true }
    }

    -- Roll all dice
    local result = DiceService.rollAllDice(ownedDice)

    -- Add coins to player
    if result.coinsEarned > 0 then
        CoinService.addCoins(player, result.coinsEarned)
    end

    -- Fire result back to client
    Remotes.RollResult:FireClient(player, result)

    return result
end

-- Handle shop purchases
Remotes.ShopUpdated.OnServerEvent:Connect(function(player, diceIndex)
    -- TODO: Implement shop purchase logic
    -- For now, just print
    print(player.Name .. " wants to buy dice index: " .. tostring(diceIndex))
end)

print("D20 Farm server initialized!")
