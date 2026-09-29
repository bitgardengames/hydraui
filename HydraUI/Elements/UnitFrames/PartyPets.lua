local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["party-pets-enable"] = true
Defaults["party-pets-width"] = 78
Defaults["party-pets-health-height"] = 22
Defaults["party-pets-health-reverse"] = false
Defaults["party-pets-health-color"] = "CLASS"
Defaults["party-pets-health-orientation"] = "HORIZONTAL"
Defaults["party-pets-health-smooth"] = true
Defaults["party-pets-power-height"] = 0 -- NYI

local UF = HydraUI:GetModule("Unit Frames")

HydraUI.StyleFuncs["partypet"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	UF:CreateBackdrop(self, { texture = "Blank", layer = "BORDER" })
	UF:CreateThreatIndicator(self, { backdrop = HydraUI.Outline, postUpdate = UF.ThreatPostUpdate })

	-- Health and prediction bars use only this frame family's resolved settings.
	local Health, HealthBG = UF:CreateHealthBar(self, {
		height = Settings["party-pets-health-height"],
		texture = Settings["ui-widget-texture"],
		reverseFill = Settings["party-pets-health-reverse"],
		orientation = Settings["party-pets-health-orientation"],
		backgroundLayer = "BACKGROUND",
	})
	local HealBar, AbsorbsBar = UF:CreateHealAndAbsorbBars(self, Health, {
		width = Settings["party-pets-width"],
		height = Settings["party-pets-health-height"],
		texture = Settings["ui-widget-texture"],
		reverseFill = Settings["party-pets-health-reverse"],
		createAbsorb = HydraUI.IsMainline,
	})

	local Highlight = UF:CreateMouseoverHighlight(self, Health, {
		texture = "Blank", enabled = Settings.PartyEnableMouseover,
	})

	local HealthMiddle = UF:CreateFontString(Health, {
		font = Settings["party-font"], size = Settings["party-font-size"], flags = Settings["party-font-flags"],
		point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, justify = "CENTER",
	})

	-- Attributes
	Health.frequentUpdates = true
	Health.colorDisconnected = true
	Health.Smooth = Settings["party-pets-health-smooth"]

	UF:SetHealthAttributes(Health, Settings["party-pets-health-color"])

	-- Target Icon
	local RaidTarget = UF:CreateRaidTargetIndicator(Health, { size = 16 })

	-- Tags
	self:Tag(HealthMiddle, "[Name10]")

	self.Range = {
		insideAlpha = Settings["party-in-range"] / 100,
		outsideAlpha = Settings["party-out-of-range"] / 100,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthMiddle = HealthMiddle
	self.RaidTargetIndicator = RaidTarget
end

local UpdateHealthTexture = function(value)
	UF:SetHeaderHealthTexture(HydraUI.UnitFrames["partypet"], value)
end

local UpdatePowerTexture = function(value)
	if HydraUI.UnitFrames["partypet"] then
		UF:ForEachHeaderChild(HydraUI.UnitFrames["partypet"], function(Unit, value)
			Unit.Power:SetStatusBarTexture(Assets:GetTexture(value))
			Unit.Power.bg:SetTexture(Assets:GetTexture(value))
		end, value)
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Party Pets"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("party-pets-enable", Settings["party-pets-enable"], Language["Enable Party Pet Frames"], Language["Enable the party pet frames module"], ReloadUI):RequiresReload(true)

	right:CreateHeader(Language["Party Pets Size"])
	right:CreateSlider("party-pets-width", Settings["party-pets-width"], 40, 200, 1, Language["Width"], Language["Set the width of party pet unit frames"], ReloadUI, nil):RequiresReload(true)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("party-pets-health-height", Settings["party-pets-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of party health bars"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("party-pets-health-color", Settings["party-pets-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("party-pets-health-orientation", Settings["party-pets-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the fill orientation of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("party-pets-health-reverse", Settings["party-pets-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("party-pets-health-smooth", Settings["party-pets-health-smooth"], Language["Enable Smooth Progress"], Language["Set the health bar to animate changes smoothly"], ReloadUI):RequiresReload(true)
end)
