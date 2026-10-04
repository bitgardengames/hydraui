local _, ns = ...
local HydraUI = ns:get()
local Handlers = ns.UnitFrameElementHandlers

local active = {}
local driver = CreateFrame("Frame")
local min, max, abs = math.min, math.max, math.abs

local function IsSecret(value)
	return HydraUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function Animate()
	for bar, target in pairs(active) do
		local current = bar:GetValue()
		if IsSecret(current) or IsSecret(target) then
			bar:SetValueImmediately(target)
			active[bar] = nil
		else
			local value = current + min((target - current) / 3, max(target - current, 30 / GetFramerate()))
			if value ~= value then
				value = target
			end
			bar:SetValueImmediately(value)
			if current == target or abs(value - target) < 2 then
				bar:SetValueImmediately(target)
				active[bar] = nil
			end
		end
	end
	if not next(active) then
		driver:SetScript("OnUpdate", nil)
	end
end

local function SmoothValue(bar, value)
	local _, maximum = bar:GetMinMaxValues()
	if IsSecret(value) or IsSecret(maximum) or (bar.__smoothMaximum and bar.__smoothMaximum ~= maximum) then
		bar:SetValueImmediately(value)
		active[bar] = nil
	else
		active[bar] = value
		driver:SetScript("OnUpdate", Animate)
	end
	bar.__smoothMaximum = IsSecret(maximum) and nil or maximum
end

local function SmoothBar(_, bar)
	if not bar or bar.SetValueImmediately then
		return
	end
	bar.SetValueImmediately = bar.SetValue
	bar.SetValue = SmoothValue
end

local function Enable(frame)
	frame.SmoothBar = SmoothBar
	-- Health and power historically opted into smoothing unless a layout
	-- explicitly disabled it.
	if frame.Health and frame.Health.Smooth ~= false then
		frame:SmoothBar(frame.Health)
	end
	if frame.Power and frame.Power.Smooth ~= false then
		frame:SmoothBar(frame.Power)
	end
	return frame.Health ~= nil or frame.Power ~= nil
end

local function Restore(bar)
	if bar and bar.SetValueImmediately then
		bar.SetValue = bar.SetValueImmediately
		bar.SetValueImmediately = nil
		bar.__smoothMaximum = nil
		active[bar] = nil
	end
end

Handlers.Smooth = {
	update = function() end,
	enable = Enable,
	disable = function(frame)
		Restore(frame.Health)
		Restore(frame.Power)
		if not next(active) then
			driver:SetScript("OnUpdate", nil)
		end
	end,
}
