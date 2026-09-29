local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()
local AB = HydraUI:GetModule("Action Bars")

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
			AB:Disable(_G[FlyoutButton:GetName() .. "FloatingBG"])
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

	if Settings["ab-totem-enable"] then
		self:EnableBar(self.TotemBar)
	else
		self:DisableBar(self.TotemBar)
	end
end


local LegacyTotem = {}
function LegacyTotem:IsAvailable()
	return MultiCastActionBarFrame and MultiCastActionBarFrame.numActiveSlots and MultiCastActionBarFrame.numActiveSlots > 0
end
function LegacyTotem:Load()
	AB:StyleTotemBar()
	hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
	hooksecurefunc("MultiCastRecallSpellButton_Update", MultiCastRecallSpellButton_Update)
	hooksecurefunc("MultiCastFlyoutFrame_LoadSlotSpells", MultiCastFlyoutFrame_LoadSlotSpells)
end
AB:RegisterSubsystem(LegacyTotem)
