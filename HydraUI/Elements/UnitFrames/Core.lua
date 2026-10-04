local _, ns = ...
local HydraUI = ns:get()

local UnitFrames = HydraUI.UnitFrames or {}
HydraUI.UnitFrames = UnitFrames

ns.UnitFrameComponentHandlers = ns.UnitFrameComponentHandlers or {}
local componentHandlers = ns.UnitFrameComponentHandlers
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

local function Dispatch(self, event, ...)
	if not self:IsVisible() then
		return
	end

	local handlers = self.__events[event]
	if handlers then
		for i = 1, #handlers do
			handlers[i](self, event, ...)
		end
	end
end

local function RegisterEvent(self, event, handler, global)
	local handlers = self.__events[event]
	if not handlers then
		handlers = {}
		self.__events[event] = handlers
	end
	for i = 1, #handlers do
		if handlers[i] == handler then
			return
		end
	end
	handlers[#handlers + 1] = handler

	if global or self.__eventless then
		self.unitEvents[event] = nil
		self.__nativeRegisterEvent(self, event)
	else
		self.unitEvents[event] = true
		local otherUnit = secondaryUnits[event] and secondaryUnits[event][self.unit]
		self.__nativeRegisterUnitEvent(self, event, self.unit, otherUnit or "")
	end
end

local function UnregisterEvent(self, event, handler)
	local handlers = self.__events[event]
	if not handlers then
		return
	end
	for i = #handlers, 1, -1 do
		if not handler or handlers[i] == handler then
			table.remove(handlers, i)
		end
	end
	if #handlers == 0 then
		self.__events[event] = nil
		self.unitEvents[event] = nil
		self.__nativeUnregisterEvent(self, event)
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
		for registeredEvent in next, self.unitEvents do
			local otherUnit = secondaryUnits[registeredEvent] and secondaryUnits[registeredEvent][unit]
			self.__nativeRegisterUnitEvent(self, registeredEvent, unit, otherUnit or "")
		end
	end
	self:UpdateAllElements(event or "RefreshUnit")
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
	self.__elapsed = (self.__elapsed or 0) + elapsed
	if self.__elapsed >= 0.5 then
		self.__elapsed = 0
		self:UpdateAllElements("OnUpdate")
	end
end

local function EnableElement(self, name, unit)
	local handler = componentHandlers[name]
	if not handler or self.__enabledElements[name] then
		return
	end
	if handler.enable(self, unit or self.unit) then
		self.__enabledElements[name] = true
		if handler.update then
			self.__updates[#self.__updates + 1] = handler.update
		end
	end
end

local function DisableElement(self, name)
	if not self.__enabledElements[name] then
		return
	end
	local handler = componentHandlers[name]
	for i = #self.__updates, 1, -1 do
		if self.__updates[i] == handler.update then
			table.remove(self.__updates, i)
			break
		end
	end
	self.__enabledElements[name] = nil
	return handler.disable(self)
end

local function UpdateAllElements(self, event)
	if not self.unit or not UnitExists(self.unit) then
		return
	end
	if self.PreUpdate then
		self:PreUpdate(event)
	end
	for i = 1, #self.__updates do
		self.__updates[i](self, event, self.unit)
	end
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

function UnitFrames:CreateUnitButton(unit, globalName, builder)
	assert(not InCombatLockdown(), "secure unit frames cannot be created during combat")
	local frame = CreateFrame("Button", globalName, HydraUI.UIParent, "SecureUnitButtonTemplate")
	frame.__nativeRegisterEvent = frame.RegisterEvent
	frame.__nativeRegisterUnitEvent = frame.RegisterUnitEvent
	frame.__nativeUnregisterEvent = frame.UnregisterEvent
	frame.__events, frame.unitEvents = {}, {}
	frame.__updates, frame.__enabledElements = {}, {}
	frame.__elements = frame.__updates
	frame.colors, frame.unit, frame.realUnit = colors, unit, nil
	frame.__eventless = IsEventless(unit)

	frame.RegisterEvent, frame.UnregisterEvent = RegisterEvent, UnregisterEvent
	frame.EnableElement, frame.DisableElement = EnableElement, DisableElement
	frame.IsElementEnabled = function(owner, name)
		return owner.__enabledElements[name]
	end
	frame.UpdateAllElements = UpdateAllElements
	frame.Tag, frame.Untag, frame.UpdateTags = tag, untag, updateTags
	frame.Enable, frame.Disable = Enable, Disable
	frame.IsEnabled = UnitWatchRegistered
	frame:SetScript("OnEvent", Dispatch)
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame:SetAttribute("toggleForVehicle", true)
	frame:SetAttribute("unit", unit)

	builder(frame, unit)
	for name in next, componentHandlers do
		frame:EnableElement(name, unit)
	end

	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateUnit, true)
	if not frame.__eventless then
		frame:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateUnit)
		frame:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateUnit)
		if unit ~= "player" then
			frame:RegisterEvent("UNIT_PET", UpdatePet)
		end
	else
		frame:SetScript("OnUpdate", PollEventless)
	end
	if unit == "target" then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateAllElements, true)
	elseif unit == "focus" then
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED", UpdateAllElements, true)
	elseif unit:match("boss%d+$") then
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", UpdateAllElements, true)
		frame:RegisterEvent("UNIT_TARGETABLE_CHANGED", UpdateAllElements)
	end

	frame:SetScript("OnShow", UpdateUnit)
	frame:HookScript("OnAttributeChanged", UnitAttributeChanged)
	RegisterUnitWatch(frame)
	_G.ClickCastFrames = _G.ClickCastFrames or {}
	_G.ClickCastFrames[frame] = true
	return frame
end
