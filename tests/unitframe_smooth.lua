-- Run from the repository root with texlua or Lua.
local elements, driver = {}, nil
local UF = {}
function UF:RegisterElement(name, handler) elements[name] = handler end
function UF:CreateForceUpdate() return function() end end
local ui = {IsMainline = false}
function ui:GetModule() return UF end
local ns = {get = function() return ui end}
CreateFrame = function()
	driver = {SetScript = function(self, _, fn) self.tick = fn end}
	return driver
end
GetFramerate = function() return 60 end
local health = 80
UnitHealth = function() return health end
UnitHealthMax = function() return 100 end
UnitIsConnected = function() return true end
for _, name in ipairs({"Smooth", "Health"}) do
	assert(loadfile("HydraUI/Elements/UnitFrames/Elements/" .. name .. ".lua"))(nil, ns)
end
local bar = {value = 0}
function bar:SetValue(value, interpolation)
	assert(interpolation == nil, "Snap flag must not reach the native status bar")
	self.value = value
end
function bar:GetValue() return self.value end
function bar:SetMinMaxValues(_, maximum) self.maximum = maximum end
function bar:GetMinMaxValues() return 0, self.maximum end
function bar:Show() end
local frame = {unit = "target", Health = bar, RegisterEvent = function() end}
assert(elements.Health.enable(frame))
assert(elements.Smooth.enable(frame))
local function Update(event) elements.Health.update(frame, event, frame.unit) end

-- Even a health event arriving before the target-change event initializes instantly.
Update("UNIT_HEALTH_FREQUENT")
assert(bar.value == 80 and driver.tick == nil)

for _, event in ipairs({"RefreshUnit", "OnShow", "OnAttributeChanged", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED"}) do
	-- Start an ordinary health animation, then acquire/show a unit at the same maximum.
	health = 40
	Update("UNIT_HEALTH_FREQUENT")
	assert(bar.value == 80 and driver.tick)
	driver.tick()
	assert(bar.value < 80 and bar.value > 40)
	health = 80
	Update(event)
	assert(bar.value == 80, event .. " must snap immediately")
	driver.tick()
	assert(bar.value == 80 and driver.tick == nil, "Old animation must be cancelled")
end

-- Ordinary changes still animate after acquisition.
health = 60
Update("UNIT_HEALTH_FREQUENT")
assert(bar.value == 80 and driver.tick)
driver.tick()
assert(bar.value < 80 and bar.value > 60)
for i = 1, 100 do
	if driver.tick then driver.tick() end
end
assert(bar.value == 60 and driver.tick == nil)

-- Disabled smoothing uses the native SetValue signature.
elements.Smooth.disable(frame)
health = 70
Update("PLAYER_TARGET_CHANGED")
assert(bar.value == 70)
print("Unitframe initial health, acquisition, and smoothing checks passed")
