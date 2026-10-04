local _, ns = ...
local HydraUI = ns:get()
local UnitFrames = HydraUI.UnitFrames

local function Force(element, update)
	return function()
		update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function Install(name, events, update, enable)
	local function Path(frame, ...)
		local element = frame[name]
		return (element.Override or update)(frame, ...)
	end
	UnitFrames:RegisterElement(name, {
		update = Path,
		enable = function(frame)
			local element = frame[name]
			if not element or (enable and enable(frame, element) == false) then
				return
			end
			element.__owner, element.ForceUpdate = frame, Force(element, Path)
			for i = 1, #events do
				frame:RegisterEvent(events[i][1], Path, events[i][2])
			end
			Path(frame, "ElementEnable", frame.unit)
			return true
		end,
		disable = function(frame)
			frame[name]:Hide()
			for i = 1, #events do
				frame:UnregisterEvent(events[i][1], Path)
			end
		end,
	})
end

local function TextureIndicator(name, predicate, texture)
	Install(name, {
		{"PLAYER_ENTERING_WORLD", true},
		{"GROUP_ROSTER_UPDATE", true},
		{"PLAYER_UPDATE_RESTING", true},
		{"UNIT_FLAGS"},
		{"UNIT_CLASSIFICATION_CHANGED"},
		{"INCOMING_SUMMON_CHANGED"},
	}, function(frame)
		local element = frame[name]
		if predicate(frame.unit) then
			element:Show()
		else
			element:Hide()
		end
	end, function(frame, element)
		if texture and element:IsObjectType("Texture") and not element:GetTexture() then
			element:SetTexture(texture)
		end
	end)
end

TextureIndicator("RestingIndicator", function(unit)
	return UnitIsUnit(unit, "player") and IsResting()
end, [[Interface\CharacterFrame\UI-StateIcon]])
TextureIndicator("QuestIndicator", function(unit)
	return UnitIsQuestBoss and UnitIsQuestBoss(unit)
end, [[Interface\TargetingFrame\PortraitQuestBadge]])
TextureIndicator("EliteIndicator", function(unit)
	local classification = UnitClassification(unit)
	return classification == "elite" or classification == "worldboss" or classification == "rareelite"
end)
TextureIndicator("RaidRoleIndicator", function(unit)
	return GetPartyAssignment and (GetPartyAssignment("MAINTANK", unit) or GetPartyAssignment("MAINASSIST", unit))
end)
TextureIndicator("SummonIndicator", function(unit)
	return C_IncomingSummon and C_IncomingSummon.HasIncomingSummon(unit)
end, [[Interface\RaidFrame\Raid-Icon-SummonPending]])
TextureIndicator("PvPClassificationIndicator", function(unit)
	return UnitPVPName and UnitPVPName(unit) ~= nil and UnitIsPVP(unit)
end)

local function UpdateResource(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.__resourceElement
	local powerType = element.powerType
	local current, maximum = UnitPower(frame.unit, powerType), UnitPowerMax(frame.unit, powerType)
	if element.PreUpdate then
		element:PreUpdate(frame.unit)
	end
	element:SetMinMaxValues(0, maximum)
	element:SetValue(current)
	element.cur, element.max = current, maximum
	element:SetShown(maximum and maximum > 0)
	if element.PostUpdate then
		element:PostUpdate(frame.unit, current, maximum)
	end
end

local function Resource(name, powerType)
	Install(name, {{"UNIT_POWER_UPDATE"}, {"UNIT_POWER_FREQUENT"}, {"UNIT_MAXPOWER"}, {"UNIT_DISPLAYPOWER"}}, function(frame, ...)
		frame.__resourceElement = frame[name]
		UpdateResource(frame, ...)
		frame.__resourceElement = nil
	end, function(_, element)
		element.powerType = element.powerType or powerType
	end)
end

Resource("AlternativePower", Enum and Enum.PowerType and (Enum.PowerType.Alternate or 10) or 10)
Resource("AdditionalPower", Enum and Enum.PowerType and (Enum.PowerType.Mana or 0) or 0)
Resource("Happiness")

local function UpdatePoints(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame[frame.__pointsName]
	local current = UnitPower(frame.unit, element.powerType)
	for i = 1, #element do
		element[i]:SetShown(i <= current)
	end
	element.cur = current
	if element.PostUpdate then
		element:PostUpdate(frame.unit, current, #element)
	end
end

local function Points(name, powerType)
	Install(name, {{"UNIT_POWER_UPDATE"}, {"UNIT_POWER_FREQUENT"}, {"UNIT_MAXPOWER"}}, function(frame, ...)
		frame.__pointsName = name
		UpdatePoints(frame, ...)
		frame.__pointsName = nil
	end, function(frame, element)
		-- Player.lua owns the resource container and its rune, charged-point, and client-specific behavior; aliases should not install duplicate updaters.
		if frame.ClassResource == element then
			return false
		end
		element.powerType = element.powerType or powerType
	end)
end

Points("Runes", Enum and Enum.PowerType and Enum.PowerType.Runes or 5)
Points("Totems")
Points("ClassPower")
Points("ComboPoints", Enum and Enum.PowerType and Enum.PowerType.ComboPoints or 4)
Points("HolyPower", Enum and Enum.PowerType and Enum.PowerType.HolyPower or 9)
Points("SoulShards", Enum and Enum.PowerType and Enum.PowerType.SoulShards or 7)

Install("HealComm", {{"UNIT_HEAL_PREDICTION"}}, function(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.HealComm
	local incoming = UnitGetIncomingHeals and UnitGetIncomingHeals(frame.unit, "player") or 0
	local total = UnitGetIncomingHeals and UnitGetIncomingHeals(frame.unit) or 0
	local others = total - incoming
	if element.myBar then
		element.myBar:SetValue(incoming)
	end
	if element.otherBar then
		element.otherBar:SetValue(others)
	end
	element.myHeal, element.otherHeal = incoming, others
	if element.PostUpdate then
		element:PostUpdate(frame.unit, incoming, others)
	end
end)

Install("Stagger", {{"UNIT_ABSORB_AMOUNT_CHANGED"}, {"UNIT_AURA"}, {"UNIT_MAXHEALTH"}}, function(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.Stagger
	local current = UnitStagger and UnitStagger(frame.unit) or 0
	local maximum = UnitHealthMax(frame.unit)
	element:SetMinMaxValues(0, maximum)
	element:SetValue(current)
	element.cur, element.max = current, maximum
	element:SetShown(current > 0)
	if element.PostUpdate then
		element:PostUpdate(frame.unit, current, maximum)
	end
end)
