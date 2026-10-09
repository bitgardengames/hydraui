-- Exercise global HealComm callbacks across nameplate removal and reuse.
strmatch = string.match
loadstring = loadstring or load
unpack = unpack or table.unpack
local libraries = "HydraUI/Elements/Libraries/"
assert(loadfile(libraries .. "LibStub.lua"))()
geterrorhandler = function() return function(message) error(message) end end
assert(loadfile(libraries .. "CallbackHandler-1.0.lua"))()
local HealComm = LibStub:NewLibrary("LibHealComm-4.0", 1)
HealComm.ALL_HEALS = 1
local callbacks = LibStub("CallbackHandler-1.0"):New(HealComm)
function HealComm:GetHealAmount() return 25 end
function HealComm:GetHealModifier() return 1 end

local element
local UF = {}
function UF:RegisterElement(_, handlers) element = handlers end
function UF:CreateForceUpdate(bar, update)
	return function() update(bar.__owner, "ForceUpdate") end
end
local HydraUI = {IsVanilla = true}
function HydraUI:GetModule() return UF end
assert(loadfile("HydraUI/Elements/UnitFrames/Elements/HealthPrediction.lua"))(nil, {
	get = function() return HydraUI end,
})

local guidCalls, healthCalls = 0, 0
UnitGUID = function(unit)
	assert(type(unit) == "string", "UnitGUID requires a unit token")
	guidCalls = guidCalls + 1
	if unit ~= "missing" then return "guid-" .. unit end
end
UnitHealth = function(unit)
	assert(unit, "UnitHealth requires a unit token")
	healthCalls = healthCalls + 1
	return 50
end
UnitHealthMax = function(unit) assert(unit) return 100 end
local bar = {}
function bar:SetMinMaxValues() end
function bar:SetValue(value) self.value = value end
function bar:Show() end
function bar:Hide() end
local frame = {unit = "nameplate1", HealBar = bar}
function frame:RegisterEvent() end
function frame:UnregisterEvent() end
assert(element.enable(frame))

local function FireHeals(guid)
	for _, event in ipairs({"HealComm_HealStarted", "HealComm_HealUpdated", "HealComm_HealDelayed", "HealComm_HealStopped"}) do
		callbacks:Fire(event, "caster", 123, 1, 10, "other-guid", guid)
	end
	callbacks:Fire("HealComm_ModifierChanged", guid)
	callbacks:Fire("HealComm_GUIDDisappeared", guid)
end
FireHeals("guid-nameplate1")
assert(healthCalls == 6 and bar.value == 25)
FireHeals("unrelated-guid")
assert(healthCalls == 6)

frame.unit = nil
local before = guidCalls
FireHeals("guid-nameplate1")
element.update(frame, "PLAYER_TARGET_CHANGED")
bar.ForceUpdate()
assert(guidCalls == before and healthCalls == 6)

frame.unit = "missing"
FireHeals(nil)
assert(healthCalls == 6)
frame.unit = "nameplate2"
FireHeals("guid-nameplate2")
assert(healthCalls == 12 and bar.value == 25)
element.disable(frame)
before = guidCalls
FireHeals("guid-nameplate2")
assert(guidCalls == before)
print("Health prediction lifecycle checks passed")
