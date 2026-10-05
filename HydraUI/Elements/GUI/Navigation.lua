local HydraUI, Language, Assets, Settings = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local SPACING, WIDGET_HEIGHT, MENU_BUTTON_WIDTH = 3, 20, 120
local SELECTED_HIGHLIGHT_ALPHA, MOUSEOVER_HIGHLIGHT_ALPHA = 0.25, 0.1
local MAX_WIDGETS_SHOWN = 15
local tinsert, tsort = table.insert, table.sort
local type = type
local SortByName = function(a, b)
	return a.Name < b.Name
end

local SetArrowDirection = function(arrow, expanded)
	arrow:SetTexture(Assets:GetTexture(expanded and "Arrow Up" or "Arrow Down"))
end

function GUI:SetPageExpanded(page, expanded)
	if page.Parent or #page.Children == 0 or page.Expanded == expanded then
		return
	end

	page.Expanded = expanded
	SetArrowDirection(page.Button.Arrow, expanded)
	self.SelectionRowsDirty = true
	self:ScrollSelections()
end

function GUI:TogglePage(page)
	self:SetPageExpanded(page, not page.Expanded)
end

function GUI:SortMenuButtons()
	tsort(self.CategoryOrder, SortByName)

	self.NumShownButtons = 0

	local Categories = self.CategoryOrder

	for i = 1, #Categories do
		local Category = Categories[i]
		tsort(Category.Pages, SortByName)

		for j = 1, #Category.Pages do
			local Page = Category.Pages[j]
			tsort(Page.Children, SortByName)

			if j == 1 then
				Page.Button:SetPoint("TOPLEFT", Category.Frame, "BOTTOMLEFT", 0, -2)
			else
				Page.Button:SetPoint("TOPLEFT", Category.Pages[j-1].Button, "BOTTOMLEFT", 0, -2)
			end

			self.NumShownButtons = self.NumShownButtons + 1
		end

		if i == 1 then
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
	local Descriptor = self:GetCategoryDescriptor(name)

	if Descriptor.Frame then
		return Descriptor
	end

	local Category = CreateFrame("Frame", nil, self)
	Category:SetSize(MENU_BUTTON_WIDTH, WIDGET_HEIGHT)
	Category:SetFrameLevel(self:GetFrameLevel() + 2)
	Category.Descriptor = Descriptor

	local Text = Category:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Category, 5, 0)
	Text:SetSize(MENU_BUTTON_WIDTH - 10, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
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


function GUI:ShowWindow(category, name, parent)
	local Page = type(category) == "table" and category or self:HasButton(category, name, parent)

	if not Page then
		error(format("Unknown GUI page '%s/%s'", tostring(category), tostring(name)), 2)
	end

	local Button = Page.Button
	local PreviousPage = self.ActivePage

	if PreviousPage then
		if PreviousPage.Window then
			PreviousPage.Window:Hide()
		end

		if PreviousPage.Button.Selected:GetAlpha() > 0 then
			PreviousPage.Button.Selected:SetAlpha(0)
		end
	end

	if not Page.Window then
		Page.Window = self:CreateWidgetWindow(Page)
	end

	if Page.Parent then
		local ParentPage = Page.Parent

		if not ParentPage.Expanded then
			self:SetPageExpanded(ParentPage, true)
		end

		if ParentPage.Window then
			ParentPage.Window:Hide()
		end

		if ParentPage.Button.Selected:GetAlpha() > 0 then
			ParentPage.Button.Selected:SetAlpha(0)
		end
	elseif #Page.Children > 0 then
		self:TogglePage(Page)
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

function GUI:CreateWindow(page)
	if page.Button then
		return page
	end
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
