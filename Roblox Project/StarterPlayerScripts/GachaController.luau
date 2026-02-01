local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local UIUtils = require(ReplicatedStorage.GameData.UIUtils) -- Uses Step 1

local GachaController = {}

local SOUND_IDS = {
	SpinTick = "rbxassetid://6895079853", 
	Rarities = {
		Common = "rbxassetid://112017309686871",
		Uncommon = "rbxassetid://112017309686871",
		Rare = "rbxassetid://4612374393",
		Epic = "rbxassetid://4612374393",
		Legendary = "rbxassetid://1839997929",
		Mythical = "rbxassetid://1926608277",
		Cosmic = "rbxassetid://1926608277",
	},
	Mutations = {
		Gold = "rbxassetid://3150375869",
		Diamond = "rbxassetid://78763911472991",
		Platinum = "rbxassetid://135483737426662",
		Midas = "rbxassetid://3150375869",
		Crimson = "rbxassetid://1926608277" 
	}
}

local function CreateSpinGui(position)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 8, 0)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0) 
	billboard.AlwaysOnTop = true

	local anchor = Instance.new("Part")
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Position = position
	anchor.Parent = workspace
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.new(0.5, 0, 0.45, 0) 
	imageLabel.Size = UDim2.new(0.6, 0, 0.45, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.Parent = billboard

	local mutLabel = Instance.new("TextLabel")
	mutLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	mutLabel.Position = UDim2.new(0.5, 0, 0.1, 0) 
	mutLabel.Size = UDim2.new(1, 0, 0.15, 0)
	mutLabel.BackgroundTransparency = 1
	mutLabel.Font = Enum.Font.FredokaOne
	mutLabel.TextScaled = true
	mutLabel.TextColor3 = Color3.new(1, 1, 1)
	mutLabel.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.Position = UDim2.new(0.5, 0, 0.75, 0) 
	nameLabel.Size = UDim2.new(1, 0, 0.15, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	rarityLabel.Position = UDim2.new(0.5, 0, 0.9, 0) 
	rarityLabel.Size = UDim2.new(1, 0, 0.1, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.FredokaOne
	rarityLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
	rarityLabel.TextScaled = true
	rarityLabel.Parent = billboard

	return anchor, imageLabel, mutLabel, nameLabel, rarityLabel
end

local function PlaySound(soundId)
	if not soundId then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Parent = workspace
	sound:Play()
	Debris:AddItem(sound, 5) 
end

local function AddSpecialEffects(imageLabel, rarity, mutation)
	local isHighRarity = (rarity == "Legendary" or rarity == "Mythical" or rarity == "Cosmic")
	local isMutated = (mutation and mutation ~= "None")
	if not isHighRarity and not isMutated then return end 

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 0 
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = imageLabel

	local effectColor = UIUtils.RARITY_COLORS[rarity]
	if isMutated then effectColor = UIUtils.MUTATION_COLORS[mutation] end
	stroke.Color = effectColor

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(stroke, tweenInfo, {Thickness = 6, Transparency = 0.5}):Play()

	if isMutated or rarity == "Mythical" or rarity == "Cosmic" then
		stroke.Thickness = 8 
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 45
		gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, effectColor),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), 
			ColorSequenceKeypoint.new(1, effectColor)
		}
		gradient.Parent = stroke

		task.spawn(function()
			while stroke.Parent do
				gradient.Rotation = gradient.Rotation + 2
				task.wait(0.05)
			end
		end)
	end
end

function GachaController.Spin(position, winningId, mutation)
	local anchor, displayImage, mutLbl, nameLbl, rarityLbl = CreateSpinGui(position)
	
	local allIds = {}
	for id, _ in pairs(ItemDatabase.Items) do table.insert(allIds, id) end

	local currentDelay = 0.05
	local tickSound = Instance.new("Sound")
	tickSound.SoundId = SOUND_IDS.SpinTick
	tickSound.Volume = 0.5
	tickSound.Parent = anchor

	-- [FIX] SPIN LOOP (Now Silhouetted)
	for i = 1, 20 do
		local randomId = allIds[math.random(1, #allIds)]
		local itemData = ItemDatabase.Items[randomId]
		
		displayImage.Image = itemData.ImageId
		displayImage.ImageColor3 = Color3.new(0, 0, 0) -- [ADDED] Force Black Silhouette
		
		pcall(function() tickSound:Play() end)
		nameLbl.Text = "???"
		rarityLbl.Text = "???"
		mutLbl.Text = ""
		
		currentDelay = currentDelay * 1.1 
		task.wait(currentDelay)
	end
	if tickSound then tickSound:Destroy() end

	-- REVEAL
	local winningItem = ItemDatabase.Items[winningId]
	displayImage.Image = winningItem.ImageId
	nameLbl.Text = winningItem.DisplayName
	rarityLbl.Text = winningItem.Rarity
	
	UIUtils.ApplyTextStyle(rarityLbl, winningItem.Rarity)
	AddSpecialEffects(displayImage, winningItem.Rarity, mutation)

	-- [FIX] Tween from Black (Silhouette) to White (Full Color)
	displayImage.ImageColor3 = Color3.new(0, 0, 0) -- Ensure it starts black
	local colorTween = TweenService:Create(displayImage, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {ImageColor3 = Color3.new(1, 1, 1)})
	local sizeTween = TweenService:Create(displayImage, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = UDim2.new(1.2, 0, 0.7, 0)})
	
	colorTween:Play()
	sizeTween:Play()

	task.spawn(function()
		if mutation and mutation ~= "None" then
			mutLbl.Text = mutation .. " MUTATION!" 
			UIUtils.ApplyTextStyle(mutLbl, mutation)
			nameLbl.TextColor3 = UIUtils.MUTATION_COLORS[mutation]
			PlaySound(SOUND_IDS.Mutations[mutation])
		else
			mutLbl.Text = ""
			nameLbl.TextColor3 = Color3.new(1,1,1)
			PlaySound(SOUND_IDS.Rarities[winningItem.Rarity])
		end
	end)

	task.wait(3) 
	if anchor then anchor:Destroy() end
end

return GachaController