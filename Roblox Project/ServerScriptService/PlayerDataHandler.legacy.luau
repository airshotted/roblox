local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [CONFIG] The One Store to Rule Them All
local MainStore = DataStoreService:GetDataStore("UnifiedPlayerData_V1")

-- SERVER COMMUNICATION
local ServerComm = ReplicatedStorage:FindFirstChild("ServerComm") or Instance.new("Folder", ReplicatedStorage)
ServerComm.Name = "ServerComm"

-- BINDABLES (For other scripts to ask for data)
local GetFullData = ServerComm:FindFirstChild("GetFullData") or Instance.new("BindableFunction", ServerComm)
GetFullData.Name = "GetFullData"

-- MAIN SESSION TABLE (Holds ALL data for ALL players)
local ServerSessions = {}

local DEFAULT_DATA = {
	Inventory = {},       -- Was in GameHandler
	Quests = {            -- Was in PlaytimeManager
		Daily = 0,
		Weekly = 0,
		LastDay = os.date("!%Y-%j"),
		LastWeek = os.date("!%Y-%W"),
		CollectionTier = 1
	},
	Settings = {          -- Ready for future use!
		MusicEnabled = true,
		ShadowsEnabled = true
	}
}

---------------------------------------------------------
-- DATA MANAGEMENT
---------------------------------------------------------
local function DeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = DeepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

local function LoadPlayer(player)
	local success, data = pcall(function()
		return MainStore:GetAsync("User_" .. player.UserId)
	end)

	-- Apply Defaults if new or missing keys
	local finalData = data or DeepCopy(DEFAULT_DATA)

	-- [SAFETY] Ensure sub-tables exist if we add new features later
	if not finalData.Inventory then finalData.Inventory = {} end
	if not finalData.Quests then finalData.Quests = DeepCopy(DEFAULT_DATA.Quests) end
	if not finalData.Settings then finalData.Settings = DeepCopy(DEFAULT_DATA.Settings) end

	-- CHECK FOR TIME RESETS (Daily/Weekly)
	local currentDay = os.date("!%Y-%j")
	local currentWeek = os.date("!%Y-%W")

	if finalData.Quests.LastDay ~= currentDay then
		finalData.Quests.Daily = 0
		finalData.Quests.LastDay = currentDay
	end

	if finalData.Quests.LastWeek ~= currentWeek then
		finalData.Quests.Weekly = 0
		finalData.Quests.LastWeek = currentWeek
	end

	ServerSessions[player.UserId] = finalData
	print("Data Loaded for " .. player.Name)
end

local function SavePlayer(player)
	local data = ServerSessions[player.UserId]
	if not data then return end

	-- Quests usually track session time, ensure they are up to date before saving
	-- (Logic for adding session time will happen in PlaytimeManager via reference)

	pcall(function()
		MainStore:SetAsync("User_" .. player.UserId, data)
	end)
	ServerSessions[player.UserId] = nil
	print("Data Saved for " .. player.Name)
end

---------------------------------------------------------
-- LISTENERS
---------------------------------------------------------
Players.PlayerAdded:Connect(LoadPlayer)
Players.PlayerRemoving:Connect(SavePlayer)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		SavePlayer(player)
	end
end)

-- Allow other server scripts to access the LIVE table
GetFullData.OnInvoke = function(userId)
	return ServerSessions[userId] -- Returns the Reference!
end