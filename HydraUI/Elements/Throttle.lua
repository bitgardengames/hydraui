local HydraUI = select(2, ...):get()

local GetTime = GetTime

local Throttle = HydraUI:NewModule("Throttle")
local Deadlines = {}

function Throttle:IsThrottled(name)
	local Deadline = Deadlines[name]

	if (Deadline and Deadline > GetTime()) then
		return true
	end

	if (Deadline) then
		Deadlines[name] = nil
	end
end

function Throttle:Start(name, duration)
	if (not self:IsThrottled(name)) then
		Deadlines[name] = GetTime() + duration
	end
end
