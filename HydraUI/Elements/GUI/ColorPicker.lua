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

local Controller = Core.Controllers.Color

-- Color
local COLOR_WIDTH = 80
local SWATCH_SIZE = 20
local MAX_SWATCHES_X = 20
local MAX_SWATCHES_Y = 10

local ColorSwatchOnMouseUp = function(self)
	GUI.ColorPicker.Transition:SetChange(HydraUI:HexToRGB(self.Value))
	GUI.ColorPicker.Transition:Play()
	GUI.ColorPicker.NewHexText:SetText("#"..self.Value)
	GUI.ColorPicker.Selected = self.Value
end

local ColorSwatchOnEnter = function(self)
	self.Highlight:SetAlpha(1)
end

local ColorSwatchOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local ColorPickerAccept = function(self)
	self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-button-texture-color"]))

	local Active = self:GetParent().Active

	if GUI.ColorPicker.Selected then
		Active.Transition:SetChange(HydraUI:HexToRGB(GUI.ColorPicker.Selected))
		Active.Transition:Play()

		Active.MiddleText:SetText("#"..upper(GUI.ColorPicker.Selected))
		Active.Value = GUI.ColorPicker.Selected

		SetVariable(Active.ID, Active.Value)

		if Active.ReloadFlag then
			HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, Active.Hook, CANCEL, nil, Active.Value, Active.ID)
		elseif Active.Hook then
			Active.Hook(Active.Value, Active.ID)
		end
	end

	GUI.ColorPicker.FadeOut:Play()
end

local ColorPickerCancel = function(self)
	self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-button-texture-color"]))

	GUI.ColorPicker.FadeOut:Play()
end

local ColorPickerOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local ColorPickerOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local SwatchEditBoxOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local SwatchEditBoxOnEnterPressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local SwatchEditBoxOnEditFocusLost = function(self)
	local Value = self:GetText()

	Value = gsub(Value, "#", "")

	if Value and match(Value, "%x%x%x%x%x%x") then
		self:SetText("#"..Value)

		GUI.ColorPicker.Transition:SetChange(HydraUI:HexToRGB(Value))
		GUI.ColorPicker.Selected = Value
	elseif Value and Value == "CLASS" then
		local ClassColor = RAID_CLASS_COLORS[HydraUI.UserClass]
		local ClassHex = HydraUI:RGBToHex(ClassColor.r, ClassColor.g, ClassColor.b)

		self:SetText("#"..upper(ClassHex))

		GUI.ColorPicker.Transition:SetChange(HydraUI:HexToRGB(ClassHex))
		GUI.ColorPicker.Selected = ClassHex
	else
		HydraUI:print(format(Language['Invalid hex code "%s".'], Value))

		self:SetText("#" .. GUI.ColorPicker.Active.Value)

		GUI.ColorPicker.Transition:SetChange(HydraUI:HexToRGB(GUI.ColorPicker.Active.Value))
		GUI.ColorPicker.Selected = GUI.ColorPicker.Active.Value
	end

	GUI.ColorPicker.Transition:Play()
end

local SwatchEditBoxOnChar = function(self)
	local Value = self:GetText()

	Value = gsub(Value, "#", "")
	Value = upper(Value)

	self:SetText(Value)

	if match(Value, "%x%x%x%x%x%x") or (Value == "CLASS") then
		self:SetAutoFocus(false)
		self:ClearFocus()
	end
end

local SwatchEditBoxOnEditFocusGained = function(self)
	local Text = self:GetText()

	Text = gsub(Text, "#", "")

	self:SetText(Text)
	self:HighlightText()
end

local SwatchEditBoxOnMouseDown = function(self)
	self:SetAutoFocus(true)
end

local SwatchButtonOnMouseDown = function(self)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-button-texture-color"])

	self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
end

local UpdateColorPalette = function(value)
	GUI.ColorPicker:SetColorPalette(value)
end

local UpdateColorPickerTexture = function(value)
	local Texture = Assets:GetTexture(value)

	for i = 1, MAX_SWATCHES_Y do
		for j = 1, MAX_SWATCHES_X do
			GUI.ColorPicker.SwatchParent[i][j].Texture:SetTexture(Texture)
		end
	end
end

local CreateColorPicker = function()
	if GUI.ColorPicker then
		return
	end

	local ColorPicker = CreateFrame("Frame", "HydraUIColorPicker", GUI, "BackdropTemplate")
	ColorPicker:SetSize(388, 290)
	ColorPicker:SetPoint("CENTER", GUI, 0, 50)
	ColorPicker:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	ColorPicker:SetBackdropBorderColor(0, 0, 0)
	ColorPicker:SetFrameStrata("HIGH")
	ColorPicker:SetFrameLevel(10)
	ColorPicker:Hide()
	ColorPicker:SetAlpha(0)
	ColorPicker:SetMovable(true)
	ColorPicker:EnableMouse(true)
	ColorPicker:RegisterForDrag("LeftButton")
	ColorPicker:SetScript("OnDragStart", ColorPicker.StartMoving)
	ColorPicker:SetScript("OnDragStop", ColorPicker.StopMovingOrSizing)

	-- Header
	ColorPicker.Header = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.Header:SetHeight(HEADER_HEIGHT)
	ColorPicker.Header:SetPoint("TOPLEFT", ColorPicker, 2, -2)
	ColorPicker.Header:SetPoint("TOPRIGHT", ColorPicker, -(HEADER_HEIGHT + 2), -2)
	ColorPicker.Header:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.Header:SetBackdropColor(0, 0, 0)
	ColorPicker.Header:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.HeaderTexture = ColorPicker.Header:CreateTexture(nil, "OVERLAY")
	ColorPicker.HeaderTexture:SetPoint("TOPLEFT", ColorPicker.Header, 1, -1)
	ColorPicker.HeaderTexture:SetPoint("BOTTOMRIGHT", ColorPicker.Header, -1, 1)
	ColorPicker.HeaderTexture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	ColorPicker.HeaderTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	ColorPicker.Header.Text = ColorPicker.Header:CreateFontString(nil, "OVERLAY")
	ColorPicker.Header.Text:SetPoint("LEFT", ColorPicker.Header, HEADER_SPACING, -1)
	HydraUI:SetFontInfo(ColorPicker.Header.Text, Settings["ui-header-font"], Settings["ui-header-font-size"])
	ColorPicker.Header.Text:SetJustifyH("LEFT")
	ColorPicker.Header.Text:SetText("|cFF"..Settings["ui-header-font-color"]..Language["Select a color"].."|r")

	-- Close button
	ColorPicker.CloseButton = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.CloseButton:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
	ColorPicker.CloseButton:SetPoint("LEFT", ColorPicker.Header, "RIGHT", 2, 0)
	ColorPicker.CloseButton:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.CloseButton:SetBackdropColor(0, 0, 0, 0)
	ColorPicker.CloseButton:SetBackdropBorderColor(0, 0, 0)
	ColorPicker.CloseButton:SetScript("OnEnter", function(self) self.Cross:SetVertexColor(HydraUI:HexToRGB("C0392B")) end)
	ColorPicker.CloseButton:SetScript("OnLeave", function(self) self.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE")) end)
	ColorPicker.CloseButton:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

		self:GetParent().FadeOut:Play()
	end)

	ColorPicker.CloseButton:SetScript("OnMouseDown", function(self)
		local R, G, B = HydraUI:HexToRGB(Settings["ui-header-texture-color"])

		self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
	end)

	ColorPicker.CloseButton.Texture = ColorPicker.CloseButton:CreateTexture(nil, "ARTWORK")
	ColorPicker.CloseButton.Texture:SetPoint("TOPLEFT", ColorPicker.CloseButton, 1, -1)
	ColorPicker.CloseButton.Texture:SetPoint("BOTTOMRIGHT", ColorPicker.CloseButton, -1, 1)
	ColorPicker.CloseButton.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	ColorPicker.CloseButton.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	ColorPicker.CloseButton.Cross = ColorPicker.CloseButton:CreateTexture(nil, "OVERLAY")
	ColorPicker.CloseButton.Cross:SetPoint("CENTER", ColorPicker.CloseButton, 0, 0)
	ColorPicker.CloseButton.Cross:SetSize(16, 16)
	ColorPicker.CloseButton.Cross:SetTexture(Assets:GetTexture("Close"))
	ColorPicker.CloseButton.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE"))

	-- Selection parent
	ColorPicker.SwatchParent = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.SwatchParent:SetPoint("TOPLEFT", ColorPicker.Header, "BOTTOMLEFT", 0, -2)
	ColorPicker.SwatchParent:SetPoint("TOPRIGHT", ColorPicker.CloseButton, "BOTTOMRIGHT", 0, -2)
	ColorPicker.SwatchParent:SetHeight((SWATCH_SIZE * MAX_SWATCHES_Y) - SPACING)
	ColorPicker.SwatchParent:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.SwatchParent:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	ColorPicker.SwatchParent:SetBackdropBorderColor(0, 0, 0)

	-- Current
	ColorPicker.Current = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.Current:SetSize((390 / 3), 20)
	ColorPicker.Current:SetPoint("TOPLEFT", ColorPicker.SwatchParent, "BOTTOMLEFT", 0, -2)
	ColorPicker.Current:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.Current:SetBackdropColor(0, 0, 0)
	ColorPicker.Current:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.CurrentTexture = ColorPicker.Current:CreateTexture(nil, "OVERLAY")
	ColorPicker.CurrentTexture:SetPoint("TOPLEFT", ColorPicker.Current, 1, -1)
	ColorPicker.CurrentTexture:SetPoint("BOTTOMRIGHT", ColorPicker.Current, -1, 1)
	ColorPicker.CurrentTexture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	ColorPicker.CurrentTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	ColorPicker.CurrentText = ColorPicker.Current:CreateFontString(nil, "OVERLAY")
	ColorPicker.CurrentText:SetPoint("CENTER", ColorPicker.Current, HEADER_SPACING, -1)
	HydraUI:SetFontInfo(ColorPicker.CurrentText, Settings["ui-header-font"], Settings["ui-font-size"])
	ColorPicker.CurrentText:SetJustifyH("CENTER")
	ColorPicker.CurrentText:SetText(Language["Current"])
	ColorPicker.CurrentText:SetTextColor(HydraUI:HexToRGB(Settings["ui-header-font-color"]))

	ColorPicker.CurrentHex = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.CurrentHex:SetSize(108, 20)
	ColorPicker.CurrentHex:SetPoint("TOPLEFT", ColorPicker.Current, "BOTTOMLEFT", 0, -2)
	ColorPicker.CurrentHex:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.CurrentHex:SetBackdropColor(0, 0, 0)
	ColorPicker.CurrentHex:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.CurrentHexTexture = ColorPicker.CurrentHex:CreateTexture(nil, "OVERLAY")
	ColorPicker.CurrentHexTexture:SetPoint("TOPLEFT", ColorPicker.CurrentHex, 1, -1)
	ColorPicker.CurrentHexTexture:SetPoint("BOTTOMRIGHT", ColorPicker.CurrentHex, -1, 1)
	ColorPicker.CurrentHexTexture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	ColorPicker.CurrentHexTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	ColorPicker.CurrentHexText = ColorPicker.CurrentHex:CreateFontString(nil, "OVERLAY")
	ColorPicker.CurrentHexText:SetPoint("CENTER", ColorPicker.CurrentHex, 0, 0)
	HydraUI:SetFontInfo(ColorPicker.CurrentHexText, Settings["ui-header-font"], Settings["ui-font-size"])
	ColorPicker.CurrentHexText:SetJustifyH("CENTER")

	ColorPicker.CompareCurrentParent = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.CompareCurrentParent:SetSize(20, 20)
	ColorPicker.CompareCurrentParent:SetPoint("LEFT", ColorPicker.CurrentHex, "RIGHT", 2, 0)
	ColorPicker.CompareCurrentParent:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.CompareCurrentParent:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	ColorPicker.CompareCurrentParent:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.CompareCurrent = ColorPicker.CompareCurrentParent:CreateTexture(nil, "OVERLAY")
	ColorPicker.CompareCurrent:SetPoint("TOPLEFT", ColorPicker.CompareCurrentParent, 1, -1)
	ColorPicker.CompareCurrent:SetPoint("BOTTOMRIGHT", ColorPicker.CompareCurrentParent, -1, 1)
	ColorPicker.CompareCurrent:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))

	-- New
	ColorPicker.New = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.New:SetSize((390 / 3), 20)
	ColorPicker.New:SetPoint("TOPLEFT", ColorPicker.Current, "TOPRIGHT", 2, 0)
	ColorPicker.New:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.New:SetBackdropColor(0, 0, 0)
	ColorPicker.New:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.NewTexture = ColorPicker.New:CreateTexture(nil, "OVERLAY")
	ColorPicker.NewTexture:SetPoint("TOPLEFT", ColorPicker.New, 1, -1)
	ColorPicker.NewTexture:SetPoint("BOTTOMRIGHT", ColorPicker.New, -1, 1)
	ColorPicker.NewTexture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	ColorPicker.NewTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	ColorPicker.NewText = ColorPicker.New:CreateFontString(nil, "OVERLAY")
	ColorPicker.NewText:SetPoint("CENTER", ColorPicker.New, 0, -1)
	HydraUI:SetFontInfo(ColorPicker.NewText, Settings["ui-header-font"], Settings["ui-font-size"])
	ColorPicker.NewText:SetJustifyH("CENTER")
	ColorPicker.NewText:SetText(Language["New"])
	ColorPicker.NewText:SetTextColor(HydraUI:HexToRGB(Settings["ui-header-font-color"]))

	ColorPicker.NewHex = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.NewHex:SetSize(108, 20)
	ColorPicker.NewHex:SetPoint("TOPRIGHT", ColorPicker.New, "BOTTOMRIGHT", 0, -2)
	ColorPicker.NewHex:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.NewHex:SetBackdropColor(0, 0, 0)
	ColorPicker.NewHex:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.NewHexTexture = ColorPicker.NewHex:CreateTexture(nil, "OVERLAY")
	ColorPicker.NewHexTexture:SetPoint("TOPLEFT", ColorPicker.NewHex, 1, -1)
	ColorPicker.NewHexTexture:SetPoint("BOTTOMRIGHT", ColorPicker.NewHex, -1, 1)
	ColorPicker.NewHexTexture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	ColorPicker.NewHexTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	ColorPicker.NewHexText = CreateFrame("EditBox", nil, ColorPicker.NewHex)
	HydraUI:SetFontInfo(ColorPicker.NewHexText, Settings["ui-widget-font"], Settings["ui-font-size"])
	ColorPicker.NewHexText:SetPoint("TOPLEFT", ColorPicker.NewHex, SPACING, -2)
	ColorPicker.NewHexText:SetPoint("BOTTOMRIGHT", ColorPicker.NewHex, -SPACING, 2)
	ColorPicker.NewHexText:SetJustifyH("CENTER")
	ColorPicker.NewHexText:SetMaxLetters(7)
	ColorPicker.NewHexText:SetAutoFocus(false)
	ColorPicker.NewHexText:EnableKeyboard(true)
	ColorPicker.NewHexText:EnableMouse(true)
	ColorPicker.NewHexText:SetText("")
	ColorPicker.NewHexText:SetHighlightColor(0, 0, 0)
	ColorPicker.NewHexText:SetScript("OnMouseDown", SwatchEditBoxOnMouseDown)
	ColorPicker.NewHexText:SetScript("OnEscapePressed", SwatchEditBoxOnEscapePressed)
	ColorPicker.NewHexText:SetScript("OnEnterPressed", SwatchEditBoxOnEnterPressed)
	ColorPicker.NewHexText:SetScript("OnEditFocusLost", SwatchEditBoxOnEditFocusLost)
	ColorPicker.NewHexText:SetScript("OnEditFocusGained", SwatchEditBoxOnEditFocusGained)
	ColorPicker.NewHexText:SetScript("OnChar", SwatchEditBoxOnChar)

	ColorPicker.CompareNewParent = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.CompareNewParent:SetSize(20, 20)
	ColorPicker.CompareNewParent:SetPoint("RIGHT", ColorPicker.NewHex, "LEFT", -2, 0)
	ColorPicker.CompareNewParent:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.CompareNewParent:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	ColorPicker.CompareNewParent:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.CompareNew = ColorPicker.CompareNewParent:CreateTexture(nil, "OVERLAY")
	ColorPicker.CompareNew:SetSize(ColorPicker.CompareNewParent:GetWidth() - 2, 19)
	ColorPicker.CompareNew:SetPoint("TOPLEFT", ColorPicker.CompareNewParent, 1, -1)
	ColorPicker.CompareNew:SetPoint("BOTTOMRIGHT", ColorPicker.CompareNewParent, -1, 1)
	ColorPicker.CompareNew:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))

	ColorPicker.Transition = LibMotion:CreateAnimation(ColorPicker.CompareNew, "Color")
	ColorPicker.Transition:SetColorType("vertex")
	ColorPicker.Transition:SetEasing("in")
	ColorPicker.Transition:SetDuration(0.3)

	-- Accept
	ColorPicker.Accept = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.Accept:SetSize((390 / 3) - (SPACING * 3) + 1, 20)
	ColorPicker.Accept:SetPoint("TOPLEFT", ColorPicker.New, "TOPRIGHT", 2, 0)
	ColorPicker.Accept:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.Accept:SetBackdropColor(0, 0, 0)
	ColorPicker.Accept:SetBackdropBorderColor(0, 0, 0)
	ColorPicker.Accept:SetScript("OnMouseDown", SwatchButtonOnMouseDown)
	ColorPicker.Accept:SetScript("OnMouseUp", ColorPickerAccept)
	ColorPicker.Accept:SetScript("OnEnter", ColorPickerOnEnter)
	ColorPicker.Accept:SetScript("OnLeave", ColorPickerOnLeave)

	ColorPicker.Accept.Texture = ColorPicker.Accept:CreateTexture(nil, "ARTWORK")
	ColorPicker.Accept.Texture:SetPoint("TOPLEFT", ColorPicker.Accept, 1, -1)
	ColorPicker.Accept.Texture:SetPoint("BOTTOMRIGHT", ColorPicker.Accept, -1, 1)
	ColorPicker.Accept.Texture:SetTexture(Assets:GetTexture(Settings["ui-button-texture"]))
	ColorPicker.Accept.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-button-texture-color"]))

	ColorPicker.Accept.Highlight = ColorPicker.Accept:CreateTexture(nil, "OVERLAY")
	ColorPicker.Accept.Highlight:SetPoint("TOPLEFT", ColorPicker.Accept, 1, -1)
	ColorPicker.Accept.Highlight:SetPoint("BOTTOMRIGHT", ColorPicker.Accept, -1, 1)
	ColorPicker.Accept.Highlight:SetTexture(Assets:GetTexture("Blank"))
	ColorPicker.Accept.Highlight:SetVertexColor(1, 1, 1, 0.4)
	ColorPicker.Accept.Highlight:SetAlpha(0)

	ColorPicker.AcceptText = ColorPicker.Accept:CreateFontString(nil, "OVERLAY")
	ColorPicker.AcceptText:SetPoint("CENTER", ColorPicker.Accept, 0, 0)
	HydraUI:SetFontInfo(ColorPicker.AcceptText, Settings["ui-button-font"], Settings["ui-font-size"])
	ColorPicker.AcceptText:SetJustifyH("CENTER")
	ColorPicker.AcceptText:SetText("|cFF"..Settings["ui-button-font-color"]..ACCEPT.."|r")

	-- Cancel
	ColorPicker.Cancel = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.Cancel:SetSize((390 / 3) - (SPACING * 3) + 1, 20)
	ColorPicker.Cancel:SetPoint("TOPLEFT", ColorPicker.Accept, "BOTTOMLEFT", 0, -2)
	ColorPicker.Cancel:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.Cancel:SetBackdropColor(0, 0, 0)
	ColorPicker.Cancel:SetBackdropBorderColor(0, 0, 0)
	ColorPicker.Cancel:SetScript("OnMouseDown", SwatchButtonOnMouseDown)
	ColorPicker.Cancel:SetScript("OnMouseUp", ColorPickerCancel)
	ColorPicker.Cancel:SetScript("OnEnter", ColorPickerOnEnter)
	ColorPicker.Cancel:SetScript("OnLeave", ColorPickerOnLeave)

	ColorPicker.Cancel.Texture = ColorPicker.Cancel:CreateTexture(nil, "ARTWORK")
	ColorPicker.Cancel.Texture:SetPoint("TOPLEFT", ColorPicker.Cancel, 1, -1)
	ColorPicker.Cancel.Texture:SetPoint("BOTTOMRIGHT", ColorPicker.Cancel, -1, 1)
	ColorPicker.Cancel.Texture:SetTexture(Assets:GetTexture(Settings["ui-button-texture"]))
	ColorPicker.Cancel.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-button-texture-color"]))

	ColorPicker.Cancel.Highlight = ColorPicker.Cancel:CreateTexture(nil, "OVERLAY")
	ColorPicker.Cancel.Highlight:SetPoint("TOPLEFT", ColorPicker.Cancel, 1, -1)
	ColorPicker.Cancel.Highlight:SetPoint("BOTTOMRIGHT", ColorPicker.Cancel, -1, 1)
	ColorPicker.Cancel.Highlight:SetTexture(Assets:GetTexture("Blank"))
	ColorPicker.Cancel.Highlight:SetVertexColor(1, 1, 1, 0.4)
	ColorPicker.Cancel.Highlight:SetAlpha(0)

	ColorPicker.CancelText = ColorPicker.Cancel:CreateFontString(nil, "OVERLAY")
	ColorPicker.CancelText:SetPoint("CENTER", ColorPicker.Cancel, 0, 0)
	HydraUI:SetFontInfo(ColorPicker.CancelText, Settings["ui-button-font"], Settings["ui-font-size"])
	ColorPicker.CancelText:SetJustifyH("CENTER")
	ColorPicker.CancelText:SetText("|cFF"..Settings["ui-button-font-color"]..CANCEL.."|r")

	ColorPicker.BG = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
	ColorPicker.BG:SetPoint("TOPLEFT", ColorPicker.Header, -3, 3)
	ColorPicker.BG:SetPoint("BOTTOMRIGHT", ColorPicker, 3, 0)
	ColorPicker.BG:SetBackdrop(HydraUI.BackdropAndBorder)
	ColorPicker.BG:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	ColorPicker.BG:SetBackdropBorderColor(0, 0, 0)

	ColorPicker.FadeIn = LibMotion:CreateAnimation(ColorPicker, "Fade")
	ColorPicker.FadeIn:SetEasing("in")
	ColorPicker.FadeIn:SetDuration(0.3)
	ColorPicker.FadeIn:SetChange(1)

	ColorPicker.FadeOut = LibMotion:CreateAnimation(ColorPicker, "Fade")
	ColorPicker.FadeOut:SetEasing("out")
	ColorPicker.FadeOut:SetDuration(0.3)
	ColorPicker.FadeOut:SetChange(0)
	ColorPicker.FadeOut:SetScript("OnFinished", FadeOnFinished)

	local PaletteDropdown = GUI.Widgets.CreateDropdown(ColorPicker, "ui-picker-palette", Settings["ui-picker-palette"], Assets:GetPaletteList(), Language["Set Palette"], Language["Select a color palette to use"], UpdateColorPalette, "Palette")
	PaletteDropdown:ClearAllPoints()
	PaletteDropdown:SetPoint("BOTTOMLEFT", ColorPicker, 2, 3)
	PaletteDropdown:GetParent():SetPoint("BOTTOMLEFT", ColorPicker, 0, 3)
	PaletteDropdown.Text:ClearAllPoints()
	PaletteDropdown.Text:SetPoint("LEFT", PaletteDropdown, "RIGHT", LABEL_SPACING, 0)

	local Palette = Assets:GetPalette(Settings["ui-picker-palette"])

	ColorPicker.SetColorPalette = function(self, name)
		local Palette = Assets:GetPalette(name)
		local Swatch

		for i = 1, MAX_SWATCHES_Y do
			for j = 1, MAX_SWATCHES_X do
				Swatch = self.SwatchParent[i][j]

				if Palette[i] and Palette[i][j] then
					Swatch.Value = Palette[i][j]
					Swatch:SetScript("OnMouseUp", ColorSwatchOnMouseUp)
					Swatch:SetScript("OnEnter", ColorSwatchOnEnter)
					Swatch:SetScript("OnLeave", ColorSwatchOnLeave)
				else
					Swatch.Value = "444444"
					Swatch:SetScript("OnMouseUp", nil)
					Swatch:SetScript("OnEnter", nil)
					Swatch:SetScript("OnLeave", nil)
				end

				Swatch.Texture:SetVertexColor(HydraUI:HexToRGB(Swatch.Value))
			end
		end
	end

	for i = 1, MAX_SWATCHES_Y do
		for j = 1, MAX_SWATCHES_X do
			local Swatch = CreateFrame("Frame", nil, ColorPicker, "BackdropTemplate")
			Swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)
			Swatch:SetBackdrop(HydraUI.BackdropAndBorder)
			Swatch:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
			Swatch:SetBackdropBorderColor(0, 0, 0)

			if Palette[i] and Palette[i][j] then
				Swatch.Value = Palette[i][j]
				Swatch:SetScript("OnMouseUp", ColorSwatchOnMouseUp)
				Swatch:SetScript("OnEnter", ColorSwatchOnEnter)
				Swatch:SetScript("OnLeave", ColorSwatchOnLeave)
			else
				Swatch.Value = "444444"
				Swatch:SetScript("OnMouseUp", nil)
				Swatch:SetScript("OnEnter", nil)
				Swatch:SetScript("OnLeave", nil)
			end

			Swatch.Texture = Swatch:CreateTexture(nil, "OVERLAY")
			Swatch.Texture:SetPoint("TOPLEFT", Swatch, 1, -1)
			Swatch.Texture:SetPoint("BOTTOMRIGHT", Swatch, -1, 1)
			Swatch.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
			Swatch.Texture:SetVertexColor(HydraUI:HexToRGB(Swatch.Value))

			Swatch.Highlight = CreateFrame("Frame", nil, Swatch, "BackdropTemplate")
			Swatch.Highlight:SetBackdrop(HydraUI.Outline)
			Swatch.Highlight:SetPoint("TOPLEFT", Swatch, 1, -1)
			Swatch.Highlight:SetPoint("BOTTOMRIGHT", Swatch, -1, 1)
			Swatch.Highlight:SetBackdropColor(0, 0, 0)
			Swatch.Highlight:SetBackdropBorderColor(1, 1, 1)
			Swatch.Highlight:SetAlpha(0)

			if not ColorPicker.SwatchParent[i] then
				ColorPicker.SwatchParent[i] = {}
			end

			if i == 1 then
				if j == 1 then
					Swatch:SetPoint("TOPLEFT", ColorPicker.SwatchParent, 3, -3)
				else
					Swatch:SetPoint("LEFT", ColorPicker.SwatchParent[i][j-1], "RIGHT", -1, 0)
				end
			else
				if j == 1 then
					Swatch:SetPoint("TOPLEFT", ColorPicker.SwatchParent[i-1][1], "BOTTOMLEFT", 0, 1)
				else
					Swatch:SetPoint("LEFT", ColorPicker.SwatchParent[i][j-1], "RIGHT", -1, 0)
				end
			end

			ColorPicker.SwatchParent[i][j] = Swatch
		end
	end

	GUI.ColorPicker = ColorPicker
end

local SetSwatchObject = function(active)
	Controller.Active = active
	GUI.ColorPicker.Active = active

	GUI.ColorPicker.CompareCurrent:SetVertexColor(HydraUI:HexToRGB(active.Value))
	GUI.ColorPicker.CurrentHexText:SetText("#"..active.Value)

	GUI.ColorPicker.NewHexText:SetText("")
	GUI.ColorPicker.CompareNew:SetVertexColor(1, 1, 1)
	GUI.ColorPicker.Selected = active.Value
end

local ColorSelectionOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local ColorSelectionOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local ColorSelectionOnMouseUp = function(self)
	if not GUI.ColorPicker then
		CreateColorPicker()
	end

	if GUI.ColorPicker:IsShown() then
		if self ~= GUI.ColorPicker.Active then
			SetSwatchObject(self)
		else
			GUI.ColorPicker.FadeOut:Play()
		end
	else
		SetSwatchObject(self)

		GUI.ColorPicker:Show()
		GUI.ColorPicker.FadeIn:Play()
	end

	self.MiddleText:ClearAllPoints()
	self.MiddleText:SetPoint("CENTER", self, 0, 0)
end

local ColorSelectionOnMouseDown = function(self)
	self.MiddleText:ClearAllPoints()
	self.MiddleText:SetPoint("CENTER", self, 1, -1)
end

local ColorRequiresReload = function(self, flag)
	self.ReloadFlag = flag

	return self
end

GUI.Widgets.CreateColorSelection = function(self, id, value, label, tooltip, hook)
	if Settings[id] ~= nil then
		value = Settings[id]
	end
	value = Core.NormalizeColor(value)

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	local Swatch = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Swatch:SetSize(SWATCH_SIZE, SWATCH_SIZE)
	Swatch:SetPoint("RIGHT", Anchor, 0, 0)
	Swatch:SetBackdrop(HydraUI.BackdropAndBorder)
	Swatch:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Swatch:SetBackdropBorderColor(0, 0, 0)

	Swatch.Texture = Swatch:CreateTexture(nil, "OVERLAY")
	Swatch.Texture:SetPoint("TOPLEFT", Swatch, 1, -1)
	Swatch.Texture:SetPoint("BOTTOMRIGHT", Swatch, -1, 1)
	Swatch.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Swatch.Texture:SetVertexColor(HydraUI:HexToRGB(value))

	local Button = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Button:SetSize(COLOR_WIDTH, WIDGET_HEIGHT)
	Button:SetPoint("RIGHT", Swatch, "LEFT", -2, 0)
	Button:SetBackdrop(HydraUI.BackdropAndBorder)
	Button:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Button:SetBackdropBorderColor(0, 0, 0)
	Button:SetScript("OnEnter", ColorSelectionOnEnter)
	Button:SetScript("OnLeave", ColorSelectionOnLeave)
	Button:SetScript("OnMouseUp", ColorSelectionOnMouseUp)
	Button:SetScript("OnMouseDown", ColorSelectionOnMouseDown)
	Button.ID = id
	Button.Hook = hook
	Button.Value = value
	Button.Tooltip = tooltip
	Button.Swatch = Swatch
	Button.RequiresReload = ColorRequiresReload

	Button.Highlight = Button:CreateTexture(nil, "OVERLAY")
	Button.Highlight:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Highlight:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Button.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Button.Highlight:SetAlpha(0)

	Button.Texture = Button:CreateTexture(nil, "ARTWORK")
	Button.Texture:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Texture:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Button.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	Button.Transition = LibMotion:CreateAnimation(Swatch.Texture, "color")
	Button.Transition:SetColorType("vertex")
	Button.Transition:SetEasing("in")
	Button.Transition:SetDuration(0.3)

	Button.MiddleText = Button:CreateFontString(nil, "OVERLAY")
	Button.MiddleText:SetPoint("CENTER", Button, 0, 0)
	Button.MiddleText:SetSize(COLOR_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Button.MiddleText, Settings["ui-widget-font"], Settings["ui-font-size"])
	Button.MiddleText:SetJustifyH("CENTER")
	Button.MiddleText:SetText("#"..upper(value))

	Button.Text = Button:CreateFontString(nil, "OVERLAY")
	Button.Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Button.Text:SetSize(GROUP_WIDTH - COLOR_WIDTH - SWATCH_SIZE - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Button.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Button.Text:SetJustifyH("LEFT")
	Button.Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	RegisterWidget(self, Anchor, "")

	return Button
end
