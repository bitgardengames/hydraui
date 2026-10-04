local _, ns = ...
local HydraUI = ns:get()

local UF = HydraUI:NewModule("Unit Frames")

local Hider = CreateFrame("Frame", nil, HydraUI.UIParent, "SecureHandlerStateTemplate")
Hider:Hide()
UF.Hider = Hider

local UnitFrames = HydraUI.UnitFrames or {}
HydraUI.UnitFrames = UnitFrames

-- Element lifecycle state is private to HydraUI's unit-frame module. The addon
-- namespace is only used to obtain HydraUI and is not a library registry.
UF.ElementHandlers = {}
local elementHandlers = UF.ElementHandlers
local colors = HydraUI:GetUnitFrameColors()

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

local function DispatchEvent(self, event, ...)
	if not self:IsVisible() then
		return
	end

	local handlers = self._events[event]

	if handlers then
		for i = 1, #handlers do
			handlers[i](self, event, ...)
		end
	end
end

local function Subscribe(self, event, handler, global)
	local handlers = self._events[event]

	if not handlers then
		handlers = {}
		self._events[event] = handlers
	end

	for i = 1, #handlers do
		if handlers[i] == handler then
			return
		end
	end

	handlers[#handlers + 1] = handler

	if global or self._pollsUnit then
		self._unitEvents[event] = nil
		self._registerEvent(self, event)
	else
		self._unitEvents[event] = true

		local otherUnit = secondaryUnits[event] and secondaryUnits[event][self.unit]

		if otherUnit then
			self._registerUnitEvent(self, event, self.unit, otherUnit)
		else
			self._registerUnitEvent(self, event, self.unit)
		end
	end
end

local function Unsubscribe(self, event, handler)
	local handlers = self._events[event]

	if not handlers then
		return
	end

	for i = #handlers, 1, -1 do
		if not handler or handlers[i] == handler then
			table.remove(handlers, i)
		end
	end

	if #handlers == 0 then
		self._events[event] = nil
		self._unitEvents[event] = nil
		self._unregisterEvent(self, event)
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
		self.unit = unit
		self.realUnit = unit ~= realUnit and realUnit or nil

		for registeredEvent in next, self._unitEvents do
			local otherUnit = secondaryUnits[registeredEvent] and secondaryUnits[registeredEvent][unit]

			if otherUnit then
				self._registerUnitEvent(self, registeredEvent, unit, otherUnit)
			else
				self._registerUnitEvent(self, registeredEvent, unit)
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
	self._pollElapsed = (self._pollElapsed or 0) + elapsed

	if self._pollElapsed >= 0.5 then
		self._pollElapsed = 0
		self:Refresh("OnUpdate")
	end
end

local function EnableElement(self, name, unit)
	local handler = elementHandlers[name]

	if not handler or self._enabledElements[name] then
		return
	end

	if handler.enable(self, unit or self.unit) then
		self._enabledElements[name] = true

		if handler.update then
			self._refreshers[#self._refreshers + 1] = handler.update
		end
	end
end

local function DisableElement(self, name)
	if not self._enabledElements[name] then
		return
	end

	local handler = elementHandlers[name]

	for i = #self._refreshers, 1, -1 do
		if self._refreshers[i] == handler.update then
			table.remove(self._refreshers, i)

			break
		end
	end

	self._enabledElements[name] = nil

	return handler.disable(self)
end

local function Refresh(self, event)
	if not self.unit or not UnitExists(self.unit) then
		return
	end

	if self.PreUpdate then
		self:PreUpdate(event)
	end

	for i = 1, #self._refreshers do
		self._refreshers[i](self, event, self.unit)
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
	return self._enabledElements[name] == true
end

local function PrepareFrame(frame, unit, pollsUnit)
	-- Preserve Blizzard's event methods before installing HydraUI's fan-out dispatcher. Several independent components can then share one event.
	frame._registerEvent = frame.RegisterEvent
	frame._registerUnitEvent = frame.RegisterUnitEvent
	frame._unregisterEvent = frame.UnregisterEvent
	frame._events = {}
	frame._unitEvents = {}
	frame._refreshers = {}
	frame._enabledElements = {}
	frame.colors = colors
	frame.unit = unit
	frame.realUnit = nil
	frame._pollsUnit = pollsUnit == true

	frame.RegisterEvent = Subscribe
	frame.UnregisterEvent = Unsubscribe
	frame.EnableElement = EnableElement
	frame.DisableElement = DisableElement
	frame.IsElementEnabled = IsElementEnabled
	frame.Refresh = Refresh
	-- Kept as a transition alias for extensions written against earlier HydraUI releases. New code should describe its intent with Refresh.
	frame.UpdateAllElements = Refresh
	frame.Tag = UF.Tag
	frame.Untag = UF.Untag
	frame.UpdateTags = UF.UpdateTags
	frame:SetScript("OnEvent", DispatchEvent)
end

local function BuildElements(frame, unit, builder)
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
	frame.Enable = Enable
	frame.Disable = Disable
	frame.IsEnabled = UnitWatchRegistered
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame:SetAttribute("toggleForVehicle", true)
	frame:SetAttribute("unit", unit)

	BuildElements(frame, unit, builder)

	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateUnit, true)

	if not frame._pollsUnit then
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

-- Blizzard creates secure-header children for us.  Adopt one into the native unit-frame runtime exactly once after its secure attributes have been set.
function UnitFrames:InitializeHeaderChild(frame, unit, builder)
	if frame._unitFrameInitialized then
		return
	end

	frame._unitFrameInitialized = true

	PrepareFrame(frame, unit, false)

	frame.Enable = Enable
	frame.Disable = Disable
	frame.IsEnabled = UnitWatchRegistered

	BuildElements(frame, unit, builder)

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

	BuildElements(frame, unit, builder)

	return frame
end

function UnitFrames:SetNamePlateUnit(frame, unit)
	if not unit then
		for event in next, frame._unitEvents do
			frame._unregisterEvent(frame, event)
		end

		frame.unit = nil
		frame:Hide()

		return
	end

	frame.unit = unit

	for event in next, frame._unitEvents do
		frame._registerUnitEvent(frame, event, unit)
	end

	frame:Show()
	frame:Refresh("RefreshUnit")
end
