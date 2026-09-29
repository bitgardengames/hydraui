local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-targettarget-width"] = 110
Defaults["unitframes-targettarget-health-height"] = 26
Defaults["unitframes-targettarget-health-reverse"] = false
Defaults["unitframes-targettarget-health-color"] = "CLASS"
Defaults["unitframes-targettarget-health-smooth"] = true
Defaults["unitframes-targettarget-enable-power"] = true
Defaults["unitframes-targettarget-power-height"] = 3
Defaults["unitframes-targettarget-power-reverse"] = false
Defaults["unitframes-targettarget-power-color"] = "POWER"
Defaults["unitframes-targettarget-power-smooth"] = true
Defaults["unitframes-targettarget-health-left"] = "[Name(10)]"
Defaults["unitframes-targettarget-health-right"] = "[HealthPercent]"
Defaults["unitframes-targettarget-debuffs"] = true
Defaults["unitframes-targettarget-debuff-size"] = 20
Defaults["unitframes-targettarget-debuff-pos"] = "BOTTOM"
Defaults["tot-enable"] = true
Defaults.ToTHealthTexture = "HydraUI 4"
Defaults.ToTPowerTexture = "HydraUI 4"

local UF = HydraUI:GetModule("Unit Frames")

HydraUI.StyleFuncs["targettarget"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	UF:CreateBackdrop(self, "Blank", "BACKGROUND")
	UF:CreateThreatIndicator(self, HydraUI.Outline, UF.ThreatPostUpdate)

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(
		self,
		Settings["unitframes-targettarget-health-height"],
		Settings.ToTHealthTexture,
		Settings["unitframes-targettarget-health-reverse"],
		nil,
		"BORDER"
	)
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(
		self,
		Health,
		Settings["unitframes-targettarget-width"],
		Settings["unitframes-targettarget-health-height"],
		Settings.ToTHealthTexture,
		Settings["unitframes-targettarget-health-reverse"],
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

	-- Target Icon
	local RaidTargetIndicator = UF:CreateRaidTargetIndicator(Health, 16)

	local R, G, B = HydraUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.Smooth = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-targettarget-health-color"])

	-- Power Bar
	local Power, PowerBG = UF:CreatePowerBar(self, Settings["unitframes-targettarget-power-height"], Settings.ToTPowerTexture, Settings["unitframes-targettarget-power-reverse"])

	-- Attributes
	Power.frequentUpdates = true
	Power.colorReaction = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-targettarget-power-color"])

	if Settings["unitframes-targettarget-debuffs"] then
		local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
		Debuffs:SetSize(Settings["unitframes-targettarget-width"], Settings["unitframes-targettarget-debuff-size"])
		Debuffs.size = Settings["unitframes-targettarget-debuff-size"]
		Debuffs.spacing = 2
		Debuffs.num = 5
		Debuffs.tooltipAnchor = "ANCHOR_TOP"
		Debuffs.PostCreateIcon = UF.PostCreateIcon
		Debuffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["unitframes-targettarget-debuff-pos"] == "TOP") then
			Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			Debuffs.initialAnchor = "TOPRIGHT"
			Debuffs["growth-x"] = "LEFT"
			Debuffs["growth-y"] = "DOWN"
		else
			Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			Debuffs.initialAnchor = "TOPRIGHT"
			Debuffs["growth-x"] = "LEFT"
			Debuffs["growth-y"] = "DOWN"
		end

		self.Debuffs = Debuffs
	end

	self:Tag(HealthLeft, Settings["unitframes-targettarget-health-left"])
	self:Tag(HealthRight, Settings["unitframes-targettarget-health-right"])

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.Power = Power
	self.Power.bg = PowerBG
	self.HealthLeft = HealthLeft
	self.HealthRight = HealthRight
	self.RaidTargetIndicator = RaidTargetIndicator
end

local UpdateTargetTargetWidth = function(value)
	UF:SetFrameWidth("targettarget", value)
end

local UpdateTargetTargetHealthHeight = function(value)
	UF:SetHealthHeight("targettarget", value, Settings["unitframes-targettarget-power-height"])
end

local UpdateTargetTargetPowerHeight = function(value)
	UF:SetPowerHeight("targettarget", value, Settings["unitframes-targettarget-health-height"])
end

local UpdateTargetTargetHealthColor = function(value)
	UF:ApplyHealthAttributes("targettarget", value)
end

local UpdateTargetTargetHealthFill = function(value)
	UF:SetHealthReverseFill("targettarget", value)
end

local UpdateTargetTargetPowerColor = function(value)
	UF:ApplyPowerAttributes("targettarget", value)
end

local UpdateTargetTargetPowerFill = function(value)
	UF:SetPowerReverseFill("targettarget", value)
end

local UpdateEnableDebuffs = function(value)
	UF:SetElementEnabled("targettarget", value, "Debuffs")
end

local UpdateDebuffSize = function(value)
	UF:SetAuraSize("targettarget", value, "Debuffs", Settings["unitframes-targettarget-width"])
end

local UpdateDebuffPosition = function(value)
	UF:SetAuraPosition("targettarget", value, "Debuffs", "LEFT")
end

local UpdateHealthTexture = function(value)
	UF:SetHealthTexture("targettarget", value)
end

local UpdatePowerTexture = function(value)
	UF:SetPowerTexture("targettarget", value)
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Target of Target"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("tot-enable", Settings["tot-enable"], Language["Enable Target Target"], Language["Enable the target of target unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-targettarget-width", Settings["unitframes-targettarget-width"], 60, 320, 1, "Width", "Set the width of the target's target unit frame", UpdateTargetTargetWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-targettarget-health-reverse", Settings["unitframes-targettarget-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateTargetTargetHealthFill)
	left:CreateSlider("unitframes-targettarget-health-height", Settings["unitframes-targettarget-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the target of target health bar", UpdateTargetTargetHealthHeight)
	left:CreateDropdown("unitframes-targettarget-health-color", Settings["unitframes-targettarget-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateTargetTargetHealthColor)
	left:CreateInput("unitframes-targettarget-health-left", Settings["unitframes-targettarget-health-left"], Language["Left Health Text"], Language["Set the text on the left of the target of target health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-targettarget-health-right", Settings["unitframes-targettarget-health-right"], Language["Right Health Text"], Language["Set the text on the right of the target of target health bar"], ReloadUI):RequiresReload(true)

	left:CreateDropdown("ToTHealthTexture", Settings.ToTHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-targettarget-power-reverse", Settings["unitframes-targettarget-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateTargetTargetPowerFill)
	right:CreateSlider("unitframes-targettarget-power-height", Settings["unitframes-targettarget-power-height"], 1, 30, 1, "Power Bar Height", "Set the height of the target of target power bar", UpdateTargetTargetPowerHeight)
	right:CreateDropdown("unitframes-targettarget-power-color", Settings["unitframes-targettarget-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateTargetTargetPowerColor)

	right:CreateDropdown("ToTPowerTexture", Settings.ToTPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Debuffs"])
	right:CreateSwitch("unitframes-targettarget-debuffs", Settings["unitframes-targettarget-debuffs"], Language["Enable Debuffs"], Language["Enable debuffs on the unit frame"], UpdateEnableDebuffs)
	right:CreateSlider("unitframes-targettarget-debuff-size", Settings["unitframes-targettarget-debuff-size"], 10, 40, 1, "Debuff Size", "Set the size of the debuff icons", UpdateDebuffSize)
	right:CreateDropdown("unitframes-targettarget-debuff-pos", Settings["unitframes-targettarget-debuff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the debuffs"], UpdateDebuffPosition)
end)
