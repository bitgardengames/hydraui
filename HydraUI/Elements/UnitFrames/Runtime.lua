local _, ns = ...
local HydraUI = ns:get()

local Runtime = {}
ns.UnitFrameRuntime = Runtime

local oUF = ns.oUF
local private = oUF.Private
local elements = private.elements
local frameMethods = private.frame_metatable.__index

local secondaryUnits = {
	UNIT_ENTERED_VEHICLE = {pet = "player"},
	UNIT_EXITED_VEHICLE = {pet = "player"},
	UNIT_PET = {pet = "player"},
}

local function Dispatch(self, event, ...)
	local handlers = self.__hydraEvents and self.__hydraEvents[event]
	if not handlers or not self:IsVisible() then return end
	for handler in pairs(handlers) do handler(self, event, ...) end
end

local function RegisterEvent(self, event, handler, unitless)
	local events = self.__hydraEvents
	events[event] = events[event] or {}
	events[event][handler] = true
	if unitless then
		getmetatable(self).__index.RegisterEvent(self, event)
	else
		self.__hydraUnitEvents[event] = true
		local other = secondaryUnits[event] and secondaryUnits[event][self.unit]
		getmetatable(self).__index.RegisterUnitEvent(self, event, self.unit, other or "")
	end
end

local function UnregisterEvent(self, event, handler)
	local handlers = self.__hydraEvents[event]
	if not handlers then return end
	handlers[handler] = nil
	if not next(handlers) then
		self.__hydraEvents[event] = nil
		self.__hydraUnitEvents[event] = nil
		getmetatable(self).__index.UnregisterEvent(self, event)
	end
end

local function UpdateAll(self, event)
	if not self.unit or not UnitExists(self.unit) then return end
	if self.PreUpdate then self:PreUpdate(event) end
	for _, update in ipairs(self.__hydraUpdates) do update(self, event, self.unit) end
	if self.PostUpdate then self:PostUpdate(event) end
end

local function EnableElement(self, name, unit)
	local element = elements[name]
	if not element or self.__hydraEnabled[name] then return end
	if element.enable(self, unit or self.unit) then
		self.__hydraEnabled[name] = true
		if element.update then self.__hydraUpdates[#self.__hydraUpdates + 1] = element.update end
	end
end

local function DisableElement(self, name)
	local element = elements[name]
	if not element or not self.__hydraEnabled[name] then return end
	for i, update in ipairs(self.__hydraUpdates) do
		if update == element.update then table.remove(self.__hydraUpdates, i) break end
	end
	self.__hydraEnabled[name] = nil
	return element.disable(self)
end

local function Initialize(frame, unit)
	frame.__hydraEvents, frame.__hydraUnitEvents = {}, {}
	frame.__hydraUpdates, frame.__hydraEnabled, frame.__elements = {}, {}, {}
	frame.RegisterEvent, frame.UnregisterEvent = RegisterEvent, UnregisterEvent
	frame.EnableElement, frame.DisableElement = EnableElement, DisableElement
	frame.IsElementEnabled = function(self, name) return self.__hydraEnabled[name] end
	frame.UpdateAllElements, frame.HydraUpdateAll = UpdateAll, UpdateAll
	frame.Enable, frame.Disable, frame.IsEnabled = RegisterUnitWatch, frameMethods.Disable, UnitWatchRegistered
	-- Tags are an element helper, not part of frame creation. Reuse only these
	-- mature parsers while the runtime owns lifecycle and event registration.
	frame.Tag, frame.Untag, frame.UpdateTags = frameMethods.Tag, frameMethods.Untag, frameMethods.UpdateTags
	frame:SetScript("OnEvent", Dispatch)
	Runtime:SetUnit(frame, unit, true)
	Runtime:ApplyStyle(frame, unit)
	for name in pairs(elements) do frame:EnableElement(name, unit) end
	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateAll, true)
	frame:SetScript("OnShow", function(self) self:HydraUpdateAll("OnShow") end)
	return frame
end

function Runtime:ResolveStyle(unit)
	if HydraUI.StyleFuncs[unit] then return HydraUI.StyleFuncs[unit] end
	if unit:match("^raidpet") then return HydraUI.StyleFuncs.raidpet end
	if unit:match("^raid") then return HydraUI.StyleFuncs.raid end
	if unit:match("^partypet") then return HydraUI.StyleFuncs.partypet end
	if unit:match("^party") then return HydraUI.StyleFuncs.party end
	if unit:match("^boss%d+") then return HydraUI.StyleFuncs.boss end
	if unit:match("^nameplate") then return HydraUI.StyleFuncs.nameplate end
end

function Runtime:ApplyStyle(frame, unit)
	local style = self:ResolveStyle(unit)
	if style then style(frame, unit) end
end

function Runtime:SetUnit(frame, unit, initial)
	frame.unit = unit
	frame.id = unit and unit:match("(%d+)$")
	if unit then frame:SetAttribute("unit", unit) end
	if not initial then
		for event in pairs(frame.__hydraUnitEvents) do
			local other = secondaryUnits[event] and secondaryUnits[event][unit]
			getmetatable(frame).__index.RegisterUnitEvent(frame, event, unit, other or "")
		end
		frame:HydraUpdateAll("HydraUnitChanged")
	end
end

function Runtime:CreateUnit(unit, name, parent)
	local frame = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate")
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame:SetAttribute("toggleForVehicle", true)
	Initialize(frame, unit)
	RegisterUnitWatch(frame)
	_G.ClickCastFrames = _G.ClickCastFrames or {}
	_G.ClickCastFrames[frame] = true
	return frame
end

local initialConfig = [[
	self:SetWidth(self:GetParent():GetAttribute('initial-width'))
	self:SetHeight(self:GetParent():GetAttribute('initial-height'))
	self:SetAttribute('*type1', 'target')
	self:SetAttribute('*type2', 'togglemenu')
	RegisterUnitWatch(self)
	self:GetParent():CallMethod('InitializeChild', self:GetName())
]]

function Runtime:CreateHeader(name, template, visibility, ...)
	local header = CreateFrame("Frame", name, HydraUI.UIParent, template or "SecureGroupHeaderTemplate")
	header.InitializeChild = function(_, childName)
		local child = _G[childName]
		if child and not child.__hydraEnabled then Initialize(child, child:GetAttribute("unit")) end
	end
	header:SetAttribute("template", "SecureUnitButtonTemplate")
	for i = 1, select("#", ...), 2 do header:SetAttribute(select(i, ...), select(i + 1, ...)) end
	header:SetAttribute("initialConfigFunction", initialConfig)
	header:SetScript("OnShow", function(self)
		for _, child in ipairs({self:GetChildren()}) do
			if not child.__hydraEnabled and child:GetAttribute("unit") then Initialize(child, child:GetAttribute("unit")) end
		end
	end)
	if visibility then RegisterAttributeDriver(header, "state-visibility", visibility) end
	return header
end

function Runtime:CreateNamePlates(callback, cvars)
	for key, value in pairs(cvars or {}) do SetCVar(key, value) end
	local driver = CreateFrame("Frame")
	driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	driver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	driver:RegisterEvent("PLAYER_TARGET_CHANGED")
	driver:SetScript("OnEvent", function(_, event, unit)
		if event == "PLAYER_TARGET_CHANGED" then unit = "target" end
		local plate = unit and C_NamePlate.GetNamePlateForUnit(unit)
		if not plate then return end
		if event == "NAME_PLATE_UNIT_REMOVED" then
			if callback then callback(plate.unitFrame, event, unit) end
			return
		end
		if not plate.unitFrame then
			plate.unitFrame = CreateFrame("Button", nil, plate)
			plate.unitFrame.isNamePlate = true
			Initialize(plate.unitFrame, unit)
		else self:SetUnit(plate.unitFrame, unit) end
		if callback then callback(plate.unitFrame, event, unit) end
		plate.unitFrame:HydraUpdateAll(event)
	end)
end
