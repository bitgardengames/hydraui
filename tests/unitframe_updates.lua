-- Run from the repository root with Lua 5.1; only settings and widgets are mocked.
local root = "HydraUI/Elements/UnitFrames/"
local UF, frames, settings, trace = {}, {}, {}, {}
local HydraUI = {UnitFrames = frames}
local function Record(name, ...)
	local values = {name}
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		values[#values + 1] = type(value) == "table" and value.name or tostring(value)
	end
	trace[#trace + 1] = table.concat(values, ":")
end
local function Widget(name)
	local widget = {name = name}
	for _, method in ipairs({"SetWidth", "SetHeight", "SetSize", "SetReverseFill", "ClearAllPoints", "SetPoint", "SetStatusBarTexture", "SetTexture", "ForceUpdate", "EnableElement", "DisableElement", "Refresh"}) do
		widget[method] = function(_, ...)
			Record(name .. "." .. method, ...)
		end
	end
	function widget:GetStatusBarTexture()
		return self.name .. ".texture"
	end
	return widget
end
local function Frame(heal, absorb)
	local frame = Widget("frame")
	frame.Health, frame.Power = Widget("health"), Widget("power")
	frame.Health.bg, frame.Power.bg = Widget("health.bg"), Widget("power.bg")
	frame.HealBar = heal and Widget("heal") or nil
	frame.AbsorbsBar = absorb and Widget("absorb") or nil
	frame.Buffs, frame.Debuffs = Widget("buffs"), Widget("debuffs")
	return frame
end
function HydraUI:GetModule()
	return UF
end
function UF:SetHealthAttributes(bar, value)
	Record("health.color", bar, value)
end
function UF:SetPowerAttributes(bar, value)
	Record("power.color", bar, value)
end
local Assets = {GetTexture = function(_, value)
	Record("texture", value)
	return "asset-" .. value
end}
local ns = {get = function()
	return HydraUI, {}, Assets, settings
end}
assert(loadfile(UPDATE_SOURCE or root .. "Elements/Updates.lua"))("HydraUI", ns)
assert(loadfile(GROUP_SOURCE or root .. "Frames/GroupFrames.lua"))("HydraUI", ns)
local allTraces = {}
local function Capture(callback)
	trace = {}
	callback()
	local result = table.concat(trace, "|")
	allTraces[#allTraces + 1] = result
	return result
end
local cases = {
	{"ApplyHealthAttributes", "HealthColor", "class"},
	{"ApplyPowerAttributes", "PowerColor", "power"},
	{"SetHealthReverseFill", "HealthReverse", true},
	{"SetHealthReverseFill", "HealthReverse", false},
	{"SetPowerReverseFill", "PowerReverse", true},
	{"SetPowerReverseFill", "PowerReverse", false},
	{"SetHealthTexture", "HealthTexture", "health"},
	{"SetPowerTexture", "PowerTexture", "power"},
}
for mask = 0, 3 do
	frames.player = Frame(mask % 2 == 1, mask >= 2)
	for _, case in ipairs(cases) do
		local public = Capture(function() UF[case[1]](UF, "player", case[3]) end)
		local callback = Capture(function() UF:CreateUnitUpdater("player", case[2])(case[3]) end)
		assert(public == callback, case[1])
	end
	local healthTexture = Capture(function() UF:SetHealthTexture("player", "health") end)
	assert(healthTexture:find("health.SetStatusBarTexture:asset-health", 1, true))
	assert(healthTexture:find("health.bg.SetTexture:asset-health", 1, true))
	assert(not frames.player.HealBar or healthTexture:find("heal.SetStatusBarTexture:asset-health", 1, true))
	assert(not frames.player.AbsorbsBar or healthTexture:find("absorb.SetStatusBarTexture:asset-health", 1, true))
	frames.party = {frames.player}
	function UF:ForEachHeaderChild(header, operation, value, descriptor)
		for _, frame in ipairs(header) do
			operation(frame, value, descriptor)
		end
	end
	assert(healthTexture == Capture(function() UF:UpdateGroupFrames({header = "party"}, "healthTexture", "health") end))
	local powerTexture = Capture(function() UF:SetPowerTexture("player", "power") end)
	assert(powerTexture == Capture(function() UF:UpdateGroupFrames({header = "party"}, "powerTexture", "power") end))
end
-- Group callbacks receive frame objects, whereas public setters receive keys.
-- Every live party/raid control must reach the same widgets as singleton updates.
for _, prefix in ipairs({"party", "raid"}) do
	local descriptor = {header = prefix, prefix = prefix}
	frames[prefix] = {frames.player}
	settings[prefix .. "-power-height"] = 7
	settings[prefix .. "-health-height"] = 20
	for _, case in ipairs({
		{"width", "SetFrameWidth", 140},
		{"healthHeight", "SetHealthHeight", 24, 7},
		{"powerHeight", "SetPowerHeight", 9, 20},
		{"healthColor", "ApplyHealthAttributes", "class"},
		{"powerColor", "ApplyPowerAttributes", "power"},
		{"healthReverse", "SetHealthReverseFill", true},
		{"powerReverse", "SetPowerReverseFill", true},
	}) do
		local expected = Capture(function() UF[case[2]](UF, "player", case[3], case[4]) end)
		assert(expected ~= "")
		assert(expected == Capture(function() UF:UpdateGroupFrames(descriptor, case[1], case[3]) end), prefix .. case[1])
	end
	assert(Capture(function() UF:UpdateGroupFrames(descriptor, "powerEnabled", false) end) == "frame.DisableElement:Power|frame.SetHeight:22")
	assert(Capture(function() UF:UpdateGroupFrames(descriptor, "powerEnabled", true) end) == "frame.EnableElement:Power|frame.SetHeight:30")
	assert(Capture(function() UF:UpdateGroupFrames(descriptor, "debuffs", false) end) == "frame.DisableElement:Auras")
	assert(Capture(function() UF:UpdateGroupFrames(descriptor, "debuffs", true) end) == "frame.EnableElement:Auras")
end
for _, position in ipairs({"TOP", "BOTTOM"}) do
	for _, companionPosition in ipairs({"TOP", "BOTTOM"}) do
		settings.companionPosition = companionPosition
		local public = Capture(function() UF:SetAuraPosition("player", position, "Buffs", "LEFT", "Debuffs", companionPosition) end)
		local callback = Capture(function()
			UF:CreateUnitUpdater("player", "AuraPosition", {element = "Buffs", growthX = "LEFT", companion = "Debuffs", companionPosition = "companionPosition"})(position)
		end)
		assert(public == callback)
		assert(frames.player.Buffs["growth-y"] == (position == "TOP" and "UP" or "DOWN"))
		assert(frames.player.Buffs["growth-x"] == "LEFT")
		local relative = position == companionPosition and "debuffs" or "frame"
		assert(public:find(":" .. relative .. ":", 1, true))
	end
end
-- Callbacks must resolve current frames and settings at invocation, including
-- sparse boss slots and frames created after the settings panel was built.
local update = UF:CreateUnitUpdater("boss", "HealthTexture", {count = 3})
frames.boss1, frames.boss3 = Frame(false, false), Frame(true, true)
local bossTrace = Capture(function() update("boss") end)
assert(bossTrace == Capture(function()
	UF:SetHealthTexture("boss1", "boss")
	UF:SetHealthTexture("boss3", "boss")
end))
frames.boss1, frames.boss3 = nil, nil
assert(Capture(function() update("boss") end) == "")
for _, case in ipairs(cases) do
	assert(Capture(function() UF[case[1]](UF, "missing", case[3]) end) == "")
end
frames.player.Buffs = nil
assert(Capture(function() UF:SetAuraPosition("player", "TOP", "Buffs", "RIGHT") end) == "")
assert(Capture(function() UF:CreateUnitUpdater("player", "AuraPosition", {element = "Buffs"})("TOP") end) == "")
return table.concat(allTraces, "\n")
