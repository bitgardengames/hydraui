local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "oUF Dispel: unable to locate oUF")

local select = select
local Class = select(2, UnitClass("player"))
local UnitAura = UnitAura
local DebuffTypeColor = DebuffTypeColor
local FindAuraByName = AuraUtil.FindAuraByName

local Priorities = {
	Magic = 4,
	Curse = 3,
	Disease = 2,
	Poison = 1,
}

local Classes = {
	DRUID = {Poison = true, Curse = true},
	MONK = {Magic = false, Poison = true, Disease = true},
	PALADIN = {Magic = true, Poison = true, Disease = true},
	PRIEST = {Magic = true, Disease = true},
	SHAMAN = {Poison = true, Disease = true},
}

local Filter = {}
local Valid = Classes[Class]

local Update = function(self, event, unit)
	if (unit ~= self.unit) then
		return
	end

	local Dispel = self.Dispel
	local Found = false

	for i = 1, 16 do
		local Name, Icon, Count, DispelType = UnitAura(unit, i, "HARMFUL")

		if (not Name) then
			break
		end

		if (DispelType and Valid[DispelType] and DebuffTypeColor[DispelType]) then
			local CurrPrio = Priorities[DispelType]

			if (CurrPrio > Dispel.Prio) then
				Dispel.Prio = CurrPrio
				Dispel.Name = Name
			end

			Found = true
		end
	end

	if (Found and Dispel.Name) then
		local Name, Icon, Count, DispelType, Duration, Expires, Caster, IsStealable, NameplateShowPersonal, SpellID = FindAuraByName(Dispel.Name, unit, "HARMFUL")

		if (not Expires) then
			if Dispel:IsShown() then
				Dispel:Hide()
				Dispel.Prio = 0
				Dispel.Name = nil
			end

			return
		end

		Dispel.SpellID = SpellID
		Dispel.icon:SetTexture(Icon)
		Dispel.cd:SetCooldown(Expires - Duration, Duration)

		if (Count and Count > 1) then
			Dispel.count:SetText(Count)
		else
			Dispel.count:SetText("")
		end

		local Color = DebuffTypeColor[DispelType]

		if Color then
			Dispel:SetBackdropBorderColor(Color.r, Color.g, Color.b)
		else
			Dispel:SetBackdropBorderColor(0.9, 0.1, 0.1) -- User defined debuffs
		end

		if (not Dispel:IsShown()) then
			Dispel:Show()
		end
	elseif Dispel:IsShown() then
		Dispel:Hide()
		Dispel.Prio = 0
		Dispel.Name = nil
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	if (not Valid) then
		if self.Dispel then
			self.Dispel:Hide()
		end

		return
	end

	if self.Dispel then
		self:RegisterEvent("UNIT_AURA", Update)
		self.Dispel.ForceUpdate = ForceUpdate
		self.Dispel.__owner = self
		self.Dispel.Prio = 0

		self.Dispel:Hide()

		return true
	end
end

local Disable = function(self)
	if self.Dispel then
		self:UnregisterEvent("UNIT_AURA", Update)
		self.Dispel:Hide()
		self.Dispel.__owner = nil
	end
end

oUF:AddElement("Dispel", Update, Enable, Disable)