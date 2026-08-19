--[[
    ShopService.test.lua
    Unit tests for shop pricing logic derived from Constants.luau.
    No ShopService module exists yet — these tests verify the pricing
    contract that any future ShopService must satisfy.
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

-- ── Constants (mirrors Constants.luau) ──────────────────────────────────────
local SHOP_CONFIG = {
    basePrice = 100,
    priceMultiplier = 2.5,
}

local DICE_TYPES = {
    { name = "Wooden D20",    cost = 0,     multiplier = 1.0 },
    { name = "Stone D20",     cost = 100,   multiplier = 1.1 },
    { name = "Iron D20",      cost = 250,   multiplier = 1.2 },
    { name = "Gold D20",      cost = 600,   multiplier = 1.4 },
    { name = "Emerald D20",   cost = 1500,  multiplier = 1.6 },
    { name = "Ruby D20",      cost = 4000,  multiplier = 1.9 },
    { name = "Diamond D20",   cost = 10000, multiplier = 2.3 },
    { name = "Obsidian D20",  cost = 25000, multiplier = 2.8 },
    { name = "Cosmic D20",    cost = 60000, multiplier = 3.5 },
    { name = "Legendary D20", cost = 150000,multiplier = 4.5 },
    { name = "Mythic D20",    cost = 400000,multiplier = 6.0 },
}

-- ── Mock ShopService (pricing formula) ──────────────────────────────────────
local ShopService = {}

-- Compute the expected price for tier index i (1-based, tier 0 = Wooden = free).
function ShopService.getPrice(tierIndex)
    if tierIndex <= 1 then return 0 end
    return math.floor(SHOP_CONFIG.basePrice * SHOP_CONFIG.priceMultiplier ^ (tierIndex - 2))
end

-- Check whether a player can afford a given tier.
function ShopService.canAfford(playerCoins, tierIndex)
    local price = ShopService.getPrice(tierIndex)
    return playerCoins >= price, price
end

-- ── Tests ───────────────────────────────────────────────────────────────────

test("tier 0 (Wooden) costs 0", function()
    assert_eq(ShopService.getPrice(1), 0, "Wooden D20 price ")
end)

test("tier 1 (Stone) costs basePrice (100)", function()
    assert_eq(ShopService.getPrice(2), 100, "Stone D20 price ")
end)

test("tier 2 (Iron) costs floor(100 × 2.5^1) = 250", function()
    assert_eq(ShopService.getPrice(3), 250, "Iron D20 price ")
end)

test("exponential growth: each tier costs more than previous", function()
    for i = 2, #DICE_TYPES do
        local prev = ShopService.getPrice(i)
        local curr = ShopService.getPrice(i + 1)
        if curr <= prev then
            error(string.format(
                "tier %d price (%d) should exceed tier %d (%d)",
                i + 1, curr, i, prev
            ))
        end
    end
end)

test("prices match Constants.DICE_TYPES costs", function()
    for i, dice in ipairs(DICE_TYPES) do
        local computed = ShopService.getPrice(i)
        assert_eq(computed, dice.cost, dice.name .. " price mismatch ")
    end
end)

test("canAfford: sufficient coins returns true", function()
    local canBuy, price = ShopService.canAfford(500, 3) -- Iron D20 costs 250
    assert_eq(canBuy, true, "should afford ")
    assert_eq(price, 250, "price ")
end)

test("canAfford: insufficient coins returns false", function()
    local canBuy, price = ShopService.canAfford(50, 3) -- Iron D20 costs 250
    assert_eq(canBuy, false, "should not afford ")
    assert_eq(price, 250, "price ")
end)

test("canAfford: exact coins returns true", function()
    local canBuy = ShopService.canAfford(250, 3)
    assert_eq(canBuy, true, "exact match should afford ")
end)

test("canAfford: zero coins cannot buy anything except Wooden", function()
    local canBuyWooden = ShopService.canAfford(0, 1)
    assert_eq(canBuyWooden, true, "free tier ")

    local canBuyStone = ShopService.canAfford(0, 2)
    assert_eq(canBuyStone, false, "paid tier with 0 coins ")
end)

test("multiplier increases with tier", function()
    for i = 2, #DICE_TYPES do
        if DICE_TYPES[i].multiplier <= DICE_TYPES[i - 1].multiplier then
            error(string.format(
                "%s multiplier (%.1f) should exceed %s (%.1f)",
                DICE_TYPES[i].name, DICE_TYPES[i].multiplier,
                DICE_TYPES[i - 1].name, DICE_TYPES[i - 1].multiplier
            ))
        end
    end
end)

-- ── Summary ─────────────────────────────────────────────────────────────────
print(string.format("\nShopService: %d passed, %d failed", passCount, failCount))
if failCount > 0 then
    error(string.format("ShopService: %d test(s) failed", failCount))
end
