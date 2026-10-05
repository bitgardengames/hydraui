local HydraUI, Language, Assets, Settings = select(2, ...):get()
local Chat = HydraUI:GetModule("Chat")
local MaxMessagesPerFrame = 25
local LegacyMaxHistoryMessages = 50
local MessageTuplePool, MessageListPool = {}, {}

local NewFrameHistory = function()
	return {
		Start = 1,
		Count = 0,
		Records = {},
	}
end

local AddToFrameHistory = function(History, Entry)
	local Index

	if History.Count < MaxMessagesPerFrame then
		Index = ((History.Start + History.Count - 1) % MaxMessagesPerFrame) + 1
		History.Count = History.Count + 1
	else
		Index = History.Start
		History.Start = (History.Start % MaxMessagesPerFrame) + 1
	end

	History.Records[Index] = Entry
end

local MigrateHistory = function(History)
	local Frames = {}
	local Count = History.Count or #History
	local Start = History.Start or 1
	local Records = History.Records or History

	for Offset = 1, Count do
		local Index = History.Records and (((Start + Offset - 2) % LegacyMaxHistoryMessages) + 1) or Offset
		local Entry = Records[Index]
		local FrameName = Entry and Entry.Frame

		if FrameName and FrameName ~= "ChatFrame2" then
			local FrameHistory = Frames[FrameName]

			if not FrameHistory then
				FrameHistory = NewFrameHistory()
				Frames[FrameName] = FrameHistory
			end

			AddToFrameHistory(FrameHistory, Entry)
		end
	end

	return {
		Version = 2,
		Frames = Frames,
	}
end

function Chat:GetHistory()
	if not HydraUIData then
		HydraUIData = {}
	end

	HydraUIData.ChatHistory = HydraUIData.ChatHistory or {}
	local ProfileKey = HydraUI.UserProfileKey
	local History = HydraUIData.ChatHistory[ProfileKey]

	if not History then
		History = {
			Version = 2,
			Frames = {},
		}
		HydraUIData.ChatHistory[ProfileKey] = History
	elseif not History.Frames then
		History = MigrateHistory(History)
		HydraUIData.ChatHistory[ProfileKey] = History
	end

	return History
end

function Chat:GetFrameHistory(FrameName)
	local History = self:GetHistory()
	local FrameHistory = History.Frames[FrameName]

	if not FrameHistory then
		FrameHistory = NewFrameHistory()
		History.Frames[FrameName] = FrameHistory
	end

	return FrameHistory
end

function Chat:IterateHistory(History)
	local Offset = 0

	return function()
		Offset = Offset + 1

		if Offset <= History.Count then
			local Index = ((History.Start + Offset - 2) % MaxMessagesPerFrame) + 1

			return Offset, History.Records[Index]
		end
	end
end


function Chat:SaveMessage(frame, message, r, g, b)
	if (not Settings["chat-enable-history"]) or self.RestoringHistory or (type(message) ~= "string") then
		return
	end

	local FrameName = frame:GetName()

	-- Combat messages are intentionally excluded: they are too frequent and are
	-- already managed by Blizzard's combat log.
	if (not FrameName) or FrameName == "ChatFrame2" then
		return
	end

	local History = self:GetFrameHistory(FrameName)
	local Entry = {}

	Entry.Frame = FrameName
	Entry.Message = message
	Entry.R = r
	Entry.G = g
	Entry.B = b

	AddToFrameHistory(History, Entry)
end

function Chat:RestoreHistory()
	if not Settings["chat-enable-history"] then
		return
	end

	local History = self:GetHistory()
	local CurrentMessages = {}

	-- Chat is initialized after Blizzard has already printed login messages (such as the guild MOTD). Save and remove those messages so restored history can be inserted before them, then put the login messages back in their original order.
	for FrameName, FrameHistory in pairs(History.Frames) do
		local Frame = FrameName ~= "ChatFrame2" and _G[FrameName]

		if Frame and Frame.GetNumMessages and Frame.GetMessageInfo and Frame.Clear then
			local Messages = MessageListPool[#MessageListPool]

			if Messages then
				MessageListPool[#MessageListPool] = nil
			else
				Messages = {}
			end

			Messages.Count = 0

			for i = 1, Frame:GetNumMessages() do
				local Message, R, G, B, InfoID, AccessID, TypeID = Frame:GetMessageInfo(i)
				local Values = MessageTuplePool[#MessageTuplePool]

				if Values then
					MessageTuplePool[#MessageTuplePool] = nil
				else
					Values = {}
				end

				Values[1], Values[2], Values[3], Values[4] = Message, R, G, B
				Values[5], Values[6], Values[7] = InfoID, AccessID, TypeID
				Messages.Count = Messages.Count + 1
				Messages[Messages.Count] = Values
			end

			CurrentMessages[Frame] = Messages
			Frame:Clear()
		end
	end

	self.RestoringHistory = true

	for FrameName, FrameHistory in pairs(History.Frames) do
		local Frame = FrameName ~= "ChatFrame2" and _G[FrameName]

		if Frame and Frame.AddMessage then
			for _, Entry in self:IterateHistory(FrameHistory) do
				Frame:AddMessage(Entry.Message, Entry.R, Entry.G, Entry.B)
			end
		end
	end

	for Frame, Messages in pairs(CurrentMessages) do
		for i = 1, Messages.Count do
			local Message = Messages[i]

			Frame:AddMessage(unpack(Message, 1, 7))

			for j = 1, 7 do
				Message[j] = nil
			end

			Messages[i] = nil
			MessageTuplePool[#MessageTuplePool + 1] = Message
		end

		Messages.Count = nil
		CurrentMessages[Frame] = nil
		MessageListPool[#MessageListPool + 1] = Messages
	end

	self.RestoringHistory = nil
end
