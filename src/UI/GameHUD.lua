--[[
	GameHUD.lua
	Master HUD that wires together all UI components:
	  - DiceDisplay (centered dice visualization)
	  - CoinCounter (coin total display)
	  - RollButton (centered below dice, triggers roll)
	  - ShopButton (top-right icon, toggles ShopOverlay)

	Parent hierarchy:
	  ScreenGui "GameHUD"
	    ├─ DiceDisplay frame
	    ├─ CoinCounter frame
	    ├─ RollButton (TextButton)
	    ├─ ShopButton (TextButton)
	    └─ ShopOverlay frame (initially hidden)

	Usage:
	  local GameHUD = require(ReplicatedStorage.UI.GameHUD)
	  GameHUD.create(playerGui)  -- parents the ScreenGui under PlayerGui
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local RollController = require(ReplicatedStorage.Client.Controllers.RollController)

local DiceDisplay = require(ReplicatedStorage.UI.DiceDisplay)
local CoinCounter = require(ReplicatedStorage.UI.CoinCounter)
local ShopOverlay = require(ReplicatedStorage.UI.ShopOverlay)

local GameHUD = {}

-- ── Layout tokens ──────────────────────────────────────────────
-- Centered on screen. DiceDisplay occupies roughly a 300×300 box;
-- RollButton sits directly below it.
local ROLL_BTN_WIDTH = 200
local ROLL_BTN_HEIGHT = 60
local ROLL_BTN_OFFSET_Y = 180 -- pixels below the dice box center

local SHOP_BTN_SIZE = 40
local SHOP_BTN_MARGIN = 16 -- inset from top-right corner

-- ── Color palette ──────────────────────────────────────────────
local COLOR_ROLL_IDLE = Color3.fromRGB(50, 120, 50)
local COLOR_ROLL_COOLDOWN = Color3.fromRGB(40, 40, 40)
local COLOR_SHOP_BG = Color3.fromRGB(80, 80, 80)
local COLOR_TEXT = Color3.new(1, 1, 1)

-- ── Cooldown state ─────────────────────────────────────────────
local isOnCooldown = false

-- ── ScreenGui ──────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "GameHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ── Roll button (centered below dice display) ──────────────────
local rollBtn = Instance.new("TextButton")
rollBtn.Name = "RollButton"
rollBtn.Size = UDim2.new(0, ROLL_BTN_WIDTH, 0, ROLL_BTN_HEIGHT)
rollBtn.Position = UDim2.new(0.5, -ROLL_BTN_WIDTH / 2, 0.5, ROLL_BTN_OFFSET_Y)
rollBtn.AnchorPoint = Vector2.new(0, 0)
rollBtn.BackgroundColor3 = COLOR_ROLL_IDLE
rollBtn.Text = "ROLL"
rollBtn.TextColor3 = COLOR_TEXT
rollBtn.Font = Enum.Font.GothamBold
rollBtn.TextSize = 24
rollBtn.AutoButtonColor = true
rollBtn.Parent = gui

-- Rounded corners for roll button
local rollCorner = Instance.new("UICorner")
rollCorner.CornerRadius = UDim.new(0, 8)
rollCorner.Parent = rollBtn

-- ── Shop button (top-right corner) ─────────────────────────────
local shopBtn = Instance.new("TextButton")
shopBtn.Name = "ShopButton"
shopBtn.Size = UDim2.new(0, SHOP_BTN_SIZE, 0, SHOP_BTN_SIZE)
shopBtn.Position = UDim2.new(1, -(SHOP_BTN_SIZE + SHOP_BTN_MARGIN), 0, SHOP_BTN_MARGIN)
shopBtn.BackgroundColor3 = COLOR_SHOP_BG
shopBtn.Text = "S"
shopBtn.TextColor3 = COLOR_TEXT
shopBtn.Font = Enum.Font.GothamBold
shopBtn.TextSize = 18
shopBtn.AutoButtonColor = true
shopBtn.Parent = gui

-- Rounded corners for shop button
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 8)
shopCorner.Parent = shopBtn

-- ── Public API ─────────────────────────────────────────────────

--- Build the full HUD and parent it under `parent` (typically PlayerGui).
--- Creates sub-components (DiceDisplay, CoinCounter, ShopOverlay) and
--- wires button callbacks to the RollController.
--- @param parent Instance  The ScreenGui's parent (PlayerGui).
--- @return ScreenGui       The master GameHUD ScreenGui.
function GameHUD.create(parent)
	-- Instantiate sub-components inside the master GUI.
	DiceDisplay.create(gui)
	CoinCounter.create(gui)
	ShopOverlay.create(gui)

	-- ── Roll button callback ─────────────────────────────────
	rollBtn.MouseButton1Click:Connect(function()
		if isOnCooldown then
			return
		end
		RollController.requestRoll()
	end)

	-- ── Shop button callback ─────────────────────────────────
	shopBtn.MouseButton1Click:Connect(function()
		if ShopOverlay.isOpen() then
			ShopOverlay.close()
		else
			local state = RollController.getGameState()
			ShopOverlay.open(state.coins, {})
		end
	end)

	-- ── Roll result handler ──────────────────────────────────
	RollController.onRollResult(function(result)
		-- Trigger dice animation (critical glow if applicable).
		if result.isCritical then
			DiceDisplay.playCriticalGlow()
		end
		DiceDisplay.playRollAnimation()

		-- Show coin earned popup.
		CoinCounter.showPopup(result.coinsEarned)

		-- Enter cooldown state — disable button visually.
		isOnCooldown = true
		rollBtn.BackgroundColor3 = COLOR_ROLL_COOLDOWN
		rollBtn.Text = "COOLDOWN"
		rollBtn.AutoButtonColor = false

		-- Exit cooldown after the configured duration.
		task.delay(Constants.GAME_CONFIG.rollCooldown, function()
			isOnCooldown = false
			rollBtn.BackgroundColor3 = COLOR_ROLL_IDLE
			rollBtn.Text = "ROLL"
			rollBtn.AutoButtonColor = true
		end)
	end)

	-- Parent the master GUI into the player's PlayerGui.
	gui.Parent = parent
	return gui
end

return GameHUD
