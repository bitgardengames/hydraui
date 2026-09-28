local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

Defaults["nameplates-enable"] = true
Defaults["nameplates-width"] = 138
Defaults["nameplates-height"] = 14
Defaults["nameplates-font"] = "Roboto"
Defaults["nameplates-font-size"] = 12
Defaults["nameplates-font-flags"] = ""
Defaults["nameplates-cc-health"] = false
Defaults["nameplates-top-text"] = ""
Defaults["nameplates-topleft-text"] = "[LevelColor][Level][Plus][ColorStop] [Name(20)]"
Defaults["nameplates-topright-text"] = ""
Defaults["nameplates-bottom-text"] = ""
Defaults["nameplates-bottomleft-text"] = ""
Defaults["nameplates-bottomright-text"] = "[HealthPercent]"
Defaults["nameplates-only-player-debuffs"] = true
Defaults["nameplates-health-color"] = "CLASS"
Defaults["nameplates-health-smooth"] = true
Defaults["nameplates-enable-elite-indicator"] = true
Defaults["nameplates-enable-target-indicator"] = true
Defaults["nameplates-target-indicator-size"] = "SMALL"
Defaults["nameplates-enable-castbar"] = true
Defaults["nameplates-cast-classcolor"] = true
Defaults["nameplates-castbar-height"] = 12
Defaults["nameplates-castbar-enable-icon"] = true
Defaults["nameplates-castbar-show-name"] = true
Defaults["nameplates-castbar-show-time"] = true
Defaults["nameplates-castbar-interruptible-color"] = "f0b849"
Defaults["nameplates-castbar-uninterruptible-color"] = "d94c4c"
Defaults["nameplates-castbar-emphasize-target"] = true
Defaults["nameplates-selected-alpha"] = 100
Defaults["nameplates-unselected-alpha"] = 40
Defaults["nameplates-show-friendly"] = false
Defaults["nameplates-show-enemy"] = true
Defaults["nameplates-show-neutral"] = true
Defaults["nameplates-show-pets"] = true
Defaults["nameplates-show-guardians"] = true
Defaults["nameplates-show-minor"] = true
Defaults["nameplates-show-personal"] = false
Defaults["nameplates-stacking"] = true
Defaults["nameplates-overlap-horizontal"] = 0.8
Defaults["nameplates-overlap-vertical"] = 1.1
Defaults["nameplates-max-distance"] = 60
Defaults["nameplates-friendly-name-only"] = false
Defaults["nameplates-target-scale"] = 110
Defaults["nameplates-execute-coloring"] = false
Defaults["nameplates-execute-threshold"] = 20
Defaults["nameplates-execute-color"] = "d62f2f"
Defaults["nameplates-threat-tank-safe"] = "33cc66"
Defaults["nameplates-threat-tank-danger"] = "e64545"
Defaults["nameplates-threat-dps-safe"] = "33cc66"
Defaults["nameplates-threat-dps-danger"] = "e64545"
Defaults["nameplates-enable-auras"] = true
Defaults["nameplates-buffs-direction"] = "LTR"
Defaults["nameplates-debuffs-direction"] = "RTL"
Defaults.NPHealthTexture = "HydraUI 4"
Defaults.NPCastTexture = "HydraUI 4"

local oUF = ns.oUF or oUF
local UF = HydraUI:GetModule("Unit Frames")

local GetNamePlates = C_NamePlate.GetNamePlates
local UnitGroupRolesAssigned = UnitGroupRolesAssigned

-- Only CVars deliberately supported by this module belong here.  Keep this
-- separate from HydraUI:SetCVars(), which is an unfinished, global concept.
local NamePlateCVarSettings = {
	nameplateShowFriends = "nameplates-show-friendly",
	nameplateShowEnemies = "nameplates-show-enemy",
	nameplateShowEnemyMinus = "nameplates-show-minor",
	nameplateShowEnemyPets = "nameplates-show-pets",
	nameplateShowFriendlyPets = "nameplates-show-pets",
	nameplateShowEnemyGuardians = "nameplates-show-guardians",
	nameplateShowFriendlyGuardians = "nameplates-show-guardians",
	nameplateShowSelf = "nameplates-show-personal",
	nameplateShowOnlyNames = "nameplates-friendly-name-only",
	nameplateMotion = "nameplates-stacking",
	nameplateOverlapH = "nameplates-overlap-horizontal",
	nameplateOverlapV = "nameplates-overlap-vertical",
	nameplateMaxDistance = "nameplates-max-distance",
	nameplateSelectedScale = "nameplates-target-scale",
}

local function GetNamePlateCVarValue(cvar, setting)
	local value = Settings[setting]
	if (cvar == "nameplateSelectedScale") then return value / 100 end
	if (cvar == "nameplateMotion") then return value and 1 or 0 end
	if (type(value) == "boolean") then return value and 1 or 0 end
	return value
end

function UF:ApplyNamePlateCVars()
	for cvar, setting in pairs(NamePlateCVarSettings) do
		local value = GetNamePlateCVarValue(cvar, setting)
		C_CVar.SetCVar(cvar, value)
		if self.NamePlateCVars then self.NamePlateCVars[cvar] = value end
	end
	-- Neutral units are governed by the enemy master CVar, so preserve enemy
	-- plates when either hostile or neutral visibility is requested.
	C_CVar.SetCVar("nameplateShowEnemies", (Settings["nameplates-show-enemy"] or Settings["nameplates-show-neutral"]) and 1 or 0)
end

local function NamePlateThreatPostUpdate(self, unit, status)
	if (not status or status == 0) then return end
	local tank = UnitGroupRolesAssigned("player") == "TANK"
	local safe = tank and status >= 2 or (not tank and status < 2)
	local key = tank and (safe and "nameplates-threat-tank-safe" or "nameplates-threat-tank-danger")
		or (safe and "nameplates-threat-dps-safe" or "nameplates-threat-dps-danger")
	local r, g, b = HydraUI:HexToRGB(Settings[key])
	self.Top:SetVertexColor(r, g, b)
	self.Bottom:SetVertexColor(r, g, b)
end

local function NamePlateHealthPostUpdate(self, unit, current, maximum)
	if Settings["nameplates-execute-coloring"] and maximum and maximum > 0
	and ((current / maximum) * 100 <= Settings["nameplates-execute-threshold"]) then
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["nameplates-execute-color"]))
	end
end

local function NamePlateCastColor(self)
	local key = self.notInterruptible and "nameplates-castbar-uninterruptible-color" or "nameplates-castbar-interruptible-color"
	local r, g, b = HydraUI:HexToRGB(Settings[key])
	self:SetStatusBarColor(r, g, b)
	self.bg:SetVertexColor(r, g, b)
end

HydraUI.StyleFuncs["nameplate"] = function(self, unit)
	self:SetScale(UIParent:GetScale())
	self:SetSize(Settings["nameplates-width"], Settings["nameplates-height"])
	self:SetPoint("CENTER", 0, 0)

	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetAllPoints()
	Backdrop:SetTexture(Assets:GetTexture("Blank"))
	Backdrop:SetVertexColor(0, 0, 0)

	self.colors.debuff = HydraUI.DebuffColors

	-- Health Bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetPoint("TOPLEFT", self, 1, -1)
	Health:SetPoint("BOTTOMRIGHT", self, -1, 1)
	Health:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	Health:EnableMouse(false)

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(Settings["nameplates-width"])
	HealBar:SetHeight(Settings["nameplates-height"])
	HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)

	self.HealBar = HealBar

	if HydraUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["nameplates-width"])
		AbsorbsBar:SetHeight(Settings["nameplates-height"])
		AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings.NPHealthTexture))
	HealthBG.multiplier = 0.2

	-- Target Icon
	local RaidTargetIndicator = Health:CreateTexture(nil, 'OVERLAY')
	RaidTargetIndicator:SetSize(16, 16)
	RaidTargetIndicator:SetPoint("LEFT", Health, "RIGHT", 5, 0)

	local Top = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(Top, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Top:SetPoint("CENTER", Health, "TOP", 0, 3)
	Top:SetJustifyH("CENTER")

	local TopLeft = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(TopLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	TopLeft:SetPoint("LEFT", Health, "TOPLEFT", 4, 3)
	TopLeft:SetJustifyH("LEFT")

	local TopRight = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(TopRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	TopRight:SetPoint("RIGHT", Health, "TOPRIGHT", -4, 3)
	TopRight:SetJustifyH("RIGHT")

	local Bottom = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(Bottom, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Bottom:SetPoint("CENTER", Health, "BOTTOM", 0, -3)
	Bottom:SetJustifyH("CENTER")

	local BottomRight = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(BottomRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	BottomRight:SetPoint("RIGHT", Health, "BOTTOMRIGHT", -4, -3)
	BottomRight:SetJustifyH("RIGHT")

	local BottomLeft = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(BottomLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	BottomLeft:SetPoint("LEFT", Health, "BOTTOMLEFT", 4, -3)
	BottomLeft:SetJustifyH("LEFT")

	--[[local InsideCenter = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(InsideCenter, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	InsideCenter:SetPoint("CENTER", Health, 0, 0)
	InsideCenter:SetJustifyH("CENTER")]]

	Health.Smooth = Settings["nameplates-health-smooth"]
	Health.colorTapping = true
	Health.colorDisconnected = true

	UF:SetHealthAttributes(Health, Settings["nameplates-health-color"])
	Health.PostUpdate = NamePlateHealthPostUpdate

	local Threat = CreateFrame("Frame", nil, Health)
	Threat:SetAllPoints(Health)
	Threat:SetFrameLevel(Health:GetFrameLevel() - 1)
	Threat.feedbackUnit = "player"
	Threat.PostUpdate = NamePlateThreatPostUpdate

	Threat.Top = Threat:CreateTexture(nil, "BORDER")
	Threat.Top:SetHeight(6)
	Threat.Top:SetPoint("BOTTOMLEFT", Threat, "TOPLEFT", 8, 1)
	Threat.Top:SetPoint("BOTTOMRIGHT", Threat, "TOPRIGHT", -8, 1)
	Threat.Top:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Threat.Top:SetAlpha(0.8)

	Threat.Bottom = Threat:CreateTexture(nil, "BORDER")
	Threat.Bottom:SetHeight(6)
	Threat.Bottom:SetPoint("TOPLEFT", Threat, "BOTTOMLEFT", 8, -1)
	Threat.Bottom:SetPoint("TOPRIGHT", Threat, "BOTTOMRIGHT", -8, -1)
	Threat.Bottom:SetTexture(Assets:GetTexture("RenHorizonDown"))
	Threat.Bottom:SetAlpha(0.8)

	-- Buffs
	if Settings["nameplates-enable-auras"] then
		local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
		Buffs:SetSize(Settings["nameplates-width"], 26)
		Buffs:SetPoint("BOTTOM", self, "TOP", 0, 10)
		Buffs.size = 26
		Buffs.spacing = 2
		Buffs.num = 5
		Buffs.PostCreateIcon = UF.PostCreateIcon
		Buffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["nameplates-buffs-direction"] == "LTR") then
			Buffs.initialAnchor = "TOPLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "UP"
		else
			Buffs.initialAnchor = "TOPRIGHT"
			Buffs["growth-x"] = "LEFT"
			Buffs["growth-y"] = "UP"
		end

		self.Buffs = Buffs
	end

	-- Debuffs
	local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
	Debuffs:SetSize(Settings["nameplates-width"], 26)
	Debuffs.size = 26
	Debuffs.spacing = 2
	Debuffs.num = 5
	Debuffs.numRow = 4
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.onlyShowPlayer = Settings["nameplates-only-player-debuffs"]
	Debuffs.showStealableBuffs = true
	Debuffs.disableMouse = true

	if (Settings["nameplates-debuffs-direction"] == "LTR") then
		Debuffs.initialAnchor = "TOPLEFT"
		Debuffs["growth-x"] = "RIGHT"
		Debuffs["growth-y"] = "UP"
	else
		Debuffs.initialAnchor = "TOPRIGHT"
		Debuffs["growth-x"] = "LEFT"
		Debuffs["growth-y"] = "UP"
	end

	if Settings["nameplates-enable-auras"] then
		Debuffs:SetPoint("BOTTOM", self.Buffs, "TOP", 0, 2)
	else
		Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 10)
	end

    -- Castbar
    local Castbar = CreateFrame("StatusBar", nil, self)
    Castbar:SetSize(Settings["nameplates-width"] - 2, Settings["nameplates-castbar-height"])
	Castbar:SetPoint("TOP", Health, "BOTTOM", 0, -4)
    Castbar:SetStatusBarTexture(Assets:GetTexture(Settings.NPCastTexture))

	local CastbarBG = Castbar:CreateTexture(nil, "ARTWORK")
	CastbarBG:SetPoint("TOPLEFT", Castbar, 0, 0)
	CastbarBG:SetPoint("BOTTOMRIGHT", Castbar, 0, 0)
    CastbarBG:SetTexture(Assets:GetTexture(Settings.NPCastTexture))
	CastbarBG:SetAlpha(0.2)

    local Background = Castbar:CreateTexture(nil, "BACKGROUND")
	Background:SetPoint("TOPLEFT", Castbar, -1, 1)
    Background:SetPoint("BOTTOMRIGHT", Castbar, 1, -1)
    Background:SetTexture(Assets:GetTexture("Blank"))
    Background:SetVertexColor(0, 0, 0)

    local Time = Castbar:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(Time, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Time:SetPoint("RIGHT", Castbar, "BOTTOMRIGHT", -4, -3)
	Time:SetJustifyH("RIGHT")

    local Text = Castbar:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(Text, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Text:SetPoint("LEFT", Castbar, "BOTTOMLEFT", 4, -3)
	Text:SetWidth(Settings["nameplates-width"] / 2 + 4)
	Text:SetJustifyH("LEFT")

    local Icon = Castbar:CreateTexture(nil, "OVERLAY")
    Icon:SetSize(Settings["nameplates-height"] + 12 + 2, Settings["nameplates-height"] + 12 + 2)
    Icon:SetPoint("BOTTOMRIGHT", Castbar, "BOTTOMLEFT", -4, 0)
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
	Castbar.IconBG = IconBG
    Castbar.showTradeSkills = true
    Castbar.timeToHold = 0.7
	Castbar.ClassColor = Settings["nameplates-cast-classcolor"]
	Castbar.PostCastStart = NamePlateCastColor
	Castbar.PostCastStop = UF.PostCastStop
	Castbar.PostCastFail = UF.PostCastFail
	Castbar.PostCastInterruptible = NamePlateCastColor
	if (not Settings["nameplates-castbar-show-name"]) then Text:Hide() end
	if (not Settings["nameplates-castbar-show-time"]) then Time:Hide() end
	if (not Settings["nameplates-castbar-enable-icon"]) then Icon:Hide(); IconBG:Hide() end

	--[[ Elite icon
	local EliteIndicator = Health:CreateTexture(nil, "OVERLAY")
    EliteIndicator:SetSize(16, 16)
    EliteIndicator:SetPoint("RIGHT", Health, "LEFT", -1, 0)
    EliteIndicator:SetTexture(Assets:GetTexture("Small Star"))
    EliteIndicator:Hide()]]

	-- Target
	local TargetIndicator = CreateFrame("Frame", nil, self)
	TargetIndicator:SetPoint("TOPLEFT", Health, 0, 0)
	TargetIndicator:SetPoint("BOTTOMRIGHT", Health, 0, 0)
	TargetIndicator:Hide()

	TargetIndicator.Left = TargetIndicator:CreateTexture(nil, "ARTWORK")
	TargetIndicator.Left:SetSize(16, 16)
	TargetIndicator.Left:SetPoint("RIGHT", TargetIndicator, "LEFT", 2, 0)
	TargetIndicator.Left:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	TargetIndicator.Right = TargetIndicator:CreateTexture(nil, "ARTWORK")
	TargetIndicator.Right:SetSize(16, 16)
	TargetIndicator.Right:SetPoint("LEFT", TargetIndicator, "RIGHT", -3, 0)
	TargetIndicator.Right:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	if (Settings["nameplates-target-indicator-size"] == "SMALL") then
		TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left"))
		TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right"))
	elseif (Settings["nameplates-target-indicator-size"] == "LARGE") then
		TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Large"))
		TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Large"))
	elseif (Settings["nameplates-target-indicator-size"] == "HUGE") then
		TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Huge"))
		TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Huge"))
	end

	self:Tag(Top, Settings["nameplates-top-text"])
	self:Tag(TopLeft, Settings["nameplates-topleft-text"])
	self:Tag(TopRight, Settings["nameplates-topright-text"])
	self:Tag(Bottom, Settings["nameplates-bottom-text"])
	self:Tag(BottomRight, Settings["nameplates-bottomright-text"])
	self:Tag(BottomLeft, Settings["nameplates-bottomleft-text"])

	self.Health = Health
	self.Top = Top
	self.TopLeft = TopLeft
	self.TopRight = TopRight
	self.Bottom = Bottom
	self.BottomRight = BottomRight
	self.BottomLeft = BottomLeft
	self.Health.bg = HealthBG
	self.Debuffs = Debuffs
	self.Castbar = Castbar
	--self.EliteIndicator = EliteIndicator
	self.TargetIndicator = TargetIndicator
	self.ThreatIndicator = Threat
	self.RaidTargetIndicator = RaidTargetIndicator
end

UF.NamePlateCVars = {
    nameplateGlobalScale = 1,
    NamePlateHorizontalScale = 1,
    NamePlateVerticalScale = 1,
    nameplateLargerScale = 1,
    nameplateMaxScale = 1,
    nameplateMinScale = 1,
    nameplateSelectedScale = 1,
    nameplateSelfScale = 1,
}

UF.NamePlateCallback = function(plate)
	if (not plate) then
		return
	end

	if Settings["nameplates-enable-auras"] then
		plate:EnableElement("Auras")
	else
		plate:DisableElement("Auras")
	end

	if Settings["nameplates-enable-target-indicator"] then
		plate:EnableElement("TargetIndicator")

		if (Settings["nameplates-target-indicator-size"] == "SMALL") then
			plate.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left"))
			plate.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right"))
		elseif (Settings["nameplates-target-indicator-size"] == "LARGE") then
			plate.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Large"))
			plate.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Large"))
		elseif (Settings["nameplates-target-indicator-size"] == "HUGE") then
			plate.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Huge"))
			plate.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Huge"))
		end
	else
		plate:DisableElement("TargetIndicator")
	end

	if Settings["nameplates-enable-castbar"] then
		plate:EnableElement("Castbar")
	else
		plate:DisableElement("Castbar")
	end

	plate.Castbar.Text:SetShown(Settings["nameplates-castbar-show-name"])
	plate.Castbar.Time:SetShown(Settings["nameplates-castbar-show-time"])
	plate.Castbar.Icon:SetShown(Settings["nameplates-castbar-enable-icon"])
	plate.Castbar.IconBG:SetShown(Settings["nameplates-castbar-enable-icon"])
	local emphasize = Settings["nameplates-castbar-emphasize-target"] and UnitIsUnit(plate.unit, "target")
	plate.Castbar:SetScale(emphasize and 1.15 or 1)

	if plate.Buffs then
		if (Settings["nameplates-buffs-direction"] == "LTR") then
			plate.Buffs.initialAnchor = "TOPLEFT"
			plate.Buffs["growth-x"] = "RIGHT"
			plate.Buffs["growth-y"] = "UP"
		else
			plate.Buffs.initialAnchor = "TOPRIGHT"
			plate.Buffs["growth-x"] = "LEFT"
			plate.Buffs["growth-y"] = "UP"
		end
	end

	if plate.Debuffs then
		plate.Debuffs.onlyShowPlayer = Settings["nameplates-only-player-debuffs"]

		if (Settings["nameplates-debuffs-direction"] == "LTR") then
			plate.Debuffs.initialAnchor = "TOPLEFT"
			plate.Debuffs["growth-x"] = "RIGHT"
			plate.Debuffs["growth-y"] = "UP"
		else
			plate.Debuffs.initialAnchor = "TOPRIGHT"
			plate.Debuffs["growth-x"] = "LEFT"
			plate.Debuffs["growth-y"] = "UP"
		end
	end

	plate:SetSize(Settings["nameplates-width"], Settings["nameplates-height"])
	plate.Castbar:SetHeight(Settings["nameplates-castbar-height"])
	plate.Castbar:SetStatusBarTexture(Assets:GetTexture(Settings.NPCastTexture))
	plate.Castbar.bg:SetTexture(Assets:GetTexture(Settings.NPCastTexture))

	plate.Health:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	plate.Health.bg:SetTexture(Assets:GetTexture(Settings.NPHealthTexture))

	if plate.HealBar then
		plate.HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	end

	if plate.AbsorbsBar then
		plate.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	end

	HydraUI:SetFontInfo(plate.Top, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.TopLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.TopRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.Bottom, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.BottomRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.BottomLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.Castbar.Time, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(plate.Castbar.Text, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
end

local RunForAllNamePlates = function(func, value)
	local NamePlates = GetNamePlates()

	if NamePlates then
		for i = 1, #NamePlates do
			func(NamePlates[i].unitFrame, value)

			NamePlates[i].unitFrame:UpdateAllElements("ForceUpdate")
		end
	end
end

local NamePlatesUpdateEnableAuras = function(self, value)
	if value then
		self:EnableElement("Auras")
	else
		self:DisableElement("Auras")
	end
end

local UpdateNamePlatesEnableAuras = function(value)
	RunForAllNamePlates(NamePlatesUpdateEnableAuras, value)
end

local NamePlatesUpdateShowPlayerDebuffs = function(self)
	if self.Debuffs then
		self.Debuffs.onlyShowPlayer = Settings["nameplates-only-player-debuffs"]
	end
end

local UpdateNamePlatesShowPlayerDebuffs = function(value)
	RunForAllNamePlates(NamePlatesUpdateShowPlayerDebuffs, value)
end

local NamePlateSetWidth = function(self)
	self:SetWidth(Settings["nameplates-width"])
end

local UpdateNamePlatesWidth = function()
	RunForAllNamePlates(NamePlateSetWidth)
end

local NamePlateSetHeight = function(self)
	self:SetHeight(Settings["nameplates-height"])
end

local UpdateNamePlatesHeight = function()
	RunForAllNamePlates(NamePlateSetHeight)
end

local NamePlateSetHealthColor = function(self)
	UF:SetHealthAttributes(self.Health, Settings["nameplates-health-color"])
end

local UpdateNamePlatesHealthColor = function()
	RunForAllNamePlates(NamePlateSetHealthColor)
end

local NamePlateSetTargetHightlight = function(self, value)
	if value then
		self:EnableElement("TargetIndicator")
	else
		self:DisableElement("TargetIndicator")
	end
end

local UpdateNamePlatesTargetHighlight = function(value)
	RunForAllNamePlates(NamePlateSetTargetHightlight, value)
end

local NamePlateSetFont = function(self)
	HydraUI:SetFontInfo(self.Top, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.TopLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.TopRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.Bottom, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.BottomRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.BottomLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.Castbar.Time, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	HydraUI:SetFontInfo(self.Castbar.Text, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
end

local UpdateNamePlatesFont = function()
	RunForAllNamePlates(NamePlateSetFont)
end

local NamePlateEnableCastBars = function(self, value)
	if value then
		self:EnableElement("Castbar")
	else
		self:DisableElement("Castbar")
	end
end

local UpdateNamePlatesEnableCastBars = function(value)
	RunForAllNamePlates(NamePlateEnableCastBars, value)
end

local NamePlateSetCastBarsHeight = function(self, value)
	self.Castbar:SetHeight(value)
end

local UpdateNamePlatesCastBarsHeight = function(value)
	RunForAllNamePlates(NamePlateSetCastBarsHeight, value)
end

local NamePlateSetTargetIndicatorSize = function(self, value)
	if (value == "SMALL") then
		self.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left"))
		self.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right"))
	elseif (value == "LARGE") then
		self.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Large"))
		self.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Large"))
	elseif (value == "HUGE") then
		self.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Huge"))
		self.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Huge"))
	end
end

local UpdateNamePlatesTargetIndicatorSize = function(value)
	RunForAllNamePlates(NamePlateSetTargetIndicatorSize, value)
end

local UpdateNamePlateSelectedAlpha = function(value)
	C_CVar.SetCVar("nameplateSelectedAlpha", value / 100)
end

local UpdateNamePlateUnselectedAlpha = function(value)
	C_CVar.SetCVar("nameplateMinAlpha", value / 100)
	C_CVar.SetCVar("nameplateMaxAlpha", value / 100)
end

local UpdateNamePlateCVars = function()
	UF:ApplyNamePlateCVars()
end

local UpdateNamePlateAppearance = function()
	RunForAllNamePlates(function(plate)
		plate.Castbar.Text:SetShown(Settings["nameplates-castbar-show-name"])
		plate.Castbar.Time:SetShown(Settings["nameplates-castbar-show-time"])
		plate.Castbar.Icon:SetShown(Settings["nameplates-castbar-enable-icon"])
		plate.Castbar.IconBG:SetShown(Settings["nameplates-castbar-enable-icon"])
		local emphasize = Settings["nameplates-castbar-emphasize-target"] and UnitIsUnit(plate.unit, "target")
		plate.Castbar:SetScale(emphasize and 1.15 or 1)
		plate:UpdateAllElements("ForceUpdate")
	end)
end

local NamePlateSetBuffDirection = function(self, value)
	if (Settings["nameplates-buffs-direction"] == "LTR") then
		self.Buffs.initialAnchor = "TOPLEFT"
		self.Buffs["growth-x"] = "RIGHT"
		self.Buffs["growth-y"] = "UP"
	else
		self.Buffs.initialAnchor = "TOPRIGHT"
		self.Buffs["growth-x"] = "LEFT"
		self.Buffs["growth-y"] = "UP"
	end
end

local UpdateNamePlatesBuffDirection = function(value)
	RunForAllNamePlates(NamePlateSetBuffDirection, value)
end

local NamePlateSetDebuffDirection = function(self, value)
	if (Settings["nameplates-debuffs-direction"] == "LTR") then
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "UP"
	else
		self.Debuffs.initialAnchor = "TOPRIGHT"
		self.Debuffs["growth-x"] = "LEFT"
		self.Debuffs["growth-y"] = "UP"
	end
end

local UpdateNamePlatesDebuffDirection = function(value)
	RunForAllNamePlates(NamePlateSetDebuffDirection, value)
end

local SetHealthTexture = function(self, value)
	self.Health:SetStatusBarTexture(Assets:GetTexture(value))
	self.Health.bg:SetTexture(Assets:GetTexture(value))
	self.HealBar:SetStatusBarTexture(Assets:GetTexture(value))

	if self.AbsorbsBar then
		self.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(value))
	end
end

local UpdateHealthTexture = function(value)
	RunForAllNamePlates(SetHealthTexture, value)
end

local SetCastTexture = function(self, value)
	self.Castbar:SetStatusBarTexture(Assets:GetTexture(value))
	self.Castbar.bg:SetTexture(Assets:GetTexture(value))
end

local UpdateCastTexture = function(value)
	RunForAllNamePlates(SetCastTexture, value)
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Name Plates"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("nameplates-enable", Settings["nameplates-enable"], Language["Enable Name Plates"], Language["Enable the HydraUI name plates module"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("nameplates-show-friendly", Settings["nameplates-show-friendly"], "Friendly Units", "Show friendly nameplates", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-show-enemy", Settings["nameplates-show-enemy"], "Enemy Units", "Show enemy nameplates", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-show-neutral", Settings["nameplates-show-neutral"], "Neutral Units", "Show neutral nameplates", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-show-pets", Settings["nameplates-show-pets"], "Pets", "Show enemy pet nameplates", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-show-guardians", Settings["nameplates-show-guardians"], "Guardians", "Show enemy guardian nameplates", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-show-minor", Settings["nameplates-show-minor"], "Minor Units", "Show minor-unit nameplates", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-show-personal", Settings["nameplates-show-personal"], "Personal Resource", "Show the personal resource nameplate", UpdateNamePlateCVars)

	left:CreateHeader("Blizzard Behavior")
	left:CreateSwitch("nameplates-stacking", Settings["nameplates-stacking"], "Stack Nameplates", "Stack nameplates instead of allowing overlap", UpdateNamePlateCVars)
	left:CreateSlider("nameplates-overlap-horizontal", Settings["nameplates-overlap-horizontal"], 0.1, 2, 0.1, "Horizontal Spacing", "Set horizontal nameplate spacing", UpdateNamePlateCVars)
	left:CreateSlider("nameplates-overlap-vertical", Settings["nameplates-overlap-vertical"], 0.1, 2, 0.1, "Vertical Spacing", "Set vertical nameplate spacing", UpdateNamePlateCVars)
	left:CreateSlider("nameplates-max-distance", Settings["nameplates-max-distance"], 20, 60, 1, "Maximum Distance", "Set nameplate distance up to the client limit", UpdateNamePlateCVars)
	left:CreateSwitch("nameplates-friendly-name-only", Settings["nameplates-friendly-name-only"], "Friendly Names Only", "Only show names on friendly nameplates", UpdateNamePlateCVars)
	left:CreateSlider("nameplates-target-scale", Settings["nameplates-target-scale"], 100, 150, 1, "Target Scale", "Set the selected nameplate scale", UpdateNamePlateCVars)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("nameplates-font", Settings["nameplates-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the name plates"], UpdateNamePlatesFont, "Font")
	left:CreateSlider("nameplates-font-size", Settings["nameplates-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the name plates"], UpdateNamePlatesFont)
	left:CreateDropdown("nameplates-font-flags", Settings["nameplates-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the name plates"], UpdateNamePlatesFont)

	left:CreateHeader(Language["Health"])
	left:CreateSlider("nameplates-width", Settings["nameplates-width"], 60, 220, 1, "Set Width", "Set the width of name plates", UpdateNamePlatesWidth)
	left:CreateSlider("nameplates-height", Settings["nameplates-height"], 4, 50, 1, "Set Height", "Set the height of name plates", UpdateNamePlatesHeight)
	left:CreateDropdown("nameplates-health-color", Settings["nameplates-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM", [Language["Blizzard"]] = "BLIZZARD", [Language["Threat"]] = "THREAT"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateNamePlatesHealthColor)
	left:CreateSwitch("nameplates-health-smooth", Settings["nameplates-health-smooth"], Language["Enable Smooth Progress"], Language["Set the health bar to animate changes smoothly"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("NPHealthTexture", Settings.NPHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")
	left:CreateSwitch("nameplates-execute-coloring", Settings["nameplates-execute-coloring"], "Execute-range Coloring", "Color low-health nameplates", UpdateNamePlateAppearance)
	left:CreateSlider("nameplates-execute-threshold", Settings["nameplates-execute-threshold"], 1, 50, 1, "Execute Threshold", "Health percentage considered execute range", UpdateNamePlateAppearance)
	left:CreateColorSelection("nameplates-execute-color", Settings["nameplates-execute-color"], "Execute Color", "Color used in execute range", UpdateNamePlateAppearance)
	left:CreateColorSelection("nameplates-threat-tank-safe", Settings["nameplates-threat-tank-safe"], "Tank: Secure", "Threat color when a tank securely holds threat", UpdateNamePlateAppearance)
	left:CreateColorSelection("nameplates-threat-tank-danger", Settings["nameplates-threat-tank-danger"], "Tank: Losing", "Threat color when a tank does not hold threat", UpdateNamePlateAppearance)
	left:CreateColorSelection("nameplates-threat-dps-safe", Settings["nameplates-threat-dps-safe"], "Damage/Healer: Safe", "Threat color without aggro", UpdateNamePlateAppearance)
	left:CreateColorSelection("nameplates-threat-dps-danger", Settings["nameplates-threat-dps-danger"], "Damage/Healer: Aggro", "Threat color when holding aggro", UpdateNamePlateAppearance)

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("nameplates-enable-auras", Settings["nameplates-enable-auras"], Language["Enable Buffs"], Language["Display buffs above nameplates"], UpdateNamePlatesEnableAuras)
	left:CreateDropdown("nameplates-buffs-direction", Settings["nameplates-buffs-direction"], {[Language["Left to Right"]] = "LTR", [Language["Right to Left"]] = "RTL"}, Language["Buff Direction"], Language["Set which direction the buffs will grow towards"], UpdateNamePlatesBuffDirection)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSwitch("nameplates-only-player-debuffs", Settings["nameplates-only-player-debuffs"], Language["Only Display Player Debuffs"], Language["If enabled, only your own debuffs will be displayed"], UpdateNamePlatesShowPlayerDebuffs)
	left:CreateDropdown("nameplates-debuffs-direction", Settings["nameplates-debuffs-direction"], {[Language["Left to Right"]] = "LTR", [Language["Right to Left"]] = "RTL"}, Language["Debuff Direction"], Language["Set which direction the debuffs will grow towards"], UpdateNamePlatesDebuffDirection)

	right:CreateHeader(Language["Information"])
	right:CreateInput("nameplates-top-text", Settings["nameplates-top-text"], Language["Top Text"], "")
	right:CreateInput("nameplates-topleft-text", Settings["nameplates-topleft-text"], Language["Top Left Text"], "")
	right:CreateInput("nameplates-topright-text", Settings["nameplates-topright-text"], Language["Top Right Text"], "")
	right:CreateInput("nameplates-bottom-text", Settings["nameplates-bottom-text"], Language["Bottom Text"], "")
	right:CreateInput("nameplates-bottomleft-text", Settings["nameplates-bottomleft-text"], Language["Bottom Left Text"], "")
	right:CreateInput("nameplates-bottomright-text", Settings["nameplates-bottomright-text"], Language["Bottom Right Text"], "")

	right:CreateHeader(Language["Casting Bar"])
	right:CreateSwitch("nameplates-enable-castbar", Settings["nameplates-enable-castbar"], Language["Enable Casting Bar"], Language["Enable the casting bar the name plates"], UpdateNamePlatesEnableCastBars)
	right:CreateSwitch("nameplates-cast-classcolor", Settings["nameplates-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], ReloadUI):RequiresReload(true)
	right:CreateSlider("nameplates-castbar-height", Settings["nameplates-castbar-height"], 3, 28, 1, Language["Set Height"], Language["Set the height of name plate casting bars"], UpdateNamePlatesCastBarsHeight)
	right:CreateColorSelection("nameplates-castbar-interruptible-color", Settings["nameplates-castbar-interruptible-color"], "Interruptible Color", "Color for interruptible casts", UpdateNamePlateAppearance)
	right:CreateColorSelection("nameplates-castbar-uninterruptible-color", Settings["nameplates-castbar-uninterruptible-color"], "Non-interruptible Color", "Color for protected casts", UpdateNamePlateAppearance)
	right:CreateSwitch("nameplates-castbar-show-name", Settings["nameplates-castbar-show-name"], "Show Cast Name", "Display cast-name text", UpdateNamePlateAppearance)
	right:CreateSwitch("nameplates-castbar-show-time", Settings["nameplates-castbar-show-time"], "Show Cast Time", "Display remaining cast time", UpdateNamePlateAppearance)
	right:CreateSwitch("nameplates-castbar-enable-icon", Settings["nameplates-castbar-enable-icon"], "Show Cast Icon", "Display the spell icon", UpdateNamePlateAppearance)
	right:CreateSwitch("nameplates-castbar-emphasize-target", Settings["nameplates-castbar-emphasize-target"], "Emphasize Target Cast", "Enlarge the target's cast bar", UpdateNamePlateAppearance)
	right:CreateDropdown("NPCastTexture", Settings.NPCastTexture, Assets:GetTextureList(), Language["Castbar Texture"], "", UpdateCastTexture, "Texture")

	right:CreateHeader(Language["Target Indicator"])
	right:CreateSwitch("nameplates-enable-target-indicator", Settings["nameplates-enable-target-indicator"], Language["Enable Target Indicator"], Language["Display an indication on the targetted unit name plate"], UpdateNamePlatesTargetHighlight)
	right:CreateDropdown("nameplates-target-indicator-size", Settings["nameplates-target-indicator-size"], {[Language["Small"]] = "SMALL", [Language["Large"]] = "LARGE", [Language["Huge"]] = "HUGE"}, Language["Indicator Size"], Language["Select the size of the target indicator"], UpdateNamePlatesTargetIndicatorSize)

	right:CreateHeader(Language["Opacity"])
	right:CreateSlider("nameplates-selected-alpha", Settings["nameplates-selected-alpha"], 1, 100, 5, Language["Selected Opacity"], Language["Set the opacity of the selected name plate"], UpdateNamePlateSelectedAlpha)
	right:CreateSlider("nameplates-unselected-alpha", Settings["nameplates-unselected-alpha"], 0, 100, 5, Language["Unselected Opacity"], Language["Set the opacity of unselected name plates"], UpdateNamePlateUnselectedAlpha)
end)
