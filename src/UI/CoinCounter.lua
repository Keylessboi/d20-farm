--[[
	CoinCounter.lua
	Top-left HUD element showing the player's coin balance.

	Features:
	  - Pixel-art coin icon + TextLabel with smooth count-up animation
	  - Listens to Remotes.CoinUpdated to stay in sync with the server
	  - "+N" popup that tweens upward and fades when coins are earned
	  - Large numbers formatted with K/M suffix (e.g. 12.5K, 1.2M)

	Usage:
	  local CoinCounter = require(path.to.CoinCounter)
	  CoinCounter.create(PlayerGui)

	  -- Trigger popup from RollController callback:
	  CoinCounter.showPopup(coinsEarned)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CoinCounter = {}

-- ── ScreenGui ────────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name = "CoinCounter"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ── Container (top-left, 16px margin) ───────────────────────────────────────

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 200, 0, 50)
container.Position = UDim2.new(0, 16, 0, 16)
container.BackgroundTransparency = 1
container.Parent = gui

-- ── Coin icon ───────────────────────────────────────────────────────────────

local coinIcon = Instance.new("ImageLabel")
coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.new(0, 40, 0, 40)
coinIcon.Position = UDim2.new(0, 0, 0.5, -20)
coinIcon.BackgroundTransparency = 1
coinIcon.ScaleType = Enum.ScaleType.Fit
-- Coin.hex is an 8x8 pixel-art grid — placeholder until a Roblox decal is uploaded.
coinIcon.Image = "rbxassetid://105709188463991"
coinIcon.Parent = container

-- ── Coin count text ─────────────────────────────────────────────────────────

local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Size = UDim2.new(1, -50, 1, 0)
countLabel.Position = UDim2.new(0, 50, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Font = Enum.Font.GothamBold
countLabel.TextSize = 24
countLabel.TextColor3 = Color3.new(1, 1, 1)
countLabel.TextStrokeTransparency = 0.6
countLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Text = "0"
countLabel.Parent = container

-- ── Helpers ──────────────────────────────────────────────────────────────────

--- @param n number
--- @return string
local function formatNumber(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n))
end

-- ── Internal state ───────────────────────────────────────────────────────────

local currentDisplay = 0

-- Hidden NumberValue used as a tween target for smooth count-up.
-- TweenService cannot interpolate Text (a string), so we tween this
-- number and update the label text from its Changed event.
local tweenValue = Instance.new("NumberValue")
tweenValue.Value = 0

local activeTween = nil

tweenValue.Changed:Connect(function(value)
	countLabel.Text = formatNumber(value)
end)

--- Smoothly tween the displayed count from one value to another.
--- Duration scales with the size of the jump, capped at 0.5s.
--- @param from number
--- @param to number
local function animateCount(from, to)
	if from == to then
		countLabel.Text = formatNumber(to)
		return
	end

	-- Cancel any in-progress tween so rapid updates don't stack.
	if activeTween then
		activeTween:Cancel()
	end

	tweenValue.Value = from

	local delta = math.abs(to - from)
	local duration = math.clamp(delta / 200, 0.15, 0.5)

	activeTween = TweenService:Create(
		tweenValue,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = to }
	)
	activeTween:Play()
end

-- ── Public API ───────────────────────────────────────────────────────────────

--- Mount the CoinCounter into a ScreenGui parent (typically PlayerGui).
--- @param parent Instance  The GuiParent to attach to.
--- @return ScreenGui
function CoinCounter.create(parent)
	gui.Parent = parent

	Remotes.CoinUpdated.OnClientEvent:Connect(function(newBalance)
		local old = currentDisplay
		currentDisplay = newBalance
		animateCount(old, newBalance)
	end)

	return gui
end

--- Show a "+N" popup that tweens upward and fades out over 1 second.
--- Call this from the RollController callback with coinsEarned.
--- @param amount number  The number of coins just earned.
function CoinCounter.showPopup(amount)
	local popup = Instance.new("TextLabel")
	popup.Name = "CoinPopup"
	popup.Size = UDim2.new(0, 150, 0, 40)
	popup.Position = UDim2.new(0.5, -75, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0, 0)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.TextSize = 28
	popup.TextColor3 = Color3.fromRGB(255, 215, 0) -- gold
	popup.TextStrokeTransparency = 0.2
	popup.TextStrokeColor3 = Color3.new(0, 0, 0)
	popup.Text = "+" .. formatNumber(amount)
	popup.Parent = gui

	local tween = TweenService:Create(
		popup,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(0.5, -75, 0.5, -50),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

return CoinCounter
