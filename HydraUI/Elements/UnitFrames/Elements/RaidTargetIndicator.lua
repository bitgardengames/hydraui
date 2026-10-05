local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

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
	indicator.ForceUpdate = UF:CreateForceUpdate(indicator, UpdateRaidTarget)
	frame:RegisterEvent("RAID_TARGET_UPDATE", UpdateRaidTarget, true)

	return true
end

local function DisableRaidTarget(frame)
	frame.RaidTargetIndicator:Hide()
	frame:UnregisterEvent("RAID_TARGET_UPDATE", UpdateRaidTarget)
end

UF:RegisterElement("RaidTargetIndicator", {
	update = UpdateRaidTarget,
	enable = EnableRaidTarget,
	disable = DisableRaidTarget,
})
