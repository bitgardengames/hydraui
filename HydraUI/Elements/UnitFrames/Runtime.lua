local _, ns = ...
local HydraUI = ns:get()

local Runtime = {}
ns.UnitFrameRuntime = Runtime

local oUF = ns.oUF
local private = oUF.Private
local frameMethods = private.frame_metatable.__index
local components = ns.UnitFrameComponents

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
	local element = components[name]
	if not element or self.__hydraEnabled[name] then return end
	if element.enable(self, unit or self.unit) then
		self.__hydraEnabled[name] = true
		if element.update then self.__hydraUpdates[#self.__hydraUpdates + 1] = element.update end
	end
end

local function DisableElement(self, name)
	local element = components[name]
	if not element or not self.__hydraEnabled[name] then return end
	for i, update in ipairs(self.__hydraUpdates) do
		if update == element.update then table.remove(self.__hydraUpdates, i) break end
	end
	self.__hydraEnabled[name] = nil
	return element.disable(self)
end

local function Initialize(frame, unit, secureUnit, styleKey)
	frame.__hydraEvents, frame.__hydraUnitEvents = {}, {}
	frame.__hydraUpdates, frame.__hydraEnabled, frame.__elements = {}, {}, {}
	frame.colors = oUF.colors
	frame.RegisterEvent, frame.UnregisterEvent = RegisterEvent, UnregisterEvent
	frame.EnableElement, frame.DisableElement = EnableElement, DisableElement
	frame.IsElementEnabled = function(self, name) return self.__hydraEnabled[name] end
	frame.UpdateAllElements, frame.HydraUpdateAll = UpdateAll, UpdateAll
	frame.Enable, frame.Disable, frame.IsEnabled = RegisterUnitWatch, frameMethods.Disable, UnitWatchRegistered
	-- Tags are an element helper, not part of frame creation. Reuse only these
	-- mature parsers while the runtime owns lifecycle and event registration.
	frame.Tag, frame.Untag, frame.UpdateTags = frameMethods.Tag, frameMethods.Untag, frameMethods.UpdateTags
	frame.ColorGradient = frameMethods.ColorGradient
	frame:SetScript("OnEvent", Dispatch)
	Runtime:SetUnit(frame, unit, true, secureUnit)
	Runtime:ApplyStyle(frame, unit, styleKey)
	components.ApplyColors(frame)
	for _, name in ipairs(components.order) do frame:EnableElement(name, unit) end
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

function Runtime:ApplyStyle(frame, unit, styleKey)
	local style = self:ResolveStyle(styleKey or unit)
	if style then style(frame, unit) end
end

function Runtime:SetUnit(frame, unit, initial, secureUnit)
	if not initial and frame.unit ~= unit then
		-- A unit event for the old token can no longer clean these visual
		-- objects once a secure header or nameplate has been reassigned.
		for _, name in ipairs(components.order) do
			local component = components[name]
			if frame.__hydraEnabled[name] and component.clear then
				component.clear(frame)
			end
		end
	end
	frame.unit = unit
	frame.id = unit and unit:match("(%d+)$")
	-- A group header owns its children's unit attribute. Writing it back from
	-- insecure code would be both redundant and forbidden while in combat.
	if unit and not secureUnit then frame:SetAttribute("unit", unit) end
	if not initial then
		for event in pairs(frame.__hydraUnitEvents) do
			getmetatable(frame).__index.UnregisterEvent(frame, event)
			if unit then
				local other = secondaryUnits[event] and secondaryUnits[event][unit]
				getmetatable(frame).__index.RegisterUnitEvent(frame, event, unit, other or "")
			end
		end
		if unit and UnitExists(unit) then
			frame:HydraUpdateAll("HydraUnitChanged")
		end
	end
end

-- Secure headers create and reassign their children. This is deliberately a
-- non-secure half of that lifecycle: the secure snippet only reports that a
-- child changed, and HydraUI installs/styles it exactly once here.
function Runtime:RefreshHeaderChild(frame, styleKey)
	if not frame then return end
	local unit = frame:GetAttribute("unit")
	if not frame.__hydraEnabled then
		Initialize(frame, unit, true, styleKey)
	elseif frame.unit ~= unit then
		self:SetUnit(frame, unit, false, true)
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

function Runtime:CreateNamePlates(callback, cvars)
	local namePlateAPI = C_NamePlate
	if not namePlateAPI or not namePlateAPI.GetNamePlateForUnit then
		return
	end

	local layers = setmetatable({}, {__mode = "k"})
	local units = {}
	self.NamePlateLayers = layers

	local function ApplyCVars()
		local setCVar = C_CVar and C_CVar.SetCVar or SetCVar
		if not setCVar then
			return
		end
		for key, value in pairs(cvars or {}) do
			setCVar(key, value)
		end
	end

	local function IsUsablePlate(plate)
		if not plate then
			return false
		end
		return not plate.IsForbidden or not plate:IsForbidden()
	end

	local function Resolve(unit)
		if not unit then
			return
		end
		local plate = namePlateAPI.GetNamePlateForUnit(unit)
		if IsUsablePlate(plate) then
			return plate
		end
	end

	local function ClearLayer(layer)
		if not layer then
			return
		end
		self:SetUnit(layer, nil)
		-- SetUnit clears component-owned state (including aura icons and casts).
		-- Tags are shared helpers rather than components, so explicitly blank them.
		if layer.HydraTags then
			for fontString in pairs(layer.HydraTags) do
				fontString:SetText("")
			end
		end
		layer:Hide()
	end

	local driver = CreateFrame("Frame")
	driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	driver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	driver:RegisterEvent("PLAYER_TARGET_CHANGED")
	if IsLoggedIn and IsLoggedIn() then
		ApplyCVars()
	else
		driver:RegisterEvent("PLAYER_LOGIN")
	end
	driver:SetScript("OnEvent", function(_, event, unit)
		if event == "PLAYER_LOGIN" then
			ApplyCVars()
			driver:UnregisterEvent("PLAYER_LOGIN")
			return
		end
		if event == "PLAYER_TARGET_CHANGED" then
			-- Both the old and new target need their target/threat presentation reset.
			for _, layer in pairs(units) do
				if layer.unit then
					layer:HydraUpdateAll(event)
				end
			end
			return
		end

		local plate = Resolve(unit)
		if event == "NAME_PLATE_UNIT_REMOVED" then
			local layer = units[unit] or (plate and layers[plate])
			if callback then
				callback(layer, event, unit)
			end
			units[unit] = nil
			ClearLayer(layer)
			return
		end
		if not plate then
			return
		end
		local layer = layers[plate]
		if not layer then
			-- This is a visual-only, unprotected child.  Never write unit or click
			-- attributes onto Blizzard's protected nameplate hierarchy.
			layer = CreateFrame("Frame", nil, plate)
			layer:EnableMouse(false)
			layer.isNamePlate = true
			layers[plate] = layer
			Initialize(layer, unit, true, "nameplate")
		else
			self:SetUnit(layer, unit, false, true)
			layer:Show()
		end
		units[unit] = layer
		if callback then
			callback(layer, event, unit)
		end
		layer:HydraUpdateAll(event)
	end)
	self.NamePlateDriver = driver
end

function Runtime:GetNamePlateLayer(plate)
	return self.NamePlateLayers and self.NamePlateLayers[plate]
end
