local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local Core = GUI.WidgetCore
local SPACING, HEADER_HEIGHT, HEADER_SPACING = Core.SPACING, Core.HEADER_HEIGHT, Core.HEADER_SPACING
local GROUP_HEIGHT, GROUP_WIDTH, WIDGET_HEIGHT = Core.GROUP_HEIGHT, Core.GROUP_WIDTH, Core.WIDGET_HEIGHT
local LABEL_SPACING = Core.LABEL_SPACING
local SELECTED_HIGHLIGHT_ALPHA, MOUSEOVER_HIGHLIGHT_ALPHA = Core.SELECTED_HIGHLIGHT_ALPHA, Core.MOUSEOVER_HIGHLIGHT_ALPHA
local RegisterWidget, SetVariable = Core.RegisterWidget, Core.SetVariable
local Round, TrimHex = Core.Round, Core.TrimHex
local AnchorOnEnter, AnchorOnLeave, FadeOnFinished = Core.AnchorOnEnter, Core.AnchorOnLeave, Core.FadeOnFinished
local type, next, tonumber = type, next, tonumber
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local match, upper, lower, sub, gsub, find = string.match, string.upper, string.lower, string.sub, string.gsub, string.find
local floor, max, min = math.floor, math.max, math.min
local InCombatLockdown, IsModifierKeyDown = InCombatLockdown, IsModifierKeyDown

local Dialog = {}
GUI.Dialog = Dialog

local DialogCloseOnEnter = function(self)
	self.Cross:SetVertexColor(self.HoverR, self.HoverG, self.HoverB)
end

local DialogCloseOnLeave = function(self)
	self.Cross:SetVertexColor(self.NormalR, self.NormalG, self.NormalB)
end

local DialogCloseOnMouseDown = function(self)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-header-texture-color"])

	self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
end

local DialogCloseOnMouseUp = function(self)
	if self.Texture then
		self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))
	end

	if self.CloseBehavior then
		self.CloseBehavior(self.Window)
	elseif self.Animated then
		self.Window.FadeOut:Play()
	else
		self.Window:Hide()
	end
end

Dialog.CreateDialogShell = function(parent, options)
	local Window = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Window:SetSize(options.Width, options.Height)
	Window:SetPoint(options.Point, options.RelativeTo, options.RelativePoint or options.Point, options.X, options.Y)
	Window:SetBackdrop(HydraUI.BackdropAndBorder)
	Window:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	Window:SetBackdropBorderColor(0, 0, 0)
	Window:SetFrameStrata(options.Strata)
	Window:SetMovable(true)
	Window:EnableMouse(true)
	Window:RegisterForDrag("LeftButton")
	Window:SetScript("OnDragStart", Window.StartMoving)
	Window:SetScript("OnDragStop", Window.StopMovingOrSizing)

	if options.ClampedToScreen then
		Window:SetClampedToScreen(true)
	end

	if options.Alpha then
		Window:SetAlpha(options.Alpha)
	end

	Window:Hide()

	return Window
end

Dialog.CreateDialogHeader = function(Window, options)
	local Header = CreateFrame("Frame", nil, Window, "BackdropTemplate")
	Header:SetHeight(HEADER_HEIGHT)
	Header:SetPoint("TOPLEFT", Window, SPACING, -SPACING)
	Header:SetPoint("TOPRIGHT", Window, -options.RightInset, -SPACING)
	Header:SetBackdrop(HydraUI.BackdropAndBorder)
	Header:SetBackdropColor(0, 0, 0)
	Header:SetBackdropBorderColor(0, 0, 0)

	Window.Header = Header
	Window.HeaderTexture = Header:CreateTexture(nil, "OVERLAY")
	Window.HeaderTexture:SetPoint("TOPLEFT", Header, 1, -1)
	Window.HeaderTexture:SetPoint("BOTTOMRIGHT", Header, -1, 1)
	Window.HeaderTexture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	Window.HeaderTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	Header.Text = Header:CreateFontString(nil, "OVERLAY")
	Header.Text:SetPoint("LEFT", Header, HEADER_SPACING, -1)
	HydraUI:SetFontInfo(Header.Text, Settings["ui-header-font"], Settings["ui-header-font-size"])
	Header.Text:SetJustifyH("LEFT")
	Header.Text:SetText("|cFF" .. Settings["ui-header-font-color"] .. options.Text .. "|r")

	return Header
end

Dialog.CreateDialogCloseControl = function(Window, options)
	local Parent = options.Parent or Window.Header
	local CloseButton

	if options.Template then
		CloseButton = CreateFrame("Frame", nil, Parent, options.Template)
	else
		CloseButton = CreateFrame("Frame", nil, Parent)
	end
	CloseButton:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
	CloseButton:SetPoint(options.Point, options.RelativeTo or Parent, options.RelativePoint or options.Point, options.X or 0, options.Y or 0)
	CloseButton:SetScript("OnEnter", DialogCloseOnEnter)
	CloseButton:SetScript("OnLeave", DialogCloseOnLeave)
	CloseButton:SetScript("OnMouseUp", DialogCloseOnMouseUp)
	CloseButton.Window = Window
	CloseButton.Animated = options.Animated
	CloseButton.CloseBehavior = options.CloseBehavior
	CloseButton.HoverR, CloseButton.HoverG, CloseButton.HoverB = options.HoverR, options.HoverG, options.HoverB
	CloseButton.NormalR, CloseButton.NormalG, CloseButton.NormalB = options.NormalR, options.NormalG, options.NormalB

	if options.Template then
		CloseButton:SetBackdrop(HydraUI.BackdropAndBorder)
		CloseButton:SetBackdropColor(0, 0, 0, 0)
		CloseButton:SetBackdropBorderColor(0, 0, 0)
		CloseButton:SetScript("OnMouseDown", DialogCloseOnMouseDown)

		CloseButton.Texture = CloseButton:CreateTexture(nil, "ARTWORK")
		CloseButton.Texture:SetPoint("TOPLEFT", CloseButton, 1, -1)
		CloseButton.Texture:SetPoint("BOTTOMRIGHT", CloseButton, -1, 1)
		CloseButton.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
		CloseButton.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))
	end

	CloseButton.Cross = CloseButton:CreateTexture(nil, "OVERLAY")
	CloseButton.Cross:SetPoint("CENTER", CloseButton, 0, 0)
	CloseButton.Cross:SetSize(16, 16)
	CloseButton.Cross:SetTexture(Assets:GetTexture("Close"))
	CloseButton.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE"))

	if options.Field then
		Window[options.Field] = CloseButton
	else
		Window.Header.CloseButton = CloseButton
	end

	return CloseButton
end

Dialog.CreateDialogInnerBackdrop = function(Window, options)
	local Parent = options.Parent or Window
	local Backdrop = CreateFrame("Frame", nil, Parent, "BackdropTemplate")
	Backdrop:SetPoint(options.TopPoint, options.TopRelativeTo, options.TopRelativePoint, options.TopX, options.TopY)
	Backdrop:SetPoint(options.BottomPoint, options.BottomRelativeTo, options.BottomRelativePoint, options.BottomX, options.BottomY)

	if options.Height then
		Backdrop:SetHeight(options.Height)
	end

	Backdrop:SetBackdrop(HydraUI.BackdropAndBorder)
	if options.Color then
		Backdrop:SetBackdropColor(HydraUI:HexToRGB(Settings[options.Color]))
	else
		Backdrop:SetBackdropColor(options.R, options.G, options.B, options.A)
	end
	Backdrop:SetBackdropBorderColor(0, 0, 0)
	Window[options.Field] = Backdrop

	if options.TextureLayer then
		Window.InputTexture = Backdrop:CreateTexture(nil, options.TextureLayer)
		Window.InputTexture:SetPoint("TOPLEFT", Backdrop, 1, -1)
		Window.InputTexture:SetPoint("BOTTOMRIGHT", Backdrop, -1, 1)
		Window.InputTexture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		Window.InputTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))
	end

	return Backdrop
end

Dialog.CreateDialogEditBox = function(Window, options)
	local Input = CreateFrame("EditBox", nil, options.Parent)
	HydraUI:SetFontInfo(Input, Settings["ui-widget-font"], Settings["ui-font-size"])
	Input:SetPoint("TOPLEFT", options.Parent, 3, -3)
	Input:SetPoint("BOTTOMRIGHT", options.Parent, -3, 3)

	if options.Strata then
		Input:SetFrameStrata(options.Strata)
	end

	if options.Level then
		Input:SetFrameLevel(options.Level)
	end

	Input:SetJustifyH("LEFT")
	Input:SetAutoFocus(false)
	Input:EnableKeyboard(true)
	Input:EnableMouse(true)

	if options.MultiLine ~= nil then
		Input:SetMultiLine(options.MultiLine)
	end

	if options.MaxLetters then
		Input:SetMaxLetters(options.MaxLetters)
	end

	if options.CursorPosition then
		Input:SetCursorPosition(options.CursorPosition)
	end

	for Script, Handler in next, options.Scripts do
		Input:SetScript(Script, Handler)
	end

	Window.Input = Input

	return Input
end

