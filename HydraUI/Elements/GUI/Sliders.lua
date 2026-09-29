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

-- Slider
local SLIDER_WIDTH = 80
local EDITBOX_WIDTH = 48

local NormalizeSliderValue = function(self, value)
	return Core.NormalizeSliderValue(value, self.EditBox.MinValue, self.EditBox.MaxValue, self.EditBox.StepValue)
end

local SliderOnValueChanged = function(self)
	local Value = NormalizeSliderValue(self, self:GetValue())

	if (Value == self.AppliedValue) then
		return
	end

	self.AppliedValue = Value

	self.EditBox.Value = Value
	self.EditBox:SetText(self.Prefix..Value..self.Postfix)

	SetVariable(self.ID, Value)

	if self.ReloadFlag then
		HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, self.Hook, CANCEL, nil, Value, self.ID)
	elseif self.Hook then
		self.Hook(Value, self.ID)
	end
end

local SliderOnMouseWheel = function(self, delta)
	if (not IsModifierKeyDown()) then
		return
	end

	local Value = self.EditBox.Value
	local Step = self.EditBox.StepValue

	if (delta < 0) then
		Value = Value - Step
	else
		Value = Value + Step
	end

	if (Step >= 1) then
		Value = floor(Value)
	else
		Value = Round(Value, (Step <= 0.01 and 2 or 1))
	end

	if (Value < self.EditBox.MinValue) then
		Value = self.EditBox.MinValue
	elseif (Value > self.EditBox.MaxValue) then
		Value = self.EditBox.MaxValue
	end

	self.EditBox.Value = Value

	self:SetValue(Value)
end

local EditBoxOnEnterPressed = function(self)
	local Value = tonumber(self:GetText())

	if (type(Value) ~= "number") then
		return
	end

	if (Value ~= self.Value) then
		self.Slider:SetValue(Value)
	end

	self:SetAutoFocus(false)
	self:ClearFocus()
end

local EditBoxOnMouseDown = function(self)
	self:SetAutoFocus(true)
	self:SetText(self.Value)
end

local EditBoxOnEditFocusLost = function(self)
	if (self.Value > self.MaxValue) then
		self.Value = self.MaxValue
	elseif (self.Value < self.MinValue) then
		self.Value = self.MinValue
	end

	self:SetText(self.Prefix..self.Value..self.Postfix)
end

local EditBoxOnChar = function(self)
	local Value = tonumber(self:GetText())

	if (type(Value) ~= "number") then
		self:SetText(self.Value)
	end
end

local EditBoxOnMouseWheel = function(self, delta)
	if (not IsModifierKeyDown()) then
		return
	end

	if self:HasFocus() then
		self:SetAutoFocus(false)
		self:ClearFocus()
	end

	if (delta > 0) then
		self.Value = self.Value + self.StepValue

		if (self.Value > self.MaxValue) then
			self.Value = self.MaxValue
		end
	else
		self.Value = self.Value - self.StepValue

		if (self.Value < self.MinValue) then
			self.Value = self.MinValue
		end
	end

	self.Slider:SetValue(self.Value)
end

local EditBoxOnEnter = function(self)
	self.Parent.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)

	if IsModifierKeyDown() then
		self:SetScript("OnMouseWheel", self.OnMouseWheel)
	end
end

local EditboxOnLeave = function(self)
	self.Parent.Highlight:SetAlpha(0)

	if self:HasScript("OnMouseWheel") then
		self:SetScript("OnMouseWheel", nil)
	end
end

local SliderOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)

	if IsModifierKeyDown() then
		self:SetScript("OnMouseWheel", self.OnMouseWheel)
	end
end

local SliderOnLeave = function(self)
	self.Highlight:SetAlpha(0)

	if self:HasScript("OnMouseWheel") then
		self:SetScript("OnMouseWheel", nil)
	end
end

local SliderEnable = function(self)
	self.Slider:EnableMouse(true)
	self.Slider:EnableMouseWheel(true)

	self.Slider.EditBox:EnableKeyboard(true)
	self.Slider.EditBox:EnableMouse(true)
	self.Slider.EditBox:EnableMouseWheel(true)

	self.Slider.EditBox:SetTextColor(HydraUI:HexToRGB("FFFFFF"))
	self.Slider.Progress:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))
end

local SliderDisable = function(self)
	self.Slider:EnableMouse(false)
	self.Slider:EnableMouseWheel(false)

	self.Slider.EditBox:EnableKeyboard(false)
	self.Slider.EditBox:EnableMouse(false)
	self.Slider.EditBox:EnableMouseWheel(false)

	self.Slider.EditBox:SetTextColor(HydraUI:HexToRGB("A5A5A5"))
	self.Slider.Progress:SetVertexColor(HydraUI:HexToRGB("A5A5A5"))
end

local SliderRequiresReload = function(self, flag)
	self.ReloadFlag = flag

	return self
end

GUI.Widgets.CreateSlider = function(self, id, value, minvalue, maxvalue, step, label, tooltip, hook, prefix, postfix)
	if (Settings[id] ~= nil) then
		value = Settings[id]
	end

	local Anchor = CreateFrame("Frame", nil, self)
	Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip
	Anchor.Enable = SliderEnable
	Anchor.Disable = SliderDisable

	Anchor:SetScript("OnEnter", AnchorOnEnter)
	Anchor:SetScript("OnLeave", AnchorOnLeave)

	if (not prefix) then
		prefix = ""
	end

	if (not postfix) then
		postfix = ""
	end

	local EditBox = CreateFrame("Frame", nil, Anchor, "BackdropTemplate")
	EditBox:SetSize(EDITBOX_WIDTH, WIDGET_HEIGHT)
	EditBox:SetPoint("RIGHT", Anchor, 0, 0)
	EditBox:SetBackdrop(HydraUI.BackdropAndBorder)
	EditBox:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	EditBox:SetBackdropBorderColor(0, 0, 0)

	EditBox.Texture = EditBox:CreateTexture(nil, "ARTWORK")
	EditBox.Texture:SetPoint("TOPLEFT", EditBox, 1, -1)
	EditBox.Texture:SetPoint("BOTTOMRIGHT", EditBox, -1, 1)
	EditBox.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	EditBox.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	EditBox.Highlight = EditBox:CreateTexture(nil, "OVERLAY")
	EditBox.Highlight:SetPoint("TOPLEFT", EditBox, 1, -1)
	EditBox.Highlight:SetPoint("BOTTOMRIGHT", EditBox, -1, 1)
	EditBox.Highlight:SetTexture(Assets:GetTexture("Blank"))
	EditBox.Highlight:SetVertexColor(1, 1, 1, 0.4)
	EditBox.Highlight:SetAlpha(0)

	EditBox.Box = CreateFrame("EditBox", nil, EditBox)
	HydraUI:SetFontInfo(EditBox.Box, Settings["ui-widget-font"], Settings["ui-font-size"])
	EditBox.Box:SetPoint("TOPLEFT", EditBox, SPACING, -2)
	EditBox.Box:SetPoint("BOTTOMRIGHT", EditBox, -SPACING, 2)
	EditBox.Box:SetJustifyH("CENTER")
	EditBox.Box:SetMaxLetters(5)
	EditBox.Box:SetAutoFocus(false)
	EditBox.Box:EnableKeyboard(true)
	EditBox.Box:EnableMouse(true)
	EditBox.Box:EnableMouseWheel(true)
	EditBox.Box:SetText(prefix..value..postfix)
	EditBox.Box.MinValue = minvalue
	EditBox.Box.MaxValue = maxvalue
	EditBox.Box.StepValue = step
	EditBox.Box.Value = value
	EditBox.Box.Prefix = prefix
	EditBox.Box.Postfix = postfix
	EditBox.Box.Parent = EditBox
	EditBox.Box.OnMouseWheel = EditBoxOnMouseWheel

	EditBox.Box:SetScript("OnMouseDown", EditBoxOnMouseDown)
	EditBox.Box:SetScript("OnEscapePressed", EditBoxOnEnterPressed)
	EditBox.Box:SetScript("OnEnterPressed", EditBoxOnEnterPressed)
	EditBox.Box:SetScript("OnEditFocusLost", EditBoxOnEditFocusLost)
	EditBox.Box:SetScript("OnChar", EditBoxOnChar)
	EditBox.Box:SetScript("OnEnter", EditBoxOnEnter)
	EditBox.Box:SetScript("OnLeave", EditboxOnLeave)

	local Slider = CreateFrame("Slider", nil, Anchor, "BackdropTemplate")
	Slider:SetPoint("RIGHT", EditBox, "LEFT", -2, 0)
	Slider:SetSize(SLIDER_WIDTH, WIDGET_HEIGHT)
	Slider:SetThumbTexture(Assets:GetTexture("Blank"))
	Slider:SetOrientation("HORIZONTAL")
	Slider:SetValueStep(step)
	Slider:SetBackdrop(HydraUI.BackdropAndBorder)
	Slider:SetBackdropColor(0, 0, 0)
	Slider:SetBackdropBorderColor(0, 0, 0)
	Slider:SetMinMaxValues(minvalue, maxvalue)
	Slider:SetValue(value)
	Slider:EnableMouseWheel(true)
	Slider:SetObeyStepOnDrag(true)
	Slider:SetScript("OnValueChanged", SliderOnValueChanged)
	Slider:SetScript("OnEnter", SliderOnEnter)
	Slider:SetScript("OnLeave", SliderOnLeave)
	Slider.Prefix = prefix or ""
	Slider.Postfix = postfix or ""
	Slider.EditBox = EditBox.Box
	Slider.Hook = hook
	Slider.ID = id
	Slider.AppliedValue = NormalizeSliderValue(Slider, Slider:GetValue())
	Slider.RequiresReload = SliderRequiresReload
	Slider.OnMouseWheel = SliderOnMouseWheel

	Slider.Text = Slider:CreateFontString(nil, "OVERLAY")
	Slider.Text:SetPoint("LEFT", Anchor, LABEL_SPACING, 0)
	Slider.Text:SetSize(GROUP_WIDTH - SLIDER_WIDTH - EDITBOX_WIDTH - 6, WIDGET_HEIGHT)
	HydraUI:SetFontInfo(Slider.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Slider.Text:SetJustifyH("LEFT")
	Slider.Text:SetText("|cFF"..Settings["ui-widget-font-color"]..label.."|r")

	Slider.TrackTexture = Slider:CreateTexture(nil, "ARTWORK")
	Slider.TrackTexture:SetPoint("TOPLEFT", Slider, 1, -1)
	Slider.TrackTexture:SetPoint("BOTTOMRIGHT", Slider, -1, 1)
	Slider.TrackTexture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Slider.TrackTexture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bg-color"]))

	local Thumb = Slider:GetThumbTexture()
	Thumb:SetSize(8, WIDGET_HEIGHT)
	Thumb:SetTexture(Assets:GetTexture("Blank"))
	Thumb:SetVertexColor(0, 0, 0)

	Slider.NewThumb = CreateFrame("Frame", nil, Slider, "BackdropTemplate")
	Slider.NewThumb:SetPoint("TOPLEFT", Thumb, 0, -1)
	Slider.NewThumb:SetPoint("BOTTOMRIGHT", Thumb, 0, 1)
	Slider.NewThumb:SetBackdrop(HydraUI.BackdropAndBorder)
	Slider.NewThumb:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-widget-bg-color"]))
	Slider.NewThumb:SetBackdropBorderColor(0, 0, 0)

	Slider.NewThumb.Texture = Slider.NewThumb:CreateTexture(nil, "OVERLAY")
	Slider.NewThumb.Texture:SetPoint("TOPLEFT", Slider.NewThumb, 1, 0)
	Slider.NewThumb.Texture:SetPoint("BOTTOMRIGHT", Slider.NewThumb, -1, 0)
	Slider.NewThumb.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Slider.NewThumb.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-bright-color"]))

	Slider.Progress = Slider:CreateTexture(nil, "ARTWORK")
	Slider.Progress:SetPoint("TOPLEFT", Slider, 1, -1)
	Slider.Progress:SetPoint("BOTTOMRIGHT", Slider.NewThumb.Texture, "BOTTOMLEFT", 0, 0)
	Slider.Progress:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Slider.Progress:SetVertexColor(HydraUI:HexToRGB(Settings["ui-widget-color"]))

	Slider.Highlight = Slider:CreateTexture(nil, "OVERLAY")
	Slider.Highlight:SetPoint("TOPLEFT", Slider, 1, -1)
	Slider.Highlight:SetPoint("BOTTOMRIGHT", Slider, -1, 1)
	Slider.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Slider.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Slider.Highlight:SetDrawLayer("OVERLAY", 7)
	Slider.Highlight:SetAlpha(0)

	EditBox.Box.Slider = Slider
	Anchor.Slider = Slider

	Slider:Show()

	RegisterWidget(self, Anchor, id)

	return Slider
end
