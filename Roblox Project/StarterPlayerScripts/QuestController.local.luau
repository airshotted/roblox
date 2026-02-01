local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local questUI = playerGui:WaitForChild("QuestUI")
local container = questUI:WaitForChild("TaskContainer") -- Now a ScrollingFrame!
local indexUI = playerGui:WaitForChild("IndexUI")
local milestoneTemplate = indexUI:WaitForChild("MilestoneTemplate")
local milestoneContainer = indexUI -- Shows in center screen

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetDataRemote = Remotes:WaitForChild("GetData")
local UpdateIndexRemote = Remotes:WaitForChild("UpdateIndex")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

---------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------
local COLLECTION_MILESTONES = {
	10, 25, 50, 100, 150, 200, 250, 300, 400, 500, 
	750, 1000, 999999
}

-- STATE VARIABLES
local currentMilestoneIndex = 1 -- We start at the first goal (10)
local cachedOwnedData = {}      -- Store data so the button can refresh the UI

-- PLAYTIME GOALS (In Seconds)
local GOAL_DAILY_PLAYTIME = 30 * 60       -- 30 Minutes
local GOAL_WEEKLY_PLAYTIME = 3 * 60 * 60  -- 3 Hours

local BAR_COLOR = Color3.fromRGB(85, 255, 127)
local TEXT_COLOR = Color3.new(1, 1, 1)

-- LAYOUT ORDERS
local ORDERS = {
	DailyHeader = 100,
	DailyTasks = 101, 
	DailyPlaytime = 102, 
	
	WeeklyHeader = 200,
	WeeklyTasks = 201, 
	WeeklyPlaytime = 202
}

---------------------------------------------------------
-- HELPER: TIME FORMATTER
---------------------------------------------------------
local function FormatTime(seconds)
	if seconds >= 3600 then
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		return string.format("%dh %dm", h, m)
	else
		local m = math.floor(seconds / 60)
		local s = seconds % 60
		return string.format("%dm %ds", m, s)
	end
end

local function PlayMilestoneNotification(data)
	-- 1. CLONE TEMPLATE
	local frame = milestoneTemplate:Clone()
	frame.Parent = milestoneContainer
	frame.Visible = true
	
	local scaler = frame:FindFirstChild("UIScale") or Instance.new("UIScale", frame)
	
	-- 2. APPLY DATA
	local icon = frame:FindFirstChild("Icon")
	local title = frame:FindFirstChild("Title")
	local sub = frame:FindFirstChild("SubText")
	
	if icon then icon.Image = data.Image or "" end
	
	if title then 
		title.Text = data.Title or "TASK COMPLETED!"
		title.TextColor3 = data.Color or Color3.new(1,0.8,0) 
		title.TextSize = 18
		title.Font = Enum.Font.FredokaOne
		title.TextStrokeTransparency = 0.2
	end
	
	if sub then 
		sub.Text = data.Sub or "" 
		sub.TextColor3 = Color3.new(1, 1, 1)
		sub.TextSize = 18
		sub.Font = Enum.Font.FredokaOne
		sub.TextStrokeTransparency = 0.2
	end
	
	-- 3. ANIMATION (Pop In)
	scaler.Scale = 0 
	
	TweenService:Create(scaler, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	}):Play()
	
	-- Sound
	local sfx = Instance.new("Sound", workspace)
	sfx.SoundId = "rbxassetid://1839997929" 
	sfx:Play()
	game:GetService("Debris"):AddItem(sfx, 3)
	
	-- 4. CLEANUP
	task.delay(4, function()
		if frame and frame.Parent and scaler then
			local out = TweenService:Create(scaler, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Scale = 0
			})
			out:Play()
			out.Completed:Wait()
			frame:Destroy()
		end
	end)
end

---------------------------------------------------------
-- UI GENERATOR
---------------------------------------------------------
local function CreateSectionHeader(text, order)
	local id = "Header_" .. text
	if container:FindFirstChild(id) then return end
	
	local lbl = Instance.new("TextLabel")
	lbl.Name = id
	lbl.Text = text
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = Color3.fromRGB(255, 215, 0) 
	lbl.TextSize = 20
	lbl.Size = UDim2.new(1, 0, 0, 30)
	lbl.BackgroundTransparency = 1
	lbl.LayoutOrder = order
	lbl.Parent = container
	
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0,0,0)
	stroke.Parent = lbl
end

local function CreateTaskFrame(id, title, layoutOrder)
	if container:FindFirstChild(id) then return container[id] end
	
	-- 1. Main Frame
	local frame = Instance.new("Frame")
	frame.Name = id
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 45) 
	frame.LayoutOrder = layoutOrder or 9999
	frame.Parent = container
	
	-- 2. Title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Title"
	titleLbl.Text = title
	titleLbl.Font = Enum.Font.SourceSansBold
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextColor3 = TEXT_COLOR
	titleLbl.TextStrokeTransparency = 0
	titleLbl.TextSize = 18
	titleLbl.Size = UDim2.new(0.65, 0, 0.45, 0) 
	titleLbl.Position = UDim2.new(0, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Parent = frame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 2
	titleStroke.Parent = titleLbl
	
	-- 3. Progress Text
	local progressLbl = Instance.new("TextLabel")
	progressLbl.Name = "ProgressText"
	progressLbl.Text = "Loading..."
	progressLbl.Font = Enum.Font.SourceSansBold
	progressLbl.TextXAlignment = Enum.TextXAlignment.Right
	progressLbl.TextColor3 = TEXT_COLOR
	progressLbl.TextStrokeTransparency = 0
	progressLbl.TextSize = 18
	progressLbl.Size = UDim2.new(0.35, 0, 0.45, 0) 
	progressLbl.Position = UDim2.new(0.65, 0, 0, 0)
	progressLbl.BackgroundTransparency = 1
	progressLbl.Parent = frame

	local progressStroke = Instance.new("UIStroke")
	progressStroke.Thickness = 2
	progressStroke.Parent = progressLbl
	
	-- 4. Bar Background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBG"
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBg.BorderSizePixel = 0
	barBg.Position = UDim2.new(0, 0, 0.55, 0) 
	barBg.Size = UDim2.new(1, 0, 0.25, 0) 
	barBg.Parent = frame
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = barBg
	
	-- 5. Fill Bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = BAR_COLOR
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(0, 0, 1, 0) 
	fill.Parent = barBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	
	-- 6. CLAIM BUTTON
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimButton"
	claimBtn.Visible = false -- Hidden until task is done
	claimBtn.Text = "CLAIM REWARD!"
	claimBtn.Font = Enum.Font.FredokaOne
	claimBtn.TextSize = 14
	claimBtn.TextColor3 = Color3.new(1, 1, 1)
	claimBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	claimBtn.Size = UDim2.new(1, 0, 0.55, 0) 
	claimBtn.Position = UDim2.new(0, 0, 0.45, 0)
	claimBtn.AutoButtonColor = true
	claimBtn.Parent = frame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = claimBtn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Thickness = 2
	btnStroke.Color = Color3.fromRGB(255, 255, 255)
	btnStroke.Transparency = 0.5
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Parent = claimBtn
	
	return frame
end

---------------------------------------------------------
-- LOGIC: COLLECTION TASKS (Sticky Logic)
---------------------------------------------------------
local function UpdateCollectionTask(ownedData)
	-- Save data so the button always has the LATEST count
	cachedOwnedData = ownedData 
	
	local taskFrame = CreateTaskFrame("CollectionMilestone", "Index Progress", ORDERS.DailyTasks)
	local claimBtn = taskFrame:FindFirstChild("ClaimButton")
	local progText = taskFrame:FindFirstChild("ProgressText")
	local barBg = taskFrame:FindFirstChild("BarBG")
	
	-- 1. Setup Button Logic (Run Once)
	if not taskFrame:GetAttribute("EventsConnected") then
		taskFrame:SetAttribute("EventsConnected", true)
		
		claimBtn.MouseButton1Click:Connect(function()
			local realCount = 0
			for _ in pairs(cachedOwnedData) do realCount += 1 end
			
			PlayMilestoneNotification({
				Title = "TIER REACHED!",
				Sub = "Total Collection: " .. realCount .. " Items!", 
				Image = "rbxassetid://135483737426662", 
				Color = Color3.fromRGB(255, 215, 0)
			})

			-- 2. Increment Tier (Locally)
			currentMilestoneIndex += 1
			if currentMilestoneIndex > #COLLECTION_MILESTONES then
				currentMilestoneIndex = #COLLECTION_MILESTONES
			end
			
			-- [NEW] Tell Server to Save this!
			local ClaimRemote = Remotes:FindFirstChild("ClaimMilestone")
			if ClaimRemote then
				ClaimRemote:FireServer()
			end
			
			-- 3. Refresh UI
			UpdateCollectionTask(cachedOwnedData)
		end)
	end

	-- 2. Count Items (For the Bar)
	local currentCount = 0
	for _ in pairs(ownedData) do currentCount += 1 end
	
	-- 3. Get Sticky Goal
	local nextGoal = COLLECTION_MILESTONES[currentMilestoneIndex] or 999999
	local ratio = math.clamp(currentCount / nextGoal, 0, 1)
	
	-- 4. Visual State
	if currentCount >= nextGoal then
		-- COMPLETED STATE (Show Button)
		claimBtn.Visible = true
		progText.Visible = false
		barBg.Visible = false
	else
		-- PROGRESS STATE (Show Bar)
		claimBtn.Visible = false
		progText.Visible = true
		barBg.Visible = true
		
		progText.Text = currentCount .. " / " .. nextGoal
		
		TweenService:Create(barBg.Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()
		
		progText.TextColor3 = TEXT_COLOR
	end
end

---------------------------------------------------------
-- LOGIC: PLAYTIME TASKS
---------------------------------------------------------
local function UpdatePlaytimeTasks(dailySeconds, weeklySeconds)
	local function UpdateState(frame, current, goal, formattedTime, taskName)
		local claimBtn = frame:FindFirstChild("ClaimButton")
		local progText = frame:FindFirstChild("ProgressText")
		local barBg = frame:FindFirstChild("BarBG")
		
		-- Setup Click Event (Once per frame)
		if not frame:GetAttribute("EventsConnected") then
			frame:SetAttribute("EventsConnected", true)
			claimBtn.MouseButton1Click:Connect(function()
				-- PLAY NOTIFICATION
				PlayMilestoneNotification({
					Title = "TASK COMPLETED!",
					Sub = "Finished: " .. taskName,
					Image = "rbxassetid://1839997929", -- Checkmark or Clock Icon
					Color = Color3.fromRGB(85, 255, 85) -- Green for tasks
				})
				
				-- Logic for "Claiming" rewards goes here later...
				claimBtn.Text = "CLAIMED"
				claimBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				claimBtn.Active = false
			end)
		end
		
		if current >= goal then
			-- Show Claim Button (Unless already claimed logic added later)
			claimBtn.Visible = true
			progText.Visible = false
			barBg.Visible = false
		else
			claimBtn.Visible = false
			progText.Visible = true
			barBg.Visible = true
			
			local ratio = math.clamp(current / goal, 0, 1)
			barBg.Fill.Size = UDim2.new(ratio, 0, 1, 0)
			progText.Text = formattedTime
			progText.TextColor3 = TEXT_COLOR
		end
	end

	-- UPDATE CALLS (Pass the Task Name now)
	local dailyFrame = CreateTaskFrame("DailyPlaytime", "Play for 30 Mins", ORDERS.DailyPlaytime)
	UpdateState(dailyFrame, dailySeconds, GOAL_DAILY_PLAYTIME, FormatTime(dailySeconds) .. " / 30m", "Daily Playtime")

	local weeklyFrame = CreateTaskFrame("WeeklyPlaytime", "Play for 3 Hours", ORDERS.WeeklyPlaytime)
	UpdateState(weeklyFrame, weeklySeconds, GOAL_WEEKLY_PLAYTIME, FormatTime(weeklySeconds) .. " / 3h", "Weekly Playtime")
end

---------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------
CreateSectionHeader("Daily Tasks", ORDERS.DailyHeader)
CreateSectionHeader("Weekly Tasks", ORDERS.WeeklyHeader)

UpdateIndexRemote.OnClientEvent:Connect(function(newData)
	UpdateCollectionTask(newData or {})
end)

-- 3. Initial Load & Playtime Loop
task.spawn(function()
	local data = GetDataRemote:InvokeServer() or {}
	local GetTimeRemote = Remotes:WaitForChild("GetPlaytime")
	
	-- A. ASK SERVER ONCE (The Baseline)
	local startDaily, startWeekly, savedTier = GetTimeRemote:InvokeServer()
	
	-- Sync Tier
	if savedTier then currentMilestoneIndex = savedTier end
	UpdateCollectionTask(data)
	
	-- B. LOCAL CLOCK (The Counter)
	local clientStartTime = os.time()
	
	while true do
		-- We calculate the time LOCALLY relative to when we asked the server
		local now = os.time()
		local sessionDuration = now - clientStartTime
		
		-- Display = ServerBaseline + SessionTime
		UpdatePlaytimeTasks(startDaily + sessionDuration, startWeekly + sessionDuration)
		
		task.wait(1) 
	end
end)

---------------------------------------------------------
-- HOVER LOGIC
---------------------------------------------------------
container.ScrollBarImageTransparency = 1 
container.BackgroundTransparency = 1    
container.BackgroundColor3 = Color3.new(0, 0, 0) 
container.Active = true 

local fadeInInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function SetHoverState(isHovering)
	local targetBg = isHovering and 0.6 or 1 
	local targetScroll = isHovering and 0 or 1 
	
	TweenService:Create(container, fadeInInfo, {
		BackgroundTransparency = targetBg,
		ScrollBarImageTransparency = targetScroll
	}):Play()
end

container.MouseEnter:Connect(function() SetHoverState(true) end)
container.MouseLeave:Connect(function() SetHoverState(false) end)