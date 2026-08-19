--[[
	CriticalFlash.lua
	Screen flash overlay for natural-20 critical rolls.
	Creates a gold Frame that fades out over 0.5 seconds,
	then destroys itself. Runs on the client's ScreenGui.

	Triggered by RollController when isCritical=true.
	Works alongside DiceDisplay.playCriticalGlow() for the dice-level effect.
]]

local TweenService = game:GetService("TweenService")

local CriticalFlash = {}

-- Design tokens
local FLASH_COLOR = Color3.fromRGB(255, 215, 0) -- gold
local FLASH_DURATION = 0.5
local FLASH_START_TRANSPARENCY = 0.5
local FLASH_Z_INDEX = 100

--- Play a gold screen-flash overlay inside the given ScreenGui.
--- The flash covers the full viewport, fades from semi-opaque gold
--- to fully transparent, then self-destructs.
---@param gui ScreenGui -- The ScreenGui to overlay the flash onto
function CriticalFlash.play(gui: ScreenGui)
	-- Full-screen flash overlay
	local flash = Instance.new("Frame")
	flash.Name = "CriticalFlashOverlay"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.Position = UDim2.new(0, 0, 0, 0)
	flash.BackgroundColor3 = FLASH_COLOR
	flash.BackgroundTransparency = FLASH_START_TRANSPARENCY
	flash.BorderSizePixel = 0
	flash.ZIndex = FLASH_Z_INDEX
	flash.Parent = gui

	-- Fade to invisible
	local tweenInfo = TweenInfo.new(
		FLASH_DURATION,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(flash, tweenInfo, {
		BackgroundTransparency = 1,
	})

	tween:Play()

	tween.Completed:Connect(function()
		if flash and flash.Parent then
			flash:Destroy()
		end
	end)
end

return CriticalFlash
