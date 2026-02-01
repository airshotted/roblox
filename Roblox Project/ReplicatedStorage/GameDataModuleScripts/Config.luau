local Config = {}

Config.Rarities = {
	Common = 85,
	Uncommon = 65,
	Rare = 35,
	Epic = 15,
	Legendary = 5,
	Mythical = 1,
	Cosmic = 0.1,
}

Config.TextStyles = {
	-- RARITIES
	Common = {
		Color = Color3.fromRGB(200, 200, 200),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 1.5,
	},
	Uncommon = {
		Color = Color3.fromRGB(119, 200, 131),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 1.5,
	},
	Rare = {
		Color = Color3.fromRGB(17, 82, 163),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 1.5,
	},
	Epic = {
		Color = Color3.fromRGB(113, 49, 190),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 2.5,
	},
	Legendary = {
		Color = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 3.2,
		
		Gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 209, 43)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 131, 49)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 209, 43)),
		},
		-- [NEW] This makes it animate!
		AnimationSpeed = 4, 
	},
	Mythical = {
		Color = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 3.2,
		
		Gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(75, 0, 113)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255)),
		},
		-- [NEW] This makes it animate!
		AnimationSpeed = 4, 
	},
	Cosmic = {
		Color = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 3.2,
		
		Gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(177, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 0, 0)), 
			ColorSequenceKeypoint.new(1, Color3.fromRGB(177, 0, 0)),  
		},
		-- [NEW] Fire moves fast!
		AnimationSpeed = 4,
	},

	-- MUTATIONS (These will override Rarity if present)
	Radioactive = {
		Color = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 3,
		
		Gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 177, 18)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(26, 97, 21)), 
			ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 177, 1)),    
		},
		AnimationSpeed = 4,
	},
	Void = {
		Color = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(0, 0, 0),
		Thickness = 3,
		
		Gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 38, 109)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(31, 26, 61)), 
			ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 38, 109)),    
		},
		AnimationSpeed = 4,
	},
	Galaxy = {
		Color = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(0, 0, 0), 
		Thickness = 3,
		
		Gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 10, 171)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(66, 20, 84)), 
			ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 10, 171)),   
		},
		AnimationSpeed = 4,
	},
}


Config.BlockLuck = {
	Common = { 
		Common = 1,
		Uncommon = 1,
		Rare = 1,
		Epic = 1,
		Legendary = 1,
		Mythical = 1,
		Cosmic = 1,
	},
	Uncommon = { 
		Common = 0.8,
		Uncommon = 2,
		Rare = 1.2,
		Epic = 1,
		Legendary = 1,
		Mythical = 1,
		Cosmic = 1,
	},
	Rare = { 
		Common = 0.5, 
		Uncommon = 0.8,
		Rare = 3,     
		Epic = 1.5,
		Legendary = 1.2, 
		Mythical = 1,
		Cosmic = 1,
	},
	Epic = { 
		Common = 0.1, 
		Uncommon = 0.5,
		Rare = 1,     
		Epic = 4,
		Legendary = 2, 
		Mythical = 1.5,
		Cosmic = 1.5,
	},
	Legendary = { 
		Common = 0, 
		Uncommon = 0.1,
		Rare = 0.5,
		Epic = 2,
		Legendary = 10, 
		Mythical = 5,
		Cosmic = 5,
	},
	Mythical = { 
		Common = 0, 
		Uncommon = 0,
		Rare = 0.1,
		Epic = 1,
		Legendary = 5, 
		Mythical = 50,
		Cosmic = 20,
	},
	Cosmic = { 
		Common = 0, 
		Uncommon = 0,
		Rare = 0,
		Epic = 0,
		Legendary = 1, 
		Mythical = 10,
		Cosmic = 50,
	},
}

Config.Mutations = {
	Gold = 50,      
	Diamond = 100,  
	Platinum = 10  
}

Config.BlockMutations = {
	Radioactive = 50,
	Void = 100,
	Galaxy = 300
}

Config.MutationTextures = {
	-- Replace these numbers with your actual Decal IDs!
	Radioactive = "rbxassetid://8508980527", 
	Void = "rbxassetid://692827210",
	Galaxy = "rbxassetid://2015192",
}

return Config