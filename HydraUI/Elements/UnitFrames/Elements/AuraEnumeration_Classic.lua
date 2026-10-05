local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

if not HydraUI.IsMainline then
	local UnitAura = UnitAura

	function UF.EnumerateAuras(unit, filter, visitor)
		for index = 1, 40 do
			local name, icon, count, debuffType, duration, expiration, caster, isStealable, _, spellID = UnitAura(unit, index, filter)

			if not name then
				break
			end

			if visitor(index, name, icon, count, debuffType, duration, expiration, caster, isStealable, spellID) == false then
				break
			end
		end
	end
end