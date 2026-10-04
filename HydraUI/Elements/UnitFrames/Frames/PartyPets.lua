local HydraUI, Language, _, Settings, Defaults = select(2, ...):get()

Defaults["party-pets-enable"] = true
Defaults["party-pets-width"] = 78
Defaults["party-pets-health-height"] = 22
Defaults["party-pets-health-reverse"] = false
Defaults["party-pets-health-color"] = "CLASS"
Defaults["party-pets-health-orientation"] = "HORIZONTAL"
Defaults["party-pets-health-smooth"] = true

local UF = HydraUI:GetModule("Unit Frames")

local PartyPetsFrameConfig = {
	settingsPrefix = "party-pets",
	backdropLayer = "BORDER",
	healthTextureKey = "ui-widget-texture",
	healthBackgroundLayer = "BACKGROUND",
	healthOrientation = true,
	healthSmoothKey = "party-pets-health-smooth",
	healthFrequentUpdates = true,
	healthTags = false,
	fontKey = "party-font",
	fontSizeKey = "party-font-size",
	fontFlagsKey = "party-font-flags",
	middleTag = "[Name10]",
	mouseoverKey = "PartyEnableMouseover",
	power = false,
	colorDisconnected = true,
	raidTarget = true,
	range = {},
}

HydraUI.StyleFuncs["partypet"] = function(self, unit)
	PartyPetsFrameConfig.range.insideAlpha = Settings["party-in-range"] / 100
	PartyPetsFrameConfig.range.outsideAlpha = Settings["party-out-of-range"] / 100

	UF:BuildSingleUnitFrame(self, unit, PartyPetsFrameConfig)
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
