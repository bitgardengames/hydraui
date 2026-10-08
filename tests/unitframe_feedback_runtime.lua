-- Run from the repository root with texlua or Lua. Exercises native feedback without a WoW client.
local unpack = unpack or table.unpack
local elements = {}
local UF = {}
local HydraUI = {IsMainline = false, DebuffColors = {Magic = {0, 0.5, 1}, Poison = {0, 1, 0}}}
function HydraUI:GetModule() return UF end
function UF:RegisterElement(name, handlers) elements[name] = handlers end
function UF:CreateForceUpdate(element, update)
	return function() update(element.__owner, "ForceUpdate") end
end
local ns = {get = function() return HydraUI end}
local function Load(name)
	assert(loadfile("HydraUI/Elements/UnitFrames/Elements/" .. name .. ".lua"))(nil, ns)
end
local function Widget()
	local widget = {scripts = {}, shown = true}
	function widget:Show() self.shown = true end
	function widget:Hide() self.shown = false end
	function widget:SetTexture(value) self.texture = value end
	function widget:SetText(value) self.text = value end
	function widget:SetCooldown(start, duration) self.start, self.duration = start, duration end
	function widget:SetBackdropBorderColor(...) self.color = {...} end
	function widget:SetAlpha(value) self.alpha = value end
	function widget:SetScript(event, handler) self.scripts[event] = handler end
	function widget:GetScript(event) return self.scripts[event] end
	function widget:HookScript(event, handler) self.scripts[event] = handler end
	function widget:IsVisible() return self.shown end
	function widget:RegisterEvent() end
	function widget:UnregisterEvent() end
	return widget
end
CreateFrame = Widget
UnitClass = function() return "Priest", "PRIEST" end
Load("Dispel")
local frame = Widget()
frame.unit = "party1"
frame.Dispel = Widget()
frame.Dispel.icon, frame.Dispel.cd, frame.Dispel.count = Widget(), Widget(), Widget()
local auras = {
	{1, "Duplicate", "poison", 1, "Poison", 10, 50, nil, false, 1},
	{2, "Duplicate", "magic", 3, "Magic", 12, 60, nil, false, 2},
}
function UF.EnumerateAuras(_, _, visitor)
	for _, aura in ipairs(auras) do visitor(unpack(aura, 1, 11)) end
end
assert(elements.Dispel.enable(frame))
elements.Dispel.update(frame)
assert(frame.Dispel.shown and frame.Dispel.icon.texture == "magic")
assert(frame.Dispel.SpellID == 2 and frame.Dispel.count.text == 3)
assert(frame.Dispel.color[2] == 0.5 and frame.Dispel.cd.start == 48)
auras[2][6], auras[2][7] = 0, 0
elements.Dispel.update(frame)
assert(frame.Dispel.shown and not frame.Dispel.cd.shown)
auras = {}
elements.Dispel.update(frame)
assert(not frame.Dispel.shown and frame.Dispel.SpellID == nil)

Load("Range")
frame.Range = {insideAlpha = 1, outsideAlpha = 0.4}
local connected, inRange, checked = true, false, true
UnitIsConnected = function() return connected end
UnitInRange = function() return inRange, checked end
assert(elements.Range.enable(frame))
assert(frame.alpha == 0.4)
inRange = true
frame.Range.ForceUpdate()
assert(frame.alpha == 1)
connected = false
frame.Range.ForceUpdate()
assert(frame.alpha == 1)
connected, checked = true, false
frame.Range.ForceUpdate()
assert(frame.alpha == 1)
HydraUI.IsMainline = true
local secret = {}
issecretvalue = function(value) return value == secret end
canaccessvalue = function(value) return value ~= secret end
inRange, checked = secret, true
function frame:SetAlphaFromBoolean(value, inside, outside)
	assert(value == secret and inside == 1 and outside == 0.4)
	self.alpha = outside
end
frame.Range.ForceUpdate()
assert(frame.alpha == 0.4)
frame.SetAlphaFromBoolean = nil
frame.Range.ForceUpdate()
assert(frame.alpha == 1)
elements.Range.disable(frame)
assert(frame.alpha == 1)

HydraUI.IsMainline = false
Load("ThreatIndicator")
frame.ThreatIndicator = Widget()
frame.colors = {threat = {[0] = {1, 1, 1}, [1] = {1, 1, 0}, [2] = {1, 1, 0}, [3] = {1, 0, 0}}}
local status
UnitThreatSituation = function() return status end
assert(elements.ThreatIndicator.enable(frame))
for _, value in ipairs({0, 1, 2, 3}) do
	status = value
	elements.ThreatIndicator.update(frame)
	assert(frame.ThreatIndicator.shown == (status > 0))
	if status > 0 then assert(frame.ThreatIndicator.color[2] == (status == 3 and 0 or 1)) end
end
status = nil
elements.ThreatIndicator.update(frame)
assert(not frame.ThreatIndicator.shown)
print("Dispel, range, and threat runtime checks passed")
