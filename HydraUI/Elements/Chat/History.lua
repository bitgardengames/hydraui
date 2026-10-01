local HydraUI, Language, Assets, Settings = select(2, ...):get()
local Chat = HydraUI:GetModule("Chat")
local MaxHistoryMessages = 50
local MessageTuplePool, MessageListPool = {}, {}

function Chat:GetHistory()
	if not HydraUIData then
		HydraUIData = {}
	end

	HydraUIData.ChatHistory = HydraUIData.ChatHistory or {}
	local ProfileKey = HydraUI.UserProfileKey
	local History = HydraUIData.ChatHistory[ProfileKey]

	if not History then
		History = {
			Start = 1,
			Count = 0,
			Records = {},
		}
		HydraUIData.ChatHistory[ProfileKey] = History
	elseif not History.Records then
		-- Older versions stored history as an array. Keep the newest entries and
		-- retain their record tables while converting it to a circular buffer.
		local LegacyCount = #History
		local First = 1
		local Records = {}

		if LegacyCount > MaxHistoryMessages then
			First = LegacyCount - MaxHistoryMessages + 1
		end

		for i = First, LegacyCount do
			Records[#Records + 1] = History[i]
		end

		for i = 1, LegacyCount do
			History[i] = nil
		end

		History.Start = 1
		History.Count = #Records
		History.Records = Records
	end

	return History
end

function Chat:IterateHistory(History)
	local Offset = 0

	return function()
		Offset = Offset + 1

		if Offset <= History.Count then
			local Index = ((History.Start + Offset - 2) % MaxHistoryMessages) + 1

			return Offset, History.Records[Index]
		end
	end
end

function Chat:SaveMessage(frame, message, r, g, b)
	if (not Settings["chat-enable-history"]) or self.RestoringHistory or (type(message) ~= "string") then
		return
	end

	local History = self:GetHistory()
	local Index

	if History.Count < MaxHistoryMessages then
		Index = ((History.Start + History.Count - 1) % MaxHistoryMessages) + 1
		History.Count = History.Count + 1
	else
		Index = History.Start
		History.Start = (History.Start % MaxHistoryMessages) + 1
	end

	local Entry = History.Records[Index]

	if not Entry then
		Entry = {}
		History.Records[Index] = Entry
	end

	Entry.Frame = frame:GetName()
	Entry.Message = message
	Entry.R = r
	Entry.G = g
	Entry.B = b
end

function Chat:RestoreHistory()
	if not Settings["chat-enable-history"] then
		return
	end

	local History = self:GetHistory()
	local CurrentMessages = {}

	-- Chat is initialized after Blizzard has already printed login messages (such as the guild MOTD). Save and remove those messages so restored history can be inserted before them, then put the login messages back in their original order.
	for _, Entry in self:IterateHistory(History) do
		local Frame = Entry.Frame and _G[Entry.Frame]

		if Frame and not CurrentMessages[Frame] and Frame.GetNumMessages and Frame.GetMessageInfo and Frame.Clear then
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

	for _, Entry in self:IterateHistory(History) do
		local Frame = Entry.Frame and _G[Entry.Frame]

		if Frame and Frame.AddMessage then
			Frame:AddMessage(Entry.Message, Entry.R, Entry.G, Entry.B)
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
