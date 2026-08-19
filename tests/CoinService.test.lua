--[[
    CoinService.test.lua
    Unit tests for CoinService coin-balance logic.
    Self-contained: replicates the in-memory balance tracking and
    addCoins / getCoins / deductCoins contracts without Roblox dependencies.
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

-- ── Mock CoinService (mirrors actual CoinService.lua logic) ─────────────────
local CoinService = {}
local playerCoins = {} -- [userId] = number

-- Reset state between tests to prevent cross-test contamination.
function CoinService._reset()
    table.clear(playerCoins)
end

function CoinService.addCoins(player, amount)
    assert(amount > 0, "Amount must be positive")
    local userId = player.UserId
    playerCoins[userId] = (playerCoins[userId] or 0) + amount
    return playerCoins[userId]
end

function CoinService.getCoins(player)
    return playerCoins[player.UserId] or 0
end

function CoinService.deductCoins(player, amount)
    local userId = player.UserId
    local current = playerCoins[userId] or 0
    if current < amount then
        return false
    end
    playerCoins[userId] = current - amount
    return true
end

-- ── Tests ───────────────────────────────────────────────────────────────────

test("addCoins: increases balance from zero", function()
    CoinService._reset()
    local player = { UserId = 1001 }
    local balance = CoinService.addCoins(player, 100)
    assert_eq(balance, 100, "balance after add ")
    assert_eq(CoinService.getCoins(player), 100, "getCoins after add ")
end)

test("addCoins: accumulates across multiple calls", function()
    CoinService._reset()
    local player = { UserId = 1002 }
    CoinService.addCoins(player, 50)
    CoinService.addCoins(player, 30)
    assert_eq(CoinService.getCoins(player), 80, "accumulated balance ")
end)

test("addCoins: rejects non-positive amount", function()
    CoinService._reset()
    local player = { UserId = 1003 }
    local ok = pcall(function()
        CoinService.addCoins(player, 0)
    end)
    assert_eq(ok, false, "zero amount should error ")

    ok = pcall(function()
        CoinService.addCoins(player, -10)
    end)
    assert_eq(ok, false, "negative amount should error ")
end)

test("getCoins: returns 0 for unknown player", function()
    CoinService._reset()
    local player = { UserId = 9999 }
    assert_eq(CoinService.getCoins(player), 0, "unknown player ")
end)

test("deductCoins: succeeds with sufficient funds", function()
    CoinService._reset()
    local player = { UserId = 2001 }
    CoinService.addCoins(player, 100)
    local success = CoinService.deductCoins(player, 40)
    assert_eq(success, true, "deduct result ")
    assert_eq(CoinService.getCoins(player), 60, "remaining balance ")
end)

test("deductCoins: fails on insufficient funds and leaves balance unchanged", function()
    CoinService._reset()
    local player = { UserId = 2002 }
    CoinService.addCoins(player, 50)
    local success = CoinService.deductCoins(player, 100)
    assert_eq(success, false, "should return false ")
    assert_eq(CoinService.getCoins(player), 50, "balance unchanged ")
end)

test("deductCoins: exact balance succeeds", function()
    CoinService._reset()
    local player = { UserId = 2003 }
    CoinService.addCoins(player, 200)
    local success = CoinService.deductCoins(player, 200)
    assert_eq(success, true, "exact deduction ")
    assert_eq(CoinService.getCoins(player), 0, "zero after exact ")
end)

test("deductCoins: from zero balance returns false", function()
    CoinService._reset()
    local player = { UserId = 2004 }
    local success = CoinService.deductCoins(player, 1)
    assert_eq(success, false, "deduct from zero ")
end)

test("multiple players tracked independently", function()
    CoinService._reset()
    local alice = { UserId = 3001 }
    local bob = { UserId = 3002 }
    CoinService.addCoins(alice, 500)
    CoinService.addCoins(bob, 200)
    CoinService.deductCoins(alice, 100)
    assert_eq(CoinService.getCoins(alice), 400, "alice ")
    assert_eq(CoinService.getCoins(bob), 200, "bob ")
end)

-- ── Summary ─────────────────────────────────────────────────────────────────
print(string.format("\nCoinService: %d passed, %d failed", passCount, failCount))
if failCount > 0 then
    error(string.format("CoinService: %d test(s) failed", failCount))
end
