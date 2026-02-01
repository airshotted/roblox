local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local ActiveEventVal = ReplicatedStorage:WaitForChild("ActiveEvent")

-- CONFIGURATION
local DAY_LENGTH = 6 * 60 -- 6 Minutes
local NIGHT_LENGTH = 6 * 60 -- 6 Minutes
local TOTAL_CYCLE = DAY_LENGTH + NIGHT_LENGTH

-- Helper: Date Check for Special Events
local function IsDateInRange(startStr, endStr)
	local now = os.date("*t")
	local currentMonthDay = (now.month * 100) + now.day
	local sM, sD = startStr:match("(%d+)/(%d+)")
	local eM, eD = endStr:match("(%d+)/(%d+)")
	local startVal = (tonumber(sM) * 100) + tonumber(sD)
	local endVal = (tonumber(eM) * 100) + tonumber(eD)
	return currentMonthDay >= startVal and currentMonthDay <= endVal
end

local function CheckForEvents()
	if ActiveEventVal:GetAttribute("ManualOverride") == true then return end
	
	local highestPriorityEvent = nil
	local highestPriority = -1
	
	-------------------------------------------------------
	-- 1. DETERMINE BASE STATE (Day/Night Cycle)
	-------------------------------------------------------
	-- We use os.time() for perfect sync across all servers
	local now = os.time()
	local timeInCycle = now % TOTAL_CYCLE
	
	local baseState = "SunnyDay"
	if timeInCycle >= DAY_LENGTH then
		baseState = "NightTime"
	end
	
	-- Set this as the baseline
	highestPriorityEvent = baseState
	highestPriority = 1 

	-------------------------------------------------------
	-- 2. CHECK FOR SPECIAL EVENTS (Overrides)
	-------------------------------------------------------
	local dateTable = os.date("*t")
	local distributedTime = workspace.DistributedGameTime

	for eventId, data in pairs(ItemDatabase.Events) do
		-- Skip base states, we calculated them above
		if eventId == "SunnyDay" or eventId == "NightTime" then continue end
		
		local isActive = false
		local schedule = data.Schedule

		if schedule.Type == "RealTime" then
			local hoursMatch = true
			if schedule.ActiveHours then
				local s, e = schedule.ActiveHours.Start, schedule.ActiveHours.End
				local h = dateTable.hour
				if s > e then hoursMatch = (h >= s) or (h < e)
				else hoursMatch = (h >= s) and (h < e) end
			end
			isActive = hoursMatch
			
		elseif schedule.Type == "Interval" then
			local totalCycle = (schedule.IntervalMinutes * 60)
			local activeDuration = (schedule.DurationMinutes * 60)
			local t = distributedTime % totalCycle
			isActive = t < activeDuration
			if distributedTime < totalCycle then isActive = false end
		end

		if isActive and data.Priority > highestPriority then
			highestPriority = data.Priority
			highestPriorityEvent = eventId
		end
	end

	-------------------------------------------------------
	-- 3. APPLY STATE
	-------------------------------------------------------
	local current = ActiveEventVal.Value
	if current ~= highestPriorityEvent then
		print("--- EVENT CHANGED TO: " .. highestPriorityEvent .. " ---")
		ActiveEventVal.Value = highestPriorityEvent
		
		-- Update Luck Attribute
		local data = ItemDatabase.Events[highestPriorityEvent]
		ActiveEventVal:SetAttribute("LiveLuckMult", data and data.GlobalLuck or 1)
	end
end

while true do
	CheckForEvents()
	task.wait(1) -- Check every second for precise transitions
end