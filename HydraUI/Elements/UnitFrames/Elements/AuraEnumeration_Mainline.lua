local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

if HydraUI.IsMainline then
	-- Retail's aura table API is selected once while files load.  Shared aura layout code therefore never branches on the client for each icon.
	function UF.EnumerateAuras(unit, filter, visitor)
		for index = 1, 255 do
			local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
			if not aura then
				break
			end
			if visitor(index, aura.name, aura.icon, aura.applications, aura.dispelName,
				aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable,
				aura.spellId, aura) == false then
				break
			end
		end
	end
end
