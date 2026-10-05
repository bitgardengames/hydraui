local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local Handlers = UF.ElementHandlers

local PredictionEvents = {
	"UNIT_HEAL_PREDICTION",
	"UNIT_MAXHEALTH",
	"UNIT_HEALTH",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	"UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
}

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function IsInaccessible(value)
	return HydraUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function UpdatePrediction(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local health = UnitHealth(frame.unit)
	local maximum = UnitHealthMax(frame.unit)
	local incoming = UnitGetIncomingHeals and (UnitGetIncomingHeals(frame.unit) or 0) or 0
	local inaccessible = IsInaccessible(health) or IsInaccessible(maximum) or IsInaccessible(incoming)

	if frame.HealBar then
		frame.HealBar:SetMinMaxValues(0, maximum)
		frame.HealBar:SetValue(not inaccessible and health > 0 and math.min(incoming, maximum - health) or 0)
	end

	if frame.AbsorbsBar then
		local absorbs = UnitGetTotalAbsorbs(frame.unit) or 0
		frame.AbsorbsBar:SetMinMaxValues(0, maximum)
		frame.AbsorbsBar:SetValue(not inaccessible and not IsInaccessible(absorbs) and health > 0 and math.min(absorbs, maximum - health) or 0)
	end
end

local function EnablePrediction(frame)
	local heal = frame.HealBar

	if not heal then
		return
	end

	heal.__owner = frame
	heal.ForceUpdate = Force(heal, UpdatePrediction)

	for _, event in ipairs(PredictionEvents) do
		frame:RegisterEvent(event, UpdatePrediction)
	end

	heal:SetMinMaxValues(0, 1)
	heal:SetValue(0)
	heal:Show()

	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetMinMaxValues(0, 1)
		frame.AbsorbsBar:SetValue(0)
		frame.AbsorbsBar:Show()
	end

	return true
end

local function DisablePrediction(frame)
	frame.HealBar:Hide()

	if frame.AbsorbsBar then
		frame.AbsorbsBar:Hide()
	end

	for _, event in ipairs(PredictionEvents) do
		frame:UnregisterEvent(event, UpdatePrediction)
	end
end

Handlers.HealPrediction = {
	update = UpdatePrediction,
	enable = EnablePrediction,
	disable = DisablePrediction,
}