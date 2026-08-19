--[[
	Constants.luau
	Shared game configuration for D20 Idle Dice Game.
	Defines dice tiers, shop settings, gameplay parameters, and remote event names.
	Used by both server and client via ReplicatedStorage.Shared.Constants.
]]

local Constants = {}

-- Dice tiers: each entry defines a purchasable dice with visual theme, cost, and reward multiplier.
-- Tier 0 (Wooden) is the starter dice and costs nothing.
Constants.DICE_TYPES = {
	{ name = "Wooden D20",    color = Color3.fromRGB(139, 90, 43),   cost = 0,    multiplier = 1.0 },
	{ name = "Stone D20",     color = Color3.fromRGB(128, 128, 128), cost = 100,  multiplier = 1.1 },
	{ name = "Iron D20",      color = Color3.fromRGB(192, 192, 192), cost = 250,  multiplier = 1.2 },
	{ name = "Gold D20",      color = Color3.fromRGB(255, 215, 0),   cost = 600,  multiplier = 1.4 },
	{ name = "Emerald D20",   color = Color3.fromRGB(80, 200, 120),  cost = 1500, multiplier = 1.6 },
	{ name = "Ruby D20",      color = Color3.fromRGB(220, 50, 50),   cost = 4000, multiplier = 1.9 },
	{ name = "Diamond D20",   color = Color3.fromRGB(180, 230, 255), cost = 10000,multiplier = 2.3 },
	{ name = "Obsidian D20",  color = Color3.fromRGB(30, 30, 40),    cost = 25000,multiplier = 2.8 },
	{ name = "Cosmic D20",    color = Color3.fromRGB(100, 80, 200),  cost = 60000,multiplier = 3.5 },
	{ name = "Legendary D20", color = Color3.fromRGB(255, 170, 0),   cost = 150000,multiplier = 4.5 },
	{ name = "Mythic D20",    color = Color3.fromRGB(255, 60, 120),  cost = 400000,multiplier = 6.0 },
}

-- Shop configuration for purchasing new dice tiers.
Constants.SHOP_CONFIG = {
	basePrice = 100,         -- Coins required for the first purchasable dice (Stone D20).
	priceMultiplier = 2.5,   -- Each subsequent tier costs this many times the previous tier.
}

-- Core gameplay parameters.
Constants.GAME_CONFIG = {
	criticalRollValue = 20,     -- The dice value that triggers a critical hit.
	criticalMultiplier = 2,     -- Coins earned on a critical hit are multiplied by this value.
	rollCooldown = 1.5,         -- Seconds a player must wait between rolls.
}

-- Remote event / function names shared between server and client.
Constants.REMOTES = {
	"RollDice",
	"RollResult",
	"CoinUpdated",
	"ShopUpdated",
	"DiceAdded",
}

return Constants
