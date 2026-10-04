local _, ns = ...
local Handlers = ns.UnitFrameComponentHandlers

local PowerEvents = {
	"UNIT_MAXPOWER",
	"UNIT_DISPLAYPOWER",
	"UNIT_POWER_BAR_HIDE",
	"UNIT_POWER_BAR_SHOW",
	"UNIT_CONNECTION",
	"UNIT_FACTION",
	"UNIT_FLAGS",
	"UNIT_THREAT_LIST_UPDATE",
}

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function SetPowerColor(frame, bar, unit, powerType, token)
	local color
	if bar.colorPower then
		color = frame.colors.power[token] or frame.colors.power[powerType]
	elseif bar.colorClass and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		color = frame.colors.class[class]
	elseif bar.colorReaction then
		color = frame.colors.reaction[UnitReaction(unit, "player") or 5]
	end

	if color then
		bar:SetStatusBarColor(color[1], color[2], color[3])
		if bar.bg then
			local multiplier = bar.bg.multiplier or 1
			bar.bg:SetVertexColor(color[1] * multiplier, color[2] * multiplier, color[3] * multiplier)
		end
	end
	return color
end

local function UpdatePower(frame, _, unit)
	if unit ~= frame.unit then
		return
	end

	local bar = frame.Power
	local powerType, token = UnitPowerType(unit)
	local displayType, minimum
	if bar.displayAltPower and bar.GetDisplayPower then
		displayType, minimum = bar:GetDisplayPower(unit)
	end
	local current = UnitPower(unit, displayType)
	local maximum = UnitPowerMax(unit, displayType)

	if bar.PreUpdate then
		bar:PreUpdate(unit)
	end
	bar:SetMinMaxValues(minimum or 0, maximum)
	bar:SetValue(UnitIsConnected(unit) and current or maximum)
	bar.cur, bar.min, bar.max, bar.displayType = current, minimum, maximum, displayType

	local color = SetPowerColor(frame, bar, unit, powerType, token)
	if bar.PostUpdateColor then
		bar:PostUpdateColor(unit, color and color[1], color and color[2], color and color[3])
	end
	if bar.PostUpdate then
		bar:PostUpdate(unit, current, minimum, maximum)
	end
end

local function EnablePower(frame)
	local bar = frame.Power
	if not bar then
		return
	end

	bar.__owner = frame
	bar.ForceUpdate = Force(bar, UpdatePower)
	frame:RegisterEvent(bar.frequentUpdates and "UNIT_POWER_FREQUENT" or "UNIT_POWER_UPDATE", UpdatePower)
	for _, event in ipairs(PowerEvents) do
		frame:RegisterEvent(event, UpdatePower)
	end
	bar:Show()
	return true
end

local function DisablePower(frame)
	frame.Power:Hide()
	frame:UnregisterEvent("UNIT_POWER_UPDATE", UpdatePower)
	frame:UnregisterEvent("UNIT_POWER_FREQUENT", UpdatePower)
	for _, event in ipairs(PowerEvents) do
		frame:UnregisterEvent(event, UpdatePower)
	end
end

Handlers.Power = {
	update = UpdatePower,
	enable = EnablePower,
	disable = DisablePower,
}
