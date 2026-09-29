local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local oUF = ns.oUF or oUF

local select = select
local find = string.find
local GetTime = GetTime
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local Class, Colors, _

Defaults["unitframes-only-player-debuffs"] = false
Defaults["unitframes-show-player-buffs"] = true
Defaults["unitframes-show-player-debuffs"] = true
Defaults["unitframes-show-target-buffs"] = true
Defaults["unitframes-show-target-debuffs"] = true
Defaults["unitframes-show-druid-mana"] = true
Defaults["unitframes-font"] = "Roboto"
Defaults["unitframes-font-size"] = 12
Defaults["unitframes-font-flags"] = ""
Defaults["unitframes-display-aura-timers"] = true

local UF = HydraUI:NewModule("Unit Frames")

local function ForEachChild(operation, value, descriptor, child, ...)
	if not child then
		return
	end

	operation(child, value, descriptor)

	return ForEachChild(operation, value, descriptor, ...)
end

-- Secure group headers return their children as multiple values. Pass those
-- values through the iterator so each invocation uses the header's current
-- children without allocating a temporary table.
function UF:ForEachHeaderChild(header, operation, value, descriptor)
	if not header then
		return
	end

	ForEachChild(operation, value, descriptor, header:GetChildren())
end

HydraUI.UnitFrames = {}
HydraUI.StyleFuncs = {}

local Hider = CreateFrame("Frame", nil, HydraUI.UIParent, "SecureHandlerStateTemplate")
Hider:Hide()

function UF:GetRoleTexCoords(role)
	if (role == "TANK") then
		return 0, 19/64, 22/64, 41/64
	elseif (role == "HEALER") then
		return 20/64, 39/64, 1/64, 20/64
	elseif (role == "DAMAGER") then
		return 20/64, 39/64, 22/64, 41/64
	end
end

if CompactRaidFrameManager then
	CompactRaidFrameManager:SetParent(UIParent)
end

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

local UnregisterAuraTimer = function(button)
	HydraUI.DurationText:Unregister(button)
	button.LastAuraTime = nil

	if button.Time then
		button.Time:Hide()
	end

end

local function GetAuraRemaining(button, now)
	return button.Expiration and (button.Expiration - now)
end

local function FormatAuraRemaining(remaining)
	return HydraUI:AuraFormatTime(remaining)
end

local function ClearAuraTimer(button)
	button.LastAuraTime = nil
	button.Time:Hide()
end

local RegisterAuraTimer = function(button, expiration)
	button.Expiration = expiration
	button.Time:Show()
	HydraUI.DurationText:Register(button, button.Time, FormatAuraRemaining, GetAuraRemaining, ClearAuraTimer)
end

UF.ThreatPostUpdate = function(self, unit, status, r, g, b)
	if (status and status > 0) then
		self:SetBackdropBorderColor(r, g, b)
	end
end

UF.NPThreatPostUpdate = function(self, unit, status, r, g, b)
	if (status and status > 0) then
		self.Top:SetVertexColor(r, g, b)
		self.Bottom:SetVertexColor(r, g, b)
	end
end

if HydraUI.IsVanilla then
	local LCD = LibStub("LibClassicDurations")
	local UnitAura = UnitAura

	LCD:Register("HydraUI")

	UF.PostUpdateIcon = function(self, unit, button, index, position, duration, expiration, debuffType, isStealable)
		UnregisterAuraTimer(button)

		local Name, _, _, _, Duration, Expiration, Caster, _, _, SpellID = UnitAura(unit, index, button.filter)
		local DurationNew, ExpirationNew = LCD:GetAuraDurationByUnit(unit, SpellID, Caster, Name)

		if (Duration == 0 and DurationNew) then
			Duration = DurationNew
			Expiration = ExpirationNew
		end

		if button.cd then
			if (Duration and Duration > 0) then
				button.cd:SetCooldown(Expiration - Duration, Duration)
				button.cd:Show()
			else
				button.cd:Hide()
			end
		end

		if debuffType then
			local Color = self.__owner.colors.debuff[debuffType]

			button.DebuffType:SetBackdropBorderColor(Color[1], Color[2], Color[3])
			button.DebuffType:Show()
		else
			button.DebuffType:Hide()
		end

		if ((button.filter == "HARMFUL") and (not button.isPlayer) and debuffType) then
			button.icon:SetDesaturated(true)
		else
			button.icon:SetDesaturated(false)
		end

		if (Expiration and Expiration ~= 0) then
			RegisterAuraTimer(button, Expiration)
		end
	end
else
	UF.PostUpdateIcon = function(self, unit, button, index, position, duration, expiration, debuffType, isStealable)
		UnregisterAuraTimer(button)

		if button.cd then
			if (duration and duration > 0) then
				button.cd:SetCooldown(expiration - duration, duration)
				button.cd:Show()
			else
				button.cd:Hide()
			end
		end

		if (debuffType and debuffType ~= "") then
			local Color = self.__owner.colors.debuff[debuffType]

			button.DebuffType:SetBackdropBorderColor(Color[1], Color[2], Color[3])
			button.DebuffType:Show()
		else
			button.DebuffType:Hide()
		end

		if ((button.filter == "HARMFUL") and (not button.isPlayer) and debuffType) then
			button.icon:SetDesaturated(true)
		else
			button.icon:SetDesaturated(false)
		end

		if (expiration and expiration ~= 0) then
			RegisterAuraTimer(button, expiration)
		end
	end
end

local CancelAuraOnMouseUp = function(aura, button)
	if ((button ~= "RightButton") or InCombatLockdown()) then
		return
	end

	CancelUnitBuff("player", aura.ID)
end

UF.PostCreateIcon = function(unit, button)
	UnregisterAuraTimer(button)
	button:HookScript("OnHide", UnregisterAuraTimer)

	local ID = button:GetName():match("%d+")

	if ID then
		button.ID = tonumber(ID)
		button:SetScript("OnMouseUp", CancelAuraOnMouseUp)
	end

	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetPoint("TOPLEFT", button, 0, 0)
	button.bg:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.bg:SetColorTexture(0, 0, 0)

	button.cd.noOCC = true
	button.cd.noCooldownCount = true
	button.cd:ClearAllPoints()
	button.cd:SetPoint("TOPLEFT", button, 1, -1)
	button.cd:SetPoint("BOTTOMRIGHT", button, -1, 1)
	button.cd:SetHideCountdownNumbers(true)
	button.cd:SetReverse(true)

	button.icon:SetPoint("TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	button.count:SetPoint("BOTTOMRIGHT", 1, 2)
	button.count:SetJustifyH("RIGHT")
	HydraUI:SetFontInfo(button.count, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")

	button.Time = button.cd:CreateFontString(nil, "OVERLAY")
	HydraUI:SetFontInfo(button.Time, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")
	button.Time:SetPoint("TOPLEFT", -1, -1)
	button.Time:SetJustifyH("LEFT")

	button.DebuffType = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.DebuffType:SetPoint("TOPLEFT", 1, -1)
	button.DebuffType:SetPoint("BOTTOMRIGHT", -1, 1)
	button.DebuffType:SetBackdrop(HydraUI.Outline)
	button.DebuffType:SetFrameLevel(button:GetFrameLevel() + 3)

	if (not Settings["unitframes-display-aura-timers"]) then
		button.Time:SetParent(Hider)
	end
end

UF.PostCastStart = function(self, unit)
	if self.notInterruptible then
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
	elseif (self.ClassColor and UnitIsPlayer(unit)) then
		_, Class = UnitClass(unit)

		if Class then
			Colors = HydraUI.ClassColors[Class]

			self:SetStatusBarColor(Colors[1], Colors[2], Colors[3])
			self.bg:SetVertexColor(Colors[1], Colors[2], Colors[3])
		else
			self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
			self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		end
	else
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
	end
end

UF.PostCastInterruptible = function(self)
	if self.notInterruptible then
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
	elseif (self.ClassColor and UnitIsPlayer(unit)) then
		_, Class = UnitClass(unit)

		if Class then
			Colors = HydraUI.ClassColors[Class]

			self:SetStatusBarColor(Colors[1], Colors[2], Colors[3])
			self.bg:SetVertexColor(Colors[1], Colors[2], Colors[3])
		else
			self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
			self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		end
	else
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
	end
end

UF.PostCastStop = function(self)
	self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-stopped"]))
	self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-stopped"]))
end

UF.PostCastFail = function(self)
	self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-interrupted"]))
	self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-interrupted"]))
end

local ActiveTotemBars = {}
local TotemUpdater = CreateFrame("Frame")

TotemUpdater:Hide()

local TotemOnUpdate = function(self)
	local CurrentTime = GetTime()

	for Bar in pairs(ActiveTotemBars) do
		local Time = Bar.Duration - (CurrentTime - Bar.Start)

		Bar:SetValue(Time)

		if (Time < 0) then
			ActiveTotemBars[Bar] = nil
			Bar:Hide()
		end
	end

	if (not next(ActiveTotemBars)) then
		self:SetScript("OnUpdate", nil)
		self:Hide()
	end
end

UF.PostUpdateTotems = function(self, slot, havetotem, name, start, duration, icon)
	if (not self[slot]) then
		return
	end

	if (start and duration > 0) then
		local Bar = self[slot].Bar

		if (not Bar) then
			return
		end

		Bar:SetMinMaxValues(0, duration)
		Bar:SetValue(duration - (GetTime() - start))
		Bar.Duration = duration
		Bar.Start = start
		Bar:Show()
		ActiveTotemBars[Bar] = true

		if (not TotemUpdater:GetScript("OnUpdate")) then
			TotemUpdater:SetScript("OnUpdate", TotemOnUpdate)
			TotemUpdater:Show()
		end
	else
		local Bar = self[slot].Bar

		ActiveTotemBars[Bar] = nil

		if (not next(ActiveTotemBars)) then
			TotemUpdater:SetScript("OnUpdate", nil)
			TotemUpdater:Hide()
		end

		Bar:Hide()
	end
end

UF.AuraOffsets = {
	TOPLEFT = {6, 0},
	TOPRIGHT = {-6, 0},
	BOTTOMLEFT = {6, 0},
	BOTTOMRIGHT = {-6, 0},
	LEFT = {6, 0},
	RIGHT = {-6, 0},
	TOP = {0, 0},
	BOTTOM = {0, 0},
}

if HydraUI.IsMainline then
	UF.BuffIDs = {
		["DRUID"] = {
			{774, "TOPLEFT", {0.8, 0.4, 0.8}},      -- Rejuvenation
			{155777, "LEFT", {0.8, 0.4, 0.8}},      -- Germination
			{8936, "TOPRIGHT", {0.2, 0.8, 0.2}},    -- Regrowth
			{33763, "BOTTOMLEFT", {0.4, 0.8, 0.2}}, -- Lifebloom
			{48438, "BOTTOMRIGHT", {0.8, 0.4, 0}},  -- Wild Growth
			{102342, "RIGHT", {0.8, 0.2, 0.2}},     -- Ironbark
			{102351, "BOTTOM", {0.84, 0.92, 0.77}}, -- Cenarion Ward
			{102352, "BOTTOM", {0.84, 0.92, 0.77}}, -- Cenarion Ward (Heal)
		},

		["MONK"] = {
			{119611, "TOPLEFT", {0.32, 0.89, 0.74}},  -- Renewing Mist
			{116849, "TOPRIGHT", {0.2, 0.8, 0.2}},	  -- Life Cocoon
			{124682, "BOTTOMLEFT", {0.9, 0.8, 0.48}}, -- Enveloping Mist
			{124081, "BOTTOMRIGHT", {0.7, 0.4, 0}},   -- Zen Sphere
			{115175, "LEFT", {0.24, 0.87, 0.49}},     -- Soothing Mist
		},

		["PALADIN"] = {
			{53563, "TOPRIGHT", {0.7, 0.3, 0.7}},	        -- Beacon of Light
			{156910, "TOPRIGHT", {0.7, 0.3, 0.7}},	        -- Beacon of Faith
			{200025, "TOPRIGHT", {0.7, 0.3, 0.7}},	        -- Beacon of Virtue
			{287280, "BOTTOMLEFT", {0.99, 0.75, 0.36}},	    -- Glimmer of Light
			{1022, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},-- Blessing of Protection
			{1044, "BOTTOMRIGHT", {0.89, 0.45, 0}, true},	-- Blessing of Freedom
			--{1038, "BOTTOMRIGHT", {0.93, 0.75, 0}, true},	-- Blessing of Salvation
			{6940, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},	-- Blessing of Sacrifice
			--{223306, "TOPLEFT", {0.81, 0.85, 0.1}},	    -- Bestow Faith
		},

		["PRIEST"] = {
			{41635, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},  -- Prayer of Mending
			{139, "BOTTOMLEFT", {0.4, 0.7, 0.2}},     -- Renew
			{17, "TOPLEFT", {0.81, 0.85, 0.1}, true}, -- Power Word: Shield
			{194384, "TOPRIGHT", {1, 0, 0}},          -- Atonement

			{33206, "BOTTOMLEFT", {0.93, 0.91, 0.87}}, -- Pain Suppression
			{121536, "BOTTOMRIGHT", {0.98, 0.76, 0.03}}, -- Angelic Feather
		},

		["SHAMAN"] = {
			{61295, "TOPLEFT", {0.7, 0.3, 0.7}},   -- Riptide
			{974, "TOPRIGHT", {0.73, 0.61, 0.33}}, -- Earth Shield
		},

		["EVOKER"] = { -- Requires ID's

		}
	}
elseif (HydraUI.IsCata or HydraUI.IsMists) then
	UF.BuffIDs = {
		["DRUID"] = {
			-- Regrowth
			{8936, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8938, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8939, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8940, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8941, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9750, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9856, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9857, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9858, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{26980, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{48442, "TOPRIGHT", {0.2, 0.8, 0.2}}, -- rank 11
			{48443, "TOPRIGHT", {0.2, 0.8, 0.2}}, -- rank 12

			-- Rejuvenation
			{774, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1058, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1430, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2090, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2091, "TOPLEFT", {0.8, 0.4, 0.8}},
			{3627, "TOPLEFT", {0.8, 0.4, 0.8}},
			{8910, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9839, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9840, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9841, "TOPLEFT", {0.8, 0.4, 0.8}},
			{25299, "TOPLEFT", {0.8, 0.4, 0.8}},
			{26981, "TOPLEFT", {0.8, 0.4, 0.8}},
			{26982, "TOPLEFT", {0.8, 0.4, 0.8}},
			{48440, "TOPLEFT", {0.8, 0.4, 0.8}}, -- rank 14
			{48441, "TOPLEFT", {0.8, 0.4, 0.8}}, -- rank 15

			-- Lifebloom
			{33763, "BOTTOMLEFT", {0.4, 0.8, 0.2}},
			{48450, "BOTTOMLEFT", {0.4, 0.8, 0.2}}, -- rank 2
			{48451, "BOTTOMLEFT", {0.4, 0.8, 0.2}}, -- rank 3
		},

		["PALADIN"] = {
			-- Beacon of Light
			{53563, "TOPRIGHT", {0.81, 0.85, 0.1}, true},

			-- Sacred Shield
			{53601, "TOPLEFT", {0.80, 0.61, 0.11}, true},

			-- Hand of Freedom
			{1044, "BOTTOMRIGHT", {0.89, 0.45, 0}, true},

			-- Hand of Protection
			{1022, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{5599, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{10278, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},

			-- Hand of Sacrifice
			{6940, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{20729, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{27147, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{27148, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
		},

		["PRIEST"] = {
			-- Prayer of Mending
			{33076, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{351575, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{41635, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{41637, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{44583, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{44586, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{46045, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{48112, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{48113, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},

			-- Power Word: Shield
			{17, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{592, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{600, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{3747, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6065, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6066, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10898, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10899, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10900, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10901, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{25217, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{25218, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{48065, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{48066, "TOPLEFT", {0.81, 0.85, 0.1}, true},

			-- Renew
			{139, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6074, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6075, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6076, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6077, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6078, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10927, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10928, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10929, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25315, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25221, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25222, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{48067, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{48068, "BOTTOMLEFT", {0.4, 0.7, 0.2}},

			-- Weakened Soul
			{6788, "TOPRIGHT", {0.9, 0.1, 0.1}, true},
		},

		["SHAMAN"] = {
			-- Earth Shield
			{974, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{32593, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{32594, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{49283, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{49284, "TOPRIGHT", {0.73, 0.61, 0.33}},

			-- Riptide
			{61295, "TOPLEFT", {0, 0.4, 0.6}},
			{61299, "TOPLEFT", {0, 0.4, 0.6}},
			{61300, "TOPLEFT", {0, 0.4, 0.6}},
			{61301, "TOPLEFT", {0, 0.4, 0.6}},
		},
	}
else -- Classic
	UF.BuffIDs = {
		["DRUID"] = {
			-- Regrowth
			{8936, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8938, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8939, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8940, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8941, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9750, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9856, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9857, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9858, "TOPRIGHT", {0.2, 0.8, 0.2}},

			-- Rejuvenation
			{774, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1058, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1430, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2090, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2091, "TOPLEFT", {0.8, 0.4, 0.8}},
			{3627, "TOPLEFT", {0.8, 0.4, 0.8}},
			{8910, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9839, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9840, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9841, "TOPLEFT", {0.8, 0.4, 0.8}},
			{25299, "TOPLEFT", {0.8, 0.4, 0.8}},
		},

		["PALADIN"] = {
			-- Blessing of Freedom
			{1044, "BOTTOMRIGHT", {0.89, 0.45, 0}, true},

			-- Blessing of Protection
			{1022, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{5599, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{10278, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},

			-- Blessing of Sacrifice
			{6940, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{20729, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
		},

		["PRIEST"] = {
			-- Power Word: Shield
			{17, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{592, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{600, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{3747, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6065, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6066, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10898, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10899, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10900, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10901, "TOPLEFT", {0.81, 0.85, 0.1}, true},

			-- Renew
			{139, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6074, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6075, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6076, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6077, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6078, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10927, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10928, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10929, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25315, "BOTTOMLEFT", {0.4, 0.7, 0.2}},

			-- Weakened Soul
			{6788, "TOPRIGHT", {0.9, 0.1, 0.1}, true},
		},
	}
end

UF.PostCreateAuraWatchIcon = function(auras, icon)
	icon.icon:SetPoint("TOPLEFT", 1, -1)
	icon.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	icon.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	icon.icon:SetDrawLayer("ARTWORK")

	icon.bg = icon:CreateTexture(nil, "BORDER")
	icon.bg:SetPoint("TOPLEFT", icon, -1, 1)
	icon.bg:SetPoint("BOTTOMRIGHT", icon, 1, -1)
	icon.bg:SetTexture(0, 0, 0)

	icon.overlay:SetTexture()
end

local Style = function(self, unit)
	if HydraUI.StyleFuncs[unit] then
		HydraUI.StyleFuncs[unit](self, unit)
	elseif (find(unit, "raid") and Settings["raid-enable"]) then
		HydraUI.StyleFuncs["raid"](self, unit)
	elseif (find(unit, "raidpet") and Settings["raid-pets-enable"]) then
		HydraUI.StyleFuncs["raidpet"](self, unit)
	elseif (find(unit, "partypet") and Settings["party-enable"] and Settings["party-pets-enable"]) then
		HydraUI.StyleFuncs["partypet"](self, unit)
	elseif (find(unit, "party") and not find(unit, "pet") and Settings["party-enable"]) then
		HydraUI.StyleFuncs["party"](self, unit)
	elseif (find(unit, "nameplate") and Settings["nameplates-enable"]) then
		HydraUI.StyleFuncs["nameplate"](self, unit)
	elseif find(unit, "boss%d") then
		HydraUI.StyleFuncs["boss"](self, unit)
	end
end

local UpdateShowPlayerBuffs = function(value)
	if HydraUI.UnitFrames["player"] then
		if value then
			HydraUI.UnitFrames["player"]:EnableElement("Auras")
			HydraUI.UnitFrames["player"]:UpdateAllElements("ForceUpdate")
		else
			HydraUI.UnitFrames["player"]:DisableElement("Auras")
		end
	end
end

local UpdateRaidSortingMethod = function(value)
	if (value == "CLASS") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "DEATHKNIGHT,DEMONHUNTER,DRUID,HUNTER,MAGE,MONK,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "CLASS")
	elseif (value == "ROLE") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "ASSIGNEDROLE")
	elseif (value == "NAME") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", nil)
	elseif (value == "MTMA") then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,NONE")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "ROLE")
	else -- GROUP
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "INDEX")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "GROUP")
	end
end

oUF:RegisterStyle("HydraUI", Style)

local SingletonUnits = {
	{unit = "player", globalName = "HydraUI Player", enabled = "player-enable", dimensions = {width = "unitframes-player-width", health = "unitframes-player-health-height", power = "unitframes-player-power-height"}, defaultAnchor = {"TOPRIGHT", "CENTER", -68, -281}, postSpawn = "ConfigurePlayer"},
	{unit = "target", globalName = "HydraUI Target", enabled = "target-enable", dimensions = {width = "unitframes-target-width", health = "unitframes-target-health-height", power = "unitframes-target-power-height"}, defaultAnchor = {"TOPLEFT", "CENTER", 68, -281}, postSpawn = "ConfigureTarget"},
	{unit = "targettarget", globalName = "HydraUI Target Target", enabled = "tot-enable", dimensions = {width = "unitframes-targettarget-width", health = "unitframes-targettarget-health-height", power = "unitframes-targettarget-power-height"}, defaultAnchor = {"TOPRIGHT", "CENTER", 68, -341}, postSpawn = "ConfigureTargetTarget"},
	{unit = "pet", globalName = "HydraUI Pet", enabled = "pet-enable", dimensions = {width = "unitframes-pet-width", health = "unitframes-pet-health-height", power = "unitframes-pet-power-height"}, defaultAnchor = {"TOPLEFT", "CENTER", -68, -341}, postSpawn = "ConfigurePet"},
	{unit = "focus", globalName = "HydraUI Focus", enabled = "focus-enable", dimensions = {width = "unitframes-focus-width", health = "unitframes-focus-health-height", power = "unitframes-focus-power-height"}, defaultAnchor = {"RIGHT", "CENTER", -68, 304}, postSpawn = "ConfigureFocus"},
}
UF.SingletonUnits = SingletonUnits

function UF:SpawnSingletonFrames()
	for _, descriptor in ipairs(SingletonUnits) do
		if Settings[descriptor.enabled] then
			local dimensions = descriptor.dimensions
			local frame = oUF:Spawn(descriptor.unit, descriptor.globalName)
			frame:SetSize(Settings[dimensions.width], Settings[dimensions.health] + Settings[dimensions.power] + 3)
			frame:SetPoint(descriptor.defaultAnchor[1], HydraUI.UIParent, descriptor.defaultAnchor[2], descriptor.defaultAnchor[3], descriptor.defaultAnchor[4])
			frame:SetParent(HydraUI.UIParent)
			HydraUI.UnitFrames[descriptor.unit] = frame
		end
	end

	if Settings["player-enable"] then
		local Player = HydraUI.UnitFrames["player"]

		if Settings["unitframes-player-enable-power"] and (not Settings["player-move-power"]) then
			Player:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-health-height"] + Settings["unitframes-player-power-height"] + 3)
		else
			Player:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-health-height"] + 2)
		end

		Player:SetPoint("TOPRIGHT", HydraUI.UIParent, "CENTER", -68, -281)
		Player:SetParent(HydraUI.UIParent)

		if Settings["player-enable-portrait"] then
			Player:EnableElement("Portrait")
		else
			Player:DisableElement("Portrait")
		end

		if (not Settings["player-enable-pvp"]) then
			Player:DisableElement("PvPIndicator")
			Player.PvPIndicator:Hide()
		end

		if Settings["unitframes-show-player-buffs"] then
			Player.Buffs:Show()
		else
			Player.Buffs:Hide()
		end

		if Settings["unitframes-show-player-debuffs"] then
			Player.Debuffs:Show()
		else
			Player.Debuffs:Hide()
		end

		if Settings["unitframes-player-enable-castbar"] then
			Player.CastAnchor:SetPoint("BOTTOM", HydraUI.UIParent, 0, 118)
			HydraUI:CreateMover(Player.CastAnchor, 2)
		end

		HydraUI.UnitFrames["player"] = Player
		HydraUI:CreateMover(Player)

		Player:UpdateAllElements("ForceUpdate")
	end

	if Settings["target-enable"] then
		local Target = HydraUI.UnitFrames["target"]
		Target:SetSize(Settings["unitframes-target-width"], Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 3)
		Target:SetPoint("TOPLEFT", HydraUI.UIParent, "CENTER", 68, -281)
		Target:SetParent(HydraUI.UIParent)

		if Settings["target-enable-portrait"] then
			Target:EnableElement("Portrait")
		else
			Target:DisableElement("Portrait")
		end

		if Settings["unitframes-show-target-buffs"] then
			Target.Buffs:Show()
		else
			Target.Buffs:Hide()
		end

		if Settings["unitframes-show-target-debuffs"] then
			Target.Debuffs:Show()
		else
			Target.Debuffs:Hide()
		end

		if Settings["unitframes-target-enable-castbar"] then
			Target.CastAnchor:SetPoint("BOTTOM", HydraUI.UIParent, 0, 146)
			HydraUI:CreateMover(Target.CastAnchor, 2)
		end

		HydraUI.UnitFrames["target"] = Target
		HydraUI:CreateMover(Target)

		Target:UpdateAllElements("ForceUpdate")
	end

	if Settings["tot-enable"] then
		local TargetTarget = HydraUI.UnitFrames["targettarget"]
		TargetTarget:SetSize(Settings["unitframes-targettarget-width"], Settings["unitframes-targettarget-health-height"] + Settings["unitframes-targettarget-power-height"] + 3)
		TargetTarget:SetParent(HydraUI.UIParent)

		if Settings["target-enable"] then
			TargetTarget:SetPoint("TOPRIGHT", HydraUI.UnitFrames["target"], "BOTTOMRIGHT", 0, -2)
		else
			TargetTarget:SetPoint("TOPRIGHT", HydraUI.UIParent, "CENTER", 68, -341)
		end

		HydraUI.UnitFrames["targettarget"] = TargetTarget
		HydraUI:CreateMover(TargetTarget)
	end

	if Settings["pet-enable"] then
		local Pet = HydraUI.UnitFrames["pet"]
		Pet:SetSize(Settings["unitframes-pet-width"], Settings["unitframes-pet-health-height"] + Settings["unitframes-pet-power-height"] + 3)
		Pet:SetParent(HydraUI.UIParent)

		if Settings["player-enable"] then
			Pet:SetPoint("TOPLEFT", HydraUI.UnitFrames["player"], "BOTTOMLEFT", 0, -2)
		else
			Pet:SetPoint("TOPLEFT", HydraUI.UIParent, "CENTER", -68, -341)
		end

		HydraUI.UnitFrames["pet"] = Pet
		HydraUI:CreateMover(Pet)
	end

	if Settings["focus-enable"] then
		local Focus = HydraUI.UnitFrames["focus"]
		Focus:SetSize(Settings["unitframes-focus-width"], Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3)
		Focus:SetPoint("RIGHT", HydraUI.UIParent, "CENTER", -68, 304)
		Focus:SetParent(HydraUI.UIParent)

		if Settings["focus-enable-buffs"] then
			Focus:EnableElement("Auras")
		else
			Focus:DisableElement("Auras")
		end

		HydraUI.UnitFrames["focus"] = Focus
		HydraUI:CreateMover(Focus)
	end

end

function UF:SpawnBossFrames()
	if Settings["unitframes-boss-enable"] then
		for i = 1, 8 do
			local Boss = oUF:Spawn("boss" .. i, "HydraUI Boss " .. i)
			Boss:SetSize(Settings["unitframes-boss-width"], Settings["unitframes-boss-health-height"] + Settings["unitframes-boss-power-height"] + 3)
			Boss:SetParent(HydraUI.UIParent)

			if (i == 1) then
				Boss:SetPoint("LEFT", HydraUI.UIParent, 300, 200)
			else
				Boss:SetPoint("TOP", HydraUI.UnitFrames["boss" .. (i-1)], "BOTTOM", 0, -28) -- -2
			end

			HydraUI:CreateMover(Boss)

			HydraUI.UnitFrames["boss" .. i] = Boss
		end
	end

end

function UF:GetGrowthOffsets(point, spacing)
	if point == "LEFT" then return spacing, 0 end
	if point == "RIGHT" then return -spacing, 0 end
	if point == "TOP" then return 0, -spacing end
	if point == "BOTTOM" then return 0, spacing end
	return 0, 0
end

function UF:BuildHeaderAttributes(options)
	assert(options.width and options.height, "header attributes require width and height")
	return {
		"initial-width", options.width, "initial-height", options.height,
		"showSolo", options.showSolo, "showPlayer", options.showPlayer,
		"showParty", options.showParty, "showRaid", options.showRaid,
		"point", options.point, "xOffset", options.xOffset or 0,
		"yOffset", options.yOffset or 0,
	}
end

function UF:SpawnPartyHeaders()
	if Settings["party-enable"] then
		local XOffset, YOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])

		local Party = oUF:SpawnHeader("HydraUI Party", nil, "party,solo",
			"initial-width", Settings["party-width"],
			"initial-height", (Settings["party-health-height"] + Settings["party-power-height"] + 3),
			"isTesting", false,
			"showSolo", Settings["party-show-solo"],
			"showPlayer", true,
			"showParty", true,
			"showRaid", false,
			"xOffset", XOffset,
			"yOffset", YOffset,
			"point", Settings["party-point"],
			"oUF-initialConfigFunction", [[
				local Header = self:GetParent()

				self:SetWidth(Header:GetAttribute("initial-width"))
				self:SetHeight(Header:GetAttribute("initial-height"))
			]]
		)

		self.PartyAnchor = CreateFrame("Frame", "HydraUI Party Anchor", HydraUI.UIParent)
		self.PartyAnchor:SetSize((5 * Settings["party-width"] + (4 * Settings["party-spacing"])), (Settings["party-health-height"] + Settings["party-power-height"]) + 3)
		self.PartyAnchor:SetPoint("BOTTOMLEFT", HydraUIChatFrameTop, "TOPLEFT", -3, 5)

		Party:SetPoint("BOTTOMLEFT", self.PartyAnchor, 0, 0)
		Party:SetParent(HydraUI.UIParent)

		HydraUI.UnitFrames["party"] = Party

		--UpdatePartyShowRole(Settings["party-show-role"])

		HydraUI:CreateMover(self.PartyAnchor)

		if Settings["party-pets-enable"] then
			local XOffset, YOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])

			local PartyPet = oUF:SpawnHeader("HydraUI Party Pets", "SecureGroupPetHeaderTemplate", "party,solo",
				"initial-width", Settings["party-pets-width"],
				"initial-height", (Settings["party-pets-health-height"] + 2),
				"showSolo", Settings["party-show-solo"],
				"showPlayer", false,
				"showParty", true,
				"showRaid", false,
				"xOffset", XOffset,
				"yOffset", YOffset,
				"point", Settings["party-point"],
				"oUF-initialConfigFunction", [[
					local Header = self:GetParent()

					self:SetWidth(Header:GetAttribute("initial-width"))
					self:SetHeight(Header:GetAttribute("initial-height"))
				]]
			)

			self.PartyPetAnchor = CreateFrame("Frame", "HydraUI Party Pet Anchor", HydraUI.UIParent)
			self.PartyPetAnchor:SetSize((5 * Settings["party-width"] + (4 * Settings["party-spacing"])), Settings["party-pets-health-height"] + 2)
			self.PartyPetAnchor:SetPoint("TOPLEFT", self.PartyAnchor, "BOTTOMLEFT", 0, -2)

			PartyPet:SetPoint("TOPLEFT", self.PartyPetAnchor, 0, 0)
			PartyPet:SetParent(HydraUI.UIParent)

			HydraUI:CreateMover(self.PartyPetAnchor)

			HydraUI.UnitFrames["party-pets"] = PartyPet
		end
	end

end

function UF:SpawnRaidHeaders()
	if Settings["raid-enable"] then
		local Raid = oUF:SpawnHeader("HydraUI Raid", nil, "raid,solo",
			"initial-width", Settings["raid-width"],
			"initial-height", (Settings["raid-health-height"] + Settings["raid-power-height"] + 3),
			"isTesting", false,
			"showSolo", Settings["raid-show-solo"],
			"showPlayer", true,
			"showParty", false,
			"showRaid", true,
			"point", Settings["raid-point"],
			"xoffset", Settings["raid-x-offset"],
			"yOffset", Settings["raid-y-offset"],
			"maxColumns", Settings["raid-max-columns"],
			"unitsPerColumn", Settings["raid-units-per-column"],
			"columnSpacing", Settings["raid-column-spacing"],
			"columnAnchorPoint", Settings["raid-column-anchor"],
			"oUF-initialConfigFunction", [[
				local Header = self:GetParent()

				self:SetWidth(Header:GetAttribute("initial-width"))
				self:SetHeight(Header:GetAttribute("initial-height"))
			]]
		)

		local UnitHeight = (Settings["raid-health-height"] + Settings["raid-power-height"]) + 1
		local MaxSize = floor(40 / Settings["raid-max-columns"])

		self.RaidAnchor = CreateFrame("Frame", "HydraUI Raid Anchor", HydraUI.UIParent)
		self.RaidAnchor:SetWidth((MaxSize * Settings["raid-width"] + (MaxSize * Settings["raid-x-offset"] - 2)))
		self.RaidAnchor:SetHeight(UnitHeight * (Settings["raid-max-columns"] + 1) + (Settings["raid-y-offset"] * (Settings["raid-max-columns"] - 1)))
		self.RaidAnchor:SetPoint("BOTTOMLEFT", HydraUIChatFrameTop, "TOPLEFT", -3, 10)

		if CompactRaidFrameContainer then
			CompactRaidFrameContainer:UnregisterAllEvents()
			CompactRaidFrameContainer:SetParent(Hider)

			CompactRaidFrameManager:UnregisterAllEvents()
			CompactRaidFrameManager:SetParent(Hider)
		end

		Raid:SetPoint("BOTTOMLEFT", self.RaidAnchor, 0, 0)
		Raid:SetParent(HydraUI.UIParent)

		HydraUI:CreateMover(self.RaidAnchor)

		HydraUI.UnitFrames["raid"] = Raid

		UpdateRaidSortingMethod(Settings["raid-sorting-method"])

		if Settings["raid-pets-enable"] then
			local RaidPet = oUF:SpawnHeader("HydraUI Raid Pets", "SecureGroupPetHeaderTemplate", "raid,solo",
			"initial-width", Settings["raid-pets-width"],
			"initial-height", (Settings["raid-pets-health-height"] + 2),
			"isTesting", false,
			"showSolo", Settings["raid-show-solo"],
			"showPlayer", true,
			"showParty", false,
			"showRaid", true,
			"point", Settings["raid-point"],
			"xoffset", Settings["raid-x-offset"],
			"yOffset", Settings["raid-y-offset"],
			"maxColumns", Settings["raid-max-columns"],
			"unitsPerColumn", Settings["raid-units-per-column"],
			"columnSpacing", Settings["raid-column-spacing"],
			"columnAnchorPoint", Settings["raid-column-anchor"],
			"oUF-initialConfigFunction", [[
				local Header = self:GetParent()

				self:SetWidth(Header:GetAttribute("initial-width"))
				self:SetHeight(Header:GetAttribute("initial-height"))
			]]
			)

			self.RaidPetAnchor = CreateFrame("Frame", "HydraUI Raid Pet Anchor", HydraUI.UIParent)
			self.RaidPetAnchor:SetWidth((floor(40 / Settings["raid-max-columns"]) * Settings["raid-width"] + (floor(40 / Settings["raid-max-columns"]) * Settings["raid-x-offset"] - 2)))
			self.RaidPetAnchor:SetHeight(Settings["raid-pets-health-height"] * (Settings["raid-max-columns"] + (Settings["raid-y-offset"])) - 1)
			self.RaidPetAnchor:SetPoint("BOTTOMLEFT", self.RaidAnchor, "TOPLEFT", 0, 0)

			HydraUI:CreateMover(self.RaidPetAnchor)

			RaidPet:SetPoint("TOPLEFT", self.RaidPetAnchor, 0, 0)
			RaidPet:SetParent(HydraUI.UIParent)

			HydraUI.UnitFrames["raid-pets"] = RaidPet
		end
	end

end

function UF:SpawnNameplates()
	if Settings["nameplates-enable"] then
		UF.NamePlateCVars.nameplateSelectedAlpha = (Settings["nameplates-selected-alpha"] / 100)
		UF.NamePlateCVars.nameplateMinAlpha = (Settings["nameplates-unselected-alpha"] / 100)
		UF.NamePlateCVars.nameplateMaxAlpha = (Settings["nameplates-unselected-alpha"] / 100)

		oUF:SpawnNamePlates(nil, UF.NamePlateCallback, UF.NamePlateCVars)
	end
end

function UF:Load()
	self:SpawnSingletonFrames()
	self:SpawnBossFrames()
	self:SpawnPartyHeaders()
	self:SpawnRaidHeaders()
	self:SpawnNameplates()
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Font"])
	left:CreateDropdown("unitframes-font", Settings["unitframes-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the unit frames"], nil, "Font")
	left:CreateSlider("unitframes-font-size", Settings["unitframes-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the unit frames"])
	left:CreateDropdown("unitframes-font-flags", Settings["unitframes-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the unit frames"])

	right:CreateHeader(Language["Auras"])
	right:CreateSwitch("unitframes-display-aura-timers", Settings["unitframes-display-aura-timers"], Language["Display Aura Timers"], Language["Display the timer on unit frame auras"], ReloadUI):RequiresReload(true)
end)

--/run HydraUIFakeBosses()
HydraUIFakeBosses = function()
	local Boss

	for i = 1, 8 do
		Boss = HydraUI.UnitFrames["boss"..i]

		if (not Boss:IsShown()) then
			Boss.unit = "player"
			UnregisterUnitWatch(Boss)
			RegisterUnitWatch(Boss, true)
			Boss:Show()
		else
			Boss.unit = nil
			UnregisterUnitWatch(Boss)
			Boss:Hide()
		end
	end
end
