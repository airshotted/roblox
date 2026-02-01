local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ItemDatabase = require(ReplicatedStorage:WaitForChild("ItemDatabase")) -- CORRECT (Looks in RepStorage)

local UIUtils = {}

-- CENTRALIZED COLORS
UIUtils.RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(119, 200, 131),
	Rare = Color3.fromRGB(17, 82, 163),
	Epic = Color3.fromRGB(113, 49, 190),
	Legendary = Color3.fromRGB(255, 205, 5),
	Mythical = Color3.fromRGB(255, 79, 240),
	Cosmic = Color3.fromRGB(208, 87, 46),
}

UIUtils.MUTATION_COLORS = {
	Gold = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(85, 255, 255),
	Platinum = Color3.fromRGB(170, 170, 255),
	Midas = Color3.fromRGB(255, 180, 0),
	Crimson = Color3.fromRGB(255, 0, 0),
	None = Color3.new(1, 1, 1)
}

function UIUtils.ApplyTextStyle(label, styleName)
	local style = ItemDatabase.TextStyles[styleName] or ItemDatabase.TextStyles.Common
	label.TextColor3 = style.Color

	local stroke = label:FindFirstChild("StyleStroke") or Instance.new("UIStroke", label)
	stroke.Name = "StyleStroke"
	stroke.Color = style.Stroke
	stroke.Thickness = style.Thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

	local gradient = label:FindFirstChild("StyleGradient")
	if style.Gradient then
		if not gradient then
			gradient = Instance.new("UIGradient")
			gradient.Name = "StyleGradient"
			gradient.Parent = label
		end
		gradient.Color = style.Gradient
		gradient.Enabled = true

		if style.AnimationSpeed then
			gradient.Offset = Vector2.new(-1, 0)
			local tweenInfo = TweenInfo.new(style.AnimationSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
			TweenService:Create(gradient, tweenInfo, {Offset = Vector2.new(1, 0)}):Play()
		else
			gradient.Offset = Vector2.new(0, 0)
		end
	else
		if gradient then gradient.Enabled = false end
	end
end

return UIUtils