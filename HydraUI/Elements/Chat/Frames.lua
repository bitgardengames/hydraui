local HydraUI, Language, Assets, Settings = select(2, ...):get()
local Chat = HydraUI:GetModule("Chat")
local select, match, gsub = select, string.match, string.gsub
local NoCall = function() end
local CHAT_LABEL = CHAT_LABEL
local DT

Chat.StyledFrames = Chat.StyledFrames or {}
Chat.TemporaryWindowHooks = Chat.TemporaryWindowHooks or {}
function Chat:ForEachStyledFrame(callback)
	for frame in pairs(self.StyledFrames) do callback(frame) end
end

Chat.RemoveTextures = {
	"TabLeft",
	"TabMiddle",
	"TabRight",
	"TabSelectedLeft",
	"TabSelectedMiddle",
	"TabSelectedRight",
	"TabHighlightLeft",
	"TabHighlightMiddle",
	"TabHighlightRight",
	"ButtonFrameUpButton",
	"ButtonFrameDownButton",
	"ButtonFrameBottomButton",
	"ButtonFrameMinimizeButton",
	"ButtonFrame",
	"EditBoxFocusLeft",
	"EditBoxFocusMid",
	"EditBoxFocusRight",
	"EditBoxLeft",
	"EditBoxMid",
	"EditBoxRight",
}

local Disable = function(object)
	if not object then
		return
	end

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end

	if (object.HasScript and object:HasScript("OnUpdate")) then
		object:SetScript("OnUpdate", nil)
	end

	object.Show = NoCall
	object:Hide()
end

local OnMouseWheel = function(self, delta)
	if (delta < 0) then
		if IsShiftKeyDown() then
			self:ScrollToBottom()
		elseif IsControlKeyDown() then
			for i = 1, 5 do
				self:ScrollDown()
			end
		else
			self:ScrollDown()
		end
	elseif (delta > 0) then
		if IsShiftKeyDown() then
			self:ScrollToTop()
		elseif IsControlKeyDown() then
			for i = 1, 5 do
				self:ScrollUp()
			end
		else
			self:ScrollUp()
		end
	end
end

local UpdateHeader = function(editbox)
	local ChatType = editbox:GetAttribute("chatType")

	if (ChatType == "CHANNEL") then
		if editbox:GetAttribute("channelTarget") then
			local ID = GetChannelName(editbox:GetAttribute("channelTarget"))

			if (ID == 0) then
				Chat.EditBox.Outside:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))
			else
				Chat.EditBox.Outside:SetBackdropColor(ChatTypeInfo[ChatType..ID].r * 0.2, ChatTypeInfo[ChatType..ID].g * 0.2, ChatTypeInfo[ChatType..ID].b * 0.2)
			end
		else
			Chat.EditBox.Outside:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))
		end
	else
		Chat.EditBox.Outside:SetBackdropColor(ChatTypeInfo[ChatType].r * 0.2, ChatTypeInfo[ChatType].g * 0.2, ChatTypeInfo[ChatType].b * 0.2)
	end
end

local OnEditFocusLost = function(self)
	local Left = DT:GetAnchor("Chat-Left")
	local Middle = DT:GetAnchor("Chat-Middle")
	local Right = DT:GetAnchor("Chat-Right")

	Chat.EditBox:SetAlpha(0)
	Chat.EditBox:EnableMouse(false)

	if Left then Left:SetAlpha(1) end
	if Middle then Middle:SetAlpha(1) end
	if Right then Right:SetAlpha(1) end

	if Settings["data-text-enable-tooltips"] then
		if Left then Left:EnableMouse(true) end
		if Middle then Middle:EnableMouse(true) end
		if Right then Right:EnableMouse(true) end
	end
end

local OnEditFocusGained = function(self)
	local Left = DT:GetAnchor("Chat-Left")
	local Middle = DT:GetAnchor("Chat-Middle")
	local Right = DT:GetAnchor("Chat-Right")

	if Left then
		Left:SetAlpha(0)

		if Left:IsMouseEnabled() then
			Left:EnableMouse(false)
		end
	end

	if Middle then
		Middle:SetAlpha(0)

		if Middle:IsMouseEnabled() then
			Middle:EnableMouse(false)
		end
	end

	if Right then
		Right:SetAlpha(0)

		if Right:IsMouseEnabled() then
			Right:EnableMouse(false)
		end
	end

	Chat.EditBox:SetAlpha(1)
	Chat.EditBox:EnableMouse(true)
end

local CheckForBottom = function(self)
	if (not self:AtBottom() and not self.JumpButton.FadeIn:IsPlaying()) then
		if (self.JumpButton:GetAlpha() == 0) then
			self.JumpButton:Show()
			self.JumpButton.FadeIn:Play()
		end
	elseif (self:AtBottom() and self.JumpButton:IsShown() and not self.JumpButton.FadeOut:IsPlaying()) then
		if (self.JumpButton:GetAlpha() > 0) then
			self.JumpButton.FadeOut:Play()
		end
	end
end

local JumpButtonOnMouseUp = function(self)
	self:GetParent():ScrollToBottom()
end

local JumpButtonOnEnter = function(self)
	self.Arrow:SetVertexColor(1, 1, 1)
end

local JumpButtonOnLeave = function(self)
	self.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
end

local JumpButtonOnFinished = function(self)
	self.Parent:Hide()
end

local TabOnEnter = function(self)
	self.TabText:_SetTextColor(HydraUI:HexToRGB(Settings["chat-tab-font-color-mouseover"]))
end

local TabOnLeave = function(self)
	self.TabText:_SetTextColor(HydraUI:HexToRGB(Settings["chat-tab-font-color"]))
end

local ValidLinkTypes = {
	["item"] = true,
	["spell"] = true,
	["enchant"] = true,
}

local OnHyperlinkEnter = function(self, link, text, button)
	local LinkType = match(link, "^(%a+):")

	if (not ValidLinkTypes[LinkType]) then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:ClearAllPoints()

	--GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
end

local OnHyperlinkLeave = function(self)
	GameTooltip:Hide()
end

function Chat:OverrideAddMessage(msg, ...)
	if Settings["chat-shorten-channels"] and (type(msg) == "string") then
		msg = gsub(msg, "|h%[(%d+)%.%s.-%]|h", "|h[%1]|h")
	end

	Chat:SaveMessage(self, msg, ...)
	self.OldAddMessage(self, msg, ...)
end

function Chat:StyleChatFrame(frame)
	if frame.Styled then
		return
	end

	if (frame ~= ChatFrame2) then
		frame.OldAddMessage = frame.AddMessage
		frame.AddMessage = Chat.OverrideAddMessage
	end

	local FrameName = frame:GetName()
	local Tab = _G[FrameName.."Tab"]
	local TabText = Tab.Text or _G[FrameName.."TabText"]
	local EditBox = _G[FrameName.."EditBox"]
	local Minimize = _G[FrameName.."MinimizeButton"]

	if frame.ScrollBar then
		Disable(frame.ScrollBar)
		Disable(frame.ScrollToBottomButton)
		Disable(_G[FrameName.."ThumbTexture"])
	end

	if Tab.conversationIcon then
		Disable(Tab.conversationIconKill)
	end

	if Minimize then
		Disable(Minimize)
	end

	-- Tabs Alpha
	Tab.mouseOverAlpha = 1
	Tab.noMouseAlpha = 1
	Tab:SetAlpha(1)
	Tab.SetAlpha = UIFrameFadeRemoveFrame
	Tab.TabText = TabText

	if Tab.ActiveLeft then
		Tab.Left:SetTexture(nil)
		Tab.HighlightLeft:SetTexture(nil)
		Tab.ActiveLeft:SetTexture(nil)
		Tab.Middle:SetTexture(nil)
		Tab.HighlightMiddle:SetTexture(nil)
		Tab.ActiveMiddle:SetTexture(nil)
		Tab.Right:SetTexture(nil)
		Tab.HighlightRight:SetTexture(nil)
		Tab.ActiveRight:SetTexture(nil)
	end

	Tab:HookScript("OnEnter", TabOnEnter)
	Tab:HookScript("OnLeave", TabOnLeave)

	if TabText then
		HydraUI:SetFontInfo(TabText, Settings["chat-tab-font"], Settings["chat-tab-font-size"], Settings["chat-tab-font-flags"])
		TabText._SetFont = TabText.SetFont
		TabText.SetFont = NoCall

		TabText:SetTextColor(HydraUI:HexToRGB(Settings["chat-tab-font-color"]))
		TabText._SetTextColor = TabText.SetTextColor
		TabText.SetTextColor = NoCall

		if Tab.glow then
			Tab.glow:ClearAllPoints()
			Tab.glow:SetPoint("BOTTOM", Tab, 0, 1 > Settings["ui-border-thickness"] and -1 or -(Settings["ui-border-thickness"] + 2)) -- 1
			Tab.glow:SetWidth(TabText:GetStringWidth() + 10)
		end
	end

	frame:SetFrameStrata("MEDIUM")
	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	frame:SetFading(false)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseWheel", OnMouseWheel)
	frame:SetSize(self:GetWidth() - 8, self:GetHeight() - 8)
	frame:SetFrameLevel(self:GetFrameLevel() + 1)
	frame:SetFrameStrata("MEDIUM")
	frame:SetJustifyH("LEFT")
	frame:SetFading(Settings["chat-enable-fading"])
	frame:SetTimeVisible(Settings["chat-fade-time"])
	frame:Hide()

	if Settings["chat-link-tooltip"] then
		frame:SetScript("OnHyperlinkEnter", OnHyperlinkEnter)
		frame:SetScript("OnHyperlinkLeave", OnHyperlinkLeave)
	end

	FCF_SetChatWindowFontSize(nil, frame, 12)

	if (not frame.isLocked) then
		FCF_SetLocked(frame, 1)
	end

	EditBox:ClearAllPoints()
	EditBox:SetPoint("TOPLEFT", self.EditBox, -2, 0)
	EditBox:SetPoint("BOTTOMRIGHT", self.EditBox, 0, 0)
	HydraUI:SetFontInfo(EditBox, Settings["chat-font"], Settings["chat-font-size"], Settings["chat-font-flags"])
	EditBox:SetAltArrowKeyMode(false)
	EditBox:SetTextInsets(0, 0, 0, 0)
	EditBox:SetAlpha(0)
	EditBox:EnableMouse(false)
	EditBox:HookScript("OnEditFocusLost", OnEditFocusLost)
	EditBox:HookScript("OnEditFocusGained", OnEditFocusGained)

	HydraUI:SetFontInfo(EditBox.header, Settings["chat-font"], Settings["chat-font-size"], Settings["chat-font-flags"])

	-- Scroll to bottom
	--if (not HydraUI.IsMainline) then
		local JumpButton = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		JumpButton:SetSize(20, 20)
		JumpButton:SetPoint("BOTTOMRIGHT", frame, 0, 0)
		JumpButton:SetBackdrop(HydraUI.BackdropAndBorder)
		JumpButton:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
		JumpButton:SetBackdropBorderColor(0, 0, 0)
		JumpButton:SetFrameStrata("HIGH")
		JumpButton:SetScript("OnMouseUp", JumpButtonOnMouseUp)
		JumpButton:SetScript("OnEnter", JumpButtonOnEnter)
		JumpButton:SetScript("OnLeave", JumpButtonOnLeave)
		JumpButton:SetAlpha(0)
		JumpButton:Hide()

		JumpButton.Texture = JumpButton:CreateTexture(nil, "ARTWORK")
		JumpButton.Texture:SetPoint("TOPLEFT", JumpButton, 1, -1)
		JumpButton.Texture:SetPoint("BOTTOMRIGHT", JumpButton, -1, 1)
		JumpButton.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
		JumpButton.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

		JumpButton.Arrow = JumpButton:CreateTexture(nil, "OVERLAY")
		JumpButton.Arrow:SetPoint("CENTER", JumpButton, 0, 0)
		JumpButton.Arrow:SetSize(16, 16)
		JumpButton.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
		JumpButton.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

		JumpButton.Fade = LibMotion:CreateAnimationGroup()

		JumpButton.FadeIn = LibMotion:CreateAnimation(JumpButton, "Fade")
		JumpButton.FadeIn:SetEasing("in")
		JumpButton.FadeIn:SetDuration(0.15)
		JumpButton.FadeIn:SetChange(1)

		JumpButton.FadeOut = LibMotion:CreateAnimation(JumpButton, "Fade")
		JumpButton.FadeOut:SetEasing("out")
		JumpButton.FadeOut:SetDuration(0.15)
		JumpButton.FadeOut:SetChange(0)
		JumpButton.FadeOut:SetScript("OnFinished", JumpButtonOnFinished)

		frame.JumpButton = JumpButton

		hooksecurefunc(frame, "SetScrollOffset", CheckForBottom)
	--end

	-- Remove textures
	for i = 1, #CHAT_FRAME_TEXTURES do
		_G[FrameName..CHAT_FRAME_TEXTURES[i]]:SetTexture(nil)
	end

	for i = 1, #self.RemoveTextures do
		Disable(_G[FrameName..self.RemoveTextures[i]])
	end

	FCFTab_UpdateAlpha(frame)

	frame.Styled = true
	self.StyledFrames[frame] = true
end

local OpenTemporaryWindow = function()
	local Frame = FCF_GetCurrentChatFrame()

	if (Frame.name and Frame.name == PET_BATTLE_COMBAT_LOG) then
		return FCF_Close(Frame)
	end

	if (not Frame.Styled) then
		Chat:StyleChatFrame(Frame)
	end
end

function Chat:MoveChatFrames()
	-- Override edit mode
	EDIT_MODE_CLASSIC_SYSTEM_MAP[Enum.EditModeSystem.ChatFrame] = {
		settings = {
			[Enum.EditModeChatFrameSetting.WidthHundreds] = 4,
			[Enum.EditModeChatFrameSetting.WidthTensAndOnes] = 30,
			[Enum.EditModeChatFrameSetting.HeightHundreds] = 1,
			[Enum.EditModeChatFrameSetting.HeightTensAndOnes] = 20,
		},
		anchorInfo = {
			point = "CENTER",
			relativeTo = self.Middle,
			relativePoint = "CENTER",
			offsetX = 0,
			offsetY = 0,
		},
	}

	for Frame in pairs(self.StyledFrames) do

		Frame:SetFrameLevel(self.Middle:GetFrameLevel() + 1)
		Frame:SetFrameStrata("MEDIUM")
		Frame:SetJustifyH("LEFT")

		if Frame.Tab then -- only Voice has .Tab
			FCF_UnDockFrame(Frame)
			FCF_SetLocked(Frame, false)
			FCF_Close(Frame)
		end

		if (Settings["right-window-enable"] and (Settings["right-window-size"] == "SINGLE") and (Frame.name and Frame.name == Settings["rw-single-embed"])) then
			local EmbedFrame = Chat.Window:GetEmbedFrame()

			FCF_UnDockFrame(Frame)
			FCF_SetTabPosition(Frame, 0)

			Frame:SetMovable(true)
			Frame:SetUserPlaced(true)
			Frame:ClearAllPoints()
			Frame:SetPoint("TOPLEFT", EmbedFrame, 4 + Settings["ui-border-thickness"], -(4 + Settings["ui-border-thickness"]))
			Frame:SetPoint("BOTTOMRIGHT", EmbedFrame, -(4 + Settings["ui-border-thickness"]), 4 + Settings["ui-border-thickness"])
			Frame:Show()
		else
			--if (Frame.name and (not match(Frame.name, CHAT_LABEL .. "%s%d+")) and not Frame.Tab) then
			if (not Frame.isLocked) and (Frame.name and Frame.name ~= VOICE_LABEL) then
				FCF_DockFrame(Frame)
			end

			if (Frame == ChatFrame1) then
				Frame:SetUserPlaced(true)
				Frame:ClearAllPoints()
				--Frame:SetHeight(92)
				Frame:SetPoint("TOPLEFT", self.Top, "BOTTOMLEFT", 4, -2)
				Frame:SetPoint("BOTTOMRIGHT", self.Bottom, "TOPRIGHT", -4, 2)
				--Frame:SetPoint("TOPLEFT", self.Middle, 4 + Settings["ui-border-thickness"], -(4 + Settings["ui-border-thickness"]))
				--Frame:SetPoint("BOTTOMRIGHT", self.Middle, -(4 + Settings["ui-border-thickness"]), 4 + Settings["ui-border-thickness"])
			end
		end

		if (not Frame.isLocked) then
			FCF_SetLocked(Frame, true)
		end

		FCF_SetChatWindowFontSize(nil, Frame, Settings["chat-font-size"])
		--FCF_SavePositionAndDimensions(Frame)

		local Font, IsPixel = Assets:GetFont(Settings["chat-font"])

		if IsPixel then
			Frame:SetFont(Font, Settings["chat-font-size"], "MONOCHROME, OUTLINE")
			Frame:SetShadowColor(0, 0, 0, 0)
		else
			Frame:SetFont(Font, Settings["chat-font-size"], Settings["chat-font-flags"])
			Frame:SetShadowColor(0, 0, 0)
			Frame:SetShadowOffset(1, -1)
		end
	end

	GeneralDockManager:ClearAllPoints()
	GeneralDockManager:SetFrameStrata("MEDIUM")

	if (HydraUI.ClientVersion >= 100000) then
		GeneralDockManager:SetPoint("LEFT", self.Top, 0, 0)
		GeneralDockManager:SetPoint("RIGHT", self.Top, 0, 0)
	else
		GeneralDockManager:SetPoint("LEFT", self.Top, 0, 5)
		GeneralDockManager:SetPoint("RIGHT", self.Top, 0, 5)
	end

	GeneralDockManagerOverflowButton:ClearAllPoints()
	GeneralDockManagerOverflowButton:SetPoint("RIGHT", self.Top, -2, 0)
end

function Chat:StyleChatFrames()
	-- DataText is registered after this file is loaded. Resolve it once during
	-- module initialization, before the edit-box focus hooks can run.
	DT = HydraUI:GetModule("DataText")

	for i = 1, NUM_CHAT_WINDOWS do
		self:StyleChatFrame(_G["ChatFrame"..i])
	end

	Disable(ChatConfigFrameDefaultButton)
	Disable(ChatFrameMenuButton)
	Disable(QuickJoinToastButton)

	Disable(ChatFrameChannelButton)
	Disable(ChatFrameToggleVoiceDeafenButton)
	Disable(ChatFrameToggleVoiceMuteButton)

	-- Restyle Combat Log objects
	CombatLogQuickButtonFrame_Custom:ClearAllPoints()
	CombatLogQuickButtonFrame_Custom:SetHeight(26)
	CombatLogQuickButtonFrame_Custom:SetPoint("TOPLEFT", ChatFrame2, -4, 29)
	CombatLogQuickButtonFrame_Custom:SetPoint("TOPRIGHT", ChatFrame2, 4, 29)

	CombatLogQuickButtonFrame_CustomProgressBar:ClearAllPoints()
	CombatLogQuickButtonFrame_CustomProgressBar:SetPoint("BOTTOMLEFT", CombatLogQuickButtonFrame_Custom, 1, 1)
	CombatLogQuickButtonFrame_CustomProgressBar:SetPoint("BOTTOMRIGHT", CombatLogQuickButtonFrame_Custom, -1, 1)
	CombatLogQuickButtonFrame_CustomProgressBar:SetHeight(3)
	CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))

	for i = 1, CombatLogQuickButtonFrame_Custom:GetNumChildren() do
		local Child = select(i, CombatLogQuickButtonFrame_Custom:GetChildren())

		for i = 1, Child:GetNumRegions() do
			local Region = select(i, Child:GetRegions())

			if (Region:GetObjectType() == "FontString") then
				HydraUI:SetFontInfo(Region, Settings["chat-tab-font"], Settings["chat-tab-font-size"], Settings["chat-tab-font-flags"])
			end
		end
	end
end

function Chat:InstallFrameHooks()
 hooksecurefunc("ChatEdit_UpdateHeader", UpdateHeader)
 local hooks = self.TemporaryWindowHooks
 hooks.FCF_OpenTemporaryWindow = OpenTemporaryWindow
 hooks.FCF_RestorePositionAndDimensions = function() Chat:MoveChatFrames() end
 hooks.FCF_SavePositionAndDimensions = hooks.FCF_RestorePositionAndDimensions
 for name, callback in pairs(hooks) do hooksecurefunc(name, callback) end
 if UIParent_ManageFramePositions then hooksecurefunc("UIParent_ManageFramePositions", hooks.FCF_RestorePositionAndDimensions) end
end

function Chat:SetLinkTooltips(enabled)
 self:ForEachStyledFrame(function(frame)
  frame:SetScript("OnHyperlinkEnter", enabled and OnHyperlinkEnter or nil)
  frame:SetScript("OnHyperlinkLeave", enabled and OnHyperlinkLeave or nil)
 end)
end
