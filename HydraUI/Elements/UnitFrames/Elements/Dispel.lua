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

local function FindHighestPriorityDebuff(unit)
	local bestName, bestPriority

	for index = 1, 40 do
		local name, _, _, debuffType = UnitAura(unit, index, "HARMFUL")

		if not name then
			break
		end

		local priority = debuffType and ValidDispelTypes[debuffType] and DispelPriority[debuffType]

		if priority and (not bestPriority or priority > bestPriority) then
			bestName, bestPriority = name, priority
		end
	end

	return bestName
end

local function UpdateDispel(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local element = frame.Dispel
	local name = FindHighestPriorityDebuff(frame.unit)

	if not name then
		element:Hide()

		return
	end

	local _, icon, count, debuffType, duration, expiration, _, _, _, spellID = AuraUtil.FindAuraByName(name, frame.unit, "HARMFUL")

	if not expiration then
		element:Hide()

		return
	end

	element.SpellID = spellID
	element.icon:SetTexture(icon)
	element.cd:SetCooldown(expiration - duration, duration)
	element.count:SetText(count and count > 1 and count or "")

	local color = DebuffTypeColor[debuffType]
	element:SetBackdropBorderColor(color.r, color.g, color.b)
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
