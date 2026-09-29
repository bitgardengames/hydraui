local HydraUI, Language, Assets, Settings = select(2, ...):get()

local GetNumFriends = C_FriendList.GetNumFriends
local GetNumOnlineFriends = C_FriendList.GetNumOnlineFriends
local GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local Label = TUTORIAL_TITLE22
local FriendList, GroupPool, RecordPool = {}, {}, {}

local function AcquireGroup()
	local Index = #GroupPool
	local Group = GroupPool[Index]
	if Group then GroupPool[Index] = nil return Group end
	return {}
end

local function AcquireRecord()
	local Index = #RecordPool
	local Record = RecordPool[Index]
	if Record then RecordPool[Index] = nil return Record end
	return {}
end

local function ReleaseRecord(Record)
	for Key in next, Record do Record[Key] = nil end
	RecordPool[#RecordPool + 1] = Record
end

local function ResetFriendList()
	for Client, Group in next, FriendList do
		for i = #Group, 1, -1 do ReleaseRecord(Group[i]); Group[i] = nil end
		GroupPool[#GroupPool + 1] = Group
	end
	wipe(FriendList)
end

local function GetClass(Class)
	if HydraUI.ClassColors[Class] then return Class end
	for Token, Localized in next, LOCALIZED_CLASS_NAMES_MALE do
		if Localized == Class then return Token end
	end
end

local function AddRecord(Record)
	local GroupName = Record.project
	if not GroupName then ReleaseRecord(Record); return false end
	if not FriendList[GroupName] then FriendList[GroupName] = AcquireGroup() end
	FriendList[GroupName][#FriendList[GroupName] + 1] = Record
	return true
end

local function ColorCharacter(Record, Name)
	local Class = GetClass(Record.class)
	if Class == "Unknown" then Class = "PRIEST" end
	if not HydraUI.ClassColors[Class] then return Name end
	local ClassColor = HydraUI.ClassColors[Class]
	ClassColor = HydraUI:RGBToHex(ClassColor[1], ClassColor[2], ClassColor[3])
	local LevelColor = GetQuestDifficultyColor(Record.level)
	LevelColor = HydraUI:RGBToHex(LevelColor.r, LevelColor.g, LevelColor.b)
	return format("|cFFFFFFFF|cFF%s%s|r |cFF%s%s|r|cFFFFFFFF|r", LevelColor, Record.level, ClassColor, Name)
end

local function ColorBattleNetCharacter(Record, Account)
	local Class = GetClass(Record.class)
	local ClassColor = Class and HydraUI.ClassColors[Class]
	if not ClassColor then return end
	ClassColor = HydraUI:RGBToHex(ClassColor[1], ClassColor[2], ClassColor[3])
	local LevelColor = GetQuestDifficultyColor(Record.level)
	LevelColor = HydraUI:RGBToHex(LevelColor.r, LevelColor.g, LevelColor.b)
	return format("|cFF%s%s|r |cFF%s%s|r|cFFFFFFFF|r %s", LevelColor, Record.level, ClassColor, Record.character, Account)
end

local function FormatRecord(Adapter, Record)
	local Descriptor = Adapter.ClientInfo[Record.client]
	if not Descriptor then return end

	if Record.client == "WoW" then
		local Name = Record.accountName
		if Record.afk then Name = Adapter.FormatWoWStatus(Name, true, false)
		elseif Record.dnd then Name = Adapter.FormatWoWStatus(Name, false, true)
		else Name = format("|cFF00FFF6(%s)|r", Name) end
		Record.left = ColorBattleNetCharacter(Record, Name)
		if not Record.left then Record.left = Record.accountName end
		Record.right = Record.area
		if Record.right == GetRealZoneText() then Record.right = format("|cFF33FF33%s|r", Record.right) end
		return
	end

	if Descriptor.DisplayName == "richPresence" then
		Record.left = Record.richPresence
	else
		local AFK, DND = Adapter:GetStatusTokens(Record.client)
		if Record.afk then Record.left = format("|cFF00FFF6%s|r |cFFFFFF33%s|r", Record.accountName, AFK)
		elseif Record.dnd then Record.left = format("|cFF00FFF6%s|r |cFFFFFF33%s|r", Record.accountName, DND)
		else Record.left = format("|cFF00FFF6%s|r", Record.accountName) end
	end
	Record.right = Descriptor.Right == "richPresence" and Record.richPresence or nil
end

function HydraUI:CreateFriendsDataText(Adapter)
	local function OnEnter(self)
		if not self:SetTooltip() then return end
		C_FriendList.ShowFriends()
		local NumFriends, NumOnline = GetNumFriends(), GetNumOnlineFriends()
		local NumBNFriends, NumBNOnline = BNGetNumFriends()
		local NumClients, Name = 0
		local MapID = C_Map.GetBestMapForUnit("player")
		local CurrentZone = MapID and (C_Map.GetMapInfo(MapID).name or GetRealZoneText()) or GetRealZoneText()
		GameTooltip:AddDoubleLine(Label, format("%s/%s", NumBNOnline + NumOnline, NumFriends + NumBNFriends), nil, nil, nil, Adapter.HeaderWhite and 1, Adapter.HeaderWhite and 1, Adapter.HeaderWhite and 1)
		GameTooltip:AddLine(" ")

		for i = 1, NumBNFriends do
			local Record = AcquireRecord()
			if Adapter:NormalizeBattleNetFriend(i, Record) then
				Record.project = Adapter.ProjectNames[Record.project] or Adapter.ClientNames[Record.client]
				FormatRecord(Adapter, Record)
				if AddRecord(Record) and #FriendList[Record.project] == 1 then NumClients = NumClients + 1 end
			else ReleaseRecord(Record) end
		end

		for i = 1, NumFriends do
			local Info = GetFriendInfoByIndex(i)
			if Info.connected then
				local Record = AcquireRecord()
				Record.client, Record.project = "WoW", Adapter.NativeProject
				Record.character, Record.level, Record.class, Record.area = Info.name, Info.level, Info.className, Info.area
				Record.afk, Record.dnd = Info.afk, Info.dnd
				if Info.afk then Name = format("%s |cFFFFFF33%s|r", Info.name, Adapter.NativeAFK)
				elseif Info.dnd then Name = format("%s |cFFFFFF33%s|r", Info.name, Adapter.NativeDND)
				else Name = Info.name end
				Record.left, Record.right = ColorCharacter(Record, Name), Info.area
				if AddRecord(Record) and #FriendList[Record.project] == 1 then NumClients = NumClients + 1 end
			end
		end

		local ClientCount = 0
		for Client, Group in next, FriendList do
			GameTooltip:AddLine(Client); ClientCount = ClientCount + 1
			for i = 1, #Group do
				local Record = Group[i]
				if Record.right then GameTooltip:AddDoubleLine(Record.left, Record.right, nil, nil, nil, Record.right == CurrentZone and 0.2 or 1, 1, Record.right == CurrentZone and 0.2 or 1)
				else GameTooltip:AddLine(Record.left) end
			end
			if ClientCount ~= NumClients then GameTooltip:AddLine(" ") end
		end
		GameTooltip:Show(); ResetFriendList(); self.TooltipShown = true
	end

	local function OnLeave(self) GameTooltip:Hide(); self.TooltipShown = false end
	local function OnMouseUp() if not InCombatLockdown() then ToggleFriendsFrame(1) end end
	local function Update(self)
		local _, BNOnline = BNGetNumFriends()
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, HydraUI.ValueColor, GetNumOnlineFriends() + BNOnline)
		if self.TooltipShown then OnLeave(self); OnEnter(self) end
	end
	local Events = {"FRIENDLIST_UPDATE", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_INFO_CHANGED", "BN_FRIEND_INFO_CHANGED", "BN_CONNECTED", "BN_DISCONNECTED", "WHO_LIST_UPDATE", "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "PLAYER_FLAGS_CHANGED"}
	local function OnEnable(self)
		for i = 1, #Events do self:RegisterEvent(Events[i]) end
		self:SetScript("OnEvent", Update); self:SetScript("OnEnter", OnEnter); self:SetScript("OnLeave", OnLeave); self:SetScript("OnMouseUp", OnMouseUp)
		C_FriendList.ShowFriends(); self:Update()
	end
	local function OnDisable(self)
		for i = 1, #Events do self:UnregisterEvent(Events[i]) end
		self:SetScript("OnEvent", nil); self:SetScript("OnEnter", nil); self:SetScript("OnLeave", nil); self:SetScript("OnMouseUp", nil); self.Text:SetText("")
	end
	self:AddDataText("Friends", OnEnable, OnDisable, Update)
end
