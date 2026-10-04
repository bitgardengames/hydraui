local _, ns = ...
local Handlers = ns.UnitFrameElementHandlers

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function UpdateRaidTarget(frame)
	local indicator = frame.RaidTargetIndicator
	if indicator.PreUpdate then
		indicator:PreUpdate()
	end

	local index = GetRaidTargetIndex(frame.unit)
	if index then
		SetRaidTargetIconTexture(indicator, index)
		indicator:Show()
	else
		indicator:Hide()
	end

	if indicator.PostUpdate then
		indicator:PostUpdate(index)
	end
end

local function EnableRaidTarget(frame)
	local indicator = frame.RaidTargetIndicator
	if not indicator then
		return
	end

	indicator.__owner = frame
	indicator.ForceUpdate = Force(indicator, UpdateRaidTarget)
	frame:RegisterEvent("RAID_TARGET_UPDATE", UpdateRaidTarget, true)
	return true
end

local function DisableRaidTarget(frame)
	frame.RaidTargetIndicator:Hide()
	frame:UnregisterEvent("RAID_TARGET_UPDATE", UpdateRaidTarget)
end

Handlers.RaidTargetIndicator = {
	update = UpdateRaidTarget,
	enable = EnableRaidTarget,
	disable = DisableRaidTarget,
}
