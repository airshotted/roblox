local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase"))
local UIUtils = require(ReplicatedStorage.GameData.UIUtils) -- Uses Step 1

local BlockVisualsController = {}

local function PaintBlock(object)
	local blockId = object:GetAttribute("BlockID")
	if not blockId then return end 

	local blockData = ItemDatabase.Blocks[blockId]
	if not blockData then return end

	local mutation = object:GetAttribute("BlockMutation")

	-- A. HANDLE IMAGE
	task.spawn(function()
		local imageBillboard = object:WaitForChild("BillboardGui", 5) 
		if imageBillboard then
			imageBillboard.StudsOffset = Vector3.new(0, 0, 0)
			local imgLabel = imageBillboard:WaitForChild("ImageLabel", 5)
			if imgLabel then
				imgLabel.BackgroundTransparency = 1 
				local finalImage = blockData.ImageId 

				if mutation and mutation ~= "None" then
					local customTexture = ItemDatabase.MutationTextures and ItemDatabase.MutationTextures[mutation]
					if customTexture then finalImage = customTexture end
				end

				imgLabel.Image = finalImage
				imgLabel.ImageColor3 = Color3.new(1, 1, 1) 
			end
		end
	end)

	-- B. HANDLE TEXT
	task.spawn(function()
		local infoName = "InfoBillboard"
		local textBillboard = object:FindFirstChild(infoName)

		if not textBillboard then
			textBillboard = Instance.new("BillboardGui")
			textBillboard.Name = infoName
			textBillboard.Size = UDim2.new(5, 0, 2, 0) 
			textBillboard.StudsOffset = Vector3.new(0, 2.9, 0)
			textBillboard.AlwaysOnTop = true
			textBillboard.MaxDistance = 100
			textBillboard.Parent = object
		end

		local nameLabel = textBillboard:FindFirstChild("NameLabel")
		if not nameLabel then
			nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.FredokaOne
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.TextStrokeTransparency = 0
			nameLabel.Parent = textBillboard
		end

		local finalText = blockData.DisplayName
		local styleKey = blockData.Rarity 

		if mutation and mutation ~= "None" then
			finalText = mutation .. " " .. finalText
			if ItemDatabase.TextStyles[mutation] then styleKey = mutation end
		end

		nameLabel.Text = finalText
		UIUtils.ApplyTextStyle(nameLabel, styleKey) -- Use Helper!

		local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true) 
		if prompt then prompt.ObjectText = finalText end
	end)
end

function BlockVisualsController.Init()
	print("--- STARTING VISUAL LISTENERS ---")

	local function MonitorBlock(object)
		PaintBlock(object)
		object:GetAttributeChangedSignal("BlockMutation"):Connect(function()
			PaintBlock(object)
		end)
	end

	for _, object in pairs(CollectionService:GetTagged("LuckyBlock")) do
		MonitorBlock(object) 
	end

	CollectionService:GetInstanceAddedSignal("LuckyBlock"):Connect(MonitorBlock)
end

return BlockVisualsController