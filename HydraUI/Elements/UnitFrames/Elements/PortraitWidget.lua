local _, ns = ...
local HydraUI, Language, Assets, Settings = ns:get()

local Installers = ns.UnitFrameElementInstallers or {}
ns.UnitFrameElementInstallers = Installers

Installers[#Installers + 1] = function(UF, Hider)
function UF:CreatePortrait(frame, style, width, height, point, relativeTo, relativePoint, x, y, alpha, backgroundTexture, backgroundVisible)
	local portrait
	if style == "2D" then
		portrait = frame:CreateTexture(nil, "OVERLAY")
		portrait:SetTexCoord(0.12, 0.88, 0.12, 0.88)
	else
		portrait = CreateFrame("PlayerModel", nil, frame)
	end

	portrait:SetSize(width, height)
	portrait:SetPoint(point, relativeTo or frame, relativePoint, x or 0, y or 0)
	if alpha then
		portrait:SetAlpha(alpha)
	end

	if style ~= "OVERLAY" then
		local background = frame:CreateTexture(nil, "BACKGROUND")
		background:SetPoint("TOPLEFT", portrait, -1, 1)
		background:SetPoint("BOTTOMRIGHT", portrait, 1, -1)
		background:SetTexture(Assets:GetTexture(backgroundTexture))
		background:SetVertexColor(0, 0, 0)
		if backgroundVisible == false then
			background:Hide()
		end
		portrait.BG = background
	end

	frame.Portrait = portrait
	return portrait
end

end
