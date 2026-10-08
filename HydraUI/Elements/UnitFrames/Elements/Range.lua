local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local RangeEnabledFrames, RangeFrames, RangeDriver = {}, {}, nil

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
	local alphaSet

	if connected then
		inRange, checked = UnitInRange(frame.unit)

		if IsInaccessible(inRange) then
			if frame.SetAlphaFromBoolean and not IsInaccessible(checked) and checked then
				frame:SetAlphaFromBoolean(inRange, range.insideAlpha, range.outsideAlpha)
				alphaSet = true
			end

			inRange = nil
			checked = nil
		end

		if IsInaccessible(checked) then
			checked = nil
		end
	end

	local outsideRange = connected and checked and not inRange

	if not alphaSet then
		frame:SetAlpha(outsideRange and range.outsideAlpha or range.insideAlpha)
	end

	if range.PostUpdate then
		range:PostUpdate(frame, inRange, checked, connected)
	end
end

local function RangeOnUpdate(driver, delta)
	driver.Elapsed = driver.Elapsed + delta

	if driver.Elapsed < 0.2 then
		return
	end

	driver.Elapsed = 0

	for frame in pairs(RangeFrames) do
		UpdateRange(frame)
	end
end

local function CreateRangeDriver()
	local driver = CreateFrame("Frame")

	driver.Elapsed = 0

	return driver
end

local function StartRangeDriver()
	RangeDriver = RangeDriver or CreateRangeDriver()

	if not RangeDriver:GetScript("OnUpdate") then
		RangeDriver.Elapsed = 0
		RangeDriver:SetScript("OnUpdate", RangeOnUpdate)
	end
end

local function StopRangeDriver()
	if RangeDriver and not next(RangeFrames) then
		RangeDriver:SetScript("OnUpdate", nil)
		RangeDriver.Elapsed = 0
	end
end

local function RangeOnShow(frame)
	if RangeEnabledFrames[frame] then
		RangeFrames[frame] = true
		StartRangeDriver()
		UpdateRange(frame)
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
	range.ForceUpdate = function()
		UpdateRange(frame)
	end
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
	update = UpdateRange,
	enable = EnableRange,
	disable = DisableRange,
})
