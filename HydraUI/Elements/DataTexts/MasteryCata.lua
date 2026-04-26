local HydraUI, Language, Assets, Settings = select(2, ...):get()

local GetMasteryEffect = GetMasteryEffect
local GetCombatRatingBonus = GetCombatRatingBonus
local CR_MASTERY = CR_MASTERY
local Label = STAT_MASTERY

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local OnEnter = function(self)
	self:SetTooltip()

	local _, Class = UnitClass("player")
	local Mastery = GetMastery()
	local Bonus = GetCombatRatingBonus(CR_MASTERY)
	local MasteryKnown = IsSpellKnown(CLASS_MASTERY_SPELLS[Class])
	local TalentTree = GetPrimaryTalentTree()

	local Title = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MASTERY).." "..format("%.2F", Mastery)..FONT_COLOR_CODE_CLOSE

	if (Bonus > 0) then
		Title = Title..HIGHLIGHT_FONT_COLOR_CODE.." ("..format("%.2F", Mastery-Bonus)..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..format("%.2F", Bonus)..FONT_COLOR_CODE_CLOSE..HIGHLIGHT_FONT_COLOR_CODE..")";
	end

	GameTooltip:SetText(Title)


	if (MasteryKnown and TalentTree) then
		local Spell, Spell2 = GetTalentTreeMasterySpells(TalentTree)

		if Spell then
			GameTooltip:AddSpellByID(Spell)
		end

		if Spell2 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddSpellByID(Spell2)
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, GetCombatRating(CR_MASTERY), Bonus), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	else
		GameTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, GetCombatRating(CR_MASTERY), Bonus), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
		GameTooltip:AddLine(" ")

		if MasteryKnown then
			GameTooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true)
		else
			GameTooltip:AddLine(STAT_MASTERY_TOOLTIP_NOT_KNOWN, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, true)
		end
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, event, unit)
	if (unit and unit ~= "player") then
		return
	end

	local Mastery = GetMastery()

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, HydraUI.ValueColor, Mastery)
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

HydraUI:AddDataText("Mastery", OnEnable, OnDisable, Update)