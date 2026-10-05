local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")
local Core = GUI.WidgetCore
local SPACING, HEADER_HEIGHT, HEADER_SPACING = Core.SPACING, Core.HEADER_HEIGHT, Core.HEADER_SPACING
local GROUP_HEIGHT, GROUP_WIDTH, WIDGET_HEIGHT = Core.GROUP_HEIGHT, Core.GROUP_WIDTH, Core.WIDGET_HEIGHT
local LABEL_SPACING = Core.LABEL_SPACING
local SELECTED_HIGHLIGHT_ALPHA, MOUSEOVER_HIGHLIGHT_ALPHA = Core.SELECTED_HIGHLIGHT_ALPHA, Core.MOUSEOVER_HIGHLIGHT_ALPHA
local RegisterWidget, CommitValue = Core.RegisterWidget, Core.CommitValue
local Round, TrimHex = Core.Round, Core.TrimHex
local AnchorOnEnter, AnchorOnLeave, FadeOnFinished = Core.AnchorOnEnter, Core.AnchorOnLeave, Core.FadeOnFinished
local type, next, tonumber = type, next, tonumber
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local match, upper, lower, sub, gsub, find = string.match, string.upper, string.lower, string.sub, string.gsub, string.find
local floor, max, min = math.floor, math.max, math.min
local InCombatLockdown, IsModifierKeyDown = InCombatLockdown, IsModifierKeyDown

local Controller = Core.Controllers.Dropdown

-- Dropdown
local DROPDOWN_WIDTH = 130
local DROPDOWN_HEIGHT = 20
local DROPDOWN_FADE_DELAY = 3 -- To be implemented
local DROPDOWN_MAX_SHOWN = 8

local CloseLastDropdown = function(compare)
	if Controller.Active and Controller.Active.Menu:IsShown() and (Controller.Active ~= compare) then
		if not Controller.Active.Menu.FadeOut:IsPlaying() then
			Controller.Active.Menu.FadeOut:Play()
			Controller.Active.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
		end
	end
end

local InitializeDropdown

local GetDropdownSelectionValue = function(self, MenuItem)
	if self.SpecificType then
		return MenuItem.Key
	end

	return MenuItem.Value
end

local SynchronizeDropdownSelection = function(self)
	local Menu = self.Menu

	if self.Value == Menu.SynchronizedValue then
		return
	end

	if Menu.SelectedItem then
		Menu.SelectedItem.Selected:Hide()
		Menu.SelectedItem = nil
	end

	for i = 1, #Menu do
		local MenuItem = Menu[i]

		if GetDropdownSelectionValue(self, MenuItem) == self.Value then
			MenuItem.Selected:Show()
			Menu.SelectedItem = MenuItem
			break
		end
	end

	Menu.SynchronizedValue = self.Value
end

local DropdownButtonOnMouseUp = function(self)
	InitializeDropdown(self.Parent)

	self.Parent.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	self.Parent.Current:ClearAllPoints()
	self.Parent.Current:SetPoint("LEFT", self.Parent, HEADER_SPACING, 0)

	if self.Menu:IsVisible() then
		self.Menu.FadeOut:Play()
		self.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
	else
		SynchronizeDropdownSelection(self.Parent)

		CloseLastDropdown(self)
		self.Menu:Show()
		self.Menu.FadeIn:Play()
		self.Arrow:SetTexture(Assets:GetTexture("Arrow Up"))
	end

	Controller.Active = self
end

local DropdownButtonOnMouseDown = function(self)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

	self.Parent.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)

	self.Parent.Current:ClearAllPoints()
	self.Parent.Current:SetPoint("LEFT", self.Parent, HEADER_SPACING + 1, -1)
end

local MenuItemOnMouseUp = function(self)
	local Dropdown = self.GrandParent
	local Value = GetDropdownSelectionValue(Dropdown, self)

	self.Parent.FadeOut:Play()
	Dropdown.Button.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))

	if self.Parent.SelectedItem and self.Parent.SelectedItem ~= self then
		self.Parent.SelectedItem.Selected:Hide()
	end

	self.Selected:Show()
	self.Parent.SelectedItem = self
	self.Parent.SynchronizedValue = Value

	self.Highlight:SetAlpha(0)
	self.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	Dropdown.Value = Value
	CommitValue(Dropdown, Value)

	if Dropdown.SpecificType == "Texture" then
		Dropdown.Texture:SetTexture(Assets:GetTexture(self.Key))
	elseif Dropdown.SpecificType == "Font" then
		HydraUI:SetFontInfo(Dropdown.Current, self.Key, Settings["ui-font-size"])
	end

	Dropdown.Current:SetText(self.Key)
end

local MenuItemOnMouseDown = function(self)
	local R, G, B = HydraUI:HexToRGB(Settings["ui-widget-bright-color"])

	self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
end

local DropdownUpdateList

local DropdownOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local DropdownOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local MenuItemOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local MenuItemOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local DropdownEnable = function(self)
	self.Dropdown.Button:EnableMouse(true)

	self.Dropdown.Current:SetTextColor(HydraUI:HexToRGB("FFFFFF"))

	self.Dropdown.Button.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
end

local DropdownDisable = function(self)
	self.Dropdown.Button:EnableMouse(false)

	self.Dropdown.Current:SetTextColor(HydraUI:HexToRGB("A5A5A5"))

	self.Dropdown.Button.Arrow:SetVertexColor(HydraUI:HexToRGB("A5A5A5"))
end

local NormalizeDropdownOffset = function(self, offset)
	return Core.NormalizeDropdownOffset(offset, #self, DROPDOWN_MAX_SHOWN)
end

local AnchorDropdownRows = function(self, first, last)
	local Previous

	for i = first, last do
		local Row = self[i]

		Row:ClearAllPoints()

		if Previous then
			Row:SetPoint("TOPLEFT", Previous, "BOTTOMLEFT", 0, 1)
		else
			Row:SetPoint("TOPLEFT", self, 0, 0)
		end

		Previous = Row
	end
end

local DropdownOnMouseWheel = function(self, delta)
	self.RowViewport:ScrollBy(delta)
	self.LastRenderedOffset = self.RowViewport.LastRenderedOffset
end

local AddDropdownScrollBar = function(self)
	local ScrollWidth = (WIDGET_HEIGHT / 2)

	local ScrollBar = CreateFrame("Slider", nil, self, "BackdropTemplate")
	ScrollBar:SetPoint("TOPRIGHT", self, 0, 0)
	ScrollBar:SetPoint("BOTTOMRIGHT", self, 0, 0)
	ScrollBar:SetWidth(ScrollWidth)
	GUI:StyleVerticalSlider(ScrollBar, {Width = ScrollWidth, ProgressTexture = Settings["ui-widget-texture"], ProgressColor = "ui-widget-color"})
	ScrollBar:SetMinMaxValues(1, (#self - (DROPDOWN_MAX_SHOWN - 1)))
	ScrollBar:SetValue(1)

	self:EnableMouseWheel(true)
	self:SetScript("OnMouseWheel", DropdownOnMouseWheel)

	self.ScrollBar = ScrollBar
	local Viewport = GUI:CreateRowViewport(self, {
		Rows = self,
		MaxVisibleRows = DROPDOWN_MAX_SHOWN,
		AnchorRows = function(Owner, Rows, First, Last) AnchorDropdownRows(Owner, First, Last) end,
		UpdateRows = function(Owner, Rows, OldRows, OldOffset, OldLast, Offset, Last)
			-- Preserve the cheap single hide/show operation for one-row wheel movement.
			if not OldOffset then
				for i = Offset, Last do
					Rows[i]:Show()
				end
				for i = Last + 1, #Rows do
					Rows[i]:Hide()
				end
			elseif Offset == OldOffset + 1 then
				Rows[OldOffset]:Hide()
				Rows[Last]:Show()
			elseif Offset == OldOffset - 1 then
				Rows[OldLast]:Hide()
				Rows[Offset]:Show()
			else
				for i = OldOffset, OldLast do
					if (i < Offset) or (i > Last) then
						Rows[i]:Hide()
					end
				end
				for i = Offset, Last do
					Rows[i]:Show()
				end
			end
		end,
	})
	Viewport:SetScrollBar(ScrollBar)

	Viewport:SetOffset(1)

	ScrollBar:Show()

	for i = 1, #self do
		self[i]:SetWidth((DROPDOWN_WIDTH - ScrollWidth) - (SPACING * 3) + 1)
	end

	self:SetWidth((DROPDOWN_WIDTH - ScrollWidth) - (SPACING * 3) + 1)
	self:SetHeight(((WIDGET_HEIGHT - 1) * DROPDOWN_MAX_SHOWN) + 1)
end

DropdownUpdateList = function(self)
	if not self.Menu.Initialized then
		return
	end

	local Menu = self.Menu
	local Count = #Menu
	local IsScrolling = Count > DROPDOWN_MAX_SHOWN
	local ItemWidth = DROPDOWN_WIDTH - (SPACING * 2)

	tsort(Menu, function(a, b)
		return TrimHex(a.Key) < TrimHex(b.Key)
	end)

	-- Rows may have anchors to their former neighbours after a dynamic update.
	for i = 1, Count do
		Menu[i]:ClearAllPoints()
	end

	if IsScrolling then
		if not Menu.ScrollBar then
			AddDropdownScrollBar(Menu)
		end

		ItemWidth = (DROPDOWN_WIDTH - (WIDGET_HEIGHT / 2)) - (SPACING * 3) + 1
		Menu.RowViewport:SetScrollRange(Count)
		Menu.ScrollBar:EnableMouse(true)
		Menu.ScrollBar:Show()
		Menu:EnableMouseWheel(true)
		Menu:SetScript("OnMouseWheel", DropdownOnMouseWheel)
		Menu:SetHeight(((WIDGET_HEIGHT - 1) * DROPDOWN_MAX_SHOWN) + 1)
	else
		if Menu.ScrollBar then
			Menu.ScrollBar:Hide()
			Menu.ScrollBar:EnableMouse(false)
			Menu.RowViewport:SetScrollRange(Count)
		end

		Menu:EnableMouseWheel(false)
		Menu:SetScript("OnMouseWheel", nil)
		Menu:SetHeight(((WIDGET_HEIGHT - 1) * Count) + 1)
	end

	Menu:SetWidth(ItemWidth)

	local SelectedItem

	for i = 1, Count do
		local MenuItem = Menu[i]

		MenuItem:SetWidth(ItemWidth)
		MenuItem:SetShown(false)

		if not SelectedItem and GetDropdownSelectionValue(self, MenuItem) == self.Value then
			SelectedItem = MenuItem
		end

		MenuItem.Selected:SetShown(MenuItem == SelectedItem)
	end

	Menu.SelectedItem = SelectedItem
	Menu.SynchronizedValue = SelectedItem and self.Value or nil
	Menu.Offset = NormalizeDropdownOffset(Menu, Menu.Offset)
	if Menu.RowViewport then
		Menu.RowViewport.LastRenderedRows = nil
		Menu.RowViewport.LastRenderedOffset = nil
		Menu.RowViewport:SetOffset(Menu.Offset, true)
		Menu.LastRenderedOffset = Menu.RowViewport.LastRenderedOffset
	else
		local First, Last = GUI.GetVisibleRowRange(Menu.Offset, Count, DROPDOWN_MAX_SHOWN)
		for i = First, Last do
			Menu[i]:Show()
		end
		AnchorDropdownRows(Menu, First, Last)
	end
end

local DropdownSort = DropdownUpdateList

local CreateDropdownSelection = function(self, key, value)
	local MenuItem = CreateFrame("Frame", nil, self.Menu)
	MenuItem:SetSize(DROPDOWN_WIDTH - 6, WIDGET_HEIGHT)
	MenuItem:SetScript("OnMouseDown", MenuItemOnMouseDown)
	MenuItem:SetScript("OnMouseUp", MenuItemOnMouseUp)
	MenuItem:SetScript("OnEnter", MenuItemOnEnter)
	MenuItem:SetScript("OnLeave", MenuItemOnLeave)
	MenuItem.Parent = MenuItem:GetParent()
	MenuItem.GrandParent = MenuItem.Parent:GetParent()
	MenuItem.Key = key
	MenuItem.Value = value
	MenuItem.ID = self.ID

	-- A dropdown may contain hundreds of shared-media entries. Applying a
	-- BackdropTemplate to every row runs NineSlice layout for each entry and can
	-- exceed the script time limit when the menu is first opened. The inset row
	-- texture covers the background, so a single black texture provides the same
	-- one-pixel border without invoking NineSlice.
	MenuItem.Background = MenuItem:CreateTexture(nil, "BACKGROUND")
	MenuItem.Background:SetAllPoints()
	MenuItem.Background:SetTexture(Assets:GetTexture("Blank"))
	MenuItem.Background:SetVertexColor(0, 0, 0)

	MenuItem.Highlight = MenuItem:CreateTexture(nil, "OVERLAY")
	MenuItem.Highlight:SetPoint("TOPLEFT", MenuItem, 1, -1)
	MenuItem.Highlight:SetPoint("BOTTOMRIGHT", MenuItem, -1, 1)
	MenuItem.Highlight:SetTexture(Assets:GetTexture("Blank"))
	MenuItem.Highlight:SetVertexColor(1, 1, 1, 0.4)
	MenuItem.Highlight:SetAlpha(0)

	MenuItem.Texture = MenuItem:CreateTexture(nil, "ARTWORK")
	MenuItem.Texture:SetPoint("TOPLEFT", MenuItem, 1, -1)
	MenuItem.Texture:SetPoint("BOTTOMRIGHT", MenuItem, -1, 1)
	MenuItem.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	MenuItem.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	MenuItem.Selected = MenuItem:CreateTexture(nil, "OVERLAY")
	MenuItem.Selected:SetPoint("TOPLEFT", MenuItem, 1, -1)
	MenuItem.Selected:SetPoint("BOTTOMRIGHT", MenuItem, -1, 1)
	MenuItem.Selected:SetTexture(Assets:GetTexture("RenHorizonUp"))
	MenuItem.Selected:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	MenuItem.Selected:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)

	MenuItem.Text = MenuItem:CreateFontString(nil, "OVERLAY")
	MenuItem.Text:SetPoint("LEFT", MenuItem, 5, 0)
	MenuItem.Text:SetSize((DROPDOWN_WIDTH - 6) - 12, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(MenuItem.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	MenuItem.Text:SetJustifyH("LEFT")
	MenuItem.Text:SetText(key)

	tinsert(self.Menu, MenuItem)

	return MenuItem
end

local ConfigureDropdownSelection = function(self, MenuItem)
	if self.SpecificType == "Texture" then
		MenuItem.Texture:SetTexture(Assets:GetTexture(MenuItem.Key))
	elseif self.SpecificType == "Font" then
		HydraUI:SetFontInfo(MenuItem.Text, MenuItem.Key, 12)
	end

	local IsSelected

	if self.SpecificType then
		IsSelected = MenuItem.Key == self.Value
	else
		IsSelected = MenuItem.Value == self.Value
	end

	MenuItem.Selected:SetShown(IsSelected)

	if IsSelected then
		if self.Menu.SelectedItem and self.Menu.SelectedItem ~= MenuItem then
			self.Menu.SelectedItem.Selected:Hide()
		end

		self.Menu.SelectedItem = MenuItem
		self.Current:SetText(MenuItem.Key)
	end
end

InitializeDropdown = function(self)
	if self.Menu.Initialized then
		return
	end

	for Key, Value in next, self.Values do
		ConfigureDropdownSelection(self, CreateDropdownSelection(self, Key, Value))
	end

	self.Menu.Initialized = true
	self.Menu.Offset = 1
	DropdownUpdateList(self)
end

local DropdownCreateSelection = function(self, key, value)
	self.Values[key] = value

	if not self.Menu.Initialized then
		return
	end

	local MenuItem = CreateDropdownSelection(self, key, value)
	ConfigureDropdownSelection(self, MenuItem)
	DropdownUpdateList(self)

	return MenuItem
end

local DropdownRemoveSelection = function(self, key)
	self.Values[key] = nil

	if not self.Menu.Initialized then
		return
	end

	for i = 1, #self.Menu do
		if self.Menu[i].Key == key then
			if self.Menu.SelectedItem == self.Menu[i] then
				self.Menu.SelectedItem = nil
				self.Menu.SynchronizedValue = nil
			end

			self.Menu[i]:Hide()
			self.Menu[i]:EnableMouse(false)

			tremove(self.Menu, i)
			DropdownUpdateList(self)

			return
		end
	end
end

GUI.Widgets.CreateDropdown = function(self, id, value, values, label, tooltip, hook, specific)
	value = Core.GetInitialValue(id, value)

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip
	Anchor.Enable = DropdownEnable
	Anchor.Disable = DropdownDisable

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	local Dropdown = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Dropdown:SetSize(DROPDOWN_WIDTH, WIDGET_HEIGHT)
	Dropdown:SetPoint("RIGHT", Anchor, 0, 0)
	Dropdown:SetBackdrop(HydraUI.BackdropAndBorder)
	Dropdown:SetBackdropColor(0.6, 0.6, 0.6)
	Dropdown:SetBackdropBorderColor(0, 0, 0)
	Dropdown:SetFrameLevel(self:GetFrameLevel() + 1)
	Dropdown.Values = values
	Dropdown.Value = value
	Dropdown.ID = id
	Dropdown.Hook = hook
	Dropdown.Tooltip = tooltip
	Dropdown.SpecificType = specific
	Dropdown.RequiresReload = Core.SetRequiresReload
	Dropdown.DisableSaving = Core.DisableSaving

	Dropdown.Sort = DropdownSort
	Dropdown.CreateSelection = DropdownCreateSelection
	Dropdown.RemoveSelection = DropdownRemoveSelection

	Dropdown.Texture = Dropdown:CreateTexture(nil, "ARTWORK")
	Dropdown.Texture:SetPoint("TOPLEFT", Dropdown, 1, -1)
	Dropdown.Texture:SetPoint("BOTTOMRIGHT", Dropdown, -1, 1)
	Dropdown.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	Dropdown.Current = Dropdown:CreateFontString(nil, "ARTWORK")
	Dropdown.Current:SetPoint("LEFT", Dropdown, HEADER_SPACING, 0)
	Dropdown.Current:SetSize(DROPDOWN_WIDTH - 20, Settings["ui-font-size"])
	HydraUI:SetFontInfo(Dropdown.Current, Settings["ui-widget-font"], Settings["ui-font-size"])
	Dropdown.Current:SetJustifyH("LEFT")

	for Key, Value in next, values do
		if (specific and Key == value) or (not specific and Value == value) then
			Dropdown.Current:SetText(Key)

			break
		end
	end

	Dropdown.Button = CreateFrame("Frame", nil, Dropdown, "BackdropTemplate")
	Dropdown.Button:SetSize(DROPDOWN_WIDTH, WIDGET_HEIGHT)
	Dropdown.Button:SetPoint("LEFT", Dropdown, 0, 0)
	Dropdown.Button:SetBackdrop(HydraUI.BackdropAndBorder)
	Dropdown.Button:SetBackdropColor(0, 0, 0, 0)
	Dropdown.Button:SetBackdropBorderColor(0, 0, 0, 0)
	Dropdown.Button:SetScript("OnMouseUp", DropdownButtonOnMouseUp)
	Dropdown.Button:SetScript("OnMouseDown", DropdownButtonOnMouseDown)
	Dropdown.Button:SetScript("OnEnter", DropdownOnEnter)
	Dropdown.Button:SetScript("OnLeave", DropdownOnLeave)

	Dropdown.Button.Highlight = Dropdown.Button:CreateTexture(nil, "OVERLAY")
	Dropdown.Button.Highlight:SetPoint("TOPLEFT", Dropdown.Button, 1, -1)
	Dropdown.Button.Highlight:SetPoint("BOTTOMRIGHT", Dropdown.Button, -1, 1)
	Dropdown.Button.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Dropdown.Button.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Dropdown.Button.Highlight:SetAlpha(0)

	Dropdown.Text = Dropdown:CreateFontString(nil, "OVERLAY")
	Dropdown.Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Dropdown.Text:SetSize(GROUP_WIDTH - DROPDOWN_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Dropdown.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Dropdown.Text:SetJustifyH("LEFT")
	Dropdown.Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	Dropdown.ArrowAnchor = CreateFrame("Frame", nil, Dropdown)
	Dropdown.ArrowAnchor:SetSize(WIDGET_HEIGHT, WIDGET_HEIGHT)
	Dropdown.ArrowAnchor:SetPoint("RIGHT", Dropdown, 0, 0)

	Dropdown.Button.Arrow = Dropdown.Button:CreateTexture(nil, "OVERLAY")
	Dropdown.Button.Arrow:SetPoint("CENTER", Dropdown.ArrowAnchor, 0, 0)
	Dropdown.Button.Arrow:SetSize(16, 16)
	Dropdown.Button.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
	Dropdown.Button.Arrow:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
	Dropdown.Button.Arrow:SetDrawLayer("OVERLAY", 7)

	Dropdown.Menu = CreateFrame("Frame", nil, Dropdown)
	Dropdown.Menu:SetPoint("TOPLEFT", Dropdown, "BOTTOMLEFT", SPACING, -2)
	Dropdown.Menu:SetPoint("TOPRIGHT", Dropdown, "BOTTOMRIGHT", -SPACING, -2)
	Dropdown.Menu:SetSize(DROPDOWN_WIDTH - (SPACING * 2), 1)
	Dropdown.Menu:SetFrameStrata("DIALOG")
	Dropdown.Menu:EnableMouse(true)
	Dropdown.Menu:EnableMouseWheel(true)
	Dropdown.Menu:Hide()
	Dropdown.Menu:SetAlpha(0)
	Dropdown.Menu.Initialized = false
	Dropdown.Menu.Offset = 1
	Dropdown.Menu.SelectedItem = nil
	Dropdown.Menu.SynchronizedValue = nil

	Dropdown.Button.Menu = Dropdown.Menu
	Dropdown.Button.Parent = Dropdown

	Dropdown.Menu.FadeIn = LibMotion:CreateAnimation(Dropdown.Menu, "Fade")
	Dropdown.Menu.FadeIn:SetEasing("in")
	Dropdown.Menu.FadeIn:SetDuration(0.15)
	Dropdown.Menu.FadeIn:SetChange(1)

	Dropdown.Menu.FadeOut = LibMotion:CreateAnimation(Dropdown.Menu, "Fade")
	Dropdown.Menu.FadeOut:SetEasing("out")
	Dropdown.Menu.FadeOut:SetDuration(0.15)
	Dropdown.Menu.FadeOut:SetChange(0)
	Dropdown.Menu.FadeOut:SetScript("OnFinished", FadeOnFinished)

	Dropdown.Menu.BG = CreateFrame("Frame", nil, Dropdown.Menu, "BackdropTemplate")
	Dropdown.Menu.BG:SetPoint("BOTTOMLEFT", Dropdown.Menu, -SPACING, -SPACING)
	Dropdown.Menu.BG:SetPoint("TOPRIGHT", Dropdown, "BOTTOMRIGHT", 0, 1)
	Dropdown.Menu.BG:SetBackdrop(HydraUI.BackdropAndBorder)
	Dropdown.Menu.BG:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	Dropdown.Menu.BG:SetBackdropBorderColor(0, 0, 0)
	Dropdown.Menu.BG:SetFrameLevel(Dropdown.Menu:GetFrameLevel() - 1)
	Dropdown.Menu:EnableMouse(true)
	Dropdown.Menu.BG:EnableMouse(true)
	Dropdown.Menu.BG:SetScript("OnMouseWheel", function() end)

	if specific == "Texture" then
		Dropdown.Texture:SetTexture(Assets:GetTexture(value))
	elseif specific == "Font" then
		Dropdown.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		HydraUI:SetFontInfo(Dropdown.Current, Settings[id], Settings["ui-font-size"])
	else
		Dropdown.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	end

	Anchor.Dropdown = Dropdown

	if self.Widgets then
		RegisterWidget(self, Anchor, id)
	elseif id ~= "" then
		GUI.WidgetID[id] = Anchor
	end

	return Dropdown
end
