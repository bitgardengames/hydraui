local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:GetModule("Action Bars")

local IsUsableAction = IsUsableAction
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS

local NumPad = KEY_NUMPAD1:gsub("%s%S$", "")
local WheelUp = KEY_MOUSEWHEELUP
local WheelDown = KEY_MOUSEWHEELDOWN
local MouseButton = KEY_BUTTON4:gsub("%s%S$", "")
local MiddleButton = KEY_BUTTON3

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

		if not Settings["ab-show-hotkey"] then
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

		if not Settings["ab-show-macro"] then
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

		if not Settings["ab-show-count"] then
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

		if not Settings["action-bars-show-hotkeys"] then
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

		if not Settings["action-bars-show-macro-names"] then
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

		if not Settings["action-bars-show-count"] then
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
	if not Settings["ab-stance-enable"] then
		return
	end

	if GetNumShapeshiftForms() > 0 then
		if not AB.StanceBar:IsShown() then
			AB:EnableBar(AB.StanceBar)
		end
	elseif AB.StanceBar:IsShown() then
		AB:DisableBar(AB.StanceBar)
	end
end

function AB:UpdateButtonStatus(check, inrange)
	if not check or not self.action then
		return
	end

	local IsUsable, NoMana = IsUsableAction(self.action)

	if IsUsable then
		if inrange == false then
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
