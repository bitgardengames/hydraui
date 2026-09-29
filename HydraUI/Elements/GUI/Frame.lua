local HydraUI, Language, Assets, Settings = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local SPACING, WIDGET_HEIGHT, BUTTON_LIST_WIDTH = 3, 20, 126
local GUI_WIDTH, GUI_HEIGHT, HEADER_HEIGHT = 730, 362, 20
local HEADER_WIDTH = GUI_WIDTH - (SPACING * 2)
local PARENT_WIDTH = GUI_WIDTH - BUTTON_LIST_WIDTH - ((SPACING * 2) + 2)
local GROUP_WIDTH = ((PARENT_WIDTH / 2) - (SPACING * 4) - 8) + 1
local SELECTED_HIGHLIGHT_ALPHA, MOUSEOVER_HIGHLIGHT_ALPHA = 0.25, 0.1
local MAX_WIDGETS_SHOWN = math.floor(GUI_HEIGHT / (WIDGET_HEIGHT + SPACING))
local min, max = math.min, math.max
local GetMaxOffset = function(total) return GUI.GetMaxRowOffset(total, MAX_WIDGETS_SHOWN) end
local NoScroll = function() end

local ScrollWidgetColumn = function(parent, widgets, oldOffset, offset, point)
	local count = #widgets
	local first = offset
	local last = min(offset + MAX_WIDGETS_SHOWN - 1, count)

	if oldOffset then
		local oldLast = min(oldOffset + MAX_WIDGETS_SHOWN - 1, count)

		for i = oldOffset, oldLast do
			if (i < first) or (i > last) then
				widgets[i]:Hide()
			end
		end
	else
		-- Widgets start shown, so the initial layout must hide the non-visible rows once.
		for i = last + 1, count do
			widgets[i]:Hide()
		end
	end

	for i = first, last do
		local widget = widgets[i]
		local predecessor = widgets[i - 1]
		local anchor = (i == first) and parent or predecessor

		if (widget.HydraScrollAnchor ~= anchor) or (widget.HydraScrollPoint ~= point) then
			widget:ClearAllPoints()

			if (i == first) then
				widget:SetPoint(point, parent, point, point == "TOPLEFT" and SPACING or -SPACING, -SPACING)
			else
				widget:SetPoint("TOP", predecessor, "BOTTOM", 0, -2)
			end

			widget.HydraScrollAnchor = anchor
			widget.HydraScrollPoint = point
		end

		if (not oldOffset) or (i < oldOffset) or (i > oldOffset + MAX_WIDGETS_SHOWN - 1) then
			widget:Show()
		end
	end
end

local UpdateWidgetRows = function(Owner, Rows, OldRows, OldFirst, OldLast, First)
	local LeftOffset = Owner.LeftWidgetsBG.ScrollingDisabled and 1 or First
	local RightOffset = Owner.RightWidgetsBG.ScrollingDisabled and 1 or First

	ScrollWidgetColumn(Owner.LeftWidgetsBG, Owner.LeftWidgets, Owner.LastRenderedLeftOffset, LeftOffset, "TOPLEFT")
	ScrollWidgetColumn(Owner.RightWidgetsBG, Owner.RightWidgets, Owner.LastRenderedRightOffset, RightOffset, "TOPRIGHT")
	Owner.LastRenderedLeftOffset = LeftOffset
	Owner.LastRenderedRightOffset = RightOffset
end

local AfterRenderWidgetRows = function(Owner, Offset)
	if not Owner.ScrollBar then return end
	if Offset == 1 then
		Owner.ScrollUp.Arrow:SetVertexColor(0.65, 0.65, 0.65)
	else
		Owner.ScrollUp.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	end
	if Offset == Owner.MaxScroll then
		Owner.ScrollDown.Arrow:SetVertexColor(0.65, 0.65, 0.65)
	else
		Owner.ScrollDown.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	end
end

local AddWindowScrollBar = function(self)
	-- Scroll up
	self.ScrollUp = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.ScrollUp:SetSize(16, WIDGET_HEIGHT)
	self.ScrollUp:SetPoint("TOPRIGHT", GUI, -SPACING, -((SPACING * 2) + HEADER_HEIGHT - 1))
	self.ScrollUp:SetBackdrop(HydraUI.BackdropAndBorder)
	self.ScrollUp:SetBackdropColor(0, 0, 0, 0)
	self.ScrollUp:SetBackdropBorderColor(0, 0, 0)
	self.ScrollUp:SetScript("OnMouseUp", function(button) button.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"])); self.RowViewport:ScrollBy(1) end)
	self.ScrollUp:SetScript("OnMouseDown", function(button) local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"]); button.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85) end)

	self.ScrollUp.Texture = self.ScrollUp:CreateTexture(nil, "ARTWORK")
	self.ScrollUp.Texture:SetPoint("TOPLEFT", self.ScrollUp, 1, -1)
	self.ScrollUp.Texture:SetPoint("BOTTOMRIGHT", self.ScrollUp, -1, 1)
	self.ScrollUp.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.ScrollUp.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	self.ScrollUp.Highlight = self.ScrollUp:CreateTexture(nil, "HIGHLIGHT")
	self.ScrollUp.Highlight:SetPoint("TOPLEFT", self.ScrollUp, 1, -1)
	self.ScrollUp.Highlight:SetPoint("BOTTOMRIGHT", self.ScrollUp, -1, 1)
	self.ScrollUp.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.ScrollUp.Highlight:SetVertexColor(1, 1, 1)
	self.ScrollUp.Highlight:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)

	self.ScrollUp.Arrow = self.ScrollUp:CreateTexture(nil, "OVERLAY")
	self.ScrollUp.Arrow:SetPoint("CENTER", self.ScrollUp, 0, 0)
	self.ScrollUp.Arrow:SetSize(16, 16)
	self.ScrollUp.Arrow:SetTexture(Assets:GetTexture("Arrow Up"))
	self.ScrollUp.Arrow:SetVertexColor(0.65, 0.65, 0.65)

	-- Scroll down
	self.ScrollDown = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.ScrollDown:SetSize(16, WIDGET_HEIGHT)
	self.ScrollDown:SetPoint("BOTTOMRIGHT", GUI, -SPACING, SPACING)
	self.ScrollDown:SetBackdrop(HydraUI.BackdropAndBorder)
	self.ScrollDown:SetBackdropColor(0, 0, 0, 0)
	self.ScrollDown:SetBackdropBorderColor(0, 0, 0)
	self.ScrollDown:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

		self:GetParent().RowViewport:ScrollBy(-1)
	end)

	self.ScrollDown:SetScript("OnMouseDown", function(self)
		local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

		self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
	end)

	self.ScrollDown.Texture = self.ScrollDown:CreateTexture(nil, "ARTWORK")
	self.ScrollDown.Texture:SetPoint("TOPLEFT", self.ScrollDown, 1, -1)
	self.ScrollDown.Texture:SetPoint("BOTTOMRIGHT", self.ScrollDown, -1, 1)
	self.ScrollDown.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.ScrollDown.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	self.ScrollDown.Highlight = self.ScrollDown:CreateTexture(nil, "HIGHLIGHT")
	self.ScrollDown.Highlight:SetPoint("TOPLEFT", self.ScrollDown, 1, -1)
	self.ScrollDown.Highlight:SetPoint("BOTTOMRIGHT", self.ScrollDown, -1, 1)
	self.ScrollDown.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.ScrollDown.Highlight:SetVertexColor(1, 1, 1)
	self.ScrollDown.Highlight:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)

	self.ScrollDown.Arrow = self.ScrollDown:CreateTexture(nil, "OVERLAY")
	self.ScrollDown.Arrow:SetPoint("CENTER", self.ScrollDown, 0, 0)
	self.ScrollDown.Arrow:SetSize(16, 16)
	self.ScrollDown.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
	self.ScrollDown.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	local ScrollBar = CreateFrame("Slider", nil, self, "BackdropTemplate")
	ScrollBar:SetPoint("TOPLEFT", self.ScrollUp, "BOTTOMLEFT", 0, -2)
	ScrollBar:SetPoint("BOTTOMRIGHT", self.ScrollDown, "TOPRIGHT", 0, 2)
	GUI:StyleVerticalSlider(ScrollBar, {Highlight = true, ProgressAlpha = SELECTED_HIGHLIGHT_ALPHA})
	self.RowViewport.ScrollBar = ScrollBar
	self.RowViewport:SetScrollRange(self.WidgetCount)
	ScrollBar:SetValue(1)

	ScrollBar.Window = self

	self.RowViewport:AttachMouseWheel(self)

	self.ScrollBar = ScrollBar
	self.RowViewport:SetScrollBar(ScrollBar)

	ScrollBar:Show()
end

local DisableScrolling = function(self)
	self.ScrollingDisabled = true
end

function GUI:CreateWidgetWindow(page)
	-- Window
	local Window = CreateFrame("Frame", nil, self)
	Window:SetWidth(PARENT_WIDTH)
	Window:SetPoint("TOPLEFT", self.ScrollUp, "TOPRIGHT", 2, 0)
	Window:SetPoint("TOPRIGHT", self.CloseButton, "BOTTOMRIGHT", 0, -2)
	Window:SetPoint("BOTTOMRIGHT", self, -SPACING, SPACING)
	Window:Hide()

	Window.LeftWidgetsBG = CreateFrame("Frame", nil, Window)
	Window.LeftWidgetsBG:SetWidth(GROUP_WIDTH)
	Window.LeftWidgetsBG:SetPoint("TOPLEFT", Window, 0, 0)
	Window.LeftWidgetsBG:SetPoint("BOTTOMLEFT", Window, 0, 0)

	Window.LeftWidgetsBG.Backdrop = CreateFrame("Frame", nil, Window, "BackdropTemplate")
	Window.LeftWidgetsBG.Backdrop:SetWidth(GROUP_WIDTH)
	Window.LeftWidgetsBG.Backdrop:SetPoint("TOPLEFT", Window.LeftWidgetsBG, 0, 0)
	Window.LeftWidgetsBG.Backdrop:SetPoint("BOTTOMLEFT", Window.LeftWidgetsBG, 0, 0)
	Window.LeftWidgetsBG.Backdrop:SetBackdrop(HydraUI.BackdropAndBorder)
	Window.LeftWidgetsBG.Backdrop:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Window.LeftWidgetsBG.Backdrop:SetBackdropBorderColor(0, 0, 0)

	Window.RightWidgetsBG = CreateFrame("Frame", nil, Window)
	Window.RightWidgetsBG:SetWidth(GROUP_WIDTH)
	Window.RightWidgetsBG:SetPoint("TOPLEFT", Window.LeftWidgetsBG, "TOPRIGHT", 2, 0)
	Window.RightWidgetsBG:SetPoint("BOTTOMLEFT", Window.LeftWidgetsBG, "BOTTOMRIGHT", 2, 0)

	Window.RightWidgetsBG.Backdrop = CreateFrame("Frame", nil, Window, "BackdropTemplate")
	Window.RightWidgetsBG.Backdrop:SetWidth(GROUP_WIDTH)
	Window.RightWidgetsBG.Backdrop:SetPoint("TOPLEFT", Window.RightWidgetsBG, 0, 0)
	Window.RightWidgetsBG.Backdrop:SetPoint("BOTTOMLEFT", Window.RightWidgetsBG, 0, 0)
	Window.RightWidgetsBG.Backdrop:SetBackdrop(HydraUI.BackdropAndBorder)
	Window.RightWidgetsBG.Backdrop:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Window.RightWidgetsBG.Backdrop:SetBackdropBorderColor(0, 0, 0)

	Window.Page = page
	Window.LeftWidgets = {}
	Window.RightWidgets = {}

	Window.LeftWidgetsBG.Widgets = Window.LeftWidgets
	Window.LeftWidgetsBG.DisableScrolling = DisableScrolling
	Window.RightWidgetsBG.Widgets = Window.RightWidgets
	Window.RightWidgetsBG.DisableScrolling = DisableScrolling

	for Name, Function in next, self.Widgets do
		Window.LeftWidgetsBG[Name] = Function
		Window.RightWidgetsBG[Name] = Function
	end

	local Calls = page.Callbacks

	-- Read the queue in place instead of repeatedly removing its first item. Aside
	-- from shifting the whole table for every callback, table.remove also made a
	-- widget-heavy window unnecessarily expensive to initialize.
	for i = 1, #Calls do
		Calls[i](Window.LeftWidgetsBG, Window.RightWidgetsBG)
		Calls[i] = nil
	end

	if (#Window.LeftWidgetsBG.Widgets > 0) then
		Window.LeftWidgetsBG:CreateFooter()
	end

	if (#Window.RightWidgetsBG.Widgets > 0) then
		Window.RightWidgetsBG:CreateFooter()
	end

	Window.WidgetCount = max(#Window.LeftWidgets, #Window.RightWidgets)
	Window.MaxScroll = GetMaxOffset(Window.WidgetCount)
	GUI:CreateRowViewport(Window, {
		Rows = Window.LeftWidgets,
		TotalRows = Window.WidgetCount,
		MaxVisibleRows = MAX_WIDGETS_SHOWN,
		UpdateRows = UpdateWidgetRows,
		AfterRender = AfterRenderWidgetRows,
	})

	if (Window.MaxScroll > 1) then
		AddWindowScrollBar(Window)
	else
		Window.ScrollFiller = CreateFrame("Frame", nil, Window, "BackdropTemplate")
		Window.ScrollFiller:SetPoint("TOPRIGHT", Window, 0, 0)
		Window.ScrollFiller:SetPoint("BOTTOMRIGHT", Window, 0, 0)
		Window.ScrollFiller:SetWidth(16)
		Window.ScrollFiller:SetBackdrop(HydraUI.BackdropAndBorder)
		Window.ScrollFiller:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
		Window.ScrollFiller:SetBackdropBorderColor(0, 0, 0)

		Window:SetScript("OnMouseWheel", NoScroll)
	end

	Window.RowViewport:SetOffset(1)

	return Window
end


local FadeOnFinished = function(self)
	self.Parent:Hide()
end

function GUI:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

local CreateMainShell = function(self)
	-- This just makes the animation look better. That's all. ಠ_ಠ
	self.BlackTexture = self:CreateTexture(nil, "BACKGROUND")
	self.BlackTexture:SetPoint("TOPLEFT", self, 0, 0)
	self.BlackTexture:SetPoint("BOTTOMRIGHT", self, 0, 0)
	self.BlackTexture:SetTexture(Assets:GetTexture("Blank"))
	self.BlackTexture:SetVertexColor(0, 0, 0)

	self:SetFrameStrata("HIGH")
	self:SetSize(GUI_WIDTH, GUI_HEIGHT)
	self:SetPoint("CENTER", HydraUI.UIParent, 0, 0)
	self:SetBackdrop(HydraUI.BackdropAndBorder)
	self:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	self:SetBackdropBorderColor(0, 0, 0)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetClampedToScreen(true)
	self:SetScale(0.2)
	self:Hide()
	self:SetAlpha(0)

	self.ScaleIn = LibMotion:CreateAnimation(self, "Scale")
	self.ScaleIn:SetEasing("in")
	self.ScaleIn:SetDuration(0.2)
	self.ScaleIn:SetChange(1)

	self.FadeIn = LibMotion:CreateAnimation(self, "Fade")
	self.FadeIn:SetEasing("in")
	self.FadeIn:SetDuration(0.2)
	self.FadeIn:SetChange(1)

	self.ScaleOut = LibMotion:CreateAnimation(self, "Scale")
	self.ScaleOut:SetEasing("out")
	self.ScaleOut:SetDuration(0.2)
	self.ScaleOut:SetChange(0.2)

	self.FadeOut = LibMotion:CreateAnimation(self, "Fade")
	self.FadeOut:SetEasing("out")
	self.FadeOut:SetDuration(0.2)
	self.FadeOut:SetChange(0)
	self.FadeOut:SetScript("OnFinished", FadeOnFinished)

	self.Fader = LibMotion:CreateAnimation(self, "Fade")
	self.Fader:SetDuration(0.2)


end

local CreateHeader = function(self)
	self.Header = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Header:SetSize(HEADER_WIDTH, HEADER_HEIGHT)
	self.Header:SetPoint("TOPLEFT", self, SPACING, -SPACING)
	self.Header:SetBackdrop(HydraUI.BackdropAndBorder)
	self.Header:SetBackdropColor(0, 0, 0, 0)
	self.Header:SetBackdropBorderColor(0, 0, 0)

	self.Header.Texture = self.Header:CreateTexture(nil, "ARTWORK")
	self.Header.Texture:SetPoint("TOPLEFT", self.Header, 1, -1)
	self.Header.Texture:SetPoint("BOTTOMRIGHT", self.Header, -1, 1)
	self.Header.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.Header.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	self.Header.Text = self.Header:CreateFontString(nil, "OVERLAY")
	self.Header.Text:SetPoint("CENTER", self.Header, 0, -1)
	self.Header.Text:SetSize(HEADER_WIDTH - 6, HEADER_HEIGHT)
	HydraUI:SetFontInfo(self.Header.Text, Settings["ui-header-font"], Settings["ui-title-font-size"])
	self.Header.Text:SetJustifyH("CENTER")
	self.Header.Text:SetTextColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	self.Header.Text:SetText("Hydra|cFFEAEAEAUI|r")


end

local CreateNavigationRegion = function(self)
	-- Menu parent
	self.MenuParent = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.MenuParent:SetWidth(BUTTON_LIST_WIDTH)
	self.MenuParent:SetPoint("BOTTOMLEFT", self, SPACING, SPACING)
	self.MenuParent:SetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -2)
	self.MenuParent:SetBackdrop(HydraUI.BackdropAndBorder)
	self.MenuParent:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	self.MenuParent:SetBackdropBorderColor(0, 0, 0)
	self.SelectionViewportTarget = self.MenuParent

	-- Scroll up
	self.ScrollUp = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.ScrollUp:SetSize(16, WIDGET_HEIGHT)
	self.ScrollUp:SetPoint("TOPLEFT", self.MenuParent, "TOPRIGHT", 2, 0)
	self.ScrollUp:SetBackdrop(HydraUI.BackdropAndBorder)
	self.ScrollUp:SetBackdropColor(0, 0, 0, 0)
	self.ScrollUp:SetBackdropBorderColor(0, 0, 0)
	self.ScrollUp:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

		GUI.SelectionViewport:ScrollBy(1)
	end)

	self.ScrollUp:SetScript("OnMouseDown", function(self)
		local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

		self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
	end)

	self.ScrollUp.Texture = self.ScrollUp:CreateTexture(nil, "ARTWORK")
	self.ScrollUp.Texture:SetPoint("TOPLEFT", self.ScrollUp, 1, -1)
	self.ScrollUp.Texture:SetPoint("BOTTOMRIGHT", self.ScrollUp, -1, 1)
	self.ScrollUp.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.ScrollUp.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	self.ScrollUp.Highlight = self.ScrollUp:CreateTexture(nil, "HIGHLIGHT")
	self.ScrollUp.Highlight:SetPoint("TOPLEFT", self.ScrollUp, 1, -1)
	self.ScrollUp.Highlight:SetPoint("BOTTOMRIGHT", self.ScrollUp, -1, 1)
	self.ScrollUp.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.ScrollUp.Highlight:SetVertexColor(1, 1, 1)
	self.ScrollUp.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)

	self.ScrollUp.Arrow = self.ScrollUp:CreateTexture(nil, "OVERLAY")
	self.ScrollUp.Arrow:SetPoint("CENTER", self.ScrollUp, 0, 0)
	self.ScrollUp.Arrow:SetSize(16, 16)
	self.ScrollUp.Arrow:SetTexture(Assets:GetTexture("Arrow Up"))
	self.ScrollUp.Arrow:SetVertexColor(0.65, 0.65, 0.65)

	-- Scroll down
	self.ScrollDown = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.ScrollDown:SetSize(16, WIDGET_HEIGHT)
	self.ScrollDown:SetPoint("BOTTOMLEFT", self.MenuParent, "BOTTOMRIGHT", 2, 0)
	self.ScrollDown:SetBackdrop(HydraUI.BackdropAndBorder)
	self.ScrollDown:SetBackdropColor(0, 0, 0, 0)
	self.ScrollDown:SetBackdropBorderColor(0, 0, 0)
	self.ScrollDown:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

		GUI.SelectionViewport:ScrollBy(-1)
	end)

	self.ScrollDown:SetScript("OnMouseDown", function(self)
		local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

		self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
	end)

	self.ScrollDown.Texture = self.ScrollDown:CreateTexture(nil, "ARTWORK")
	self.ScrollDown.Texture:SetPoint("TOPLEFT", self.ScrollDown, 1, -1)
	self.ScrollDown.Texture:SetPoint("BOTTOMRIGHT", self.ScrollDown, -1, 1)
	self.ScrollDown.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.ScrollDown.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	self.ScrollDown.Highlight = self.ScrollDown:CreateTexture(nil, "HIGHLIGHT")
	self.ScrollDown.Highlight:SetPoint("TOPLEFT", self.ScrollDown, 1, -1)
	self.ScrollDown.Highlight:SetPoint("BOTTOMRIGHT", self.ScrollDown, -1, 1)
	self.ScrollDown.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.ScrollDown.Highlight:SetVertexColor(1, 1, 1)
	self.ScrollDown.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)

	self.ScrollDown.Arrow = self.ScrollDown:CreateTexture(nil, "OVERLAY")
	self.ScrollDown.Arrow:SetPoint("CENTER", self.ScrollDown, 0, 0)
	self.ScrollDown.Arrow:SetSize(16, 16)
	self.ScrollDown.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
	self.ScrollDown.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	-- Selection scrollbar
	local ScrollBar = CreateFrame("Slider", nil, self.MenuParent, "BackdropTemplate")
	ScrollBar:SetPoint("TOPLEFT", self.ScrollUp, "BOTTOMLEFT", 0, -2)
	ScrollBar:SetPoint("BOTTOMRIGHT", self.ScrollDown, "TOPRIGHT", 0, 2)
	GUI:StyleVerticalSlider(ScrollBar, {ProgressAlpha = SELECTED_HIGHLIGHT_ALPHA})
	ScrollBar:EnableMouseWheel(true)
	
	self.ScrollBar = ScrollBar
	self.SelectionViewport = GUI:CreateRowViewport(self, {
		Rows = self.ScrollButtons,
		MaxVisibleRows = MAX_WIDGETS_SHOWN,
		AnchorRows = function(Owner, Rows, First, Last)
			for i = First, Last do
				local Row, Predecessor = Rows[i], Rows[i - 1]
				local Anchor = (i == First) and Owner.MenuParent or Predecessor
				if Row.HydraScrollAnchor ~= Anchor then
					Row:ClearAllPoints()
					if i == First then Row:SetPoint("TOPLEFT", Owner.MenuParent, SPACING, -SPACING)
					else Row:SetPoint("TOP", Predecessor, "BOTTOM", 0, -2) end
					Row.HydraScrollAnchor = Anchor
				end
			end
		end,
		AfterRender = function(Owner, Offset)
			if Offset == 1 then Owner.ScrollUp.Arrow:SetVertexColor(0.65, 0.65, 0.65)
			else Owner.ScrollUp.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"])) end
			local _, Max = Owner.ScrollBar:GetMinMaxValues()
			if Offset == Max then Owner.ScrollDown.Arrow:SetVertexColor(0.65, 0.65, 0.65)
			else Owner.ScrollDown.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"])) end
		end,
	})
	self.SelectionViewport:SetScrollBar(ScrollBar)
	self.SelectionViewport:AttachMouseWheel(self.MenuParent)

end

local CreateCloseControl = function(self)
	-- Close button
	self.CloseButton = CreateFrame("Frame", nil, self)
	self.CloseButton:SetSize(HEADER_HEIGHT, HEADER_HEIGHT)
	self.CloseButton:SetPoint("RIGHT", self.Header, 0, -1)
	self.CloseButton:SetScript("OnEnter", function(self) self.Cross:SetVertexColor(HydraUI:HexToRGB("C0392B")) end)
	self.CloseButton:SetScript("OnLeave", function(self) self.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE")) end)
	self.CloseButton:SetScript("OnMouseUp", function(self)
		GUI.ScaleOut:Play()
		GUI.FadeOut:Play()

		if (GUI.ColorPicker and GUI.ColorPicker:GetAlpha() > 0) then
			GUI.ColorPicker.FadeOut:Play()
		end
	end)

	self.CloseButton.Cross = self.CloseButton:CreateTexture(nil, "OVERLAY")
	self.CloseButton.Cross:SetPoint("CENTER", self.CloseButton, 0, 0)
	self.CloseButton.Cross:SetSize(16, 16)
	self.CloseButton.Cross:SetTexture(Assets:GetTexture("Close"))
	self.CloseButton.Cross:SetVertexColor(HydraUI:HexToRGB("EEEEEE"))

end

function GUI:CreateGUI()
	CreateMainShell(self)
	CreateHeader(self)

	CreateNavigationRegion(self)
	CreateCloseControl(self)

	-- Consuming this queue from the front shifts every remaining entry on each
	-- iteration. Iterate it directly so GUI initialization remains linear as
	-- more configuration pages are registered.
	self:ValidatePages()

	for i = 1, #self.ButtonQueue do
		self:CreateWindow(self.ButtonQueue[i])
		self.ButtonQueue[i] = nil
	end

	self:SortMenuButtons()

	self.SelectionViewport:SetScrollRange(self.NumShownButtons or 0)
	self.ScrollBar:SetValue(1)
	self.SelectionViewport:SetOffset(1)
	self.ScrollBar:Show()

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:SetScript("OnEvent", self.OnEvent)

	self:ShowWindow("General", "General")

	if self.QueueAlert then
		self.QueueAlert = nil
		self:CreateUpdateAlert()
	end

	self.Loaded = true
end

