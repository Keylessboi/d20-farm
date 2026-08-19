--[[
	CoinBurst.lua
	Gold coin particle burst effect for critical rolls.
	Spawns a ParticleEmitter that fires gold coins from the dice center
	then self-destructs after 2 seconds.

	Parent under the dice Part (or any BasePart in the dice display).
	Triggered by RollController when isCritical=true.
]]

local CoinBurst = {}

-- Design tokens (shared with DiceDisplay)
local GOLD_COLOR = Color3.fromRGB(255, 215, 0)
local BURST_COUNT = 20
local CLEANUP_DELAY = 2.0

--- Play a coin burst effect on the given parent Part.
--- Emits `BURST_COUNT` gold particles outward in all directions.
--- The emitter is destroyed automatically after CLEANUP_DELAY seconds.
---@param parent Instance -- A Part or Attachment to emit from
function CoinBurst.play(parent: Instance)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CoinBurstEmitter"

	-- Gold coin color with slight warm variation
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GOLD_COLOR),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 235, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 170, 0)),
	})

	-- Size: start at full, shrink to nothing
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})

	-- Lifetime: each coin lives 0.5–1.0 seconds
	emitter.Lifetime = NumberRange.new(0.5, 1.0)

	-- Burst: fire all particles at once
	emitter.Rate = 0 -- rate-based emission off; using Emit() burst
	emitter.Speed = NumberRange.new(10, 20)

	-- Spread in all directions (sphere)
	emitter.SpreadAngle = Vector2.new(360, 360)

	-- Tumble as they fly
	emitter.RotSpeed = NumberRange.new(-180, 180)

	-- Emit from center point
	emitter.Shape = Enum.ParticleEmitterShape.Point

	-- Slight gravity pull for arc feel
	emitter.Acceleration = Vector3.new(0, -15, 0)

	-- Transparency: fade in then out
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.6, 0),
		NumberSequenceKeypoint.new(1, 1),
	})

	emitter.Parent = parent

	-- Fire the burst
	emitter:Emit(BURST_COUNT)

	-- Self-destruct after the particles have had time to die
	task.delay(CLEANUP_DELAY, function()
		if emitter and emitter.Parent then
			emitter:Destroy()
		end
	end)
end

return CoinBurst
