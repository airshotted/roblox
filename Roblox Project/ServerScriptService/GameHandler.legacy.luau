local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemDatabase = require(ReplicatedStorage.ItemDatabase)

local ServerComm = ReplicatedStorage:WaitForChild("ServerComm")
local GetFullData = ServerComm:WaitForChild("GetFullData")

-- Setup DataStore
local rollCooldowns = {}

local function GetInventory(userId)
	local allData = GetFullData:Invoke(userId)
	return allData and allData.Inventory or {}
end

-- Setup Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"

-- [NEW] Internal Server Communication
local ServerComm = ReplicatedStorage:FindFirstChild("ServerComm") or Instance.new("Folder", ReplicatedStorage)
ServerComm.Name = "ServerComm"

local GetPlayerInventory = ServerComm:FindFirstChild("GetPlayerInventory") or Instance.new("BindableFunction", ServerComm)
GetPlayerInventory.Name = "GetPlayerInventory"

-- Allow other scripts to read SessionData safely
GetPlayerInventory.OnInvoke = function(userId)
    return GetInventory(userId)
end

local RollRemote = Remotes:FindFirstChild("RequestRoll") or Instance.new("RemoteFunction", Remotes)
RollRemote.Name = "RequestRoll"

-- [NEW] DATA REQUEST REMOTE
local GetDataRemote = Remotes:FindFirstChild("GetData") or Instance.new("RemoteFunction", Remotes)
GetDataRemote.Name = "GetData"

local UpdateIndexRemote = Remotes:FindFirstChild("UpdateIndex") or Instance.new("RemoteEvent", Remotes)
UpdateIndexRemote.Name = "UpdateIndex"

local MilestoneRemote = Remotes:FindFirstChild("MilestoneReached") or Instance.new("RemoteEvent", Remotes)
MilestoneRemote.Name = "MilestoneReached"

---------------------------------------------------------
-- GACHA SYSTEM
---------------------------------------------------------

-- 1. Helper: Roll for Mutation (Gold, Diamond, etc.)
local ActiveEventVal = ReplicatedStorage:WaitForChild("ActiveEvent")

local function RollMutation()
	-- 1. Check for EVENT MUTATION First
	local currentEvent = ActiveEventVal.Value
	if currentEvent and currentEvent ~= "None" then
		local eventData = ItemDatabase.Events[currentEvent]
		
		-- [FIX] Check if MutationChance EXISTS before rolling
		-- "SunnyDay" has no MutationChance, so this check prevents the crash.
		if eventData and eventData.MutationChance and eventData.EventMutation then
			if math.random(1, eventData.MutationChance) == 1 then
				return eventData.EventMutation
			end
		end
	end

	-- 2. Standard Mutation Roll (Existing Code)
	local possibleMutations = {"Platinum", "Diamond", "Gold"}
	for _, mutName in ipairs(possibleMutations) do
		local chance = ItemDatabase.Mutations[mutName]
		if chance and math.random(1, chance) == 1 then
			return mutName
		end
	end
	
	return "None"
end

-- 2. Helper: Roll the actual Brainrot Item
local function RollItem(luckProfile)
	-- A. Default Profile
	luckProfile = luckProfile or ItemDatabase.BlockLuck["Common"]
	
	-- B. Check for Active Event Luck
	local eventLuckMult = 1
	local currentEvent = ActiveEventVal.Value
	if currentEvent and currentEvent ~= "None" then
		local eventData = ItemDatabase.Events[currentEvent]
		if eventData and eventData.GlobalLuck then
			eventLuckMult = eventData.GlobalLuck
			-- print("Event Active! Boosting luck by: " .. eventLuckMult .. "x")
		end
	end
	
	-- C. Calculate Dynamic Total Weight
	local currentTotalWeight = 0
	local weightTable = {} -- Store calculated weights to avoid re-mathing later
	
	for id, itemData in pairs(ItemDatabase.Items) do
		local baseWeight = ItemDatabase.Rarities[itemData.Rarity] or 0
		local multiplier = luckProfile[itemData.Rarity] or 1
		
		-- APPLY UNIVERSAL LUCK:
		-- We only boost "Good" items. If we boosted Common too, the odds wouldn't change!
		-- APPLY EXPONENTIAL LUCK
		-- We only boost "Good" items.
		if itemData.Rarity ~= "Common" and itemData.Rarity ~= "Uncommon" then
			
			-- 1. Define a "Tier Power" for each rarity
			-- The higher the rarity, the more it benefits from Luck.
			local tierPower = 1.0
			if itemData.Rarity == "Epic" then tierPower = 1.1 end
			if itemData.Rarity == "Legendary" then tierPower = 1.3 end
			if itemData.Rarity == "Mythical" then tierPower = 1.5 end 
			if itemData.Rarity == "Cosmic" then tierPower = 2.0 end
			
			-- 2. Apply the Math (Luck ^ Power)
			-- Example with 100x Luck:
			-- Rare gets 100^1 = 100x boost
			-- Mythical gets 100^1.5 = 1,000x boost (It catches up!)
			local weightedLuck = math.pow(eventLuckMult, tierPower)
			
			multiplier = multiplier * weightedLuck
		end
		
		local finalItemWeight = baseWeight * multiplier
		weightTable[id] = finalItemWeight -- Save for step E
		currentTotalWeight += finalItemWeight
	end
	
	-- D. Pick the Random Number
	local randomValue = math.random() * currentTotalWeight
	local runningWeight = 0
	
	local chosenId = nil
	local chosenData = nil
	
	-- E. Find the Winner
	for id, itemData in pairs(ItemDatabase.Items) do
		-- Use the pre-calculated weight from Step C
		local finalWeight = weightTable[id]
		
		runningWeight += finalWeight
		
		if randomValue <= runningWeight then
			chosenId = id
			chosenData = itemData
			break
		end
	end
	
	-- F. Roll the Mutation
	local mutation = RollMutation()
	
	return chosenId, chosenData, mutation
end

---------------------------------------------------------
-- MAIN ROLL HANDLER
---------------------------------------------------------
RollRemote.OnServerInvoke = function(player, blockInstance)
	
	local lastRoll = rollCooldowns[player.UserId] or 0
    local now = os.clock() -- os.clock is more precise for short intervals
    if now - lastRoll < 0.5 then 
        return nil -- Rolling too fast (Teleporting/Exploiting)
    end
    rollCooldowns[player.UserId] = now

	-- 1. DETERMINE LUCK
	local luckProfile = ItemDatabase.BlockLuck["Common"] -- Default to Normal
	
	if blockInstance then
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - blockInstance.Position).Magnitude
			if dist > 20 then -- 20 studs max reach
				warn(player.Name .. " tried to open a block from too far away!")
				return nil
			end
		end
		
		local blockId = blockInstance:GetAttribute("BlockID")
		if blockId and ItemDatabase.Blocks[blockId] then
			local blockRarity = ItemDatabase.Blocks[blockId].Rarity
			
			-- Retrieve the multipliers for this block rarity
			if ItemDatabase.BlockLuck[blockRarity] then
				luckProfile = ItemDatabase.BlockLuck[blockRarity]
				-- print(player.Name .. " is using " .. blockRarity .. " Luck!") 
			end
		end
	end

	-- 2. ROLL THE ITEM (Pass the luck profile!)
	local rolledId, rolledData, itemMutation = RollItem(luckProfile)
	
	if not rolledId then return nil end
	if not itemMutation then itemMutation = "None" end

	---------------------------------------------------------
	-- A. COLLECT THE BLOCK ITSELF
	---------------------------------------------------------
	if blockInstance and blockInstance:GetAttribute("BlockID") then
		local blockId = blockInstance:GetAttribute("BlockID")
		local blockMut = blockInstance:GetAttribute("BlockMutation") or "None"
		
		if blockId then
			local blockSaveKey = blockId
			if blockMut and blockMut ~= "None" then
				blockSaveKey = blockId .. "_" .. blockMut
			end
			
			if GetInventory(player.UserId) then
				GetInventory(player.UserId)[blockSaveKey] = true
			end
		end
	end

	---------------------------------------------------------
	-- B. COLLECT THE ROLLED ITEM
	---------------------------------------------------------
	local itemSaveKey = rolledId
	if itemMutation ~= "None" then
		itemSaveKey = rolledId .. "_" .. itemMutation
	end
	
	if GetInventory(player.UserId) then
		if not GetInventory(player.UserId)[itemSaveKey] then
			GetInventory(player.UserId)[itemSaveKey] = true
		end
		
		UpdateIndexRemote:FireClient(player, GetInventory(player.UserId))
	end
	
	---------------------------------------------------------
	-- C. MILESTONE CHECKER (Fixed: Supports Underscores)
	---------------------------------------------------------
	local uniqueItems = {}
	local uniqueBlocks = {}
	
	-- HELPER: Smart ID Extraction (Same logic as Client)
	local function GetBaseId(fullKey)
		if ItemDatabase.Items[fullKey] or ItemDatabase.Blocks[fullKey] then
			return fullKey
		end
		local lastUnderscore = fullKey:match("^.*()_")
		if lastUnderscore then
			local base = string.sub(fullKey, 1, lastUnderscore - 1)
			if ItemDatabase.Items[base] or ItemDatabase.Blocks[base] then
				return base
			end
		end
		return fullKey
	end
	
	for key, _ in pairs(GetInventory(player.UserId)) do
		local baseId = GetBaseId(key) -- [FIX] Smart Extract
		
		-- NOTE: Server counts UNIQUE BASE ITEMS (e.g. Gold + Normal = 1 point)
		-- If you want the Server to match the Client's "Count Mutations" logic,
		-- change these lines to: uniqueItems[key] = true
		if ItemDatabase.Items[baseId] then
			uniqueItems[key] = true -- Changed to key to match Client's "Count Each Mutation" setting
		elseif ItemDatabase.Blocks[baseId] then
			uniqueBlocks[key] = true
		end
	end
	
	-- Helper to count dictionary size
	local function CountSet(set)
		local c = 0
		for _ in pairs(set) do c += 1 end
		return c
	end

	local distinctItems = CountSet(uniqueItems)
	local distinctBlocks = CountSet(uniqueBlocks)
	
	-- Helper: Check if we JUST hit a threshold
	local function CheckThreshold(currentCount, tableType)
		local thresholds = ItemDatabase.Milestones[tableType]
		for _, goal in ipairs(thresholds) do
			if currentCount == goal then
				MilestoneRemote:FireClient(player, tableType, goal)
				break
			end
		end
	end
	
	CheckThreshold(distinctItems, "Items")
	CheckThreshold(distinctBlocks, "Blocks")

	return rolledId, itemMutation
end

---------------------------------------------------------
-- DATA REQUEST HANDLER (Fixes Race Condition)
---------------------------------------------------------
GetDataRemote.OnServerInvoke = function(player)
	-- Return the data we have loaded in memory
	return GetInventory(player.UserId) or {}
end