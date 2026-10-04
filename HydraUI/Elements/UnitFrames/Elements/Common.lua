local _, ns = ...
local HydraUI, Language, Assets, Settings = ns:get()

local Installers = ns.UnitFrameElementInstallers or {}
ns.UnitFrameElementInstallers = Installers

Installers[#Installers + 1] = function(UF, Hider)
function UF:SetHealthAttributes(health, value)
	if value == "CLASS" then
		health.colorClass = true
		health.colorReaction = true
		health.colorHealth = false
	elseif value == "REACTION" then
		health.colorClass = false
		health.colorReaction = true
		health.colorHealth = false
	elseif value == "BLIZZARD" then
		health.colorClass = false
		health.colorReaction = false
		health.colorSelection = true
	elseif value == "THREAT" then
		health.colorClass = true
		health.colorReaction = true
		health.colorSelection = false
		health.colorThreat = true
	elseif value == "CUSTOM" then
		health.colorClass = false
		health.colorReaction = false
		health.colorHealth = true
	end
end

function UF:SetPowerAttributes(power, value)
	if value == "POWER" then
		power.colorPower = true
		power.colorClass = false
		power.colorReaction = false
	elseif value == "REACTION" then
		power.colorPower = false
		power.colorClass = false
		power.colorReaction = true
	elseif value == "CLASS" then
		power.colorPower = false
		power.colorClass = true
		power.colorReaction = true
	end
end

-- Constructors for the common visual pieces accept resolved, explicit values.
-- Style modules remain responsible for choosing settings and frame-specific behavior.
function UF:CreateBackdrop(frame, texture, layer, relativeTo, colorR, colorG, colorB)
	local backdrop = frame:CreateTexture(nil, layer or "BACKGROUND")
	if relativeTo then
		backdrop:SetAllPoints(relativeTo)
	else
		backdrop:SetAllPoints()
	end
	backdrop:SetTexture(Assets:GetTexture(texture))
	backdrop:SetVertexColor(colorR or 0, colorG or 0, colorB or 0)
	return backdrop
end

function UF:CreateThreatIndicator(frame, backdrop, postUpdate, inset)
	inset = inset or -1
	local threat = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	threat:SetPoint("TOPLEFT", inset, -inset)
	threat:SetPoint("BOTTOMRIGHT", -inset, inset)
	threat:SetBackdrop(backdrop)
	threat.PostUpdate = postUpdate
	frame.ThreatIndicator = threat
	return threat
end

function UF:CreateHealthBar(frame, height, texture, reverseFill, orientation, backgroundLayer, backgroundMultiplier, leftInset, rightInset, topInset)
	leftInset = leftInset or 1
	rightInset = rightInset or 1
	topInset = topInset or 1
	local health = CreateFrame("StatusBar", nil, frame)
	health:SetPoint("TOPLEFT", frame, leftInset, -topInset)
	health:SetPoint("TOPRIGHT", frame, -rightInset, -topInset)
	health:SetHeight(height)
	health:SetStatusBarTexture(Assets:GetTexture(texture))
	health:SetReverseFill(reverseFill)
	if orientation then
		health:SetOrientation(orientation)
	end

	local background = frame:CreateTexture(nil, backgroundLayer or "BORDER")
	background:SetAllPoints(health)
	background:SetTexture(Assets:GetTexture(texture))
	background.multiplier = backgroundMultiplier or 0.2
	health.bg = background
	frame.Health = health
	return health, background
end

local function AnchorPredictionBar(bar, health, reverseFill)
	local point = reverseFill and "RIGHT" or "LEFT"
	local relativePoint = reverseFill and "LEFT" or "RIGHT"
	bar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
end

function UF:CreateHealAndAbsorbBars(frame, health, width, height, texture, reverseFill, createAbsorb)
	local heal = CreateFrame("StatusBar", nil, health)
	heal:SetSize(width, height)
	heal:SetStatusBarTexture(Assets:GetTexture(texture))
	heal:SetStatusBarColor(0, 0.48, 0)
	heal:SetReverseFill(reverseFill)
	heal:SetFrameLevel(health:GetFrameLevel() - 1)
	AnchorPredictionBar(heal, health, reverseFill)
	frame.HealBar = heal

	local absorb
	if createAbsorb then
		absorb = CreateFrame("StatusBar", nil, health)
		absorb:SetSize(width, height)
		absorb:SetStatusBarTexture(Assets:GetTexture(texture))
		absorb:SetStatusBarColor(0, 0.66, 1)
		absorb:SetReverseFill(reverseFill)
		absorb:SetFrameLevel(health:GetFrameLevel() - 2)
		AnchorPredictionBar(absorb, health, reverseFill)
		frame.AbsorbsBar = absorb
	end
	return heal, absorb
end

function UF:CreatePowerBar(frame, height, texture, reverseFill, backgroundLayer, backgroundAlpha, leftInset, rightInset, bottomInset)
	leftInset = leftInset or 1
	rightInset = rightInset or 1
	bottomInset = bottomInset or 1
	local power = CreateFrame("StatusBar", nil, frame)
	power:SetPoint("BOTTOMLEFT", frame, leftInset, bottomInset)
	power:SetPoint("BOTTOMRIGHT", frame, -rightInset, bottomInset)
	power:SetHeight(height)
	power:SetStatusBarTexture(Assets:GetTexture(texture))
	power:SetReverseFill(reverseFill)
	local background = power:CreateTexture(nil, backgroundLayer or "BORDER")
	background:SetAllPoints(power)
	background:SetTexture(Assets:GetTexture(texture))
	background:SetAlpha(backgroundAlpha or 0.2)
	power.bg = background
	frame.Power = power
	return power, background
end

function UF:CreateMouseoverHighlight(frame, health, texture, enabled, colorR, colorG, colorB, sublevel, alpha)
	local highlight = health:CreateTexture(nil, "OVERLAY")
	highlight:SetAllPoints(health)
	highlight:SetTexture(Assets:GetTexture(texture))
	highlight:SetVertexColor(colorR or 0.8, colorG or 0.8, colorB or 0.8)
	highlight:SetAlpha(0)
	highlight:SetDrawLayer("OVERLAY", sublevel or 7)
	frame.Highlight = highlight
	frame:HookScript("OnEnter", function(owner) owner.Highlight:SetAlpha(alpha or 0.15) end)
	frame:HookScript("OnLeave", function(owner) owner.Highlight:SetAlpha(0) end)
	if not enabled then
		highlight:Hide()
	end
	return highlight
end

function UF:CreateFontString(parent, font, size, flags, point, relativePoint, x, y, justify, layer)
	local text = parent:CreateFontString(nil, layer or "OVERLAY")
	HydraUI:SetFontInfo(text, font, size, flags)
	text:SetPoint(point, parent, relativePoint or point, x or 0, y or 0)
	text:SetJustifyH(justify or point)
	return text
end

end
