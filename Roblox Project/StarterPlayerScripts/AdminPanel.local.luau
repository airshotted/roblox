local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminRemote = Remotes:WaitForChild("AdminAction")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. CREATE SCREEN GUI
local screen = Instance.new("ScreenGui")
screen.Name = "CustomAdminPanel"
screen.ResetOnSpawn = false
screen.Enabled = false -- Hidden by default (Press P to toggle)
screen.Parent = playerGui

-- 2. CREATE MAIN FRAME
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 350)
frame.Position = UDim2.new(0.05, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screen

local title = Instance.new("TextLabel")
title.Text = "EVENT CONTROL"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.FredokaOne
title.TextSize = 20
title.Parent = frame

-- 3. EVENT LIST (Scrolling Frame)
local scroller = Instance.new("ScrollingFrame")
scroller.Size = UDim2.new(0.9, 0, 0.4, 0)
scroller.Position = UDim2.new(0.05, 0, 0.15, 0)
scroller.BackgroundTransparency = 0.8
scroller.BackgroundColor3 = Color3.new(0,0,0)
scroller.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scroller

-- Populate List automatically from Database
for eventId, _ in pairs(ItemDatabase.Events) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.Text = eventId
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Parent = scroller

	btn.MouseButton1Click:Connect(function()
		AdminRemote:FireServer("StartEvent", eventId)
	end)
end
scroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)

-- 4. STOP BUTTON
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.9, 0, 0, 40)
stopBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
stopBtn.Text = "STOP EVENT"
stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Font = Enum.Font.FredokaOne
stopBtn.Parent = frame

stopBtn.MouseButton1Click:Connect(function()
	AdminRemote:FireServer("StopEvent")
end)

-- 5. LUCK EDITOR
local luckBox = Instance.new("TextBox")
luckBox.Size = UDim2.new(0.6, 0, 0, 30)
luckBox.Position = UDim2.new(0.05, 0, 0.8, 0)
luckBox.PlaceholderText = "Luck Mult (e.g. 5)"
luckBox.Text = ""
luckBox.BackgroundColor3 = Color3.new(1,1,1)
luckBox.Parent = frame

local setLuckBtn = Instance.new("TextButton")
setLuckBtn.Size = UDim2.new(0.25, 0, 0, 30)
setLuckBtn.Position = UDim2.new(0.7, 0, 0.8, 0)
setLuckBtn.Text = "SET"
setLuckBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
setLuckBtn.Parent = frame

setLuckBtn.MouseButton1Click:Connect(function()
	local amount = tonumber(luckBox.Text)
	if amount then
		AdminRemote:FireServer("SetLuck", amount)
	end
end)

-- 6. TOGGLE KEYBIND (Press 'P')
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
		screen.Enabled = not screen.Enabled
	end
end)