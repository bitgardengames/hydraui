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

-- Defaults
Defaults["ab-enable"] = true

Defaults["ab-show-hotkey"] = true
Defaults["ab-show-count"] = true
Defaults["ab-show-macro"] = true

Defaults["ab-font"] = "PT Sans"
Defaults["ab-font-size"] = 12
Defaults["ab-cd-size"] = 18
Defaults["ab-font-flags"] = ""

Defaults["ab-bar1-enable"] = true
Defaults["ab-bar1-hover"] = false
Defaults["ab-bar1-button-size"] = 32
Defaults["ab-bar1-button-gap"] = 2
Defaults["ab-bar1-button-max"] = 12
Defaults["ab-bar1-per-row"] = 12
Defaults["ab-bar1-alpha"] = 100

Defaults["ab-bar2-enable"] = true
Defaults["ab-bar2-hover"] = false
Defaults["ab-bar2-button-size"] = 32
Defaults["ab-bar2-button-gap"] = 2
Defaults["ab-bar2-button-max"] = 12
Defaults["ab-bar2-per-row"] = 12
Defaults["ab-bar2-alpha"] = 100

Defaults["ab-bar3-enable"] = true
Defaults["ab-bar3-hover"] = false
Defaults["ab-bar3-button-size"] = 32
Defaults["ab-bar3-button-gap"] = 2
Defaults["ab-bar3-button-max"] = 12
Defaults["ab-bar3-per-row"] = 12
Defaults["ab-bar3-alpha"] = 100

Defaults["ab-bar4-enable"] = true
Defaults["ab-bar4-hover"] = false
Defaults["ab-bar4-button-size"] = 32
Defaults["ab-bar4-button-gap"] = 2
Defaults["ab-bar4-button-max"] = 12
Defaults["ab-bar4-per-row"] = 1
Defaults["ab-bar4-alpha"] = 100

Defaults["ab-bar5-enable"] = true
Defaults["ab-bar5-hover"] = false
Defaults["ab-bar5-button-size"] = 32
Defaults["ab-bar5-button-gap"] = 2
Defaults["ab-bar5-button-max"] = 12
Defaults["ab-bar5-per-row"] = 1
Defaults["ab-bar5-alpha"] = 100

Defaults["ab-bar6-enable"] = true
Defaults["ab-bar6-hover"] = false
Defaults["ab-bar6-button-size"] = 32
Defaults["ab-bar6-button-gap"] = 2
Defaults["ab-bar6-button-max"] = 12
Defaults["ab-bar6-per-row"] = 1
Defaults["ab-bar6-alpha"] = 100

Defaults["ab-bar7-enable"] = true
Defaults["ab-bar7-hover"] = false
Defaults["ab-bar7-button-size"] = 32
Defaults["ab-bar7-button-gap"] = 2
Defaults["ab-bar7-button-max"] = 12
Defaults["ab-bar7-per-row"] = 1
Defaults["ab-bar7-alpha"] = 100

Defaults["ab-bar8-enable"] = true
Defaults["ab-bar8-hover"] = false
Defaults["ab-bar8-button-size"] = 32
Defaults["ab-bar8-button-gap"] = 2
Defaults["ab-bar8-button-max"] = 12
Defaults["ab-bar8-per-row"] = 1
Defaults["ab-bar8-alpha"] = 100

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

AB.BarButtonOnEnter = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(true)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.MaxAlpha / 100)
	self.ParentBar.Fader:Play()
end

AB.BarButtonOnLeave = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(false)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.ShouldFade and 0 or (self.ParentBar.MaxAlpha / 100))
	self.ParentBar.Fader:Play()
end

AB.BarOnEnter = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(true)
	end

	self.Fader:SetChange(self.MaxAlpha / 100)
	self.Fader:Play()
end

AB.BarOnLeave = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(false)
	end

	self.Fader:SetChange(self.ShouldFade and 0 or (self.MaxAlpha / 100))
	self.Fader:Play()
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
	for _, bar in ipairs(self.Bars or {}) do
		local mover = HydraUI:CreateMover(bar)
		if bar == self.Bar1 then self.Bar1Mover = mover end
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

	if self.Bar1Mover then
		self.Bar1Mover.PreMove = Bar1PreMove
		self.Bar1Mover.PostMove = Bar1PostMove
	end
end


local Subsystems = {}

function AB:RegisterSubsystem(subsystem)
	Subsystems[#Subsystems + 1] = subsystem
end

function AB:ResolveSubsystems()
	local supported = {}
	for i = 1, #Subsystems do
		local subsystem = Subsystems[i]
		if subsystem:IsAvailable() then supported[#supported + 1] = subsystem end
	end
	self.SupportedSubsystems = supported
	return supported
end

function AB:Load()
	if not Settings["ab-enable"] then return end
	self.Hide = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	self.Hide:Hide()
	self:Disable(MainMenuBar)
	local supported = self:ResolveSubsystems()
	for i = 1, #supported do supported[i]:Load() end
	self:CreateMovers()
	if MainActionBar then MainActionBar:SetAlpha(0); MainActionBar:EnableMouse(false) end
end
