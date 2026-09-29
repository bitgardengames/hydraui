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

	UF:CreateBackdrop(self, { texture = "Blank", layer = "BACKGROUND" })
	UF:CreateThreatIndicator(self, { backdrop = HydraUI.Outline, postUpdate = UF.ThreatPostUpdate })

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(self, {
		height = Settings["unitframes-focus-health-height"],
		texture = Settings.FocusHealthTexture,
		reverseFill = Settings["unitframes-focus-health-reverse"],
		backgroundLayer = "BORDER",
	})
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(self, Health, {
		width = Settings["unitframes-focus-width"],
		height = Settings["unitframes-focus-health-height"],
		texture = Settings.FocusHealthTexture,
		reverseFill = Settings["unitframes-focus-health-reverse"],
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

	local R, G, B = HydraUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.Smooth = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-focus-health-color"])

	local Power, PowerBG = UF:CreatePowerBar(self, {
		height = Settings["unitframes-focus-power-height"],
		texture = Settings.FocusPowerTexture,
		reverseFill = Settings["unitframes-focus-power-reverse"],
	})

	-- Attributes
	Power.frequentUpdates = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-focus-power-color"])

	if Settings["focus-enable-castbar"] then
		-- Castbar
		local Castbar = CreateFrame("StatusBar", nil, self)
		Castbar:SetSize(Settings["unitframes-focus-width"] - 30, 24)
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

		local Time = Castbar:CreateFontString(nil, "OVERLAY")
		HydraUI:SetFontInfo(Time, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
		Time:SetPoint("RIGHT", Castbar, -3, 0)
		Time:SetJustifyH("RIGHT")

		local Text = Castbar:CreateFontString(nil, "OVERLAY")
		HydraUI:SetFontInfo(Text, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
		Text:SetPoint("LEFT", Castbar, 3, 0)
		Text:SetSize(250 * 0.7, Settings["unitframes-font-size"])
		Text:SetJustifyH("LEFT")

		local Icon = Castbar:CreateTexture(nil, "OVERLAY")
		Icon:SetSize(24, 24)
		Icon:SetPoint("TOPRIGHT", Castbar, "TOPLEFT", -4, 0)
		Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		local IconBG = Castbar:CreateTexture(nil, "BACKGROUND")
		IconBG:SetPoint("TOPLEFT", Icon, -1, 1)
		IconBG:SetPoint("BOTTOMRIGHT", Icon, 1, -1)
		IconBG:SetTexture(Assets:GetTexture("Blank"))
		IconBG:SetVertexColor(0, 0, 0)

		-- Register it with oUF
		Castbar.bg = CastbarBG
		Castbar.Time = Time
		Castbar.Text = Text
		Castbar.Icon = Icon
		Castbar.showTradeSkills = true
		Castbar.timeToHold = 0.7
		Castbar.PostCastStart = UF.PostCastStart
		Castbar.PostCastStop = UF.PostCastStop
		Castbar.PostCastFail = UF.PostCastFail
		Castbar.PostCastInterruptible = UF.PostCastInterruptible

		self.Castbar = Castbar
	end

	-- Auras
	local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
	Buffs:SetSize(((Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3) * 3) + 4, Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3)
	Buffs:SetPoint("LEFT", self, "RIGHT", 2, 0)
	Buffs.size = Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3
	Buffs.spacing = 2
	Buffs.num = 3
	Buffs.initialAnchor = "LEFT"
	Buffs.tooltipAnchor = "ANCHOR_TOP"
	Buffs["growth-x"] = "RIGHT"
	Buffs.PostCreateIcon = UF.PostCreateIcon
	Buffs.PostUpdateIcon = UF.PostUpdateIcon
	--Buffs.SetPosition = BuffsSetPosition

	local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
	Debuffs:SetSize(((Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3) * 3) + 4, Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3)
	Debuffs:SetPoint("LEFT", Buffs, "RIGHT", 2, 0)
	Debuffs.size = Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3
	Debuffs.spacing = 2
	Debuffs.num = 3
	Debuffs.initialAnchor = "LEFT"
	Debuffs.tooltipAnchor = "ANCHOR_TOP"
	Debuffs["growth-x"] = "RIGHT"
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.onlyShowPlayer = Settings["unitframes-only-focus-debuffs"]

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