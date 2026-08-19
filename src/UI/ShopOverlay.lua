--[[
	ShopOverlay.lua
	Client-side shop UI for the D20 idle dice game.
	Displays purchasable dice tiers in a grid, handles buy flow with
	confirmation prompt, and communicates purchases via ShopUpdated remote.

	Rojo maps src/UI/ → StarterGui, so this ScreenGui lands in the right place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ShopOverlay = {}

------------------------------------------------------------
-- State
------------------------------------------------------------
local gui
local isOpen = false
local shopItems = {}
local confirmFrame
local pendingDiceIndex = nil

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

-- Destroy all shop item frames and reset the list
local function clearItems()
	for _, item in ipairs(shopItems) do
		if item and item.Parent then
			item:Destroy()
		end
	end
	table.clear(shopItems)
end

-- Hide confirmation dialog if visible
local function hideConfirm()
	if confirmFrame and confirmFrame.Parent then
		confirmFrame.Visible = false
	end
end

------------------------------------------------------------
-- Build the ScreenGui (called once)
------------------------------------------------------------
local function buildGui()
	if gui then return gui end

	-- Root ScreenGui
	gui = Instance.new("ScreenGui")
	gui.Name = "ShopOverlay"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 100

	-- Semi-transparent dark overlay (full screen, click-catcher)
	local overlay = Instance.new("TextButton")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Parent = gui

	-- Shop container (centered panel)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 520, 0, 420)
	container.Position = UDim2.new(0.5, -260, 0.5, -210)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	container.BorderSizePixel = 0
	container.Parent = overlay

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 12)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(60, 60, 70)
	containerStroke.Thickness = 1
	containerStroke.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 0, 44)
	title.Position = UDim2.new(0, 16, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 26
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Text = "Dice Shop"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	-- Close button (top-right)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -46, 0, 11)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.Parent = container

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		ShopOverlay.close()
	end)

	-- Divider line under title
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, -32, 0, 1)
	divider.Position = UDim2.new(0, 16, 0, 56)
	divider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	divider.BorderSizePixel = 0
	divider.Parent = container

	-- Scrolling frame for dice grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -24, 1, -72)
	scroll.Position = UDim2.new(0, 12, 0, 64)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = container

	-- Grid layout inside scroll
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(1, -8, 0, 80)
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	-- ===== Confirmation Dialog (hidden by default) =====
	confirmFrame = Instance.new("Frame")
	confirmFrame.Name = "ConfirmDialog"
	confirmFrame.Size = UDim2.new(0, 320, 0, 200)
	confirmFrame.Position = UDim2.new(0.5, -160, 0.5, -100)
	confirmFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	confirmFrame.BorderSizePixel = 0
	confirmFrame.Visible = false
	confirmFrame.ZIndex = 20
	confirmFrame.Parent = container

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 10)
	confirmCorner.Parent = confirmFrame

	local confirmStroke = Instance.new("UIStroke")
	confirmStroke.Color = Color3.fromRGB(255, 215, 0)
	confirmStroke.Thickness = 2
	confirmStroke.Parent = confirmFrame

	-- Confirm title
	local confirmTitle = Instance.new("TextLabel")
	confirmTitle.Name = "ConfirmTitle"
	confirmTitle.Size = UDim2.new(1, -24, 0, 32)
	confirmTitle.Position = UDim2.new(0, 12, 0, 14)
	confirmTitle.BackgroundTransparency = 1
	confirmTitle.Font = Enum.Font.GothamBold
	confirmTitle.TextSize = 18
	confirmTitle.TextColor3 = Color3.new(1, 1, 1)
	confirmTitle.Text = "Confirm Purchase"
	confirmTitle.TextXAlignment = Enum.TextXAlignment.Center
	confirmTitle.ZIndex = 21
	confirmTitle.Parent = confirmFrame

	-- Confirm dice name
	local confirmDiceName = Instance.new("TextLabel")
	confirmDiceName.Name = "DiceName"
	confirmDiceName.Size = UDim2.new(1, -24, 0, 24)
	confirmDiceName.Position = UDim2.new(0, 12, 0, 50)
	confirmDiceName.BackgroundTransparency = 1
	confirmDiceName.Font = Enum.Font.GothamBold
	confirmDiceName.TextSize = 20
	confirmDiceName.TextColor3 = Color3.fromRGB(255, 215, 0)
	confirmDiceName.Text = ""
	confirmDiceName.TextXAlignment = Enum.TextXAlignment.Center
	confirmDiceName.ZIndex = 21
	confirmDiceName.Parent = confirmFrame

	-- Confirm price
	local confirmPrice = Instance.new("TextLabel")
	confirmPrice.Name = "Price"
	confirmPrice.Size = UDim2.new(1, -24, 0, 22)
	confirmPrice.Position = UDim2.new(0, 12, 0, 78)
	confirmPrice.BackgroundTransparency = 1
	confirmPrice.Font = Enum.Font.Gotham
	confirmPrice.TextSize = 16
	confirmPrice.TextColor3 = Color3.fromRGB(200, 200, 200)
	confirmPrice.Text = ""
	confirmPrice.TextXAlignment = Enum.TextXAlignment.Center
	confirmPrice.ZIndex = 21
	confirmPrice.Parent = confirmFrame

	-- YES button
	local yesBtn = Instance.new("TextButton")
	yesBtn.Name = "YesBtn"
	yesBtn.Size = UDim2.new(0, 120, 0, 38)
	yesBtn.Position = UDim2.new(0.5, -130, 1, -56)
	yesBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 55)
	yesBtn.Text = "BUY"
	yesBtn.TextColor3 = Color3.new(1, 1, 1)
	yesBtn.Font = Enum.Font.GothamBold
	yesBtn.TextSize = 16
	yesBtn.ZIndex = 21
	yesBtn.Parent = confirmFrame

	local yesCorner = Instance.new("UICorner")
	yesCorner.CornerRadius = UDim.new(0, 8)
	yesCorner.Parent = yesBtn

	-- NO button
	local noBtn = Instance.new("TextButton")
	noBtn.Name = "NoBtn"
	noBtn.Size = UDim2.new(0, 120, 0, 38)
	noBtn.Position = UDim2.new(0.5, 10, 1, -56)
	noBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	noBtn.Text = "CANCEL"
	noBtn.TextColor3 = Color3.new(1, 1, 1)
	noBtn.Font = Enum.Font.GothamBold
	noBtn.TextSize = 16
	noBtn.ZIndex = 21
	noBtn.Parent = confirmFrame

	local noCorner = Instance.new("UICorner")
	noCorner.CornerRadius = UDim.new(0, 8)
	noCorner.Parent = noBtn

	noBtn.MouseButton1Click:Connect(function()
		hideConfirm()
	end)

	yesBtn.MouseButton1Click:Connect(function()
		if pendingDiceIndex then
			hideConfirm()
			Remotes.ShopUpdated:FireServer(pendingDiceIndex)
			pendingDiceIndex = nil
		end
	end)

	return gui
end

------------------------------------------------------------
-- Show confirmation prompt for a specific dice tier
------------------------------------------------------------
local function showConfirm(diceIndex, diceInfo, price, canAfford)
	if not confirmFrame then return end

	pendingDiceIndex = diceIndex
	confirmFrame.Visible = true

	-- Update labels
	local diceNameLabel = confirmFrame:FindFirstChild("DiceName")
	if diceNameLabel then
		diceNameLabel.TextColor3 = diceInfo.color
		diceNameLabel.Text = diceInfo.name
	end

	local priceLabel = confirmFrame:FindFirstChild("Price")
	if priceLabel then
		priceLabel.Text = "Cost: " .. tostring(price) .. " coins"
		priceLabel.TextColor3 = canAfford and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(180, 60, 60)
	end
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function ShopOverlay.create(parent)
	buildGui()
	gui.Parent = parent
	return gui
end

--- Open the shop overlay.
--- @param playerCoins number  Current coin balance.
--- @param ownedDice table     List of DiceInfo the player already owns.
function ShopOverlay.open(playerCoins, ownedDice)
	buildGui()
	gui.Enabled = true
	isOpen = true
	clearItems()
	hideConfirm()

	local scroll = gui.Overlay.Container.Scroll

	-- Determine which dice tiers are unowned
	-- ownedDice may be a map of diceInfo entries with .owned = true,
	-- or a plain list of owned dice. We track owned indices.
	local ownedIndices = {}
	for _, d in ipairs(ownedDice) do
		if d.id then
			ownedIndices[d.id] = true
		end
	end

	-- Build list of purchasable tiers (unowned only, starting from the next available)
	local purchasable = {}
	for i, diceInfo in ipairs(Constants.DICE_TYPES) do
		-- Tier 1 (Wooden, cost 0) is the starter — skip it in the shop
		if diceInfo.cost <= 0 then
			continue
		end
		if not ownedIndices[i] then
			table.insert(purchasable, { index = i, info = diceInfo })
		end
	end

	-- All dice bought → "More coming soon!"
	if #purchasable == 0 then
		local msg = Instance.new("TextLabel")
		msg.Name = "AllBoughtMsg"
		msg.Size = UDim2.new(1, 0, 0, 50)
		msg.Position = UDim2.new(0, 0, 0.3, 0)
		msg.BackgroundTransparency = 1
		msg.Font = Enum.Font.GothamBold
		msg.TextSize = 22
		msg.TextColor3 = Color3.fromRGB(255, 215, 0)
		msg.Text = "More coming soon!"
		msg.TextXAlignment = Enum.TextXAlignment.Center
		msg.Parent = scroll
		table.insert(shopItems, msg)
		return
	end

	-- Populate grid with purchasable dice
	for order, entry in ipairs(purchasable) do
		local i = entry.index
		local diceInfo = entry.info
		local price = diceInfo.cost
		local canAfford = playerCoins >= price

		local itemFrame = Instance.new("Frame")
		itemFrame.Name = "Item_" .. i
		itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
		itemFrame.BorderSizePixel = 0
		itemFrame.LayoutOrder = order
		itemFrame.Parent = scroll

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 8)
		itemCorner.Parent = itemFrame

		local itemStroke = Instance.new("UIStroke")
		itemStroke.Color = canAfford and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(50, 50, 55)
		itemStroke.Thickness = 1
		itemStroke.Parent = itemFrame

		-- Dice icon (colored circle to represent the die)
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 52, 0, 52)
		icon.Position = UDim2.new(0, 12, 0.5, -26)
		icon.BackgroundColor3 = diceInfo.color
		icon.BorderSizePixel = 0
		icon.Parent = itemFrame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(1, 0)
		iconCorner.Parent = icon

		-- "D20" label inside icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 16
		iconLabel.TextColor3 = Color3.new(0, 0, 0)
		iconLabel.Text = "D20"
		iconLabel.Parent = icon

		-- Dice name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -180, 0, 24)
		nameLabel.Position = UDim2.new(0, 76, 0, 12)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextColor3 = diceInfo.color
		nameLabel.Text = diceInfo.name
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemFrame

		-- Multiplier info
		local multLabel = Instance.new("TextLabel")
		multLabel.Name = "Multiplier"
		multLabel.Size = UDim2.new(1, -180, 0, 20)
		multLabel.Position = UDim2.new(0, 76, 0, 38)
		multLabel.BackgroundTransparency = 1
		multLabel.Font = Enum.Font.Gotham
		multLabel.TextSize = 13
		multLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
		multLabel.Text = "x" .. tostring(diceInfo.multiplier) .. " coin multiplier"
		multLabel.TextXAlignment = Enum.TextXAlignment.Left
		multLabel.Parent = itemFrame

		-- Price label
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "Price"
		priceLabel.Size = UDim2.new(0, 80, 0, 20)
		priceLabel.Position = UDim2.new(0, 76, 1, -32)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextSize = 14
		priceLabel.TextColor3 = canAfford and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 60, 60)
		priceLabel.Text = tostring(price) .. " coins"
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = itemFrame

		-- Buy button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(0, 100, 0, 38)
		buyBtn.Position = UDim2.new(1, -116, 0.5, -19)
		buyBtn.BackgroundColor3 = canAfford and Color3.fromRGB(45, 140, 55) or Color3.fromRGB(55, 55, 60)
		buyBtn.Text = canAfford and "BUY" or "LOCKED"
		buyBtn.TextColor3 = canAfford and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 105)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 15
		buyBtn.AutoButtonColor = canAfford
		buyBtn.Parent = itemFrame

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyBtn

		-- Wire buy action → confirmation prompt
		if canAfford then
			buyBtn.MouseButton1Click:Connect(function()
				showConfirm(i, diceInfo, price, canAfford)
			end)
		end

		table.insert(shopItems, itemFrame)
	end
end

function ShopOverlay.close()
	if gui then
		gui.Enabled = false
	end
	hideConfirm()
	isOpen = false
end

function ShopOverlay.isOpen()
	return isOpen
end

return ShopOverlay
