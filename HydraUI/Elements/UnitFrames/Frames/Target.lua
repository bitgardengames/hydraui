local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-target-width"] = 240
Defaults["unitframes-target-health-height"] = 32
Defaults["unitframes-target-health-reverse"] = false
Defaults["unitframes-target-health-color"] = "CLASS"
Defaults["unitframes-target-health-smooth"] = true
Defaults["unitframes-target-power-height"] = 15
Defaults["unitframes-target-power-reverse"] = false
Defaults["unitframes-target-power-color"] = "POWER"
Defaults["unitframes-target-power-smooth"] = true
Defaults["unitframes-target-health-left"] = "[LevelColor][Level][Plus][ColorStop] [Name(30)]"
Defaults["unitframes-target-health-right"] = "[HealthPercent]"
Defaults["unitframes-target-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-target-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-target-cast-width"] = 250
Defaults["unitframes-target-cast-height"] = 24
Defaults["unitframes-target-cast-classcolor"] = true
Defaults["unitframes-target-enable-castbar"] = true
Defaults["target-enable-portrait"] = false
Defaults["target-portrait-style"] = "3D"
Defaults["target-overlay-alpha"] = 30
Defaults["target-enable"] = true
Defaults.TargetBuffSize = 28
Defaults.TargetBuffSpacing = 2
Defaults.TargetDebuffSize = 28
Defaults.TargetDebuffSpacing = 2
Defaults.TargetHealthTexture = "HydraUI 4"
Defaults.TargetPowerTexture = "HydraUI 4"

local UF = HydraUI:GetModule("Unit Frames")

local function BuildTargetComponents(factory, frame, unit)
-- Portrait
	factory:CreatePortrait(frame,
		Settings["target-portrait-style"],
		Settings["target-portrait-style"] == "OVERLAY" and Settings["unitframes-target-width"] or 55,
		Settings["target-portrait-style"] == "OVERLAY" and Settings["unitframes-target-health-height"] or Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 1,
		Settings["target-portrait-style"] == "OVERLAY" and "CENTER" or "LEFT",
		Settings["target-portrait-style"] == "OVERLAY" and frame.Health or frame,
		Settings["target-portrait-style"] == "OVERLAY" and "CENTER" or "RIGHT",
		Settings["target-portrait-style"] == "OVERLAY" and 0 or 3, 0,
		Settings["target-portrait-style"] == "OVERLAY" and Settings["target-overlay-alpha"] / 100 or nil,
		Settings["Blank"], Settings["target-enable-portrait"])


	-- Auras
	local Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, Settings["unitframes-target-width"], 28,
		"BOTTOMLEFT", frame, "TOPLEFT", 0, 2, Settings.TargetBuffSize, Settings.TargetBuffSpacing, 16,
		"TOPLEFT", "ANCHOR_TOP", "RIGHT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, Settings["unitframes-target-width"], 28,
		nil, nil, nil, 0, 0, Settings.TargetDebuffSize, Settings.TargetDebuffSpacing, 16,
		"TOPRIGHT", "ANCHOR_TOP", "LEFT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, Settings["unitframes-only-player-debuffs"], true)
	if Settings["unitframes-show-player-buffs"] then
		Debuffs:SetPoint("BOTTOM", Buffs, "TOP", 0, 2)
	else
		Debuffs:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
	end

	-- Castbar
	if Settings["unitframes-target-enable-castbar"] then
		local Anchor = CreateFrame("Frame", "HydraUI Target Casting Bar", frame)
		Anchor:SetSize(Settings["unitframes-target-cast-width"], Settings["unitframes-target-cast-height"])
		factory:CreateCastbar(frame, nil,
		Settings["unitframes-target-cast-width"] - Settings["unitframes-target-cast-height"] - 1, Settings["unitframes-target-cast-height"],
		"RIGHT", Anchor, "RIGHT", 0, 0, Settings["ui-widget-texture"], "Blank",
		-Settings["unitframes-target-cast-height"] - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, Settings["unitframes-target-cast-width"] * 0.7,
		Settings["unitframes-target-cast-height"], nil, nil, nil, true, 0.3, Settings["unitframes-target-cast-classcolor"],
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
		frame.CastAnchor = Anchor
	end

	frame.Buffs = Buffs
	frame.Debuffs = Debuffs
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local TargetFrameConfig = {
	settingsPrefix = "unitframes-target",
	debuffColors = true,
	healthTextureKey = "TargetHealthTexture",
	powerTextureKey = "TargetPowerTexture",
	powerTags = true,
	colorTapping = true,
	colorDisconnected = true,
	powerReaction = true,
	raidTarget = true,
	auras = BuildTargetComponents,
	range = SingleUnitRange,
}

HydraUI.StyleFuncs["target"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, TargetFrameConfig)
end

local UpdateTargetWidth = UF:CreateUnitUpdater("target", "Width", {widthElements = {"Buffs", "Debuffs"}})

local UpdateTargetHealthHeight = UF:CreateUnitUpdater("target", "HealthHeight", {powerHeight = "unitframes-target-power-height"})

local UpdateTargetHealthFill = UF:CreateUnitUpdater("target", "HealthReverse")

local UpdateTargetPowerHeight = UF:CreateUnitUpdater("target", "PowerHeight", {healthHeight = "unitframes-target-health-height"})

local UpdateTargetPowerFill = UF:CreateUnitUpdater("target", "PowerReverse")

local UpdateTargetHealthColor = UF:CreateUnitUpdater("target", "HealthColor")

local UpdateTargetPowerColor = UF:CreateUnitUpdater("target", "PowerColor")

local UpdateTargetCastBarSize = function()
	if HydraUI.UnitFrames["target"].Castbar then
		HydraUI.UnitFrames["target"].Castbar:SetSize(Settings["unitframes-target-cast-width"], Settings["unitframes-target-cast-height"])
		HydraUI.UnitFrames["target"].Castbar.Icon:SetSize(Settings["unitframes-target-cast-height"], Settings["unitframes-target-cast-height"])
	end
end

local UpdateCastClassColor = function(value)
	if HydraUI.UnitFrames["target"].Castbar then
		HydraUI.UnitFrames["target"].Castbar.ClassColor = value
		HydraUI.UnitFrames["target"].Castbar:ForceUpdate()
	end
end

local UpdateTargetEnablePortrait = function(value)
	local Frame = HydraUI.UnitFrames["target"]

	if Frame and Frame.Portrait then
		UF:SetElementEnabled("target", value, "Portrait")

		if Frame.Portrait.BG then
			if value then
				Frame.Portrait.BG:Show()
			else
				Frame.Portrait.BG:Hide()
			end
		end

		Frame.Portrait:ForceUpdate()
	end
end

local UpdateOverlayAlpha = function(value)
	if HydraUI.UnitFrames["target"] and Settings["target-portrait-style"] == "OVERLAY" then
		HydraUI.UnitFrames["target"].Portrait:SetAlpha(value / 100)
	end
end

local UpdateBuffSize = UF:CreateUnitUpdater("target", "AuraSize", {element = "Buffs", width = "unitframes-target-width"})

local UpdateBuffSpacing = UF:CreateUnitUpdater("target", "AuraSpacing", {element = "Buffs"})

local UpdateDebuffSize = UF:CreateUnitUpdater("target", "AuraSize", {element = "Debuffs", width = "unitframes-target-width"})

local UpdateDebuffSpacing = UF:CreateUnitUpdater("target", "AuraSpacing", {element = "Debuffs"})

local UpdateDisplayedAuras = function()
	if not HydraUI.UnitFrames["target"] then
		return
	end

	local Target = HydraUI.UnitFrames["target"]

	Target.Debuffs:ClearAllPoints()

	if Settings["unitframes-show-target-buffs"] then
		Target.Debuffs:SetPoint("BOTTOM", Target.Buffs, "TOP", 0, 2)
	else
		Target.Debuffs:SetPoint("BOTTOMLEFT", Target, "TOPLEFT", 0, 2)
	end

	if Settings["unitframes-show-target-buffs"] then
		Target.Buffs:Show()
	else
		Target.Buffs:Hide()
	end

	if Settings["unitframes-show-target-debuffs"] then
		Target.Debuffs:Show()
	else
		Target.Debuffs:Hide()
	end
end

local UpdateHealthTexture = UF:CreateUnitUpdater("target", "HealthTexture")

local UpdatePowerTexture = UF:CreateUnitUpdater("target", "PowerTexture")

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Target"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("target-enable", Settings["target-enable"], Language["Enable Target"], Language["Enable the target unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-target-width", Settings["unitframes-target-width"], 120, 320, 1, "Width", "Set the width of the target unit frame", UpdateTargetWidth)
	left:CreateSwitch("unitframes-only-player-debuffs", Settings["unitframes-only-player-debuffs"], Language["Only Display Player Debuffs"], Language["If enabled, only your own debuffs will be displayed on the target"], UpdateOnlyPlayerDebuffs)
	left:CreateSwitch("target-enable-portrait", Settings["target-enable-portrait"], Language["Enable Portrait"], Language["Display the target unit portrait"], UpdateTargetEnablePortrait)
	left:CreateDropdown("target-portrait-style", Settings["target-portrait-style"], {[Language["2D"]] = "2D", [Language["3D"]] = "3D", [Language["Overlay"]] = "OVERLAY"}, Language["Set Portrait Style"], Language["Set the style of the portrait"], ReloadUI):RequiresReload(true)
	left:CreateSlider("target-overlay-alpha", Settings["target-overlay-alpha"], 0, 100, 5, Language["Set Overlay Opacity"], Language["Set the opacity of the portrait overlay"], UpdateOverlayAlpha, nil, "%")

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-target-health-reverse", Settings["unitframes-target-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateTargetHealthFill)
	left:CreateSlider("unitframes-target-health-height", Settings["unitframes-target-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the target health bar", UpdateTargetHealthHeight)
	left:CreateDropdown("unitframes-target-health-color", Settings["unitframes-target-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Color"], Language["Set the color of the health bar"], UpdateTargetHealthColor)
	left:CreateInput("unitframes-target-health-left", Settings["unitframes-target-health-left"], Language["Left Health Text"], Language["Set the text on the left of the target health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-target-health-right", Settings["unitframes-target-health-right"], Language["Right Health Text"], Language["Set the text on the right of the target health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("TargetHealthTexture", Settings.TargetHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("unitframes-show-target-buffs", Settings["unitframes-show-target-buffs"], Language["Show Buffs"], Language["Show auras above the target unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("TargetBuffSize", Settings.TargetBuffSize, 26, 50, 2, "Set Size", "Set the size of the auras", UpdateBuffSize)
	left:CreateSlider("TargetBuffSpacing", Settings.TargetBuffSpacing, -1, 4, 1, "Set Spacing", "Set the spacing between the auras", UpdateBuffSpacing)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSwitch("unitframes-show-target-debuffs", Settings["unitframes-show-target-debuffs"], Language["Show Debuffs"], Language["Show your debuff auras above the target unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("TargetDebuffSize", Settings.TargetDebuffSize, 26, 50, 2, "Set Size", "Set the size of the auras", UpdateDebuffSize)
	left:CreateSlider("TargetDebuffSpacing", Settings.TargetDebuffSpacing, -1, 4, 1, "Set Spacing", "Set the spacing between the auras", UpdateDebuffSpacing)

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-target-power-reverse", Settings["unitframes-target-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateTargetPowerFill)
	right:CreateSlider("unitframes-target-power-height", Settings["unitframes-target-power-height"], 2, 30, 1, "Power Bar Height", "Set the height of the target power bar", UpdateTargetPowerHeight)
	right:CreateDropdown("unitframes-target-power-color", Settings["unitframes-target-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateTargetPowerColor)
	right:CreateInput("unitframes-target-power-left", Settings["unitframes-target-power-left"], Language["Left Power Text"], Language["Set the text on the left of the target power bar"], ReloadUI):RequiresReload(true)
	right:CreateInput("unitframes-target-power-right", Settings["unitframes-target-power-right"], Language["Right Power Text"], Language["Set the text on the right of the target power bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("TargetPowerTexture", Settings.TargetPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("unitframes-target-enable-castbar", Settings["unitframes-target-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the target cast bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-target-cast-classcolor", Settings["unitframes-target-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateCastClassColor)

	right:CreateSlider("unitframes-target-cast-width", Settings["unitframes-target-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of the target cast bar"], UpdateTargetCastBarSize)
	right:CreateSlider("unitframes-target-cast-height", Settings["unitframes-target-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of the target cast bar"], UpdateTargetCastBarSize)
end)
