local combat = false
function InCombatLockdown() return combat end
local function frame(name)
	local f = {name = name, shown = true, hooks = {}, normal = false, IconBorder = false, SlotArt = false, SlotBackground = false, SlotHighlightTexture = false}
	setmetatable(f, {__index = function(self, key)
		return function() end
	end})
	function f:GetName() return self.name end
	function f:SetParent(parent) self.parent = parent end
	function f:SetPoint(...) self.point = {...} end
	function f:SetSize(w, h) self.width, self.height = w, h end
	function f:SetAlpha(a) self.alpha = a end
	function f:Show() self.shown = true end
	function f:Hide() self.shown = false end
	function f:SetScript(event, callback) self[event] = callback end
	function f:RegisterEvent(event) self.event = event end
	function f:UnregisterEvent() self.event = nil end
	function f:GetNormalTexture() return self.normal end
	function f:SetTexture(texture) self.texture = texture end
	function f:CreateTexture() return frame('texture') end
	return f
end
function hooksecurefunc(object, method, callback)
	local original = object[method]
	object[method] = function(self, ...)
		original(self, ...)
		callback(self, ...)
	end
end
function CreateFrame(_, name) return frame(name) end
for _, name in ipairs({'CharacterReagentBag0Slot', 'CharacterBag3Slot', 'CharacterBag2Slot', 'CharacterBag1Slot', 'CharacterBag0Slot', 'MainMenuBarBackpackButton'}) do
	_G[name] = frame(name)
	_G[name].Icon = frame('icon')
	_G[name].IconMask = frame('mask')
end
-- Unlike equipped bags, the backpack can expose only button-state artwork.
MainMenuBarBackpackButton.Icon = false
MainMenuBarBackpackButton.icon = false
MainMenuBarBackpackButton.normal = frame('backpack normal')
MainMenuBarBackpackButton.normal:SetTexture('blizzard backpack artwork')
local module = frame('module')
module.IsPositioning = false
module.Panel = false
local settings = {['ab-enable'] = true, ['bags-frame-size'] = 32, ['bags-frame-visibility'] = 'SHOW', ['bags-frame-max'] = 100, ['bags-frame-opacity'] = 40}
local ui = {IsMainline = true, UIParent = frame('root'), BackdropAndBorder = {}}
function ui:NewModule() return module end
function ui:GetModule() return {Panel = frame('micro'), AddWidgets = function() end} end
function ui:CreateMover() end
function ui:HexToRGB() return 0, 0, 0 end
local language = setmetatable({}, {__index = function(_, key) return key end})
C_Container = {SetInsertItemsLeftToRight = function() end}
assert(loadfile('HydraUI/Elements/ActionBars/BagSlots.lua'))('HydraUI', {get = function() return ui, language, {}, settings, {} end})
module:Load()
assert(#module.Objects == 6)
for _, button in ipairs(module.Objects) do
	assert(button.parent == module.Panel)
	assert(button.width == 32 and button.height == 32)
	assert(button.IconMask.shown == false)
end
assert(rawget(MainMenuBarBackpackButton.normal, 'texture') == nil)
assert(MainMenuBarBackpackButton.BackpackIcon.texture == "Interface\\Icons\\INV_Misc_Bag_08")
assert(MainMenuBarBackpackButton.BackpackIcon.shown)
-- Blizzard may replace button-state textures without affecting our icon.
MainMenuBarBackpackButton.normal:SetTexture('updated blizzard artwork')
assert(MainMenuBarBackpackButton.BackpackIcon.texture == "Interface\\Icons\\INV_Misc_Bag_08")
local blizzard = frame('blizzard')
MainMenuBarBackpackButton:SetParent(blizzard)
assert(MainMenuBarBackpackButton.parent == module.Panel)
CharacterBag0Slot:SetSize(48, 24)
assert(CharacterBag0Slot.width == 32 and CharacterBag0Slot.height == 32)
combat = true
CharacterBag0Slot:SetParent(blizzard)
assert(CharacterBag0Slot.parent == blizzard)
assert(module.event == 'PLAYER_REGEN_ENABLED')
combat = false
module:OnEvent('PLAYER_REGEN_ENABLED')
assert(CharacterBag0Slot.parent == module.Panel)
settings['bags-frame-visibility'] = 'HIDE'
module:UpdateVisibility()
assert(module.Panel.shown == false)
settings['bags-frame-visibility'] = 'MOUSEOVER'
module:UpdateVisibility()
assert(module.Panel.shown and module.Panel.alpha == 0.4)
settings['bags-frame-visibility'] = 'SHOW'
module:UpdateVisibility()
assert(module.Panel.shown and module.Panel.alpha == 1)
print('Bag slots runtime checks passed')
