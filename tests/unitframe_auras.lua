-- Run from the repository root with Lua 5.1 or newer; WoW widgets are mocked.
unpack = unpack or table.unpack
local root = "HydraUI/Elements/UnitFrames/"
local UF, settings, defaults, callbacks, plates = {}, {}, {}, {}, {}
local HydraUI = {StyleFuncs = {}, DebuffColors = {}}
local Language = setmetatable({}, {__index = function(_, key) return key end})
local widgetMethods = {
	"SetScale", "SetSize", "SetWidth", "SetHeight", "SetPoint", "SetAllPoints",
	"SetTexture", "SetVertexColor", "SetStatusBarTexture", "SetStatusBarColor",
	"EnableMouse", "SetFrameLevel", "SetAlpha", "SetJustifyH", "SetTexCoord",
	"Tag", "EnableElement", "DisableElement", "RequiresReload",
}
local trace = {}
local function Record(name, ...)
	local values = {name}
	for i = 1, select("#", ...) do
		values[#values + 1] = tostring(select(i, ...))
	end
	trace[#trace + 1] = table.concat(values, ":")
end
local function Widget(name)
	local widget = {name = name, colors = {}}
	for _, method in ipairs(widgetMethods) do
		widget[method] = function(self) return self end
	end
	function widget:Show() self.shown = true; Record(name .. ".show") end
	function widget:Hide() self.shown = false; Record(name .. ".hide") end
	function widget:SetAlpha(value) self.alpha = value; Record(name .. ".alpha", value) end
	function widget:SetCooldown(start, duration) Record(name .. ".cooldown", start, duration) end
	function widget:SetText(text) self.text = text; Record(name .. ".text", text) end
	function widget:ForceUpdate() self.refreshes = (self.refreshes or 0) + 1 end
	function widget:GetFrameLevel() return 1 end
	function widget:GetStatusBarTexture() return "texture" end
	function widget:CreateTexture() return Widget("texture") end
	function widget:CreateFontString() return Widget("text") end
	return widget
end
CreateFrame = function() return Widget("frame") end
C_NamePlate = {GetNamePlates = function() return plates end}
local GUI = {}
function GUI:AddWidgets(_, _, build) self.build = build end
function HydraUI:GetModule(name) return name == "GUI" and GUI or UF end
function HydraUI:SetFontInfo() end
function HydraUI:HexToRGB() return 1, 1, 1 end
function UF:SetHealthAttributes() end
local Assets = {}
function Assets:GetTexture(name) return name end
function Assets:GetTextureList() return {} end
function Assets:GetFontList() return {} end
function Assets:GetFlagsList() return {} end
local ns = {get = function() return HydraUI, Language, Assets, settings, defaults end}
local lifecycle
function UF:RegisterElement(name, handlers)
	assert(name == "AuraWatch")
	lifecycle = handlers
end
assert(loadfile(AURA_WATCH_SOURCE or root .. "Elements/AuraWatch.lua"))("HydraUI", ns)
local function Icon(id, options)
	local icon = Widget("icon" .. id)
	icon.cd, icon.count = Widget("cooldown" .. id), Widget("count" .. id)
	for key, value in pairs(options or {}) do icon[key] = value end
	return icon
end
local frame = Widget("owner")
frame.unit = "party1"
frame.AuraWatch = Widget("watch")
frame.AuraWatch.icons = {
	[1] = Icon(1), [2] = Icon(2, {anyUnit = true}),
	[3] = Icon(3, {onlyShowPresent = true}),
	[4] = Icon(4, {onlyShowMissing = true}),
}
function frame:RegisterEvent(event, handler) self.event, self.handler = event, handler end
function frame:UnregisterEvent(event, handler) assert(handler == self.handler); self.event = nil end
assert(lifecycle.enable(frame))
assert(frame.event == "UNIT_AURA")
local auraCalls, auras = 0, {}
UnitAura = function(unit, index, filter)
	assert(unit == "party1")
	auraCalls = auraCalls + 1
	local aura = auras[filter] and auras[filter][index]
	if aura then return aura.name, nil, aura.count, nil, aura.duration, aura.expiration, aura.caster, nil, nil, aura.spell end
end
local function Aura(spell, caster, count, duration)
	return {name = "aura", spell = spell, caster = caster, count = count, duration = duration, expiration = 10}
end
-- Harmful auras still follow helpful ones; the last matching aura wins.
auras.HELPFUL = {Aura(1, "other", 3, 5), Aura(2, "other", 2, 0), Aura(4, "player", 1, 5)}
auras.HARMFUL = {Aura(1, "pet", 4, 5), Aura(1, "vehicle", 5, 5)}
lifecycle.update(frame, "UNIT_AURA", "party1")
assert(frame.AuraWatch.icons[1].count.text == 5)
assert(frame.AuraWatch.icons[2].alpha == 1)
assert(not frame.AuraWatch.icons[2].cd.shown)
assert(not frame.AuraWatch.icons[3].shown and not frame.AuraWatch.icons[4].shown)
assert(auraCalls == 7)
local previousCalls = auraCalls
lifecycle.update(frame, "UNIT_AURA", "party2")
assert(auraCalls == previousCalls)
-- Empty scans retain the default missing alpha and clear counts/cooldowns.
auras = {}
frame.AuraWatch:ForceUpdate()
assert(frame.AuraWatch.icons[1].alpha == .75)
assert(frame.AuraWatch.icons[1].count.text == "")
assert(not frame.AuraWatch.icons[1].cd.shown)
-- Both scans retain the forty-aura cap.
auras.HELPFUL, auras.HARMFUL = {}, {}
for index = 1, 42 do
	auras.HELPFUL[index], auras.HARMFUL[index] = Aura(1, "player", index, 2), Aura(2, "player", index, 2)
end
auraCalls = 0
lifecycle.update(frame)
assert(auraCalls == 80 and frame.AuraWatch.icons[1].count.text == 40)
lifecycle.disable(frame)
assert(frame.event == nil)
assert(loadfile(NAMEPLATE_SOURCE or root .. "Frames/NamePlates.lua"))("HydraUI", ns)
for key, value in pairs(defaults) do settings[key] = value end
local panel = Widget("panel")
function panel:CreateHeader() end
function panel:CreateSwitch() return self end
function panel:CreateSlider() return self end
function panel:CreateInput() return self end
function panel:CreateDropdown(key, _, _, _, _, callback)
	callbacks[key] = callback
	return self
end
GUI.build(panel, panel)
local function CheckDirection(auras, direction)
	assert(auras.initialAnchor == (direction == "LTR" and "TOPLEFT" or "TOPRIGHT"))
	assert(auras["growth-x"] == (direction == "LTR" and "RIGHT" or "LEFT"))
	assert(auras["growth-y"] == "UP")
end
for _, mainline in ipairs({false, true}) do
	HydraUI.IsMainline = mainline
	for _, enabled in ipairs({false, true}) do
		settings["nameplates-enable-auras"] = enabled
		for _, direction in ipairs({"LTR", "RTL", "UNKNOWN"}) do
			settings["nameplates-buffs-direction"], settings["nameplates-debuffs-direction"] = direction, direction
			local plate = Widget("plate")
			HydraUI.StyleFuncs.nameplate(plate, "nameplate1")
			assert((plate.Buffs ~= nil) == enabled)
			if plate.Buffs then CheckDirection(plate.Buffs, direction) end
			CheckDirection(plate.Debuffs, direction)
			local changed = direction == "LTR" and "RTL" or "LTR"
			settings["nameplates-buffs-direction"], settings["nameplates-debuffs-direction"] = changed, changed
			UF.NamePlateCallback(plate)
			if plate.Buffs then CheckDirection(plate.Buffs, changed) end
			CheckDirection(plate.Debuffs, changed)
			plates = {{_unitFrame = plate}, {}}
			settings["nameplates-buffs-direction"], settings["nameplates-debuffs-direction"] = direction, direction
			callbacks["nameplates-buffs-direction"]("ignored")
			callbacks["nameplates-debuffs-direction"]("ignored")
			if plate.Buffs then
				CheckDirection(plate.Buffs, direction)
				assert(plate.Buffs.refreshes == 1)
			end
			CheckDirection(plate.Debuffs, direction)
			assert(plate.Debuffs.refreshes == 1)
		end
	end
end
return table.concat(trace, "\n")
