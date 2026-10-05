local HydraUI, Language, Assets, Settings = select(2, ...):get()

local tonumber = tonumber
local IsInGuild = IsInGuild
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsInInstance = IsInInstance
local GetZoneText = GetZoneText
local GetNumGroupMembers = GetNumGroupMembers
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

local AddOnVersion = HydraUI.UIVersion
local AddOnNum = tonumber(HydraUI.UIVersion)
local User = HydraUI.UserName .. "-" .. HydraUI.UserRealm
local CT = ChatThrottleLib

local Prefix = "HydraUI-Version"

local Update = HydraUI:NewModule("Update")
Update.SentHome = false
Update.SentInst = false

local SendInterval = 5

local Tables = {}
local Queue = {}
local QueueHead = 1
local QueueTail = 0

local Throttle = HydraUI:GetModule("Throttle")

function Update:ScheduleSend()
	if self.SendTimer or QueueTail == 0 then
		return
	end

	self.SendTimer = C_Timer.NewTimer(SendInterval, function()
		self.SendTimer = nil
		self:SendNext()
	end)
end

function Update:QueueChannel(channel, target)
	if not channel then
		return
	end

	for i = QueueHead, QueueTail do
		local Data = Queue[i]

		if Data[1] == channel and Data[2] == target then
			return
		end
	end

	local Data
	local Last = #Tables

	if Last == 0 then
		Data = {channel, target}
	else
		Data = Tables[Last]
		Tables[Last] = nil
		Data[1] = channel
		Data[2] = target
	end

	QueueTail = QueueTail + 1
	Queue[QueueTail] = Data
	self:ScheduleSend()
end

function Update:SendNext()
	local Data = Queue[QueueHead]

	if not Data then
		QueueHead = 1
		QueueTail = 0

		return
	end

	Queue[QueueHead] = nil
	QueueHead = QueueHead + 1

	if QueueHead > QueueTail then
		QueueHead = 1
		QueueTail = 0
	end

	CT:SendAddonMessage("NORMAL", Prefix, AddOnVersion, Data[1], Data[2])

	Data[1] = nil
	Data[2] = nil
	Tables[#Tables + 1] = Data

	self:ScheduleSend()
end

function Update:PLAYER_ENTERING_WORLD()
	if (not HydraUI.IsMainline and not IsInInstance()) and (not Throttle:IsThrottled("version")) then
		C_Timer.After(5, function()
			self:QueueChannel("YELL")
		end)

		Throttle:Start("version", 10)
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

	if Home == 0 and self.SentHome then
		self.SentHome = false
	end

	if Instance == 0 and self.SentInst then
		self.SentInst = false
	end

	if Instance > 0 and not self.SentInst then
		self:QueueChannel("INSTANCE_CHAT")
		self.SentInst = true
	elseif Home > 0 and not self.SentHome then
		self:QueueChannel(IsInRaid(LE_PARTY_CATEGORY_HOME) and "RAID" or IsInGroup(LE_PARTY_CATEGORY_HOME) and "PARTY")
		self.SentHome = true
	end
end

function Update:CHAT_MSG_ADDON(prefix, message, channel, sender)
	if sender == User or prefix ~= Prefix then
		return
	end

	message = tonumber(message)

	if not message then
		return
	end

	if AddOnNum > message then -- We have a higher version, share it
		self:QueueChannel(channel)
	elseif message > AddOnNum then -- We're behind!
		HydraUI:print(Language["You can get an updated version of HydraUI at https://www.curseforge.com/wow/addons/hydraui"])

		HydraUI:GetModule("GUI"):CreateUpdateAlert()

		AddOnNum = message
		AddOnVersion = tostring(message)
	end
end

function Update:ZoneVersionCheck()
	if IsInInstance() then
		return
	end

	local Zone = GetZoneText()

	if Zone ~= self.Zone and not Throttle:IsThrottled("version") then
		self:QueueChannel("YELL")
		self.Zone = Zone
		Throttle:Start("version", 10)
	end
end

function Update:ZONE_CHANGED()
	self:ZoneVersionCheck()
end

function Update:ZONE_CHANGED_NEW_AREA()
	self:ZoneVersionCheck()
end

function Update:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

if not HydraUI.IsMainline then
	Update:RegisterEvent("ZONE_CHANGED")
	Update:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

C_ChatInfo.RegisterAddonMessagePrefix(Prefix)

Update:RegisterEvent("GUILD_ROSTER_UPDATE")
Update:RegisterEvent("PLAYER_ENTERING_WORLD")
Update:RegisterEvent("GROUP_ROSTER_UPDATE")
Update:RegisterEvent("CHAT_MSG_ADDON")
Update:SetScript("OnEvent", Update.OnEvent)
