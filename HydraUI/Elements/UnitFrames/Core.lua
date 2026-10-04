local _, ns = ...
local HydraUI = ns:get()

HydraUI:NewModule("Unit Frames")

local Hider = CreateFrame("Frame", nil, HydraUI.UIParent, "SecureHandlerStateTemplate")
Hider:Hide()
ns.UnitFrameHider = Hider

local UnitFrames = HydraUI.UnitFrames or {}
HydraUI.UnitFrames = UnitFrames

-- Elements belong to HydraUI's unit-frame runtime. Each element registers a small lifecycle record and is enabled only when a style creates its widget. Keep the old namespace key as a compatibility alias for third-party styles.
ns.UnitFrameElementHandlers = ns.UnitFrameElementHandlers or ns.UnitFrameComponentHandlers or {}
ns.UnitFrameComponentHandlers = ns.UnitFrameElementHandlers
local elementHandlers = ns.UnitFrameElementHandlers
local colors = ns.UnitFrameColors
local tag, untag, updateTags = ns.UnitFrameTag, ns.UnitFrameUntag, ns.UnitFrameUpdateTags

local secondaryUnits = {
	UNIT_ENTERED_VEHICLE = {pet = "player"},
	UNIT_EXITED_VEHICLE = {pet = "player"},
	UNIT_PET = {pet = "player"},
}

local eventlessUnits = {boss6 = true, boss7 = true, boss8 = true}

local function IsEventless(unit)
	return unit:match("%w+target") or eventlessUnits[unit]
end

function UnitFrames:RegisterElement(name, lifecycle)
	assert(type(name) == "string", "unit-frame element names must be strings")
	assert(type(lifecycle) == "table" and type(lifecycle.enable) == "function", "invalid unit-frame element")

	elementHandlers[name] = lifecycle
end

-- Compatibility for extensions written during the native-runtime migration.
UnitFrames.RegisterComponent = UnitFrames.RegisterElement

local function DispatchEvent(self, event, ...)
	if not self:IsVisible() then
		return
	end

	local handlers = self._hydraEvents[event]

	if handlers then
		for i = 1, #handlers do
			handlers[i](self, event, ...)
		end
	end
end

local function Subscribe(self, event, handler, global)
	local handlers = self._hydraEvents[event]

	if not handlers then
		handlers = {}
		self._hydraEvents[event] = handlers
	end

	for i = 1, #handlers do
		if handlers[i] == handler then
			return
		end
	end

	handlers[#handlers + 1] = handler

	if global or self._hydraPollsUnit then
		self._hydraUnitEvents[event] = nil
		self._hydraRegisterEvent(self, event)
	else
		self._hydraUnitEvents[event] = true

		local otherUnit = secondaryUnits[event] and secondaryUnits[event][self.unit]

		if otherUnit then
			self._hydraRegisterUnitEvent(self, event, self.unit, otherUnit)
		else
			self._hydraRegisterUnitEvent(self, event, self.unit)
		end
	end
end

local function Unsubscribe(self, event, handler)
	local handlers = self._hydraEvents[event]

	if not handlers then
		return
	end

	for i = #handlers, 1, -1 do
		if not handler or handlers[i] == handler then
			table.remove(handlers, i)
		end
	end

	if #handlers == 0 then
		self._hydraEvents[event] = nil
		self._hydraUnitEvents[event] = nil
		self._hydraUnregisterEvent(self, event)
	end
end

local function UpdateUnit(self, event)
	local realUnit = SecureButton_GetUnit(self)
	local unit = SecureButton_GetModifiedUnit(self)

	if realUnit == "playerpet" then
		realUnit = "pet"
	end

	if realUnit == "playertarget" then
		realUnit = "target"
	end

	if unit == "pet" and realUnit ~= "pet" then
		unit = "vehicle"
	end

	if not unit then
		return
	end

	if self.unit ~= unit or self.realUnit ~= realUnit then
		self.unit, self.realUnit = unit, unit ~= realUnit and realUnit or nil

		for registeredEvent in next, self._hydraUnitEvents do
			local otherUnit = secondaryUnits[registeredEvent] and secondaryUnits[registeredEvent][unit]

			if otherUnit then
				self._hydraRegisterUnitEvent(self, registeredEvent, unit, otherUnit)
			else
				self._hydraRegisterUnitEvent(self, registeredEvent, unit)
			end
		end
	end

	self:Refresh(event or "RefreshUnit")
end

local function UpdatePet(self, event, changedUnit)
	if changedUnit == "target" then
		return
	end

	if changedUnit == "player" and self.unit ~= "pet" and self.realUnit ~= "pet" then
		return
	end

	UpdateUnit(self, event)
end

local function UnitAttributeChanged(self, name, value)
	if name == "unit" and value then
		UpdateUnit(self, "OnAttributeChanged")
	end
end

local function PollEventless(self, elapsed)
	self._hydraPollElapsed = (self._hydraPollElapsed or 0) + elapsed

	if self._hydraPollElapsed >= 0.5 then
		self._hydraPollElapsed = 0
		self:Refresh("OnUpdate")
	end
end

local function EnableElement(self, name, unit)
	local handler = elementHandlers[name]

	if not handler or self._hydraEnabledComponents[name] then
		return
	end

	if handler.enable(self, unit or self.unit) then
		self._hydraEnabledComponents[name] = true

		if handler.update then
			self._hydraRefreshers[#self._hydraRefreshers + 1] = handler.update
		end
	end
end

local function DisableElement(self, name)
	if not self._hydraEnabledComponents[name] then
		return
	end

	local handler = elementHandlers[name]

	for i = #self._hydraRefreshers, 1, -1 do
		if self._hydraRefreshers[i] == handler.update then
			table.remove(self._hydraRefreshers, i)

			break
		end
	end

	self._hydraEnabledComponents[name] = nil

	return handler.disable(self)
end

local function Refresh(self, event)
	if not self.unit or not UnitExists(self.unit) then
		return
	end

	if self.PreUpdate then
		self:PreUpdate(event)
	end

	for i = 1, #self._hydraRefreshers do
		self._hydraRefreshers[i](self, event, self.unit)
	end

	-- Tags are not elements, but they still need the same forced refresh used when a frame acquires a new target/focus/header unit. Unit events keep them current between those full refreshes.
	self:UpdateTags(event)

	if self.PostUpdate then
		self:PostUpdate(event)
	end
end

local function Enable(self, asState)
	RegisterUnitWatch(self, asState)
end

local function Disable(self)
	UnregisterUnitWatch(self)
	self:Hide()
end

local function IsElementEnabled(self, name)
	return self._hydraEnabledComponents[name] == true
end

local function PrepareFrame(frame, unit, pollsUnit)
	-- Preserve Blizzard's event methods before installing HydraUI's fan-out dispatcher. Several independent components can then share one event.
	frame._hydraRegisterEvent = frame.RegisterEvent
	frame._hydraRegisterUnitEvent = frame.RegisterUnitEvent
	frame._hydraUnregisterEvent = frame.UnregisterEvent
	frame._hydraEvents = {}
	frame._hydraUnitEvents = {}
	frame._hydraRefreshers = {}
	frame._hydraEnabledComponents = {}
	frame.colors, frame.unit, frame.realUnit = colors, unit, nil
	frame._hydraPollsUnit = pollsUnit == true

	frame.RegisterEvent, frame.UnregisterEvent = Subscribe, Unsubscribe
	frame.EnableElement, frame.DisableElement = EnableElement, DisableElement
	frame.IsElementEnabled = IsElementEnabled
	frame.Refresh = Refresh
	-- Kept as a transition alias for extensions written against earlier HydraUI releases. New code should describe its intent with Refresh.
	frame.UpdateAllElements = Refresh
	frame.Tag, frame.Untag, frame.UpdateTags = tag, untag, updateTags
	frame:SetScript("OnEvent", DispatchEvent)
end

local function BuildComponents(frame, unit, builder)
	builder(frame, unit)

	for name in next, elementHandlers do
		frame:EnableElement(name, unit)
	end
end

local function EnableClickCasting(frame)
	_G.ClickCastFrames = _G.ClickCastFrames or {}
	_G.ClickCastFrames[frame] = true
end

function UnitFrames:CreateUnitButton(unit, globalName, builder)
	assert(not InCombatLockdown(), "secure unit frames cannot be created during combat")

	local frame = CreateFrame("Button", globalName, HydraUI.UIParent, "SecureUnitButtonTemplate")

	PrepareFrame(frame, unit, IsEventless(unit))
	frame.Enable, frame.Disable = Enable, Disable
	frame.IsEnabled = UnitWatchRegistered
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame:SetAttribute("toggleForVehicle", true)
	frame:SetAttribute("unit", unit)

	BuildComponents(frame, unit, builder)

	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateUnit, true)

	if not frame._hydraPollsUnit then
		frame:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateUnit)
		frame:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateUnit)

		if unit ~= "player" then
			frame:RegisterEvent("UNIT_PET", UpdatePet)
		end
	else
		frame:SetScript("OnUpdate", PollEventless)
	end

	if unit == "target" then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", Refresh, true)
	elseif unit == "focus" then
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED", Refresh, true)
	elseif unit:match("boss%d+$") then
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", Refresh, true)
		frame:RegisterEvent("UNIT_TARGETABLE_CHANGED", Refresh)
	end

	frame:SetScript("OnShow", UpdateUnit)
	frame:HookScript("OnAttributeChanged", UnitAttributeChanged)
	RegisterUnitWatch(frame)
	EnableClickCasting(frame)

	return frame
end

-- Blizzard creates secure-header children for us.  Adopt one into the native
-- unit-frame runtime exactly once after its secure attributes have been set.
function UnitFrames:InitializeHeaderChild(frame, unit, builder)
	if frame._hydraInitialized then
		return
	end

	frame._hydraInitialized = true

	PrepareFrame(frame, unit, false)

	frame.Enable, frame.Disable, frame.IsEnabled = Enable, Disable, UnitWatchRegistered

	BuildComponents(frame, unit, builder)

	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateUnit, true)
	frame:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateUnit)
	frame:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateUnit)
	frame:RegisterEvent("UNIT_PET", UpdatePet)
	frame:SetScript("OnShow", UpdateUnit)
	frame:HookScript("OnAttributeChanged", UnitAttributeChanged)

	EnableClickCasting(frame)
end

function UnitFrames:CreateNamePlateButton(parent, unit, builder)
	local frame = CreateFrame("Button", nil, parent)

	PrepareFrame(frame, unit, false)

	frame:EnableMouse(false)
	frame.isNamePlate = true

	BuildComponents(frame, unit, builder)

	return frame
end

function UnitFrames:SetNamePlateUnit(frame, unit)
	if not unit then
		for event in next, frame._hydraUnitEvents do
			frame._hydraUnregisterEvent(frame, event)
		end
		
		frame.unit = nil
		frame:Hide()
		
		return
	end
	
	frame.unit = unit
	
	for event in next, frame._hydraUnitEvents do
		frame._hydraRegisterUnitEvent(frame, event, unit)
	end
	
	frame:Show()
	frame:Refresh("RefreshUnit")
end