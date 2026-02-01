local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService") -- [NEW] For mouse tracking
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ActiveEventVal = ReplicatedStorage:WaitForChild("ActiveEvent")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

-- UI REFERENCES
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local eventUI = playerGui:WaitForChild("EventUI")
local eventFrame = eventUI:WaitForChild("EventFrame")

local titleLbl, timerLbl
local currentEventLoop = nil

-- TOOLTIP STATE
local tooltipFrame = nil
local toolLabels = {} -- Stores references to the text labels inside tooltip

---------------------------------------------------------
-- 1. SETUP UI (Event Frame & Tooltip)
---------------------------------------------------------
local function SetupEventUI()
	-- A. SETUP MAIN EVENT FRAME
	eventFrame.Active = true -- Crucial for MouseEnter/Leave to work!
	eventFrame.BackgroundTransparency = 1 -- Start invisible

	-- Clear old junk
	for _, child in pairs(eventFrame:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("UICorner") then child:Destroy() end
	end

	-- Add Corner for style
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = eventFrame

	-- Title Label
	titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "TitleLabel"
	titleLbl.Parent = eventFrame
	titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0.4, 0)
	titleLbl.Position = UDim2.new(0, 0, 0.1, 0)
	titleLbl.Font = Enum.Font.FredokaOne
	titleLbl.TextScaled = true
	titleLbl.TextColor3 = Color3.new(1, 1, 1)
	titleLbl.TextStrokeTransparency = 0
	titleLbl.Text = "LOADING..."

	-- Timer Label
	timerLbl = Instance.new("TextLabel")
	timerLbl.Name = "TimerLabel"
	timerLbl.Parent = eventFrame
	timerLbl.BackgroundTransparency = 1
	timerLbl.Size = UDim2.new(1, 0, 0.3, 0)
	timerLbl.Position = UDim2.new(0, 0, 0.5, 0)
	timerLbl.Font = Enum.Font.FredokaOne
	timerLbl.TextScaled = true
	timerLbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	timerLbl.TextStrokeTransparency = 0
	timerLbl.Text = "00:00"

	---------------------------------------------------------
	-- B. SETUP DYNAMIC TOOLTIP
	---------------------------------------------------------
	if tooltipFrame then tooltipFrame:Destroy() end

	tooltipFrame = Instance.new("Frame")
	tooltipFrame.Name = "EventTooltip"
	tooltipFrame.Size = UDim2.new(0, 220, 0, 100) -- Size of the popup
	tooltipFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tooltipFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	tooltipFrame.BorderSizePixel = 2
	tooltipFrame.ZIndex = 100 -- Float above everything
	tooltipFrame.Visible = false
	tooltipFrame.Parent = eventUI 

	local tipCorner = Instance.new("UICorner")
	tipCorner.CornerRadius = UDim.new(0, 6)
	tipCorner.Parent = tooltipFrame
	
	-- Helper to make lines in the tooltip
	local function CreateTipLine(name, yPos, color)
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Size = UDim2.new(1, -20, 0.25, 0)
		lbl.Position = UDim2.new(0, 10, yPos, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = color or Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 101
		lbl.Parent = tooltipFrame
		return lbl
	end
	
	toolLabels.Type = CreateTipLine("Type", 0.1, Color3.fromRGB(200, 200, 200))
	toolLabels.Luck = CreateTipLine("Luck", 0.35, Color3.fromRGB(255, 215, 0)) -- Gold
	toolLabels.Mut = CreateTipLine("Mutation", 0.6, Color3.fromRGB(170, 0, 255)) -- Purple
end

SetupEventUI()

---------------------------------------------------------
-- 2. HELPER: TIME LOGIC
---------------------------------------------------------
local function GetSecondsRemaining(eventId)
	-- A. BASE CYCLE (Sunny/Night)
	if eventId == "SunnyDay" or eventId == "NightTime" then
		local totalCycle = 12 * 60 
		local timeInCycle = os.time() % totalCycle

		if eventId == "SunnyDay" then
			return math.max(0, (6 * 60) - timeInCycle)
		else
			return math.max(0, totalCycle - timeInCycle)
		end
	end

	-- B. SPECIAL EVENTS
	local data = ItemDatabase.Events[eventId]
	if not data then return 0 end
	local schedule = data.Schedule

	if schedule.Type == "Interval" then
		local serverTime = workspace.DistributedGameTime
		local cycleDuration = schedule.IntervalMinutes * 60
		local activeDuration = schedule.DurationMinutes * 60
		local timeInCycle = serverTime % cycleDuration
		return math.max(0, activeDuration - timeInCycle)

	elseif schedule.Type == "RealTime" and schedule.ActiveHours then
		local now = os.date("*t")
		local endHour = schedule.ActiveHours.End
		local hoursLeft = 0

		if endHour > now.hour then hoursLeft = endHour - now.hour
		else hoursLeft = (24 - now.hour) + endHour end

		local totalSecondsLeft = (hoursLeft * 3600) - (now.min * 60) - now.sec
		return math.max(0, totalSecondsLeft)
	end

	return 0
end

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d", m, s)
end

---------------------------------------------------------
-- 3. VISUALS HANDLER
---------------------------------------------------------
local function UpdateEventVisuals(eventId)
	local data = ItemDatabase.Events[eventId]
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if currentEventLoop then
		task.cancel(currentEventLoop)
		currentEventLoop = nil
	end

	if data then
		-- A. UI UPDATES
		eventFrame.Visible = true
		titleLbl.Text = data.DisplayName

		local styles = data.UI or {} 
		titleLbl.TextColor3 = styles.TitleColor or Color3.new(1,1,1)
		titleLbl.Font = styles.TitleFont or Enum.Font.FredokaOne
		timerLbl.TextColor3 = styles.TimerColor or Color3.new(1,1,1)

		-- B. LIGHTING UPDATES
		if data.Visuals then
			local v = data.Visuals
			if v.OutdoorAmbient then
				TweenService:Create(Lighting, tweenInfo, {OutdoorAmbient = v.OutdoorAmbient}):Play()
			end
			if v.FogColor then
				TweenService:Create(Lighting, tweenInfo, {FogColor = v.FogColor}):Play()
			end
			if v.TimeOfDay then
				local h, m = v.TimeOfDay:match("(%d+):(%d+)")
				if h and m then
					local targetClock = tonumber(h) + (tonumber(m) / 60)
					TweenService:Create(Lighting, tweenInfo, {ClockTime = targetClock}):Play()
				end
			end
		end

		-- C. START TIMER
		currentEventLoop = task.spawn(function()
			while true do
				local timeLeft = GetSecondsRemaining(eventId)
				timerLbl.Text = FormatTime(timeLeft)
				task.wait(1)
			end
		end)
	else
		eventFrame.Visible = false
	end
end

---------------------------------------------------------
-- 4. INTERACTION: HOVER & TOOLTIP
---------------------------------------------------------
-- Update Tooltip Text Content
local function UpdateTooltipContent()
	local eventId = ActiveEventVal.Value
	local data = ItemDatabase.Events[eventId]
	if not data then return end

	-- 1. EVENT TYPE
	local typeText = "Normal Event"
	if eventId ~= "SunnyDay" and eventId ~= "NightTime" then
		typeText = "Special Event!"
		toolLabels.Type.TextColor3 = Color3.fromRGB(255, 80, 80) 
	else
		toolLabels.Type.TextColor3 = Color3.fromRGB(200, 200, 200) 
	end
	toolLabels.Type.Text = "Type: " .. typeText

	-- 2. LUCK
	local luck = data.GlobalLuck or 1
	toolLabels.Luck.Text = "Luck: " .. luck .. "x"

	-- 3. MUTATION
	local mut = data.EventMutation or "None"
	if mut ~= "None" then
		toolLabels.Mut.Text = "Active: " .. mut .. " Mutation"
		toolLabels.Mut.TextColor3 = Color3.fromRGB(170, 0, 255)
	else
		toolLabels.Mut.Text = "Active: None"
		toolLabels.Mut.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

-- HELPER: TOGGLE VISIBILITY
local function SetTooltipState(isVisible)
	tooltipFrame.Visible = isVisible
	local targetAlpha = isVisible and 0.3 or 1
	TweenService:Create(eventFrame, TweenInfo.new(0.3), {BackgroundTransparency = targetAlpha}):Play()
	
	if isVisible then
		UpdateTooltipContent()
	end
end

-- PC: Mouse Enter/Leave
eventFrame.MouseEnter:Connect(function()
	SetTooltipState(true)
end)

eventFrame.MouseLeave:Connect(function()
	SetTooltipState(false)
end)

-- MOBILE: Tap to Toggle
eventFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		-- Toggle state based on current visibility
		SetTooltipState(not tooltipFrame.Visible)
	end
end)

-- Follow Mouse/Touch Loop
RunService.RenderStepped:Connect(function()
	if tooltipFrame.Visible then
		local mPos = UserInputService:GetMouseLocation()
		
		-- On Mobile, mPos is the last touched location.
		-- We offset it so your finger doesn't cover the text.
		tooltipFrame.Position = UDim2.fromOffset(mPos.X + 15, mPos.Y + 15)
	end
end)

---------------------------------------------------------
-- INIT LISTENERS
---------------------------------------------------------
ActiveEventVal.Changed:Connect(UpdateEventVisuals)
ActiveEventVal:GetAttributeChangedSignal("LiveLuckMult"):Connect(function()
	UpdateEventVisuals(ActiveEventVal.Value)
	if tooltipFrame.Visible then UpdateTooltipContent() end
end)

UpdateEventVisuals(ActiveEventVal.Value)