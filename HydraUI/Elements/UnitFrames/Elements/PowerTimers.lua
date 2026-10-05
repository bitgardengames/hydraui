local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local Handlers = UF.ElementHandlers

local function ManaOnUpdate(element, elapsed)
	element.elapsed = element.elapsed + elapsed
	element:SetValue(element.elapsed)

	if element.elapsed >= element.max then
		element.LastPower = UnitPower("player")
		element:Hide()
		element:SetScript("OnUpdate", nil)
	end
end

local function UpdateMana(frame, _, unit)
	if unit and unit ~= "player" then
		return
	end

	local element = frame.ManaTimer
	local power = UnitPower("player")

	if UnitPowerType("player") ~= Enum.PowerType.Mana or power == UnitPowerMax("player") then
		element.LastPower = power
		element:Hide()
		element:SetScript("OnUpdate", nil)

		return
	end

	if element.LastPower > power then
		element.max = 5.5
	elseif power > element.LastPower then
		element.max = 2
	else
		return
	end

	element.elapsed = 0
	element:SetMinMaxValues(0, element.max)
	element:Show()
	element:SetScript("OnUpdate", ManaOnUpdate)
	element.LastPower = power
end

local function EnableMana(frame)
	local element = frame.ManaTimer

	if HydraUI.IsMists or HydraUI.IsMainline or not element or not UnitIsUnit(frame.unit, "player") then
		return
	end

	element.__owner = frame
	element.LastPower = UnitPower("player")
	element.ForceUpdate = function()
		UpdateMana(frame, "ForceUpdate", "player")
	end

	frame:RegisterEvent("UNIT_POWER_FREQUENT", UpdateMana)
	element:Hide()

	return true
end

local function DisableMana(frame)
	frame:UnregisterEvent("UNIT_POWER_FREQUENT", UpdateMana)
	frame.ManaTimer:Hide()
	frame.ManaTimer:SetScript("OnUpdate", nil)
end

Handlers.ManaRegen = {
	update = UpdateMana,
	enable = EnableMana,
	disable = DisableMana,
}

local lastEnergyTick = GetTime()
local lastEnergy = 0

local function EnergyOnUpdate(element)
	local power = UnitPower("player")
	local currentTime = GetTime()

	if power > lastEnergy or currentTime - lastEnergyTick >= 2 then
		lastEnergyTick = currentTime
	end

	element:SetValue(currentTime - lastEnergyTick)
	lastEnergy = power
end

local function UpdateEnergy(frame)
	EnergyOnUpdate(frame.EnergyTick)
end

local function EnableEnergy(frame)
	local element = frame.EnergyTick

	if not (HydraUI.IsVanilla or HydraUI.IsTBC) or not element or not UnitIsUnit(frame.unit, "player") then
		return
	end

	local class = select(2, UnitClass("player"))

	if class ~= "ROGUE" and class ~= "DRUID" then
		return
	end

	element.__owner = frame
	element.ForceUpdate = function()
		EnergyOnUpdate(element)
	end
	element:SetMinMaxValues(0, 2)
	element:SetScript("OnUpdate", EnergyOnUpdate)
	element:Show()

	return true
end

local function DisableEnergy(frame)
	frame.EnergyTick:Hide()
	frame.EnergyTick:SetScript("OnUpdate", nil)
end

Handlers.EnergyTick = {
	update = UpdateEnergy,
	enable = EnableEnergy,
	disable = DisableEnergy,
}

local function FindSpellCost(unit, spellID)
	local costs = C_Spell.GetSpellPowerCost(spellID)

	if not costs then
		return 0
	end

	local powerType = UnitPowerType(unit)

	for _, costInfo in next, costs do
		if costInfo.type == powerType and (#costs == 1 or costInfo.hasRequiredAura) then
			return costInfo.cost
		end
	end

	return 0
end

local function UpdatePrediction(frame, event, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local element = frame.PowerPrediction
	local _, _, _, startTime, endTime, _, _, _, spellID = UnitCastingInfo(frame.unit)
	local cost = 0

	if event == "UNIT_SPELLCAST_START" and startTime ~= endTime and spellID then
		cost = FindSpellCost(frame.unit, spellID)
		element.mainCost = cost
	elseif spellID then
		cost = element.mainCost or 0
	else
		element.mainCost = 0
	end

	if element.mainBar then
		element.mainBar:SetMinMaxValues(0, UnitPowerMax(frame.unit))
		element.mainBar:SetValue(cost)
		element.mainBar:SetShown(cost > 0)
	end
end

local PredictionEvents = {
	"UNIT_DISPLAYPOWER",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_SUCCEEDED",
}

local function EnablePrediction(frame, unit)
	local element = frame.PowerPrediction

	if not element or not C_Spell or not UnitIsUnit(unit, "player") then
		return
	end

	element.__owner = frame
	element.ForceUpdate = function()
		UpdatePrediction(frame, "ForceUpdate", frame.unit)
	end

	for i = 1, #PredictionEvents do
		frame:RegisterEvent(PredictionEvents[i], UpdatePrediction)
	end

	return true
end

local function DisablePrediction(frame)
	for i = 1, #PredictionEvents do
		frame:UnregisterEvent(PredictionEvents[i], UpdatePrediction)
	end

	if frame.PowerPrediction.mainBar then
		frame.PowerPrediction.mainBar:Hide()
	end
end

Handlers.PowerPrediction = {
	update = UpdatePrediction,
	enable = EnablePrediction,
	disable = DisablePrediction,
}
