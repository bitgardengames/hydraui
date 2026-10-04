local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-boss-enable"] = true
Defaults["unitframes-boss-width"] = 240
Defaults["unitframes-boss-health-height"] = 28
Defaults["unitframes-boss-health-reverse"] = false
Defaults["unitframes-boss-health-color"] = "CLASS"
Defaults["unitframes-boss-health-smooth"] = true
Defaults["unitframes-boss-health-left"] = "[LevelColor][Level][Plus]|r [Name(30)]"
Defaults["unitframes-boss-health-right"] = "[HealthPercent]"
Defaults["unitframes-boss-power-height"] = 16
Defaults["unitframes-boss-power-reverse"] = false
Defaults["unitframes-boss-power-color"] = "POWER"
Defaults["unitframes-boss-power-smooth"] = true
Defaults["unitframes-boss-power-smooth"] = true
Defaults["unitframes-boss-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-boss-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-boss-buffs"] = true
Defaults["unitframes-boss-buff-size"] = 47
Defaults["unitframes-boss-debuff-size"] = 47
Defaults.BossHealthTexture = "HydraUI 4"
Defaults.BossPowerTexture = "HydraUI 4"

local UF = HydraUI:GetModule("Unit Frames")

local function BuildBossComponents(factory, frame, unit)
	-- Auras
	local Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, Settings["unitframes-boss-width"], Settings["unitframes-boss-buff-size"],
		"RIGHT", frame, "LEFT", -2, 0, Settings["unitframes-boss-buff-size"], 2, 3,
		"TOPRIGHT", "ANCHOR_TOP", "LEFT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, Settings["unitframes-boss-width"], Settings["unitframes-boss-debuff-size"],
		"LEFT", frame, "RIGHT", 2, 0, Settings["unitframes-boss-debuff-size"], 2, 4,
		"TOPLEFT", "ANCHOR_TOP", "RIGHT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, Settings["unitframes-only-player-debuffs"], nil)
	local Castbar = factory:CreateCastbar(frame, frame:GetName() .. " Casting Bar",
		Settings["unitframes-boss-width"] - 28, 22,
		"TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3, Settings["ui-widget-texture"], "Blank",
		-22 - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, 250 * 0.7,
		22, -4, true, nil, true, 0.3, nil,
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)

	frame.Buffs = Buffs
	frame.Debuffs = Debuffs
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local BossFrameConfig = {
	settingsPrefix = "unitframes-boss",
	threat = false,
	powerReverse = false,
	healthTextureKey = "BossHealthTexture",
	powerTextureKey = "BossPowerTexture",
	powerTags = true,
	colorTapping = true,
	colorDisconnected = true,
	powerReaction = true,
	raidTarget = true,
	auras = BuildBossComponents,
	range = SingleUnitRange,
}

HydraUI.StyleFuncs["boss"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, BossFrameConfig)
end

local BossUpdaterOptions = {count = 8}
local UpdateWidth = UF:CreateUnitUpdater("boss", "Width", BossUpdaterOptions)
local UpdateHealthHeight = UF:CreateUnitUpdater("boss", "HealthHeight", {count = 8, powerHeight = "unitframes-boss-power-height"})
local UpdatePowerHeight = UF:CreateUnitUpdater("boss", "PowerHeight", {count = 8, healthHeight = "unitframes-boss-health-height"})
local UpdateHealthColor = UF:CreateUnitUpdater("boss", "HealthColor", BossUpdaterOptions)
local UpdateHealthFill = UF:CreateUnitUpdater("boss", "HealthReverse", BossUpdaterOptions)
local UpdatePowerColor = UF:CreateUnitUpdater("boss", "PowerColor", BossUpdaterOptions)
local UpdatePowerFill = UF:CreateUnitUpdater("boss", "PowerReverse", BossUpdaterOptions)
local UpdateEnableBuffs = UF:CreateUnitUpdater("boss", "ElementEnabled", {count = 8, element = "Auras", component = "Buffs"})
local UpdateBuffSize = UF:CreateUnitUpdater("boss", "AuraSize", {count = 8, element = "Buffs", width = "unitframes-boss-width"})
local UpdateDebuffSize = UF:CreateUnitUpdater("boss", "AuraSize", {count = 8, element = "Debuffs", width = "unitframes-boss-width"})
local UpdateHealthTexture = UF:CreateUnitUpdater("boss", "HealthTexture", BossUpdaterOptions)
local UpdatePowerTexture = UF:CreateUnitUpdater("boss", "PowerTexture", BossUpdaterOptions)

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Bosses"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("unitframes-boss-enable", Settings["unitframes-boss-enable"], Language["Enable Boss Frames"], Language["Enable the boss unit frames"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-boss-width", Settings["unitframes-boss-width"], 60, 320, 1, "Width", "Set the width of the unit frame", UpdateWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-boss-health-reverse", Settings["unitframes-boss-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateHealthFill)
	left:CreateSlider("unitframes-boss-health-height", Settings["unitframes-boss-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the health bar", UpdateHealthHeight)
	left:CreateDropdown("unitframes-boss-health-color", Settings["unitframes-boss-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateHealthColor)
	left:CreateInput("unitframes-boss-health-left", Settings["unitframes-boss-health-left"], Language["Left Health Text"], Language["Set the text on the left of the health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-boss-health-right", Settings["unitframes-boss-health-right"], Language["Right Health Text"], Language["Set the text on the right of the health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("BossHealthTexture", Settings.BossHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-boss-power-reverse", Settings["unitframes-boss-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePowerFill)
	right:CreateSlider("unitframes-boss-power-height", Settings["unitframes-boss-power-height"], 1, 30, 1, "Power Bar Height", "Set the height of the power bar", UpdatePowerHeight)
	right:CreateDropdown("unitframes-boss-power-color", Settings["unitframes-boss-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePowerColor)
	right:CreateDropdown("BossPowerTexture", Settings.BossPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Buffs"])
	right:CreateSwitch("unitframes-boss-buffs", Settings["unitframes-boss-buffs"], Language["Enable buffs"], Language["Enable debuffs on the unit frame"], UpdateEnableBuffs)
	right:CreateSlider("unitframes-boss-buff-size", Settings["unitframes-boss-buff-size"], 10, 50, 1, "Buff Size", "Set the size of the debuff icons", UpdateBuffSize)

	right:CreateHeader(Language["Debuffs"])
	right:CreateSlider("unitframes-boss-debuff-size", Settings["unitframes-boss-debuff-size"], 10, 50, 1, "Debuff Size", "Set the size of the debuff icons", UpdateDebuffSize)
end)
