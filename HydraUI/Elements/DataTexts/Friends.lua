local HydraUI, Language = select(2, ...):get()

local Adapter = {
	Mainline = true,
	NativeAFK = DEFAULT_AFK_MESSAGE,
	NativeDND = DEFAULT_DND_MESSAGE,
	NativeProject = EXPANSION_NAME10,
	ClientNames = {App=Language["B.Net"], BSAp=Language["B.Net"], DST2=Language["Destiny 2"], D3=Language["Diablo 3"], Hero=Language["Heroes of the Storm"], OSI="Diablo II: Resurrected", Pro=Language["Overwatch 2"], S1=Language["StarCraft: Remastered"], S2=Language["StarCraft 2"], VIPR=Language["Call of Duty: Black Ops 4"], ODIN=Language["Call of Duty: Modern Warfare"], WoW=CINEMATIC_NAME_1, WTCG=Language["Hearthstone"], ANBS="Diablo Immortal", AUKS=Language["Call of Duty: MWII"], Fen=Language["Diablo IV"], GRY=Language["Warcraft Rumble"], W3=Language["Warcraft III"]},
	ProjectNames = {[1]=EXPANSION_NAME10, [2]=EXPANSION_NAME0, [5]=EXPANSION_NAME1, [11]=EXPANSION_NAME2, [14]=EXPANSION_NAME3, [19]=EXPANSION_NAME4},
	ClientInfo = {App={DisplayName="accountName"}, ANBS={DisplayName="accountName",Right="richPresence"}, BSAp={DisplayName="accountName",Right="richPresence"}, DST2={DisplayName="accountName",Right="richPresence"}, D3={DisplayName="accountName",Right="richPresence"}, Hero={DisplayName="accountName",Right="richPresence"}, Pro={DisplayName="accountName",Right="richPresence"}, S1={DisplayName="accountName",Right="richPresence"}, S2={DisplayName="accountName",Right="richPresence"}, VIPR={DisplayName="accountName",Right="richPresence"}, AUKS={DisplayName="accountName",Right="richPresence"}, ODIN={DisplayName="accountName",Right="richPresence"}, OSI={DisplayName="accountName",Right="richPresence"}, WTCG={DisplayName="richPresence"}, Fen={DisplayName="richPresence"}, GRY={DisplayName="richPresence"}, W3={DisplayName="accountName",Right="richPresence"}, WoW={}},
}
function Adapter:GetStatusTokens(Client) if Client == "W3" then return CHAT_FLAG_AFK, CHAT_FLAG_DND end return DEFAULT_AFK_MESSAGE, DEFAULT_DND_MESSAGE end
function Adapter.FormatWoWStatus(Name, AFK) return format("|cFF00FFF6(%s)|r |cFFFFFF33<%s>|r", Name, AFK and DEFAULT_AFK_MESSAGE or DEFAULT_DND_MESSAGE) end
function Adapter:NormalizeBattleNetFriend(Index, Record)
	local Info = C_BattleNet.GetFriendAccountInfo(Index)
	if not Info or not Info.gameAccountInfo then return false end
	local Game = Info.gameAccountInfo
	Record.client, Record.accountName, Record.character = Game.clientProgram, Info.accountName, Game.characterName
	Record.level, Record.class, Record.area, Record.project = Game.characterLevel, Game.className, Game.areaName, Game.wowProjectID
	Record.afk, Record.dnd, Record.richPresence = Game.isGameAFK, Game.isGameBusy, Game.richPresence
	return true
end
HydraUI:CreateFriendsDataText(Adapter)
