local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = ReplicatedStorage:WaitForChild("GameData") 

local ItemDatabase = {}

-- MILESTONE CONFIGURATION
ItemDatabase.Milestones = {
	-- How many unique Items/Brainrots to collect
	Items = {5, 10, 25, 50, 100, 200}, 
	
	-- How many unique Lucky Blocks to find
	Blocks = {5, 10, 20, 50, 100} 
}

local Config = require(GameData.Config)
local Items = require(GameData.Items)
local Blocks = require(GameData.Blocks)
local Events = require(GameData.Events)

ItemDatabase.Rarities = Config.Rarities
ItemDatabase.BlockLuck = Config.BlockLuck
ItemDatabase.Mutations = Config.Mutations
ItemDatabase.BlockMutations = Config.BlockMutations
ItemDatabase.MutationTextures = Config.MutationTextures
ItemDatabase.TextStyles = Config.TextStyles

ItemDatabase.Items = Items
ItemDatabase.Blocks = Blocks
ItemDatabase.Events = Events

ItemDatabase.TotalWeight = 0
for _, item in pairs(ItemDatabase.Items) do
	local weight = ItemDatabase.Rarities[item.Rarity]
	if weight then
		ItemDatabase.TotalWeight += weight
	end
end

return ItemDatabase