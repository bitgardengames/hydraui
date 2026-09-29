local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["raid-enable"] = true
Defaults["raid-width"] = 78
Defaults["raid-in-range"] = 100
Defaults["raid-out-of-range"] = 50
Defaults["raid-health-height"] = 42
Defaults["raid-health-reverse"] = false
Defaults["raid-health-color"] = "CLASS"
Defaults["raid-health-orientation"] = "HORIZONTAL"
Defaults["raid-health-top"] = "[Name(10)]"
Defaults["raid-health-bottom"] = "[HealthDeficit:Short]"
Defaults["raid-health-smooth"] = true
Defaults["raid-power-enable"] = false
Defaults["raid-power-height"] = 2
Defaults["raid-power-reverse"] = false
Defaults["raid-power-color"] = "POWER"
Defaults["raid-power-smooth"] = true
Defaults["raid-x-offset"] = 2
Defaults["raid-y-offset"] = -2
Defaults["raid-units-per-column"] = 5
Defaults["raid-max-columns"] = 8
Defaults["raid-column-spacing"] = 2
Defaults["raid-point"] = "LEFT"
Defaults["raid-column-anchor"] = "TOP"
Defaults["raid-sorting-method"] = "GROUP"
Defaults["raid-show-solo"] = false
Defaults["raid-font"] = "Roboto"
Defaults["raid-font-size"] = 12
Defaults["raid-font-flags"] = ""
Defaults.RaidHealthTexture = "HydraUI 4"
Defaults.RaidPowerTexture = "HydraUI 4"
Defaults.RaidEnableMouseover = true

local UF = HydraUI:GetModule("Unit Frames")

local Ignore = {}

if HydraUI.IsWrath then
	Ignore[GetSpellInfo(69127)] = true -- Chill of the Throne
end

local RaidDebuffFilter = function(self, unit, icon, name, texture, count, dtype, duration, timeLeft, caster, stealable, nameplateshow, id, canapply, boss, player, showall)
	if Ignore[name] then
		return false
	end

	if (boss or (count and count > 0) or (duration > 0 and timeLeft and not player and not canapply)) then
		return true
	end
end

HydraUI.StyleFuncs["raid"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	UF:CreateBackdrop(self, "Blank", "BACKGROUND")
	UF:CreateThreatIndicator(self, HydraUI.Outline, UF.ThreatPostUpdate)

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(
		self,
		Settings["raid-health-height"],
		Settings.RaidHealthTexture,
		Settings["raid-health-reverse"],
		Settings["raid-health-orientation"],
		"BORDER"
	)
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(
		self,
		Health,
		Settings["raid-width"],
		Settings["raid-health-height"],
		Settings.RaidHealthTexture,
		Settings["raid-health-reverse"],
		HydraUI.IsMainline
	)

	local Highlight = UF:CreateMouseoverHighlight(self, Health, "Blank", Settings.RaidEnableMouseover)

	local HealthDead = Health:CreateTexture(nil, "OVERLAY")
	HealthDead:SetAllPoints(Health)
	HealthDead:SetTexture(Assets:GetTexture("RenHorizonUp"))
	HealthDead:SetVertexColor(0.8, 0.8, 0.8)
	HealthDead:SetAlpha(0)
	HealthDead:SetDrawLayer("OVERLAY", 7)

	Health.DeadAnim = LibMotion:CreateAnimationGroup()

	Health.DeadAnim.In = LibMotion:CreateAnimation(HealthDead, "Fade")
	Health.DeadAnim.In:SetEasing("in")
	Health.DeadAnim.In:SetDuration(0.15)
	Health.DeadAnim.In:SetChange(0.6)
	Health.DeadAnim.In:SetGroup(Health.DeadAnim)
	Health.DeadAnim.In:SetOrder(1)

	Health.DeadAnim.Out = LibMotion:CreateAnimation(HealthDead, "Fade")
	Health.DeadAnim.Out:SetEasing("out")
	Health.DeadAnim.Out:SetDuration(0.3)
	Health.DeadAnim.Out:SetChange(0)
	Health.DeadAnim.Out:SetGroup(Health.DeadAnim)
	Health.DeadAnim.Out:SetOrder(2)

	local HealthName = UF:CreateFontString(
		Health,
		Settings["raid-font"],
		Settings["raid-font-size"],
		Settings["raid-font-flags"],
		"BOTTOM",
		"CENTER",
		0,
		1,
		"CENTER"
	)

	local HealthBottom = UF:CreateFontString(
		Health,
		Settings["raid-font"],
		Settings["raid-font-size"],
		Settings["raid-font-flags"],
		"TOP",
		"CENTER",
		0,
		-1,
		"CENTER"
	)

	-- Attributes
	Health.colorDisconnected = true
	Health.Smooth = true

	UF:SetHealthAttributes(Health, Settings["raid-health-color"])

	local Power, PowerBG = UF:CreatePowerBar(self, Settings["raid-power-height"], Settings.RaidPowerTexture, Settings["raid-power-reverse"])

	-- Attributes
	Power.frequentUpdates = true

	UF:SetPowerAttributes(Power, Settings["raid-power-color"])

	if UF.BuffIDs[HydraUI.UserClass] then
		local Auras = CreateFrame("Frame", nil, Health)
		Auras:SetPoint("TOPLEFT", Health)
		Auras:SetPoint("BOTTOMRIGHT", Health)
		Auras:SetFrameLevel(10)
		Auras:SetFrameStrata("HIGH")
		Auras.presentAlpha = 1
		Auras.missingAlpha = 0
		Auras.strictMatching = true
		Auras.icons = {}
		Auras.PostCreateIcon = UF.PostCreateAuraWatchIcon

		for key, spell in next, UF.BuffIDs[HydraUI.UserClass] do
			local Icon = CreateFrame("Frame", nil, Auras)
			Icon.spellID = spell[1]
			Icon.anyUnit = spell[4]
			Icon.strictMatching = true
			Icon:SetSize(8, 8)
			Icon:SetPoint(spell[2], 0, 0)

			local Texture = Icon:CreateTexture(nil, "OVERLAY")
			Texture:SetAllPoints(Icon)
			Texture:SetTexture(Assets:GetTexture("Blank"))

			local BG = Icon:CreateTexture(nil, "BORDER")
			BG:SetPoint("TOPLEFT", Icon, -1, 1)
			BG:SetPoint("BOTTOMRIGHT", Icon, 1, -1)
			BG:SetTexture(Assets:GetTexture("Blank"))
			BG:SetVertexColor(0, 0, 0)

			if (spell[3]) then
				Texture:SetVertexColor(unpack(spell[3]))
			else
				Texture:SetVertexColor(0.8, 0.8, 0.8)
			end

			local Count = Icon:CreateFontString(nil, "OVERLAY")
			HydraUI:SetFontInfo(Count, Settings["raid-font"], 10)
			Count:SetPoint("CENTER", unpack(UF.AuraOffsets[spell[2]]))
			Icon.count = Count

			Auras.icons[spell[1]] = Icon
		end

		self.AuraWatch = Auras
	end

	-- Debuffs
	local Debuffs = UF:CreateAuraContainer(
		self,
		self:GetName() .. "Debuffs",
		Health,
		24,
		24,
		"CENTER",
		Health,
		"CENTER",
		nil,
		nil,
		24,
		0,
		1,
		"TOPLEFT",
		"ANCHOR_TOP",
		"RIGHT",
		"DOWN",
		UF.PostCreateIcon,
		UF.PostUpdateIcon,
		RaidDebuffFilter
	)
	self.Debuffs = Debuffs

	-- Leader
    local Leader = Health:CreateTexture(nil, "OVERLAY")
    Leader:SetSize(16, 16)
    Leader:SetPoint("LEFT", Health, "TOPLEFT", 3, 0)
    Leader:SetTexture(Assets:GetTexture("Leader"))
    Leader:SetVertexColor(HydraUI:HexToRGB("FFEB3B"))
    Leader:Hide()

	-- Assist
    local Assist = Health:CreateTexture(nil, "OVERLAY")
    Assist:SetSize(16, 16)
    Assist:SetPoint("LEFT", Health, "TOPLEFT", 3, 0)
    Assist:SetTexture(Assets:GetTexture("Assist"))
    Assist:SetVertexColor(HydraUI:HexToRGB("FFEB3B"))
    Assist:Hide()

	-- Ready Check
    local ReadyCheck = Health:CreateTexture(nil, "OVERLAY")
	ReadyCheck:SetSize(16, 16)
    ReadyCheck:SetPoint("LEFT", Health, 2, 0)

    -- Phase
    local PhaseIndicator = CreateFrame("Frame", nil, Health)
    PhaseIndicator:SetSize(16, 16)
    PhaseIndicator:SetPoint("LEFT", Health, 2, 0)

	PhaseIndicator.Icon = PhaseIndicator:CreateTexture(nil, "OVERLAY")
	PhaseIndicator.Icon:SetAllPoints()

	-- Target Icon
	local RaidTarget = UF:CreateRaidTargetIndicator(Health, 16)

    -- Resurrect
	local Resurrect = Health:CreateTexture(nil, "OVERLAY")
	Resurrect:SetSize(16, 16)
	Resurrect:SetPoint("LEFT", Health, 2, 0)

	-- Role
	local RoleIndicator = Health:CreateTexture(nil, "OVERLAY")
	RoleIndicator:SetSize(16, 16)
	RoleIndicator:SetPoint("LEFT", Health, 2, 0)

	-- Dispels
	local Dispel = CreateFrame("Frame", nil, Health, "BackdropTemplate")
	Dispel:SetSize(22, 22)
	Dispel:SetPoint("CENTER", Health, 0, 0)
	Dispel:SetFrameLevel(Health:GetFrameLevel() + 20)
	Dispel:SetBackdrop(HydraUI.BackdropAndBorder)
	Dispel:SetBackdropColor(0, 0, 0)
	Dispel:SetFrameStrata("HIGH")
	Dispel:SetFrameLevel(10)

	Dispel.icon = Dispel:CreateTexture(nil, "ARTWORK")
	Dispel.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	Dispel.icon:SetPoint("TOPLEFT", Dispel, 1, -1)
	Dispel.icon:SetPoint("BOTTOMRIGHT", Dispel, -1, 1)

	Dispel.cd = CreateFrame("Cooldown", nil, Dispel, "CooldownFrameTemplate")
	Dispel.cd:SetPoint("TOPLEFT", Dispel, 1, -1)
	Dispel.cd:SetPoint("BOTTOMRIGHT", Dispel, -1, 1)
	Dispel.cd:SetHideCountdownNumbers(true)
	Dispel.cd:SetDrawEdge(false)

	Dispel.count = Dispel.cd:CreateFontString(nil, "ARTWORK")
	HydraUI:SetFontInfo(Dispel.count, Settings["raid-font"], Settings["raid-font-size"], Settings["raid-font-flags"])
	Dispel.count:SetPoint("BOTTOMRIGHT", Dispel, "BOTTOMRIGHT", -3, 3)
	Dispel.count:SetTextColor(1, 1, 1)
	Dispel.count:SetJustifyH("RIGHT")
	Dispel.count:SetDrawLayer("ARTWORK", 7)

	Dispel.bg = Dispel:CreateTexture(nil, "BACKGROUND")
	Dispel.bg:SetPoint("TOPLEFT", Dispel, -1, 1)
	Dispel.bg:SetPoint("BOTTOMRIGHT", Dispel, 1, -1)
	Dispel.bg:SetTexture(Assets:GetTexture("Blank"))
	Dispel.bg:SetVertexColor(0, 0, 0)

    -- Position and size

	self:Tag(HealthName, Settings["raid-health-top"])
	self:Tag(HealthBottom, Settings["raid-health-bottom"])

	self.Range = {
		insideAlpha = Settings["raid-in-range"] / 100,
		outsideAlpha = Settings["raid-out-of-range"] / 100,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.Power = Power
	self.Power.bg = PowerBG
	self.HealthName = HealthName
	self.HealthBottom = HealthBottom
	self.Dispel = Dispel
	self.LeaderIndicator = Leader
	self.AssistantIndicator = Assist
	self.ReadyCheckIndicator = ReadyCheck
	self.ResurrectIndicator = Resurrect
	self.RaidTargetIndicator = RaidTarget
	self.GroupRoleIndicator = RoleIndicator
	self.PhaseIndicator = PhaseIndicator
end

local UpdateRaidAnchorSize = function()
	UF.RaidAnchor:SetWidth((floor(40 / Settings["raid-max-columns"]) * Settings["raid-width"] + (floor(40 / Settings["raid-max-columns"]) * Settings["raid-x-offset"] - 2)))
	UF.RaidAnchor:SetHeight((Settings["raid-health-height"] + Settings["raid-power-height"]) * (Settings["raid-max-columns"] + (Settings["raid-y-offset"])) - 1)
end

local SetRaidWidth = function(Unit, value)
	UF:SetFrameWidth(Unit, value)
end

local SetRaidHealthHeight = function(Unit, value)
	UF:SetHealthHeight(Unit, value, Settings["raid-power-height"])
end

local SetRaidHealthColor = function(Unit, value)
	UF:ApplyHealthAttributes(Unit, value)
end

local SetRaidPowerEnabled = function(Unit, value)
	UF:SetElementEnabled(Unit, value, "Power")
	Unit:SetHeight(Settings["raid-health-height"] + (value and Settings["raid-power-height"] + 3 or 2))
end

local SetRaidPowerHeight = function(Unit, value)
	UF:SetPowerHeight(Unit, value, Settings["raid-health-height"])
end

local SetRaidHealthOrientation = function(Unit, value)
	Unit.Health:SetOrientation(value)
end

local SetRaidHealthReverseFill = function(Unit, value)
	UF:SetHealthReverseFill(Unit, value)
end

local SetRaidPowerReverseFill = function(Unit, value)
	UF:SetPowerReverseFill(Unit, value)
end

local SetRaidPowerColor = function(Unit, value)
	UF:ApplyPowerAttributes(Unit, value)
end

local SetRaidHealthTexture = function(Unit, value)
	UF:SetHealthTexture(Unit, value)
end

local SetRaidPowerTexture = function(Unit, value)
	UF:SetPowerTexture(Unit, value)
end

local UpdateRaidWidth = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidWidth, value)
		UpdateRaidAnchorSize()
	end
end

local UpdateRaidHealthHeight = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidHealthHeight, value)
		UpdateRaidAnchorSize()
	end
end

local UpdateRaidHealthColor = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidHealthColor, value)
	end
end

local UpdateRaidHealthOrientation = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidHealthOrientation, value)
	end
end

local UpdateRaidHealthReverseFill = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidHealthReverseFill, value)
	end
end

local UpdateEnableRaidPower = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidPowerEnabled, value)
	end
end

local UpdateRaidPowerHeight = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidPowerHeight, value)
		UpdateRaidAnchorSize()
	end
end

local UpdateRaidPowerReverseFill = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidPowerReverseFill, value)
	end
end

local UpdateRaidPowerColor = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidPowerColor, value)
	end
end

local SetHighlightShown = function(Unit, value)
	if value then
		Unit.Highlight:Show()
	else
		Unit.Highlight:Hide()
	end
end

local UpdateRaidShowHighlight = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetHighlightShown, value)

		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid-pets"], SetHighlightShown, value)
	end
end

local UpdateRaidXOffset = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("xoffset", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidYOffset = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("yoffset", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidUnitsPerColumn = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("unitsPerColumn", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidMaxColumns = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("maxColumns", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidColumnSpacing = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("columnSpacing", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidColumnAnchor = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("columnAnchorPoint", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidPoint = function(value)
	HydraUI.UnitFrames["raid"]:SetAttribute("point", value)

	UpdateRaidAnchorSize()
end

local UpdateRaidSortingMethod = function(value)
	if (value == "CLASS") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "DEATHKNIGHT,DEMONHUNTER,DRUID,HUNTER,MAGE,MONK,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "CLASS")
	elseif (value == "ROLE") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "ASSIGNEDROLE")
	elseif (value == "NAME") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", nil)
	elseif (value == "MTMA") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,NONE")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "ROLE")
	else -- GROUP
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "INDEX")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "GROUP")
	end
end

local HideTestFrame = function(Frame)
	UnregisterUnitWatch(Frame)
	Frame:Hide()
end

local ShowTestFrame = function(Frame)
	Frame.unit = "player"
	UnregisterUnitWatch(Frame)
	RegisterUnitWatch(Frame, true)
	Frame:Show()
end

local ShowTestPetFrame = function(Frame)
	Frame.unit = UnitExists("pet") and "pet" or "player"
	UnregisterUnitWatch(Frame)
	RegisterUnitWatch(Frame, true)
	Frame:Show()
end

local Testing = false

local TestRaid = function()
	local Header = _G["HydraUI Raid"]
	local Pets = _G["HydraUI Raid Pets"]

	if Testing then
		if Header then
			Header:SetAttribute("isTesting", false)

			if (Header:GetAttribute("startingIndex") ~= -24) then
				Header:SetAttribute("startingIndex", -24)
			end

			UF:ForEachHeaderChild(Header, HideTestFrame)
		end

		if Pets then
			Pets:SetAttribute("isTesting", false)

			if (Pets:GetAttribute("startingIndex") ~= -24) then
				Pets:SetAttribute("startingIndex", -24)
			end

			UF:ForEachHeaderChild(Pets, HideTestFrame)
		end

		Testing = false
	else
		if Header then
			Header:SetAttribute("isTesting", true)

			if (Header:GetAttribute("startingIndex") ~= -24) then
				Header:SetAttribute("startingIndex", -24)
			end

			UF:ForEachHeaderChild(Header, ShowTestFrame)
		end

		if Pets then
			Pets:SetAttribute("isTesting", true)

			if (Pets:GetAttribute("startingIndex") ~= -24) then
				Pets:SetAttribute("startingIndex", -24)
			end

			UF:ForEachHeaderChild(Pets, ShowTestPetFrame)
		end

		Testing = true
	end
end

local UpdateShowSolo = function(value)
	_G["HydraUI Raid"]:SetAttribute("showSolo", value)
end

local UpdateHealthTexture = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidHealthTexture, value)
	end
end

local UpdatePowerTexture = function(value)
	if HydraUI.UnitFrames["raid"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["raid"], SetRaidPowerTexture, value)
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Raid"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("raid-enable", Settings["raid-enable"], Language["Enable Raid Module"], Language["Enable the raid frames module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Raid Size"])
	left:CreateSlider("raid-width", Settings["raid-width"], 40, 200, 1, Language["Width"], Language["Set the width of the raid frames"], UpdateRaidWidth, nil)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("raid-font", Settings["raid-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the raid frames"], nil, "Font")
	left:CreateSlider("raid-font-size", Settings["raid-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the raid frames"])
	left:CreateDropdown("raid-font-flags", Settings["raid-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the raid frames"])

	right:CreateHeader(Language["Test Raid Frames"])
	right:CreateButton("", Language["Test"], Language["Test Raid"], Language["Test the raid frames"], TestRaid)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("raid-health-height", Settings["raid-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of raid health bars"], UpdateRaidHealthHeight)
	right:CreateDropdown("raid-health-color", Settings["raid-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateRaidHealthColor)
	right:CreateDropdown("raid-health-orientation", Settings["raid-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the fill orientation of the health bar"], UpdateRaidHealthOrientation)
	right:CreateSwitch("raid-health-reverse", Settings["raid-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateRaidHealthReverseFill)
	right:CreateDropdown("RaidHealthTexture", Settings.RaidHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("raid-power-enable", Settings["raid-power-enable"], Language["Enable Power Bar"], Language["Enable the power bar"], UpdateEnableRaidPower)
	right:CreateSwitch("raid-power-reverse", Settings["raid-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateRaidPowerReverseFill)
	right:CreateSlider("raid-power-height", Settings["raid-power-height"], 2, 30, 1, Language["Power Height"], Language["Set the height of raid power bars"], UpdateRaidPowerHeight)
	right:CreateDropdown("raid-power-color", Settings["raid-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateRaidPowerColor)
	right:CreateDropdown("RaidPowerTexture", Settings.RaidPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Text"])
	right:CreateInput("raid-health-top", Settings["raid-health-top"], Language["Top Text"], Language["Set the text on the top of the raid frame"], ReloadUI):RequiresReload(true)
	right:CreateInput("raid-health-bottom", Settings["raid-health-bottom"], Language["Bottom Text"], Language["Set the text on the bottom of the raid frame"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Range Opacity"])
	left:CreateSlider("raid-in-range", Settings["raid-in-range"], 0, 100, 5, Language["In Range"], Language["Set the opacity of raid members within range of you"])
	left:CreateSlider("raid-out-of-range", Settings["raid-out-of-range"], 0, 100, 5, Language["Out of Range"], Language["Set the opacity of raid members out of your range"])

	left:CreateHeader(Language["Attributes"])
	left:CreateSwitch("raid-show-solo", Settings["raid-show-solo"], Language["Show Solo"], Language["Display the raid frames while not in a group"], UpdateShowSolo)
	left:CreateSlider("raid-x-offset", Settings["raid-x-offset"], -10, 10, 1, Language["X Offset"], Language["Set the x offset of raid units from eachother"], UpdateRaidXOffset)
	left:CreateSlider("raid-y-offset", Settings["raid-y-offset"], -10, 10, 1, Language["Y Offset"], Language["Set the y offset of raid units from eachother"], UpdateRaidYOffset)
	left:CreateSlider("raid-units-per-column", Settings["raid-units-per-column"], 1, 40, 1, Language["Units Per Column"], Language["Set the maximum number of units per column"], UpdateRaidUnitsPerColumn)
	left:CreateSlider("raid-max-columns", Settings["raid-max-columns"], 1, 40, 1, Language["Max Columns"], Language["Set the maximum number of visible columns of raid units"], UpdateRaidMaxColumns)
	left:CreateSlider("raid-column-spacing", Settings["raid-column-spacing"], -10, 10, 1, Language["Column Spacing"], Language["Set the spacing between columns of raid units"], UpdateRaidColumnSpacing)
	left:CreateDropdown("raid-sorting-method", Settings["raid-sorting-method"], {[Language["Group"]] = "GROUP", [Language["Name"]] = "NAME", [Language["Class"]] = "CLASS", [Language["Role"]] = "ROLE", [Language["Main Tank"]] = "MTMA"}, Language["Sorting Method"], Language["Set how the raid units are sorted"], UpdateRaidSortingMethod)
	left:CreateDropdown("raid-point", Settings["raid-point"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["Anchor Point"], Language["Set where new raid frames will connect to previous ones"], UpdateRaidPoint)
	left:CreateDropdown("raid-column-anchor", Settings["raid-column-anchor"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["New Column Anchor"], Language["Set where new columns should anchor to"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("RaidEnableMouseover", Settings.RaidEnableMouseover, Language["Enable Mouseover"], Language["Enable a mouseover highlight on raid members"], UpdateRaidShowHighlight)
end)