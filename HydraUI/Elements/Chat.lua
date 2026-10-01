local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

-- Default setting values
Defaults["chat-enable"] = true
Defaults["chat-bg-opacity"] = 70
Defaults["chat-top-opacity"] = 100
Defaults["chat-bottom-opacity"] = 100
Defaults["chat-enable-url-links"] = true
Defaults["chat-enable-discord-links"] = true
Defaults["chat-enable-email-links"] = true
Defaults["chat-enable-friend-links"] = true
Defaults["chat-font"] = "PT Sans"
Defaults["chat-font-size"] = 12
Defaults["chat-font-flags"] = ""
Defaults["chat-tab-font"] = "Roboto"
Defaults["chat-tab-font-size"] = 12
Defaults["chat-tab-font-flags"] = ""
Defaults["chat-tab-font-color"] = "FFFFFF"
Defaults["chat-tab-font-color-mouseover"] = "FFCE54"
Defaults["chat-frame-width"] = 392
Defaults["chat-frame-height"] = 104
Defaults["chat-bottom-height"] = 26
Defaults["chat-top-height"] = 26
Defaults["chat-enable-fading"] = false
Defaults["chat-fade-time"] = 15
Defaults["chat-link-tooltip"] = true
Defaults["chat-shorten-channels"] = true
Defaults["chat-enable-history"] = true

Defaults["right-window-enable"] = true
Defaults["right-window-size"] = "SINGLE"
Defaults["right-window-width"] = 392
Defaults["right-window-height"] = 128
Defaults["right-window-fill"] = 70
Defaults["right-window-left-fill"] = 70
Defaults["right-window-right-fill"] = 70
Defaults["right-window-middle-pos"] = 50
Defaults["right-window-bottom-height"] = 26
Defaults["right-window-top-height"] = 26
Defaults["rw-top-fill"] = 100
Defaults["rw-bottom-fill"] = 100
Defaults["rw-single-embed"] = "None"

local Chat = HydraUI:NewModule("Chat")
local Window = HydraUI:NewModule("Right Window")
local Assets = Assets
local Settings = Settings
local Language = Language

local AddChannelToFrame = ChatFrame_AddChannel or function(Frame, Channel)
	local WindowID = Frame:GetID()

	if (C_ChatInfo and C_ChatInfo.AddChannelToWindow) then
		C_ChatInfo.AddChannelToWindow(WindowID, Channel)
	elseif AddChatWindowChannel then
		AddChatWindowChannel(WindowID, Channel)
	end
end

function Chat:Install()
	-- General
	FCF_ResetChatWindows()
	FCF_SetLocked(ChatFrame1, true)
	FCF_SetWindowName(ChatFrame1, Language["General"])
	ChatFrame1:Show()

	ChatFrame_RemoveAllMessageGroups(ChatFrame1)
	ChatFrame_RemoveChannel(ChatFrame1, TRADE)
	ChatFrame_RemoveChannel(ChatFrame1, GENERAL)
	ChatFrame_RemoveChannel(ChatFrame1, "LocalDefense")
	ChatFrame_RemoveChannel(ChatFrame1, "GuildRecruitment")
	ChatFrame_RemoveChannel(ChatFrame1, "LookingForGroup")
	ChatFrame_RemoveChannel(ChatFrame1, "Services")

	ChatFrame_AddMessageGroup(ChatFrame1, "SAY")
	ChatFrame_AddMessageGroup(ChatFrame1, "EMOTE")
	ChatFrame_AddMessageGroup(ChatFrame1, "YELL")
	ChatFrame_AddMessageGroup(ChatFrame1, "GUILD")
	ChatFrame_AddMessageGroup(ChatFrame1, "OFFICER")
	ChatFrame_AddMessageGroup(ChatFrame1, "GUILD_ACHIEVEMENT")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_SAY")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_EMOTE")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_YELL")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_WHISPER")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_BOSS_EMOTE")
	ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_BOSS_WHISPER")
	ChatFrame_AddMessageGroup(ChatFrame1, "PARTY")
	ChatFrame_AddMessageGroup(ChatFrame1, "PARTY_LEADER")
	ChatFrame_AddMessageGroup(ChatFrame1, "RAID")
	ChatFrame_AddMessageGroup(ChatFrame1, "RAID_LEADER")
	ChatFrame_AddMessageGroup(ChatFrame1, "RAID_WARNING")
	ChatFrame_AddMessageGroup(ChatFrame1, "INSTANCE_CHAT")
	ChatFrame_AddMessageGroup(ChatFrame1, "INSTANCE_CHAT_LEADER")
	ChatFrame_AddMessageGroup(ChatFrame1, "BG_HORDE")
	ChatFrame_AddMessageGroup(ChatFrame1, "BG_ALLIANCE")
	ChatFrame_AddMessageGroup(ChatFrame1, "BG_NEUTRAL")
	ChatFrame_AddMessageGroup(ChatFrame1, "SYSTEM")
	ChatFrame_AddMessageGroup(ChatFrame1, "ERRORS")
	ChatFrame_AddMessageGroup(ChatFrame1, "AFK")
	ChatFrame_AddMessageGroup(ChatFrame1, "DND")
	ChatFrame_AddMessageGroup(ChatFrame1, "IGNORED")
	ChatFrame_AddMessageGroup(ChatFrame1, "ACHIEVEMENT")

	-- Combat Log
	FCF_DockFrame(ChatFrame2)
	FCF_SetLocked(ChatFrame2, true)
	FCF_SetWindowName(ChatFrame2, Language["Combat"])
	ChatFrame2:Show()

	-- Whispers
	local Whispers = FCF_OpenNewWindow(Language["Whispers"])
	FCF_SetLocked(Whispers, true)
	FCF_DockFrame(Whispers)

	ChatFrame_RemoveAllMessageGroups(Whispers)
	ChatFrame_AddMessageGroup(Whispers, "WHISPER")
	ChatFrame_AddMessageGroup(Whispers, "BN_WHISPER")
	ChatFrame_AddMessageGroup(Whispers, "BN_CONVERSATION")

	-- Trade
	local Trade = FCF_OpenNewWindow(Language["Trade"])
	FCF_SetLocked(Trade, true)
	FCF_DockFrame(Trade)

	ChatFrame_RemoveAllMessageGroups(Trade)
	AddChannelToFrame(Trade, TRADE)
	AddChannelToFrame(Trade, GENERAL)

	if HydraUI.IsMainline then
		AddChannelToFrame(Trade, "Services")
	end

	-- Loot
	local Loot = FCF_OpenNewWindow(Language["Loot"])
	FCF_SetLocked(Loot, true)
	FCF_DockFrame(Loot)

	ChatFrame_RemoveAllMessageGroups(Loot)
	ChatFrame_AddMessageGroup(Loot, "COMBAT_XP_GAIN")
	ChatFrame_AddMessageGroup(Loot, "COMBAT_HONOR_GAIN")
	ChatFrame_AddMessageGroup(Loot, "COMBAT_FACTION_CHANGE")
	ChatFrame_AddMessageGroup(Loot, "LOOT")
	ChatFrame_AddMessageGroup(Loot, "MONEY")
	ChatFrame_AddMessageGroup(Loot, "SKILL")

	DEFAULT_CHAT_FRAME:SetUserPlaced(true)

	C_CVar.SetCVar("chatMouseScroll", "1")
	C_CVar.SetCVar("chatStyle", "im")
	C_CVar.SetCVar("WholeChatWindowClickable", "0")
	C_CVar.SetCVar("WhisperMode", "inline")
	--C_CVar.SetCVar("BnWhisperMode", "inline")
	C_CVar.SetCVar("removeChatDelay", "1")
	C_CVar.SetCVar("colorChatNamesByClass", 0)
	C_CVar.SetCVar("chatClassColorOverride", 0)
	C_CVar.SetCVar("speechToText", "0")

	if (C_CVar.GetCVar("colorChatNamesByClass") ~= "0") then
		C_CVar.SetCVar("colorChatNamesByClass", 0)
	end

	if (C_CVar.GetCVar("chatClassColorOverride") ~= "0") then
		C_CVar.SetCVar("chatClassColorOverride", 0)
	end

	--Chat:MoveChatFrames()
	FCF_SelectDockFrame(ChatFrame1)
end
function Chat:SetChatTypeInfo()
	_G["CHAT_DISCORD_SEND"] = Language["Discord: "]
	_G["CHAT_URL_SEND"] = Language["URL: "]
	_G["CHAT_EMAIL_SEND"] = Language["Email: "]
	_G["CHAT_FRIEND_SEND"] = Language["Friend Tag:"]

	ChatTypeInfo["URL"] = {sticky = 0, r = 255/255, g = 206/255,  b = 84/255}
	ChatTypeInfo["EMAIL"] = {sticky = 0, r = 102/255, g = 187/255,  b = 106/255}
	ChatTypeInfo["DISCORD"] = {sticky = 0, r = 114/255, g = 137/255,  b = 218/255}
	ChatTypeInfo["FRIEND"] = {sticky = 0, r = 0, g = 170/255,  b = 255/255}

	ChatTypeInfo["WHISPER"].sticky = 1
	ChatTypeInfo["BN_WHISPER"].sticky = 1
	ChatTypeInfo["OFFICER"].sticky = 1
	ChatTypeInfo["RAID_WARNING"].sticky = 1
	ChatTypeInfo["CHANNEL"].sticky = 1

	ChatTypeInfo["SAY"].colorNameByClass = true
	ChatTypeInfo["YELL"].colorNameByClass = true
	ChatTypeInfo["GUILD"].colorNameByClass = true
	ChatTypeInfo["OFFICER"].colorNameByClass = true
	ChatTypeInfo["WHISPER"].colorNameByClass = true
	ChatTypeInfo["WHISPER_INFORM"].colorNameByClass = true
	ChatTypeInfo["BN_WHISPER"].colorNameByClass = true
	ChatTypeInfo["BN_WHISPER_INFORM"].colorNameByClass = true
	ChatTypeInfo["PARTY"].colorNameByClass = true
	ChatTypeInfo["PARTY_LEADER"].colorNameByClass = true
	ChatTypeInfo["RAID"].colorNameByClass = true
	ChatTypeInfo["RAID_LEADER"].colorNameByClass = true
	ChatTypeInfo["RAID_WARNING"].colorNameByClass = true
	ChatTypeInfo["INSTANCE_CHAT"].colorNameByClass = true
	ChatTypeInfo["INSTANCE_CHAT_LEADER"].colorNameByClass = true
	ChatTypeInfo["EMOTE"].colorNameByClass = true
	ChatTypeInfo["CHANNEL"].colorNameByClass = true
	ChatTypeInfo["CHANNEL1"].colorNameByClass = true
	ChatTypeInfo["CHANNEL2"].colorNameByClass = true
	ChatTypeInfo["CHANNEL3"].colorNameByClass = true
	ChatTypeInfo["CHANNEL4"].colorNameByClass = true
	ChatTypeInfo["CHANNEL5"].colorNameByClass = true
	ChatTypeInfo["CHANNEL6"].colorNameByClass = true
	ChatTypeInfo["CHANNEL7"].colorNameByClass = true
	ChatTypeInfo["CHANNEL8"].colorNameByClass = true
	ChatTypeInfo["CHANNEL9"].colorNameByClass = true
	ChatTypeInfo["CHANNEL10"].colorNameByClass = true
	ChatTypeInfo["CHANNEL11"].colorNameByClass = true
	ChatTypeInfo["CHANNEL12"].colorNameByClass = true
	ChatTypeInfo["CHANNEL13"].colorNameByClass = true
	ChatTypeInfo["CHANNEL14"].colorNameByClass = true
	ChatTypeInfo["CHANNEL15"].colorNameByClass = true
	ChatTypeInfo["CHANNEL16"].colorNameByClass = true
	ChatTypeInfo["CHANNEL17"].colorNameByClass = true
	ChatTypeInfo["CHANNEL18"].colorNameByClass = true
	ChatTypeInfo["CHANNEL19"].colorNameByClass = true
	ChatTypeInfo["CHANNEL20"].colorNameByClass = true

	if (not HydraUI.IsVanilla) then
		ChatTypeInfo["GUILD_ACHIEVEMENT"].colorNameByClass = true
	end

	if (C_CVar.GetCVar("colorChatNamesByClass") ~= "0") then
		C_CVar.SetCVar("colorChatNamesByClass", 0)
	end

	if (C_CVar.GetCVar("chatClassColorOverride") ~= "0") then
		C_CVar.SetCVar("chatClassColorOverride", 0)
	end
end
local MoveChatFrames = function()
	Chat:MoveChatFrames()
end

function Chat:Load()
	if not Settings["chat-enable"] then
		return
	end

	-- Installation order is intentional: adapters, window, styling, persisted state.
	self:InstallLinkHooks()
	self:CreateChatWindow()
	self:StyleChatFrames()

	HydraUIData = HydraUIData or {}

	if not HydraUIData.ChatInstalled then
		self:Install()
		HydraUIData.ChatInstalled = true
	end

	self:MoveChatFrames()
	self:SetChatTypeInfo()
	self:RestoreHistory()
	self:InstallFrameHooks()
	DEFAULT_CHAT_FRAME:SetUserPlaced(true)

	if HydraUI.IsMainline then
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("CVAR_UPDATE")
		self:RegisterEvent("PLAYER_LEVEL_CHANGED")
	end

	self:RegisterEvent("UI_SCALE_CHANGED")
	self:SetScript("OnEvent", self.MoveChatFrames)
end

local UpdateChatFrameHeight = function(value)
	Chat.Middle:SetHeight(value)
	Chat:MoveChatFrames()
end

local UpdateChatFrameWidth = function()
	local Width = Settings["chat-frame-width"]

	Chat.Bottom:SetWidth(Width)
	Chat.Middle:SetWidth(Width)
	Chat.Top:SetWidth(Width)

	Chat.Window:SetChatDataTextWidth(Width)
	Chat:MoveChatFrames()
end

local UpdateTopHeight = function(value)
	Chat.Top:SetHeight(value)
end

local UpdateBottomHeight = function(value)
	Chat.Top:SetHeight(value)
end

local UpdateTopOpacity = function(value)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-window-main-color"])

	Chat.Top.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateMiddleOpacity = function(value)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-window-main-color"])

	Chat.Middle.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateBottomOpacity = function(value)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-window-main-color"])

	Chat.Bottom.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateChatFont = function()
	Chat:ForEachStyledFrame(function(Frame)

		FCF_SetChatWindowFontSize(nil, Frame, Settings["chat-font-size"])

		local Font, IsPixel = Assets:GetFont(Settings["chat-font"])

		if IsPixel then
			Frame:SetFont(Font, Settings["chat-font-size"], "MONOCHROME, OUTLINE")
			Frame:SetShadowColor(0, 0, 0, 0)
		else
			Frame:SetFont(Font, Settings["chat-font-size"], Settings["chat-font-flags"])
			Frame:SetShadowColor(0, 0, 0)
			Frame:SetShadowOffset(1, -1)
		end
	end)
end

local UpdateChatTabFont = function()
	local R, G, B = HydraUI:HexToRGB(Settings["chat-tab-font-color"])

	Chat:ForEachStyledFrame(function(Frame)
		local TabText = _G[Frame:GetName() .. "TabText"]
		local Font, IsPixel = Assets:GetFont(Settings["chat-tab-font"])

		TabText:_SetTextColor(R, G, B)

		if IsPixel then
			TabText:_SetFont(Font, Settings["chat-tab-font-size"], "MONOCHROME, OUTLINE")
			TabText:SetShadowColor(0, 0, 0, 0)
		else
			TabText:_SetFont(Font, Settings["chat-tab-font-size"], Settings["chat-tab-font-flags"])
			TabText:SetShadowColor(0, 0, 0)
			TabText:SetShadowOffset(1, -1)
		end
	end)
end

local RunChatInstall = function()
	Chat:Install()
	ReloadUI()
end

local UpdateEnableFading = function(value)
	Chat:ForEachStyledFrame(function(frame)
		frame:SetFading(value)
	end)
end

local UpdateFadeTime = function(value)
	Chat:ForEachStyledFrame(function(frame)
		frame:SetTimeVisible(value)
	end)
end

local UpdateEnableLinks = function(value)
	Chat:SetLinkTooltips(value)
end
HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Chat"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("chat-enable", Settings["chat-enable"], Language["Enable Chat Module"], Language["Enable the HydraUI chat module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["General"])
	left:CreateSlider("chat-fade-time", Settings["chat-enable-fading"], 0, 60, 5, Language["Set Fade Time"], Language["Set the duration to display text before fading out"], UpdateFadeTime, nil, "s")
	left:CreateSwitch("chat-enable-fading", Settings["chat-enable-fading"], Language["Enable Text Fading"], Language["Set the text to fade after the set amount of time"], UpdateEnableFading)
	left:CreateSwitch("chat-link-tooltip", Settings["chat-link-tooltip"], Language["Show Link Tooltips"], Language["Display a tooltip when hovering over links in chat"], UpdateEnableLinks)
	left:CreateSwitch("chat-shorten-channels", Settings["chat-shorten-channels"], Language["Shorten Channel Names"], Language["Shorten chat channel names to their channel number"])
	left:CreateSwitch("chat-enable-history", Settings["chat-enable-history"], Language["Enable Chat History"], Language["Restore the last 50 chat messages when logging in"])

	right:CreateHeader(Language["Install"])
	right:CreateButton("", Language["Install"], Language["Install Chat Defaults"], Language["Set default channels and settings related to chat"], RunChatInstall):RequiresReload(true)

	left:CreateHeader(Language["Links"])
	left:CreateSwitch("chat-enable-url-links", Settings["chat-enable-url-links"], Language["Enable URL Links"], Language["Enable URL links in the chat frame"])
	left:CreateSwitch("chat-enable-discord-links", Settings["chat-enable-discord-links"], Language["Enable Discord Links"], Language["Enable Discord links in the chat frame"])
	left:CreateSwitch("chat-enable-email-links", Settings["chat-enable-email-links"], Language["Enable Email Links"], Language["Enable email links in the chat frame"])
	left:CreateSwitch("chat-enable-friend-links", Settings["chat-enable-friend-links"], Language["Enable Friend Tag Links"], Language["Enable friend tag links in the chat frame"])

	right:CreateHeader(Language["Chat Frame Font"])
	right:CreateDropdown("chat-font", Settings["chat-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the chat frame"], UpdateChatFont, "Font")
	right:CreateSlider("chat-font-size", Settings["chat-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the chat frame"], UpdateChatFont)
	right:CreateDropdown("chat-font-flags", Settings["chat-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the chat frame"], UpdateChatFont)

	right:CreateHeader(Language["Tab Font"])
	right:CreateDropdown("chat-tab-font", Settings["chat-tab-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the chat frame tabs"], UpdateChatTabFont, "Font")
	right:CreateSlider("chat-tab-font-size", Settings["chat-tab-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the chat frame tabs"], UpdateChatTabFont)
	right:CreateDropdown("chat-tab-font-flags", Settings["chat-tab-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the chat frame tabs"], UpdateChatTabFont)
	right:CreateColorSelection("chat-tab-font-color", Settings["chat-tab-font-color"], Language["Font Color"], Language["Set the color of the chat frame tabs"], UpdateChatTabFont)
	right:CreateColorSelection("chat-tab-font-color-mouseover", Settings["chat-tab-font-color-mouseover"], Language["Font Color Mouseover"], Language["Set the color of the chat frame tab while hovering over it"])
end)

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Left"], Language["Chat"], function(left, right)
	left:CreateHeader(Language["General"])
	left:CreateSlider("chat-frame-width", Settings["chat-frame-width"], 300, 650, 1, Language["Chat Width"], Language["Set the width of the chat frame"], UpdateChatFrameWidth)
	left:CreateSlider("chat-frame-height", Settings["chat-frame-height"], 40, 350, 1, Language["Chat Height"], Language["Set the height of the chat frame"], UpdateChatFrameHeight)
	left:CreateSlider("chat-top-opacity", Settings["chat-top-opacity"], 0, 100, 5, Language["Top Opacity"], Language["Set the opacity of the chat top"], UpdateTopOpacity, nil, "%")
	left:CreateSlider("chat-bg-opacity", Settings["chat-bg-opacity"], 0, 100, 5, Language["Background Opacity"], Language["Set the opacity of the chat background"], UpdateMiddleOpacity, nil, "%")
	left:CreateSlider("chat-bottom-opacity", Settings["chat-bottom-opacity"], 0, 100, 5, Language["Bottom Opacity"], Language["Set the opacity of the chat bottom"], UpdateBottomOpacity, nil, "%")
end)
