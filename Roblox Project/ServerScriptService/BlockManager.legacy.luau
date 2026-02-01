local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- Helper: Roll for a mutation based on Config
local function RollBlockMutation()
	-- Check Config for rates (e.g., Radioactive = 10 means 1 in 10)
	local rates = ItemDatabase.BlockMutations

	-- Order matters: Check rarest first!
	if math.random(1, rates.Galaxy) == 1 then return "Galaxy" end
	if math.random(1, rates.Void) == 1 then return "Void" end
	if math.random(1, rates.Radioactive) == 1 then return "Radioactive" end

	return "None"
end

-- TRACKER: Keeps track of which blocks are currently "Active" so we don't re-roll constantly
local activeBlocks = setmetatable({}, {__mode = "k"})

local CollectionService = game:GetService("CollectionService")

while true do
	local currentTime = os.date("!*t") 
	
	-- [OPTIMIZATION] Only loop through tagged blocks, not the whole workspace!
	local taggedBlocks = CollectionService:GetTagged("LuckyBlock")

	for _, block in pairs(taggedBlocks) do
		local blockId = block:GetAttribute("BlockID")

		if blockId then
			local data = ItemDatabase.Blocks[blockId]
			local isActiveNow = true

			-- 1. CHECK HOURS
			if data.ActiveHours then
				local startH = data.ActiveHours.Start
				local endH = data.ActiveHours.End
				if currentTime.hour < startH or currentTime.hour >= endH then
					isActiveNow = false
				end
			end

			-- 2. CHECK INTERVALS
			if data.IntervalMinutes then
				if currentTime.min >= data.IntervalMinutes then
					isActiveNow = false
				end
			end

			-- 3. APPLY MUTATION LOGIC
			if isActiveNow then
				if not activeBlocks[block] then
					local newMutation = RollBlockMutation()
					block:SetAttribute("BlockMutation", newMutation)
				end
				activeBlocks[block] = true
			else
				activeBlocks[block] = nil
			end
		end
	end

	task.wait(1)
end