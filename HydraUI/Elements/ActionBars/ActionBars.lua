local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:NewModule("Action Bars")
local GUI = HydraUI:GetModule("GUI")

local IsUsableAction = IsUsableAction
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS

local NumPad = KEY_NUMPAD1:gsub("%s%S$", "")
local WheelUp = KEY_MOUSEWHEELUP
local WheelDown = KEY_MOUSEWHEELDOWN
local MouseButton = KEY_BUTTON4:gsub("%s%S$", "")
local MiddleButton = KEY_BUTTON3

-- The descriptor table is the single source of truth for standard action bars.
-- Optional bars report their availability so creation and configuration can skip them.
local ActionBarDescriptors = {
	{ index = 1, field = "Bar1", label = "Bar 1", parent = nil, prefix = "ActionButton", anchor = { "BOTTOM", "UIParent", "BOTTOM", 0, 13 }, defaultPerRow = 12, hasButtonMax = true, available = function() return ActionButton1 ~= nil end, securePaging = true },
	{ index = 2, field = "Bar2", label = "Bar 2", parent = "MultiBarBottomLeft", prefix = "MultiBarBottomLeftButton", anchor = { "BOTTOM", "Bar1", "TOP", 0, "gap" }, defaultPerRow = 12, hasButtonMax = true, available = function() return MultiBarBottomLeft ~= nil end },
	{ index = 3, field = "Bar3", label = "Bar 3", parent = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton", anchor = { "BOTTOM", "Bar2", "TOP", 0, "gap" }, defaultPerRow = 12, hasButtonMax = true, available = function() return MultiBarBottomRight ~= nil end },
	{ index = 4, field = "Bar4", label = "Bar 4", parent = "MultiBarRight", prefix = "MultiBarRightButton", anchor = { "RIGHT", "UIParent", "RIGHT", -12, 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBarRight ~= nil end },
	{ index = 5, field = "Bar5", label = "Bar 5", parent = "MultiBarLeft", prefix = "MultiBarLeftButton", anchor = { "RIGHT", "Bar4", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBarLeft ~= nil end },
	{ index = 6, field = "Bar6", label = "Bar 6", parent = "MultiBar5", prefix = "MultiBar5Button", anchor = { "RIGHT", "Bar5", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar5 ~= nil end },
	{ index = 7, field = "Bar7", label = "Bar 7", parent = "MultiBar6", prefix = "MultiBar6Button", anchor = { "RIGHT", "Bar6", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar6 ~= nil end },
	{ index = 8, field = "Bar8", label = "Bar 8", parent = "MultiBar7", prefix = "MultiBar7Button", anchor = { "RIGHT", "Bar7", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar7 ~= nil end },
}

AB.ActionBarDescriptors = ActionBarDescriptors

-- Defaults
Defaults["ab-enable"] = true

Defaults["ab-show-hotkey"] = true
Defaults["ab-show-count"] = true
Defaults["ab-show-macro"] = true

Defaults["ab-font"] = "PT Sans"
Defaults["ab-font-size"] = 12
Defaults["ab-cd-size"] = 18
Defaults["ab-font-flags"] = ""

for _, descriptor in ipairs(ActionBarDescriptors) do
	local key = "ab-bar" .. descriptor.index
	Defaults[key .. "-enable"] = true
	Defaults[key .. "-hover"] = false
	Defaults[key .. "-button-size"] = 32
	Defaults[key .. "-button-gap"] = 2
	Defaults[key .. "-per-row"] = descriptor.defaultPerRow
	Defaults[key .. "-alpha"] = 100

	if descriptor.hasButtonMax then
		Defaults[key .. "-button-max"] = 12
	end
end

Defaults["ab-pet-enable"] = true
Defaults["ab-pet-hover"] = false
Defaults["ab-pet-button-size"] = 32
Defaults["ab-pet-button-gap"] = 2
Defaults["ab-pet-per-row"] = 1
Defaults["ab-pet-alpha"] = 100

Defaults["ab-stance-enable"] = true
Defaults["ab-stance-hover"] = false
Defaults["ab-stance-button-size"] = 32
Defaults["ab-stance-button-gap"] = 2
Defaults["ab-stance-per-row"] = 12
Defaults["ab-stance-alpha"] = 100

Defaults["ab-totem-enable"] = true
Defaults["ab-extra-button-size"] = 60

function AB:Disable(object)
	if (not object) then
		return
	end

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end

	object:SetParent(self.Hide)
end

function AB:EnableBar(bar)
	if (not bar) then
		return
	end

	RegisterAttributeDriver(bar, "state-visibility", "[nopetbattle] show; hide")
	bar:Show()
end

function AB:DisableBar(bar)
	if (not bar) then
		return
	end

	UnregisterAttributeDriver(bar, "state-visibility")
	bar:Hide()
end

function AB:UpdateHotKeyText()
	local Text = self.HotKey:GetText()

	if Text then
		Text = Text:gsub(NumPad, "N")
		Text = Text:gsub(WheelUp, "MWU")
		Text = Text:gsub(WheelDown, "MWD")
		Text = Text:gsub(MouseButton, "MB")
		Text = Text:gsub(MiddleButton, "MMB")
		Text = Text:gsub(CTRL_KEY_TEXT, "c")
		Text = Text:gsub(SHIFT_KEY_TEXT, "s")
		Text = Text:gsub(ALT_KEY_TEXT, "a")

		self.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
	end
end

function AB:PositionButtons(bar, numbuttons, perrow, size, spacing)
	if (numbuttons < perrow) then
		perrow = numbuttons
	end

	local Columns = ceil(numbuttons / perrow)

	if (Columns < 1) then
		Columns = 1
	end

	-- Bar sizing
	bar:SetWidth((size * perrow) + (spacing * (perrow - 1)))
	bar:SetHeight((size * Columns) + (spacing * (Columns - 1)))

	-- Actual moving
	for i = 1, #bar do
		local Button = bar[i]

		Button:ClearAllPoints()
		Button:SetSize(size, size)

		if (i == 1) then
			Button:SetPoint("TOPLEFT", bar, 0, 0)
		elseif ((i - 1) % perrow == 0) then
			Button:SetPoint("TOP", bar[i - perrow], "BOTTOM", 0, -spacing)
		else
			Button:SetPoint("LEFT", bar[i - 1], "RIGHT", spacing, 0)
		end

		if (i > numbuttons) then
			Button:SetParent(self.Hide)
		else
			Button:SetParent(bar.ButtonParent or bar)
		end
	end
end

function AB:StyleActionButton(button)
	if button.Styled then
		return
	end

	if button.IconMask then
		button.IconMask:Hide()
	end

	if button.RightDivider then
		button.RightDivider:Hide()
	end

	if button.SlotArt then
		button.SlotArt:Hide()
	end

	if button.SlotBackground then
		button.SlotBackground:SetAlpha(0)
		button.SlotBackground:Hide()
	end

	if _G[button:GetName().."NormalTexture"] then
		_G[button:GetName().."NormalTexture"]:SetTexture(nil)
	end

	if button:GetNormalTexture() then
		button:GetNormalTexture():SetTexture(nil)
	end

	button:SetNormalTexture("")

	if button.Border then
		button.Border:SetTexture(nil)
	end

	-- ActionButtonMixin exposes the icon as Icon on current clients. Keep the
	-- lowercase lookup for older clients, which used the template global.
	local Icon = button.Icon or button.icon

	if Icon then
		button.icon = Icon
		Icon:ClearAllPoints()
		Icon:SetPoint("TOPLEFT", button, 1, -1)
		Icon:SetPoint("BOTTOMRIGHT", button, -1, 1)
		Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		Icon:SetAlpha(1)
		Icon:Show()
	end

	if _G[button:GetName() .. "FloatingBG"] then
		self:Disable(_G[button:GetName() .. "FloatingBG"])
	end

	if button.HotKey then
		button.HotKey:ClearAllPoints()
		button.HotKey:SetPoint("TOPLEFT", button, 2, -3)
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.HotKey:SetJustifyH("LEFT")
		button.HotKey:SetTextColor(1, 1, 1)
		button.HotKey.SetTextColor = function() end

		local Text = button.HotKey:GetText()

		if Text then
			Text = Text:gsub(NumPad, "N")
			Text = Text:gsub(WheelUp, "MWU")
			Text = Text:gsub(WheelDown, "MWD")
			Text = Text:gsub(MouseButton, "MB")
			Text = Text:gsub(MiddleButton, "MMB")
			Text = Text:gsub(CTRL_KEY_TEXT, "c")
			Text = Text:gsub(SHIFT_KEY_TEXT, "s")
			Text = Text:gsub(ALT_KEY_TEXT, "a")

			button.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
		end

		button.HotKey.OST = button.HotKey.SetText
		button.HotKey.SetText = function(self, text)
			self:OST("|cFFFFFFFF" .. text .. "|r")
		end

		if (not Settings["ab-show-hotkey"]) then
			button.HotKey:SetAlpha(0)
		end
	end

	if button.Name then
		button.Name:ClearAllPoints()
		button.Name:SetPoint("BOTTOMLEFT", button, 2, 2)
		button.Name:SetWidth(button:GetWidth() - 4)
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Name:SetJustifyH("LEFT")
		button.Name:SetTextColor(1, 1, 1)
		button.Name.SetTextColor = function() end

		if (not Settings["ab-show-macro"]) then
			button.Name:SetAlpha(0)
		end
	end

	if button.Count then
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, -2, 2)
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Count:SetJustifyH("RIGHT")
		button.Count:SetDrawLayer("OVERLAY")
		button.Count:SetTextColor(1, 1, 1)
		button.Count.SetTextColor = function() end

		if (not Settings["ab-show-count"]) then
			button.Count:SetAlpha(0)
		end
	end

	button.Backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.Backdrop:SetPoint("TOPLEFT", button, 0, 0)
	button.Backdrop:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.Backdrop:SetBackdrop(HydraUI.Backdrop)
	button.Backdrop:SetBackdropColor(0, 0, 0)
	button.Backdrop:SetFrameLevel(button:GetFrameLevel() - 1)

	button.Backdrop.Texture = button.Backdrop:CreateTexture(nil, "BORDER")
	button.Backdrop.Texture:SetPoint("TOPLEFT", button.Backdrop, 1, -1)
	button.Backdrop.Texture:SetPoint("BOTTOMRIGHT", button.Backdrop, -1, 1)
	button.Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	button.Backdrop.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))

	if button:GetCheckedTexture() then
		local Checked = button:GetCheckedTexture()
		Checked:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Checked:SetColorTexture(0.1, 0.9, 0.1, 0.2)
		Checked:SetPoint("TOPLEFT", button, 1, -1)
		Checked:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	if button:GetPushedTexture() then
		local Pushed = button:GetPushedTexture()
		Pushed:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
		Pushed:SetPoint("TOPLEFT", button, 1, -1)
		Pushed:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	local Highlight = button:GetHighlightTexture()
	Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Highlight:SetColorTexture(1, 1, 1, 0.2)
	Highlight:SetPoint("TOPLEFT", button, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)

	if button.Flash then
		button.Flash:SetVertexColor(0.7, 0.7, 0.1, 0.3)
		button.Flash:SetPoint("TOPLEFT", button, 1, -1)
		button.Flash:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	local Range = button:CreateTexture(nil, "ARTWORK")
	Range:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Range:SetVertexColor(0.7, 0, 0)
	Range:SetPoint("TOPLEFT", button, 1, -1)
	Range:SetPoint("BOTTOMRIGHT", button, -1, 1)
	Range:SetAlpha(0)

	button.Range = Range

	if button.cooldown then
		button.cooldown:ClearAllPoints()
		button.cooldown:SetPoint("TOPLEFT", button, 1, -1)
		button.cooldown:SetPoint("BOTTOMRIGHT", button, -1, 1)

		button.cooldown:SetDrawEdge(true)
		button.cooldown:SetEdgeTexture(Assets:GetTexture("Blank"))
		button.cooldown:SetSwipeColor(0, 0, 0, 1)

		local FontString = button.cooldown:GetRegions()

		if FontString then
			HydraUI:SetFontInfo(FontString, Settings["ab-font"], Settings["ab-cd-size"], Settings["ab-font-flags"])
		end
	end

	button:SetFrameLevel(15)
	button:SetFrameStrata("MEDIUM")

	if button.Update then
		hooksecurefunc(button, "Update", AB.UpdateHotKeyText)
	elseif ActionButton_UpdateHotkeys then
		hooksecurefunc("ActionButton_UpdateHotkeys", AB.UpdateHotKeyText)
	end

	button.Styled = true
end

function AB:StylePetActionButton(button)
	if button.Styled then
		return
	end

	button:SetSize(Settings["ab-pet-button-size"], Settings["ab-pet-button-size"])

	local Name = button:GetName()

	if _G[Name .. "AutoCastable"] then
		_G[Name .. "AutoCastable"]:SetSize(Settings["ab-pet-button-size"] * 2 - 4, Settings["ab-pet-button-size"] * 2 - 4)
	end

	local Shine = _G[Name .. "Shine"]

	if Shine then
		Shine:SetSize(Settings["ab-pet-button-size"] - 6, Settings["ab-pet-button-size"] - 6)
		Shine:ClearAllPoints()
		Shine:SetPoint("CENTER", button, 0, 0)
	end

	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	button.icon:SetDrawLayer("BACKGROUND", 7)
	button.icon:SetPoint("TOPLEFT", button, 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, -1, 1)

	if button.IconMask then
		button.IconMask:Hide()
	end

	if button.SlotArt then
		button.SlotArt:Hide()
	end

	if button.SlotBackground then
		button.SlotBackground:SetAlpha(0)
		button.SlotBackground:Hide()
	end

	_G[button:GetName().."NormalTexture"]:SetAlpha(0)
	_G[button:GetName().."NormalTexture"]:Hide()
	button:GetNormalTexture():SetAlpha(0)
	button:GetNormalTexture():Hide()

	button:SetNormalTexture("")

	if button.HotKey then
		button.HotKey:ClearAllPoints()
		button.HotKey:SetPoint("TOPLEFT", button, 2, -3)
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.HotKey:SetJustifyH("LEFT")
		button.HotKey:SetDrawLayer("OVERLAY")
		button.HotKey:SetTextColor(1, 1, 1)
		button.HotKey.SetTextColor = function() end

		local Text = button.HotKey:GetText()

		if Text then
			button.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
		end

		button.HotKey.OST = button.HotKey.SetText
		button.HotKey.SetText = function(self, text)
			self:OST("|cFFFFFFFF" .. text .. "|r")
		end

		if (not Settings["action-bars-show-hotkeys"]) then
			button.HotKey:SetAlpha(0)
		end
	end

	if button.Name then
		button.Name:ClearAllPoints()
		button.Name:SetPoint("BOTTOMLEFT", button, 2, 2)
		button.Name:SetWidth(button:GetWidth() - 4)
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Name:SetJustifyH("LEFT")
		button.Name:SetDrawLayer("OVERLAY")
		button.Name:SetTextColor(1, 1, 1)
		button.Name.SetTextColor = function() end

		if (not Settings["action-bars-show-macro-names"]) then
			button.Name:SetAlpha(0)
		end
	end

	if button.Count then
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, -2, 2)
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Count:SetJustifyH("RIGHT")
		button.Count:SetDrawLayer("OVERLAY")
		button.Count:SetTextColor(1, 1, 1)
		button.Count.SetTextColor = function() end

		if (not Settings["action-bars-show-count"]) then
			button.Count:SetAlpha(0)
		end
	end

	_G[Name.."Flash"]:SetTexture("")

	if _G[Name .. "NormalTexture2"] then
		_G[Name .. "NormalTexture2"]:Hide()
	end

	local Checked = button:GetCheckedTexture()
	Checked:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Checked:SetColorTexture(0.1, 0.9, 0.1, 0.3)
	Checked:SetPoint("TOPLEFT", button, 1, -1)
	Checked:SetPoint("BOTTOMRIGHT", button, -1, 1)

	local Pushed = button:GetPushedTexture()
	Pushed:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
	Pushed:SetPoint("TOPLEFT", button, 1, -1)
	Pushed:SetPoint("BOTTOMRIGHT", button, -1, 1)

	local Highlight = button:GetHighlightTexture()
	Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Highlight:SetColorTexture(1, 1, 1, 0.2)
	Highlight:SetPoint("TOPLEFT", button, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)

	button.Backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.Backdrop:SetPoint("TOPLEFT", button, 0, 0)
	button.Backdrop:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.Backdrop:SetBackdrop(HydraUI.Backdrop)
	button.Backdrop:SetBackdropColor(0, 0, 0)
	button.Backdrop:SetFrameLevel(button:GetFrameLevel() - 1)

	button.Backdrop.Texture = button.Backdrop:CreateTexture(nil, "BORDER")
	button.Backdrop.Texture:SetPoint("TOPLEFT", button.Backdrop, 1, -1)
	button.Backdrop.Texture:SetPoint("BOTTOMRIGHT", button.Backdrop, -1, 1)
	button.Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	button.Backdrop.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))

	button.Styled = true
end

function AB:PetActionBar_Update()
	for i = 1, NUM_PET_ACTION_SLOTS do
		AB.PetBar[i]:SetNormalTexture("")
	end
end

function AB:StanceBar_UpdateState()
	if (not Settings["ab-stance-enable"]) then
		return
	end

	if (GetNumShapeshiftForms() > 0) then
		if (not AB.StanceBar:IsShown()) then
			AB:EnableBar(AB.StanceBar)
		end
	elseif AB.StanceBar:IsShown() then
		AB:DisableBar(AB.StanceBar)
	end
end

function AB:UpdateButtonStatus(check, inrange)
	if (not check or not self.action) then
		return
	end

	local IsUsable, NoMana = IsUsableAction(self.action)

	if IsUsable then
		if (inrange == false) then
			self.icon:SetVertexColor(HydraUI:HexToRGB("FF4C19"))
		else
			self.icon:SetVertexColor(HydraUI:HexToRGB("FFFFFF"))
		end
	elseif NoMana then
		self.icon:SetVertexColor(HydraUI:HexToRGB("7F7FE1"))
	else
		self.icon:SetVertexColor(HydraUI:HexToRGB("4C4C4C"))
	end
end

local BarButtonOnEnter = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(true)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.MaxAlpha / 100)
	self.ParentBar.Fader:Play()
end

local BarButtonOnLeave = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(false)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.ShouldFade and 0 or (self.ParentBar.MaxAlpha / 100))
	self.ParentBar.Fader:Play()
end

local BarOnEnter = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(true)
	end

	self.Fader:SetChange(self.MaxAlpha / 100)
	self.Fader:Play()
end

local BarOnLeave = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(false)
	end

	self.Fader:SetChange(self.ShouldFade and 0 or (self.MaxAlpha / 100))
	self.Fader:Play()
end

local function ResolveAnchorValue(owner, value, gap)
	if value == "UIParent" then
		return HydraUI.UIParent
	elseif value == "gap" then
		return gap
	elseif value == "negativeGap" then
		return -gap
	elseif type(value) == "string" then
		return owner[value]
	end

	return value
end

function AB:CreateActionBar(descriptor)
	if not descriptor.available() then
		return
	end

	local index = descriptor.index
	local key = "ab-bar" .. index
	local anchor = descriptor.anchor
	local gap = Settings[key .. "-button-gap"]
	local bar = CreateFrame("Frame", "HydraUI Action Bar " .. index, HydraUI.UIParent, "SecureHandlerStateTemplate")
	self[descriptor.field] = bar
	self.Bars[#self.Bars + 1] = bar
	bar.Descriptor = descriptor
	bar:SetPoint(anchor[1], ResolveAnchorValue(self, anchor[2], gap), anchor[3], ResolveAnchorValue(self, anchor[4], gap), ResolveAnchorValue(self, anchor[5], gap))
	bar:SetAlpha(Settings[key .. "-alpha"] / 100)
	bar.ShouldFade = Settings[key .. "-hover"]
	bar.MaxAlpha = Settings[key .. "-alpha"]

	local blizzardParent = descriptor.parent and _G[descriptor.parent]
	bar.ButtonParent = blizzardParent
	if blizzardParent then
		blizzardParent:SetParent(bar)
	end

	bar.Fader = LibMotion:CreateAnimation(bar, "Fade")
	bar.Fader:SetDuration(0.15)
	bar.Fader:SetEasing("inout")

	for i = 1, 12 do
		local button = _G[descriptor.prefix .. i]
		self:StyleActionButton(button)
		if descriptor.securePaging then
			button:SetParent(bar)
			bar:SetFrameRef("Button" .. i, button)
		end
		button.ParentBar = bar
		button:HookScript("OnEnter", BarButtonOnEnter)
		button:HookScript("OnLeave", BarButtonOnLeave)
		bar[i] = button
	end

	if Settings[key .. "-hover"] then
		bar:SetAlpha(0)
		bar:SetScript("OnEnter", BarOnEnter)
		bar:SetScript("OnLeave", BarOnLeave)
		for i = 1, #bar do
			bar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(bar, Settings[key .. "-button-max"], Settings[key .. "-per-row"], Settings[key .. "-button-size"], gap)
	if Settings[key .. "-enable"] then
		self:EnableBar(bar)
	else
		self:DisableBar(bar)
	end
	return bar
end

function AB:ConfigureBar1Paging(bar)
	bar.GetSpellFlyoutDirection = function() return "UP" end -- Temp
	bar:Execute([[
		Buttons = table.new()
		for i = 1, 12 do
			table.insert(Buttons, self:GetFrameRef("Button" .. i))
		end
	]])

	if HydraUI.IsVanilla then
		bar:SetAttribute("_onstate-page", [[
			if GetOverrideBarIndex and HasOverrideActionBar() then newstate = GetOverrideBarIndex() or newstate
			elseif HasTempShapeshiftActionBar() then newstate = GetTempShapeshiftBarIndex() or newstate
			elseif HasBonusActionBar() and GetActionBarPage() == 1 then newstate = GetBonusBarIndex() or newstate
			else newstate = GetActionBarPage() or newstate end
			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	else
		bar:SetAttribute("_onstate-page", [[
			if GetVehicleBarIndex and HasVehicleActionBar() then newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar and HasOverrideActionBar() then newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then newstate = GetTempShapeshiftBarIndex()
			elseif HasBonusActionBar() then newstate = GetBonusBarIndex() end
			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [vehicleui] 12; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	end

	if OverrideActionBar then
		self:Disable(OverrideActionBar)
	end
end

local PetBarUpdateGridLayout = function()
	if (not AB.PetBar:IsShown() or InCombatLockdown()) then
		return
	end

	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])
end

-- Pet
function AB:CreatePetBar()
	self.PetBar = CreateFrame("Frame", "HydraUI Pet Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.PetBar:SetPoint("RIGHT", self.Bar5, "LEFT", -Settings["ab-pet-button-gap"], 0)
	self.PetBar:SetAlpha(Settings["ab-pet-alpha"] / 100)
	self.PetBar.ButtonParent = PetActionBar or PetActionBarFrame
	self.PetBar.ShouldFade = Settings["ab-pet-hover"]
	self.PetBar.MaxAlpha = Settings["ab-pet-alpha"]

	self.PetBar.Fader = LibMotion:CreateAnimation(self.PetBar, "Fade")
	self.PetBar.Fader:SetDuration(0.15)
	self.PetBar.Fader:SetEasing("inout")

	if PetActionBar then
		PetActionBar:SetParent(self.PetBar)
		PetActionBar:SetAllPoints(self.PetBar)
		PetActionBar:EnableMouse(false)

		hooksecurefunc(PetActionBar, "UpdateGridLayout", PetBarUpdateGridLayout)
	else
		PetActionBarFrame:SetParent(self.PetBar)

		for i = 1, PetActionBarFrame:GetNumRegions() do
			local Region = select(i, PetActionBarFrame:GetRegions())

			if Region.SetTexture then
				Region:SetTexture(nil)
			end
		end
	end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local Button = _G["PetActionButton" .. i]

		self:StylePetActionButton(Button)

		Button.ParentBar = self.PetBar

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.PetBar[i] = Button
	end

	if Settings["ab-pet-hover"] then
		self.PetBar:SetAlpha(0)
		self.PetBar:SetScript("OnEnter", BarOnEnter)
		self.PetBar:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.PetBar do
			self.PetBar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	if PetActionBar_Update then
		hooksecurefunc("PetActionBar_Update", AB.PetActionBar_Update)
	end

	if Settings["ab-pet-enable"] then
		self:EnableBar(self.PetBar)
	else
		self:DisableBar(self.PetBar)
	end
end

-- Stance
local StanceBarUpdateGridLayout = function()
	if InCombatLockdown() then
		return
	end

	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

function AB:CreateStanceBar()
	self.StanceBar = CreateFrame("Frame", "HydraUI Stance Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.StanceBar:SetPoint("TOPLEFT", HydraUI.UIParent, 10, -10)
	self.StanceBar:SetAlpha(Settings["ab-stance-alpha"] / 100)
	self.StanceBar.ButtonParent = StanceBar or StanceBarFrame
	self.StanceBar.ShouldFade = Settings["ab-stance-hover"]
	self.StanceBar.MaxAlpha = Settings["ab-stance-alpha"]

	self.StanceBar.Fader = LibMotion:CreateAnimation(self.StanceBar, "Fade")
	self.StanceBar.Fader:SetDuration(0.15)
	self.StanceBar.Fader:SetEasing("inout")

	if StanceBar then
		StanceBar:SetParent(self.StanceBar)
	else
		StanceBarFrame:SetParent(self.StanceBar)
	end

	if StanceBar then
		if StanceBar.UpdateGridLayout then
			hooksecurefunc(StanceBar, "UpdateGridLayout", StanceBarUpdateGridLayout)
		end

		for i, button in next, StanceBar.actionButtons do
			self:StyleActionButton(button)

			button.ParentBar = self.StanceBar

			button:HookScript("OnEnter", BarButtonOnEnter)
			button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		--hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if (StanceBarFrame and StanceBarFrame.StanceButtons) then
		StanceBarLeft:SetAlpha(0)
		StanceBarRight:SetAlpha(0)

		for i = 1, NUM_STANCE_SLOTS do
			local Button = StanceBarFrame.StanceButtons[i]

			self:StyleActionButton(Button)

			Button.ParentBar = self.StanceBar

			Button:HookScript("OnEnter", BarButtonOnEnter)
			Button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = Button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if Settings["ab-stance-enable"] then
		self:EnableBar(self.StanceBar)
	else
		self:DisableBar(self.StanceBar)
	end
end

local UpdateZoneAbilityPosition = function(self, anchor, parent)
	--if (not InCombatLockdown()) and (parent and parent ~= AB.ExtraBar) then
	if (parent and parent ~= AB.ExtraBar) then
		self:ClearAllPoints()
		self:SetPoint("CENTER", AB.ExtraBar)
	end
end

local SkinZoneAbilityButtons = function()
	for Button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
		if (not Button.Styled) then
			Button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			Button.NormalTexture:SetAlpha(0)

			Button.Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
			Button.Backdrop:SetPoint("TOPLEFT", Button, -1, 1)
			Button.Backdrop:SetPoint("BOTTOMRIGHT", Button, 1, -1)
			Button.Backdrop:SetBackdrop(HydraUI.Backdrop)
			Button.Backdrop:SetBackdropColor(0, 0, 0)
			Button.Backdrop:SetFrameLevel(Button:GetFrameLevel() - 1)

			Button.Styled = true
		end
	end
end

local UpdateExtraActionParent = function(self, parent)
	if InCombatLockdown() then
		AB.NeedsCombatFix = true

		AB:RegisterEvent("PLAYER_REGEN_ENABLED")
		AB:SetScript("OnEvent", AB.OnEvent)

		return
	end

	if (parent and parent ~= AB.ExtraBar) then
		self:SetParent(AB.ExtraBar)
	end
end

-- Extra Bar
function AB:CreateExtraBar()
	self.ExtraBar = CreateFrame("Frame", "HydraUI Extra Action", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.ExtraBar:SetSize(Settings["ab-extra-button-size"], Settings["ab-extra-button-size"])
	self.ExtraBar:SetPoint("CENTER", HydraUI.UIParent, 0, -220)

	ExtraActionBarFrame:SetParent(HydraUIParent)
	ExtraActionBarFrame:ClearAllPoints()
	ExtraActionBarFrame:SetAllPoints(self.ExtraBar)
	ExtraActionButton1.style:SetAlpha(0)
	ExtraActionBarFrame.ignoreInLayout = true

	--hooksecurefunc(ExtraActionBarFrame, "SetPoint", UpdateExtraActionPosition)
	hooksecurefunc(ExtraActionBarFrame, "SetParent", UpdateExtraActionParent)

	self:StyleActionButton(ExtraActionButton1)

	if HydraUI.IsMists then
		--ExtraActionButton1:SetParent(ExtraActionBarFrame)
		ExtraActionButton1:ClearAllPoints()
		ExtraActionButton1:SetPoint("CENTER", ExtraActionBarFrame)
	end

	if ZoneAbilityFrame then
		ZoneAbilityFrame:ClearAllPoints()
		ZoneAbilityFrame:SetPoint("CENTER", self.ExtraBar)
		ZoneAbilityFrame.Style:SetAlpha(0)
		--ZoneAbilityFrame.ignoreInLayout = true

		hooksecurefunc(ZoneAbilityFrame, "SetPoint", UpdateZoneAbilityPosition)
		hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", SkinZoneAbilityButtons)
	end
end

function AB:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function AB:PLAYER_REGEN_ENABLED()
	if self.NeedsCombatFix then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", nil)

		ExtraActionBarFrame:SetParent(AB.ExtraBar)

		self.NeedsCombatFix = nil
	end
end

function AB:CreateBars()
	self.Bars = {}
	for _, descriptor in ipairs(ActionBarDescriptors) do
		local bar = self:CreateActionBar(descriptor)
		if bar and descriptor.securePaging then
			self:ConfigureBar1Paging(bar)
		end
	end

	if (PetActionBar or PetActionBarFrame) then
		self:CreatePetBar()
	end
	if (StanceBar or StanceBarFrame) then
		self:CreateStanceBar()
	end
	if ExtraActionButton1 then
		self:CreateExtraBar()
	end
	if (MultiCastActionBarFrame and MultiCastActionBarFrame.numActiveSlots and MultiCastActionBarFrame.numActiveSlots > 0) then
		self:StyleTotemBar()
	end
end

-- Black magic, the movers won't budge if a secure frame is positioned on it
local Bar1PreMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	AB.Bar1:Hide()
	AB.Bar1:ClearAllPoints() -- Clear the bar from the mover
	AB.Bar1:SetPoint(A1, HydraUI.UIParent, A2, X, Y)
end

local Bar1PostMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	self:ClearAllPoints()

	AB.Bar1:ClearAllPoints()
	AB.Bar1:SetPoint("CENTER", self, 0, 0) -- Position the frame to the mover again
	AB.Bar1:Show()

	self:SetPoint(A1, HydraUI.UIParent, A2, X, Y)
end

function AB:CreateMovers()
	for _, bar in ipairs(self.Bars) do
		local mover = HydraUI:CreateMover(bar)
		if bar == self.Bar1 then
			self.Bar1Mover = mover
		end
	end

	if self.StanceBar then
		HydraUI:CreateMover(self.StanceBar)
	end

	if self.PetBar then
		HydraUI:CreateMover(self.PetBar)
	end

	if self.TotemBar then
		HydraUI:CreateMover(self.TotemBar)
	end

	if HydraUI.IsMists then -- Temporarily disabling the mover on Mists, causing issues
	--if ExtraActionButton1 then
		self.ExtraBarMover = HydraUI:CreateMover(self.ExtraBar)
	end

	self.Bar1Mover.PreMove = Bar1PreMove
	self.Bar1Mover.PostMove = Bar1PostMove
end

function AB:UpdateFlyout()
	if (not self.FlyoutArrow) then
		return
	end

	if (SpellFlyout and SpellFlyout:IsShown()) then
		SpellFlyout.BgEnd:SetTexture()
		SpellFlyout.HorizBg:SetTexture()
		SpellFlyout.VertBg:SetTexture()
	end

	if self.FlyoutBorder then
		self.FlyoutBorder:SetTexture()
		self.FlyoutBorderShadow:SetTexture()
	end

	for i = 1, 8 do
		local Button = _G["SpellFlyoutButton" .. i]

		if Button then
			AB:StylePetActionButton(Button)

			if Button.GlyphIcon then
				Button.GlyphIcon:ClearAllPoints()
				Button.GlyphIcon:SetPoint("TOPRIGHT", Button, 2, 2)
			end
		end
	end
end

function AB:ShowActionBars()
	-- SetActionBarToggles is a legacy wrapper which only knew about the
	-- original four multi-bars. Set the current CVars directly so bars added
	-- through Edit Mode are enabled as well.
	for i = 1, 7 do
		C_CVar.SetCVar("showMultiActionBar" .. i, "1")
	end
end

local MultiCastSummonSpellButton_Update = function()
	for i = 1, 12 do
		local Slot = _G["MultiCastSlotButton"..i]
		local Button = _G["MultiCastActionButton"..i]
		--self:StyleActionButton(Button)
		Button:ClearAllPoints()

		if (i == 1 or i == 5 or i == 9) then
			Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Button:SetPoint("LEFT", _G["MultiCastActionButton"..i-1], "RIGHT", 2, 0)
		end
	end
end
local MultiCastRecallSpellButton_Update = function()
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastActionButton4, "RIGHT", 2, 0)
end

local MultiCastFlyoutFrame_LoadSlotSpells = function(parent, slotid)
	local FlyoutButton

	for i = 1, 8 do
		FlyoutButton = _G["MultiCastFlyoutButton" .. i]

		if (not FlyoutButton) then
			return
		end

		FlyoutButton:SetNormalTexture("")

		if FlyoutButton.Border then
			FlyoutButton.Border:SetTexture(nil)
		end

		if (FlyoutButton.icon and i ~= 1) then
			FlyoutButton.icon:ClearAllPoints()
			FlyoutButton.icon:SetPoint("TOPLEFT", FlyoutButton, 0, 0)
			FlyoutButton.icon:SetPoint("BOTTOMRIGHT", FlyoutButton, 0, 0)
			FlyoutButton.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end

		if _G[FlyoutButton:GetName() .. "FloatingBG"] then
			self:Disable(_G[FlyoutButton:GetName() .. "FloatingBG"])
		end

		FlyoutButton.Backdrop = CreateFrame("Frame", nil, FlyoutButton, "BackdropTemplate")
		FlyoutButton.Backdrop:SetPoint("TOPLEFT", FlyoutButton, -1, 1)
		FlyoutButton.Backdrop:SetPoint("BOTTOMRIGHT", FlyoutButton, 1, -1)
		FlyoutButton.Backdrop:SetBackdrop(HydraUI.Backdrop)
		FlyoutButton.Backdrop:SetBackdropColor(0, 0, 0)
		FlyoutButton.Backdrop:SetFrameLevel(FlyoutButton:GetFrameLevel() - 1)

		FlyoutButton.Backdrop.Texture = FlyoutButton.Backdrop:CreateTexture(nil, "BACKGROUND")
		FlyoutButton.Backdrop.Texture:SetPoint("TOPLEFT", FlyoutButton.Backdrop, 1, -1)
		FlyoutButton.Backdrop.Texture:SetPoint("BOTTOMRIGHT", FlyoutButton.Backdrop, -1, 1)
		FlyoutButton.Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
		FlyoutButton.Backdrop.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))

		local Highlight = FlyoutButton:GetHighlightTexture()
		Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Highlight:SetColorTexture(1, 1, 1, 0.2)
		Highlight:SetPoint("TOPLEFT", FlyoutButton, 0, 0)
		Highlight:SetPoint("BOTTOMRIGHT", FlyoutButton, 0, 0)

		FlyoutButton:ClearAllPoints()

		if (i == 1) then
			FlyoutButton:SetPoint("BOTTOM", MultiCastFlyoutFrame, 0, 3)
		else
			FlyoutButton:SetPoint("BOTTOM", _G["MultiCastFlyoutButton" .. i-1], "TOP", 0, 4)
		end

		MultiCastFlyoutFrameCloseButton:ClearAllPoints()
		MultiCastFlyoutFrameCloseButton:SetPoint("BOTTOM", MultiCastFlyoutFrame, "TOP", 0, -8)
	end
	hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
	hooksecurefunc("MultiCastFlyoutFrame_LoadSlotSpells", MultiCastFlyoutFrame_LoadSlotSpells)
end

function AB:StyleTotemBar()
	self.TotemBar = CreateFrame("Frame", "HydraUI Totem Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.TotemBar:SetPoint("BOTTOMLEFT", HydraUI.UIParent, 408, 13)
	self.TotemBar:SetSize((30 * 6) + (2 * 5), 30)

	MultiCastActionBarFrame:SetParent(self.TotemBar)
	MultiCastSummonSpellButton:SetParent(self.TotemBar)
	MultiCastSummonSpellButton:ClearAllPoints()
	MultiCastSummonSpellButton:SetPoint("LEFT", self.TotemBar, 0, 0)

	self:StyleActionButton(MultiCastSummonSpellButton)

	MultiCastSummonSpellButtonHighlight:SetTexture(nil)

	for i = 1, 4 do
		local Slot = _G["MultiCastSlotButton"..i]

		Slot:SetParent(MultiCastActionBarFrame)

		Slot.background:ClearAllPoints()
		Slot.background:SetPoint("TOPLEFT", Slot, 1, -1)
		Slot.background:SetPoint("BOTTOMRIGHT", Slot, -1, 1)
		Slot.background:SetDrawLayer("BACKGROUND", -1)
		Slot.overlayTex:SetTexture(nil) -- Colored border

		Slot:ClearAllPoints()

		if (i == 1) then
			Slot:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Slot:SetPoint("LEFT", _G["MultiCastSlotButton"..i-1], "RIGHT", 2, 0)
		end
	end

	for i = 1, 12 do
		local Button = _G["MultiCastActionButton"..i]

		self:StyleActionButton(Button)

		--Button:SetParent(MultiCastActionBarFrame)
		Button:ClearAllPoints()
		Button.overlayTex:SetTexture(nil)

		--Button.Backdrop:SetFrameStrata("BACKGROUND")

		--Button:ClearAllPoints()

		if (i == 1 or i == 5 or i == 9) then
			Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Button:SetPoint("LEFT", _G["MultiCastActionButton"..i-1], "RIGHT", 2, 0)
		end
	end

	MultiCastRecallSpellButton:SetParent(self.TotemBar)
	self:StyleActionButton(MultiCastRecallSpellButton)
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastSlotButton4, "RIGHT", 2, 0)

	MultiCastRecallSpellButtonHighlight:SetTexture(nil)

	MultiCastFlyoutFrame.top:SetTexture(nil)
	MultiCastFlyoutFrame.middle:SetTexture(nil)

	hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
	hooksecurefunc("MultiCastRecallSpellButton_Update", MultiCastRecallSpellButton_Update)
	hooksecurefunc("MultiCastFlyoutFrame_LoadSlotSpells", MultiCastFlyoutFrame_LoadSlotSpells)
	if Settings["ab-totem-enable"] then
		self:EnableBar(self.TotemBar)
	else
		self:DisableBar(self.TotemBar)
	end
end

function AB:Load()
	if (not Settings["ab-enable"]) then
		return
	end

	self.Hide = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	self.Hide:Hide()

	self:ShowActionBars()
	self:Disable(MainMenuBar)
	self:CreateBars()
	self:CreateMovers()

	if MainActionBar then
		MainActionBar:SetAlpha(0)
		MainActionBar:EnableMouse(false)
	end

	hooksecurefunc("ActionButton_UpdateRangeIndicator", AB.UpdateButtonStatus)

	if ActionButton_UpdateFlyout then
		hooksecurefunc("ActionButton_UpdateFlyout", AB.UpdateFlyout)
	end

	if ActionButton_Update then
		hooksecurefunc("ActionButton_Update", AB.UpdateButtonStatus)
	end
end

local UpdateBar = {}
local UpdateEnableBar = {}

local function CreateBarLayoutCallback(descriptor)
	local index, field = descriptor.index, descriptor.field
	local key = "ab-bar" .. index
	return function()
		local bar = AB[field]
		if bar then
			AB:PositionButtons(bar, descriptor.hasButtonMax and Settings[key .. "-button-max"] or #bar, Settings[key .. "-per-row"], Settings[key .. "-button-size"], Settings[key .. "-button-gap"])
		end
	end
end

local function CreateBarEnableCallback(descriptor)
	local field = descriptor.field
	return function(value)
		local bar = AB[field]
		if value then
			AB:EnableBar(bar)
		else
			AB:DisableBar(bar)
		end
	end
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	UpdateBar[descriptor.index] = CreateBarLayoutCallback(descriptor)
	UpdateEnableBar[descriptor.index] = CreateBarEnableCallback(descriptor)
end

local UpdatePetBar = function()
	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	for i = 1, #AB.PetBar do
		local Name = AB.PetBar[i]:GetName()

		if _G[Name .. "AutoCastable"] then
			_G[Name .. "AutoCastable"]:SetSize(Settings["ab-pet-button-size"] * 2 - 4, Settings["ab-pet-button-size"] * 2 - 4)
		end
	end
end

local UpdateStanceBar = function()
	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

local UpdateEnablePetBar = function(value)
	if value then
		AB:EnableBar(AB.PetBar)
	else
		AB:DisableBar(AB.PetBar)
	end
end

local UpdateEnableStanceBar = function(value)
	if value then
		AB:EnableBar(AB.StanceBar)
	else
		AB:DisableBar(AB.StanceBar)
	end
end

local UpdateEnableTotemBar = function(value)
	if value then
		AB:EnableBar(AB.TotemBar)
	else
		AB:DisableBar(AB.TotemBar)
	end
end

function AB:SetButtonRegionAlpha(regionName, alpha, includeAuxiliaryBars)
	for _, bar in ipairs(self.Bars or {}) do
		for i = 1, #bar do
			local region = bar[i][regionName]
			if region then
				region:SetAlpha(alpha)
			end
		end
	end

	if includeAuxiliaryBars then
		local function updateAuxiliaryBar(bar)
			if not bar then
				return
			end
			for i = 1, #bar do
				local region = bar[i][regionName]
				if region then
					region:SetAlpha(alpha)
				end
			end
		end

		updateAuxiliaryBar(self.PetBar)
		updateAuxiliaryBar(self.StanceBar)
		if ExtraActionButton1 and ExtraActionButton1[regionName] then
			ExtraActionButton1[regionName]:SetAlpha(alpha)
		end
	end
end

local UpdateShowHotKey = function(value)
	AB:SetButtonRegionAlpha("HotKey", value and 1 or 0, true)
end
local UpdateShowMacroName = function(value)
	AB:SetButtonRegionAlpha("Name", value and 1 or 0, false)
end
local UpdateShowCount = function(value)
	AB:SetButtonRegionAlpha("Count", value and 1 or 0, false)
end

function AB:UpdateButtonFont(button)
	if button.HotKey then
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.Name then
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.Count then
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.cooldown then
		local Cooldown = button.cooldown:GetRegions()

		if Cooldown then
			HydraUI:SetFontInfo(Cooldown, Settings["ab-font"], Settings["ab-cd-size"], Settings["ab-font-flags"])
		end
	end
end

local UpdateActionBarFont = function()
	for _, bar in ipairs(AB.Bars or {}) do
		for i = 1, #bar do
			AB:UpdateButtonFont(bar[i])
		end
	end

	local auxiliaryBars = { "PetBar", "StanceBar" }
	for _, field in ipairs(auxiliaryBars) do
		local bar = AB[field]
		if bar then
			for i = 1, #bar do
				AB:UpdateButtonFont(bar[i])
			end
		end
	end
end

local function SetBarHover(bar, enabled)
	if not bar then
		return
	end

	bar.ShouldFade = enabled
	bar:SetScript("OnEnter", enabled and BarOnEnter or nil)
	bar:SetScript("OnLeave", enabled and BarOnLeave or nil)
	bar:SetAlpha(enabled and 0 or (bar.MaxAlpha / 100))

	for i = 1, #bar do
		bar[i].cooldown:SetDrawBling(not enabled)
	end
end

local function SetBarAlpha(bar, percent)
	if not bar then
		return
	end

	bar.MaxAlpha = percent
	bar:SetAlpha(bar.ShouldFade and 0 or (percent / 100))
end

local UpdateHoverBar = {}
local UpdateAlphaBar = {}

local function CreateBarHoverCallback(descriptor)
	return function(value)
		SetBarHover(AB[descriptor.field], value)
	end
end

local function CreateBarAlphaCallback(descriptor)
	return function(value)
		SetBarAlpha(AB[descriptor.field], value)
	end
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	UpdateHoverBar[descriptor.index] = CreateBarHoverCallback(descriptor)
	UpdateAlphaBar[descriptor.index] = CreateBarAlphaCallback(descriptor)
end

local UpdatePetHover = function(value)
	SetBarHover(AB.PetBar, value)
end
local UpdateStanceHover = function(value)
	SetBarHover(AB.StanceBar, value)
end
local UpdatePetBarAlpha = function(value)
	SetBarAlpha(AB.PetBar, value)
end
local UpdateStanceBarAlpha = function(value)
	SetBarAlpha(AB.StanceBar, value)
end

GUI:AddWidgets(Language["General"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-enable", Settings["ab-enable"], Language["Enable Action Bar"], Language["Enable action bars module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-show-hotkey", Settings["ab-show-hotkey"], Language["Show Hotkeys"], Language["Display hotkey text on action buttons"], UpdateShowHotKey)
	left:CreateSwitch("ab-show-macro", Settings["ab-show-macro"], Language["Show Macro Names"], Language["Display macro name text on action buttons"], UpdateShowMacroName)
	left:CreateSwitch("ab-show-count", Settings["ab-show-count"], Language["Show Count Text"], Language["Display count text on action buttons"], UpdateShowCount)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("ab-font", Settings["ab-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the action bar buttons"], UpdateActionBarFont, "Font")
	left:CreateSlider("ab-font-size", Settings["ab-font-size"], 8, 42, 1, Language["Font Size"], Language["Set the font size of the action bar buttons"], UpdateActionBarFont)
	left:CreateSlider("ab-cd-size", Settings["ab-cd-size"], 8, 42, 1, Language["Cooldown Font Size"], Language["Set the font size of the action bar cooldowns"], UpdateActionBarFont)
	left:CreateDropdown("ab-font-flags", Settings["ab-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the action bar buttons"], UpdateActionBarFont)
end)

local function AddActionBarWidgets(descriptor)
	if not descriptor.available() then
		return
	end

	local index = descriptor.index
	local key = "ab-bar" .. index
	GUI:AddWidgets(Language["General"], Language[descriptor.label], Language["Action Bars"], function(left, right)
		left:CreateHeader(Language["Enable"])
		left:CreateSwitch(key .. "-enable", Settings[key .. "-enable"], Language["Enable Bar"], Language["Enable action bar " .. index], UpdateEnableBar[index])

		left:CreateHeader(Language["Styling"])
		left:CreateSwitch(key .. "-hover", Settings[key .. "-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateHoverBar[index])
		left:CreateSlider(key .. "-alpha", Settings[key .. "-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateAlphaBar[index])

		right:CreateHeader(Language["Buttons"])
		right:CreateSlider(key .. "-per-row", Settings[key .. "-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[index])
		if descriptor.hasButtonMax then
			right:CreateSlider(key .. "-button-max", Settings[key .. "-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[index])
		end
		right:CreateSlider(key .. "-button-size", Settings[key .. "-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[index])
		right:CreateSlider(key .. "-button-gap", Settings[key .. "-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[index])
	end)
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	AddActionBarWidgets(descriptor)
end

GUI:AddWidgets(Language["General"], Language["Pet Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-pet-enable", Settings["ab-pet-enable"], Language["Enable Bar"], Language["Enable the pet action bar"], UpdateEnablePetBar)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-pet-hover", Settings["ab-pet-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdatePetHover)
	left:CreateSlider("ab-pet-alpha", Settings["ab-pet-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdatePetBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-pet-per-row", Settings["ab-pet-per-row"], 1, NUM_PET_ACTION_SLOTS, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-size", Settings["ab-pet-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-gap", Settings["ab-pet-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdatePetBar)
end)

GUI:AddWidgets(Language["General"], Language["Stance Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-stance-enable", Settings["ab-stance-enable"], Language["Enable Bar"], Language["Enable the stance bar"], UpdateEnableStanceBar)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-stance-hover", Settings["ab-stance-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateStanceHover)
	left:CreateSlider("ab-stance-alpha", Settings["ab-stance-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateStanceBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-stance-per-row", Settings["ab-stance-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-size", Settings["ab-stance-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-gap", Settings["ab-stance-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateStanceBar)
end)

GUI:AddWidgets(Language["General"], Language["Totem Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-totem-enable", Settings["ab-totem-enable"], Language["Enable Bar"], Language["Enable the totem bar"], UpdateEnableTotemBar)
end)
