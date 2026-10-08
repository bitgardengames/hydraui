local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

local ThreatEvents = {
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_THREAT_LIST_UPDATE",
}

local function UpdateThreat(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local indicator = frame.ThreatIndicator

	if indicator.PreUpdate then
		indicator:PreUpdate(frame.unit)
	end

	local feedbackUnit = indicator.feedbackUnit
	local status

	if not feedbackUnit or feedbackUnit == frame.unit or UnitExists(feedbackUnit) then
		status = UnitThreatSituation(feedbackUnit or frame.unit, feedbackUnit and frame.unit or nil)
	end

	local color = status and status > 0 and frame.colors.threat[status]

	if color then
		if indicator.SetBackdropBorderColor then
			indicator:SetBackdropBorderColor(unpack(color))
		elseif indicator.SetVertexColor then
			indicator:SetVertexColor(unpack(color))
		end

		indicator:Show()
	else
		indicator:Hide()
	end

	if indicator.PostUpdate then
		indicator:PostUpdate(frame.unit, status, color and color[1], color and color[2], color and color[3])
	end
end

local function EnableThreat(frame)
	local indicator = frame.ThreatIndicator

	if not indicator then
		return
	end

	indicator.__owner = frame
	indicator.ForceUpdate = UF:CreateForceUpdate(indicator, UpdateThreat)

	for _, event in ipairs(ThreatEvents) do
		frame:RegisterEvent(event, UpdateThreat)
	end

	return true
end

local function DisableThreat(frame)
	frame.ThreatIndicator:Hide()

	for _, event in ipairs(ThreatEvents) do
		frame:UnregisterEvent(event, UpdateThreat)
	end
end

UF:RegisterElement("ThreatIndicator", {
	update = UpdateThreat,
	enable = EnableThreat,
	disable = DisableThreat,
})
