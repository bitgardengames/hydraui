local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local Core = GUI.WidgetCore
local SPACING, HEADER_HEIGHT, HEADER_SPACING = Core.SPACING, Core.HEADER_HEIGHT, Core.HEADER_SPACING
local GROUP_HEIGHT, GROUP_WIDTH, WIDGET_HEIGHT = Core.GROUP_HEIGHT, Core.GROUP_WIDTH, Core.WIDGET_HEIGHT
local LABEL_SPACING = Core.LABEL_SPACING
local SELECTED_HIGHLIGHT_ALPHA, MOUSEOVER_HIGHLIGHT_ALPHA = Core.SELECTED_HIGHLIGHT_ALPHA, Core.MOUSEOVER_HIGHLIGHT_ALPHA
local RegisterWidget, SetVariable = Core.RegisterWidget, Core.SetVariable
local Round, TrimHex = Core.Round, Core.TrimHex
local type, next, tonumber = type, next, tonumber
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local match, upper, lower, sub, gsub, find = string.match, string.upper, string.lower, string.sub, string.gsub, string.find
local floor, max, min = math.floor, math.max, math.min
local InCombatLockdown, IsModifierKeyDown = InCombatLockdown, IsModifierKeyDown

-- Line
GUI.Widgets.CreateLine = function(self, id, text)
	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)

	local Text = Anchor:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Anchor, HEADER_SPACING, 0)
	Text:SetSize(GROUP_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetText(format("|cFF%s%s|r", Settings["ui-widget-font-color"], tostring(text)))

	Anchor.Text = Text

	RegisterWidget(self, Anchor, id)

	return Text
end

-- Double Line
GUI.Widgets.CreateDoubleLine = function(self, id, left, right)
	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)

	local Left = Anchor:CreateFontString(nil, "OVERLAY")
	Left:SetPoint("LEFT", Anchor, HEADER_SPACING, 0)
	Left:SetSize((GROUP_WIDTH / 2) - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Left, Settings["ui-widget-font"], Settings["ui-font-size"])
	Left:SetJustifyH("LEFT")
	Left:SetText(format("|cFF%s%s|r", Settings["ui-widget-font-color"], tostring(left)))

	local Right = Anchor:CreateFontString(nil, "OVERLAY")
	Right:SetPoint("RIGHT", Anchor, -HEADER_SPACING, 0)
	Right:SetSize((GROUP_WIDTH / 2) - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Right, Settings["ui-widget-font"], Settings["ui-font-size"])
	Right:SetJustifyH("RIGHT")
	Right:SetText(format("|cFF%s%s|r", Settings["ui-widget-font-color"], tostring(right)))

	Anchor.Left = Left
	Anchor.Right = Right

	RegisterWidget(self, Anchor, id)

	return Left
end

-- Message
local CheckString = HydraUI.UIParent:CreateFontString(nil, "OVERLAY")
CheckString:SetWidth(GROUP_WIDTH - 6)
CheckString:SetJustifyH("LEFT")

GUI.Widgets.CreateMessage = function(self, id, text) -- Create as many lines as needed for the message
	HydraUI:SetFontInfo(CheckString, Settings["ui-widget-font"], Settings["ui-font-size"])
	CheckString:SetText(text)

	local Line = ""
	local NewLine = ""
	local Indent = 0
	local LineID = 1

	for word in string.gmatch(text, "(%S+)") do
		NewLine = Line .. (Indent == 0 and "" or " ") .. word

		CheckString:SetText(NewLine)

		if CheckString:GetStringWidth() >= (GROUP_WIDTH - 6) then
			if find(Line, "(%S+)$") then -- A word needs to be wrapped
				self:CreateLine(format("%s-%s", id, LineID), Line)
				Line = word -- Start a new line with the wrapped word
				Indent = 1
				LineID = LineID + 1
			else
				self:CreateLine(format("%s-%s", id, LineID), NewLine)
				Line = "" -- Start a new line
				Indent = 0
				LineID = LineID + 1
			end
		else
			Line = NewLine
			Indent = 1
			LineID = LineID + 1
		end
	end

	self:CreateLine(format("%s-%s", id, LineID), Line)
end

local AnimatedLineOnShow = function(self)
	if not self.Fade:IsPlaying() then
		self.Fade:Play()
	end
end

local AnimatedLineOnHide = function(self)
	if self.Fade:IsPlaying() then
		self.Fade:Stop()
	end
end

GUI.Widgets.CreateAnimatedLine = function(self, id, left, right, r, g, b)
	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)

	local Left = Anchor:CreateFontString(nil, "OVERLAY")
	Left:SetPoint("LEFT", Anchor, HEADER_SPACING, 0)
	Left:SetSize(GROUP_WIDTH - 8, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Left, Settings["ui-widget-font"], 16)
	Left:SetJustifyH("LEFT")
	Left:SetText(format("|cFF%s%s|r", Settings["ui-widget-font-color"], left))

	local Parent = CreateFrame("Frame", nil, Anchor)
	Parent:SetSize(Left:GetStringWidth() + 8, WIDGET_HEIGHT + 4)
	Parent:SetPoint("LEFT", Left, 0, 0)
	Parent:SetAlpha(0.2)
	Parent:SetScript("OnShow", AnimatedLineOnShow)
	Parent:SetScript("OnHide", AnimatedLineOnHide)
	Parent:SetFrameLevel(Anchor:GetFrameLevel() - 1)

	local Top = Parent:CreateTexture(nil, "ARTWORK")
	Top:SetSize(Parent:GetWidth(), WIDGET_HEIGHT / 2 + 2)
	Top:SetPoint("TOP", Parent, -3, 0)
	Top:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Top:SetVertexColor(r * 1.7, g * 1.7, b * 1.7)

	Anchor.Bottom = Parent:CreateTexture(nil, "ARTWORK")
	Anchor.Bottom:SetSize(Parent:GetWidth(), WIDGET_HEIGHT / 2 + 2)
	Anchor.Bottom:SetPoint("BOTTOM", Parent, -3, 0)
	Anchor.Bottom:SetTexture(Assets:GetTexture("RenHorizonDown"))
	Anchor.Bottom:SetVertexColor(r * 1.7, g * 1.7, b * 1.7)

	local Group = LibMotion:CreateAnimationGroup()
	Group:SetLooping(true)

	local In = LibMotion:CreateAnimation(Parent, "Fade")
	In:SetEasing("in")
	In:SetDuration(1)
	In:SetChange(0.5)
	In:SetGroup(Group)

	local Out = LibMotion:CreateAnimation(Parent, "Fade")
	Out:SetEasing("out")
	Out:SetDuration(1)
	Out:SetChange(0.2)
	Out:SetOrder(2)
	Out:SetGroup(Group)

	local ScaleIn = LibMotion:CreateAnimation(Parent, "Scale")
	ScaleIn:SetEasing("in")
	ScaleIn:SetDuration(0.5)
	ScaleIn:SetChange(0.8)
	ScaleIn:SetGroup(Group)

	local ScaleOut = LibMotion:CreateAnimation(Parent, "Scale")
	ScaleOut:SetEasing("out")
	ScaleOut:SetDuration(0.5)
	ScaleOut:SetChange(1)
	ScaleOut:SetOrder(2)
	ScaleOut:SetGroup(Group)

	RegisterWidget(self, Anchor, id)
end

GUI.Widgets.CreateAnimatedDoubleLine = function(self, id, left, right, r, g, b)
	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)

	Anchor.Left = Anchor:CreateFontString(nil, "OVERLAY")
	Anchor.Left:SetPoint("LEFT", Anchor, HEADER_SPACING, 0)
	Anchor.Left:SetSize(GROUP_WIDTH - 8, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Anchor.Left, Settings["ui-widget-font"], 16)
	Anchor.Left:SetJustifyH("LEFT")
	Anchor.Left:SetText(left)

	Anchor.LeftParent = CreateFrame("Frame", nil, Anchor)
	Anchor.LeftParent:SetSize(Anchor.Left:GetStringWidth() + 8, WIDGET_HEIGHT + 4)
	Anchor.LeftParent:SetPoint("LEFT", Anchor.Left, 0, -1)
	Anchor.LeftParent:SetAlpha(0.2)
	Anchor.LeftParent:SetScript("OnShow", AnimatedLineOnShow)
	Anchor.LeftParent:SetScript("OnHide", AnimatedLineOnHide)
	Anchor.LeftParent:SetFrameLevel(Anchor:GetFrameLevel() - 1)

	Anchor.TopLeft = Anchor.LeftParent:CreateTexture(nil, "ARTWORK")
	Anchor.TopLeft:SetSize(Anchor.LeftParent:GetWidth(), WIDGET_HEIGHT / 2 + 2)
	Anchor.TopLeft:SetPoint("TOP", Anchor.LeftParent, -3, 0)
	Anchor.TopLeft:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Anchor.TopLeft:SetVertexColor(r * 1.7, g * 1.7, b * 1.7)

	Anchor.BottomLeft = Anchor.LeftParent:CreateTexture(nil, "ARTWORK")
	Anchor.BottomLeft:SetSize(Anchor.LeftParent:GetWidth(), WIDGET_HEIGHT / 2 + 2)
	Anchor.BottomLeft:SetPoint("BOTTOM", Anchor.LeftParent, -3, 0)
	Anchor.BottomLeft:SetTexture(Assets:GetTexture("RenHorizonDown"))
	Anchor.BottomLeft:SetVertexColor(r * 1.7, g * 1.7, b * 1.7)

	Anchor.LeftParent.Fade = LibMotion:CreateAnimationGroup()
	Anchor.LeftParent.Fade:SetLooping(true)

	Anchor.LeftParent.In = LibMotion:CreateAnimation(Anchor.LeftParent, "Fade")
	Anchor.LeftParent.In:SetEasing("in")
	Anchor.LeftParent.In:SetDuration(1)
	Anchor.LeftParent.In:SetChange(0.5)

	Anchor.LeftParent.Out = LibMotion:CreateAnimation(Anchor.LeftParent, "Fade")
	Anchor.LeftParent.Out:SetEasing("out")
	Anchor.LeftParent.Out:SetDuration(1)
	Anchor.LeftParent.Out:SetChange(0.2)
	Anchor.LeftParent.Out:SetOrder(2)

	Anchor.LeftParent.SIn = LibMotion:CreateAnimation(Anchor.LeftParent, "Scale")
	Anchor.LeftParent.SIn:SetEasing("in")
	Anchor.LeftParent.SIn:SetDuration(0.5)
	Anchor.LeftParent.SIn:SetChange(0.8)

	Anchor.LeftParent.SOut = LibMotion:CreateAnimation(Anchor.LeftParent, "Scale")
	Anchor.LeftParent.SOut:SetEasing("out")
	Anchor.LeftParent.SOut:SetDuration(0.5)
	Anchor.LeftParent.SOut:SetChange(1)
	Anchor.LeftParent.SOut:SetOrder(2)

	if right then
		Anchor.Right = Anchor:CreateFontString(nil, "OVERLAY")
		Anchor.Right:SetPoint("RIGHT", Anchor, -HEADER_SPACING, 0)
		Anchor.Right:SetSize(GROUP_WIDTH - 8, WIDGET_HEIGHT)
		HydraUI:SetFontInfo(Anchor.Right, Settings["ui-widget-font"], 16)
		Anchor.Right:SetJustifyH("RIGHT")
		Anchor.Right:SetText(right)

		Anchor.RightParent = CreateFrame("Frame", nil, Anchor)
		Anchor.RightParent:SetSize(Anchor.Right:GetStringWidth() + 8, WIDGET_HEIGHT + 4)
		Anchor.RightParent:SetPoint("RIGHT", Anchor.Right, 0, -1)
		Anchor.RightParent:SetAlpha(0.2)
		Anchor.RightParent:SetScript("OnShow", AnimatedLineOnShow)
		Anchor.RightParent:SetScript("OnHide", AnimatedLineOnHide)
		Anchor.RightParent:SetFrameLevel(Anchor:GetFrameLevel() - 1)

		Anchor.TopRight = Anchor.RightParent:CreateTexture(nil, "ARTWORK")
		Anchor.TopRight:SetSize(Anchor.RightParent:GetWidth(), WIDGET_HEIGHT / 2 + 2)
		Anchor.TopRight:SetPoint("TOP", Anchor.RightParent, 3, 0)
		Anchor.TopRight:SetTexture(Assets:GetTexture("RenHorizonUp"))
		Anchor.TopRight:SetVertexColor(r * 1.7, g * 1.7, b * 1.7)

		Anchor.BottomRight = Anchor.RightParent:CreateTexture(nil, "ARTWORK")
		Anchor.BottomRight:SetSize(Anchor.RightParent:GetWidth(), WIDGET_HEIGHT / 2 + 2)
		Anchor.BottomRight:SetPoint("BOTTOM", Anchor.RightParent, 3, 0)
		Anchor.BottomRight:SetTexture(Assets:GetTexture("RenHorizonDown"))
		Anchor.BottomRight:SetVertexColor(r * 1.7, g * 1.7, b * 1.7)

		Anchor.RightParent.Fade = LibMotion:CreateAnimationGroup()
		Anchor.RightParent.Fade:SetLooping(true)

		Anchor.RightParent.In = LibMotion:CreateAnimation(Anchor.RightParent, "Fade")
		Anchor.RightParent.In:SetEasing("in")
		Anchor.RightParent.In:SetDuration(1)
		Anchor.RightParent.In:SetChange(0.5)

		Anchor.RightParent.Out = LibMotion:CreateAnimation(Anchor.RightParent, "Fade")
		Anchor.RightParent.Out:SetEasing("out")
		Anchor.RightParent.Out:SetDuration(1)
		Anchor.RightParent.Out:SetChange(0.2)
		Anchor.RightParent.Out:SetOrder(2)

		Anchor.RightParent.SIn = LibMotion:CreateAnimation(Anchor.RightParent, "Scale")
		Anchor.RightParent.SIn:SetEasing("in")
		Anchor.RightParent.SIn:SetDuration(0.5)
		Anchor.RightParent.SIn:SetChange(0.8)

		Anchor.RightParent.SOut = LibMotion:CreateAnimation(Anchor.RightParent, "Scale")
		Anchor.RightParent.SOut:SetEasing("out")
		Anchor.RightParent.SOut:SetDuration(0.5)
		Anchor.RightParent.SOut:SetChange(1)
		Anchor.RightParent.SOut:SetOrder(2)
	end

	RegisterWidget(self, Anchor, id)

	return Anchor.Left, Anchor.Right
end

GUI.Widgets.CreateHeader = function(self, text)
	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.IsHeader = true

	local Text = Anchor:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("CENTER", Anchor, 0, 0)
	Text:SetHeight(WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-header-font"], 12)
	Text:SetJustifyH("CENTER")
	Text:SetText("|cFF"..Settings["ui-header-font-color"]..text.."|r")

	local BG = Anchor:CreateTexture(nil, "BORDER")
	BG:SetAllPoints()
	BG:SetColorTexture(0, 0, 0)

	local Texture = Anchor:CreateTexture(nil, "ARTWORK")
	Texture:SetPoint("TOPLEFT", Anchor, 1, -1)
	Texture:SetPoint("BOTTOMRIGHT", Anchor, -1, 1)
	Texture:SetTexture(Assets:GetTexture("Blank"))
	Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	RegisterWidget(self, Anchor, "")

	return Text
end

-- Footer
GUI.Widgets.CreateFooter = function(self)
	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.IsHeader = true

	local BG = Anchor:CreateTexture(nil, "BORDER")
	BG:SetAllPoints()
	BG:SetColorTexture(0, 0, 0)

	local Texture = Anchor:CreateTexture(nil, "ARTWORK")
	Texture:SetPoint("TOPLEFT", Anchor, 1, -1)
	Texture:SetPoint("BOTTOMRIGHT", Anchor, -1, 1)
	Texture:SetTexture(Assets:GetTexture("Blank"))
	Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	RegisterWidget(self, Anchor, "")
end

-- Button
local BUTTON_WIDTH = 130

local ButtonOnMouseUp = function(self)
	self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	self.MiddleText:ClearAllPoints()
	self.MiddleText:SetPoint("CENTER", self, 0, 0)

	if self.ReloadFlag then
		HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, self.Hook, CANCEL)
	elseif self.Hook then
		self.Hook()
	end
end

local ButtonOnMouseDown = function(self)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

	self.MiddleText:ClearAllPoints()
	self.MiddleText:SetPoint("CENTER", self, 1, -1)

	self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
end

local ButtonWidgetOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local ButtonWidgetOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local ButtonRequiresReload = function(self, flag)
	self.ReloadFlag = flag
end

local ButtonEnable = function(self)
	self.Button:EnableMouse(true)

	self.Button.MiddleText:SetTextColor(1, 1, 1)
end

local ButtonDisable = function(self)
	self.Button:EnableMouse(false)

	self.Button.MiddleText:SetTextColor(HydraUI:HexToRGB("A5A5A5"))
end

GUI.Widgets.CreateButton = function(self, id, value, label, tooltip, hook)
	local Anchor = Core.CreateWidgetAnchor(self, id, label, tooltip)
	Anchor.Enable = ButtonEnable
	Anchor.Disable = ButtonDisable
	Anchor.RequiresReload = ButtonRequiresReload

	local Button = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Button:SetSize(BUTTON_WIDTH, WIDGET_HEIGHT)
	Button:SetPoint("RIGHT", Anchor, 0, 0)
	Button:SetBackdrop(HydraUI.BackdropAndBorder)
	Button:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))
	Button:SetBackdropBorderColor(0, 0, 0)
	Button:SetScript("OnMouseUp", ButtonOnMouseUp)
	Button:SetScript("OnMouseDown", ButtonOnMouseDown)
	Button:SetScript("OnEnter", ButtonWidgetOnEnter)
	Button:SetScript("OnLeave", ButtonWidgetOnLeave)
	Button.Hook = hook

	local Texture = Button:CreateTexture(nil, "BORDER")
	Texture:SetPoint("TOPLEFT", Button, 1, -1)
	Texture:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	local Highlight = Button:CreateTexture(nil, "ARTWORK")
	Highlight:SetPoint("TOPLEFT", Button, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Highlight:SetTexture(Assets:GetTexture("Blank"))
	Highlight:SetVertexColor(1, 1, 1, 0.4)
	Highlight:SetAlpha(0)

	local MiddleText = Button:CreateFontString(nil, "OVERLAY")
	MiddleText:SetPoint("CENTER", Button, 0, 0)
	MiddleText:SetSize(BUTTON_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(MiddleText, Settings["ui-widget-font"], Settings["ui-font-size"])
	MiddleText:SetJustifyH("CENTER")
	MiddleText:SetText(value)

	local Text = Button:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Text:SetSize(GROUP_WIDTH - BUTTON_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	Button.Texture = Texture
	Button.Highlight = Highlight
	Button.MiddleText = MiddleText
	Button.Text = Text

	Anchor.Button = Button

	RegisterWidget(self, Anchor, id)

	return Anchor
end

-- StatusBar
local STATUSBAR_WIDTH = 100

GUI.Widgets.CreateStatusBar = function(self, id, value, minvalue, maxvalue, label, tooltip, hook)
	local Anchor = Core.CreateWidgetAnchor(self, id, label, tooltip)

	local Backdrop = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Backdrop:SetSize(STATUSBAR_WIDTH, WIDGET_HEIGHT)
	Backdrop:SetPoint("RIGHT", Anchor, 0, 0)
	Backdrop:SetBackdrop(HydraUI.BackdropAndBorder)
	Backdrop:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Backdrop:SetBackdropBorderColor(0, 0, 0)
	Backdrop.Value = value

	local BG = Backdrop:CreateTexture(nil, "ARTWORK")
	BG:SetPoint("TOPLEFT", Backdrop, 1, -1)
	BG:SetPoint("BOTTOMRIGHT", Backdrop, -1, 1)
	BG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	BG:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bg-color"]))

	local Bar = CreateFrame("StatusBar", nil, Backdrop, "BackdropTemplate")
	Bar:SetSize(STATUSBAR_WIDTH, WIDGET_HEIGHT)
	Bar:SetPoint("TOPLEFT", Backdrop, 1, -1)
	Bar:SetPoint("BOTTOMRIGHT", Backdrop, -1, 1)
	Bar:SetBackdrop(HydraUI.BackdropAndBorder)
	Bar:SetBackdropColor(0, 0, 0, 0)
	Bar:SetBackdropBorderColor(0, 0, 0, 0)
	Bar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Bar:SetStatusBarColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	Bar:SetMinMaxValues(minvalue, maxvalue)
	Bar:SetValue(value)
	Bar.Hook = hook
	Bar.Tooltip = tooltip

	local Anim = LibMotion:CreateAnimation(Bar, "Progress")
	Anim:SetEasing("in")
	Anim:SetDuration(0.3)

	local Spark = Bar:CreateTexture(nil, "ARTWORK")
	Spark:SetSize(1, WIDGET_HEIGHT - 2)
	Spark:SetPoint("LEFT", Bar:GetStatusBarTexture(), "RIGHT", 0, 0)
	Spark:SetTexture(Assets:GetTexture("Blank"))
	Spark:SetVertexColor(0, 0, 0)

	local MiddleText = Bar:CreateFontString(nil, "ARTWORK")
	MiddleText:SetPoint("CENTER", Bar, "CENTER", 0, 0)
	MiddleText:SetSize(STATUSBAR_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(MiddleText, Settings["ui-widget-font"], Settings["ui-font-size"])
	MiddleText:SetJustifyH("CENTER")
	MiddleText:SetText(value)

	local Text = Bar:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Text:SetSize(GROUP_WIDTH - STATUSBAR_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	Bar.Anim = Anim
	Bar.Spark = Spark
	Bar.MiddleText = MiddleText
	Bar.Text = Text

	RegisterWidget(self, Anchor, id)

	return Bar
end
