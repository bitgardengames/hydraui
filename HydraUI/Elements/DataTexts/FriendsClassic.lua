local HydraUI, Language = select(2, ...):get()

local NativeProject = 2
if HydraUI.IsTBC then NativeProject = 5 elseif HydraUI.IsWrath then NativeProject = 11 end

local Adapter = {
	HeaderWhite = true,
	NativeAFK = CHAT_FLAG_AFK,
	NativeDND = CHAT_FLAG_DND,
	ClientNames = {App=Language["B.Net"], BSAp=Language["B.Net"], DST2=Language["Destiny 2"], D3=Language["Diablo 3"], Hero=Language["Heroes of the Storm"], OSI="Diablo II: Resurrected", Pro=Language["Overwatch 2"], S1=Language["StarCraft: Remastered"], S2=Language["StarCraft 2"], VIPR=Language["Call of Duty: Black Ops 4"], ODIN=Language["Call of Duty: Modern Warfare"], WoW=CINEMATIC_NAME_1, WTCG=Language["Hearthstone"], ANBS=Language["Diablo Immortal"], AUKS=Language["Call of Duty: MWII"], Fen=Language["Diablo IV"], GRY=Language["Warcraft Rumble"], W3=Language["Warcraft III"]},
	ProjectNames = {[1]=Language["Midnight"], [2]=EXPANSION_NAME0, [5]=EXPANSION_NAME1, [11]=EXPANSION_NAME2, [14]=EXPANSION_NAME3, [19]=EXPANSION_NAME4},
	ClientInfo = {App={DisplayName="accountName"}, ANBS={DisplayName="accountName",Right="richPresence"}, BSAp={DisplayName="accountName",Right="richPresence"}, DST2={DisplayName="accountName",Right="richPresence"}, D3={DisplayName="accountName",Right="richPresence"}, Hero={DisplayName="accountName",Right="richPresence"}, Pro={DisplayName="accountName",Right="richPresence"}, S1={DisplayName="accountName",Right="richPresence"}, S2={DisplayName="accountName",Right="richPresence"}, VIPR={DisplayName="accountName",Right="richPresence"}, AUKS={DisplayName="accountName",Right="richPresence"}, ODIN={DisplayName="accountName",Right="richPresence"}, OSI={DisplayName="accountName",Right="richPresence"}, WTCG={DisplayName="accountName",Right="richPresence"}, Fen={DisplayName="accountName",Right="richPresence"}, GRY={DisplayName="accountName",Right="richPresence"}, W3={DisplayName="accountName",Right="richPresence"}, WoW={}},
}
Adapter.NativeProject = Adapter.ProjectNames[NativeProject]
function Adapter:GetStatusTokens() return CHAT_FLAG_AFK, CHAT_FLAG_DND end
function Adapter.FormatWoWStatus(Name, AFK) return format("|cFF00FFF6(%s)|r |cFFFFFF33%s|r", Name, AFK and CHAT_FLAG_AFK or CHAT_FLAG_DND) end
function Adapter:NormalizeBattleNetFriend(Index, Record)
	local PresenceID, AccountName, _, _, _, GameAccountID, Client = BNGetFriendInfo(Index)
	local ID = GameAccountID or PresenceID
	if not ID then return false end
	local _, Character, RealClient, _, _, _, _, Class, _, Area, Level, RichPresence, _, _, IsOnline, _, _, IsAFK, IsBusy, _, Project = BNGetGameAccountInfo(ID)
	Record.client, Record.accountName, Record.character = RealClient or Client, AccountName, Character
	Record.level, Record.class = Level, (Class and Class:find("%S")) and Class or "DEMONHUNTER"
	Record.area = (Area and Area ~= "") and Area or (RichPresence and RichPresence:gsub("- (.+)", ""))
	Record.project, Record.afk, Record.dnd, Record.richPresence = Project, IsAFK, IsBusy, RichPresence
	return true
end
HydraUI:CreateFriendsDataText(Adapter)
