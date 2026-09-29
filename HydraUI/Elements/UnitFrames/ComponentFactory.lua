local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local function Install(UF, Hider)
function UF:SetHealthAttributes(health, value)
	if (value == "CLASS") then
		health.colorClass = true
		health.colorReaction = true
		health.colorHealth = false
	elseif (value == "REACTION") then
		health.colorClass = false
		health.colorReaction = true
		health.colorHealth = false
	elseif (value == "BLIZZARD") then
		health.colorClass = false
		health.colorReaction = false
		health.colorSelection = true
	elseif (value == "THREAT") then
		health.colorClass = true
		health.colorReaction = true
		health.colorSelection = false
		health.colorThreat = true
	elseif (value == "CUSTOM") then
		health.colorClass = false
		health.colorReaction = false
		health.colorHealth = true
	end
end

function UF:SetPowerAttributes(power, value)
	if (value == "POWER") then
		power.colorPower = true
		power.colorClass = false
		power.colorReaction = false
	elseif (value == "REACTION") then
		power.colorPower = false
		power.colorClass = false
		power.colorReaction = true
	elseif (value == "CLASS") then
		power.colorPower = false
		power.colorClass = true
		power.colorReaction = true
	end
end

-- Constructors for the common visual pieces accept resolved, explicit values.
-- Style modules remain responsible for choosing settings and frame-specific behavior.
function UF:CreateBackdrop(frame, texture, layer, relativeTo, colorR, colorG, colorB)
	local backdrop = frame:CreateTexture(nil, layer or "BACKGROUND")
	if relativeTo then backdrop:SetAllPoints(relativeTo) else backdrop:SetAllPoints() end
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
	if orientation then health:SetOrientation(orientation) end

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
	if not enabled then highlight:Hide() end
	return highlight
end

function UF:CreateFontString(parent, font, size, flags, point, relativePoint, x, y, justify, layer)
	local text = parent:CreateFontString(nil, layer or "OVERLAY")
	HydraUI:SetFontInfo(text, font, size, flags)
	text:SetPoint(point, parent, relativePoint or point, x or 0, y or 0)
	text:SetJustifyH(justify or point)
	return text
end

local ComponentDefaults = {
	Portrait = {anchor = {x = 0, y = 0}, background = {visible = true, r = 0, g = 0, b = 0}},
	Castbar = {anchor = {x = 0, y = 0}, bar = {backgroundAlpha = 0.2}, background = {topLeftX = -1, topLeftY = 1, bottomRightX = 1, bottomRightY = -1, r = 0, g = 0, b = 0}, text = {timeX = -3, textX = 3}, icon = {x = -1}},
	AuraContainer = {anchor = {x = 0, y = 0}, callbacks = {}},
}

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
	if config.debuffColors then frame.colors.debuff = HydraUI.DebuffColors end

	self:CreateBackdrop(frame, config.backdropTexture or "Blank", "BACKGROUND")
	if config.threat ~= false then
		self:CreateThreatIndicator(frame, HydraUI.Outline, self.ThreatPostUpdate)
	end

	local healthHeight = FamilySetting(config, "-health-height")
	local healthReverse = FamilySetting(config, "-health-reverse")
	local width = FamilySetting(config, "-width")
	local healthTexture = Setting(config.healthTextureKey)
	local health = self:CreateHealthBar(frame, healthHeight, healthTexture, healthReverse, nil, "BORDER")
	self:CreateHealAndAbsorbBars(frame, health, width, healthHeight, healthTexture, healthReverse, HydraUI.IsMainline)

	local font, fontSize, fontFlags = Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"]
	local leftSpec, rightSpec = SingleUnitText.left, SingleUnitText.right
	local healthLeft = self:CreateFontString(health, font, fontSize, fontFlags, leftSpec.point, leftSpec.point, leftSpec.x, 0, leftSpec.justify)
	local healthRight = self:CreateFontString(health, font, fontSize, fontFlags, rightSpec.point, rightSpec.point, rightSpec.x, 0, rightSpec.justify)

	local r, g, b = HydraUI:HexToRGB(Settings["ui-header-texture-color"])
	frame.colors.health = {r, g, b}
	health.Smooth = true
	health.colorTapping = config.colorTapping
	health.colorDisconnected = config.colorDisconnected
	self:SetHealthAttributes(health, FamilySetting(config, "-health-color"))

	local power, powerLeft, powerRight
	if config.power ~= false then
		local powerReverse = config.powerReverse
		if powerReverse == nil then powerReverse = FamilySetting(config, "-power-reverse") end
		power = self:CreatePowerBar(frame, FamilySetting(config, "-power-height"), Setting(config.powerTextureKey), powerReverse)
		power.frequentUpdates = true
		power.colorReaction = config.powerReaction
		power.Smooth = true
		self:SetPowerAttributes(power, FamilySetting(config, "-power-color"))
		if config.powerTags then
			powerLeft = self:CreateFontString(power, font, fontSize, fontFlags, leftSpec.point, leftSpec.point, leftSpec.x, 0, leftSpec.justify)
			powerRight = self:CreateFontString(power, font, fontSize, fontFlags, rightSpec.point, rightSpec.point, rightSpec.x, 0, rightSpec.justify)
			frame:Tag(powerLeft, FamilySetting(config, "-power-left"))
			frame:Tag(powerRight, FamilySetting(config, "-power-right"))
		end
	end

	frame:Tag(healthLeft, FamilySetting(config, "-health-left"))
	frame:Tag(healthRight, FamilySetting(config, "-health-right"))
	frame.Health, frame.HealthLeft, frame.HealthRight = health, healthLeft, healthRight
	frame.Power, frame.PowerLeft, frame.PowerRight = power, powerLeft, powerRight

	if config.raidTarget then frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(health, 16) end
	if config.range then frame.Range = config.range end
	if config.portrait then config.portrait(self, frame, unit) end
	if config.cast then config.cast(self, frame, unit) end
	if config.auras then config.auras(self, frame, unit) end
	if config.postBuild then config.postBuild(self, frame, unit) end
	return frame
end

-- Copy defaults into a fresh specification so callers can safely reuse their tables.
-- All component validation lives here, keeping constructor failures close to the
-- malformed declaration instead of manifesting as shifted positional arguments.
function UF:NormalizeComponentOptions(kind, options)
	assert(type(options) == "table", kind .. " options must be a table")
	local defaults = assert(ComponentDefaults[kind], "unknown component type: " .. tostring(kind))
	local normalized = {}
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			normalized[key] = {}
			for nestedKey, nestedValue in pairs(value) do normalized[key][nestedKey] = nestedValue end
		else normalized[key] = value end
	end
	for key, value in pairs(options) do
		if type(value) == "table" and type(normalized[key]) == "table" then
			for nestedKey, nestedValue in pairs(value) do normalized[key][nestedKey] = nestedValue end
		else normalized[key] = value end
	end
	assert(type(normalized.size) == "table" and normalized.size.width and normalized.size.height, kind .. " requires size.width and size.height")
	assert(type(normalized.anchor) == "table", kind .. " requires an anchor table")
	if kind ~= "AuraContainer" then assert(normalized.anchor.point, kind .. " requires anchor.point") end
	if kind == "Portrait" then assert(normalized.style, "Portrait requires style") end
	if kind == "Castbar" then
		assert(normalized.bar and normalized.bar.texture, "Castbar requires bar.texture")
		assert(normalized.background and normalized.background.texture, "Castbar requires background.texture")
		assert(normalized.text and normalized.text.font and normalized.text.fontSize, "Castbar requires text.font and text.fontSize")
		assert(normalized.icon and normalized.icon.size, "Castbar requires icon.size")
	end
	return normalized
end

function UF:CreatePortrait(frame, options)
	local spec = self:NormalizeComponentOptions("Portrait", options)
	local style, size, anchor, background = spec.style, spec.size, spec.anchor, spec.background
	local portrait
	if style == "2D" then
		portrait = frame:CreateTexture(nil, "OVERLAY")
		portrait:SetTexCoord(0.12, 0.88, 0.12, 0.88)
	else
		portrait = CreateFrame("PlayerModel", nil, frame)
	end

	portrait:SetSize(size.width, size.height)
	portrait:SetPoint(anchor.point, anchor.relativeTo or frame, anchor.relativePoint, anchor.x, anchor.y)
	if spec.alpha then portrait:SetAlpha(spec.alpha) end

	if style ~= "OVERLAY" then
		local background = frame:CreateTexture(nil, "BACKGROUND")
		background:SetPoint("TOPLEFT", portrait, -1, 1)
		background:SetPoint("BOTTOMRIGHT", portrait, 1, -1)
		background:SetTexture(Assets:GetTexture(spec.background.texture))
		background:SetVertexColor(spec.background.r, spec.background.g, spec.background.b)
		if spec.background.visible == false then background:Hide() end
		portrait.BG = background
	end

	frame.Portrait = portrait
	return portrait
end

function UF:CreateCastbar(frame, options)
	local spec = self:NormalizeComponentOptions("Castbar", options)
	local size, anchor, bar, backgroundSpec, textSpec, iconSpec, callbacks = spec.size, spec.anchor, spec.bar, spec.background, spec.text, spec.icon, spec.callbacks or {}
	local castbar = CreateFrame("StatusBar", spec.name, frame)
	castbar:SetSize(size.width, size.height)
	castbar:SetPoint(anchor.point, anchor.relativeTo or frame, anchor.relativePoint, anchor.x, anchor.y)
	castbar:SetStatusBarTexture(Assets:GetTexture(bar.texture))

	local barBackground = castbar:CreateTexture(nil, "ARTWORK")
	barBackground:SetAllPoints(castbar)
	barBackground:SetTexture(Assets:GetTexture(bar.texture))
	barBackground:SetAlpha(bar.backgroundAlpha)

	local background = castbar:CreateTexture(nil, "BACKGROUND")
	background:SetPoint("TOPLEFT", castbar, backgroundSpec.topLeftX, backgroundSpec.topLeftY)
	background:SetPoint("BOTTOMRIGHT", castbar, backgroundSpec.bottomRightX, backgroundSpec.bottomRightY)
	background:SetTexture(Assets:GetTexture(backgroundSpec.texture))
	background:SetVertexColor(backgroundSpec.r, backgroundSpec.g, backgroundSpec.b)

	local time = UF:CreateFontString(castbar, textSpec.font, textSpec.fontSize, textSpec.fontFlags, "RIGHT", "RIGHT", textSpec.timeX, 0, "RIGHT")
	local text = UF:CreateFontString(castbar, textSpec.font, textSpec.fontSize, textSpec.fontFlags, "LEFT", "LEFT", textSpec.textX, 0, "LEFT")
	text:SetSize(textSpec.width, textSpec.fontSize)

	local icon = castbar:CreateTexture(nil, "OVERLAY")
	icon:SetSize(iconSpec.size, iconSpec.size)
	icon:SetPoint("TOPRIGHT", castbar, "TOPLEFT", iconSpec.x, 0)
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	if iconSpec.background then
		local iconBG = castbar:CreateTexture(nil, "BACKGROUND")
		iconBG:SetPoint("TOPLEFT", icon, -1, 1)
		iconBG:SetPoint("BOTTOMRIGHT", icon, 1, -1)
		iconBG:SetTexture(Assets:GetTexture(backgroundSpec.texture))
		iconBG:SetVertexColor(backgroundSpec.r, backgroundSpec.g, backgroundSpec.b)
		icon.BG = iconBG
	end

	if spec.safeZone then
		local safeZone = castbar:CreateTexture(nil, "ARTWORK")
		safeZone:SetTexture(Assets:GetTexture(bar.texture))
		safeZone:SetVertexColor(0.9, 0.15, 0.15, 0.75)
		castbar.SafeZone = safeZone
	end

	castbar.bg = barBackground
	castbar.Time = time
	castbar.Text = text
	castbar.Icon = icon
	castbar.showTradeSkills = spec.showTradeSkills
	castbar.timeToHold = spec.timeToHold
	castbar.ClassColor = spec.classColor
	castbar.PostCastStart = callbacks.postCastStart
	castbar.PostCastStop = callbacks.postCastStop
	castbar.PostCastFail = callbacks.postCastFail
	castbar.PostCastInterruptible = callbacks.postCastInterruptible
	frame.Castbar = castbar
	return castbar
end

function UF:CreateAuraContainer(frame, options)
	local spec = self:NormalizeComponentOptions("AuraContainer", options)
	local anchor, callbacks = spec.anchor, spec.callbacks
	local auras = CreateFrame("Frame", spec.name, spec.parent or frame)
	auras:SetSize(spec.size.width, spec.size.height)
	if anchor.point then
		auras:SetPoint(anchor.point, anchor.relativeTo or frame, anchor.relativePoint, anchor.x, anchor.y)
	end
	auras.size = spec.iconSize
	auras.spacing = spec.spacing
	auras.num = spec.num
	auras.initialAnchor = spec.initialAnchor
	auras.tooltipAnchor = spec.tooltipAnchor
	auras["growth-x"] = spec.growthX
	auras["growth-y"] = spec.growthY
	auras.PostCreateIcon = callbacks.postCreateIcon
	auras.PostUpdateIcon = callbacks.postUpdateIcon
	auras.CustomFilter = callbacks.customFilter
	auras.onlyShowPlayer = spec.onlyShowPlayer
	auras.showStealableBuffs = spec.showStealableBuffs
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
	if frame.AbsorbsBar then frame.AbsorbsBar:SetStatusBarTexture(resolvedTexture) end
end

function UF:SetHeaderHealthTexture(header, value)
	if not header then return end
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

end

ns.UnitFrameComponentFactory = Install
