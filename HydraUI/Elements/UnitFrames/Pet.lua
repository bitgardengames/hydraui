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

HydraUI.StyleFuncs["pet"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	UF:CreateBackdrop(self, "Blank", "BACKGROUND")
	UF:CreateThreatIndicator(self, HydraUI.Outline, UF.ThreatPostUpdate)

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(
		self,
		Settings["unitframes-pet-health-height"],
		Settings.PetHealthTexture,
		Settings["unitframes-pet-health-reverse"],
		nil,
		"BORDER"
	)
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(
		self,
		Health,
		Settings["unitframes-pet-width"],
		Settings["unitframes-pet-health-height"],
		Settings.PetHealthTexture,
		Settings["unitframes-pet-health-reverse"],
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
	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.Smooth = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-pet-health-color"])

	-- Power Bar
	local Power, PowerBG = UF:CreatePowerBar(self, Settings["unitframes-pet-power-height"], Settings.PetPowerTexture, Settings["unitframes-pet-power-reverse"])

	-- Attributes
	Power.frequentUpdates = true
	Power.colorReaction = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-pet-power-color"])

	if Settings["unitframes-pet-buffs"] then
		local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
		Buffs:SetSize(Settings["unitframes-pet-width"], Settings["unitframes-pet-buff-size"])
		Buffs.size = Settings["unitframes-pet-buff-size"]
		Buffs.spacing = 2
		Buffs.num = 5
		Buffs.tooltipAnchor = "ANCHOR_TOP"
		Buffs.PostCreateIcon = UF.PostCreateIcon
		Buffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["unitframes-pet-buff-pos"] == "TOP") then
			Buffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			Buffs.initialAnchor = "TOPLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "UP"
		else
			Buffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			Buffs.initialAnchor = "TOPLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "DOWN"
		end

		self.Buffs = Buffs
	end

	if Settings["unitframes-pet-debuffs"] then
		local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
		Debuffs:SetSize(Settings["unitframes-pet-width"], Settings["unitframes-pet-debuff-size"])
		Debuffs.size = Settings["unitframes-pet-debuff-size"]
		Debuffs.spacing = 2
		Debuffs.num = 5
		Debuffs.tooltipAnchor = "ANCHOR_TOP"
		Debuffs.PostCreateIcon = UF.PostCreateIcon
		Debuffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["unitframes-pet-debuff-pos"] == "TOP") then
			if self.Buffs then
				if (Settings["unitframes-pet-buff-pos"] == "TOP") then
					Debuffs:SetPoint("BOTTOM", self.Buffs or self, "TOP", 0, 2)
				else
					Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
				end
			else
				Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			end

			Debuffs.initialAnchor = "TOPRIGHT"
			Debuffs["growth-x"] = "LEFT"
			Debuffs["growth-y"] = "DOWN"
			Debuffs["growth-y"] = "UP"
		else
			if self.Buffs then
				if (Settings["unitframes-pet-buff-pos"] == "BOTTOM") then
					Debuffs:SetPoint("TOP", self.Buffs or self, "BOTTOM", 0, -2)
				else
					Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
				end
			else
				Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			end
		end

		self.Debuffs = Debuffs
	end

	self:Tag(HealthLeft, Settings["unitframes-pet-health-left"])
	self:Tag(HealthRight, Settings["unitframes-pet-health-right"])

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthLeft = HealthLeft
	self.Power = Power
	self.Power.bg = PowerBG
end

local UpdatePetWidth = function(value)
	UF:SetFrameWidth("pet", value)
end

local UpdatePetHealthHeight = function(value)
	UF:SetHealthHeight("pet", value, Settings["unitframes-pet-power-height"])
end

local UpdatePetPowerHeight = function(value)
	UF:SetPowerHeight("pet", value, Settings["unitframes-pet-health-height"])
end

local UpdatePetHealthColor = function(value)
	UF:ApplyHealthAttributes("pet", value)
end

local UpdatePetHealthFill = function(value)
	UF:SetHealthReverseFill("pet", value)
end

local UpdatePetPowerColor = function(value)
	UF:ApplyPowerAttributes("pet", value)
end

local UpdatePetPowerFill = function(value)
	UF:SetPowerReverseFill("pet", value)
end

local UpdateEnableBuffs = function(value)
	UF:SetElementEnabled("pet", value, "Buffs")
end

local UpdateBuffSize = function(value)
	UF:SetAuraSize("pet", value, "Buffs", Settings["unitframes-pet-width"])
end

local UpdateBuffPosition = function(value)
	UF:SetAuraPosition("pet", value, "Buffs", "LEFT")
end

local UpdateDebuffSize = function(value)
	UF:SetAuraSize("pet", value, "Debuffs", Settings["unitframes-pet-width"])
end

local UpdateDebuffPosition = function(value)
	UF:SetAuraPosition("pet", value, "Debuffs", "LEFT", "Buffs", Settings["unitframes-pet-buff-pos"])
end

local UpdateHealthTexture = function(value)
	UF:SetHealthTexture("pet", value)
end

local UpdatePowerTexture = function(value)
	UF:SetPowerTexture("pet", value)
end

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
