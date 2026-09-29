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

HydraUI.StyleFuncs["focus"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	UF:CreateBackdrop(self, "Blank", "BACKGROUND")
	UF:CreateThreatIndicator(self, HydraUI.Outline, UF.ThreatPostUpdate)

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(
		self,
		Settings["unitframes-focus-health-height"],
		Settings.FocusHealthTexture,
		Settings["unitframes-focus-health-reverse"],
		nil,
		"BORDER"
	)
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(
		self,
		Health,
		Settings["unitframes-focus-width"],
		Settings["unitframes-focus-health-height"],
		Settings.FocusHealthTexture,
		Settings["unitframes-focus-health-reverse"],
		HydraUI.IsMainline
	)

	local HealthLeft = UF:CreateFontString(
		Health,
		Settings["unitframes-font"],
		Settings["unitframes-font-size"],
		Settings["unitframes-font-flags"],
		"LEFT",
		"LEFT",
		3,
		0,
		"LEFT"
	)

	local HealthRight = UF:CreateFontString(
		Health,
		Settings["unitframes-font"],
		Settings["unitframes-font-size"],
		Settings["unitframes-font-flags"],
		"RIGHT",
		"RIGHT",
		-3,
		0,
		"RIGHT"
	)

	local R, G, B = HydraUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.Smooth = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-focus-health-color"])

	local Power, PowerBG = UF:CreatePowerBar(self, Settings["unitframes-focus-power-height"], Settings.FocusPowerTexture, Settings["unitframes-focus-power-reverse"])

	-- Attributes
	Power.frequentUpdates = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-focus-power-color"])

	if Settings["focus-enable-castbar"] then
		UF:CreateCastbar(
			self,
			nil,
			Settings["unitframes-focus-width"] - 30,
			24,
			"TOPRIGHT",
			self,
			"BOTTOMRIGHT",
			-1,
			-3,
			Settings["ui-widget-texture"],
			nil,
			"Blank",
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			Settings["unitframes-font"],
			Settings["unitframes-font-size"],
			Settings["unitframes-font-flags"],
			nil,
			nil,
			250 * 0.7,
			24,
			-4,
			true,
			nil,
			true,
			0.7,
			nil,
			UF.PostCastStart,
			UF.PostCastStop,
			UF.PostCastFail,
			UF.PostCastInterruptible
		)
	end

	-- Auras
	local AuraSize = Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3
	local Buffs = UF:CreateAuraContainer(
		self,
		self:GetName() .. "Buffs",
		nil,
		(AuraSize * 3) + 4,
		AuraSize,
		"LEFT",
		self,
		"RIGHT",
		2,
		nil,
		AuraSize,
		2,
		3,
		"LEFT",
		"ANCHOR_TOP",
		"RIGHT",
		nil,
		UF.PostCreateIcon,
		UF.PostUpdateIcon
	)
	local Debuffs = UF:CreateAuraContainer(
		self,
		self:GetName() .. "Debuffs",
		nil,
		(AuraSize * 3) + 4,
		AuraSize,
		"LEFT",
		Buffs,
		"RIGHT",
		2,
		nil,
		AuraSize,
		2,
		3,
		"LEFT",
		"ANCHOR_TOP",
		"RIGHT",
		nil,
		UF.PostCreateIcon,
		UF.PostUpdateIcon,
		nil,
		Settings["unitframes-only-focus-debuffs"]
	)

	-- Tags
	self:Tag(HealthLeft, Settings["unitframes-focus-health-left"])
	self:Tag(HealthRight, Settings["unitframes-focus-health-right"])

	self.Health = Health
	self.Health.bg = HealthBG
	self.Power = Power
	self.Power.bg = PowerBG
	self.HealthLeft = HealthLeft
	self.HealthRight = HealthRight
	self.Buffs = Buffs
	self.Debuffs = Debuffs
end

local UpdateFocusWidth = function(value)
	UF:SetFrameWidth("focus", value)
end

local UpdateFocusHealthHeight = function(value)
	UF:SetHealthHeight("focus", value, Settings["unitframes-focus-power-height"])
end

local UpdateFocusPowerHeight = function(value)
	UF:SetPowerHeight("focus", value, Settings["unitframes-focus-health-height"])
end

local UpdateFocusHealthColor = function(value)
	UF:ApplyHealthAttributes("focus", value)
end

local UpdateFocusHealthFill = function(value)
	UF:SetHealthReverseFill("focus", value)
end

local UpdateFocusPowerColor = function(value)
	UF:ApplyPowerAttributes("focus", value)
end

local UpdateShowFocusBuffs = function(value)
	local Frame = HydraUI.UnitFrames["focus"]

	if Frame then
		UF:SetElementEnabled("focus", value, "Auras")
		Frame:UpdateAllElements("ForceUpdate")
	end
end

local UpdateFocusPowerFill = function(value)
	UF:SetPowerReverseFill("focus", value)
end

local UpdateHealthTexture = function(value)
	UF:SetHealthTexture("focus", value)
end

local UpdatePowerTexture = function(value)
	UF:SetPowerTexture("focus", value)
end

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