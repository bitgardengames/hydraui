local _, ns = ...
local HydraUI = ns:get()
local Handlers = ns.UnitFrameComponentHandlers

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function Unregister(frame, handler, ...)
	for i = 1, select("#", ...) do
		frame:UnregisterEvent(select(i, ...), handler)
	end
end

local function UpdatePrediction(frame,event,unit)
	if unit and unit~=frame.unit then
		return
	end
	local health, maximum=UnitHealth(frame.unit),UnitHealthMax(frame.unit)
	local incoming=UnitGetIncomingHeals and (UnitGetIncomingHeals(frame.unit) or 0) or 0
	local inaccessible = HydraUI.IsMainline and ((issecretvalue(health) and not canaccessvalue(health)) or (issecretvalue(maximum) and not canaccessvalue(maximum)) or (issecretvalue(incoming) and not canaccessvalue(incoming)))
	if frame.HealBar then
		frame.HealBar:SetMinMaxValues(0,maximum)
		frame.HealBar:SetValue(not inaccessible and health > 0 and math.min(incoming, maximum-health) or 0)
	end
	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetMinMaxValues(0,maximum)
	local absorbs=UnitGetTotalAbsorbs(frame.unit) or 0
	local secret=HydraUI.IsMainline and issecretvalue(absorbs) and not canaccessvalue(absorbs)
		frame.AbsorbsBar:SetValue(not inaccessible and not secret and health > 0 and math.min(absorbs,maximum-health) or 0)
	end
end
local function EnablePrediction(frame) if not frame.HealBar then return end
	frame.HealBar.__owner=frame
	frame.HealBar.ForceUpdate=Force(frame.HealBar,UpdatePrediction)
	frame:RegisterEvent("UNIT_HEAL_PREDICTION",UpdatePrediction)
	frame:RegisterEvent("UNIT_MAXHEALTH",UpdatePrediction)
	frame:RegisterEvent("UNIT_HEALTH",UpdatePrediction)
	frame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED",UpdatePrediction)
	frame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED",UpdatePrediction)
	frame.HealBar:SetMinMaxValues(0,1); frame.HealBar:SetValue(0); frame.HealBar:Show()
	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetMinMaxValues(0,1); frame.AbsorbsBar:SetValue(0); frame.AbsorbsBar:Show()
	end
	return true end
Handlers.HealPrediction={update=UpdatePrediction,enable=EnablePrediction,disable=function(frame) frame.HealBar:Hide()
	if frame.AbsorbsBar then
		frame.AbsorbsBar:Hide()
	end
	Unregister(frame,UpdatePrediction,"UNIT_HEAL_PREDICTION","UNIT_MAXHEALTH","UNIT_HEALTH","UNIT_ABSORB_AMOUNT_CHANGED","UNIT_HEAL_ABSORB_AMOUNT_CHANGED") end}
