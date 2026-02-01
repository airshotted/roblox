local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local ActiveEventVal = ReplicatedStorage:WaitForChild("ActiveEvent")

-- Create the Remote for communication
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminRemote = Remotes:FindFirstChild("AdminAction") or Instance.new("RemoteEvent", Remotes)
AdminRemote.Name = "AdminAction"

-- CONFIG: Who can use this?
local ADMIN_USER_IDS = {
	[game.CreatorId] = true, -- You
	[12345678] = true, -- Add friends here
}

local function IsAdmin(player)
	-- Allow Studio testing or specific Users
	if game["Run Service"]:IsStudio() then return true end
	return ADMIN_USER_IDS[player.UserId] == true
end

AdminRemote.OnServerEvent:Connect(function(player, action, ... )
	if not IsAdmin(player) then
		warn(player.Name .. " tried to use Admin Panel without permission!")
		return
	end

	local args = {...}

	---------------------------------------------------------
	-- ACTION: START EVENT
	---------------------------------------------------------
	if action == "StartEvent" then
		local eventName = args[1]
		if ItemDatabase.Events[eventName] then
			-- 1. Enable Override so the Scheduler doesn't stop it
			ActiveEventVal:SetAttribute("ManualOverride", true)

			-- 2. Set the Event
			ActiveEventVal.Value = eventName
			print("Admin " .. player.Name .. " started event: " .. eventName)
		end

		---------------------------------------------------------
		-- ACTION: STOP EVENT
		---------------------------------------------------------
	elseif action == "StopEvent" then
		-- 1. Disable Override
		ActiveEventVal:SetAttribute("ManualOverride", false)

		-- 2. Reset
		ActiveEventVal.Value = "None"
		print("Admin " .. player.Name .. " stopped the event.")

		---------------------------------------------------------
	-- ACTION: EDIT LUCK (Fixed for UI Replication)
	---------------------------------------------------------
	elseif action == "SetLuck" then
		local mult = tonumber(args[1])
		local currentEvent = ActiveEventVal.Value
		
		if currentEvent and currentEvent ~= "None" and mult then
			local data = ItemDatabase.Events[currentEvent]
			if data then
				-- 1. Update Server Math (For Rolls)
				data.GlobalLuck = mult
				
				-- 2. Update Client UI (Via Attribute)
				ActiveEventVal:SetAttribute("LiveLuckMult", mult)
				
				print("Admin " .. player.Name .. " set luck to " .. mult .. "x")
			end
		end
	end
end)