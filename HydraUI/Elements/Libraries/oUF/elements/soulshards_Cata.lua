if (select(2, UnitClass("player") ~= "WARLOCK")) then
	return
end

local _, ns = ...
local oUF = ns.oUF

local UnitPower = UnitPower
local ShardsPower = Enum.PowerType.SoulShards
local MAX_SHARDS
local Shards

if SHARD_BAR_NUM_SHARDS then
	MAX_SHARDS = SHARD_BAR_NUM_SHARDS
else
	MAX_SHARDS = UnitPowerMax("player", ShardsPower)
end

local Update = function(self, event, unit)
	if (self.unit ~= unit) then
		return
	end

	local Shards = UnitPower(unit, ShardsPower)

	for i = 1, MAX_SHARDS do
		if (i <= Shards) then
			if (self.SoulShards[i]:GetValue() ~= 1) then
				self.SoulShards[i]:SetAlpha(1)
			end

			self.SoulShards[i]:SetValue(1)
		else
			self.SoulShards[i]:SetValue(0)
			self.SoulShards[i]:SetAlpha(0.2)
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
	local element = self.SoulShards

	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_POWER_FREQUENT", Path)

		element:Show()

		return true
	end
end

local Disable = function(self)
	local element = self.SoulShards

	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_POWER_FREQUENT", Path)
	end
end

oUF:AddElement("Soul Shards", Path, Enable, Disable)