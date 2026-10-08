local source = assert(io.open("HydraUI/Elements/ActionBars/Buttons.lua")):read("*a")
local helper = source:sub(1, assert(source:find("function AB:StyleActionButton", 1, true)) - 1)
local HydraUI = {IsMainline = true, GetModule = function() return {} end}
local addon = {get = function() return HydraUI end}
KEY_NUMPAD1, KEY_MOUSEWHEELUP, KEY_MOUSEWHEELDOWN = "Num 1", "Up", "Down"
KEY_BUTTON4, KEY_BUTTON3 = "Button 4", "Middle"
local hooks = setmetatable({}, {__mode = "k"})
function hooksecurefunc(object, method, callback)
	hooks[object] = hooks[object] or {}
	hooks[object][method] = hooks[object][method] or {}
	table.insert(hooks[object][method], callback)
end
local function call(object, method, ...)
	object[method](object, ...)
	for _, callback in ipairs(hooks[object] and hooks[object][method] or {}) do
		callback(object, ...)
	end
end
local suppress = assert(load(helper .. "\nreturn SuppressButtonRotations"))("HydraUI", addon)
local function animation()
	return {playing = true, Play = function(self) self.playing = true end,
		Stop = function(self) self.playing = false end}
end
local reticle = animation()
local glow = animation()
local frame = {ActiveFrame = {GlowAnim = glow}, shown = true, updates = 0}
local button = {TargetReticleAnimFrame = {HighlightAnim = reticle}}
local function cooldown()
	return {edge = true, swipe = true, countdown = true, duration = 1.5,
		SetDrawEdge = function(self, value) self.edge = value end}
end
button.cooldown, button.chargeCooldown, button.lossOfControlCooldown = cooldown(), cooldown(), cooldown()
function button:UpdateAssistedCombatRotationFrame()
	self.AssistedCombatRotationFrame = frame
	frame.updates = frame.updates + 1
	call(glow, "Play")
end
local originalUpdate, originalPlay = button.UpdateAssistedCombatRotationFrame, reticle.Play
suppress(button)
for _, key in ipairs({"cooldown", "chargeCooldown", "lossOfControlCooldown"}) do
	local cd = button[key]
	assert(not cd.edge, key .. " still has a rotating edge")
	assert(cd.swipe and cd.countdown and cd.duration == 1.5, "cooldown state changed")
end
assert(not reticle.playing)
call(reticle, "Play")
assert(not reticle.playing, "targeting restarted the rotation")
assert(button.UpdateAssistedCombatRotationFrame == originalUpdate and reticle.Play == originalPlay)
call(button, "UpdateAssistedCombatRotationFrame")
assert(not glow.playing, "lazy creation left the glow spinning")
call(button, "UpdateAssistedCombatRotationFrame")
assert(not glow.playing and frame.updates == 2 and frame.shown)
assert(#hooks[glow].Play == 1, "repeated updates duplicated the hook")
call(glow, "Play")
assert(not glow.playing, "combat transition restarted the glow")
local existing = animation()
suppress({AssistedCombatRotationFrame = {ActiveFrame = {GlowAnim = existing}}})
assert(not existing.playing, "already-created frame was missed")
suppress({}) -- Older templates need neither field nor method.
HydraUI.IsMainline = false
local classic = animation()
local classicCooldown = cooldown()
suppress({TargetReticleAnimFrame = {HighlightAnim = classic}, cooldown = classicCooldown})
assert(classicCooldown.edge, "classic cooldown edge was modified")
assert(classic.playing and not hooks[classic], "classic was modified")
print("Action button rotation checks passed")
