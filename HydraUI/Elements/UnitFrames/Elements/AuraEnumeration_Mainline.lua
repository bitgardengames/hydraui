local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

if HydraUI.IsMainline then
	-- Retail's aura table API is selected once while files load.  Shared aura layout code therefore never branches on the client for each icon.
	function UF.EnumerateAuras(unit, filter, visitor)
		-- Restricted aura queries fail before returning data to tainted addon code.
		-- Leave the visitor unused so callers clear their previous icons and timers.
		if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
			return
		end

		for index = 1, 40 do
			-- Individual auras can also be secret outside general restrictions.
			if not (C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret and C_Secrets.ShouldUnitAuraIndexBeSecret(unit, index, filter)) then
				local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)

				if not aura then
					break
				end

				if visitor(index, aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.spellId, aura) == false then
					break
				end
			end
		end
	end
end
