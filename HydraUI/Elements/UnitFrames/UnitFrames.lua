local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local oUF = ns.oUF or oUF

local find = string.find

Defaults["unitframes-only-player-debuffs"] = false
Defaults["unitframes-show-player-buffs"] = true
Defaults["unitframes-show-player-debuffs"] = true
Defaults["unitframes-show-target-buffs"] = true
Defaults["unitframes-show-target-debuffs"] = true
Defaults["unitframes-show-druid-mana"] = true
Defaults["unitframes-font"] = "Roboto"
Defaults["unitframes-font-size"] = 12
Defaults["unitframes-font-flags"] = ""
Defaults["unitframes-display-aura-timers"] = true

local UF = HydraUI:NewModule("Unit Frames")

local function ForEachChild(operation, value, descriptor, child, ...)
	if not child then
		return
	end

	operation(child, value, descriptor)

	return ForEachChild(operation, value, descriptor, ...)
end

-- Secure group headers return their children as multiple values. Pass those
-- values through the iterator so each invocation uses the header's current
-- children without allocating a temporary table.
function UF:ForEachHeaderChild(header, operation, value, descriptor)
	if not header then
		return
	end

	ForEachChild(operation, value, descriptor, header:GetChildren())
end

HydraUI.UnitFrames = {}
HydraUI.StyleFuncs = {}

local Hider = CreateFrame("Frame", nil, HydraUI.UIParent, "SecureHandlerStateTemplate")
Hider:Hide()

-- Focused modules install the existing public UF methods on the shared module.
ns.UnitFrameComponentFactory(UF, Hider)
ns.UnitFrameAuraSupport(UF, Hider)
ns.UnitFrameCastSupport(UF, Hider)
ns.UnitFrameTotemSupport(UF, Hider)

function UF:GetRoleTexCoords(role)
	if role == "TANK" then
		return 0, 19/64, 22/64, 41/64
	elseif role == "HEALER" then
		return 20/64, 39/64, 1/64, 20/64
	elseif role == "DAMAGER" then
		return 20/64, 39/64, 22/64, 41/64
	end
end

if CompactRaidFrameManager then
	CompactRaidFrameManager:SetParent(UIParent)
end

local Style = function(self, unit)
	local StyleFunc = HydraUI.StyleFuncs[unit]

	if (not StyleFunc) and find(unit, "raidpet") and Settings["raid-pets-enable"] then
		StyleFunc = HydraUI.StyleFuncs["raidpet"]
	elseif (not StyleFunc) and find(unit, "raid") and Settings["raid-enable"] then
		StyleFunc = HydraUI.StyleFuncs["raid"]
	elseif (not StyleFunc) and find(unit, "partypet") and Settings["party-enable"] and Settings["party-pets-enable"] then
		StyleFunc = HydraUI.StyleFuncs["partypet"]
	elseif (not StyleFunc) and find(unit, "party") and not find(unit, "pet") and Settings["party-enable"] then
		StyleFunc = HydraUI.StyleFuncs["party"]
	elseif (not StyleFunc) and find(unit, "nameplate") and Settings["nameplates-enable"] then
		StyleFunc = HydraUI.StyleFuncs["nameplate"]
	elseif (not StyleFunc) and find(unit, "boss%d") then
		StyleFunc = HydraUI.StyleFuncs["boss"]
	end

	if StyleFunc then
		StyleFunc(self, unit)
	end
end

oUF:RegisterStyle("HydraUI", Style)

ns.UnitFrameSpawning(UF, Hider)

function UF:Load()
	self:SpawnSingletonFrames()
	self:SpawnBossFrames()
	self:SpawnPartyHeaders()
	self:SpawnRaidHeaders()
	self:SpawnNameplates()
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Font"])
	left:CreateDropdown("unitframes-font", Settings["unitframes-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the unit frames"], nil, "Font")
	left:CreateSlider("unitframes-font-size", Settings["unitframes-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the unit frames"])
	left:CreateDropdown("unitframes-font-flags", Settings["unitframes-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the unit frames"])

	right:CreateHeader(Language["Auras"])
	right:CreateSwitch("unitframes-display-aura-timers", Settings["unitframes-display-aura-timers"], Language["Display Aura Timers"], Language["Display the timer on unit frame auras"], ReloadUI):RequiresReload(true)
end)
