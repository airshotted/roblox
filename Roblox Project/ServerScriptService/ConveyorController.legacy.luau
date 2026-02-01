local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- CONFIGURATION
local SPAWN_RATE = 2 -- Spawn a block every 2 seconds
local MOVE_SPEED = 10 -- How many studs per second the blocks move
local CONVEYOR_FOLDER = workspace:WaitForChild("ConveyorSystem")

local StartPoint = CONVEYOR_FOLDER:WaitForChild("StartPoint")
local EndPoint = CONVEYOR_FOLDER:WaitForChild("EndPoint")

-- NEW: GUARANTEED DROP SCHEDULE
-- Format: { BlockId = "Block_Name", Interval = Seconds }
-- AttributeName is what the client looks for to show the timer.
local GUARANTEED_DROPS = {
	{ 
		BlockId = "Legendary_Block", 
		Interval = 1 * 60, -- 10 Minutes
		AttributeName = "NextLegendaryTime" 
	},
	{ 
		BlockId = "Mythical_Block", 
		Interval = 2 * 60, -- 30 Minutes
		AttributeName = "NextMythicalTime" 
	},
}

-- Initialize Timers (Set the first spawn to be X minutes from now)
local nextDropTimes = {}
for i, drop in ipairs(GUARANTEED_DROPS) do
	-- Set initial time
	nextDropTimes[i] = os.time() + drop.Interval
	
	-- Set initial Attribute so client sees it immediately
	CONVEYOR_FOLDER:SetAttribute(drop.AttributeName, nextDropTimes[i])
end

-- CALCULATE TIME
local distance = (EndPoint.Position - StartPoint.Position).Magnitude
local travelTime = distance / MOVE_SPEED

---------------------------------------------------------
-- HELPER: ROLL GLOBAL ATTRIBUTES
---------------------------------------------------------
local function GetRandomBlockType()
	-- Standard random logic
	local roll = math.random(1, 100)
	if roll <= 60 then return "Common_Block" end
	if roll <= 90 then return "Uncommon_Block" end
	return "Rare_Block" 
end

local function GetGlobalMutation()
	local rates = ItemDatabase.BlockMutations
	if math.random(1, rates.Galaxy) == 1 then return "Galaxy" end
	if math.random(1, rates.Void) == 1 then return "Void" end
	if math.random(1, rates.Radioactive) == 1 then return "Radioactive" end
	return "None"
end

---------------------------------------------------------
-- SPAWN LOGIC
---------------------------------------------------------
-- NEW: Added 'forcedId' parameter to override randomness
local function SpawnConveyorBlock(forcedId)
	
	-- 1. Determine Block Type
	local blockId = forcedId or GetRandomBlockType()
	
	local blockData = ItemDatabase.Blocks[blockId]
	if not blockData then return end

	local block = Instance.new("Part")
	block.Name = "ConveyorBlock"
	block.Size = Vector3.new(4, 4, 4)
	block.Position = StartPoint.Position
	block.Anchored = true
	block.CanCollide = false 
	block.Transparency = 1 
	
	-- 2. Apply Attributes
	block:SetAttribute("BlockID", blockId)

	local mutation = GetGlobalMutation()
	block:SetAttribute("BlockMutation", mutation)

	-- 3. Prompt Attachment (Anti-Flicker Fix)
	local promptAtt = Instance.new("Attachment")
	promptAtt.Name = "PromptAttachment"
	promptAtt.Position = Vector3.new(0, -3, 0)
	promptAtt.Parent = block

	-- 4. Add Interaction
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = blockData.DisplayName
	prompt.ActionText = "Open"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 4 -- Increased for Conveyor
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.Parent = promptAtt 

	-- 5. Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BillboardGui"
	billboard.Size = UDim2.new(4,0,4,0)
	billboard.AlwaysOnTop = true 
	billboard.Parent = block

	local img = Instance.new("ImageLabel")
	img.Name = "ImageLabel"
	img.Size = UDim2.new(1,0,1,0)
	img.BackgroundTransparency = 1
	img.Active = false
	img.Parent = billboard
	
    -- 6. PARENT TO WORKSPACE
    block.Parent = CONVEYOR_FOLDER 

	game:GetService("CollectionService"):AddTag(block, "LuckyBlock")

	-- 7. Move it
	local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(block, tweenInfo, {Position = EndPoint.Position})

	tween:Play()

	-- 8. Cleanup
	task.delay(travelTime, function()
		if block and block.Parent then
			block:Destroy()
		end
	end)
end

---------------------------------------------------------
-- MAIN LOOP (With Timer Checks)
---------------------------------------------------------
-- 1. Initial Attribute Set (Run this ONCE before the loop starts)
if nextDropTimes[1] then
	print("Initializing Timer Attribute: " .. nextDropTimes[1])
	CONVEYOR_FOLDER:SetAttribute("NextLegendaryTime", nextDropTimes[1])
end

-- 2. The Spawn Loop
while true do
	local spawnId = nil
	local currentTime = os.time()
	
	-- Check our schedule
	for i, drop in ipairs(GUARANTEED_DROPS) do
		if currentTime >= nextDropTimes[i] then
			spawnId = drop.BlockId
			
			-- Reset the timer for THIS specific drop
			nextDropTimes[i] = currentTime + drop.Interval
			
			-- Update ONLY the relevant Attribute
			CONVEYOR_FOLDER:SetAttribute(drop.AttributeName, nextDropTimes[i])
			
			print("!!! GUARANTEED SPAWN: " .. spawnId .. " !!!")
			break -- Spawn one special block at a time
		end
	end
	
	SpawnConveyorBlock(spawnId)
	task.wait(SPAWN_RATE)
end