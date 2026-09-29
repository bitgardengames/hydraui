local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-focus-width"] = 200
Defaults["unitframes-focus-health-height"] = 26
Defaults["unitframes-focus-health-reverse"] = false
Defaults["unitframes-focus-health-color"] = "CLASS"
Defaults["unitframes-focus-health-smooth"] = true
Defaults["unitframes-focus-power-height"] = 6
Defaults["unitframes-focus-power-reverse"] = false
Defaults["unitframes-focus-power-color"] = "POWER"
Defaults["unitframes-focus-power-smooth"] = true
Defaults["unitframes-focus-health-left"] = "[Name(10)]"
Defaults["unitframes-focus-health-right"] = "[HealthPercent]"
Defaults["focus-enable"] = true
Defaults["focus-enable-castbar"] = true
Defaults["focus-enable-buffs"] = true
Defaults.FocusHealthTexture = "HydraUI 4"
Defaults.FocusPowerTexture = "HydraUI 4"

local UF = HydraUI:GetModule("Unit Frames")

local function BuildFocusComponents(factory, frame, unit)
	if Settings["focus-enable-castbar"] then
		factory:CreateCastbar(frame, nil,
		Settings["unitframes-focus-width"] - 30, 24,
		"TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3, Settings["ui-widget-texture"], "Blank",
		-24 - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, 250 * 0.7,
		24, -4, true, nil, true, 0.7, nil,
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
	end

	-- Auras
	local AuraSize = Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3
	local Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, (AuraSize * 3) + 4, AuraSize,
		"LEFT", frame, "RIGHT", 2, 0, AuraSize, 2, 3,
		"LEFT", "ANCHOR_TOP", "RIGHT", nil, factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, (AuraSize * 3) + 4, AuraSize,
		"LEFT", Buffs, "RIGHT", 2, 0, AuraSize, 2, 3,
		"LEFT", "ANCHOR_TOP", "RIGHT", nil, factory.PostCreateIcon, factory.PostUpdateIcon, nil, Settings["unitframes-only-focus-debuffs"], nil)

	frame.Buffs = Buffs
	frame.Debuffs = Debuffs
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local FocusFrameConfig = {
	settingsPrefix = "unitframes-focus",
	healthTextureKey = "FocusHealthTexture",
	powerTextureKey = "FocusPowerTexture",
	powerTags = false,
	colorTapping = false,
	colorDisconnected = false,
	powerReaction = false,
	raidTarget = false,
	auras = BuildFocusComponents,
}

HydraUI.StyleFuncs["focus"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, FocusFrameConfig)
end

local UpdateFocusWidth = UF:CreateUnitUpdater("focus", "Width")

local UpdateFocusHealthHeight = UF:CreateUnitUpdater("focus", "HealthHeight", {powerHeight = "unitframes-focus-power-height"})

local UpdateFocusPowerHeight = UF:CreateUnitUpdater("focus", "PowerHeight", {healthHeight = "unitframes-focus-health-height"})

local UpdateFocusHealthColor = UF:CreateUnitUpdater("focus", "HealthColor")

local UpdateFocusHealthFill = UF:CreateUnitUpdater("focus", "HealthReverse")

local UpdateFocusPowerColor = UF:CreateUnitUpdater("focus", "PowerColor")

local UpdateShowFocusBuffs = UF:CreateUnitUpdater("focus", "ElementEnabled", {element = "Auras", component = "Buffs", forceUpdate = true})

local UpdateFocusPowerFill = UF:CreateUnitUpdater("focus", "PowerReverse")

local UpdateHealthTexture = UF:CreateUnitUpdater("focus", "HealthTexture")

local UpdatePowerTexture = UF:CreateUnitUpdater("focus", "PowerTexture")

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Focus"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("focus-enable", Settings["focus-enable"], Language["Enable Focus"], Language["Enable the focus unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-focus-width", Settings["unitframes-focus-width"], 60, 320, 1, "Width", "Set the width of the focus unit frame", UpdateFocusWidth)
	left:CreateSwitch("focus-enable-castbar", Settings["focus-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the cast bar"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-focus-health-reverse", Settings["unitframes-focus-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateFocusHealthFill)
	left:CreateSlider("unitframes-focus-health-height", Settings["unitframes-focus-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the focus health bar", UpdateFocusHealthHeight)
	left:CreateDropdown("unitframes-focus-health-color", Settings["unitframes-focus-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateFocusHealthColor)
	left:CreateInput("unitframes-focus-health-left", Settings["unitframes-focus-health-left"], Language["Left Health Text"], Language["Set the text on the left of the focus health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-focus-health-right", Settings["unitframes-focus-health-right"], Language["Right Health Text"], Language["Set the text on the right of the focus health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("FocusHealthTexture", Settings.FocusHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-focus-power-reverse", Settings["unitframes-focus-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateFocusPowerFill)
	right:CreateSlider("unitframes-focus-power-height", Settings["unitframes-focus-power-height"], 1, 30, 1, "Power Bar Height", "Set the height of the focus power bar", UpdateFocusPowerHeight)
	right:CreateDropdown("unitframes-focus-power-color", Settings["unitframes-focus-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateFocusPowerColor)
	right:CreateDropdown("FocusPowerTexture", Settings.FocusPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Buffs"])
	right:CreateSwitch("focus-enable-buffs", Settings["focus-enable-buffs"], Language["Show Focus Buffs"], Language["Show auras next to the focus unit frame"], UpdateShowFocusBuffs)
end)