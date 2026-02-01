local Blocks = {
	["Common_Block"] = {
		DisplayName = "Common Block",
		Rarity = "Common",
		ImageId = "rbxassetid://94201318234735",

		-- DEFINED DEFAULTS (Fixes Red Lines)
		RespawnTime = 20,    -- Respawns in 20 seconds
		ActiveHours = nil,   -- Always active
		IntervalMinutes = nil
	},
	["Uncommon_Block"] = {
		DisplayName = "Uncommon Block",
		Rarity = "Uncommon",
		ImageId = "rbxassetid://129020090484109",

		-- DEFINED DEFAULTS
		RespawnTime = 20,
		ActiveHours = nil,
		IntervalMinutes = nil
	},
	["Rare_Block"] = {
		DisplayName = "Rare Block",
		Rarity = "Rare",
		ImageId = "rbxassetid://125470227021303",

		-- EXAMPLE: This one has special rules
		RespawnTime = 25,                
		ActiveHours = nil,
		IntervalMinutes = nil
	},
	["Epic_Block"] = {
		DisplayName = "Epic Block",
		Rarity = "Epic",
		ImageId = "rbxassetid://78747106998893",

		RespawnTime = 25,                
		ActiveHours = nil,
		IntervalMinutes = nil
	},
	["Legendary_Block"] = {
		DisplayName = "Legendary Block",
		Rarity = "Legendary",
		ImageId = "rbxassetid://71056554990522",

		-- EXAMPLE: This one has special rules
		RespawnTime = 25,                
		ActiveHours = nil,
		IntervalMinutes = nil
	},
	["Mythical_Block"] = {
		DisplayName = "Mythical Block",
		Rarity = "Mythical",
		ImageId = "rbxassetid://71056554990522",

		RespawnTime = 25,                
		ActiveHours = nil,
		IntervalMinutes = nil
	},
	["Cosmic_Block"] = {
		DisplayName = "Cosmic Block",
		Rarity = "Cosmic",
		ImageId = "rbxassetid://71056554990522",

		RespawnTime = 25,                
		ActiveHours = nil,
		IntervalMinutes = nil
	},
}

return Blocks
