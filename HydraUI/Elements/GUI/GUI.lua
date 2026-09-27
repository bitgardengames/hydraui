local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

-- Constants
local SPACING = 3
local WIDGET_HEIGHT = 20
local BUTTON_LIST_WIDTH = 126 -- 112
local GUI_WIDTH = 730 -- 710
local GUI_HEIGHT = 362 -- 340
local HEADER_WIDTH = GUI_WIDTH - (SPACING * 2)
local HEADER_HEIGHT = 20
local HEADER_SPACING = 5
local PARENT_WIDTH = GUI_WIDTH - BUTTON_LIST_WIDTH - ((SPACING * 2) + 2)
local GROUP_WIDTH = ((PARENT_WIDTH / 2) - (SPACING * 4) - 8) + 1

local MENU_BUTTON_WIDTH = BUTTON_LIST_WIDTH - (SPACING * 2)
local SELECTED_HIGHLIGHT_ALPHA = 0.25
local MOUSEOVER_HIGHLIGHT_ALPHA = 0.1
local MAX_WIDGETS_SHOWN = floor(GUI_HEIGHT / (WIDGET_HEIGHT + SPACING))

-- Locals
local type = type
local tinsert = table.insert
local tsort = table.sort
local floor = math.floor
local max = math.max
local min = math.min

local Round = function(num, dec)
	local Mult = 10 ^ (dec or 0)

	return floor(num * Mult + 0.5) / Mult
end

local GUI = HydraUI:NewModule("GUI")

-- Shared scrolling primitives. Keep these independent of a particular row type so
-- widget pages, the navigation list, and dropdowns can all use the same rules.
function GUI.GetMaxRowOffset(totalRows, maxVisibleRows)
	return max((totalRows or 0) - maxVisibleRows + 1, 1)
end

function GUI.NormalizeRowOffset(offset, totalRows, maxVisibleRows)
	return min(max(Round(tonumber(offset) or 1), 1), GUI.GetMaxRowOffset(totalRows, maxVisibleRows))
end

function GUI.GetVisibleRowRange(offset, totalRows, maxVisibleRows)
	local First = GUI.NormalizeRowOffset(offset, totalRows, maxVisibleRows)

	return First, min(First + maxVisibleRows - 1, totalRows)
end

function GUI:StyleVerticalSlider(slider, options)
	options = options or {}

	slider:SetThumbTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	slider:SetOrientation("VERTICAL")
	slider:SetValueStep(1)
	slider:SetBackdrop(HydraUI.BackdropAndBorder)
	slider:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	slider:SetBackdropBorderColor(0, 0, 0)

	local Thumb = slider:GetThumbTexture()
	Thumb:SetSize(options.Width or slider:GetWidth(), WIDGET_HEIGHT)
	Thumb:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Thumb:SetVertexColor(0, 0, 0)

	slider.NewThumb = slider:CreateTexture(nil, "BORDER")
	slider.NewThumb:SetPoint("TOPLEFT", Thumb, 0, 0)
	slider.NewThumb:SetPoint("BOTTOMRIGHT", Thumb, 0, 0)
	slider.NewThumb:SetTexture(Assets:GetTexture("Blank"))
	slider.NewThumb:SetVertexColor(0, 0, 0)

	slider.NewThumb2 = slider:CreateTexture(nil, "OVERLAY")
	slider.NewThumb2:SetPoint("TOPLEFT", slider.NewThumb, 1, -1)
	slider.NewThumb2:SetPoint("BOTTOMRIGHT", slider.NewThumb, -1, 1)
	slider.NewThumb2:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	slider.NewThumb2:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	if options.Highlight then
		slider.Highlight = slider:CreateTexture(nil, "HIGHLIGHT")
		slider.Highlight:SetPoint("TOPLEFT", slider.NewThumb, 1, -1)
		slider.Highlight:SetPoint("BOTTOMRIGHT", slider.NewThumb, -1, 1)
		slider.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		slider.Highlight:SetVertexColor(1, 1, 1)
		slider.Highlight:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)
	end

	slider.Progress = slider:CreateTexture(nil, "ARTWORK")
	slider.Progress:SetPoint("TOPLEFT", slider, 1, -1)
	slider.Progress:SetPoint("BOTTOMRIGHT", slider.NewThumb, "TOPRIGHT", -1, 0)
	slider.Progress:SetTexture(Assets:GetTexture(options.ProgressTexture or "Blank"))
	slider.Progress:SetVertexColor(HydraUI:HexToRGB(Settings[options.ProgressColor or "ui-widget-bright-color"]))
	if options.ProgressAlpha then slider.Progress:SetAlpha(options.ProgressAlpha) end
end

local RowViewport = {}
RowViewport.__index = RowViewport

function RowViewport:GetRows()
	return type(self.Rows) == "function" and self.Rows(self.Owner) or self.Rows
end

function RowViewport:GetTotalRows()
	local Rows = self:GetRows()
	return type(self.TotalRows) == "function" and self.TotalRows(self.Owner, Rows) or (self.TotalRows or #Rows)
end

function RowViewport:SyncScrollBar()
	if self.ScrollBar and (self.ScrollBar:GetValue() ~= self.Offset) then
		self.Synchronizing = true
		self.Owner.UpdatingScrollBar = true -- compatibility for external handlers
		self.ScrollBar:SetValue(self.Offset)
		self.Owner.UpdatingScrollBar = false
		self.Synchronizing = false
	end
end

function RowViewport:SetScrollBar(scrollBar)
	self.ScrollBar = scrollBar
	self.Owner.ScrollBar = scrollBar
	self:SyncScrollBar()
end

function RowViewport:SetScrollRange(totalRows)
	if not self.ScrollBar then return end
	self.Synchronizing = true
	self.Owner.UpdatingScrollBar = true
	self.ScrollBar:SetMinMaxValues(1, GUI.GetMaxRowOffset(totalRows, self.MaxVisibleRows))
	self.Owner.UpdatingScrollBar = false
	self.Synchronizing = false
end

function RowViewport:Render(rowsChanged)
	local Rows = self:GetRows()
	local Count = self:GetTotalRows()
	local First, Last = GUI.GetVisibleRowRange(self.Offset, Count, self.MaxVisibleRows)
	local OldRows, OldFirst = self.LastRenderedRows, self.LastRenderedOffset
	local OldLast = OldRows and OldFirst and min(OldFirst + self.MaxVisibleRows - 1, #OldRows)

	self.Offset = First
	self.Owner.Offset = First
	self:SyncScrollBar()

	if (not rowsChanged) and (OldRows == Rows) and (OldFirst == First) then return end

	if self.UpdateRows then
		self.UpdateRows(self.Owner, Rows, OldRows, OldFirst, OldLast, First, Last, rowsChanged)
	else
		if OldRows and OldFirst then
			for i = OldFirst, OldLast do
				if rowsChanged or (i < First) or (i > Last) then OldRows[i]:Hide() end
			end
		else
			for i = 1, First - 1 do Rows[i]:Hide() end
			for i = Last + 1, Count do Rows[i]:Hide() end
		end

		for i = First, Last do
			if rowsChanged or (not OldFirst) or (i < OldFirst) or (i > OldLast) then Rows[i]:Show() end
		end
	end

	if self.AnchorRows then self.AnchorRows(self.Owner, Rows, First, Last) end
	self.LastRenderedRows = Rows
	self.LastRenderedOffset = First
	self.Owner.LastRenderedOffset = First
	if self.AfterRender then self.AfterRender(self.Owner, First, Last) end
end

function RowViewport:SetOffset(offset, rowsChanged)
	self.Offset = GUI.NormalizeRowOffset(offset, self:GetTotalRows(), self.MaxVisibleRows)
	self.Owner.Offset = self.Offset
	self:Render(rowsChanged)
end

function RowViewport:SetOffsetByDelta(delta)
	self.Offset = GUI.NormalizeRowOffset(self.Offset + (delta == 1 and -1 or 1), self:GetTotalRows(), self.MaxVisibleRows)
	self.Owner.Offset = self.Offset
end

function GUI:CreateRowViewport(owner, options)
	local Viewport = setmetatable({
		Owner = owner,
		Rows = options.Rows,
		TotalRows = options.TotalRows,
		MaxVisibleRows = options.MaxVisibleRows,
		AnchorRows = options.AnchorRows,
		UpdateRows = options.UpdateRows,
		AfterRender = options.AfterRender,
		Offset = GUI.NormalizeRowOffset(options.Offset or owner.Offset, 0, options.MaxVisibleRows),
	}, RowViewport)

	owner.RowViewport = Viewport
	return Viewport
end

local GetMaxOffset = function(totalRows)
	return GUI.GetMaxRowOffset(totalRows, MAX_WIDGETS_SHOWN)
end

-- Storage
GUI.CategoryOrder = {}
GUI.Categories = {}
GUI.Pages = {}
GUI.Widgets = {}
GUI.WidgetID = {}
GUI.ButtonQueue = {}
GUI.ScrollButtons = {}

local GetCategory = function(self, name)
	local Category = self.Categories[name]

	if (not Category) then
		Category = {Name = name, Pages = {}, PageLookup = {}}
		self.Categories[name] = Category
		tinsert(self.CategoryOrder, Category)
		self.Pages[name] = Category.PageLookup
	end

	return Category
end

local NewPage = function(category, name)
	return {
		Category = category,
		Name = name,
		Parent = nil,
		Children = {},
		ChildLookup = {},
		Callbacks = {},
		Expanded = false,
		Button = nil,
		Window = nil,
	}
end

local GetOrCreatePage = function(self, categoryName, name, parentName)
	local Category = GetCategory(self, categoryName)
	local Page = Category.PageLookup[name]
	local ParentPage

	if parentName then
		if (name == parentName) then
			error(format("GUI page '%s/%s' cannot be its own parent", categoryName, name), 3)
		end

		ParentPage = Category.PageLookup[parentName]

		if (not ParentPage) then
			ParentPage = NewPage(Category, parentName)
			Category.PageLookup[parentName] = ParentPage
			tinsert(Category.Pages, ParentPage)
		end
	end

	if Page then
		if (Page.Parent ~= ParentPage) then
			error(format("Duplicate GUI page identity '%s/%s' registered with different parents", categoryName, name), 3)
		end
	else
		Page = NewPage(Category, name)
		Page.Parent = ParentPage
		Category.PageLookup[name] = Page

		if ParentPage then
			ParentPage.ChildLookup[name] = Page
			tinsert(ParentPage.Children, Page)
		else
			tinsert(Category.Pages, Page)
		end
	end

	Page.Defined = true

	return Page
end

local QueuePage = function(self, page)
	if page.Queued then
		return
	end

	page.Queued = true
	tinsert(self.ButtonQueue, page)
end

local ValidatePages = function(self)
	for i = 1, #self.CategoryOrder do
		local Category = self.CategoryOrder[i]

		for _, Page in next, Category.PageLookup do
			if (not Page.Defined) then
				error(format("GUI category '%s' references missing parent page '%s'", Category.Name, Page.Name), 3)
			elseif Page.Parent and Page.Parent.Parent then
				error(format("GUI page '%s/%s' has nested parent '%s'; only one child level is supported", Category.Name, Page.Name, Page.Parent.Name), 3)
			end
		end
	end
end

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

local Scroll = function(self)
	self.RowViewport:SetOffset(self.Offset)
end

local NoScroll = function() end

local SetOffsetByDelta = function(self, delta)
	self.RowViewport:SetOffsetByDelta(delta)
end

local WindowOnMouseWheel = function(self, delta)
	SetOffsetByDelta(self, delta)

	if (self.ScrollBar:GetValue() ~= self.Offset) then
		self.ScrollBar:SetValue(self.Offset)
	elseif (self.LastRenderedOffset ~= self.Offset) then
		Scroll(self)
	end
end

local SetWindowOffset = function(self, offset)
	self.RowViewport:SetOffset(offset)
end

local WindowScrollBarOnValueChanged = function(self)
	local Parent = self:GetParent()

	if not Parent.RowViewport.Synchronizing then Parent.RowViewport:SetOffset(self:GetValue()) end
end

local WindowScrollBarOnMouseWheel = function(self, delta)
	WindowOnMouseWheel(self:GetParent(), delta)
end

local WindowScrollBarOnMouseUp = function(self)
	self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	WindowOnMouseWheel(self:GetParent(), 1)
end

local WindowScrollBarOnMouseDown = function(self)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

	self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
end

local AddWindowScrollBar = function(self)
	-- Scroll up
	self.ScrollUp = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.ScrollUp:SetSize(16, WIDGET_HEIGHT)
	self.ScrollUp:SetPoint("TOPRIGHT", GUI, -SPACING, -((SPACING * 2) + HEADER_HEIGHT - 1))
	self.ScrollUp:SetBackdrop(HydraUI.BackdropAndBorder)
	self.ScrollUp:SetBackdropColor(0, 0, 0, 0)
	self.ScrollUp:SetBackdropBorderColor(0, 0, 0)
	self.ScrollUp:SetScript("OnMouseUp", WindowScrollBarOnMouseUp)
	self.ScrollUp:SetScript("OnMouseDown", WindowScrollBarOnMouseDown)

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

		WindowOnMouseWheel(self:GetParent(), -1)
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
	ScrollBar:EnableMouseWheel(true)
	ScrollBar:SetScript("OnMouseWheel", WindowScrollBarOnMouseWheel)
	ScrollBar:SetScript("OnValueChanged", WindowScrollBarOnValueChanged)

	ScrollBar.Window = self

	self:EnableMouseWheel(true)
	self:SetScript("OnMouseWheel", WindowOnMouseWheel)

	self.ScrollBar = ScrollBar
	self.RowViewport:SetScrollBar(ScrollBar)

	ScrollBar:Show()
end

function GUI:SortMenuButtons()
	tsort(self.CategoryOrder, function(a, b)
		return a.Name < b.Name
	end)

	self.NumShownButtons = 0

	local Categories = self.CategoryOrder

	for i = 1, #Categories do
		local Category = Categories[i]
		tsort(Category.Pages, function(a, b)
			return a.Name < b.Name
		end)

		for j = 1, #Category.Pages do
			local Page = Category.Pages[j]
			tsort(Page.Children, function(a, b) return a.Name < b.Name end)

			if (j == 1) then
				Page.Button:SetPoint("TOPLEFT", Category.Frame, "BOTTOMLEFT", 0, -2)
			else
				Page.Button:SetPoint("TOPLEFT", Category.Pages[j-1].Button, "BOTTOMLEFT", 0, -2)
			end

			self.NumShownButtons = self.NumShownButtons + 1
		end

		if (i == 1) then
			Category.Frame:SetPoint("TOPLEFT", self.MenuParent, "TOPLEFT", SPACING, -SPACING)
		elseif #Categories[i-1].Pages > 0 then
			Category.Frame:SetPoint("TOPLEFT", Categories[i-1].Pages[#Categories[i-1].Pages].Button, "BOTTOMLEFT", 0, -2)
		else
			Category.Frame:SetPoint("TOPLEFT", Categories[i-1].Frame, "BOTTOMLEFT", 0, -2)
		end

		self.NumShownButtons = self.NumShownButtons + 1
	end

	self.SelectionRowsDirty = true
end

function GUI:CreateCategory(name)
	local Descriptor = GetCategory(self, name)

	if Descriptor.Frame then
		return Descriptor
	end

	local Category = CreateFrame("Frame", nil, self)
	Category:SetSize(MENU_BUTTON_WIDTH, WIDGET_HEIGHT)
	Category:SetFrameLevel(self:GetFrameLevel() + 2)

	local Text = Category:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("CENTER", Category, 0, 0)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("CENTER")
	Text:SetText(format("|cFF%s%s|r", Settings["ui-header-font-color"], name))

	local BG = Category:CreateTexture(nil, "BORDER")
	BG:SetAllPoints()
	BG:SetColorTexture(0, 0, 0)

	local Texture = Category:CreateTexture(nil, "OVERLAY")
	Texture:SetPoint("TOPLEFT", Category, 1, -1)
	Texture:SetPoint("BOTTOMRIGHT", Category, -1, 1)
	Texture:SetTexture(Assets:GetTexture("Blank"))
	Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-header-texture-color"]))

	Category.Text = Text
	Category.Texture = Texture
	Descriptor.Frame = Category

	self.TotalSelections = (self.TotalSelections or 0) + 1

	self.SelectionRowsDirty = true

	return Descriptor
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
		UpdateRows = function(Owner, Rows, OldRows, OldFirst, OldLast, First)
			local LeftOffset = Owner.LeftWidgetsBG.ScrollingDisabled and 1 or First
			local RightOffset = Owner.RightWidgetsBG.ScrollingDisabled and 1 or First

			ScrollWidgetColumn(Owner.LeftWidgetsBG, Owner.LeftWidgets, Owner.LastRenderedLeftOffset, LeftOffset, "TOPLEFT")
			ScrollWidgetColumn(Owner.RightWidgetsBG, Owner.RightWidgets, Owner.LastRenderedRightOffset, RightOffset, "TOPRIGHT")
			Owner.LastRenderedLeftOffset = LeftOffset
			Owner.LastRenderedRightOffset = RightOffset
		end,
		AfterRender = function(Owner, Offset)
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
		end,
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

	SetWindowOffset(Window, 1)

	return Window
end

function GUI:ShowWindow(category, name, parent)
	local Page = type(category) == "table" and category or self:HasButton(category, name, parent)

	if (not Page) then
		error(format("Unknown GUI page '%s/%s'", tostring(category), tostring(name)), 2)
	end

	local Button = Page.Button
	local PreviousPage = self.ActivePage

	if PreviousPage then
		if PreviousPage.Window then
			PreviousPage.Window:Hide()
		end

		if (PreviousPage.Button.Selected:GetAlpha() > 0) then
			PreviousPage.Button.Selected:SetAlpha(0)
		end
	end

	if (not Page.Window) then
		Page.Window = self:CreateWidgetWindow(Page)
	end

	if Page.Parent then
		local ParentPage = Page.Parent

		if ParentPage.Window then
			ParentPage.Window:Hide()
		end

		if (ParentPage.Button.Selected:GetAlpha() > 0) then
			ParentPage.Button.Selected:SetAlpha(0)
		end
	elseif #Page.Children > 0 then
		Page.Expanded = not Page.Expanded
		Button.Arrow:SetTexture(Assets:GetTexture(Page.Expanded and "Arrow Up" or "Arrow Down"))

		for i = 1, #Page.Children do
			local ChildPage = Page.Children[i]
			local ChildButton = ChildPage.Button

			if ChildPage.Window then
				ChildPage.Window:Hide()

				if (ChildButton.Selected:GetAlpha() > 0) then
					ChildButton.Selected:SetAlpha(0)
				end
			end

			ChildButton:Hide()
		end

		self.SelectionRowsDirty = true
	end

	Button.Selected:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)
	Page.Window:Show()
	self.ActivePage = Page

	self:ScrollSelections()

	--CloseLastDropdown()
end

local WindowButtonOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local WindowButtonOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local WindowButtonOnMouseUp = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, 4, 0)

	GUI:ShowWindow(self.Page)
end

local WindowButtonOnMouseDown = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, 6, -1)
end

local WindowSubButtonOnMouseUp = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, SPACING * 3, 0)

	GUI:ShowWindow(self.Page)
end

local WindowSubButtonOnMouseDown = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, (SPACING * 3) + 2, -1)
end

function GUI:HasButton(category, name, parent)
	local Category = self.Categories[category]
	local Page = Category and Category.PageLookup[name]

	if Page and ((not parent and not Page.Parent) or (Page.Parent and Page.Parent.Name == parent)) then
		return Page
	end
end

function GUI:CreateWindow(page)
	if page.Button then return page end
	if page.Parent and (not page.Parent.Defined) then
		error(format("GUI page '%s/%s' references missing parent '%s'", page.Category.Name, page.Name, page.Parent.Name), 2)
	end

	local Category = self:CreateCategory(page.Category.Name)

	local Button = CreateFrame("Frame", nil, self)
	Button:SetSize(MENU_BUTTON_WIDTH, WIDGET_HEIGHT)
	Button:SetFrameLevel(self:GetFrameLevel() + 2)
	Button.Page = page
	Button:SetScript("OnEnter", WindowButtonOnEnter)
	Button:SetScript("OnLeave", WindowButtonOnLeave)

	Button.Selected = Button:CreateTexture(nil, "ARTWORK")
	Button.Selected:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Selected:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Selected:SetTexture(Assets:GetTexture("Blank"))
	Button.Selected:SetAlpha(0)

	Button.Highlight = Button:CreateTexture(nil, "ARTWORK")
	Button.Highlight:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Highlight:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Button.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Button.Highlight:SetAlpha(0)

	Button.Text = Button:CreateFontString(nil, "OVERLAY")
	Button.Text:SetSize(MENU_BUTTON_WIDTH - 6, WIDGET_HEIGHT)
	Button.Text:SetJustifyH("LEFT")

	if page.Parent then
		Button:SetScript("OnMouseUp", WindowSubButtonOnMouseUp)
		Button:SetScript("OnMouseDown", WindowSubButtonOnMouseDown)

		Button.Selected:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

		Button.Text:SetPoint("LEFT", Button, SPACING * 3, 0)
		HydraUI:SetFontInfo(Button.Text, Settings["ui-widget-font"], 12)
		Button.Text:SetText("|cFF" .. Settings["ui-widget-font-color"] .. page.Name .. "|r")
	else
		Button:SetScript("OnMouseUp", WindowButtonOnMouseUp)
		Button:SetScript("OnMouseDown", WindowButtonOnMouseDown)

		Button.Selected:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

		Button.Text:SetPoint("LEFT", Button, 4, 0)
		HydraUI:SetFontInfo(Button.Text, Settings["ui-widget-font"], Settings["ui-header-font-size"])
		Button.Text:SetText("|cFF" .. Settings["ui-button-font-color"] .. page.Name .. "|r")

		self.TotalSelections = (self.TotalSelections or 0) + 1
	end

	page.Button = Button

	if (not page.Parent) and (#page.Children > 0) then
		Button.Arrow = Button:CreateTexture(nil, "OVERLAY")
		Button.Arrow:SetPoint("RIGHT", Button, -3, -1)
		Button.Arrow:SetSize(16, 16)
		Button.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
		Button.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	end

	self.SelectionRowsDirty = true
	return page
end

function GUI:AddWidgets(category, name, arg1, arg2)
	if (type(arg1) == "function") then
		local Page = GetOrCreatePage(self, category, name)

		tinsert(Page.Callbacks, arg1)
		QueuePage(self, Page)
	else -- string
		local Page = GetOrCreatePage(self, category, name, arg1)

		tinsert(Page.Callbacks, arg2)
		QueuePage(self, Page)
	end
end

function GUI:GetWidget(id)
	if self.WidgetID[id] then
		return self.WidgetID[id]
	end
end

function GUI:ScrollSelections()
	local RowsChanged = self.SelectionRowsDirty

	if RowsChanged then
		local Rows = {}
		local Categories = self.CategoryOrder

		for i = 1, #Categories do
			local Category = Categories[i]
			tinsert(Rows, Category.Frame)

			for j = 1, #Category.Pages do
				local Page = Category.Pages[j]

				tinsert(Rows, Page.Button)

				if Page.Expanded then
					for o = 1, #Page.Children do
						tinsert(Rows, Page.Children[o].Button)
					end
				end
			end
		end

		self.ScrollButtons = Rows
		self.TotalSelections = #Rows
		self.SelectionRowsDirty = false
	end

	if RowsChanged then
		self.SelectionViewport:SetScrollRange(#self.ScrollButtons)
	end

	self.SelectionViewport.Rows = self.ScrollButtons
	self.SelectionViewport.TotalRows = #self.ScrollButtons
	self.SelectionViewport:SetOffset(self.Offset, RowsChanged)
	self.LastRenderedSelectionOffset = self.SelectionViewport.LastRenderedOffset
end

function GUI:SetSelectionOffset(offset)
	self.Offset = GUI.NormalizeRowOffset(offset, self.TotalSelections or #self.ScrollButtons, MAX_WIDGETS_SHOWN)
	self:ScrollSelections()
end

function GUI:SetSelectionOffsetByDelta(delta)
	self.SelectionViewport:SetOffsetByDelta(delta)
end

local SelectionOnMouseWheel = function(self, delta)
	self:SetSelectionOffsetByDelta(delta)

	if (self.ScrollBar:GetValue() ~= self.Offset) then
		self.ScrollBar:SetValue(self.Offset)
	elseif self.SelectionRowsDirty or (self.LastRenderedSelectionOffset ~= self.Offset) then
		self:ScrollSelections()
	end
end

local SelectionScrollBarOnValueChanged = function(self)
	if not GUI.SelectionViewport.Synchronizing then GUI:SetSelectionOffset(self:GetValue()) end
end

local MenuParentOnMouseWheel = function(self, delta)
	SelectionOnMouseWheel(self:GetParent(), delta)
end

local SelectionScrollBarOnMouseWheel = function(self, delta)
	SelectionOnMouseWheel(self:GetParent():GetParent(), delta)
end

local FadeOnFinished = function(self)
	self.Parent:Hide()
end

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

function GUI:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function GUI:CreateGUI()
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

	-- Header
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

	-- Menu parent
	self.MenuParent = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.MenuParent:SetWidth(BUTTON_LIST_WIDTH)
	self.MenuParent:SetPoint("BOTTOMLEFT", self, SPACING, SPACING)
	self.MenuParent:SetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -2)
	self.MenuParent:SetBackdrop(HydraUI.BackdropAndBorder)
	self.MenuParent:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	self.MenuParent:SetBackdropBorderColor(0, 0, 0)
	self.MenuParent:SetScript("OnMouseWheel", MenuParentOnMouseWheel)

	-- Scroll up
	self.ScrollUp = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.ScrollUp:SetSize(16, WIDGET_HEIGHT)
	self.ScrollUp:SetPoint("TOPLEFT", self.MenuParent, "TOPRIGHT", 2, 0)
	self.ScrollUp:SetBackdrop(HydraUI.BackdropAndBorder)
	self.ScrollUp:SetBackdropColor(0, 0, 0, 0)
	self.ScrollUp:SetBackdropBorderColor(0, 0, 0)
	self.ScrollUp:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

		SelectionOnMouseWheel(self:GetParent(), 1)
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

		SelectionOnMouseWheel(self:GetParent(), -1)
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
	ScrollBar:SetScript("OnMouseWheel", SelectionScrollBarOnMouseWheel)
	ScrollBar:SetScript("OnValueChanged", SelectionScrollBarOnValueChanged)

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

	-- Consuming this queue from the front shifts every remaining entry on each
	-- iteration. Iterate it directly so GUI initialization remains linear as
	-- more configuration pages are registered.
	ValidatePages(self)

	for i = 1, #self.ButtonQueue do
		self:CreateWindow(self.ButtonQueue[i])
		self.ButtonQueue[i] = nil
	end

	self:SortMenuButtons()

	self.SelectionViewport:SetScrollRange(self.NumShownButtons or 0)
	self.ScrollBar:SetValue(1)
	self:SetSelectionOffset(1)
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

function GUI:Toggle()
	if (not self.Loaded) then
		self:CreateGUI()
	end

	if self:IsShown() then
		self.FadeOut:Play()
		self.ScaleOut:Play()
		self:UnregisterEvent("MODIFIER_STATE_CHANGED")

		if Settings["gui-enable-fade"] then
			self:UnregisterEvent("PLAYER_STARTED_MOVING")
			self:UnregisterEvent("PLAYER_STOPPED_MOVING")
		end
	else
		if (Settings["gui-hide-in-combat"] and InCombatLockdown()) then
			HydraUI:print(ERR_NOT_IN_COMBAT)

			return
		end

		if Settings["gui-enable-fade"] then
			self:RegisterEvent("PLAYER_STARTED_MOVING")
			self:RegisterEvent("PLAYER_STOPPED_MOVING")
		end

		if (not self.FirstToggle) then
			C_Timer.After(0.2, function()
				self:Show()
				self.FadeIn:Play()
				self.ScaleIn:Play()
			end)

			self.FirstToggle = true
		else
			self:Show()
			self.FadeIn:Play()
			self.ScaleIn:Play()
		end

		self:RegisterEvent("MODIFIER_STATE_CHANGED")
	end
end

function GUI:PLAYER_REGEN_DISABLED()
	if (Settings["gui-hide-in-combat"] and self:IsVisible()) then
		self:SetAlpha(0)
		self:Hide()
		--CloseLastDropdown()
		self.WasCombatClosed = true
	end
end

local ReopenWindow = function()
	GUI:SetAlpha(0)
	GUI:Show()
	GUI.ScaleIn:Play()
	GUI.FadeIn:Play()
end

function GUI:PLAYER_REGEN_ENABLED()
	if (Settings["gui-hide-in-combat"] and self.WasCombatClosed) then
		HydraUI:DisplayPopup(Language["Attention"], Language["The settings window was automatically closed due to combat. Would you like to open it again?"], ACCEPT, ReopenWindow, CANCEL)
	end

	self.WasCombatClosed = false
end

-- Enabling the mouse wheel will stop the scrolling if we pass over a widget, but I really want mousewheeling
function GUI:MODIFIER_STATE_CHANGED(key, state)
	if GetMouseFocus then
		local MouseFocus = GetMouseFocus()

		if (not MouseFocus) then
			return
		end

		if (MouseFocus.OnMouseWheel and state == 1) then
			MouseFocus:SetScript("OnMouseWheel", MouseFocus.OnMouseWheel)
		elseif (MouseFocus.HasScript and MouseFocus:HasScript("OnMouseWheel")) then
			MouseFocus:SetScript("OnMouseWheel", nil)
		end
	elseif GetMouseFoci then
		local MouseFocus = GetMouseFoci()

		if (not MouseFocus) then
			return
		end

		MouseFocus = MouseFocus[1]

		if (not MouseFocus) then
			return
		end

		if (MouseFocus.OnMouseWheel and state == 1) then
			MouseFocus:SetScript("OnMouseWheel", MouseFocus.OnMouseWheel)
		elseif (MouseFocus.HasScript and MouseFocus:HasScript("OnMouseWheel")) then
			MouseFocus:SetScript("OnMouseWheel", nil)
		end
	end
end

function GUI:PLAYER_STARTED_MOVING()
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	self.Fader:SetEasing("out")
	self.Fader:SetChange(Settings["gui-faded-alpha"] / 100)
	self.Fader:Play()
end

function GUI:PLAYER_STOPPED_MOVING()
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	self.Fader:SetEasing("in")
	self.Fader:SetChange(1)
	self.Fader:Play()
end
