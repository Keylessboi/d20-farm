--[[
	AmbientMusic.lua
	Plays looping ambient music at low volume.
	Pauses when the window loses focus to save resources.
	Placeholders until real Roblox audio assets are uploaded.
]]

local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local AmbientMusic = {}
local music = nil

function AmbientMusic.start()
	music = Instance.new("Sound")
	music.Name = "AmbientMusic"
	music.SoundId = "rbxassetid://0" -- placeholder
	music.Volume = 0.15
	music.Looped = true
	music.Parent = SoundService
	music:Play()

	UserInputService.WindowFocused:Connect(function()
		if music then
			music:Resume()
		end
	end)

	UserInputService.WindowFocusReleased:Connect(function()
		if music then
			music:Pause()
		end
	end)
end

function AmbientMusic.stop()
	if music then
		music:Stop()
		music:Destroy()
		music = nil
	end
end

return AmbientMusic
