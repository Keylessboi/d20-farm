--!strict
-- D20 Farm - Constants
-- All magic numbers in one place

local Constants = {}

-- Dice
Constants.MAX_ROLL = 20
Constants.MIN_ROLL = 1
Constants.DICE_SIZE = 64 -- pixels per face
Constants.DICE_UPSCALE = 512 -- upload size (64x8 upscaled)

-- Animation
Constants.ROLL_DURATION = 1.5 -- seconds for spin animation
Constants.SPIN_SPEED = 720 -- degrees per second

-- Coins
Constants.COIN_BURST_COUNT = 20 -- particles per burst
Constants.COIN_BURST_DURATION = 1.5 -- seconds

-- Colors (Black & Gold dice aesthetic)
Constants.COLOR_GOLD = Color3.fromRGB(255, 215, 0)
Constants.COLOR_BLACK = Color3.fromRGB(20, 20, 20)
Constants.COLOR_DARK_BROWN = Color3.fromRGB(60, 40, 20)
Constants.COLOR_GREEN = Color3.fromRGB(34, 139, 34)
Constants.COLOR_CREAM = Color3.fromRGB(255, 253, 240)

-- UI
Constants.BUTTON_SIZE = UDim2.new(0, 200, 0, 60)
Constants.COUNTER_SIZE = UDim2.new(0, 300, 0, 50)

return Constants
