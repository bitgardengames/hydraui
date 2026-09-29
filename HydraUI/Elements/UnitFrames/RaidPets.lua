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

	UF:CreateBackdrop(self, "Blank", "BORDER")
	UF:CreateThreatIndicator(self, HydraUI.Outline, UF.ThreatPostUpdate)

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(
		self,
		Settings["raid-pets-health-height"],
		Settings["ui-widget-texture"],
		Settings["raid-pets-health-reverse"],
		Settings["raid-pets-health-orientation"],
		"BACKGROUND"
	)
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(
		self,
		Health,
		Settings["raid-pets-width"],
		Settings["raid-pets-health-height"],
		Settings["ui-widget-texture"],
		Settings["raid-pets-health-reverse"],
		HydraUI.IsMainline
	)

	local Highlight = UF:CreateMouseoverHighlight(self, Health, "Blank", Settings.RaidEnableMouseover)

	local HealthMiddle = UF:CreateFontString(
		Health,
		Settings["raid-font"],
		Settings["raid-font-size"],
		Settings["raid-font-flags"],
		"CENTER",
		"CENTER",
		0,
		0,
		"CENTER"
	)

	-- Attributes
	Health.frequentUpdates = true
	Health.colorDisconnected = true
	Health.Smooth = Settings["raid-pets-health-smooth"]

	UF:SetHealthAttributes(Health, Settings["raid-pets-health-color"])

	-- Target Icon
	local RaidTarget = UF:CreateRaidTargetIndicator(Health, 16)

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

local UpdateHealthTexture = function(value)
	UF:SetHeaderHealthTexture(HydraUI.UnitFrames["raidpet"], value)
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
