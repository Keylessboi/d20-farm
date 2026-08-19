--[[
	DiceDisplay.lua
	Center-screen dice display UI for the D20 idle dice game.
	Renders owned dice in a grid inside a fixed 300×300 box.
	Roll spins all dice; natural 20 triggers a gold glow.

	Uses CuteDice sprite sheet (9 frames, 224x224 each, vertical strip).
	Colors: Black body + Gold numbers (default).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)

-- Design tokens
local BOX_SIZE = 300
local GLOW_DURATION = 1.0
local GLOW_COLOR = Color3.fromRGB(255, 215, 0) -- gold
local SCALE_MIN = 0.4
local SCALE_STEP = 0.067

-- CuteDice sprite sheet config
-- Upload CuteDice_Sheet.png (224x2016, 9 frames vertical) to Roblox
-- Replace this with your uploaded asset ID
local DICE_SPRITE_ID = "rbxassetid://REPLACE_WITH_UPLOADED_ID"
local FRAME_SIZE = 224
local TOTAL_FRAMES = 9
local ANIM_DURATION = 0.6

-- Black + Gold color scheme
local DEFAULT_DICE_COLOR = Color3.fromRGB(20, 20, 20) -- Black body

local DiceDisplay = {}

-- Internal state
local gui: ScreenGui? = nil
local displayFrame: Frame? = nil
local diceLabels: { ImageLabel } = {}
local isAnimating = false

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function computeScale(count: number): number
	return math.max(SCALE_MIN, 1 - (count - 1) * SCALE_STEP)
end

local function computeGrid(count: number): (number, number, number)
	local cols = math.ceil(math.sqrt(count))
	local rows = math.ceil(count / cols)
	local cellSize = BOX_SIZE / math.max(cols, rows)
	return cols, rows, cellSize
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function DiceDisplay.create(parent: Instance): ScreenGui
	if gui then
		gui.Parent = parent
		return gui
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "DiceDisplay"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10

	displayFrame = Instance.new("Frame")
	displayFrame.Name = "DiceFrame"
	displayFrame.Size = UDim2.new(0, BOX_SIZE, 0, BOX_SIZE)
	displayFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	displayFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	displayFrame.BackgroundTransparency = 1
	displayFrame.Parent = gui

	gui.Parent = parent

	-- Show default single die on creation
	DiceDisplay.updateDice({{ color = DEFAULT_DICE_COLOR }}, false)

	return gui
end

function DiceDisplay.updateDice(diceList: { any }, isCritical: boolean?)
	if not displayFrame then
		warn("[DiceDisplay] Call DiceDisplay.create(parent) first")
		return
	end

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
		label.ImageRectSize = Vector2.new(FRAME_SIZE, FRAME_SIZE)
		label.ImageRectOffset = Vector2.new(0, 0)
		label.ImageColor3 = dice.color or DEFAULT_DICE_COLOR
		label.ScaleType = Enum.ScaleType.Fit
		label.AnchorPoint = Vector2.new(0.5, 0.5)

		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local cellCenterX = col * cellSize + cellSize / 2
		local cellCenterY = row * cellSize + cellSize / 2
		label.Position = UDim2.new(0, cellCenterX, 0, cellCenterY)

		label.Parent = displayFrame
		table.insert(diceLabels, label)
	end

	if isCritical then
		DiceDisplay.playCriticalGlow()
	end
end

function DiceDisplay.playRollAnimation(callback: (() -> ())?)
	if isAnimating or #diceLabels == 0 then
		if callback then
			callback()
		end
		return
	end

	isAnimating = true
	local completedCount = 0

	for _, label in ipairs(diceLabels) do
		task.spawn(function()
			-- Cycle through all 9 frames for rolling animation
			for frame = 0, TOTAL_FRAMES - 1 do
				label.ImageRectOffset = Vector2.new(0, frame * FRAME_SIZE)

				-- Squash/stretch effect during spin
				local squash = 1
				if frame < 3 then
					squash = 1 - (frame * 0.05)
				elseif frame < 6 then
					squash = 0.9 + ((frame - 3) * 0.05)
				end

				local baseSize = scaledSize or 150
				label.Size = UDim2.new(0, baseSize * squash, 0, baseSize / squash)

				task.wait(ANIM_DURATION / TOTAL_FRAMES)
			end

			-- Landing frame (frame 0 = front face)
			label.ImageRectOffset = Vector2.new(0, 0)
			local baseSize = scaledSize or 150
			label.Size = UDim2.new(0, baseSize, 0, baseSize)

			completedCount += 1
			if completedCount >= #diceLabels then
				isAnimating = false
				if callback then
					callback()
				end
			end
		end)
	end
end

function DiceDisplay.playCriticalGlow()
	for _, label in ipairs(diceLabels) do
		local glow = Instance.new("ImageLabel")
		glow.Name = "CriticalGlow"
		glow.Size = UDim2.new(1.2, 0, 1.2, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.BackgroundTransparency = 1
		glow.Image = DICE_SPRITE_ID
		glow.ImageRectSize = Vector2.new(FRAME_SIZE, FRAME_SIZE)
		glow.ImageRectOffset = label.ImageRectOffset
		glow.ImageColor3 = GLOW_COLOR
		glow.ImageTransparency = 0.5
		glow.ScaleType = Enum.ScaleType.Fit
		glow.ZIndex = label.ZIndex + 1
		glow.Parent = label

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

function DiceDisplay.setSpriteAsset(assetId: string)
	DICE_SPRITE_ID = assetId
end

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
