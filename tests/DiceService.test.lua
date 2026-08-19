--[[
    DiceService.test.lua
    Unit tests for DiceService.rollAllDice logic.
    Self-contained: inlines the dice-rolling formula so tests run outside Studio.
    Run: paste into Studio Command Bar, or require as ModuleScript.
]]

-- ── Test framework ──────────────────────────────────────────────────────────
local passCount = 0
local failCount = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passCount += 1
        print("PASS: " .. name)
    else
        failCount += 1
        print("FAIL: " .. name .. " — " .. tostring(err))
    end
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a))
    end
end

local function assert_range(val, min, max, msg)
    if val < min or val > max then
        error((msg or "") .. " expected " .. min .. "–" .. max .. ", got " .. val)
    end
end

-- ── Constants (mirrors Constants.luau) ──────────────────────────────────────
local GAME_CONFIG = {
    criticalRollValue = 20,
    criticalMultiplier = 2,
}

-- ── Mock DiceService (replicates actual rollAllDice logic) ──────────────────
local DiceService = {}

function DiceService.rollAllDice(diceOwned: { any }): any
    local result = {
        rolls = {},
        total = 0,
        isCritical = false,
        coinsEarned = 0,
    }

    if #diceOwned == 0 then
        return result
    end

    local sum = 0
    local totalMultiplier = 0

    for _, dice in ipairs(diceOwned) do
        local roll = math.random(1, 20)
        table.insert(result.rolls, roll)
        sum += roll
        totalMultiplier += dice.multiplier

        if roll == GAME_CONFIG.criticalRollValue then
            result.isCritical = true
        end
    end

    result.total = sum

    local averageMultiplier = totalMultiplier / #diceOwned
    local baseCoins = sum * averageMultiplier
    result.coinsEarned = math.floor(baseCoins * (result.isCritical and GAME_CONFIG.criticalMultiplier or 1))

    return result
end

-- ── Tests ───────────────────────────────────────────────────────────────────

test("1 die: returns single roll in [1,20]", function()
    local result = DiceService.rollAllDice({ { multiplier = 1.0 } })
    assert_eq(#result.rolls, 1, "rolls count ")
    assert_range(result.rolls[1], 1, 20, "single roll ")
end)

test("2 dice: sum in [2,40]", function()
    local result = DiceService.rollAllDice({
        { multiplier = 1.0 },
        { multiplier = 1.0 },
    })
    assert_eq(#result.rolls, 2, "rolls count ")
    assert_range(result.total, 2, 40, "two-dice sum ")
end)

test("empty input: returns zeroed result", function()
    local result = DiceService.rollAllDice({})
    assert_eq(result.total, 0, "total ")
    assert_eq(result.isCritical, false, "isCritical ")
    assert_eq(result.coinsEarned, 0, "coinsEarned ")
    assert_eq(#result.rolls, 0, "rolls length ")
end)

test("critical flag set when any roll hits 20", function()
    -- With 100 independent rolls the probability of never seeing a 20 is
    -- (19/20)^100 ≈ 0.6%, so this is reliable in practice.
    local found20 = false
    for _ = 1, 100 do
        local result = DiceService.rollAllDice({ { multiplier = 1.0 } })
        if result.isCritical then
            found20 = true
            break
        end
    end
    assert_eq(found20, true, "Should eventually roll a natural 20 ")
end)

test("non-critical coins use multiplier ×1", function()
    -- Roll many dice; with at least one non-critical run we can verify the formula.
    for _ = 1, 200 do
        local result = DiceService.rollAllDice({ { multiplier = 2.0 } })
        if not result.isCritical then
            -- For a single die: coinsEarned = floor(roll * 2.0 * 1)
            assert_eq(result.coinsEarned, math.floor(result.total * 2.0), "non-critical formula ")
            return  -- pass
        end
    end
    error("Could not produce a non-critical roll in 200 attempts")
end)

test("critical coins double the base amount", function()
    for _ = 1, 500 do
        local result = DiceService.rollAllDice({ { multiplier = 1.0 } })
        if result.isCritical then
            -- For single die: coinsEarned = floor(roll * 1.0 * 2)
            assert_eq(result.coinsEarned, math.floor(result.total * 2), "critical doubling ")
            return
        end
    end
    error("Could not roll a 20 in 500 attempts")
end)

test("multiplier averaging works with different die tiers", function()
    -- Two dice: multiplier 1.0 and 3.0 → average = 2.0
    -- Force non-critical by running many times until we get one
    for _ = 1, 200 do
        local result = DiceService.rollAllDice({
            { multiplier = 1.0 },
            { multiplier = 3.0 },
        })
        if not result.isCritical then
            local expected = math.floor(result.total * 2.0)
            assert_eq(result.coinsEarned, expected, "multiplier average ")
            return
        end
    end
    error("Could not produce a non-critical run in 200 attempts")
end)

-- ── Summary ─────────────────────────────────────────────────────────────────
print(string.format("\nDiceService: %d passed, %d failed", passCount, failCount))
if failCount > 0 then
    error(string.format("DiceService: %d test(s) failed", failCount))
end
