--[[
	RollController.lua
	Client-side controller for dice roll requests.

	Handles:
	  - Debouncing rapid clicks via a time-based cooldown (rollCooldown from Constants)
	  - Firing the server via Remotes.RollDice (RemoteFunction)
	  - Receiving results from Remotes.RollResult (RemoteEvent)
	  - Updating local GameState with new coin and roll counts
	  - Notifying registered UI callbacks so animations/popups can play

	Usage from UI:
	  local RollController = require(path.to.RollController)

	  RollController.onRollResult(function(result)
	      -- result.rolls, result.total, result.isCritical, result.coinsEarned
	  end)

	  RollController.requestRoll()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Constants = require(ReplicatedStorage.Shared.Constants)

local RollController = {}

-- Debounce state: prevents rapid-fire rolls from overwhelming the server.
-- isRolling guards against overlapping requests (the server hasn't responded yet).
-- lastRollTime enforces a minimum wall-clock gap between successive rolls.
local isRolling = false
local lastRollTime = 0

-- Local copy of GameState so callers can read current coin/roll totals without
-- reaching back into the data store every time.
local gameState = {
	coins = 0,
	totalRolls = 0,
}

-- UI callback slot. UI modules register a single callback here; it fires once
-- per roll result so they can trigger animations, popups, particle effects, etc.
local onRollResultCallback = nil

--- Register a callback that fires after every roll result.
--- @param callback fun(result: RollResult)
function RollController.onRollResult(callback)
	onRollResultCallback = callback
end

--- Read the latest local GameState snapshot.
function RollController.getGameState()
	return gameState
end

--- Request a dice roll from the server.
--- Silently ignored when:
---   1. A roll is already in-flight (isRolling guard)
---   2. The cooldown since the last roll hasn't elapsed (time-based debounce)
function RollController.requestRoll()
	local now = tick()

	-- Guard 1: A roll is already in flight — nothing to do.
	if isRolling then
		return
	end

	-- Guard 2: Cooldown not yet elapsed since the last roll.
	-- The server enforces this too, but the client-side check prevents
	-- wasted network calls and provides instant feedback to the player.
	if now - lastRollTime < Constants.GAME_CONFIG.rollCooldown then
		return
	end

	-- All guards passed — lock state and fire the request.
	isRolling = true
	lastRollTime = now

	-- Invoke the server. This yields until the server responds.
	-- The actual result arrives via RollResult.OnClientEvent (below),
	-- so we don't capture the return value here.
	Remotes.RollDice:InvokeServer()
end

-- Listen for server roll results.
-- When the server finishes processing a roll, it fires RollResult with the
-- complete RollResult data. We clear the rolling guard and forward to the UI.
Remotes.RollResult.OnClientEvent:Connect(function(result)
	isRolling = false

	-- Update local GameState so the UI can read current values.
	if result and result.coinsEarned then
		gameState.coins = gameState.coins + result.coinsEarned
		gameState.totalRolls = gameState.totalRolls + 1
	end

	-- Notify the UI callback (if registered).
	if onRollResultCallback then
		onRollResultCallback(result)
	end
end)

return RollController
