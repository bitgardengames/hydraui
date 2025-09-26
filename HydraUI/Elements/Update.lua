local HydraUI, Language, Assets, Settings = select(2, ...):get()

local tonumber = tonumber
local IsInGuild = IsInGuild
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsInInstance = IsInInstance
local GetNumGroupMembers = GetNumGroupMembers
local UnitOnTaxi = UnitOnTaxi
local GetZoneText = GetZoneText
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
local wipe = wipe

local AddOnVersion = HydraUI.UIVersion
local AddOnNum = tonumber(HydraUI.UIVersion)
local User = HydraUI.UserName .. "-" .. HydraUI.UserRealm
local CT = ChatThrottleLib
local After = C_Timer.After

local Update = HydraUI:NewModule("Update")
Update.SentHome = false
Update.SentInst = false
Update.Delay = 5
Update.TimerHandle = nil

local Tables = {}
local Queue = {}
local QueueHead = 1
local QueueTail = 0
local QueuedChannels = {}

local Throttle = HydraUI:GetModule("Throttle")

local ProcessQueueTimer = function()
        Update:ProcessQueue()
end

local function QueueVersionYell(self)
        if Throttle:IsThrottled("vrsn") then
                return false
        end

        if self:QueueChannel("YELL") then
                Throttle:Start("vrsn", 10)

                return true
        end

        return false
end

local function HandleTaxiZoneChange(self)
        if UnitOnTaxi("player") then
                local Zone = GetZoneText()

                if (Zone ~= self.Zone) and QueueVersionYell(self) then
                        self.Zone = Zone
                end
        end
end

function Update:QueueChannel(channel, target)
	if (not channel) then
		return false
	end

	local key = target and (channel .. target) or channel

	if QueuedChannels[key] then
		return false
	end

	local Data = Tables[#Tables]

	if Data then
		Tables[#Tables] = nil
		Data[1] = channel
		Data[2] = target
		Data[3] = key
	else
		Data = {channel, target, key}
	end

	QueueTail = QueueTail + 1
	Queue[QueueTail] = Data
	QueuedChannels[key] = true

	if (not self.TimerHandle) then
		self.TimerHandle = true
		After(self.Delay, ProcessQueueTimer)
	end

	return true
end

function Update:ProcessQueue()
	self.TimerHandle = nil

	local Data = Queue[QueueHead]

	if Data then
		CT:SendAddonMessage("NORMAL", "HydraUI-Version", AddOnVersion, Data[1], Data[2])

		QueuedChannels[Data[3]] = nil

		Queue[QueueHead] = nil
		QueueHead = QueueHead + 1

		Data[1] = nil
		Data[2] = nil
		Data[3] = nil
		Tables[#Tables + 1] = Data

		if (QueueHead <= QueueTail) then
			self.TimerHandle = true
			After(self.Delay, ProcessQueueTimer)
		else
			QueueHead = 1
			QueueTail = 0
			wipe(QueuedChannels)
		end
	else
		QueueHead = 1
		QueueTail = 0
		wipe(QueuedChannels)
	end
end


function Update:PLAYER_ENTERING_WORLD()
        if (not HydraUI.IsMainline and not IsInInstance()) then
                After(5, function()
                        QueueVersionYell(self)
                end)
        end

        self:GROUP_ROSTER_UPDATE()
end

function Update:GUILD_ROSTER_UPDATE()
	if IsInGuild() then
		self:QueueChannel("GUILD")

		self:UnregisterEvent("GUILD_ROSTER_UPDATE")
	end
end

function Update:GROUP_ROSTER_UPDATE()
	local Home = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
	local Instance = GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE)

	if (Home == 0 and self.SentHome) then
		self.SentHome = false
	elseif (Instance == 0 and self.SentInst) then
		self.SentInst = false
	end

        if (Instance > 0 and not self.SentInst) then
                if self:QueueChannel("INSTANCE_CHAT") then
                        self.SentInst = true
                end
        elseif (Home > 0 and not self.SentHome) then
                local channel = (IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID") or (IsInGroup(LE_PARTY_CATEGORY_HOME) and "PARTY")

                if self:QueueChannel(channel) then
                        self.SentHome = true
                end
        end
end

function Update:CHAT_MSG_ADDON(prefix, message, channel, sender)
	if (sender == User or prefix ~= "HydraUI-Version") then
		return
	end

	message = tonumber(message)

	if (AddOnNum > message) then -- We have a higher version, share it
		self:QueueChannel(channel)
	elseif (message > AddOnNum) then -- We're behind!
		HydraUI:print(Language["You can get an updated version of HydraUI at https://www.curseforge.com/wow/addons/hydraui"])
		print(Language["Join the Discord community for support and feedback https://discord.gg/XefDFa6nJR"])

		HydraUI:GetModule("GUI"):CreateUpdateAlert()

		AddOnNum = message
		AddOnVersion = tostring(message)
	end
end

function Update:ZONE_CHANGED_NEW_AREA()
        HandleTaxiZoneChange(self)
end

function Update:ZONE_CHANGED()
        HandleTaxiZoneChange(self)
end

function Update:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

if (not HydraUI.IsMainline) then
	Update:RegisterEvent("ZONE_CHANGED")
	Update:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

Update:RegisterEvent("GUILD_ROSTER_UPDATE")
Update:RegisterEvent("PLAYER_ENTERING_WORLD")
Update:RegisterEvent("GROUP_ROSTER_UPDATE")
Update:RegisterEvent("CHAT_MSG_ADDON")
Update:SetScript("OnEvent", Update.OnEvent)

C_ChatInfo.RegisterAddonMessagePrefix("HydraUI-Version")
