local HydraUI, Language, Assets, Settings = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local SPACING, HEADER_HEIGHT = 3, 20

function GUI:CreateUpdateWindow()
	if self.UpdateWindow then
		return
	end

	self.UpdateWindow = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.UpdateWindow:SetFrameStrata("HIGH")
	self.UpdateWindow:SetFrameLevel(10)
	self.UpdateWindow:SetSize(340, 168) -- GUI_WIDTH / 3 -- 220 200
	self.UpdateWindow:SetPoint("CENTER", HydraUI.UIParent, 0, 0)
	self.UpdateWindow:SetBackdrop(HydraUI.BackdropAndBorder)
	self.UpdateWindow:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	self.UpdateWindow:SetBackdropBorderColor(0, 0, 0)
	self.UpdateWindow:EnableMouse(true)
	self.UpdateWindow:SetMovable(true)
	self.UpdateWindow:RegisterForDrag("LeftButton")
	self.UpdateWindow:SetScript("OnDragStart", self.StartMoving)
	self.UpdateWindow:SetScript("OnDragStop", self.StopMovingOrSizing)
	self.UpdateWindow:SetClampedToScreen(true)

	self.UpdateWindow.Header = CreateFrame("Frame", nil, self.UpdateWindow, "BackdropTemplate")
	self.UpdateWindow.Header:SetHeight(HEADER_HEIGHT)
	self.UpdateWindow.Header:SetPoint("TOPLEFT", self.UpdateWindow, SPACING, -SPACING)
	self.UpdateWindow.Header:SetPoint("TOPRIGHT", self.UpdateWindow, -SPACING, -SPACING)
	self.UpdateWindow.Header:SetBackdrop(HydraUI.BackdropAndBorder)
	self.UpdateWindow.Header:SetBackdropColor(0, 0, 0, 0)
	self.UpdateWindow.Header:SetBackdropBorderColor(0, 0, 0)

	self.UpdateWindow.Header.Texture = self.UpdateWindow.Header:CreateTexture(nil, "ARTWORK")
	self.UpdateWindow.Header.Texture:SetPoint("TOPLEFT", self.UpdateWindow.Header, 1, -1)
	self.UpdateWindow.Header.Texture:SetPoint("BOTTOMRIGHT", self.UpdateWindow.Header, -1, 1)
	self.UpdateWindow.Header.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.UpdateWindow.Header.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	self.UpdateWindow.Header.Text = self.UpdateWindow.Header:CreateFontString(nil, "OVERLAY")
	self.UpdateWindow.Header.Text:SetPoint("LEFT", self.UpdateWindow.Header, 5, 0)
	self.UpdateWindow.Header.Text:SetSize(340 - 6, HEADER_HEIGHT)
	HydraUI:SetFontInfo(self.UpdateWindow.Header.Text, Settings["ui-header-font"], Settings["ui-header-font-size"])
	self.UpdateWindow.Header.Text:SetJustifyH("LEFT")
	self.UpdateWindow.Header.Text:SetTextColor(HydraUI:HexToRGB(Settings["ui-header-font-color"]))
	self.UpdateWindow.Header.Text:SetText(Language["Update"])

	self.UpdateWindow.CloseButton = CreateFrame("Frame", nil, self.UpdateWindow.Header)
	self.UpdateWindow.CloseButton:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
	self.UpdateWindow.CloseButton:SetPoint("RIGHT", self.UpdateWindow.Header, 0, -1)
	self.UpdateWindow.CloseButton:SetScript("OnEnter", function(self) self.Cross:SetVertexColor(HydraUI:HexToRGB("C0392B")) end)
	self.UpdateWindow.CloseButton:SetScript("OnLeave", function(self) self.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE")) end)
	self.UpdateWindow.CloseButton:SetScript("OnMouseUp", function() self.UpdateWindow:Hide() end)

	self.UpdateWindow.CloseButton.Cross = self.UpdateWindow.CloseButton:CreateTexture(nil, "OVERLAY")
	self.UpdateWindow.CloseButton.Cross:SetPoint("CENTER", self.UpdateWindow.CloseButton, 0, 0)
	self.UpdateWindow.CloseButton.Cross:SetSize(16, 16)
	self.UpdateWindow.CloseButton.Cross:SetTexture(Assets:GetTexture("Close"))
	self.UpdateWindow.CloseButton.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE"))

	self.UpdateWindow.WidgetsBG = CreateFrame("Frame", nil, self.UpdateWindow)
	self.UpdateWindow.WidgetsBG:SetPoint("TOPLEFT", self.UpdateWindow.Header, "BOTTOMLEFT", 0, -2)
	self.UpdateWindow.WidgetsBG:SetPoint("BOTTOMRIGHT", self.UpdateWindow, -SPACING, SPACING)

	self.UpdateWindow.WidgetsBG.Backdrop = CreateFrame("Frame", nil, self.UpdateWindow, "BackdropTemplate")
	self.UpdateWindow.WidgetsBG.Backdrop:SetAllPoints(self.UpdateWindow.WidgetsBG)
	self.UpdateWindow.WidgetsBG.Backdrop:SetBackdrop(HydraUI.BackdropAndBorder)
	self.UpdateWindow.WidgetsBG.Backdrop:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	self.UpdateWindow.WidgetsBG.Backdrop:SetBackdropBorderColor(0, 0, 0)

	self.UpdateWindow.Text = CreateFrame("EditBox", nil, self.UpdateWindow.WidgetsBG)
	HydraUI:SetFontInfo(self.UpdateWindow.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	self.UpdateWindow.Text:SetTextColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	self.UpdateWindow.Text:SetPoint("TOPLEFT", self.UpdateWindow.WidgetsBG, 6, -6)
	self.UpdateWindow.Text:SetPoint("TOPRIGHT", self.UpdateWindow.WidgetsBG, -6, 6)
	self.UpdateWindow.Text:SetHeight(80)
	self.UpdateWindow.Text:SetJustifyH("LEFT")
	self.UpdateWindow.Text:SetAutoFocus(false)
	self.UpdateWindow.Text:SetMultiLine(true)
	self.UpdateWindow.Text:SetMaxLetters(500)
	self.UpdateWindow.Text:SetText(Language["Staying up-to-date ensures the latest features and bug fixes! Please consider using one of the websites below as they share a portion of ad revenue with creators."])

	for i = 1, 2 do
		local Box = CreateFrame("Frame", nil, self.UpdateWindow.WidgetsBG, "BackdropTemplate")
		Box:SetHeight(20)
		Box:SetPoint("LEFT", self.UpdateWindow.WidgetsBG, 3, 0)
		Box:SetPoint("RIGHT", self.UpdateWindow.WidgetsBG, -3, 0)
		Box:SetBackdrop(HydraUI.BackdropAndBorder)
		Box:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
		Box:SetBackdropBorderColor(0, 0, 0)

		--[[Box.Texture = Box:CreateTexture(nil, "BACKGROUND")
		Box.Texture:SetPoint("TOPLEFT", Box, 1, -1)
		Box.Texture:SetPoint("BOTTOMRIGHT", Box, -1, 1)
		Box.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		Box.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))]]

		Box.Input = CreateFrame("EditBox", nil, Box)
		HydraUI:SetFontInfo(Box.Input, Settings["ui-widget-font"], Settings["ui-font-size"])
		Box.Input:SetPoint("TOPLEFT", Box, 3, -3)
		Box.Input:SetPoint("BOTTOMRIGHT", Box, -3, 3)
		Box.Input:SetFrameLevel(10)
		Box.Input:SetFrameStrata("DIALOG")
		Box.Input:SetJustifyH("LEFT")
		Box.Input:SetAutoFocus(false)
		Box.Input:EnableKeyboard(true)
		Box.Input:EnableMouse(true)
		Box.Input:SetMaxLetters(999)

		Box.Label = Box.Input:CreateFontString(nil, "OVERLAY")
		Box.Label:SetPoint("BOTTOMLEFT", Box, "TOPLEFT", 3, 4)
		HydraUI:SetFontInfo(Box.Label, Settings["ui-font"], Settings["ui-font-size"])
		Box.Label:SetJustifyH("LEFT")

		Box.Input:SetScript("OnEditFocusLost", function(self)
			self:HighlightText(0, 0)
			self:SetCursorPosition(0)
		end)
		Box.Input:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
			self:HighlightText(0, 0)
			self:SetCursorPosition(0)
		end)
		Box.Input:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
			self:HighlightText(0, 0)
			self:SetCursorPosition(0)
		end)
		Box.Input:SetScript("OnTextChanged", function(self)
			if (self:GetText() ~= self.Link) then
				self:Insert(self.Link)
			end
		end)
		Box.Input:SetScript("OnMouseDown", function(self)
			self:SetFocus()
			self:HighlightText(0, self:GetText():len())
			self:SetCursorPosition(0)
		end)

		if (i == 1) then
			Box:SetPoint("BOTTOMLEFT", self.UpdateWindow.WidgetsBG, 3, 3)
			Box.Label:SetText(Language["Download at Wago (WeakAuras Addons)"])
			Box.Input.Link = "https://addons.wago.io/addons/hydraui"
			Box.Input:SetText("https://addons.wago.io/addons/hydraui")
		else
			Box:SetPoint("BOTTOMLEFT", self.UpdateWindow.WidgetsBG, 3, 50)
			Box.Label:SetText(Language["Download at CurseForge"])
			Box.Input.Link = "https://www.curseforge.com/wow/addons/hydraui"
			Box.Input:SetText("https://www.curseforge.com/wow/addons/hydraui")
		end

		Box.Input:SetCursorPosition(0)
	end
end

function GUI:CreateUpdateAlert()
	if self.Alert then
		return
	end

	if (not self.Header) then
		self.QueueAlert = true

		return
	end

	self.Alert = CreateFrame("Frame", nil, self.Header)
	self.Alert:SetPoint("LEFT", self.Header, 0, 0)
	self.Alert:SetHeight(32)

	self.AlertBG = self.Alert:CreateTexture(nil, "OVERLAY", 1)
	self.AlertBG:SetPoint("LEFT", self.Alert, 0, 0)
	self.AlertBG:SetSize(32, 32)
	self.AlertBG:SetTexture(Assets:GetTexture("Warning"))
	self.AlertBG:SetVertexColor(1, 0.8, 0.1)

	self.AlertInside = self.Alert:CreateTexture(nil, "OVERLAY", 2)
	self.AlertInside:SetPoint("LEFT", self.Alert, 0, 0)
	self.AlertInside:SetSize(32, 32)
	self.AlertInside:SetTexture(Assets:GetTexture("WarningInner"))
	self.AlertInside:SetVertexColor(0.95, 0.95, 0.95)

	self.Alert.Text = self.Alert:CreateFontString(nil, "OVERLAY")
	self.Alert.Text:SetPoint("LEFT", self.Alert, 30, -1)
	HydraUI:SetFontInfo(self.Alert.Text, Settings["ui-header-font"], Settings["ui-font-size"])
	self.Alert.Text:SetJustifyH("LEFT")
	self.Alert.Text:SetTextColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	self.Alert.Text:SetText(Language["Update available"])

	self.Alert:SetWidth(self.Alert.Text:GetStringWidth() + 32)

	self.Alert:SetScript("OnEnter", function(self)
		self.Text:SetTextColor(1, 1, 1)
	end)

	self.Alert:SetScript("OnLeave", function(self)
		self.Text:SetTextColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	end)

	self.Alert:SetScript("OnMouseDown", function(self)
		self.Text:SetPoint("LEFT", self, 31, -2)

		HydraUI:print(Language["You can get an updated version of HydraUI at https://www.curseforge.com/wow/addons/hydraui"])

		if GUI.UpdateWindow then
			GUI.UpdateWindow:Show()
		else
			GUI:CreateUpdateWindow()
		end
	end)

	self.Alert:SetScript("OnMouseUp", function(self)
		self.Text:SetPoint("LEFT", self, 30, -1)
	end)
end

