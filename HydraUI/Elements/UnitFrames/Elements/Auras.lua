local _, ns = ...
local HydraUI, Language, Assets, Settings = ns:get()

local UF = HydraUI:GetModule("Unit Frames")

function UF:CreateAuraContainer(frame, name, parent, width, height, point, relativeTo, relativePoint, x, y, iconSize, spacing, num, initialAnchor, tooltipAnchor, growthX, growthY, postCreateIcon, postUpdateIcon, customFilter, onlyShowPlayer, showStealableBuffs)
	local auras = CreateFrame("Frame", name, parent or frame)
	auras:SetSize(width, height)
	if point then
		auras:SetPoint(point, relativeTo or frame, relativePoint, x or 0, y or 0)
	end
	auras.size = iconSize
	auras.spacing = spacing
	auras.num = num
	auras.initialAnchor = initialAnchor
	auras.tooltipAnchor = tooltipAnchor
	auras["growth-x"] = growthX
	auras["growth-y"] = growthY
	auras.PostCreateIcon = postCreateIcon
	auras.PostUpdateIcon = postUpdateIcon
	auras.CustomFilter = customFilter
	auras.onlyShowPlayer = onlyShowPlayer
	auras.showStealableBuffs = showStealableBuffs
	return auras
end
