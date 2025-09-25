local HydraUI = select(2, ...):get()

local GetTime = GetTime

local Throttle = HydraUI:NewModule("Throttle")
local Records = {}

function Throttle:IsThrottled(name)
        local record = Records[name]

        if (not record or not record.Active) then
                return false
        end

        if ((GetTime() - record.Started) >= record.Duration) then
                record.Active = false

                return false
        end

        return true
end

function Throttle:Exists(name)
        return Records[name] ~= nil
end

function Throttle:Start(name, duration)
        local record = Records[name]
        local now = GetTime()

        if (record and record.Active) then
                if ((now - record.Started) < record.Duration) then
                        return
                end

                record.Active = false
        end

        if not record then
                record = {}
                Records[name] = record
        end

        record.Duration = duration
        record.Started = now
        record.Active = true
end
