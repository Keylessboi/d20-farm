--[[
	SoundManager.lua
	Plays sound effects for dice rolls, critical hits, and coin gains.
	Limits concurrent sounds to prevent audio clipping.
	Placeholders until real Roblox audio assets are uploaded.
]]

local SoundService = game:GetService("SoundService")

local SoundManager = {}
local activeSounds = {}
local MAX_CONCURRENT = 3

-- Placeholder sound IDs (replace with actual Roblox asset IDs)
local SOUNDS = {
	roll = "rbxassetid://0",     -- dice roll click
	critical = "rbxassetid://0", -- critical hit chime
	coin = "rbxassetid://0",     -- coin gain cha-ching
}

local function playSound(name)
	if #activeSounds >= MAX_CONCURRENT then
		return -- too many concurrent sounds
	end

	local sound = Instance.new("Sound")
	sound.SoundId = SOUNDS[name]
	sound.Volume = 0.5
	sound.Parent = SoundService

	table.insert(activeSounds, sound)

	sound.Ended:Connect(function()
		for i, s in ipairs(activeSounds) do
			if s == sound then
				table.remove(activeSounds, i)
				break
			end
		end
		sound:Destroy()
	end)

	sound:Play()
end

function SoundManager.playRoll()
	playSound("roll")
end

function SoundManager.playCritical()
	playSound("critical")
end

function SoundManager.playCoin()
	playSound("coin")
end

return SoundManager
