local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

local function Run(element, fallback, frame, ...)
	return (element.Override or fallback)(frame, ...)
end

local function Unregister(frame, handler, ...)
	for i = 1, select("#", ...) do
		frame:UnregisterEvent(select(i, ...), handler)
	end
end

local function HealthColor(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local element, color = frame.Health

	if element.colorDisconnected and not UnitIsConnected(unit) then
		color = frame.colors.disconnected
	elseif element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
		color = frame.colors.tapped
	elseif element.colorThreat and not UnitPlayerControlled(unit) then
		local threat = UnitThreatSituation("player", unit)
		color = (threat and frame.colors.threat[threat]) or frame.colors.reaction[UnitReaction(unit, "player") or 5]
	elseif element.colorClass and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		color = frame.colors.class[class]
	elseif element.colorSelection and UnitSelectionColor then
		local r, g, b = UnitSelectionColor(unit)
		color = {r, g, b}
	elseif element.colorReaction then
		color = frame.colors.reaction[UnitReaction(unit, "player") or 5]
	elseif element.colorHealth then
		color = frame.colors.health
	end

	local r, g, b

	if color then
		r, g, b = color[1], color[2], color[3]
	end

	if b then
		element:SetStatusBarColor(r, g, b)

		if element.bg then
			local m = element.bg.multiplier or 1
			element.bg:SetVertexColor(r*m, g*m, b*m)
		end
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function UpdateHealth(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local bar, current, maximum = frame.Health, UnitHealth(unit), UnitHealthMax(unit)

	if bar.PreUpdate then
		bar:PreUpdate(unit)
	end

	bar:SetMinMaxValues(0, maximum)
	bar:SetValue(UnitIsConnected(unit) and current or maximum)
	bar.cur, bar.max = current, maximum

	local inaccessible = HydraUI.IsMainline and issecretvalue(current) and not canaccessvalue(current)

	if not inaccessible and current == 0 then
		if frame.HealBar then
			frame.HealBar:SetValue(0)
		end

		if frame.AbsorbsBar then
			frame.AbsorbsBar:SetValue(0)
		end
	end

	if bar.PostUpdate then
		bar:PostUpdate(unit, current, maximum)
	end
end

local function HealthPath(frame, event, unit, ...)
	local bar = frame.Health
	local updateColor = bar.UpdateColor or HealthColor

	Run(bar, UpdateHealth, frame, event, unit, ...)
	updateColor(frame, event, unit)
end

local function EnableHealth(frame)
	local bar = frame.Health

	if not bar then
		return
	end

	bar.__owner, bar.ForceUpdate = frame, UF:CreateForceUpdate(bar, HealthPath)

	for _, event in ipairs({HydraUI.IsMainline and "UNIT_HEALTH" or "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH"}) do
		frame:RegisterEvent(event, HealthPath)
	end

	for _, event in ipairs({"UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_THREAT_LIST_UPDATE"}) do
		frame:RegisterEvent(event, HealthColor)
	end

	bar:Show()

	return true
end

local function DisableHealth(frame)
	frame.Health:Hide()
	Unregister(frame, HealthPath, "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH")
	Unregister(frame, HealthColor, "UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_THREAT_LIST_UPDATE")
end

UF:RegisterElement("Health", {
	update = HealthPath,
	enable = EnableHealth,
	disable = DisableHealth,
})
