local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["raid-pets-enable"] = true
Defaults["raid-pets-width"] = 78
Defaults["raid-pets-health-height"] = 22
Defaults["raid-pets-health-reverse"] = false
Defaults["raid-pets-health-color"] = "CLASS"
Defaults["raid-pets-health-orientation"] = "HORIZONTAL"
Defaults["raid-pets-health-smooth"] = true
Defaults["raid-pets-power-height"] = 0 -- NYI

local UF = HydraUI:GetModule("Unit Frames")

HydraUI.StyleFuncs["raidpet"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	local Backdrop = self:CreateTexture(nil, "BORDER")
	Backdrop:SetAllPoints()
	Backdrop:SetTexture(Assets:GetTexture("Blank"))
	Backdrop:SetVertexColor(0, 0, 0)

	-- Threat
	local Threat = CreateFrame("Frame", nil, self, "BackdropTemplate")
	Threat:SetPoint("TOPLEFT", -1, 1)
	Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	Threat:SetBackdrop(HydraUI.Outline)
	Threat.PostUpdate = UF.ThreatPostUpdate

	self.ThreatIndicator = Threat

	-- Health Bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetPoint("TOPLEFT", self, 1, -1)
	Health:SetPoint("TOPRIGHT", self, -1, -1)
	Health:SetHeight(Settings["raid-pets-health-height"])
	Health:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Health:SetReverseFill(Settings["raid-pets-health-reverse"])
	Health:SetOrientation(Settings["raid-pets-health-orientation"])

	local HealBar = CreateFrame("StatusBar", nil, self)
	HealBar:SetAllPoints(Health)
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)

	if Settings["raid-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if HydraUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["raid-width"])
		AbsorbsBar:SetHeight(Settings["raid-pets-health-height"])
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if Settings["raid-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BACKGROUND")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	HealthBG.multiplier = 0.2

	local Highlight = Health:CreateTexture(nil, "OVERLAY")
	Highlight:SetAllPoints(Health)
	Highlight:SetTexture(Assets:GetTexture("Blank"))
	Highlight:SetVertexColor(0.8, 0.8, 0.8)
	Highlight:SetAlpha(0)
	Highlight:SetDrawLayer("OVERLAY", 7)
	self:HookScript("OnEnter", function(self) self.Highlight:SetAlpha(0.15) end)
	self:HookScript("OnLeave", function(self) self.Highlight:SetAlpha(0) end)

	self.Highlight = Highlight

	if (not Settings.RaidEnableMouseover) then
		Highlight:Hide()
	end

	local HealthMiddle = Health:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(HealthMiddle, Settings["raid-font"], Settings["raid-font-size"], Settings["raid-font-flags"])
	HealthMiddle:SetPoint("CENTER", Health, 0, 0)
	HealthMiddle:SetJustifyH("CENTER")

	-- Attributes
	Health.frequentUpdates = true
	Health.colorDisconnected = true
	Health.Smooth = Settings["raid-pets-health-smooth"]

	UF:SetHealthAttributes(Health, Settings["raid-pets-health-color"])

	-- Target Icon
	local RaidTarget = Health:CreateTexture(nil, 'OVERLAY')
	RaidTarget:SetSize(16, 16)
	RaidTarget:SetPoint("CENTER", Health, "TOP")

	-- Tags
	self:Tag(HealthMiddle, "[Name10]")

	self.Range = {
		insideAlpha = Settings["raid-in-range"] / 100,
		outsideAlpha = Settings["raid-out-of-range"] / 100,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthMiddle = HealthMiddle
	self.RaidTargetIndicator = RaidTarget
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Raid Pets"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("raid-pets-enable", Settings["raid-pets-enable"], Language["Enable Raid Pet Frames"], Language["Enable the Raid pet frames module"], ReloadUI):RequiresReload(true)

	right:CreateHeader(Language["Raid Pets Size"])
	right:CreateSlider("raid-pets-width", Settings["raid-pets-width"], 40, 200, 1, Language["Width"], Language["Set the width of raid pet unit frames"], ReloadUI, nil):RequiresReload(true)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("raid-pets-health-height", Settings["raid-pets-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of raid health bars"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("raid-pets-health-color", Settings["raid-pets-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("raid-pets-health-orientation", Settings["raid-pets-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the fill orientation of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("raid-pets-health-reverse", Settings["raid-pets-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("raid-pets-health-smooth", Settings["raid-pets-health-smooth"], Language["Enable Smooth Progress"], Language["Set the health bar to animate changes smoothly"], ReloadUI):RequiresReload(true)
end)
