local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local function Install(UF, Hider)
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

-- These descriptions are shared by every singleton style.  They are deliberately
-- kept outside BuildSingleUnitFrame: spawning several boss frames must not create
-- a new set of anchor/font descriptions for every frame.
local SingleUnitText = {
	left = {point = "LEFT", x = 3, justify = "LEFT"},
	right = {point = "RIGHT", x = -3, justify = "RIGHT"},
}

local function Setting(key)
	return key and Settings[key]
end

local function FamilySetting(config, suffix)
	return Setting(config.settingsPrefix .. suffix)
end

-- Compose the pieces common to non-group unit frames.  Optional or unusual
-- pieces are functions on the descriptor; this keeps knowledge of targets,
-- bosses, etc. out of the factory.
function UF:BuildSingleUnitFrame(frame, unit, config)
	assert(type(config) == "table" and config.settingsPrefix, "single unit frame requires settingsPrefix")

	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnEnter", UnitFrame_OnEnter)
	frame:SetScript("OnLeave", UnitFrame_OnLeave)
	if config.debuffColors then
		frame.colors.debuff = HydraUI.DebuffColors
	end

	self:CreateBackdrop(frame, config.backdropTexture or "Blank", config.backdropLayer or "BACKGROUND")
	if config.threat ~= false then
		self:CreateThreatIndicator(frame, HydraUI.Outline, self.ThreatPostUpdate)
	end

	local healthHeight = FamilySetting(config, "-health-height")
	local healthReverse = FamilySetting(config, "-health-reverse")
	local width = FamilySetting(config, "-width")
	local healthTexture = Setting(config.healthTextureKey)
	local health = self:CreateHealthBar(frame, healthHeight, healthTexture, healthReverse, config.healthOrientation and FamilySetting(config, "-health-orientation"), config.healthBackgroundLayer or "BORDER")
	self:CreateHealAndAbsorbBars(frame, health, width, healthHeight, healthTexture, healthReverse, HydraUI.IsMainline)

	local font, fontSize, fontFlags = Setting(config.fontKey or "unitframes-font"), Setting(config.fontSizeKey or "unitframes-font-size"), Setting(config.fontFlagsKey or "unitframes-font-flags")
	local leftSpec, rightSpec = SingleUnitText.left, SingleUnitText.right
	local healthLeft, healthRight
	if config.healthTags ~= false then
		healthLeft = self:CreateFontString(health, font, fontSize, fontFlags, leftSpec.point, leftSpec.point, leftSpec.x, 0, leftSpec.justify)
		healthRight = self:CreateFontString(health, font, fontSize, fontFlags, rightSpec.point, rightSpec.point, rightSpec.x, 0, rightSpec.justify)
	end

	local r, g, b = HydraUI:HexToRGB(Settings["ui-header-texture-color"])
	frame.colors.health = {r, g, b}
	health.Smooth = true
	if config.healthSmoothKey then
		health.Smooth = Setting(config.healthSmoothKey)
	end
	health.frequentUpdates = config.healthFrequentUpdates
	health.colorTapping = config.colorTapping
	health.colorDisconnected = config.colorDisconnected
	self:SetHealthAttributes(health, FamilySetting(config, "-health-color"))

	local power, powerLeft, powerRight
	if config.power ~= false and (not config.powerEnabledKey or Setting(config.powerEnabledKey)) then
		local powerReverse = config.powerReverse
		if powerReverse == nil then
			powerReverse = FamilySetting(config, "-power-reverse")
		end
		power = self:CreatePowerBar(frame, FamilySetting(config, "-power-height"), Setting(config.powerTextureKey), powerReverse)
		power.frequentUpdates = true
		power.colorReaction = config.powerReaction
		power.Smooth = FamilySetting(config, "-power-smooth")
		self:SetPowerAttributes(power, FamilySetting(config, "-power-color"))
		if config.powerTags then
			powerLeft = self:CreateFontString(power, font, fontSize, fontFlags, leftSpec.point, leftSpec.point, leftSpec.x, 0, leftSpec.justify)
			powerRight = self:CreateFontString(power, font, fontSize, fontFlags, rightSpec.point, rightSpec.point, rightSpec.x, 0, rightSpec.justify)
			frame:Tag(powerLeft, FamilySetting(config, "-power-left"))
			frame:Tag(powerRight, FamilySetting(config, "-power-right"))
		end
	end

	if healthLeft then
		frame:Tag(healthLeft, FamilySetting(config, "-health-left"))
	end
	if healthRight then
		frame:Tag(healthRight, FamilySetting(config, "-health-right"))
	end
	frame.Health, frame.HealthLeft, frame.HealthRight = health, healthLeft, healthRight
	frame.Power, frame.PowerLeft, frame.PowerRight = power, powerLeft, powerRight

	if config.middleTag then
		local middle = self:CreateFontString(health, font, fontSize, fontFlags, "CENTER", "CENTER", 0, 0, "CENTER")
		frame:Tag(middle, config.middleTag)
		frame.HealthMiddle = middle
	end
	if config.mouseoverKey then
		self:CreateMouseoverHighlight(frame, health, "Blank", Setting(config.mouseoverKey))
	end
	if config.raidTarget then
		frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(health, 16)
	end
	if config.range then
		frame.Range = config.range
	end
	if config.portrait then
		config.portrait(self, frame, unit)
	end
	if config.cast then
		config.cast(self, frame, unit)
	end
	if config.auras then
		config.auras(self, frame, unit)
	end
	if config.postBuild then
		config.postBuild(self, frame, unit)
	end
	return frame
end

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

function UF:CreateRaidTargetIndicator(health, size, layer, point, relativePoint, x, y)
	size = size or 16
	local indicator = health:CreateTexture(nil, layer or "OVERLAY")
	indicator:SetSize(size, size)
	indicator:SetPoint(point or "CENTER", health, relativePoint or "TOP", x or 0, y or 0)
	return indicator
end

-- Shared update callbacks operate on existing frames and values so settings
-- changes do not need to allocate per-frame closures or temporary tables.
function UF:SetFrameWidth(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame:SetWidth(value)
end

function UF:SetHealthHeight(unit, value, powerHeight)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame.Health:SetHeight(value)
	frame:SetHeight(value + powerHeight + 3)
end

function UF:SetPowerHeight(unit, value, healthHeight)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame.Power:SetHeight(value)
	frame:SetHeight(healthHeight + value + 3)
end

function UF:ApplyHealthAttributes(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	self:SetHealthAttributes(frame.Health, value)
	frame.Health:ForceUpdate()
end

function UF:ApplyPowerAttributes(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	self:SetPowerAttributes(frame.Power, value)
	frame.Power:ForceUpdate()
end

function UF:SetHealthReverseFill(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	local health = frame.Health
	local healBar = frame.HealBar
	local absorbsBar = frame.AbsorbsBar
	local point = value and "RIGHT" or "LEFT"
	local relativePoint = value and "LEFT" or "RIGHT"

	health:SetReverseFill(value)

	if healBar then
		healBar:SetReverseFill(value)
		healBar:ClearAllPoints()
		healBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end

	if absorbsBar then
		absorbsBar:SetReverseFill(value)
		absorbsBar:ClearAllPoints()
		absorbsBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end
end

function UF:SetPowerReverseFill(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame.Power:SetReverseFill(value)
end

function UF:SetElementEnabled(unit, value, element)
	local frame = HydraUI.UnitFrames[unit]

	if not frame or not frame[element] then
		return
	end

	if value then
		frame:EnableElement(element)
	else
		frame:DisableElement(element)
	end
end

function UF:SetHealthTexture(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	local texture = Assets:GetTexture(value)

	frame.Health:SetStatusBarTexture(texture)
	frame.Health.bg:SetTexture(texture)

	if frame.HealBar then
		frame.HealBar:SetStatusBarTexture(texture)
	end

	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetStatusBarTexture(texture)
	end
end

local function SetHeaderHealthTexture(frame, resolvedTexture)
	frame.Health:SetStatusBarTexture(resolvedTexture)
	frame.Health.bg:SetTexture(resolvedTexture)
	frame.HealBar:SetStatusBarTexture(resolvedTexture)
	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetStatusBarTexture(resolvedTexture)
	end
end

function UF:SetHeaderHealthTexture(header, value)
	if not header then
		return
	end
	local texture = Assets:GetTexture(value)
	self:ForEachHeaderChild(header, SetHeaderHealthTexture, texture)
end

function UF:SetPowerTexture(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	local texture = Assets:GetTexture(value)

	frame.Power:SetStatusBarTexture(texture)
	frame.Power.bg:SetTexture(texture)
end

function UF:SetAuraSize(unit, value, element, width)
	local frame = HydraUI.UnitFrames[unit]

	if not frame or not frame[element] then
		return
	end

	local auras = frame[element]

	auras.size = value
	auras:SetSize(width, value)
	auras:ForceUpdate()
end

function UF:SetAuraPosition(unit, value, element, growthX, companion, companionPosition)
	local frame = HydraUI.UnitFrames[unit]

	if not frame or not frame[element] then
		return
	end

	local auras = frame[element]
	local relativeTo = frame

	if companion and companionPosition == value and frame[companion] then
		relativeTo = frame[companion]
	end

	auras:ClearAllPoints()

	if value == "TOP" then
		auras:SetPoint("BOTTOM", relativeTo, "TOP", 0, 2)
		auras["growth-y"] = "UP"
	else
		auras:SetPoint("TOP", relativeTo, "BOTTOM", 0, -2)
		auras["growth-y"] = "DOWN"
	end

	auras["growth-x"] = growthX
end

-- Setting callbacks are declared once, next to the widgets that use them.  The
-- operation receives an already resolved frame; this is important because a
-- slider can fire many times while it is being dragged.
local UnitOperations = {}

function UnitOperations.Width(UF, frame, value, options)
	frame:SetWidth(value)
	if options and options.widthElements then
		for i = 1, #options.widthElements do
			local element = frame[options.widthElements[i]]
			if element then
				element:SetWidth(value)
			end
		end
	end
end

function UnitOperations.HealthHeight(UF, frame, value, options)
	frame.Health:SetHeight(value)
	frame:SetHeight(value + Settings[options.powerHeight] + 3)
end

function UnitOperations.PowerHeight(UF, frame, value, options)
	frame.Power:SetHeight(value)
	frame:SetHeight(Settings[options.healthHeight] + value + 3)
end

function UnitOperations.HealthColor(UF, frame, value)
	UF:SetHealthAttributes(frame.Health, value)
	frame.Health:ForceUpdate()
end

function UnitOperations.PowerColor(UF, frame, value)
	UF:SetPowerAttributes(frame.Power, value)
	frame.Power:ForceUpdate()
end

function UnitOperations.HealthReverse(UF, frame, value)
	local health = frame.Health
	local point, relativePoint = value and "RIGHT" or "LEFT", value and "LEFT" or "RIGHT"
	health:SetReverseFill(value)
	local healBar = frame.HealBar
	if healBar then
		healBar:SetReverseFill(value)
		healBar:ClearAllPoints()
		healBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end
	local absorbsBar = frame.AbsorbsBar
	if absorbsBar then
		absorbsBar:SetReverseFill(value)
		absorbsBar:ClearAllPoints()
		absorbsBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end
end

function UnitOperations.PowerReverse(UF, frame, value)
	frame.Power:SetReverseFill(value)
end

function UnitOperations.HealthTexture(UF, frame, value)
	local texture = Assets:GetTexture(value)
	frame.Health:SetStatusBarTexture(texture)
	frame.Health.bg:SetTexture(texture)
	if frame.HealBar then
		frame.HealBar:SetStatusBarTexture(texture)
	end
	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetStatusBarTexture(texture)
	end
end

function UnitOperations.PowerTexture(UF, frame, value)
	local texture = Assets:GetTexture(value)
	frame.Power:SetStatusBarTexture(texture)
	frame.Power.bg:SetTexture(texture)
end

function UnitOperations.AuraSize(UF, frame, value, options)
	local auras = frame[options.element]
	if not auras then
		return
	end
	auras.size = value
	auras:SetSize(Settings[options.width], value)
	auras:ForceUpdate()
end

function UnitOperations.AuraSpacing(UF, frame, value, options)
	local auras = frame[options.element]
	if not auras then
		return
	end
	auras.spacing = value
	auras:ForceUpdate()
end

function UnitOperations.ElementEnabled(UF, frame, value, options)
	if not frame[options.component or options.element] then
		return
	end
	if value then
		frame:EnableElement(options.element)
	else
		frame:DisableElement(options.element)
	end
	if options.forceUpdate then
		frame:UpdateAllElements("ForceUpdate")
	end
end

function UnitOperations.AuraPosition(UF, frame, value, options)
	local auras = frame[options.element]
	if not auras then
		return
	end
	local relativeTo = frame
	if options.companion and Settings[options.companionPosition] == value and frame[options.companion] then
		relativeTo = frame[options.companion]
	end
	auras:ClearAllPoints()
	if value == "TOP" then
		auras:SetPoint("BOTTOM", relativeTo, "TOP", 0, 2)
		auras["growth-y"] = "UP"
	else
		auras:SetPoint("TOP", relativeTo, "BOTTOM", 0, -2)
		auras["growth-y"] = "DOWN"
	end
	auras["growth-x"] = options.growthX
end

UF.UnitOperations = UnitOperations

function UF:CreateUnitUpdater(unit, operation, options)
	local update = assert(UnitOperations[operation], "unknown unit-frame update operation: " .. tostring(operation))
	if options and options.count then
		return function(value)
			for i = 1, options.count do
				local frame = HydraUI.UnitFrames[unit .. i]
				if frame then
					update(self, frame, value, options)
				end
			end
		end
	end
	return function(value)
		local frame = HydraUI.UnitFrames[unit]
		if frame then
			update(self, frame, value, options)
		end
	end
end

end

ns.UnitFrameComponentFactory = Install
