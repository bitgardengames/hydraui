-- Run from the repository root with Lua 5.1 or later.
local Tooltips, Settings = {}, {['ui-border-thickness'] = 1, ['tooltips-show-health-text'] = false}
local Unit, Exists = 'player', true
local function NewFrame()
	local frame = {scripts = {}}
	setmetatable(frame, {__index = function(_, key)
		return function() end
	end})
	function frame:CreateTexture() return NewFrame() end
	function frame:CreateFontString() return NewFrame() end
	function frame:GetFrameLevel() return 2 end
	function frame:HookScript(event, handler) self.scripts[event] = handler end
	function frame:SetVertexColor(...) self.color = {...} end
	return frame
end
GameTooltip = NewFrame()
function GameTooltip:GetUnit() return 'Unit', Unit end
GameTooltipStatusBar = NewFrame()
function GameTooltipStatusBar:GetParent() return GameTooltip end
local setterCalls = 0
function GameTooltipStatusBar:SetStatusBarColor(...)
	setterCalls = setterCalls + 1
	assert(setterCalls < 100, 'recursive color hook')
	self.color = {...}
end
function hooksecurefunc(object, name, callback)
	local original = object[name]
	object[name] = function(self, ...)
		original(self, ...)
		callback(self, ...)
	end
end
CreateFrame = NewFrame
UnitExists = function() return Exists end
UnitIsPlayer = function(unit) return unit == 'player' end
UnitClass = function() return 'Mage', 'MAGE' end
UnitReaction = function() return 2 end
local HydraUI = {ClassColors = {MAGE = {0.2, 0.4, 0.8}}, ReactionColors = {[2] = {0.9, 0.1, 0.2}}}
function HydraUI:NewModule() return Tooltips end
function HydraUI:GetModule() return {AddWidgets = function() end} end
function HydraUI:SetFontInfo() end
function HydraUI:AddBackdrop(frame) frame.Outside = NewFrame() end
function HydraUI:RGBToHex(r, g, b) return {r, g, b} end
function HydraUI:HexToRGB(color) return (table.unpack or unpack)(color) end
local ns = {get = function() return HydraUI, {}, {GetTexture = function() end}, Settings, {} end}
assert(loadfile('HydraUI/Elements/Tooltips.lua'))('HydraUI', ns)
Tooltips:StyleStatusBar()
local bar = GameTooltipStatusBar
local function Check(r, g, b)
	assert(bar.color[1] == r and bar.color[2] == g and bar.color[3] == b)
	assert(bar.BG.color[1] == r and bar.BG.color[2] == g and bar.BG.color[3] == b)
end
-- Blizzard resets color AFTER the value callback, including unchanged values.
bar.scripts.OnValueChanged(bar)
bar:SetStatusBarColor(0, 1, 0)
Check(0.2, 0.4, 0.8)
bar:SetStatusBarColor(0, 1, 0)
Check(0.2, 0.4, 0.8)
Unit = 'npc'
bar:SetStatusBarColor(0, 1, 0)
Check(0.9, 0.1, 0.2)
-- Incoming restricted values must not be compared or used in arithmetic.
local secret = setmetatable({}, {__eq = function() error('secret comparison') end,
	__add = function() error('secret arithmetic') end})
bar:SetStatusBarColor(secret, secret, secret)
Check(0.9, 0.1, 0.2)
Unit = nil
bar:SetStatusBarColor(0, 1, 0)
assert(bar.color[2] == 1)
Unit, Exists = 'npc', false
bar:SetStatusBarColor(0, 1, 0)
assert(bar.color[2] == 1)
print('Tooltip color runtime checks passed')
