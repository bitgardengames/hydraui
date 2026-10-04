local _, ns = ...
local HydraUI = ns:get()

if not HydraUI.IsMainline then
	local UnitAura = UnitAura
	function ns.UnitFrameEnumerateAuras(unit, filter, visitor)
		for index = 1, 255 do
			local name, icon, count, debuffType, duration, expiration, caster,
				isStealable, _, spellID = UnitAura(unit, index, filter)
			if not name then
				break
			end
			if visitor(index, name, icon, count, debuffType, duration, expiration,
				caster, isStealable, spellID) == false then
				break
			end
		end
	end
end
