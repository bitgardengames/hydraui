if (select(2, UnitClass("player") ~= "PALADIN")) then
	return
end

local _, ns = ...
local oUF = ns.oUF

local UnitPower = UnitPower
local HolyPower = Enum.PowerType.HolyPower
local MAX_POWER
local Power

if MAX_HOLY_POWER then
	MAX_POWER = MAX_HOLY_POWER
else
	MAX_POWER = UnitPowerMax("player", HolyPower or 9)
end

local Update = function(self, event, unit)
	if (self.unit ~= unit) then
		return
	end

	local Power = UnitPower(unit, HolyPower)

	for i = 1, MAX_POWER do
		if (i <= Power) then
			if (self.HolyPower[i]:GetValue() ~= 1) then
				self.HolyPower[i]:SetAlpha(1)
			end

			self.HolyPower[i]:SetValue(1)
		else
			self.HolyPower[i]:SetValue(0)
			self.HolyPower[i]:SetAlpha(0.2)
		end
	end
end

local Path = function(self, ...)
	return Update(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	local element = self.HolyPower

	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_POWER_FREQUENT", Path)

		element:Show()

		return true
	end
end

local Disable = function(self)
	local element = self.HolyPower

	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_POWER_FREQUENT", Path)
	end
end

oUF:AddElement("Holy Power", Path, Enable, Disable)