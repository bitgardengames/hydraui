local _, ns = ...
local HydraUI = ns:get()
local Handlers = ns.UnitFrameComponentHandlers

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function UpdateRaidTarget(frame) local e=frame.RaidTargetIndicator
	if e.PreUpdate then
		e:PreUpdate()
	end
	local index=GetRaidTargetIndex(frame.unit)
	if index then SetRaidTargetIconTexture(e,index)
	e:Show() else e:Hide() end
	if e.PostUpdate then
		e:PostUpdate(index) end
	end
local function EnableRaidTarget(frame) local e=frame.RaidTargetIndicator
	if not e then
		return
	end
	e.__owner,e.ForceUpdate=frame,Force(e,UpdateRaidTarget)
	frame:RegisterEvent("RAID_TARGET_UPDATE",UpdateRaidTarget,true)
	return true end
Handlers.RaidTargetIndicator={update=UpdateRaidTarget,enable=EnableRaidTarget,disable=function(frame) frame.RaidTargetIndicator:Hide(); frame:UnregisterEvent("RAID_TARGET_UPDATE",UpdateRaidTarget) end}
