local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local Handlers = UF.ElementHandlers
local RangeFrames, RangeDriver = {}, nil

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
