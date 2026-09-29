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

-- Checkbox
local CHECKBOX_WIDTH = 20

local CheckboxOnMouseUp = function(self)
	if self.Value then
		self.FadeOut:Play()
		self.Value = false
	else
		self.FadeIn:Play()
		self.Value = true
	end

	SetVariable(self.ID, self.Value)

	if (self.ReloadFlag) then
		HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, self.Hook, CANCEL, nil, self.Value, self.ID)
	elseif self.Hook then
		self.Hook(self.Value, self.ID)
	end
end

local CheckboxOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local CheckboxOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local CheckboxRequiresReload = function(self, flag)
	self.ReloadFlag = flag

	return self
end

GUI.Widgets.CreateCheckbox = function(self, id, value, label, tooltip, hook)
	if (Settings[id] ~= nil) then
		value = Settings[id]
	end

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	local Checkbox = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Checkbox:SetSize(CHECKBOX_WIDTH, WIDGET_HEIGHT)
	Checkbox:SetPoint("RIGHT", Anchor, 0, 0)
	Checkbox:SetBackdrop(HydraUI.BackdropAndBorder)
	Checkbox:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Checkbox:SetBackdropBorderColor(0, 0, 0)
	Checkbox:SetScript("OnMouseUp", CheckboxOnMouseUp)
	Checkbox:SetScript("OnEnter", CheckboxOnEnter)
	Checkbox:SetScript("OnLeave", CheckboxOnLeave)
	Checkbox.Value = value
	Checkbox.Hook = hook
	Checkbox.Tooltip = tooltip
	Checkbox.ID = id
	Checkbox.RequiresReload = CheckboxRequiresReload

	local BG = Checkbox:CreateTexture(nil, "ARTWORK")
	BG:SetPoint("TOPLEFT", Checkbox, 1, -1)
	BG:SetPoint("BOTTOMRIGHT", Checkbox, -1, 1)
	BG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	BG:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bg-color"]))

	local Highlight = Checkbox:CreateTexture(nil, "OVERLAY")
	Highlight:SetPoint("TOPLEFT", Checkbox, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", Checkbox, -1, 1)
	Highlight:SetTexture(Assets:GetTexture("Blank"))
	Highlight:SetVertexColor(1, 1, 1, 0.4)
	Highlight:SetAlpha(0)

	local Texture = Checkbox:CreateTexture(nil, "ARTWORK")
	Texture:SetPoint("TOPLEFT", Checkbox, 1, -1)
	Texture:SetPoint("BOTTOMRIGHT", Checkbox, -1, 1)
	Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	local Text = Anchor:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Text:SetSize(GROUP_WIDTH - CHECKBOX_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	local Hover = Checkbox:CreateTexture(nil, "HIGHLIGHT")
	Hover:SetPoint("TOPLEFT", Checkbox, 1, -1)
	Hover:SetPoint("BOTTOMRIGHT", Checkbox, -1, 1)
	Hover:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))
	Hover:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Hover:SetAlpha(0)

	local FadeIn = LibMotion:CreateAnimation(Texture, "Fade")
	FadeIn:SetEasing("in")
	FadeIn:SetDuration(0.3)
	FadeIn:SetChange(1)

	local FadeOut = LibMotion:CreateAnimation(Texture, "Fade")
	FadeOut:SetEasing("out")
	FadeOut:SetDuration(0.3)
	FadeOut:SetChange(0)

	if value then
		Texture:SetAlpha(1)
	else
		Texture:SetAlpha(0)
	end

	Checkbox.Highlight = Highlight
	Checkbox.Texture = Texture
	Checkbox.Text = Text
	Checkbox.Hover = Hover
	Checkbox.FadeIn = FadeIn
	Checkbox.FadeOut = FadeOut

	RegisterWidget(self, Anchor, id)

	return Checkbox
end

-- Switch
local SWITCH_WIDTH = 50
local SWITCH_TRAVEL = SWITCH_WIDTH - WIDGET_HEIGHT

local SwitchOnMouseUp = function(self)
	if self.Move:IsPlaying() then
		return
	end

	self.Thumb:ClearAllPoints()

	if self.Value then
		self.Thumb:SetPoint("RIGHT", self, 0, 0)
		self.Move:SetOffset(-SWITCH_TRAVEL, 0)
		self.Value = false
	else
		self.Thumb:SetPoint("LEFT", self, 0, 0)
		self.Move:SetOffset(SWITCH_TRAVEL, 0)
		self.Value = true
	end

	self.Move:Play()

	SetVariable(self.ID, self.Value)

	if self.ReloadFlag then
		HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, self.Hook, CANCEL, nil, self.Value, self.ID)
	elseif self.Hook then
		self.Hook(self.Value, self.ID)
	end
end

local SwitchOnMouseWheel = function(self, delta)
	if (not IsModifierKeyDown()) then
		return
	end

	local CurrentValue = self.Value
	local NewValue

	if (delta < 0) then
		NewValue = false
	else
		NewValue = true
	end

	if (CurrentValue ~= NewValue) then
		SwitchOnMouseUp(self) -- This is already set up to handle everything, so just pass it along
	end
end

local SwitchOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)

	if IsModifierKeyDown() then
		self:SetScript("OnMouseWheel", self.OnMouseWheel)
	end
end

local SwitchOnLeave = function(self)
	self.Highlight:SetAlpha(0)

	if self:HasScript("OnMouseWheel") then
		self:SetScript("OnMouseWheel", nil)
	end
end

local SwitchEnable = function(self)
	self.Switch:EnableMouse(true)
	self.Switch:EnableMouseWheel(true)

	self.Switch.Flavor:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
end

local SwitchDisable = function(self)
	self.Switch:EnableMouse(false)
	self.Switch:EnableMouseWheel(false)

	self.Switch.Flavor:SetVertexColor(HydraUI:HexToRGB("A5A5A5"))
end

local SwitchRequiresReload = function(self, flag)
	self.ReloadFlag = flag

	return self
end

GUI.Widgets.CreateSwitch = function(self, id, value, label, tooltip, hook)
	if (Settings[id] ~= nil) then
		value = Settings[id]
	end

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip
	Anchor.Enable = SwitchEnable
	Anchor.Disable = SwitchDisable

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	local Switch = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	Switch:SetSize(SWITCH_WIDTH, WIDGET_HEIGHT)
	Switch:SetPoint("RIGHT", Anchor, 0, 0)
	Switch:SetBackdrop(HydraUI.BackdropAndBorder)
	Switch:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	Switch:SetBackdropBorderColor(0, 0, 0)
	Switch:SetScript("OnMouseUp", SwitchOnMouseUp)
	Switch:SetScript("OnEnter", SwitchOnEnter)
	Switch:SetScript("OnLeave", SwitchOnLeave)
	Switch.Value = value
	Switch.Hook = hook
	Switch.Tooltip = tooltip
	Switch.ID = id
	Switch.RequiresReload = SwitchRequiresReload
	Switch.OnMouseWheel = SwitchOnMouseWheel

	local BG = Switch:CreateTexture(nil, "ARTWORK")
	BG:SetPoint("TOPLEFT", Switch, 1, -1)
	BG:SetPoint("BOTTOMRIGHT", Switch, -1, 1)
	BG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	BG:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bg-color"]))

	local Thumb = CreateFrame("Frame", nil, Switch, "BackdropTemplate")
	Thumb:SetSize(WIDGET_HEIGHT, WIDGET_HEIGHT)
	Thumb:SetBackdrop(HydraUI.BackdropAndBorder)
	Thumb:SetBackdropBorderColor(0, 0, 0)
	Thumb:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))
	Thumb:SetPoint(Switch.Value and "RIGHT" or "LEFT", Switch, 0, 0)

	local ThumbTexture = Thumb:CreateTexture(nil, "ARTWORK")
	ThumbTexture:SetSize(WIDGET_HEIGHT - 2, WIDGET_HEIGHT - 2)
	ThumbTexture:SetPoint("TOPLEFT", Thumb, 1, -1)
	ThumbTexture:SetPoint("BOTTOMRIGHT", Thumb, -1, 1)
	ThumbTexture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	ThumbTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	local Flavor = Switch:CreateTexture(nil, "ARTWORK")
	Flavor:SetPoint("TOPLEFT", Switch, "TOPLEFT", 1, -1)
	Flavor:SetPoint("BOTTOMRIGHT", Thumb, "BOTTOMLEFT", 0, 1)
	Flavor:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Flavor:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	local Text = Anchor:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Text:SetSize(GROUP_WIDTH - SWITCH_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	local Highlight = Switch:CreateTexture(nil, "HIGHLIGHT")
	Highlight:SetPoint("TOPLEFT", Switch, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", Switch, -1, 1)
	Highlight:SetTexture(Assets:GetTexture("Blank"))
	Highlight:SetVertexColor(1, 1, 1, 0.4)
	Highlight:SetAlpha(0)

	local Move = LibMotion:CreateAnimation(Thumb, "Move")
	Move:SetEasing("in")
	Move:SetDuration(0.1)

	Switch.Thumb = Thumb
	Switch.Text = Text
	Switch.Highlight = Highlight
	Switch.Move = Move
	Switch.Flavor = Flavor

	Anchor.Switch = Switch

	RegisterWidget(self, Anchor, id)

	return Switch
end
