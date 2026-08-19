--[[
    init.client.luau
    Client entry point for D20 idle dice game.
    Requires RollController and creates the GameHUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RollController = require(ReplicatedStorage.Client.Controllers.RollController)
local GameHUD = require(ReplicatedStorage.UI.GameHUD)

-- Wait for player to load
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create the HUD
GameHUD.create(playerGui)

print("D20 Farm client initialized!")
