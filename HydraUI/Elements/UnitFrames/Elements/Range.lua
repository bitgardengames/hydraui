local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local RangeEnabledFrames, RangeFrames, RangeTicker = {}, {}, nil

local function IsInaccessible(value)
	return HydraUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function UpdateRange(frame)
	local range = frame.Range

	if range.PreUpdate then
		range:PreUpdate()
	end

	local connected = UnitIsConnected(frame.unit)

	if IsInaccessible(connected) then
		connected = nil
	end

	local inRange, checked

	if connected then
		inRange, checked = UnitInRange(frame.unit)

		if IsInaccessible(inRange) then
			inRange = nil
		end

		if IsInaccessible(checked) then
			checked = nil
		end
	end

	local outsideRange = connected and checked and not inRange

	frame:SetAlpha(outsideRange and range.outsideAlpha or range.insideAlpha)

	if range.PostUpdate then
		range:PostUpdate(frame, inRange, checked, connected)
	end
end

local function UpdateRanges()
	for frame in pairs(RangeFrames) do
		UpdateRange(frame)
	end
end

local function StartRangeDriver()
	if not RangeTicker then
		RangeTicker = C_Timer.NewTicker(0.2, UpdateRanges)
	end
end

local function StopRangeDriver()
	if RangeTicker and not next(RangeFrames) then
		RangeTicker:Cancel()
		RangeTicker = nil
	end
end

local function RangeOnShow(frame)
	if RangeEnabledFrames[frame] then
		RangeFrames[frame] = true
		StartRangeDriver()
	end
end

local function RangeOnHide(frame)
	RangeFrames[frame] = nil
	StopRangeDriver()
end

local function EnableRange(frame)
	local range = frame.Range

	if not range then
		return
	end

	range.__owner = frame
	range.insideAlpha = range.insideAlpha or 1
	range.outsideAlpha = range.outsideAlpha or 0.55
	RangeEnabledFrames[frame] = true

	if not frame.RangeDriverHooks then
		frame:HookScript("OnShow", RangeOnShow)
		frame:HookScript("OnHide", RangeOnHide)
		frame.RangeDriverHooks = true
	end

	if frame:IsVisible() then
		RangeOnShow(frame)
	end

	return true
end

local function DisableRange(frame)
	RangeEnabledFrames[frame] = nil
	RangeFrames[frame] = nil
	frame:SetAlpha(frame.Range.insideAlpha)
	StopRangeDriver()
end

UF:RegisterElement("Range", {
	enable = EnableRange,
	disable = DisableRange,
})
