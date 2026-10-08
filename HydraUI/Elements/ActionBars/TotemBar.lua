local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:GetModule("Action Bars")
local GUI = HydraUI:GetModule("GUI")

function AB:UpdateFlyout()
	if not self.FlyoutArrow then
		return
	end

	if SpellFlyout and SpellFlyout:IsShown() then
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

	self:EnableAlwaysShowButtons()
end

local function EnableAlwaysShowButtons()
	if InCombatLockdown() then
		return false
	end

	-- Older clients use the CVar; current clients store this per Edit Mode bar.
	if not (C_EditMode and C_EditMode.GetLayouts) then
		if C_CVar.GetCVar("alwaysShowActionBars") ~= nil then
			C_CVar.SetCVar("alwaysShowActionBars", "1")
			return true
		end
		return false
	end

	if not (EditModePresetLayoutManager and Enum.EditModeActionBarSetting
		and Enum.EditModeActionBarSetting.AlwaysShowButtons) then
		return false
	end

	-- Only edit fresh copies, never the tables owned by Blizzard's secure frames.
	local Info = C_EditMode.GetLayouts()
	local Layouts = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
	local PresetCount = #Layouts

	for _, Layout in ipairs(Info.layouts) do
		table.insert(Layouts, Layout)
	end

	local Layout = Layouts[Info.activeLayout]
	if not Layout then
		return false
	end

	local Changed = false
	for _, System in ipairs(Layout.systems) do
		if System.system == Enum.EditModeSystem.ActionBar then
			for _, Setting in ipairs(System.settings) do
				if Setting.setting == Enum.EditModeActionBarSetting.AlwaysShowButtons and Setting.value ~= 1 then
					Setting.value = 1
					Changed = true
				end
			end
		end
	end

	if not Changed then
		return true
	end

	local AddedLayout
	if Info.activeLayout <= PresetCount then
		-- Presets are read-only. Save a character copy rather than changing them.
		local CharacterCount = 0
		for _, SavedLayout in ipairs(Info.layouts) do
			if SavedLayout.layoutType == Enum.EditModeLayoutType.Character then
				CharacterCount = CharacterCount + 1
			end
		end

		if CharacterCount >= Constants.EditModeConsts.EditModeMaxLayoutsPerType then
			HydraUI:print("Select a custom Edit Mode layout to enable Always Show Buttons; character layout slots are full.")
			return true
		end

		Layout = CopyTable(Layout)
		Layout.layoutType = Enum.EditModeLayoutType.Character
		Layout.layoutName = "HydraUI"
		Layout.layoutIndex = nil
		-- Restore the original preset in the save table.
		Layouts[Info.activeLayout] = EditModePresetLayoutManager:GetCopyOfPresetLayouts()[Info.activeLayout]
		table.insert(Layouts, Layout)
		AddedLayout = #Layouts
	end

	Info.layouts = Layouts
	C_EditMode.SaveLayouts(Info)
	if AddedLayout then
		C_EditMode.OnLayoutAdded(AddedLayout, true, false)
	else
		C_EditMode.SetActiveLayout(Info.activeLayout)
	end
	return true
end

function AB:EnableAlwaysShowButtons()
	-- This frame is separate from AB's extra-action-bar combat repair handler.
	local Pending = CreateFrame("Frame")
	local Applying = false
	local function Apply()
		if Applying then
			return
		end
		Applying = true
		local Complete = EnableAlwaysShowButtons()
		Applying = false
		if Complete then
			Pending:UnregisterAllEvents()
			Pending:SetScript("OnEvent", nil)
		end
	end

	Pending:RegisterEvent("PLAYER_ENTERING_WORLD")
	Pending:RegisterEvent("PLAYER_REGEN_ENABLED")
	if C_EditMode and C_EditMode.GetLayouts then
		Pending:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	end
	Pending:SetScript("OnEvent", Apply)
	Apply()
end

local MultiCastSummonSpellButton_Update = function()
	for i = 1, 12 do
		local Slot = _G["MultiCastSlotButton"..i]
		local Button = _G["MultiCastActionButton"..i]
		--self:StyleActionButton(Button)
		Button:ClearAllPoints()

		if i == 1 or i == 5 or i == 9 then
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

		if not FlyoutButton then
			return
		end

		FlyoutButton:SetNormalTexture("")

		if FlyoutButton.Border then
			FlyoutButton.Border:SetTexture(nil)
		end

		if FlyoutButton.icon and i ~= 1 then
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

		if i == 1 then
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

		if i == 1 then
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

		if i == 1 or i == 5 or i == 9 then
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

local UpdateEnableTotemBar = function(value)
	if value then
		AB:EnableBar(AB.TotemBar)
	else
		AB:DisableBar(AB.TotemBar)
	end
end



GUI:AddWidgets(Language["General"], Language["Totem Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-totem-enable", Settings["ab-totem-enable"], Language["Enable Bar"], Language["Enable the totem bar"], UpdateEnableTotemBar)
end)
