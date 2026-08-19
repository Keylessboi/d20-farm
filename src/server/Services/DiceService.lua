--[[
    DiceService.luau
    Server-side authoritative dice rolling logic.
    Each owned die rolls 1-20; results are summed and coins calculated
    with an average-multiplier formula. Natural 20 doubles earnings.
    No remote events here — RollController handles client communication.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local DiceService = {}

--[[
    rollAllDice(diceOwned) -> RollResult

    Parameters:
        diceOwned: {DiceInfo}  — array of owned dice (already filtered).

    Returns:
        RollResult = {
            rolls: {number},   -- individual face values (1-20 each)
            total: number,     -- sum of all rolls
            isCritical: boolean, -- true if ANY roll hit natural 20
            coinsEarned: number, -- total coins (floored)
        }

    Coin formula:
        baseCoins = totalRolls * averageMultiplier
        finalCoins = baseCoins * (criticalMultiplier if isCritical else 1)
        Floored to integer.
]]
function DiceService.rollAllDice(diceOwned: { any }): any
    local result = {
        rolls = {},
        total = 0,
        isCritical = false,
        coinsEarned = 0,
    }

    -- Edge case: no dice owned yet — return empty result, not a crash.
    if #diceOwned == 0 then
        return result
    end

    local sum = 0
    local totalMultiplier = 0

    for _, dice in ipairs(diceOwned) do
        local roll = math.random(1, 20)
        table.insert(result.rolls, roll)
        sum = sum + roll
        totalMultiplier = totalMultiplier + dice.multiplier

        if roll == Constants.GAME_CONFIG.criticalRollValue then
            result.isCritical = true
        end
    end

    result.total = sum

    -- Coins = sum of rolls × average multiplier, doubled on critical.
    local averageMultiplier = totalMultiplier / #diceOwned
    local baseCoins = sum * averageMultiplier
    result.coinsEarned = math.floor(baseCoins * (result.isCritical and Constants.GAME_CONFIG.criticalMultiplier or 1))

    return result
end

return DiceService
