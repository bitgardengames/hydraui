local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local Bubbles = HydraUI:NewModule("Chat Bubbles")

local next = next
local GetAllChatBubbles = C_ChatBubbles.GetAllChatBubbles

local ScanInterval = 0.05
local ScanTimeout = 1
local ScanQuietTimeout = 0.35

local BubbleEvents = {
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_INSTANCE_CHAT",
	"CHAT_MSG_INSTANCE_CHAT_LEADER",
	"CHAT_MSG_MONSTER_SAY",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_MONSTER_WHISPER",
	"CHAT_MSG_MONSTER_PARTY",
}

Defaults["chat-bubbles-enable"] = true
Defaults["chat-bubbles-opacity"] = 70
Defaults["chat-bubbles-font"] = "PT Sans"
Defaults["chat-bubbles-font-size"] = 14
Defaults["chat-bubbles-font-flags"] = ""

function Bubbles:PrepareSettings()
	self.Font = Settings["chat-bubbles-font"]
	self.FontSize = Settings["chat-bubbles-font-size"]
	self.FontFlags = Settings["chat-bubbles-font-flags"]
	self.Opacity = Settings["chat-bubbles-opacity"] / 100
	self.WindowColorR, self.WindowColorG, self.WindowColorB = HydraUI:HexToRGB(Settings["ui-window-main-color"])
end

function Bubbles:RefreshBubble(bubble)
	local Child = bubble:GetChildren()

	if (not Child or Child:IsForbidden() or not bubble.Backdrop) then
		return
	end

	HydraUI:SetFontInfo(Child.String, self.Font, self.FontSize, self.FontFlags)
	bubble.Backdrop:SetBackdropColor(self.WindowColorR, self.WindowColorG, self.WindowColorB, self.Opacity)
end

function Bubbles:SkinBubble(bubble)
	local Child = bubble:GetChildren()

	if (Child and Child:IsForbidden()) then
		return
	end

	Child.Tail:Hide()
	Child:DisableDrawLayer("BORDER")

	if Child.SetBackdrop then
		Child:SetBackdrop(nil)
	end

	HydraUI:SetFontInfo(Child.String, self.Font, self.FontSize, self.FontFlags)

	bubble.Backdrop = CreateFrame("Frame", nil, Child, "BackdropTemplate")
	bubble.Backdrop:SetPoint("TOPLEFT", Child, 4, -4)
	bubble.Backdrop:SetPoint("BOTTOMRIGHT", Child, -4, 4)
	bubble.Backdrop:SetBackdrop(HydraUI.BackdropAndBorder)
	bubble.Backdrop:SetBackdropColor(self.WindowColorR, self.WindowColorG, self.WindowColorB, self.Opacity)
	bubble.Backdrop:SetBackdropBorderColor(0, 0, 0)
	bubble.Backdrop:SetFrameStrata("LOW")

	bubble:SetScale(UIParent:GetScale())

	bubble.Skinned = true
end

function Bubbles:OnUpdate(elapsed)
	self.Elapsed = self.Elapsed + elapsed
	self.ScanElapsed = self.ScanElapsed + elapsed
	self.QuietElapsed = self.QuietElapsed + elapsed

	if (self.Elapsed >= ScanInterval) then
		local FoundUnskinned = false

		for Index, Bubble in next, GetAllChatBubbles() do
			if (not Bubble.Skinned) then
				self:SkinBubble(Bubble)
				FoundUnskinned = FoundUnskinned or Bubble.Skinned
			elseif self.NeedsRefresh then
				self:RefreshBubble(Bubble)
			end
		end

		-- Clear this only after the snapshot returned by GetAllChatBubbles has
		-- been traversed in full.
		self.NeedsRefresh = false

		if FoundUnskinned then
			self.QuietElapsed = 0
		end

		self.Elapsed = 0
	end

	if (self.ScanElapsed >= ScanTimeout or self.QuietElapsed >= ScanQuietTimeout) then
		self:SetScript("OnUpdate", nil)
	end
end

function Bubbles:StartScan()
	if (not self.CanScan) then
		return
	end

	self.Elapsed = ScanInterval
	self.ScanElapsed = 0
	self.QuietElapsed = 0
	self:SetScript("OnUpdate", self.OnUpdate)
end

function Bubbles:OnEvent(event)
	if (event ~= "PLAYER_ENTERING_WORLD") then
		self:StartScan()
		return
	end

	local Name, Type = GetInstanceInfo()

	if (Type == "none") then
		self.CanScan = true
		self:StartScan()
	else
		self.CanScan = false
		self:SetScript("OnUpdate", nil)
	end
end

function Bubbles:Load()
	self:PrepareSettings()

	if (not Settings["chat-bubbles-enable"]) then
		return
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	for Index = 1, #BubbleEvents do
		self:RegisterEvent(BubbleEvents[Index])
	end

	self:SetScript("OnEvent", self.OnEvent)
	self:OnEvent("PLAYER_ENTERING_WORLD")
end

local SetToRefresh = function()
	Bubbles:PrepareSettings()
	Bubbles.NeedsRefresh = true
	Bubbles:StartScan()
end

local UpdateShowBubbles = function(value)
	if (value == "ALL") then
		SetCVar("chatBubbles", 1)
		SetCVar("chatBubblesParty", 1)
	elseif (value == "EXCLUDE_PARTY") then
		SetCVar("chatBubbles", 1)
		SetCVar("chatBubblesParty", 0)
	else -- "NONE"
		SetCVar("chatBubbles", 0)
		SetCVar("chatBubblesParty", 0)
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Chat"], function(left, right)
	right:CreateHeader(Language["Chat Bubbles"])
	right:CreateSwitch("chat-bubbles-enable", Settings["chat-bubbles-enable"], Language["Enable Chat Bubbles"], Language["Enable the HydraUI chat bubbles module"], ReloadUI):RequiresReload(true)
	right:CreateSlider("chat-bubbles-opacity", Settings["chat-bubbles-opacity"], 0, 100, 5, Language["Background Opacity"], Language["Set the opacity of the chat bubbles background"], SetToRefresh, nil, "%")
	right:CreateDropdown("chat-bubbles-font", Settings["chat-bubbles-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the chat bubbles"], SetToRefresh, "Font")
	right:CreateSlider("chat-bubbles-font-size", Settings["chat-bubbles-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the chat bubbles"], SetToRefresh)
	right:CreateDropdown("chat-bubbles-font-flags", Settings["chat-bubbles-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the chat bubbles"], SetToRefresh)
	--right:CreateDropdown("chat-bubbles-show", Settings["chat-bubbles-show"], {[Language["All"]] = "ALL", [Language["None"]] = "NONE", [Language["Exclude Party"]] = "EXCLUDE_PARTY"}, Language["Show Chat Bubbles"], "Set who to display chat bubbles from", UpdateShowBubbles)
end)
