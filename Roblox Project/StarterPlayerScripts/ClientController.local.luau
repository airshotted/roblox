local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local UIUtils = require(ReplicatedStorage.GameData.UIUtils)
local BlockVisualsController = require(script.Parent:WaitForChild("BlockVisualsController"))
local GachaController = require(script.Parent:WaitForChild("GachaController"))
local RollRemote = Remotes:WaitForChild("RequestRoll")
local GetDataRemote = Remotes:WaitForChild("GetData")

-- EVENT UI REFERENCES
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local indexUI = playerGui:WaitForChild("IndexUI")

-- NOTIFICATION UI REFERENCES
local notifTemplate = indexUI:WaitForChild("NotificationTemplate")

-- 1. SETUP STACK CONTAINER (Right Side)
local stackFrame = indexUI:FindFirstChild("StackContainer")
if not stackFrame then
	stackFrame = Instance.new("Frame")
	stackFrame.Name = "StackContainer"
	stackFrame.Parent = indexUI
	stackFrame.BackgroundTransparency = 1
	-- Positioned on the Right (0.75), Spanning Top to Bottom (0.1 to 0.9)
	stackFrame.Position = UDim2.new(0.8, 0, 0.1, 0)
	stackFrame.Size = UDim2.new(0.18, 0, 0.8, 0)
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = stackFrame
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5) -- 5px gap between items
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- Stacks from bottom up (Killfeed style)
	-- Change to .Top if you want them falling down from the top
end

local localPlayerIndex = GetDataRemote:InvokeServer() or {}

-- CONSTANTS
local SPIN_DURATION = 20 -- How many items to flash before landing
local INITIAL_SPEED = 0.05 -- How fast it starts flashing

---------------------------------------------------------
-- TYPE A: STACK NOTIFICATION (Items & Blocks)
---------------------------------------------------------
local function PlayNotification(data)
	-- Data: { Image, Title, Name, Color, Sub }
	
	local frame = notifTemplate:Clone()
	frame.Parent = stackFrame
	frame.Visible = true
	frame.BackgroundTransparency = 0
	
	-- SCALE TO FIT: Make them smaller to fit on the side
	frame.Size = UDim2.new(1, 0, 0, 80) -- Fixed height
	
	-- [NEW] ADD UISCALE FOR POP EFFECT
	local scaler = frame:FindFirstChild("UIScale")
	if not scaler then
		scaler = Instance.new("UIScale")
		scaler.Parent = frame
	end
	
	local icon = frame:FindFirstChild("Icon")
	local title = frame:FindFirstChild("Title")
	local nameLbl = frame:FindFirstChild("ItemName")
	local sub = frame:FindFirstChild("SubText")
	
	if icon then icon.Image = data.Image or "" end
	
	if title then 
		title.Text = data.Title or "ALERT"
		title.TextColor3 = data.Color or Color3.new(1,1,1) -- Keeps the color, but no animation
		title.TextSize = 18
		title.TextStrokeTransparency = 0.2
		title.Font = Enum.Font.FredokaOne
		
	end
	
	if nameLbl then 
		nameLbl.Text = data.Name or "Unknown" 
		nameLbl.TextSize = 18
		nameLbl.TextColor3 = Color3.new(1, 1, 1) -- Standard White Name
		nameLbl.TextStrokeTransparency = 0.2
		nameLbl.Font = Enum.Font.FredokaOne
	end
	
	if sub then 
		sub.Text = data.Sub or "" 
		sub.TextSize = 18
		sub.Font = Enum.Font.FredokaOne
		
		-- [MOVED HERE] Only animate the Rarity Text (e.g. "MYTHICAL")
		if data.Style then
			UIUtils.ApplyTextStyle(sub, data.Style)
		else
			-- Fallback color if no style exists
			sub.TextColor3 = data.Color or Color3.new(1, 1, 1)
		end
	end
	
	-- [NEW] ANIMATE IN (Pop Effect)
	scaler.Scale = 0 -- Start invisible/tiny
	
	-- Elastic Tween (The "Boing" effect)
	TweenService:Create(scaler, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	}):Play()
	
	-- LIMIT CHECK: Keep only X items to fit on screen
	local activeNotifs = stackFrame:GetChildren()
	if #activeNotifs > 7 then 
		for i, child in ipairs(activeNotifs) do
			if child:IsA("Frame") then
				child:Destroy()
				break -- Delete just the first (oldest) one
			end
		end
	end
	
	-- AUTO CLEANUP
	task.delay(4, function()
		if frame and frame.Parent and scaler then
			-- [NEW] Animate Out (Shrink to 0)
			local out = TweenService:Create(scaler, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Scale = 0
			})
			out:Play()
			
			-- Wait for animation to finish, then destroy
			out.Completed:Wait()
			frame:Destroy()
		end
	end)
end

BlockVisualsController.Init()


---------------------------------------------------------
-- INTERACTION HANDLING
---------------------------------------------------------
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local block = prompt.Parent
	
	-- FIX: Check for Attachment FIRST, before looking for the ID
	if block:IsA("Attachment") then
		block = block.Parent
	end
	
	-- NOW it is safe to grab the ID from the actual Part
	local blockId = block:GetAttribute("BlockID")
	
	if block and blockId then
		local blockData = ItemDatabase.Blocks[blockId]
		local originalPos = block.Position

		-- [NEW] NOTIFY BLOCK COLLECTION IMMEDIATELY
		local blockMutation = block:GetAttribute("BlockMutation")
		local bName = blockData.DisplayName
		local bColor = UIUtils.RARITY_COLORS[blockData.Rarity] or Color3.new(1,1,1)
		
		local fullBlockId = blockId
		if blockMutation and blockMutation ~= "None" then
			bName = blockMutation .. " " .. bName
			fullBlockId = blockId .. "_" .. blockMutation
			-- Mutation Color Override
			if blockMutation == "Radioactive" then bColor = Color3.fromRGB(50, 255, 50) end
			if blockMutation == "Void" then bColor = Color3.fromRGB(150, 50, 255) end
			if blockMutation == "Galaxy" then bColor = Color3.fromRGB(80, 80, 255) end
		end
		
		local bTitle = "New Block!"
		-- CHECK DUPLICATE STATUS
		if localPlayerIndex[fullBlockId] then
			bTitle = "Already Owned!" -- Explicit text so you know it's a duplicate
			bColor = Color3.fromRGB(150, 150, 150) -- Turn the notification Grey/Silver
		end

		-- Wrapped in task.spawn so it doesn't pause the script!
		task.spawn(function()
			PlayNotification({
				Image = blockData.ImageId, 
				Title = bTitle,
				Name = bName,
				Color = bColor,
				Sub = "Lucky Block",
				Style = blockData.Rarity
			})
		end)

		block:SetAttribute("IsCollected", true)

		-- 2. HIDE VISUALS
		prompt.Enabled = false
		block.Transparency = 1 
		
		local luckyBlockGui = block:FindFirstChildOfClass("BillboardGui")
		if luckyBlockGui then luckyBlockGui.Enabled = false end

		local textGui = block:FindFirstChild("InfoBillboard")
		if textGui then textGui.Enabled = false end

		local inventorySnapshot = table.clone(localPlayerIndex)

		local winningId, mutation = RollRemote:InvokeServer(block)

		if winningId then
			GachaController.Spin(originalPos, winningId, mutation)

			local winningItem = ItemDatabase.Items[winningId]
			local color = UIUtils.RARITY_COLORS[winningItem.Rarity] or Color3.new(1,1,1)
			
			-- Handle Mutation Colors
			if mutation and mutation ~= "None" then
				if mutation == "Radioactive" then color = Color3.fromRGB(50, 255, 50) end
				if mutation == "Void" then color = Color3.fromRGB(150, 50, 255) end
				-- Add others...
			end
			
			task.spawn(function()
				-- Reduced delay: Pop up as soon as the item is revealed (Animation takes ~2s)
				task.wait(0.3) 
				
				-- LOGIC: Check if it's new or duplicate
				local fullItemId = winningId
				if mutation and mutation ~= "None" then
					fullItemId = winningId .. "_" .. mutation
				end
				
				local titleText = "New Discovery!"
				if inventorySnapshot[fullItemId] then
					titleText = "Already Owned!"
					
					-- [FIX] TURN IT GRAY!
					-- This was missing, so it was staying the Rarity Color.
					color = Color3.fromRGB(150, 150, 150) 
				end
				
				-- LOGIC: Format Name with Mutation
				local dispName = winningItem.DisplayName
				if mutation and mutation ~= "None" then
					dispName = mutation .. " " .. dispName
				end
				
				PlayNotification({
					Image = winningItem.ImageId,
					Title = titleText,
					Name = dispName,
					Color = color,
					Sub = winningItem.Rarity,
					Style = winningItem.Rarity
				})
			end)
		end

		-- 4. MASTER CONTROL RESPAWN LOGIC
		local respawnTime = blockData.RespawnTime or 20
		
		if respawnTime >= 0 then
			task.wait(respawnTime)
			
			local rates = ItemDatabase.BlockMutations
			local localMut = "None"
			
			-- [FIX] Safety Checks to prevent "number expected, got nil"
			if rates and rates.Galaxy and math.random(1, rates.Galaxy) == 1 then localMut = "Galaxy"
			elseif rates and rates.Void and math.random(1, rates.Void) == 1 then localMut = "Void"
			elseif rates and rates.Radioactive and math.random(1, rates.Radioactive) == 1 then localMut = "Radioactive"
			end
			
			block:SetAttribute("BlockMutation", localMut)
			block:SetAttribute("IsCollected", false)
		end
	end
end)

---------------------------------------------------------
-- MASTER TIME CONTROL LOOP (Cleaned)
---------------------------------------------------------
task.spawn(function()
	print("--- Client Visibility Loop Started ---") 
	
	while true do
		local currentTime = os.date("!*t") 
		-----------------------------------------------------
		-- 1. CONVEYOR TIMER (Re-Implemented)
		-----------------------------------------------------
		-- Find the folder and the part
		local ConveyorFolder = workspace:WaitForChild("ConveyorSystem", 5)
		if ConveyorFolder then
			local timerPart = ConveyorFolder:FindFirstChild("ConveyorTimerPart")
			
			if timerPart then
				-- Find the Label
				local sGui = timerPart:FindFirstChild("SurfaceGui")
				local label = sGui and sGui:FindFirstChild("TimerLabel")
				
				if label then
					local currentTime = os.time()
					
					-- 1. GET BOTH TIMES
					local legTime = ConveyorFolder:GetAttribute("NextLegendaryTime")
					local mythTime = ConveyorFolder:GetAttribute("NextMythicalTime")
					
					-- 2. HELPER FUNCTION (Updated for Colors)
					local function GetLine(title, targetTime, colorHex)
						-- Wrap the title in color tags
						local styledTitle = string.format('<font color="%s"><b>%s</b></font>', colorHex, title)

						if not targetTime then return styledTitle .. ": --:--" end

						local diff = math.max(0, targetTime - currentTime)
						if diff > 0 then
							local m = math.floor(diff / 60)
							local s = diff % 60
							return string.format("%s: %02d:%02d", styledTitle, m, s)
						else
							-- When spawning, make the alert RED
							return styledTitle .. ": <font color='#FF0000'>SPAWNING!</font>"
						end
					end

					-- 3. COMBINE THEM (Pass Hex Colors Here)
					-- #FFD700 is Gold, #B04EF0 is Purple
					local line1 = GetLine("LEGENDARY", legTime, "#FFD700") 
					local line2 = GetLine("MYTHICAL", mythTime, "#B04EF0")
					
					label.Text = line1 .. "\n" .. line2
					label.TextColor3 = Color3.new(1, 1, 1)
				end
			end
		end

		-- 3. BLOCK VISIBILITY CHECK (Keep this!)
		for _, block in pairs(game:GetService("CollectionService"):GetTagged("LuckyBlock")) do
			local blockId = block:GetAttribute("BlockID")
			
			if blockId then
				local data = ItemDatabase.Blocks[blockId]
				local isCollected = block:GetAttribute("IsCollected") 
				local shouldBeVisible = true
				
				-- CHECK 1: Real World Hours
				if data.ActiveHours then
					local startH = data.ActiveHours.Start
					local endH = data.ActiveHours.End
					if currentTime.hour < startH or currentTime.hour >= endH then
						shouldBeVisible = false
					end
				end
				
				-- CHECK 2: Intervals 
				if data.IntervalMinutes then
					if currentTime.min >= data.IntervalMinutes then
						shouldBeVisible = false
					end
				end

				local currentMut = block:GetAttribute("BlockMutation")
				if currentMut and currentMut ~= "None" then
					shouldBeVisible = true
				end
				
				-- CHECK 3: Is it currently collected/on cooldown?
				if isCollected then
					shouldBeVisible = false
				end
				
				-- APPLY VISIBILITY
				local imageGui = block:FindFirstChild("BillboardGui")
				local textGui = block:FindFirstChild("InfoBillboard")
				
				local isCurrentlyVisible = imageGui and imageGui.Enabled
				
				if isCurrentlyVisible ~= shouldBeVisible then
					local prompt = block:FindFirstChildWhichIsA("ProximityPrompt")
					if prompt then prompt.Enabled = shouldBeVisible end
					if imageGui then imageGui.Enabled = shouldBeVisible end
					if textGui then textGui.Enabled = shouldBeVisible end
				end
			end
		end
		
		task.wait(1) 
	end
end)

---------------------------------------------------------
-- DATA LISTENER (For Duplicate Checks)
---------------------------------------------------------
local UpdateIndexRemote = Remotes:WaitForChild("UpdateIndex")

UpdateIndexRemote.OnClientEvent:Connect(function(data)
	localPlayerIndex = data or {}
end)