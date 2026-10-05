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

local Dialog = GUI.Dialog
local CreateDialogShell, CreateDialogHeader = Dialog.CreateDialogShell, Dialog.CreateDialogHeader
local CreateDialogCloseControl, CreateDialogInnerBackdrop, CreateDialogEditBox = Dialog.CreateDialogCloseControl, Dialog.CreateDialogInnerBackdrop, Dialog.CreateDialogEditBox

-- Input
function GUI:SetInputObject(input)
	local Text = input.ButtonText:GetText() or ""

	Core.Controllers.Input.Active = input
	self.InputWindow.ActiveInput = input
	self.InputWindow.Input:SetText(Text)
	self.InputWindow:Show()
	self.InputWindow.FadeIn:Play()
end

function GUI:ToggleInputWindow(input)
	if not self.InputWindow then
		self:CreateInputWindow()
	end

	if self.InputWindow:IsShown() then
		if input ~= self.InputWindow.ActiveInput then
			self:SetInputObject(input)
		else
			self.InputWindow.FadeOut:Play()
		end
	else
		self:SetInputObject(input)
	end
end

local InputWindowOnEnterPressed = function(self)
	local Text = self:GetText() or ""

	self:SetAutoFocus(false)
	self:ClearFocus()

	if GUI.InputWindow.ActiveInput then
		local Input = GUI.InputWindow.ActiveInput

		if Input.IsSavingDisabled then
			Input.ButtonText:SetText("")
		else
			SetVariable(Input.ID, Text)
			Input.ButtonText:SetText(Text)
		end

		if Input.ReloadFlag then
			HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, Input.Hook, CANCEL, nil, Text, Input.ID)
		elseif Input.Hook then
			Input.Hook(Text, Input.ID)
		end

		GUI:ToggleInputWindow(Input)
	end
end

local InputWindowOnMouseDown = function(self)
	self:HighlightText()
	self:SetAutoFocus(true)
end

function GUI:CreateInputWindow()
	if self.InputWindow then
		return self.InputWindow
	end

	local Window = CreateDialogShell(self, {
		Width = 300, Height = 200,
		Point = "CENTER", RelativeTo = HydraUI.UIParent, X = 0, Y = 0,
		Strata = "DIALOG", ClampedToScreen = true, Alpha = 0,
	})

	CreateDialogHeader(Window, {
		RightInset = (SPACING + 2) + HEADER_HEIGHT,
		Text = Language["Input"],
	})

	local HoverR, HoverG, HoverB = HydraUI:HexToRGB("C0392B")
	local NormalR, NormalG, NormalB = HydraUI:HexToRGB("EEEEEE")
	CreateDialogCloseControl(Window, {
		Parent = Window, Field = "CloseButton", Template = "BackdropTemplate",
		Point = "TOPRIGHT", RelativeTo = Window, X = -SPACING, Y = -SPACING,
		HoverR = HoverR, HoverG = HoverG, HoverB = HoverB,
		NormalR = NormalR, NormalG = NormalG, NormalB = NormalB,
		Animated = true,
	})

	CreateDialogInnerBackdrop(Window, {
		Field = "Inner",
		TopPoint = "TOPLEFT", TopRelativeTo = Window.Header, TopRelativePoint = "BOTTOMLEFT", TopX = 0, TopY = -2,
		BottomPoint = "BOTTOMRIGHT", BottomRelativeTo = Window, BottomRelativePoint = "BOTTOMRIGHT", BottomX = -3, BottomY = 3,
		Color = "ui-window-main-color",
	})

	CreateDialogEditBox(Window, {
		Parent = Window.Inner, Strata = "DIALOG", MultiLine = true, MaxLetters = 9999, CursorPosition = 0,
		Scripts = {
			OnEnterPressed = InputWindowOnEnterPressed,
			OnEscapePressed = InputWindowOnEnterPressed,
			OnMouseDown = InputWindowOnMouseDown,
		},
	})

	Window.FadeIn = LibMotion:CreateAnimation(Window, "Fade")
	Window.FadeIn:SetEasing("in")
	Window.FadeIn:SetDuration(0.3)
	Window.FadeIn:SetChange(1)

	Window.FadeOut = LibMotion:CreateAnimation(Window, "Fade")
	Window.FadeOut:SetEasing("out")
	Window.FadeOut:SetDuration(0.3)
	Window.FadeOut:SetChange(0)
	Window.FadeOut:SetScript("OnFinished", FadeOnFinished)

	self.InputWindow = Window

	return Window
end

local INPUT_WIDTH = 130

local InputOnMouseDown = function(self)
	GUI:ToggleInputWindow(self)
end

local InputOnEnter = function(self)
	self.Parent.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local InputOnLeave = function(self)
	self.Parent.Highlight:SetAlpha(0)
end

local InputDisableSaving = function(self)
	self.IsSavingDisabled = true

	return self
end

local CreateInputControl = function(parent, width, id, value, tooltip, hook, isCombined)
	local Input = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	Input:SetSize(width, WIDGET_HEIGHT)
	Input:SetPoint(isCombined and "LEFT" or "RIGHT", parent, 0, 0)
	Input:SetBackdrop(HydraUI.BackdropAndBorder)
	Input:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-widget-bg-color"]))
	Input:SetBackdropBorderColor(0, 0, 0)
	Input.Tooltip = tooltip

	Input.Texture = Input:CreateTexture(nil, "ARTWORK")
	Input.Texture:SetPoint("TOPLEFT", Input, 1, -1)
	Input.Texture:SetPoint("BOTTOMRIGHT", Input, -1, 1)
	Input.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Input.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	Input.Flash = Input:CreateTexture(nil, "OVERLAY")
	Input.Flash:SetPoint("TOPLEFT", Input, 1, -1)
	Input.Flash:SetPoint("BOTTOMRIGHT", Input, -1, 1)
	Input.Flash:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Input.Flash:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	Input.Flash:SetAlpha(0)

	Input.Highlight = Input:CreateTexture(nil, "OVERLAY")
	Input.Highlight:SetPoint("TOPLEFT", Input, 1, -1)
	Input.Highlight:SetPoint("BOTTOMRIGHT", Input, -1, 1)
	Input.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Input.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Input.Highlight:SetAlpha(0)

	local Control

	if isCombined then
		Control = CreateFrame("EditBox", nil, Input)
		Control:SetPoint("TOPLEFT", Input, SPACING, -2)
		Control:SetPoint("BOTTOMRIGHT", Input, -SPACING, 2)
		Control:SetAutoFocus(false)
		Control:EnableKeyboard(true)
		Control:EnableMouse(true)
		Control:SetMultiLine(true)
		Control:SetMaxLetters(9999)

		Control:SetScript("OnMouseDown", InputOnMouseDown)
		Control:SetScript("OnEscapePressed", InputOnEscapePressed)
		Control:SetScript("OnEnterPressed", InputOnEnterPressed)
		Control:SetScript("OnEditFocusLost", InputOnEditFocusLost)
		Control:SetScript("OnChar", InputOnChar)
		Control:SetScript("OnEnter", InputOnEnter)
		Control:SetScript("OnLeave", InputOnLeave)

		Input.Box = Control
	else
		Control = Input
		Control:SetScript("OnEnter", InputOnEnter)
		Control:SetScript("OnLeave", InputOnLeave)
		Control:SetScript("OnMouseUp", InputOnMouseDown)

		Input.ButtonText = Input:CreateFontString(nil, "OVERLAY")
		Input.ButtonText:SetSize(width, WIDGET_HEIGHT)
		Input.ButtonText:SetPoint("TOPLEFT", Input, SPACING, -SPACING)
		Input.ButtonText:SetPoint("BOTTOMRIGHT", Input, -SPACING, SPACING)
		Input.ButtonText:SetJustifyH("LEFT")
	end

	local TextControl = isCombined and Control or Input.ButtonText
	HydraUI:SetFontInfo(TextControl, Settings["ui-widget-font"], Settings["ui-font-size"])
	TextControl:SetText(value)

	if isCombined then
		Control:SetJustifyH("LEFT")
	end

	Control.ID = id
	Control.Hook = hook
	Control.Parent = Input
	Control.Tooltip = tooltip
	Control.RequiresReload = Core.SetRequiresReload
	Control.DisableSaving = InputDisableSaving

	Input.FadeIn = LibMotion:CreateAnimation(Input.Flash, "Fade")
	Input.FadeIn:SetEasing("in")
	Input.FadeIn:SetDuration(0.3)
	Input.FadeIn:SetChange(SELECTED_HIGHLIGHT_ALPHA)

	Input.FadeOut = LibMotion:CreateAnimation(Input.Flash, "Fade")
	Input.FadeOut:SetOrder(2)
	Input.FadeOut:SetEasing("out")
	Input.FadeOut:SetDuration(0.3)
	Input.FadeOut:SetChange(0)

	return Input
end

GUI.Widgets.CreateInput = function(self, id, value, label, tooltip, hook)
	value = Core.GetInitialValue(id, value)

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	local Input = CreateInputControl(Anchor, INPUT_WIDTH, id, value, tooltip, hook, false)

	Input.Text = Input:CreateFontString(nil, "OVERLAY")
	Input.Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Input.Text:SetSize(GROUP_WIDTH - INPUT_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Input.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Input.Text:SetJustifyH("LEFT")
	Input.Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	RegisterWidget(self, Anchor, id)

	Anchor.Input = Input

	return Input
end

local InputButtonOnMouseUp = function(self)
	self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	InputOnEnterPressed(self.Input)
end

local INPUT_BUTTON_WIDTH = (GROUP_WIDTH / 2) - (SPACING / 2)

GUI.Widgets.CreateInputWithButton = function(self, id, value, button, label, tooltip, hook)
	value = Core.GetInitialValue(id, value)

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.Text = label
	Anchor.Tooltip = tooltip

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	local Text = Anchor:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Text:SetSize(GROUP_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetShadowColor(0, 0, 0)
	Text:SetShadowOffset(1, -1)
	Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	local Anchor2 = CreateFrame("Frame", nil, self)
	Anchor2:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor2.ID = id
	Anchor2.Text = label

	local Button = CreateFrame("Frame", nil, Anchor2, "BackdropTemplate")
	Button:SetSize(INPUT_BUTTON_WIDTH, WIDGET_HEIGHT)
	Button:SetPoint("RIGHT", Anchor2, 0, 0)
	Button:SetBackdrop(HydraUI.BackdropAndBorder)
	Button:SetBackdropColor(0.17, 0.17, 0.17)
	Button:SetBackdropBorderColor(0, 0, 0)
	Button:SetScript("OnMouseUp", InputButtonOnMouseUp)
	Button:SetScript("OnMouseDown", ButtonOnMouseDown)
	Button:SetScript("OnEnter", ButtonWidgetOnEnter)
	Button:SetScript("OnLeave", ButtonWidgetOnLeave)
	Button.Tooltip = tooltip

	Button.Texture = Button:CreateTexture(nil, "BORDER")
	Button.Texture:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Texture:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Button.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	Button.Highlight = Button:CreateTexture(nil, "ARTWORK")
	Button.Highlight:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Highlight:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Button.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Button.Highlight:SetAlpha(0)

	Button.MiddleText = Button:CreateFontString(nil, "OVERLAY")
	Button.MiddleText:SetPoint("CENTER", Button, "CENTER", 0, 0)
	HydraUI:SetFontInfo(Button.MiddleText, Settings["ui-widget-font"], Settings["ui-font-size"])
	Button.MiddleText:SetJustifyH("CENTER")
	Button.MiddleText:SetText(button)

	local Input = CreateInputControl(Anchor2, INPUT_BUTTON_WIDTH, id, value, tooltip, hook, true)

	Input.Button = Button
	Button.Input = Input.Box

	RegisterWidget(self, Anchor, "")
	RegisterWidget(self, Anchor2, "")

	Anchor.Input = Input

	return Input
end

GUI.ToggleExportWindow = function(self)
	if not self.ExportWindow then
		self:CreateExportWindow()
	end

	if self.ExportWindow:IsShown() then
		self.ExportWindow:Hide()
	else
		self.ExportWindow:Show()
	end
end

function GUI:SetExportWindowText(text)
	if type(text) ~= "string" then
		return
	end

	if not match(text, "%S") then
		return
	end

	if self.ExportWindow then
		self.ExportWindow.Input:SetText(text)
		self.ExportWindow.Input:HighlightText()
		self.ExportWindow.Input:SetAutoFocus(true)
	end
end

local ExportWindowOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local ExportWindowOnMouseDown = function(self)
	self:HighlightText()
	self:SetAutoFocus(true)
end

function GUI:CreateExportWindow()
	if self.ExportWindow then
		return self.ExportWindow
	end

	local Window = CreateDialogShell(self, {
		Width = 300, Height = 74,
		Point = "CENTER", RelativeTo = HydraUI.UIParent, X = 0, Y = 230,
		Strata = "DIALOG",
	})

	CreateDialogHeader(Window, {
		RightInset = SPACING,
		Text = Language["Export string"],
	})

	CreateDialogCloseControl(Window, {
		Point = "RIGHT", RelativeTo = Window.Header,
		HoverR = 1, HoverG = 0, HoverB = 0,
		NormalR = 1, NormalG = 1, NormalB = 1,
		Animated = false,
	})

	CreateDialogInnerBackdrop(Window, {
		Field = "BG",
		TopPoint = "TOPLEFT", TopRelativeTo = Window.Header, TopRelativePoint = "BOTTOMLEFT", TopX = 0, TopY = -2,
		BottomPoint = "BOTTOMRIGHT", BottomRelativeTo = Window, BottomRelativePoint = "BOTTOMRIGHT", BottomX = -3, BottomY = 3,
		Color = "ui-window-main-color",
	})

	CreateDialogInnerBackdrop(Window, {
		Parent = Window.BG, Field = "InputBG", Height = 20, TextureLayer = "BACKGROUND",
		TopPoint = "BOTTOMLEFT", TopRelativeTo = Window.BG, TopRelativePoint = "BOTTOMLEFT", TopX = 3, TopY = 3,
		BottomPoint = "BOTTOMRIGHT", BottomRelativeTo = Window.BG, BottomRelativePoint = "BOTTOMRIGHT", BottomX = -3, BottomY = 3,
		R = 0, G = 0, B = 0, A = 0,
	})

	CreateDialogEditBox(Window, {
		Parent = Window.InputBG, Level = 10, MaxLetters = 9999, CursorPosition = 0,
		Scripts = {
			OnEnterPressed = ExportWindowOnEnterPressed,
			OnEscapePressed = ExportWindowOnEnterPressed,
			OnMouseDown = ExportWindowOnMouseDown,
		},
	})

	Window.Label = Window.BG:CreateFontString(nil, "OVERLAY")
	Window.Label:SetPoint("BOTTOMLEFT", Window.InputBG, "TOPLEFT", 3, 4)
	HydraUI:SetFontInfo(Window.Label, Settings["ui-font"], Settings["ui-font-size"])
	Window.Label:SetJustifyH("LEFT")
	Window.Label:SetText(Language["Press ctrl + c to copy"])

	self.ExportWindow = Window

	return Window
end

function GUI:ToggleImportWindow()
	if not self.ImportWindow then
		self:CreateImportWindow()
	end

	if self.ImportWindow:IsShown() then
		self.ImportWindow:Hide()
	else
		self.ImportWindow.Input:SetAutoFocus(true)
		self.ImportWindow:Show()
	end
end

local ImportWindowOnEnterPressed = function(self)
	local Text = self:GetText()

	if not match(Text, "%S+") then
		self:SetAutoFocus(false)
		self:ClearFocus()

		return
	end

	local Profile = HydraUI:DecodeProfile(Text)

	if Profile then
		HydraUI:AddProfile(Profile)
	end

	self:SetText("")
	self:SetAutoFocus(false)
	self:ClearFocus()

	GUI:ToggleImportWindow()
end

local ImportWindowOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local ImportWindowOnMouseDown = function(self)
	self:SetAutoFocus(true)
end

local ImportWindowOnTextChanged = function(self)
	local Text = self:GetText()

	self:SetText("")
	self:SetAutoFocus(false)
	self:ClearFocus()

	if not match(Text, "%S+") then
		return
	end

	local Profile = HydraUI:DecodeProfile(Text)

	if Profile then
		--HydraUI:AddProfile(Profile)
		print(Profile["profile-name"])


	--[[["profile-name"] = true,
	["profile-created"] = true,
	["profile-created-by"] = true,
	["profile-last-modified"] = true,]]

	end
end

function GUI:CreateImportWindow()
	if self.ImportWindow then
		return self.ImportWindow
	end

	local Window = CreateDialogShell(self, {
		Width = 300, Height = 74,
		Point = "CENTER", RelativeTo = HydraUI.UIParent, X = 0, Y = 230,
		Strata = "DIALOG",
	})

	CreateDialogHeader(Window, {
		RightInset = SPACING,
		Text = Language["Import string"],
	})

	CreateDialogCloseControl(Window, {
		Point = "RIGHT", RelativeTo = Window.Header,
		HoverR = 1, HoverG = 0, HoverB = 0,
		NormalR = 1, NormalG = 1, NormalB = 1,
		Animated = false,
	})

	CreateDialogInnerBackdrop(Window, {
		Field = "BG",
		TopPoint = "TOPLEFT", TopRelativeTo = Window.Header, TopRelativePoint = "BOTTOMLEFT", TopX = 0, TopY = -2,
		BottomPoint = "BOTTOMRIGHT", BottomRelativeTo = Window, BottomRelativePoint = "BOTTOMRIGHT", BottomX = -3, BottomY = 3,
		Color = "ui-window-main-color",
	})

	CreateDialogInnerBackdrop(Window, {
		Parent = Window.BG, Field = "InputBG", Height = 20, TextureLayer = "BORDER",
		TopPoint = "BOTTOMLEFT", TopRelativeTo = Window.BG, TopRelativePoint = "BOTTOMLEFT", TopX = 3, TopY = 3,
		BottomPoint = "BOTTOMRIGHT", BottomRelativeTo = Window.BG, BottomRelativePoint = "BOTTOMRIGHT", BottomX = -3, BottomY = 3,
		R = 0, G = 0, B = 0, A = 0,
	})

	Window.Label = Window.BG:CreateFontString(nil, "OVERLAY")
	Window.Label:SetPoint("BOTTOMLEFT", Window.InputBG, "TOPLEFT", 3, 4)
	HydraUI:SetFontInfo(Window.Label, Settings["ui-font"], Settings["ui-font-size"])
	Window.Label:SetJustifyH("LEFT")
	Window.Label:SetText(Language["Paste your profile string below"])

	CreateDialogEditBox(Window, {
		Parent = Window.InputBG, Level = 10, MaxLetters = 9999,
		Scripts = {
			OnEnterPressed = ImportWindowOnEnterPressed,
			OnEscapePressed = ImportWindowOnEscapePressed,
			OnMouseDown = ImportWindowOnMouseDown,
		},
	})

	self.ImportWindow = Window

	return Window
end
