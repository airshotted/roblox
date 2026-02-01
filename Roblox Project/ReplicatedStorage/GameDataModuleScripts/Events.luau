local Events = {
	["SunnyDay"] = {
		DisplayName = "Sunny Day",
		Priority = 1, -- Low priority (Default state)
		GlobalLuck = 1,
		
		-- UI Styling
		UI = {
			TitleColor = Color3.fromRGB(255, 230, 150),
			TitleFont = Enum.Font.FredokaOne,
			TimerColor = Color3.fromRGB(255, 255, 255),
		},
		
		Visuals = {
			TimeOfDay = "14:00:00",
			OutdoorAmbient = Color3.fromRGB(200, 200, 200),
			FogColor = Color3.fromRGB(192, 192, 192),
		}
	},

	["NightTime"] = {
		DisplayName = "Night Time",
		Priority = 1,
		GlobalLuck = 1,
		
		UI = {
			TitleColor = Color3.fromRGB(100, 100, 255),
			TitleFont = Enum.Font.FredokaOne,
			TimerColor = Color3.fromRGB(200, 200, 255),
		},

		Visuals = {
			TimeOfDay = "00:00:00",
			OutdoorAmbient = Color3.fromRGB(50, 50, 80),
			FogColor = Color3.fromRGB(20, 20, 40),
		}
	},

	["BloodMoon"] = {
		DisplayName = "BLOOD MOON",
		Priority = 10,
		EventMutation = "Crimson",
		MutationChance = 10,

		GlobalLuck = 1.5, 

		Schedule = {
			Type = "RealTime",
			ActiveHours = {Start = 17, End = 18}
		},

		-- NEW: UI STYLING
		UI = {
			TitleColor = Color3.fromRGB(255, 0, 0), -- Red Title
			TitleFont = Enum.Font.Creepster,        -- Spooky Font

			MutationColor = Color3.fromRGB(255, 100, 100),
			TimerColor = Color3.fromRGB(200, 0, 0),

			StrokeColor = Color3.fromRGB(50, 0, 0), -- Dark Red Outline
		},

		Visuals = {
			TimeOfDay = "00:00:00",
			OutdoorAmbient = Color3.fromRGB(150, 0, 0),
			FogColor = Color3.fromRGB(50, 0, 0),
		}
	},

	["GoldenHour"] = {
		DisplayName = "Golden Hour",
		Priority = 5,
		EventMutation = "Midas",
		MutationChance = 20,

		Schedule = {
			Type = "Interval", 
			IntervalMinutes = 60,
			DurationMinutes = 10 
		},

		-- NEW: UI STYLING
		UI = {
			TitleColor = Color3.fromRGB(255, 215, 0), -- Gold Title
			TitleFont = Enum.Font.FredokaOne,         -- Friendly Font

			MutationColor = Color3.fromRGB(255, 255, 200),
			TimerColor = Color3.fromRGB(255, 220, 100),

			StrokeColor = Color3.fromRGB(100, 80, 0), -- Brownish Outline
		},

		Visuals = {
			TimeOfDay = "17:30:00",
			OutdoorAmbient = Color3.fromRGB(255, 221, 51),
		}
	},
}

return Events 
