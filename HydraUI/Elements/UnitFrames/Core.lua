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
local elementHandlers, elementNames = {}, {}
local colors = HydraUI:GetUnitFrameColors()

local petOwnerEvents = {
	UNIT_ENTERED_VEHICLE = true,
	UNIT_EXITED_VEHICLE = true,
	UNIT_PET = true,
}

local eventlessUnits = {boss6 = true, boss7 = true, boss8 = true}

local function IsEventless(unit)
	return unit:match("%w+target") or eventlessUnits[unit]
end

function UF:RegisterElement(name, lifecycle)
	assert(type(name) == "string", "unit-frame element names must be strings")
	assert(type(lifecycle) == "table" and type(lifecycle.enable) == "function", "invalid unit-frame element")

	if not elementHandlers[name] then
		elementNames[#elementNames + 1] = name
	end

	elementHandlers[name] = lifecycle
end

-- Elements expose ForceUpdate on their widget. Keep the small adapter here so
-- every element uses the same owner, event, and unit calling convention.
function UF:CreateForceUpdate(element, update)
	return function()
		local frame = element.__owner

		return update(frame, "ForceUpdate", frame.unit)
	end
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

-- Pet events also report changes on their owner. Keep this registration rule
-- in one place for both initial subscriptions and secure unit changes.
local function BindUnitEvent(self, event)
	if self.unit == "pet" and petOwnerEvents[event] then
		self._registerUnitEvent(self, event, self.unit, "player")
	else
		self._registerUnitEvent(self, event, self.unit)
	end
end

local function Subscribe(self, event, handler, global)
	local handlers = self._events[event]
	local firstHandler = not handlers

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
		-- An event only needs one native registration, regardless of how many
		-- elements listen for it. Promote an existing unit event when a later
		-- subscriber needs the global form.
		if not firstHandler and not self._unitEvents[event] then
			return
		end

		self._unitEvents[event] = nil
		self._registerEvent(self, event)
	else
		if not firstHandler then
			return
		end

		self._unitEvents[event] = true

		BindUnitEvent(self, event)
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

	realUnit = unit ~= realUnit and realUnit or nil

	if self.unit ~= unit or self.realUnit ~= realUnit then
		self.unit = unit
		self.realUnit = realUnit

		for registeredEvent in next, self._unitEvents do
			BindUnitEvent(self, registeredEvent)
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

local function StartEventlessPolling(self)
	UpdateUnit(self, "OnShow")

	if not self._pollTicker then
		self._pollTicker = C_Timer.NewTicker(0.5, function()
			self:Refresh("PollEventless")
		end)
	end
end

local function StopEventlessPolling(self)
	if self._pollTicker then
		self._pollTicker:Cancel()
		self._pollTicker = nil
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
	StopEventlessPolling(self)
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

	for i = 1, #elementNames do
		frame:EnableElement(elementNames[i], unit)
	end
end

local function EnableClickCasting(frame)
	_G.ClickCastFrames = _G.ClickCastFrames or {}
	_G.ClickCastFrames[frame] = true
end

local function InitializeUnitButton(frame, unit, builder, pollsUnit)
	PrepareFrame(frame, unit, pollsUnit)

	frame.Enable = Enable
	frame.Disable = Disable
	frame.IsEnabled = UnitWatchRegistered

	BuildElements(frame, unit, builder)

	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateUnit, true)

	if pollsUnit then
		frame:SetScript("OnShow", StartEventlessPolling)
		frame:SetScript("OnHide", StopEventlessPolling)
	else
		frame:RegisterEvent("UNIT_ENTERED_VEHICLE", UpdateUnit)
		frame:RegisterEvent("UNIT_EXITED_VEHICLE", UpdateUnit)

		if unit ~= "player" then
			frame:RegisterEvent("UNIT_PET", UpdatePet)
		end

		frame:SetScript("OnShow", UpdateUnit)
	end

	frame:HookScript("OnAttributeChanged", UnitAttributeChanged)
	EnableClickCasting(frame)
end

function UnitFrames:CreateUnitButton(unit, globalName, builder)
	assert(not InCombatLockdown(), "secure unit frames cannot be created during combat")

	local frame = CreateFrame("Button", globalName, HydraUI.UIParent, "SecureUnitButtonTemplate")

	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame:SetAttribute("toggleForVehicle", true)
	frame:SetAttribute("unit", unit)

	InitializeUnitButton(frame, unit, builder, IsEventless(unit))

	if unit == "target" then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", Refresh, true)
	elseif unit == "focus" then
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED", Refresh, true)
	elseif unit:match("boss%d+$") then
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", Refresh, true)
		frame:RegisterEvent("UNIT_TARGETABLE_CHANGED", Refresh)
	end

	RegisterUnitWatch(frame)

	-- A newly-created frame can already be visible, in which case installing an
	-- OnShow handler does not invoke it retroactively.
	if frame._pollsUnit and frame:IsShown() then
		StartEventlessPolling(frame)
	end

	return frame
end

-- Blizzard creates secure-header children for us.  Adopt one into the native unit-frame runtime exactly once after its secure attributes have been set.
function UnitFrames:InitializeHeaderChild(frame, unit, builder)
	if frame._unitFrameInitialized then
		return
	end

	frame._unitFrameInitialized = true

	InitializeUnitButton(frame, unit, builder, false)
end

function UnitFrames:CreateNamePlateButton(parent, unit, builder)
	local frame = CreateFrame("Button", nil, parent)

	PrepareFrame(frame, unit, false)

	frame:EnableMouse(false)
	frame.isNamePlate = true

	BuildElements(frame, unit, builder)

	-- A native parent becoming visible only requires fresh data, not Show/Hide.
	frame:SetScript("OnShow", function(self)
		self:Refresh("NamePlateShown")
	end)

	return frame
end

function UnitFrames:SetNamePlateUnit(frame, unit)
	if not unit then
		for event in next, frame._unitEvents do
			frame._unregisterEvent(frame, event)
		end

		frame.unit = nil
		-- Detach from the native pool so another unit cannot inherit this child.
		frame:SetParent(UF.Hider)

		return
	end

	frame.unit = unit

	for event in next, frame._unitEvents do
		frame._registerUnitEvent(frame, event, unit)
	end

	frame:Refresh("RefreshUnit")
end
