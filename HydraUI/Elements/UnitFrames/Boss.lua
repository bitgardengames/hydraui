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

HydraUI.StyleFuncs["boss"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	UF:CreateBackdrop(self, { texture = "Blank", layer = "BACKGROUND" })

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(self, {
		height = Settings["unitframes-boss-health-height"],
		texture = Settings.BossHealthTexture,
		reverseFill = Settings["unitframes-boss-health-reverse"],
		backgroundLayer = "BORDER",
	})
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(self, Health, {
		width = Settings["unitframes-boss-width"],
		height = Settings["unitframes-boss-health-height"],
		texture = Settings.BossHealthTexture,
		reverseFill = Settings["unitframes-boss-health-reverse"],
		createAbsorb = HydraUI.IsMainline,
	})

	local HealthLeft = UF:CreateFontString(Health, {
		font = Settings["unitframes-font"], size = Settings["unitframes-font-size"], flags = Settings["unitframes-font-flags"],
		point = "LEFT", relativePoint = "LEFT", x = 3, y = 0, justify = "LEFT",
	})

	local HealthRight = UF:CreateFontString(Health, {
		font = Settings["unitframes-font"], size = Settings["unitframes-font-size"], flags = Settings["unitframes-font-flags"],
		point = "RIGHT", relativePoint = "RIGHT", x = -3, y = 0, justify = "RIGHT",
	})

	-- Target Icon
	local RaidTarget = UF:CreateRaidTargetIndicator(Health, { size = 16 })

	local R, G, B = HydraUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.Smooth = true
	Health.colorTapping = true
	Health.colorDisconnected = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-boss-health-color"])

	local Power, PowerBG = UF:CreatePowerBar(self, {
		height = Settings["unitframes-boss-power-height"],
		texture = Settings.BossPowerTexture,
		reverseFill = false,
	})

	local PowerLeft = UF:CreateFontString(Power, {
		font = Settings["unitframes-font"], size = Settings["unitframes-font-size"], flags = Settings["unitframes-font-flags"],
		point = "LEFT", relativePoint = "LEFT", x = 3, y = 0, justify = "LEFT",
	})

	local PowerRight = UF:CreateFontString(Power, {
		font = Settings["unitframes-font"], size = Settings["unitframes-font-size"], flags = Settings["unitframes-font-flags"],
		point = "RIGHT", relativePoint = "RIGHT", x = -3, y = 0, justify = "RIGHT",
	})

	-- Attributes
	Power.frequentUpdates = true
	Power.colorReaction = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-boss-power-color"])

	-- Auras
	local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
	Buffs:SetSize(Settings["unitframes-player-width"], Settings["unitframes-boss-buff-size"])
	Buffs:SetPoint("RIGHT", self, "LEFT", -2, 0)
	Buffs.size = Settings["unitframes-boss-buff-size"]
	Buffs.spacing = 2
	Buffs.num = 3
	Buffs.initialAnchor = "TOPRIGHT"
	Buffs.tooltipAnchor = "ANCHOR_TOP"
	Buffs["growth-x"] = "LEFT"
	Buffs["growth-y"] = "UP"
	Buffs.PostCreateIcon = UF.PostCreateIcon
	Buffs.PostUpdateIcon = UF.PostUpdateIcon

	local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
	Debuffs:SetSize(Settings["unitframes-player-width"], Settings["unitframes-boss-debuff-size"])
	Debuffs:SetPoint("LEFT", self, "RIGHT", 2, 0)
	Debuffs.size = Settings["unitframes-boss-debuff-size"]
	Debuffs.spacing = 2
	Debuffs.num = 4
	Debuffs.initialAnchor = "TOPLEFT"
	Debuffs.tooltipAnchor = "ANCHOR_TOP"
	Debuffs["growth-x"] = "RIGHT"
	Debuffs["growth-y"] = "UP"
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.onlyShowPlayer = Settings["unitframes-only-player-debuffs"]

    -- Castbar
    local Castbar = CreateFrame("StatusBar", self:GetName() .. " Casting Bar", self)
	Castbar:SetSize(Settings["unitframes-boss-width"] - 28, 22)
	Castbar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -1, -3)
    Castbar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))

	local CastbarBG = Castbar:CreateTexture(nil, "ARTWORK")
	CastbarBG:SetPoint("TOPLEFT", Castbar, 0, 0)
	CastbarBG:SetPoint("BOTTOMRIGHT", Castbar, 0, 0)
    CastbarBG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	CastbarBG:SetAlpha(0.2)

    local Background = Castbar:CreateTexture(nil, "BACKGROUND")
	Background:SetPoint("TOPLEFT", Castbar, -1, 1)
    Background:SetPoint("BOTTOMRIGHT", Castbar, 1, -1)
    Background:SetTexture(Assets:GetTexture("Blank"))
    Background:SetVertexColor(0, 0, 0)

    local Time = UF:CreateFontString(Castbar, {
		font = Settings["unitframes-font"], size = Settings["unitframes-font-size"], flags = Settings["unitframes-font-flags"],
		point = "RIGHT", relativePoint = "RIGHT", x = -3, y = 0, justify = "RIGHT",
	})

    local Text = Castbar:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(Text, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	Text:SetPoint("LEFT", Castbar, 3, 0)
	Text:SetSize(250 * 0.7, Settings["unitframes-font-size"])
	Text:SetJustifyH("LEFT")

    local Icon = Castbar:CreateTexture(nil, "OVERLAY")
    Icon:SetSize(22, 22)
	Icon:SetPoint("TOPRIGHT", Castbar, "TOPLEFT", -4, 0)
    Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    local IconBG = Castbar:CreateTexture(nil, "BACKGROUND")
    IconBG:SetPoint("TOPLEFT", Icon, -1, 1)
    IconBG:SetPoint("BOTTOMRIGHT", Icon, 1, -1)
    IconBG:SetTexture(Assets:GetTexture("Blank"))
    IconBG:SetVertexColor(0, 0, 0)

    Castbar.bg = CastbarBG
    Castbar.Time = Time
    Castbar.Text = Text
    Castbar.Icon = Icon
    Castbar.showTradeSkills = true
    Castbar.timeToHold = 0.3
	Castbar.PostCastStart = UF.PostCastStart
	Castbar.PostCastStop = UF.PostCastStop
	Castbar.PostCastFail = UF.PostCastFail
	Castbar.PostCastInterruptible = UF.PostCastInterruptible

	-- Tags
	self:Tag(HealthLeft, Settings["unitframes-boss-health-left"])
	self:Tag(HealthRight, Settings["unitframes-boss-health-right"])
	self:Tag(PowerLeft, Settings["unitframes-boss-power-left"])
	self:Tag(PowerRight, Settings["unitframes-boss-power-right"])

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthLeft = HealthLeft
	self.HealthRight = HealthRight
	self.Power = Power
	self.Power.bg = PowerBG
	self.PowerLeft = PowerLeft
	self.PowerRight = PowerRight
	self.Buffs = Buffs
	self.Debuffs = Debuffs
	self.Castbar = Castbar
	self.RaidTargetIndicator = RaidTarget
end

local UpdateWidth = function(value)
	for i = 1, 8 do
		UF:SetFrameWidth("boss"..i, value)
	end
end

local UpdateHealthHeight = function(value)
	for i = 1, 8 do
		UF:SetHealthHeight("boss"..i, value, Settings["unitframes-boss-power-height"])
	end
end

local UpdatePowerHeight = function(value)
	for i = 1, 8 do
		UF:SetPowerHeight("boss"..i, value, Settings["unitframes-boss-health-height"])
	end
end

local UpdateHealthColor = function(value)
	for i = 1, 8 do
		UF:ApplyHealthAttributes("boss"..i, value)
	end
end

local UpdateHealthFill = function(value)
	for i = 1, 8 do
		UF:SetHealthReverseFill("boss"..i, value)
	end
end

local UpdatePowerColor = function(value)
	for i = 1, 8 do
		UF:ApplyPowerAttributes("boss"..i, value)
	end
end

local UpdatePowerFill = function(value)
	for i = 1, 8 do
		UF:SetPowerReverseFill("boss"..i, value)
	end
end

local UpdateEnableBuffs = function(value)
	for i = 1, 8 do
		UF:SetElementEnabled("boss"..i, value, "Auras")
	end
end

local UpdateBuffSize = function(value)
	for i = 1, 8 do
		UF:SetAuraSize("boss"..i, value, "Buffs", Settings["unitframes-boss-width"])
	end
end

local UpdateDebuffSize = function(value)
	for i = 1, 8 do
		UF:SetAuraSize("boss"..i, value, "Debuffs", Settings["unitframes-boss-width"])
	end
end

local UpdateHealthTexture = function(value)
	for i = 1, 8 do
		UF:SetHealthTexture("boss"..i, value)
	end
end

local UpdatePowerTexture = function(value)
	for i = 1, 8 do
		UF:SetPowerTexture("boss"..i, value)
	end
end

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
