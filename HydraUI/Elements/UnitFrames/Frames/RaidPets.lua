local HydraUI, Language, _, Settings, Defaults = select(2, ...):get()

Defaults["raid-pets-enable"] = true
Defaults["raid-pets-width"] = 78
Defaults["raid-pets-health-height"] = 22
Defaults["raid-pets-health-reverse"] = false
Defaults["raid-pets-health-color"] = "CLASS"
Defaults["raid-pets-health-orientation"] = "HORIZONTAL"
Defaults["raid-pets-health-smooth"] = true

local UF = HydraUI:GetModule("Unit Frames")

local RaidPetsFrameConfig = {
	settingsPrefix = "raid-pets",
	backdropLayer = "BORDER",
	healthTextureKey = "ui-widget-texture",
	healthBackgroundLayer = "BACKGROUND",
	healthOrientation = true,
	healthSmoothKey = "raid-pets-health-smooth",
	healthFrequentUpdates = true,
	healthTags = false,
	fontKey = "raid-font",
	fontSizeKey = "raid-font-size",
	fontFlagsKey = "raid-font-flags",
	middleTag = "[Name10]",
	mouseoverKey = "RaidEnableMouseover",
	power = false,
	colorDisconnected = true,
	raidTarget = true,
	range = {},
}

HydraUI.StyleFuncs["raidpet"] = function(self, unit)
	RaidPetsFrameConfig.range.insideAlpha = Settings["raid-in-range"] / 100
	RaidPetsFrameConfig.range.outsideAlpha = Settings["raid-out-of-range"] / 100

	UF:BuildSingleUnitFrame(self, unit, RaidPetsFrameConfig)
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Raid Pets"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("raid-pets-enable", Settings["raid-pets-enable"], Language["Enable Raid Pet Frames"], Language["Enable the raid pet frame module"], ReloadUI):RequiresReload(true)

	right:CreateHeader(Language["Raid Pets Size"])
	right:CreateSlider("raid-pets-width", Settings["raid-pets-width"], 40, 200, 1, Language["Width"], Language["Set the width of raid pet unit frames"], ReloadUI, nil):RequiresReload(true)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("raid-pets-health-height", Settings["raid-pets-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of raid health bars"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("raid-pets-health-color", Settings["raid-pets-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("raid-pets-health-orientation", Settings["raid-pets-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the fill orientation of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("raid-pets-health-reverse", Settings["raid-pets-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("raid-pets-health-smooth", Settings["raid-pets-health-smooth"], Language["Enable Smooth Progress"], Language["Set the health bar to animate changes smoothly"], ReloadUI):RequiresReload(true)
end)
