--[[
	DiceDisplay.lua
	Center-screen dice display UI for the D20 idle dice game.
	Renders owned dice in a grid inside a fixed 300×300 box.
	Roll spins all dice; natural 20 triggers a gold glow.

	Parented under StarterGui via Rojo (src/UI/ → StarterGui).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)

-- Design tokens (from DESIGN.md)
local BOX_SIZE = 300
local SPIN_DURATION = 0.5
local GLOW_DURATION = 1.0
local GLOW_COLOR = Color3.fromRGB(255, 215, 0) -- gold
local SCALE_MIN = 0.4
local SCALE_STEP = 0.067 -- per additional die beyond the first

-- Dice sprite asset ID (replace with uploaded asset ID in production)
-- The D20.hex sprite is uploaded as an Image asset in Roblox Studio.
-- For now we use a placeholder decal ID that will be swapped after upload.
local DICE_SPRITE_ID = "rbxassetid://0" -- placeholder — set after asset upload

local DiceDisplay = {}

-- Internal state
local gui: ScreenGui? = nil
local displayFrame: Frame? = nil
local diceLabels: { ImageLabel } = {}
local isAnimating = false

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

--- Calculate scale factor for a given dice count.
--- 1 die = 100%, 5 dice = 60%, 10 dice = 40%.
local function computeScale(count: number): number
	return math.max(SCALE_MIN, 1 - (count - 1) * SCALE_STEP)
end

--- Build a grid layout for `count` items inside a square box.
--- Returns columns, rows, and cell size in pixels.
local function computeGrid(count: number): (number, number, number)
	local cols = math.ceil(math.sqrt(count))
	local rows = math.ceil(count / cols)
	local cellSize = BOX_SIZE / math.max(cols, rows)
	return cols, rows, cellSize
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Create the ScreenGui and attach it to the given parent (typically StarterGui).
function DiceDisplay.create(parent: Instance): ScreenGui
	if gui then
		-- Already created; re-parent if needed
		gui.Parent = parent
		return gui
	end

	-- ScreenGui
	gui = Instance.new("ScreenGui")
	gui.Name = "DiceDisplay"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10 -- above base UI

	-- Center frame (fixed 300×300)
	displayFrame = Instance.new("Frame")
	displayFrame.Name = "DiceFrame"
	displayFrame.Size = UDim2.new(0, BOX_SIZE, 0, BOX_SIZE)
	displayFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	displayFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	displayFrame.BackgroundTransparency = 1
	displayFrame.Parent = gui

	gui.Parent = parent
	return gui
end

--- Update the displayed dice list.
--- `diceList` is an array of DiceInfo (from Types.luau) representing owned dice.
--- `isCritical` adds the gold glow to every die.
function DiceDisplay.updateDice(diceList: { any }, isCritical: boolean?)
	if not displayFrame then
		warn("[DiceDisplay] Call DiceDisplay.create(parent) first")
		return
	end

	-- Clear previous dice
	for _, label in ipairs(diceLabels) do
		if label then
			label:Destroy()
		end
	end
	table.clear(diceLabels)

	local count = #diceList
	if count == 0 then
		return
	end

	local scale = computeScale(count)
	local cols, rows, cellSize = computeGrid(count)
	local scaledSize = cellSize * scale

	for i, dice in ipairs(diceList) do
		local label = Instance.new("ImageLabel")
		label.Name = "Die_" .. i
		label.Size = UDim2.new(0, scaledSize, 0, scaledSize)
		label.BackgroundTransparency = 1
		label.Image = DICE_SPRITE_ID
		label.ImageColor3 = dice.color or Color3.fromRGB(255, 255, 255)
		label.ScaleType = Enum.ScaleType.Fit
		label.AnchorPoint = Vector2.new(0.5, 0.5)

		-- Grid position: center die in its cell
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local cellCenterX = col * cellSize + cellSize / 2
		local cellCenterY = row * cellSize + cellSize / 2
		label.Position = UDim2.new(0, cellCenterX, 0, cellCenterY)

		label.Parent = displayFrame
		table.insert(diceLabels, label)
	end

	-- If critical, glow immediately
	if isCritical then
		DiceDisplay.playCriticalGlow()
	end
end

--- Play the roll spin animation on all displayed dice.
--- Calls `callback` when the animation completes (after SPIN_DURATION seconds).
function DiceDisplay.playRollAnimation(callback: (() -> ())?)
	if isAnimating then
		return -- prevent overlapping rolls
	end
	if #diceLabels == 0 then
		if callback then
			callback()
		end
		return
	end

	isAnimating = true

	local completedCount = 0
	local totalCount = #diceLabels

	for _, label in ipairs(diceLabels) do
		local tween = TweenService:Create(
			label,
			TweenInfo.new(
				SPIN_DURATION,
				Enum.EasingStyle.Cubic,
				Enum.EasingDirection.Out,
				0, -- repeatCount
				false, -- reverses
				0 -- delayTime
			),
			{ Rotation = 360 }
		)

		tween:Play()

		tween.Completed:Connect(function()
			label.Rotation = 0 -- reset to avoid cumulative drift
			completedCount += 1

			if completedCount >= totalCount then
				isAnimating = false
				if callback then
					callback()
				end
			end
		end)
	end
end

--- Play the critical glow effect on all displayed dice.
--- A gold ImageLabel overlays each die and fades out over GLOW_DURATION.
function DiceDisplay.playCriticalGlow()
	for _, label in ipairs(diceLabels) do
		local glow = Instance.new("ImageLabel")
		glow.Name = "CriticalGlow"
		-- 120% size, centered (overflows by 10% each side)
		glow.Size = UDim2.new(1.2, 0, 1.2, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.BackgroundTransparency = 1
		glow.Image = DICE_SPRITE_ID
		glow.ImageColor3 = GLOW_COLOR
		glow.ImageTransparency = 0.5
		glow.ScaleType = Enum.ScaleType.Fit
		glow.ZIndex = label.ZIndex + 1
		glow.Parent = label

		-- Fade out
		local fadeTween = TweenService:Create(
			glow,
			TweenInfo.new(GLOW_DURATION, Enum.EasingStyle.Linear),
			{ ImageTransparency = 1 }
		)
		fadeTween:Play()

		fadeTween.Completed:Connect(function()
			glow:Destroy()
		end)
	end
end

--- Set the dice sprite asset ID (call after uploading D20.hex to Roblox).
function DiceDisplay.setSpriteAsset(assetId: string)
	DICE_SPRITE_ID = assetId
end

--- Clean up all dice and the GUI.
function DiceDisplay.destroy()
	for _, label in ipairs(diceLabels) do
		if label then
			label:Destroy()
		end
	end
	table.clear(diceLabels)

	if displayFrame then
		displayFrame:Destroy()
		displayFrame = nil
	end

	if gui then
		gui:Destroy()
		gui = nil
	end

	isAnimating = false
end

return DiceDisplay
