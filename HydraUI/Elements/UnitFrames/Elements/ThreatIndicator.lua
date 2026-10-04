local _, ns = ...
local HydraUI = ns:get()
local Handlers = ns.UnitFrameComponentHandlers

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function UpdateThreat(frame,event,unit)
	if unit and unit ~= frame.unit then
		return
	end
	local e=frame.ThreatIndicator
	if e.PreUpdate then
		e:PreUpdate(frame.unit)
	end
	local feedback = e.feedbackUnit
	local status
	if not feedback or feedback == frame.unit or UnitExists(feedback) then
		status=UnitThreatSituation(feedback or frame.unit, feedback and frame.unit or nil)
	end
	local color=status and frame.colors.threat[status]
		if color then
		if e.SetVertexColor then
			e:SetVertexColor(unpack(color))
		end
		e:Show()
	else
		e:Hide()
	end
	if e.PostUpdate then
		e:PostUpdate(frame.unit,status,color and color[1],color and color[2],color and color[3])
	end
end
local function EnableThreat(frame) local e=frame.ThreatIndicator
	if not e then
		return
	end
	e.__owner,e.ForceUpdate=frame,Force(e,UpdateThreat)
	frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE",UpdateThreat)
	frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE",UpdateThreat)
	return true end
Handlers.ThreatIndicator={update=UpdateThreat,enable=EnableThreat,disable=function(frame)
	frame.ThreatIndicator:Hide()
	Unregister(frame, UpdateThreat, "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE")
end}
