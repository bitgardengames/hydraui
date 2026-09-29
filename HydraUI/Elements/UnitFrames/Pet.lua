local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-pet-width"] = 110
Defaults["unitframes-pet-health-height"] = 26
Defaults["unitframes-pet-health-reverse"] = false
Defaults["unitframes-pet-health-color"] = "CLASS"
Defaults["unitframes-pet-health-smooth"] = true
Defaults["unitframes-pet-enable-power"] = true
Defaults["unitframes-pet-power-height"] = 3
Defaults["unitframes-pet-power-reverse"] = false
Defaults["unitframes-pet-power-color"] = "POWER"
Defaults["unitframes-pet-power-smooth"] = true
Defaults["unitframes-pet-health-right"] = "[HealthPercent]"
Defaults["unitframes-pet-buffs"] = true
Defaults["unitframes-pet-buff-size"] = 20
Defaults["unitframes-pet-buff-pos"] = "BOTTOM"
Defaults["unitframes-pet-debuff-size"] = 20
Defaults["unitframes-pet-debuff-pos"] = "BOTTOM"
Defaults["pet-enable"] = true
Defaults.PetHealthTexture = "HydraUI 4"
Defaults.PetPowerTexture = "HydraUI 4"

if HydraUI.IsMainline then
	Defaults["unitframes-pet-health-left"] = "[Name(10)]"
else
	Defaults["unitframes-pet-health-left"] = "[HappinessColor][Name(10)]"
end

local UF = HydraUI:GetModule("Unit Frames")

local function BuildPetComponents(factory, frame, unit)
	local width = Settings["unitframes-pet-width"]
	local buffPosition = Settings["unitframes-pet-buff-pos"]
	if Settings["unitframes-pet-buffs"] then
		frame.Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, width, Settings["unitframes-pet-buff-size"],
		buffPosition == "TOP" and "BOTTOM" or "TOP", frame, buffPosition == "TOP" and "TOP" or "BOTTOM", 0, buffPosition == "TOP" and 2 or -2, Settings["unitframes-pet-buff-size"], 2, 5,
		"TOPLEFT", "ANCHOR_TOP", "RIGHT", buffPosition == "TOP" and "UP" or "DOWN", factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	end

	if Settings["unitframes-pet-debuffs"] then
		local debuffPosition = Settings["unitframes-pet-debuff-pos"]
		local besideBuffs = frame.Buffs and buffPosition == debuffPosition
		frame.Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, width, Settings["unitframes-pet-debuff-size"],
		debuffPosition == "TOP" and "BOTTOM" or "TOP", besideBuffs and frame.Buffs or frame, debuffPosition == "TOP" and "TOP" or "BOTTOM", 0, debuffPosition == "TOP" and 2 or -2, Settings["unitframes-pet-debuff-size"], 2, 5,
		"TOPRIGHT", "ANCHOR_TOP", "LEFT", debuffPosition == "TOP" and "UP" or "DOWN", factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	end
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local PetFrameConfig = {
	settingsPrefix = "unitframes-pet",
	healthTextureKey = "PetHealthTexture",
	powerTextureKey = "PetPowerTexture",
	powerTags = false,
	colorTapping = true,
	colorDisconnected = true,
	powerReaction = true,
	raidTarget = true,
	auras = BuildPetComponents,
	range = SingleUnitRange,
}

HydraUI.StyleFuncs["pet"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, PetFrameConfig)
end

local UpdatePetWidth = UF:CreateUnitUpdater("pet", "Width")

local UpdatePetHealthHeight = UF:CreateUnitUpdater("pet", "HealthHeight", {powerHeight = "unitframes-pet-power-height"})

local UpdatePetPowerHeight = UF:CreateUnitUpdater("pet", "PowerHeight", {healthHeight = "unitframes-pet-health-height"})

local UpdatePetHealthColor = UF:CreateUnitUpdater("pet", "HealthColor")

local UpdatePetHealthFill = UF:CreateUnitUpdater("pet", "HealthReverse")

local UpdatePetPowerColor = UF:CreateUnitUpdater("pet", "PowerColor")

local UpdatePetPowerFill = UF:CreateUnitUpdater("pet", "PowerReverse")

local UpdateEnableBuffs = UF:CreateUnitUpdater("pet", "ElementEnabled", {element = "Buffs"})

local UpdateBuffSize = UF:CreateUnitUpdater("pet", "AuraSize", {element = "Buffs", width = "unitframes-pet-width"})

local UpdateBuffPosition = UF:CreateUnitUpdater("pet", "AuraPosition", {element = "Buffs", growthX = "LEFT"})

local UpdateDebuffSize = UF:CreateUnitUpdater("pet", "AuraSize", {element = "Debuffs", width = "unitframes-pet-width"})

local UpdateDebuffPosition = UF:CreateUnitUpdater("pet", "AuraPosition", {element = "Debuffs", growthX = "LEFT", companion = "Buffs", companionPosition = "unitframes-pet-buff-pos"})

local UpdateHealthTexture = UF:CreateUnitUpdater("pet", "HealthTexture")

local UpdatePowerTexture = UF:CreateUnitUpdater("pet", "PowerTexture")

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Pet"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("pet-enable", Settings["pet-enable"], Language["Enable Pet"], Language["Enable the pet unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-pet-width", Settings["unitframes-pet-width"], 60, 320, 1, "Width", "Set the width of the pet unit frame", UpdatePetWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-pet-health-reverse", Settings["unitframes-pet-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePetHealthFill)
	left:CreateSlider("unitframes-pet-health-height", Settings["unitframes-pet-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the pet health bar", UpdatePetHealthHeight)
	left:CreateDropdown("unitframes-pet-health-color", Settings["unitframes-pet-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePetHealthColor)
	left:CreateInput("unitframes-pet-health-left", Settings["unitframes-pet-health-left"], Language["Left Health Text"], Language["Set the text on the left of the pet health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-pet-health-right", Settings["unitframes-pet-health-right"], Language["Right Health Text"], Language["Set the text on the right of the pet health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("PetHealthTexture", Settings.PetHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-pet-power-reverse", Settings["unitframes-pet-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePetPowerFill)
	right:CreateSlider("unitframes-pet-power-height", Settings["unitframes-pet-power-height"], 1, 30, 1, "Power Bar Height", "Set the height of the pet power bar", UpdatePetPowerHeight)
	right:CreateDropdown("unitframes-pet-power-color", Settings["unitframes-pet-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePetPowerColor)
	right:CreateDropdown("PetPowerTexture", Settings.PetPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Buffs"])
	right:CreateSwitch("unitframes-pet-buffs", Settings["unitframes-pet-buffs"], Language["Enable buffs"], Language["Enable debuffs on the unit frame"], UpdateEnableBuffs)
	right:CreateSlider("unitframes-pet-buff-size", Settings["unitframes-pet-buff-size"], 10, 40, 1, "Buff Size", "Set the size of the debuff icons", UpdateBuffSize)
	right:CreateDropdown("unitframes-pet-buff-pos", Settings["unitframes-pet-buff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the buffs"], UpdateBuffPosition)

	right:CreateHeader(Language["Debuffs"])
	right:CreateSlider("unitframes-pet-debuff-size", Settings["unitframes-pet-debuff-size"], 10, 40, 1, "Debuff Size", "Set the size of the debuff icons", UpdateDebuffSize)
	right:CreateDropdown("unitframes-pet-debuff-pos", Settings["unitframes-pet-debuff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the debuffs"], UpdateDebuffPosition)
end)
