local _, ns = ...
local HydraUI, Language, Assets, Settings = ns:get()

local UF = HydraUI:GetModule("Unit Frames")

function UF:CreateCastbar(frame, name, width, height, point, relativeTo, relativePoint, x, y, texture, backgroundTexture, backgroundTopLeftX, backgroundTopLeftY, backgroundBottomRightX, backgroundBottomRightY, font, fontSize, fontFlags, timeX, textX, textWidth, iconSize, iconX, iconBackground, safeZoneEnabled, showTradeSkills, timeToHold, classColor, postCastStart, postCastStop, postCastFail, postCastInterruptible)
	local castbar = CreateFrame("StatusBar", name, frame)
	castbar:SetSize(width, height)
	castbar:SetPoint(point, relativeTo or frame, relativePoint, x or 0, y or 0)
	castbar:SetStatusBarTexture(Assets:GetTexture(texture))

	local barBackground = castbar:CreateTexture(nil, "ARTWORK")
	barBackground:SetAllPoints(castbar)
	barBackground:SetTexture(Assets:GetTexture(texture))
	barBackground:SetAlpha(0.2)

	local background = castbar:CreateTexture(nil, "BACKGROUND")
	background:SetPoint("TOPLEFT", castbar, backgroundTopLeftX or -1, backgroundTopLeftY or 1)
	background:SetPoint("BOTTOMRIGHT", castbar, backgroundBottomRightX or 1, backgroundBottomRightY or -1)
	background:SetTexture(Assets:GetTexture(backgroundTexture))
	background:SetVertexColor(0, 0, 0)

	local time = self:CreateFontString(castbar, font, fontSize, fontFlags, "RIGHT", "RIGHT", timeX or -3, 0, "RIGHT")
	local text = self:CreateFontString(castbar, font, fontSize, fontFlags, "LEFT", "LEFT", textX or 3, 0, "LEFT")
	text:SetSize(textWidth, fontSize)

	local icon = castbar:CreateTexture(nil, "OVERLAY")
	icon:SetSize(iconSize, iconSize)
	icon:SetPoint("TOPRIGHT", castbar, "TOPLEFT", iconX or -1, 0)
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	if iconBackground then
		local iconBG = castbar:CreateTexture(nil, "BACKGROUND")
		iconBG:SetPoint("TOPLEFT", icon, -1, 1)
		iconBG:SetPoint("BOTTOMRIGHT", icon, 1, -1)
		iconBG:SetTexture(Assets:GetTexture(backgroundTexture))
		iconBG:SetVertexColor(0, 0, 0)
		icon.BG = iconBG
	end

	if safeZoneEnabled then
		local safeZone = castbar:CreateTexture(nil, "ARTWORK")
		safeZone:SetTexture(Assets:GetTexture(texture))
		safeZone:SetVertexColor(0.9, 0.15, 0.15, 0.75)
		castbar.SafeZone = safeZone
	end

	castbar.bg = barBackground
	castbar.Time = time
	castbar.Text = text
	castbar.Icon = icon
	castbar.showTradeSkills = showTradeSkills
	castbar.timeToHold = timeToHold
	castbar.ClassColor = classColor
	castbar.PostCastStart = postCastStart
	castbar.PostCastStop = postCastStop
	castbar.PostCastFail = postCastFail
	castbar.PostCastInterruptible = postCastInterruptible
	frame.Castbar = castbar
	return castbar
end
