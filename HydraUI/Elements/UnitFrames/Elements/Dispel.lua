local _, ns = ...
local Handlers = ns.UnitFrameComponentHandlers
local class = select(2, UnitClass("player"))
local validByClass = {
	DRUID={Poison=true,Curse=true}, MONK={Magic=false,Poison=true,Disease=true},
	PALADIN={Magic=true,Poison=true,Disease=true}, PRIEST={Magic=true,Disease=true},
	SHAMAN={Poison=true,Disease=true},
}
local valid, priority = validByClass[class], {Magic=4,Curse=3,Disease=2,Poison=1}

local function Update(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element, bestName, bestPriority = frame.Dispel, nil, 0
	for index = 1, 40 do
		local name, _, _, kind = UnitAura(frame.unit, index, "HARMFUL")
		if not name then
			break
		end
		if kind and valid[kind] and priority[kind] > bestPriority then
			bestName, bestPriority = name, priority[kind]
		end
	end
	if not bestName then element:Hide()
	return end
	local _, icon, count, kind, duration, expires, _, _, _, spellID = AuraUtil.FindAuraByName(bestName, frame.unit, "HARMFUL")
	if not expires then element:Hide()
	return end
	element.SpellID = spellID
	element.icon:SetTexture(icon)
	element.cd:SetCooldown(expires-duration, duration)
	element.count:SetText(count and count > 1 and count or "")
	local color = DebuffTypeColor[kind]
	element:SetBackdropBorderColor(color.r, color.g, color.b)
	element:Show()
end
local function Enable(frame)
	if not frame.Dispel or not valid then if frame.Dispel then
		frame.Dispel:Hide() end return
	end
	frame.Dispel.__owner=frame
	frame.Dispel.ForceUpdate=function() Update(frame,"ForceUpdate",frame.unit) end
	frame:RegisterEvent("UNIT_AURA",Update)
	frame.Dispel:Hide()
	return true
end
local function Disable(frame) frame:UnregisterEvent("UNIT_AURA",Update)
	frame.Dispel:Hide() end
Handlers.Dispel={update=Update,enable=Enable,disable=Disable}
