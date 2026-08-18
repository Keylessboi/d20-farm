--!strict
-- D20 Farm - Client Bootstrap
-- Loads all controllers

print("[D20Farm] Client bootstrapping...")

-- Load controllers
local Controllers = script.Parent:WaitForChild("Controllers")

-- Wait for game to load
game:GetService("Players").LocalPlayer.CharacterAdded:Wait()

print("[D20Farm] Client ready!")
