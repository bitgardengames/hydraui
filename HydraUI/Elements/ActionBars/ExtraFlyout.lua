local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()
local AB = HydraUI:GetModule("Action Bars")

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


local ExtraFlyout = {}
function ExtraFlyout:IsAvailable() return ExtraActionButton1 ~= nil end
function ExtraFlyout:Load()
	AB:CreateExtraBar()
	if ActionButton_UpdateFlyout then hooksecurefunc("ActionButton_UpdateFlyout", AB.UpdateFlyout) end
end
AB:RegisterSubsystem(ExtraFlyout)
