local combat = false
function InCombatLockdown() return combat end
local function frame(name)
	local f = {name = name, shown = true, hooks = {}, removedMasks = {}, normal = false, CircleMask = false, searchOverlay = false, ItemContextOverlay = false, IconBorder = false, SlotArt = false, SlotBackground = false, SlotHighlightTexture = false}
	setmetatable(f, {__index = function(self, key)
		return function() end
	end})
	function f:GetName() return self.name end
	function f:SetParent(parent) self.parent = parent end
	function f:SetPoint(...) self.point = {...} end
	function f:ClearAllPoints() self.point = nil; self.allPoints = nil end
	function f:SetAllPoints(target) self.allPoints = target end
	function f:SetTexCoord(...) self.texCoords = {...} end
	function f:SetRotation(rotation) self.rotation = rotation end
	function f:SetSize(w, h) self.width, self.height = w, h end
	function f:SetAlpha(a) self.alpha = a end
	function f:HookScript(event, callback) self.hooks[event] = callback end
	function f:IsShown() return self.shown end
	function f:Show()
		local changed = not self.shown
		self.shown = true
		if changed and self.hooks.OnShow then self.hooks.OnShow(self) end
	end
	function f:Hide()
		local changed = self.shown
		self.shown = false
		if changed and self.hooks.OnHide then self.hooks.OnHide(self) end
	end
	function f:SetScript(event, callback) self[event] = callback end
	function f:RegisterEvent(event) self.event = event end
	function f:UnregisterEvent() self.event = nil end
	function f:GetNormalTexture() return self.normal end
	function f:SetTexture(texture) self.texture = texture end
	function f:SetColorTexture(...) self.color = {...}; self.texture = 'color' end
	function f:RemoveMaskTexture(mask) self.removedMasks = self.removedMasks or {}; self.removedMasks[mask] = true end
	function f:GetPushedTexture() return self.pushed end
	function f:GetHighlightTexture() return self.highlight end
	function f:SetPushedTexture(texture) self.pushed = texture end
	function f:SetHighlightTexture(texture) self.highlight = texture end
	function f:UpdateTextures()
		self.normal:SetTexture('circular border')
		self.pushed:SetTexture('circular border')
		self.highlight:SetTexture('circular highlight')
		self.SlotHighlightTexture:SetTexture('circular highlight')
	end
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
	_G[name].CircleMask = frame('circle mask')
	_G[name].searchOverlay = frame('search')
	_G[name].ItemContextOverlay = frame('context')
	_G[name].SlotHighlightTexture = frame('slot highlight')
	_G[name].normal = frame('normal')
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
assert(loadfile('HydraUI/Elements/ActionBars/BagSlots.lua'))('HydraUI', {get = function() return ui, language, {GetTexture = function() return 'blank' end}, settings, {} end})
module:Load()
assert(#module.Objects == 6)
for _, button in ipairs(module.Objects) do
	assert(button.parent == module.Panel)
	assert(button.width == 32 and button.height == 32)
	assert(button.IconMask.shown == false)
	if button ~= MainMenuBarBackpackButton then
		assert(button.Icon.removedMasks[button.CircleMask])
	end
	assert(button.searchOverlay.removedMasks[button.CircleMask])
	assert(button.ItemContextOverlay.removedMasks[button.CircleMask])
	button:UpdateTextures()
	assert(rawget(button.normal, 'texture') == nil)
	assert(button.pushed.texture == 'color')
	assert(button.highlight.texture == 'color')
	assert(button.SlotHighlightTexture.texture == 'color')
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
assert(module.Panel.width == 220 and module.Panel.height == 40)
for _, button in ipairs({CharacterBag0Slot, CharacterBag1Slot, CharacterBag2Slot, CharacterBag3Slot}) do
	button:Hide()
end
assert(module.Panel.width == 76 and module.Panel.height == 40)
assert(CharacterReagentBag0Slot.point[2] == MainMenuBarBackpackButton)
-- Changing icon size while collapsed must use the visible count.
settings['bags-frame-size'] = 40
module:PositionButtons()
assert(module.Panel.width == 92 and module.Panel.height == 48)
combat = true
CharacterBag0Slot:Show()
assert(module.Panel.width == 92)
assert(module.event == 'PLAYER_REGEN_ENABLED')
combat = false
module:OnEvent('PLAYER_REGEN_ENABLED')
assert(module.Panel.width == 136)
for _, button in ipairs({CharacterBag1Slot, CharacterBag2Slot, CharacterBag3Slot}) do
	button:Show()
end
assert(module.Panel.width == 268 and module.Panel.height == 48)
-- Hiding the whole panel must not change the expanded slot count.
settings['bags-frame-visibility'] = 'HIDE'
module:UpdateVisibility()
module:PositionButtons()
assert(module.Panel.width == 268)

-- Classic keyring art uses button-state textures, not an item icon.
for _, client in ipairs({'IsVanilla', 'IsTBC'}) do
	ui.IsMainline = false
	ui.IsVanilla = client == 'IsVanilla'
	ui.IsTBC = client == 'IsTBC'
	module = frame('classic module')
	module.IsPositioning = false
	module.Panel = false
	for _, name in ipairs({'KeyRingButton', 'CharacterBag3Slot', 'CharacterBag2Slot', 'CharacterBag1Slot', 'CharacterBag0Slot', 'MainMenuBarBackpackButton'}) do
		local button = frame(name)
		_G[name] = button
		button.Icon = false
		button.icon = false
		button.IconMask = false
		button.normal = frame('normal')
		button.normal:SetTexture('normal artwork')
		button.pushed = frame('pushed')
		button.pushed:SetTexture('pressed artwork')
		button.normal:SetPoint('CENTER')
		button.pushed:SetPoint('CENTER')
	end
	function KeyRingButton:UpdateOrientation()
		self:SetSize(39, 18)
		self.normal:SetRotation(math.pi / 2)
		self.pushed:SetRotation(math.pi / 2)
	end
	settings['bags-frame-size'] = 32
	settings['bags-frame-visibility'] = 'SHOW'
	assert(loadfile('HydraUI/Elements/ActionBars/BagSlots.lua'))('HydraUI', {get = function() return ui, language, {}, settings, {} end})
	module:Load()
	local function checkKeyRing(size)
		assert(KeyRingButton.width == size / 2 and KeyRingButton.height == size)
		assert(KeyRingButton.normal.texture == 'normal artwork')
		assert(KeyRingButton.pushed.texture == 'pressed artwork')
		for _, texture in ipairs({KeyRingButton.normal, KeyRingButton.pushed}) do
			assert(texture.allPoints == KeyRingButton and rawget(texture, 'point') == nil)
			assert(texture.rotation == 0)
			local uv = texture.texCoords
			assert(uv[1] == 0.05625 and uv[2] == 0.50625 and uv[3] == 0.0609375 and uv[4] == 0.5484375)
		end
	end
	checkKeyRing(32)
	settings['bags-frame-size'] = 48
	module:PositionButtons()
	checkKeyRing(48)
	KeyRingButton:UpdateOrientation()
	checkKeyRing(48)
end
print('Bag slots runtime checks passed')
