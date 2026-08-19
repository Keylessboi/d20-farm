--[[
    init.client.luau
    Client entry point for D20 idle dice game.
    Requires RollController and creates the GameHUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RollController = require(script:WaitForChild("Controllers"):WaitForChild("RollController"))
local GameHUD = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("GameHUD"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

GameHUD.create(playerGui, RollController)

print("D20 Farm client initialized!")
