local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local PlayerClass = select(2, UnitClass("player"))

local DispelTypesByClass = {
	DRUID = {Poison = true, Curse = true},
	MONK = {Magic = false, Poison = true, Disease = true},
	PALADIN = {Magic = true, Poison = true, Disease = true},
	PRIEST = {Magic = true, Disease = true},
	SHAMAN = {Poison = true, Disease = true},
}
local DispelPriority = {Magic = 4, Curse = 3, Disease = 2, Poison = 1}
local ValidDispelTypes = DispelTypesByClass[PlayerClass]

local function IsInaccessible(value)
	return HydraUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function UpdateDispel(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local element = frame.Dispel
	local bestPriority, bestIcon, bestCount, bestType, bestDuration, bestExpiration, bestSpellID

	UF.EnumerateAuras(frame.unit, "HARMFUL", function(_, name, icon, count, debuffType, duration, expiration, caster, stealable, spellID)
		if IsInaccessible(debuffType) then
			return
		end

		local priority = debuffType and ValidDispelTypes and ValidDispelTypes[debuffType] and DispelPriority[debuffType]

		if priority and (not bestPriority or priority > bestPriority) then
			bestPriority, bestIcon, bestCount, bestType = priority, icon, count, debuffType
			bestDuration, bestExpiration, bestSpellID = duration, expiration, spellID
		end
	end)

	if not bestPriority then
		element.SpellID = nil
		element:Hide()

		return
	end

	element.SpellID = bestSpellID
	element.icon:SetTexture(bestIcon)

	if not IsInaccessible(bestDuration) and not IsInaccessible(bestExpiration) and bestDuration and bestDuration > 0 and bestExpiration then
		element.cd:SetCooldown(bestExpiration - bestDuration, bestDuration)
		element.cd:Show()
	else
		element.cd:Hide()
	end

	if IsInaccessible(bestCount) then
		element.count:SetText("")
	else
		element.count:SetText(bestCount and bestCount > 1 and bestCount or "")
	end

	local color = HydraUI.DebuffColors[bestType] or HydraUI.DebuffColors.none
	element:SetBackdropBorderColor(unpack(color))
	element:Show()
end

local function EnableDispel(frame)
	local element = frame.Dispel

	if not element or not ValidDispelTypes then
		if element then
			element:Hide()
		end

		return
	end

	element.__owner = frame
	element.ForceUpdate = function()
		UpdateDispel(frame, "ForceUpdate", frame.unit)
	end
	frame:RegisterEvent("UNIT_AURA", UpdateDispel)
	element:Hide()

	return true
end

local function DisableDispel(frame)
	frame:UnregisterEvent("UNIT_AURA", UpdateDispel)
	frame.Dispel:Hide()
end

UF:RegisterElement("Dispel", {
	update = UpdateDispel,
	enable = EnableDispel,
	disable = DisableDispel,
})
