local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- [FIX] Create the Remotes if they don't exist
local GetTimeRemote = Remotes:FindFirstChild("GetPlaytime") or Instance.new("RemoteFunction", Remotes)
GetTimeRemote.Name = "GetPlaytime"

local ClaimRemote = Remotes:FindFirstChild("ClaimMilestone") or Instance.new("RemoteEvent", Remotes)
ClaimRemote.Name = "ClaimMilestone"

-- [NEW] LINK TO UNIFIED DATA
local ServerComm = ReplicatedStorage:WaitForChild("ServerComm")
local GetFullData = ServerComm:WaitForChild("GetFullData")

-- [FIX] ADD THESE TABLES (They were missing!)
local sessionStartTimes = {} 
local claimCooldowns = {} 

-- 1. TRACK SESSIONS
Players.PlayerAdded:Connect(function(player)
	sessionStartTimes[player.UserId] = os.time()
end)

-- 2. GET PLAYTIME (Updated to use Unified Data)
GetTimeRemote.OnServerInvoke = function(player)
	-- [FIX] Use GetFullData instead of storedData
	local allData = GetFullData:Invoke(player.UserId)
	if not allData or not allData.Quests then return 0, 0, 1 end
	
	local qData = allData.Quests
	local currentSession = os.time() - (sessionStartTimes[player.UserId] or os.time())
	
	return (qData.Daily + currentSession), (qData.Weekly + currentSession), qData.CollectionTier
end

-- 3. CLAIM MILESTONE (Updated to use Unified Data)
ClaimRemote.OnServerEvent:Connect(function(player)
	local lastClaim = claimCooldowns[player.UserId] or 0
	if os.time() - lastClaim < 2 then return end 
	claimCooldowns[player.UserId] = os.time()
	
	-- [FIX] Use GetFullData instead of storedData/IndexStore
	local allData = GetFullData:Invoke(player.UserId)
	if not allData then return end
	
	local inventory = allData.Inventory 
	local qData = allData.Quests
	
	local uniqueCount = 0
	for _ in pairs(inventory) do uniqueCount += 1 end
	
	local ItemDatabase = require(ReplicatedStorage.ItemDatabase)
	local currentTier = qData.CollectionTier or 1
	local goal = ItemDatabase.Milestones.Items[currentTier]
	
	if goal and uniqueCount >= goal then
		qData.CollectionTier += 1 
		print("Tier Upgraded for " .. player.Name)
	end
end)

-- 4. SAVE SESSION ON EXIT
Players.PlayerRemoving:Connect(function(player)
	local allData = GetFullData:Invoke(player.UserId)
	if allData and allData.Quests then
		local sessionTime = os.time() - (sessionStartTimes[player.UserId] or os.time())
		allData.Quests.Daily += sessionTime
		allData.Quests.Weekly += sessionTime
	end
	sessionStartTimes[player.UserId] = nil
end)