local HydraUI = select(2, ...):get()

local GetTime = GetTime
local max = math.max
local type = type

local Throttle = HydraUI:NewModule("Throttle")
local Records = {}

local HandleExpiration

HandleExpiration = function(name, record, canceled)
        record.Active = false

        if record.OnExpire then
                local callback = record.OnExpire
                record.OnExpire = nil

                callback(name, canceled)
        end
end

local function IsRecordActive(name, record, now)
        if (not record or not record.Active) then
                return false
        end

        if ((now - record.Started) >= record.Duration) then
                HandleExpiration(name, record, false)

                return false
        end

        return true
end

function Throttle:IsThrottled(name)
        return IsRecordActive(name, Records[name], GetTime())
end

function Throttle:Exists(name)
        return Records[name] ~= nil
end

function Throttle:Start(name, duration, onExpire)
        local record = Records[name]
        local now = GetTime()

        if IsRecordActive(name, record, now) then
                return false
        end

        duration = duration or 0

        if not record then
                record = {}
                Records[name] = record
        end

        record.Duration = duration
        record.Started = now
        record.Active = true
        record.OnExpire = onExpire

        return true
end

function Throttle:Cancel(name)
        local record = Records[name]

        if (not record or not record.Active) then
                return false
        end

        HandleExpiration(name, record, true)

        return true
end

function Throttle:GetRemaining(name)
        local record = Records[name]
        local now = GetTime()

        if (not IsRecordActive(name, record, now)) then
                return 0
        end

        return max(0, record.Duration - (now - record.Started))
end

function Throttle:Run(name, duration, func, ...)
        if (type(func) ~= "function") then
                return false
        end

        if (not self:Start(name, duration)) then
                return false
        end

        func(...)

        return true
end
