local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local indexUI = playerGui:WaitForChild("IndexUI")
local mainFrame = indexUI:WaitForChild("MainFrame")
local contentContainer = mainFrame:WaitForChild("ContentContainer")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetDataRemote = Remotes:WaitForChild("GetData")
local UpdateIndexRemote = Remotes:WaitForChild("UpdateIndex")
local RunService = game:GetService("RunService") -- Ensure this is at the top!

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

---------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------
-- 1. Sort Order (Logic for ordering the grid)
local RARITY_ORDER = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythical = 6,
	Cosmic = 7
}

-- 2. Card Background Gradients (Top to Bottom)
-- Edit these colors to change the background look of the cards!
local RARITY_BACKGROUNDS = {
	Common = ColorSequence.new(Color3.fromRGB(220, 220, 220), Color3.fromRGB(100, 100, 100)),
	Uncommon = ColorSequence.new(Color3.fromRGB(150, 255, 150), Color3.fromRGB(50, 150, 50)),
	Rare = ColorSequence.new(Color3.fromRGB(100, 200, 255), Color3.fromRGB(20, 80, 150)),
	Epic = ColorSequence.new(Color3.fromRGB(180, 100, 255), Color3.fromRGB(80, 20, 120)),
	Legendary = ColorSequence.new(Color3.fromRGB(255, 220, 50), Color3.fromRGB(180, 120, 0)),
	Mythical = ColorSequence.new(Color3.fromRGB(255, 100, 220), Color3.fromRGB(150, 0, 100)),
	Cosmic = ColorSequence.new(Color3.fromRGB(255, 80, 50), Color3.fromRGB(100, 20, 0)),
}

local MUTATION_LISTS = {
	Blocks = {"None", "Radioactive", "Void", "Galaxy"},
	Items = {"None", "Gold", "Platinum", "Diamond", "Midas", "Crimson"}
}

---------------------------------------------------------
-- STATE
---------------------------------------------------------
local ownedData = {}
local activeFilters = {
	Blocks = "None",
	Items = "None"
}

---------------------------------------------------------
-- HELPER: TEXT STYLES (Reused from your old code)
---------------------------------------------------------
local function ApplyTextStyle(label, styleName)
	local style = ItemDatabase.TextStyles[styleName] or ItemDatabase.TextStyles.Common
	
	label.TextColor3 = style.Color
	
	local stroke = label:FindFirstChild("UIStroke") or Instance.new("UIStroke", label)
	stroke.Color = style.Stroke
	stroke.Thickness = style.Thickness
	
	-- Only apply fancy gradients to high tiers if defined
	if style.Gradient then
		local grad = label:FindFirstChild("UIGradient") or Instance.new("UIGradient", label)
		grad.Color = style.Gradient
		grad.Enabled = true
	else
		if label:FindFirstChild("UIGradient") then label.UIGradient:Destroy() end
	end
end

---------------------------------------------------------
-- NEW: DYNAMIC TOOLTIP SYSTEM
---------------------------------------------------------
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local tooltipFrame = nil
local tooltipName = nil
local tooltipProb = nil

local function InitTooltip()
	if tooltipFrame then return end
	
	-- 1. Create Container
	tooltipFrame = Instance.new("Frame")
	tooltipFrame.Name = "Tooltip"
	tooltipFrame.Size = UDim2.new(0, 200, 0, 70) -- Fixed size
	tooltipFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tooltipFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	tooltipFrame.BorderSizePixel = 2
	tooltipFrame.ZIndex = 100 -- Float above everything
	tooltipFrame.Visible = false
	tooltipFrame.Parent = indexUI -- Parent to ScreenGui so it ignores clipping
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = tooltipFrame
	
	-- 2. Name Label
	tooltipName = Instance.new("TextLabel")
	tooltipName.Size = UDim2.new(1, -10, 0.5, 0)
	tooltipName.Position = UDim2.new(0, 5, 0, 5)
	tooltipName.BackgroundTransparency = 1
	tooltipName.TextColor3 = Color3.new(1,1,1)
	tooltipName.Font = Enum.Font.FredokaOne
	tooltipName.TextScaled = true
	tooltipName.TextXAlignment = Enum.TextXAlignment.Left
	tooltipName.ZIndex = 101
	tooltipName.Parent = tooltipFrame
	
	-- 3. Probability Label
	tooltipProb = Instance.new("TextLabel")
	tooltipProb.Size = UDim2.new(1, -10, 0.4, 0)
	tooltipProb.Position = UDim2.new(0, 5, 0.5, 0)
	tooltipProb.BackgroundTransparency = 1
	tooltipProb.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	tooltipProb.Font = Enum.Font.FredokaOne
	tooltipProb.TextScaled = true
	tooltipProb.TextXAlignment = Enum.TextXAlignment.Left
	tooltipProb.ZIndex = 101
	tooltipProb.Parent = tooltipFrame
end

-- Mouse Follower Loop
RunService.RenderStepped:Connect(function()
	if tooltipFrame and tooltipFrame.Visible then
		local mPos = UserInputService:GetMouseLocation()
		-- [CHANGED] Reduced offset from 15 to 8 (Closer, but not covering the pointer)
		tooltipFrame.Position = UDim2.fromOffset(mPos.X + 8, mPos.Y + 8)
	end
end)

-- Helper: Format numbers with commas (e.g. 1,000,000)
local function FormatNumber(n)
	-- [FIXED] Added parentheses around (%d%d%d) so %1 works
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function CalculateProbability(rarity, mutation, category)
	-- 1. Calculate REAL Total Weight (Count every item in the game)
	local totalWeight = 0
	
	-- We must loop through the items/blocks to see how many exist
	local db = (category == "Blocks") and ItemDatabase.Blocks or ItemDatabase.Items
	
	for _, itemData in pairs(db) do
		local w = ItemDatabase.Rarities[itemData.Rarity] or 0
		totalWeight += w
	end
	
	-- 2. Get Weight of THIS specific item
	local itemWeight = ItemDatabase.Rarities[rarity] or 1
	
	-- 3. Apply Mutation Multiplier
	local mutationMult = 1
	if mutation and mutation ~= "None" then
		if category == "Blocks" then
			mutationMult = ItemDatabase.BlockMutations[mutation] or 1
		else
			mutationMult = ItemDatabase.Mutations[mutation] or 1
		end
	end
	
	-- 4. Final Calculation
	-- (Total Weight / Item Weight) * MutationRarity
	local finalOneIn = (totalWeight / itemWeight) * mutationMult
	
	return "1 in " .. FormatNumber(finalOneIn)
end

---------------------------------------------------------
-- CORE: SEAMLESS VISUAL UPDATES
---------------------------------------------------------
local function UpdateCardVisuals(frame, id, data, category)
	local currentMutation = activeFilters[category]
	local checkKey = id
	-- [CHANGE] We no longer calculate DisplayName here for the card
	-- The card always shows Rarity.
	
	local icon = frame:FindFirstChild("Icon")
	local nameLbl = frame:FindFirstChild("NameLabel")
	local gradient = frame:FindFirstChild("UIGradient")
	
	-- 1. Determine Target Image based on Filter
	local targetImage = data.ImageId
	
	if currentMutation ~= "None" then
		checkKey = id .. "_" .. currentMutation
		-- Handle Texture Overrides
		if category == "Blocks" and ItemDatabase.MutationTextures[currentMutation] then
			targetImage = ItemDatabase.MutationTextures[currentMutation]
		end
	end
	
	-- SHARED VISUALS
	frame.BackgroundColor3 = Color3.new(1,1,1)
	
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Parent = frame
	end
	gradient.Color = RARITY_BACKGROUNDS[data.Rarity] or RARITY_BACKGROUNDS.Common
	
	-- 2. Check Ownership
	if ownedData[checkKey] then
		-- UNLOCKED
		icon.Image = targetImage
		icon.ImageColor3 = Color3.new(1,1,1)
		icon.ImageTransparency = 0
		
		-- [CHANGE] Show Rarity Text
		nameLbl.Text = data.Rarity 
		ApplyTextStyle(nameLbl, data.Rarity)
		
	else
		-- LOCKED
		icon.Image = targetImage
		icon.ImageColor3 = Color3.new(0, 0, 0) 
		icon.ImageTransparency = 0.5
		
		nameLbl.Text = "???"
		nameLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		
		if nameLbl:FindFirstChild("UIStroke") then nameLbl.UIStroke:Destroy() end
		if nameLbl:FindFirstChild("UIGradient") then nameLbl.UIGradient:Destroy() end
		
		local simpleStroke = Instance.new("UIStroke")
		simpleStroke.Thickness = 2
		simpleStroke.Color = Color3.new(0,0,0)
		simpleStroke.Parent = nameLbl
	end
end

local function CreateBaseCard(id, data, category)
	local frame = Instance.new("Frame")
	frame.Name = id
	frame.BackgroundColor3 = Color3.new(1,1,1)
	frame.BorderSizePixel = 0

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1.0 
	ratio.Parent = frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- [REMOVED] ClickZone Button
	-- We will use the Frame's MouseEnter event directly
	
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.7, 0, 0.6, 0)
	icon.Position = UDim2.new(0.15, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = frame
	
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.Size = UDim2.new(0.9, 0, 0.25, 0)
	nameLbl.Position = UDim2.new(0.05, 0, 0.72, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextScaled = true
	nameLbl.Parent = frame
	
	return frame
end

---------------------------------------------------------
-- CORE: SECTION RENDERING
---------------------------------------------------------
local function CreateSection(categoryName, databaseTable, filterKey)
	-- Ensure Tooltip exists
	InitTooltip()

	-- 1. Create Container (Only once)
	local sectionName = categoryName .. "Section"
	if contentContainer:FindFirstChild(sectionName) then return end 
	
	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = sectionName
	sectionFrame.BackgroundTransparency = 1
	sectionFrame.Size = UDim2.new(1, 0, 0, 0) 
	sectionFrame.LayoutOrder = (categoryName == "Lucky Blocks" and 1 or 2)
	sectionFrame.Parent = contentContainer
	
	-- 2. Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.08, 30)
	header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	header.BackgroundTransparency = 1
	header.Parent = sectionFrame
	
	local headerTitle = Instance.new("TextLabel")
	headerTitle.Text = categoryName
	headerTitle.Font = Enum.Font.SourceSansBold
	headerTitle.TextScaled = true
	headerTitle.TextColor3 = Color3.new(1,1,1)
	headerTitle.Size = UDim2.new(0.5, 0, 0.7, 0)
	headerTitle.Position = UDim2.new(0.02, 0, 0.15, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Parent = header
	
	-- 3. Filter Button
	local filterBtn = Instance.new("TextButton")
	filterBtn.Name = "FilterButton"
	filterBtn.Size = UDim2.new(0.3, 0, 0.8, 0)
	filterBtn.Position = UDim2.new(0.68, 0, 0.1, 0)
	filterBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	filterBtn.TextColor3 = Color3.new(1,1,1)
	filterBtn.Font = Enum.Font.SourceSansBold
	filterBtn.TextScaled = true
	filterBtn.Text = "Mutation: None"
	filterBtn.Parent = header
	
	local corner = Instance.new("UICorner"); corner.Parent = filterBtn
	
	-- 4. Grid Container
	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "Grid"
	gridFrame.BackgroundTransparency = 1
	gridFrame.Position = UDim2.new(0, 0, 0, 0)
	gridFrame.Size = UDim2.new(1, 0, 0, 0)
	gridFrame.Parent = sectionFrame
	
	local sectionLayout = Instance.new("UIListLayout")
	sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sectionLayout.Parent = sectionFrame

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.18, 0, 0, 100) 
	layout.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gridFrame

	-- Dynamic Resize
	local function UpdateGridSize()
		if not gridFrame.Parent then return end
		
		-- 1. GET WIDTH
		local totalWidth = gridFrame.AbsoluteSize.X
		
		-- [NEW] ANIMATION GUARD
		-- If the frame is too small (during a pop-in animation), DO NOT resize.
		-- This prevents the items from crunching into microscopic dots.
		if totalWidth < 100 then return end 
		
		local cellWidth = totalWidth * 0.18
		local cellHeight = cellWidth / 1.0 
		layout.CellSize = UDim2.new(0.18, 0, 0, cellHeight)
		
		task.delay(0.1, function()
			local contentHeight = layout.AbsoluteContentSize.Y
			gridFrame.Size = UDim2.new(1, 0, 0, contentHeight)
			sectionFrame.Size = UDim2.new(1, 0, 0, contentHeight + header.AbsoluteSize.Y + 20)
		end)
	end
	gridFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateGridSize)
	
	-- 5. Filter Logic
	filterBtn.MouseButton1Click:Connect(function()
		local list = MUTATION_LISTS[filterKey]
		local current = activeFilters[filterKey]
		local idx = table.find(list, current) or 1
		local nextIdx = (idx % #list) + 1
		local nextMut = list[nextIdx]
		
		activeFilters[filterKey] = nextMut
		filterBtn.Text = "Mutation: " .. nextMut
		
		for id, data in pairs(databaseTable) do
			local card = gridFrame:FindFirstChild(id)
			if card then
				UpdateCardVisuals(card, id, data, filterKey)
			end
		end
	end)
	
	-- 6. Populate Grid & Hover Logic
	local sortedItems = {}
	for id, data in pairs(databaseTable) do
		table.insert(sortedItems, {ID = id, Data = data})
	end
	table.sort(sortedItems, function(a, b)
		local rankA = RARITY_ORDER[a.Data.Rarity] or 0
		local rankB = RARITY_ORDER[b.Data.Rarity] or 0
		return rankA < rankB
	end)
	
	for _, item in ipairs(sortedItems) do
		local card = CreateBaseCard(item.ID, item.Data, filterKey)
		UpdateCardVisuals(card, item.ID, item.Data, filterKey)
		
		-- [NEW] HOVER TOOLTIP LOGIC
		card.MouseEnter:Connect(function()
			local currentMutation = activeFilters[filterKey]
			
			-- Determine Name (Handle Locked State)
			local checkKey = item.ID
			if currentMutation ~= "None" then checkKey = item.ID .. "_" .. currentMutation end
			
			local displayName = item.Data.DisplayName
			if currentMutation ~= "None" then displayName = currentMutation .. " " .. displayName end
			
			if not ownedData[checkKey] then
				displayName = "???"
			end
			
			-- Update Tooltip Text
			tooltipName.Text = displayName
			tooltipProb.Text = CalculateProbability(item.Data.Rarity, currentMutation, filterKey)
			tooltipFrame.Visible = true
		end)
		
		card.MouseLeave:Connect(function()
			tooltipFrame.Visible = false
		end)
		
		card.Parent = gridFrame
	end
	
	task.defer(UpdateGridSize)
end
---------------------------------------------------------
-- MAIN: INITIALIZE & UPDATE
---------------------------------------------------------
function RefreshIndex()
	-- 1. Ensure UI exists (Only runs once)
	CreateSection("Lucky Blocks", ItemDatabase.Blocks, "Blocks")
	CreateSection("Brainrots", ItemDatabase.Items, "Items")
	
	-- 2. Update States (Runs on every data update)
	local function UpdateSection(name, db, key)
		local section = contentContainer:FindFirstChild(name .. "Section")
		if section then
			local grid = section:FindFirstChild("Grid")
			if grid then
				for id, data in pairs(db) do
					local card = grid:FindFirstChild(id)
					if card then
						UpdateCardVisuals(card, id, data, key)
					end
				end
			end
		end
	end
	
	UpdateSection("Lucky Blocks", ItemDatabase.Blocks, "Blocks")
	UpdateSection("Brainrots", ItemDatabase.Items, "Items")
end

---------------------------------------------------------
-- LISTENERS
---------------------------------------------------------
-- Listen for data updates from Server
UpdateIndexRemote.OnClientEvent:Connect(function(newData)
	ownedData = newData or {}
	RefreshIndex()
end)

-- Initial Load
task.spawn(function()
	ownedData = GetDataRemote:InvokeServer() or {}
	RefreshIndex()
end)

---------------------------------------------------------
-- ANIMATED TOGGLE & BUTTON LOGIC
---------------------------------------------------------
-- [1] SETUP VARIABLES
local openBtn = indexUI:WaitForChild("OpenButton")
local isOpen = false
local isAnimating = false 

-- Setup MainFrame Scaler (The "Pop" Effect)
local scaler = mainFrame:FindFirstChild("UIScale")
if not scaler then
	scaler = Instance.new("UIScale")
	scaler.Parent = mainFrame
end

-- Setup Button Scaler (For Hover/Click Effects)
local btnScaler = openBtn:FindFirstChild("UIScale")
if not btnScaler then
	btnScaler = Instance.new("UIScale")
	btnScaler.Parent = openBtn
end

-- [2] DEFINE MENU FUNCTIONS
local function OpenMenu()
	if isAnimating then return end
	isAnimating = true
	isOpen = true
	
	-- Prepare State
	scaler.Scale = 0
	mainFrame.Visible = true
	
	-- Reset Scroll Position (Prevents visual glitches)
	contentContainer.CanvasPosition = Vector2.new(0, 0)
	RunService.RenderStepped:Wait() 
	
	-- Animate Pop In
	local openTween = TweenService:Create(scaler, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	})
	openTween:Play()
	
	openTween.Completed:Wait()
	isAnimating = false
end

local function CloseMenu()
	if isAnimating then return end
	isAnimating = true
	isOpen = false
	
	-- Animate Pop Out (Shrink)
	local closeTween = TweenService:Create(scaler, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Scale = 0
	})
	closeTween:Play()
	
	closeTween.Completed:Wait()
	mainFrame.Visible = false
	isAnimating = false
end

-- [3] SETUP BUTTON ANIMATIONS
local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local clickInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local hoverTween = TweenService:Create(btnScaler, hoverInfo, {Scale = 1.1}) -- Grows 10%
local leaveTween = TweenService:Create(btnScaler, hoverInfo, {Scale = 1.0}) -- Normal
local pressTween = TweenService:Create(btnScaler, clickInfo, {Scale = 0.9}) -- Shrinks 10%

openBtn.MouseEnter:Connect(function() hoverTween:Play() end)
openBtn.MouseLeave:Connect(function() leaveTween:Play() end)
openBtn.MouseButton1Down:Connect(function() pressTween:Play() end)
openBtn.MouseButton1Up:Connect(function() hoverTween:Play() end) -- Pop back to hover size

-- [4] CONNECT TOGGLE ACTION
openBtn.MouseButton1Click:Connect(function()
	if isOpen then
		CloseMenu()
	else
		OpenMenu()
	end
end)

-- [5] INITIAL STATE
mainFrame.Visible = false
scaler.Scale = 0