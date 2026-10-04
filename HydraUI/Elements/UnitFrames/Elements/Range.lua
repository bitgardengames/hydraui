local _, ns = ...
local HydraUI = ns:get()
local Handlers = ns.UnitFrameComponentHandlers
local RangeFrames, RangeDriver = {}, nil

local function UpdateRange(frame) local e=frame.Range
	if e.PreUpdate then
		e:PreUpdate()
	end
	local inRange,checked=UnitInRange(frame.unit)
	local connected=UnitIsConnected(frame.unit)
	frame:SetAlpha(connected and checked and not inRange and (e.outsideAlpha or .55) or (e.insideAlpha or 1))
	if e.PostUpdate then
		e:PostUpdate(frame,inRange,checked,connected) end
	end
local function EnableRange(frame) if not frame.Range then return end
	frame.Range.__owner=frame; frame.Range.insideAlpha=frame.Range.insideAlpha or 1; frame.Range.outsideAlpha=frame.Range.outsideAlpha or .55
	RangeFrames[frame]=true
	if not RangeDriver then RangeDriver=CreateFrame("Frame")
	local elapsed=0
	RangeDriver:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt
	if elapsed>=.2 then elapsed=0
	for owner in pairs(RangeFrames) do
		if owner:IsShown() then UpdateRange(owner) end end end end)
	end
	return true end
Handlers.Range={enable=EnableRange,disable=function(frame) RangeFrames[frame]=nil
	frame:SetAlpha(frame.Range.insideAlpha or 1) end}
