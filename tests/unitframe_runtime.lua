-- Run from the repository root with Lua 5.1. No WoW client or libraries needed.
local root = "HydraUI/Elements/UnitFrames/"
local UF, HydraUI = {}, {UIParent = {}, IsMainline = false}
local Language = setmetatable({}, {__index = function(_, key)
	return key
end})
local ns = {get = function()
	return HydraUI, Language
end}
function HydraUI:NewModule()
	return UF
end
function HydraUI:GetModule()
	return UF
end
function HydraUI:GetUnitFrameColors()
	return {}
end
function HydraUI:ShortValue(value)
	return tostring(value)
end
function HydraUI:Comma(value)
	return tostring(value)
end
function HydraUI:RGBToHex()
	return "00FF00"
end

local function NewFrame()
	local frame = {scripts = {}, attributes = {}, registrations = {}, visible = true}
	function frame:RegisterEvent(event)
		self.registrations[#self.registrations + 1] = {event, "global"}
	end
	function frame:RegisterUnitEvent(event, ...)
		self.registrations[#self.registrations + 1] = {event, "unit", ...}
	end
	function frame:UnregisterEvent(event)
		self.registrations[#self.registrations + 1] = {event, "removed"}
	end
	function frame:SetScript(script, handler)
		self.scripts[script] = handler
	end
	function frame:HookScript(script, handler)
		self.scripts[script] = handler
	end
	function frame:SetAttribute(name, value)
		self.attributes[name] = value
	end
	function frame:IsShown()
		return self.visible
	end
	frame.IsVisible = frame.IsShown
	function frame:Hide()
		self.visible = false
		if self.scripts.OnHide then
			self.scripts.OnHide(self)
		end
	end
	function frame:Show()
		self.visible = true
		if self.scripts.OnShow then
			self.scripts.OnShow(self)
		end
	end
	function frame:EnableMouse() end
	return frame
end
CreateFrame = NewFrame
InCombatLockdown = function() return false end
UnitExists = function(unit) return unit ~= nil end
SecureButton_GetUnit = function(frame) return frame.attributes.unit end
SecureButton_GetModifiedUnit = function(frame) return frame.modifiedUnit or frame.attributes.unit end
RegisterUnitWatch = function(frame) frame.watched = true end
UnregisterUnitWatch = function(frame) frame.watched = false end
UnitWatchRegistered = function(frame) return frame.watched end
local tickerCount = 0
C_Timer = {NewTicker = function(interval, callback)
	assert(interval == 0.5)
	tickerCount = tickerCount + 1
	return {callback = callback, Cancel = function(self)
		self.cancelled = true
	end}
end}
local function Load(name)
	assert(loadfile(root .. name))("HydraUI", ns)
end
Load("Core.lua")
UF.Tag, UF.Untag, UF.UpdateTags = function() end, function() end, function() end

-- Shared events register once, promote to global, and remain until the last
-- subscriber leaves. Hidden frames suppress dispatch without losing handlers.
local frame = HydraUI.UnitFrames:CreateUnitButton("pet", nil, function() end)
frame.registrations = {}
local calls = 0
local function first() calls = calls + 1 end
local function second() calls = calls + 10 end
frame:RegisterEvent("UNIT_HEALTH", first)
frame:RegisterEvent("UNIT_HEALTH", first)
frame:RegisterEvent("UNIT_HEALTH", second)
assert(#frame.registrations == 1)
assert(frame.registrations[1][3] == "pet" and frame.registrations[1][4] == nil)
frame.scripts.OnEvent(frame, "UNIT_HEALTH", "pet")
assert(calls == 11)
frame:Hide()
frame.scripts.OnEvent(frame, "UNIT_HEALTH", "pet")
assert(calls == 11)
frame:RegisterEvent("UNIT_HEALTH", function() end, true)
assert(#frame.registrations == 2 and not frame._unitEvents.UNIT_HEALTH)
frame:UnregisterEvent("UNIT_HEALTH", first)
assert(#frame.registrations == 2)
frame:UnregisterEvent("UNIT_HEALTH")
assert(#frame.registrations == 3 and not frame._events.UNIT_HEALTH)

-- Secure vehicle changes rebind unit events, including pet owner events, while
-- globally promoted events stay global.
frame:RegisterEvent("UNIT_HEALTH", first)
frame:RegisterEvent("UNIT_FACTION", second, true)
frame:Show()
frame.registrations = {}
frame.modifiedUnit = "vehicle"
frame.scripts.OnAttributeChanged(frame, "unit", "pet")
assert(frame.unit == "vehicle" and frame.realUnit == "pet")
for _, registration in ipairs(frame.registrations) do
	assert(registration[1] ~= "UNIT_FACTION")
	assert(registration[3] == "vehicle" and registration[4] == nil)
end
frame.modifiedUnit = nil
frame.registrations = {}
frame.scripts.OnAttributeChanged(frame, "unit", "pet")
local foundPet = false
for _, registration in ipairs(frame.registrations) do
	if registration[1] == "UNIT_PET" then
		assert(registration[3] == "pet" and registration[4] == "player")
		foundPet = true
	end
end
assert(foundPet)

-- Element order and lifecycle remain stable, including the public refresh alias.
local updates = {}
UF:RegisterElement("Test", {
	update = function(_, event, unit)
		updates[#updates + 1] = {event, unit}
	end,
	enable = function() return true end,
	disable = function() end,
})
local polling = HydraUI.UnitFrames:CreateUnitButton("boss6", nil, function() end)
assert(polling.Refresh == polling.UpdateAllElements)
assert(tickerCount == 1 and #updates == 1)
local ticker = polling._pollTicker
polling.scripts.OnShow(polling)
assert(tickerCount == 1)
ticker.callback()
assert(updates[#updates][1] == "PollEventless")
polling:Hide()
assert(ticker.cancelled and not polling._pollTicker)
polling:Show()
assert(tickerCount == 2)
polling:DisableElement("Test")
local count = #updates
polling:Refresh("Test")
assert(#updates == count)
polling:EnableElement("Test")
polling:Disable()
assert(not polling._pollTicker and not polling.watched)

-- Nameplate reuse retains event subscriptions and refreshes the new unit.
local plate = HydraUI.UnitFrames:CreateNamePlateButton({}, "nameplate1", function() end)
plate:RegisterEvent("UNIT_HEALTH", first)
plate.registrations = {}
HydraUI.UnitFrames:SetNamePlateUnit(plate, nil)
assert(not plate.unit and not plate:IsShown())
HydraUI.UnitFrames:SetNamePlateUnit(plate, "nameplate2")
assert(plate.registrations[2][3] == "nameplate2")
assert(updates[#updates][2] == "nameplate2")

-- Header adoption is idempotent and uses the same lifecycle.
local child, builds = NewFrame(), 0
HydraUI.UnitFrames:InitializeHeaderChild(child, "party", function() builds = builds + 1 end)
HydraUI.UnitFrames:InitializeHeaderChild(child, "party", function() builds = builds + 1 end)
assert(builds == 1)

-- All supported clients keep the same status precedence and legacy tag names.
local state = {}
DEAD, PLAYER_OFFLINE, CHAT_MSG_AFK, DEFAULT_AFK_MESSAGE = "Dead", "Offline", "AFK", "Away"
UnitIsDead = function() return state.dead end
UnitIsGhost = function() return state.ghost end
UnitIsConnected = function() return not state.offline end
UnitIsAFK = function() return state.afk end
UnitHealth = function() return state.health or 50 end
UnitHealthMax = function() return 100 end
UnitName = function(unit)
	return unit == "vehicle" and "VehicleName" or state.name
end
issecretvalue = function(value) return value == state.secret and value ~= nil end
canaccessvalue = function() return false end
for _, mainline in ipairs({false, true}) do
	HydraUI.IsMainline = mainline
	Load("Tags.lua")
	local methods = UF.TagMethods
	for _, test in ipairs({
		{{dead = true, ghost = true, offline = true, afk = true}, "|cFFEE4D4DDead|r"},
		{{ghost = true, offline = true, afk = true}, "|cFFEEEEEEGhost|r"},
		{{offline = true, afk = true}, "|cFFEEEEEEOffline|r"},
		{{afk = true}, mainline and "|cFFEEEEEEAway|r" or "|cFFEEEEEEAFK|r"},
	}) do
		state = test[1]
		for _, name in ipairs({"Status", "HealthDeficit", "HealthDeficit:Short", "GroupStatus"}) do
			assert(methods[name]("player") == test[2], name)
		end
	end
	state = {name = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"}
	assert(methods.Status("player") == "")
	assert(methods.HealthDeficit("player") == "-50")
	assert(methods["HealthDeficit:Short"]("player") == "-50")
	assert(methods.GroupStatus("player") == "|cFF00FF0050|r")
	for _, limit in ipairs({4, 5, 8, 10, 14, 15, 20, 30}) do
		local name = "Name" .. limit
		assert(methods[name]("player", "vehicle") == string.sub(state.name, 1, limit))
		assert(UF.TagEvents[name] == "UNIT_NAME_UPDATE UNIT_PET")
	end
	assert(methods.Name("player", "vehicle", "4") == "Vehi")
	state.name = "éééééééééééééééééééééééééééééééé"
	assert(methods.Name4("player") == "éééé")
	state.name = nil
	assert(methods.Name4("player") == nil)
	if mainline then
		state = {health = 75, secret = 75}
		assert(methods.HealthDeficit("player") == "")
		assert(methods["HealthDeficit:Short"]("player") == "")
		assert(methods.GroupStatus("player") == "")
	end

	-- Prefixes, suffixes, literal %, nil, false, zero, dynamic overrides and
	-- unit filtering preserve the original formatter's behavior.
	local tagFrame = NewFrame()
	tagFrame.unit = "player"
	tagFrame.handlers = {}
	function tagFrame:RegisterEvent(event, handler)
		self.handlers[event] = handler
	end
	local font = {SetText = function(self, text) self.text = text end,
		SetFormattedText = function(self, text, ...)
			local values = {...}
			self.values = values
			if values[1] == state.secret and state.secret then
				self.text = text
				return
			end
			for i = 1, #values do
				values[i] = tostring(values[i])
			end
			self.text = string.format(text, unpack(values))
		end}
	local value = "x"
	UF.TagMethods.Test = function() return value end
	UF.TagEvents.Test = "UNIT_NAME_UPDATE"
	UF.Tag(tagFrame, font, "100% [pre%$>Test<$%post] [Missing]")
	assert(font.text == "100% pre%x%post ")
	value = ""
	tagFrame.handlers.UNIT_NAME_UPDATE(tagFrame, "UNIT_NAME_UPDATE", "target")
	assert(font.text == "100% pre%x%post ")
	tagFrame.handlers.UNIT_NAME_UPDATE(tagFrame, "UNIT_NAME_UPDATE", "player")
	assert(font.text == "100%%  ") -- SetText receives the escaped literal too.
	value = 0
	UF.UpdateTags(tagFrame)
	assert(font.text == "100% pre%0%post ")
	value = false
	UF.UpdateTags(tagFrame)
	assert(font.text == "100% pre%false%post ")
	UF.TagMethods.Test = function() return "replacement" end
	UF.UpdateTags(tagFrame)
	assert(font.text == "100% pre%replacement%post ")
	if mainline then
		local secret = setmetatable({}, {__tostring = function()
			error("Secret tag values must not be coerced")
		end})
		state.secret = secret
		UF.TagMethods.Test = function() return secret end
		UF.UpdateTags(tagFrame)
		assert(font.values[1] == secret)
	end
	UF.Untag(tagFrame, font)
	assert(#tagFrame.__tags == 0 and not font.__tagBinding)
	state = {name = "PlayerName"}
	font.overrideUnit = true
	tagFrame.realUnit = "vehicle"
	UF.Tag(tagFrame, font, "[Name(4)]")
	assert(font.text == "Vehi")
	font.overrideUnit = false
	UF.UpdateTags(tagFrame)
	assert(font.text == "Play")
end
print("Unit frame runtime checks passed")

-- Singleton spawning keeps geometry and options for every enable combination,
-- including detached player power and pet/targettarget fallback anchors.
local settings = {}
ns.get = function() return HydraUI, Language, {}, settings end
HydraUI.StyleFuncs = {}
HydraUI.CreateMover = function(_, frame) frame.hasMover = true end
Load("Spawning.lua")
UF.DisableBlizzardUnitFrame = function() end
local units = {"player", "target", "targettarget", "pet", "focus"}
local enables = {"player-enable", "target-enable", "tot-enable", "pet-enable", "focus-enable"}
function HydraUI.UnitFrames:CreateUnitButton(unit, name)
	local result = NewFrame()
	result.unit, result.name, result.enabled = unit, name, {}
	function result:SetSize(width, height) self.width, self.height = width, height end
	function result:SetPoint(...) self.anchor = {...} end
	function result:SetParent(parent) self.parent = parent end
	function result:EnableElement(name) self.enabled[name] = true end
	function result:DisableElement(name) self.enabled[name] = false end
	function result:Refresh(event) self.refreshed = event end
	result.UpdateAllElements = result.Refresh
	result.Buffs, result.Debuffs, result.PvPIndicator, result.CastAnchor = NewFrame(), NewFrame(), NewFrame(), NewFrame()
	result.CastAnchor.SetPoint = result.SetPoint
	return result
end
for mask = 0, 127 do
	for i, unit in ipairs(units) do
		HydraUI.UnitFrames[unit] = nil
		settings[enables[i]] = math.floor(mask / 2 ^ (i - 1)) % 2 == 1
		settings["unitframes-" .. unit .. "-width"] = 100 + i
		settings["unitframes-" .. unit .. "-health-height"] = 20 + i
		settings["unitframes-" .. unit .. "-power-height"] = 5 + i
	end
	settings["unitframes-player-enable-power"] = math.floor(mask / 32) % 2 == 1
	settings["player-move-power"] = math.floor(mask / 64) % 2 == 1
	local option = mask % 2 == 1
	for _, key in ipairs({"player-enable-portrait", "target-enable-portrait", "player-enable-pvp",
		"unitframes-show-player-buffs", "unitframes-show-player-debuffs", "unitframes-show-target-buffs",
		"unitframes-show-target-debuffs", "unitframes-player-enable-castbar", "unitframes-target-enable-castbar",
		"focus-enable-buffs"}) do
		settings[key] = option
	end
	UF:SpawnSingletonFrames()
	for i, unit in ipairs(units) do
		local result = HydraUI.UnitFrames[unit]
		assert((result ~= nil) == settings[enables[i]])
		if result then
			assert(result.width == 100 + i and result.parent == HydraUI.UIParent and result.hasMover)
			local height = 28 + 2 * i
			if unit == "player" and (not settings["unitframes-player-enable-power"] or settings["player-move-power"]) then
				height = 23
			end
			assert(result.height == height)
			if unit == "pet" or unit == "targettarget" then
				local parent = HydraUI.UnitFrames[unit == "pet" and "player" or "target"]
				assert(result.anchor[2] == (parent or HydraUI.UIParent))
				assert(result.anchor[3] == (parent and (unit == "pet" and "BOTTOMLEFT" or "BOTTOMRIGHT") or "CENTER"))
				assert(result.anchor[5] == (parent and -2 or -341))
			elseif unit == "focus" then
				assert(result.anchor[1] == "RIGHT" and result.anchor[5] == 304)
				assert(result.enabled.Auras == option)
			else
				assert(result.anchor[1] == (unit == "player" and "TOPRIGHT" or "TOPLEFT"))
				assert(result.anchor[5] == -281)
				assert(result.enabled.Portrait == option)
				assert(result.Buffs.visible == option and result.Debuffs.visible == option)
				assert(result.refreshed == "ForceUpdate")
				if option then
					assert(result.CastAnchor.anchor[4] == (unit == "player" and 118 or 146))
				end
			end
		end
	end
end
print("All 128 singleton configurations passed")
