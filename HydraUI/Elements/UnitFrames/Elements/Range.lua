local _, ns = ...
local Handlers = ns.UnitFrameComponentHandlers
local RangeFrames, RangeDriver = {}, nil

local function UpdateRange(frame)
	local range = frame.Range
	if range.PreUpdate then
		range:PreUpdate()
	end

	local inRange, checked = UnitInRange(frame.unit)
	local connected = UnitIsConnected(frame.unit)
	local outsideRange = connected and checked and not inRange
	frame:SetAlpha(outsideRange and range.outsideAlpha or range.insideAlpha)

	if range.PostUpdate then
		range:PostUpdate(frame, inRange, checked, connected)
	end
end

local function CreateRangeDriver()
	local driver = CreateFrame("Frame")
	local elapsed = 0
	driver:SetScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta
		if elapsed < 0.2 then
			return
		end

		elapsed = 0
		for frame in pairs(RangeFrames) do
			if frame:IsShown() then
				UpdateRange(frame)
			end
		end
	end)
	return driver
end

local function EnableRange(frame)
	local range = frame.Range
	if not range then
		return
	end

	range.__owner = frame
	range.insideAlpha = range.insideAlpha or 1
	range.outsideAlpha = range.outsideAlpha or 0.55
	RangeFrames[frame] = true
	RangeDriver = RangeDriver or CreateRangeDriver()
	return true
end

local function DisableRange(frame)
	RangeFrames[frame] = nil
	frame:SetAlpha(frame.Range.insideAlpha)
end

Handlers.Range = {
	enable = EnableRange,
	disable = DisableRange,
}
