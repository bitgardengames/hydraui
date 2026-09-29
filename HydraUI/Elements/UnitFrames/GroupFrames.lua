local HydraUI, Language, Assets, Settings = select(2, ...):get()
local UF = HydraUI:GetModule("Unit Frames")

-- Group frame descriptors are deliberately data-only and live for the lifetime of
-- the addon.  Settings callbacks can therefore pass one stable object through the
-- header iterator instead of manufacturing a closure (or a children table).
local function CreateAuraWatch(frame, health, descriptor)
	if not descriptor.indicators.auraWatch or not UF.BuffIDs[HydraUI.UserClass] then return end
	local auras = CreateFrame("Frame", nil, health)
	auras:SetPoint("TOPLEFT", health)
	auras:SetPoint("BOTTOMRIGHT", health)
	auras:SetFrameLevel(10)
	auras:SetFrameStrata("HIGH")
	auras.presentAlpha, auras.missingAlpha = 1, 0
	auras.strictMatching, auras.icons = true, {}
	auras.PostCreateIcon = UF.PostCreateAuraWatchIcon
	for _, spell in pairs(UF.BuffIDs[HydraUI.UserClass]) do
		local icon = CreateFrame("Frame", nil, auras)
		icon.spellID, icon.anyUnit, icon.strictMatching = spell[1], spell[4], true
		icon:SetSize(8, 8); icon:SetPoint(spell[2], 0, 0)
		local texture = icon:CreateTexture(nil, "OVERLAY")
		texture:SetAllPoints(icon); texture:SetTexture(Assets:GetTexture("Blank"))
		if spell[3] then texture:SetVertexColor(unpack(spell[3])) else texture:SetVertexColor(.8, .8, .8) end
		local bg = icon:CreateTexture(nil, "BORDER")
		bg:SetPoint("TOPLEFT", icon, -1, 1); bg:SetPoint("BOTTOMRIGHT", icon, 1, -1)
		bg:SetTexture(Assets:GetTexture("Blank")); bg:SetVertexColor(0, 0, 0)
		local count = icon:CreateFontString(nil, "OVERLAY")
		HydraUI:SetFontInfo(count, Settings[descriptor.prefix .. "-font"], 10)
		count:SetPoint("CENTER", unpack(UF.AuraOffsets[spell[2]])); icon.count = count
		auras.icons[spell[1]] = icon
	end
	frame.AuraWatch = auras
end

local function CreateIndicatorTexture(health, texture, point, relativePoint, x, y)
	local indicator = health:CreateTexture(nil, "OVERLAY")
	indicator:SetSize(16, 16); indicator:SetPoint(point, health, relativePoint or point, x or 0, y or 0)
	if texture then indicator:SetTexture(Assets:GetTexture(texture)) end
	return indicator
end

function UF:BuildGroupFrame(frame, unit, descriptor)
	local prefix = descriptor.prefix
	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnEnter", UnitFrame_OnEnter); frame:SetScript("OnLeave", UnitFrame_OnLeave)
	UF:CreateBackdrop(frame, "Blank", "BACKGROUND")
	UF:CreateThreatIndicator(frame, HydraUI.Outline, UF.ThreatPostUpdate)
	local health, healthBG = UF:CreateHealthBar(frame, {
		size = {height = Settings[prefix .. "-health-height"]},
		bar = {texture = Settings[descriptor.healthTextureKey], reverseFill = Settings[prefix .. "-health-reverse"], orientation = Settings[prefix .. "-health-orientation"]},
	})
	local heal, absorbs = UF:CreateHealAndAbsorbBars(frame, {
		health = health, size = {width = Settings[prefix .. "-width"], height = Settings[prefix .. "-health-height"]},
		bar = {texture = Settings[descriptor.healthTextureKey], reverseFill = Settings[prefix .. "-health-reverse"]}, createAbsorb = HydraUI.IsMainline,
	})
	local highlight = UF:CreateMouseoverHighlight(frame, health, "Blank", Settings[descriptor.mouseoverKey])
	local dead = health:CreateTexture(nil, "OVERLAY")
	dead:SetAllPoints(health); dead:SetTexture(Assets:GetTexture("RenHorizonUp")); dead:SetVertexColor(.8,.8,.8); dead:SetAlpha(0); dead:SetDrawLayer("OVERLAY", 7)
	health.DeadAnim = LibMotion:CreateAnimationGroup()
	local fadeIn = LibMotion:CreateAnimation(dead, "Fade"); fadeIn:SetEasing("in"); fadeIn:SetDuration(.15); fadeIn:SetChange(.6); fadeIn:SetGroup(health.DeadAnim); fadeIn:SetOrder(1); health.DeadAnim.In = fadeIn
	local fadeOut = LibMotion:CreateAnimation(dead, "Fade"); fadeOut:SetEasing("out"); fadeOut:SetDuration(.3); fadeOut:SetChange(0); fadeOut:SetGroup(health.DeadAnim); fadeOut:SetOrder(2); health.DeadAnim.Out = fadeOut
	local healthName = UF:CreateFontString(health, Settings[prefix .. "-font"], Settings[prefix .. "-font-size"], Settings[prefix .. "-font-flags"], "BOTTOM", "CENTER", 0, 1, "CENTER")
	local healthBottom = UF:CreateFontString(health, Settings[prefix .. "-font"], Settings[prefix .. "-font-size"], Settings[prefix .. "-font-flags"], "TOP", "CENTER", 0, -1, "CENTER")
	health.colorDisconnected, health.Smooth = true, true; UF:SetHealthAttributes(health, Settings[prefix .. "-health-color"])
	local power, powerBG = UF:CreatePowerBar(frame, {size = {height = Settings[prefix .. "-power-height"]}, bar = {texture = Settings[descriptor.powerTextureKey], reverseFill = Settings[prefix .. "-power-reverse"]}})
	power.frequentUpdates = true; UF:SetPowerAttributes(power, Settings[prefix .. "-power-color"])
	local debuffs = descriptor.createDebuffs(frame, health, descriptor.debuffFilter)
	CreateAuraWatch(frame, health, descriptor)
	local leader = CreateIndicatorTexture(health, "Leader", "LEFT", "TOPLEFT", descriptor.indicators.leaderX, 0); leader:SetVertexColor(HydraUI:HexToRGB("FFEB3B")); leader:Hide()
	local assist = CreateIndicatorTexture(health, "Assist", "LEFT", "TOPLEFT", 3, 0); assist:SetVertexColor(HydraUI:HexToRGB("FFEB3B")); assist:Hide()
	local ready = CreateIndicatorTexture(health, nil, "LEFT", "LEFT", 2, 0)
	local resurrect = CreateIndicatorTexture(health, nil, "LEFT", "LEFT", 2, 0)
	local phase = CreateFrame("Frame", nil, health); phase:SetSize(16,16); phase:SetPoint(descriptor.indicators.phasePoint, health, descriptor.indicators.phasePoint, 0, 0); phase.Icon = phase:CreateTexture(nil,"OVERLAY"); phase.Icon:SetAllPoints()
	local raidTarget = UF:CreateRaidTargetIndicator(health, 16)
	local role
	if descriptor.indicators.role then role = CreateIndicatorTexture(health, nil, "LEFT", "LEFT", 2, 0) end
	local dispel = CreateFrame("Frame", nil, health, "BackdropTemplate")
	dispel:SetSize(descriptor.dispelSize, descriptor.dispelSize); dispel:SetPoint("CENTER", health); dispel:SetBackdrop(HydraUI.BackdropAndBorder); dispel:SetBackdropColor(0,0,0); dispel:SetFrameLevel((descriptor.dispelAboveDebuffs and debuffs:GetFrameLevel() or health:GetFrameLevel() + 19) + 1)
	dispel.icon = dispel:CreateTexture(nil,"ARTWORK"); dispel.icon:SetTexCoord(.1,.9,.1,.9); dispel.icon:SetPoint("TOPLEFT",dispel,1,-1); dispel.icon:SetPoint("BOTTOMRIGHT",dispel,-1,1)
	dispel.cd = CreateFrame("Cooldown",nil,dispel,"CooldownFrameTemplate"); dispel.cd:SetPoint("TOPLEFT",dispel,1,-1); dispel.cd:SetPoint("BOTTOMRIGHT",dispel,-1,1); dispel.cd:SetHideCountdownNumbers(true); dispel.cd:SetDrawEdge(false)
	dispel.count = dispel.cd:CreateFontString(nil,"ARTWORK"); HydraUI:SetFontInfo(dispel.count,Settings[prefix.."-font"],Settings[prefix.."-font-size"],Settings[prefix.."-font-flags"]); dispel.count:SetPoint("BOTTOMRIGHT",dispel,"BOTTOMRIGHT",-3,3); dispel.count:SetTextColor(1,1,1); dispel.count:SetJustifyH("RIGHT"); dispel.count:SetDrawLayer("ARTWORK",7)
	dispel.bg = dispel:CreateTexture(nil,"BACKGROUND"); dispel.bg:SetPoint("TOPLEFT",dispel,-1,1); dispel.bg:SetPoint("BOTTOMRIGHT",dispel,1,-1); dispel.bg:SetTexture(Assets:GetTexture("Blank")); dispel.bg:SetVertexColor(0,0,0)
	frame:Tag(healthName, Settings[prefix.."-health-top"]); frame:Tag(healthBottom, Settings[prefix.."-health-bottom"])
	frame.Range = { insideAlpha=Settings[prefix.."-in-range"]/100, outsideAlpha=Settings[prefix.."-out-of-range"]/100 }
	frame.Health, health.bg, frame.Power, power.bg = health, healthBG, power, powerBG
	frame.HealthName, frame.HealthBottom, frame.Debuffs, frame.Dispel = healthName, healthBottom, debuffs, dispel
	frame.LeaderIndicator, frame.AssistantIndicator, frame.ReadyCheckIndicator = leader, assist, ready
	frame.ResurrectIndicator, frame.RaidTargetIndicator, frame.PhaseIndicator = resurrect, raidTarget, phase
	frame.GroupRoleIndicator = role
	if descriptor.finish then descriptor.finish(frame, health) end
end

local Operations = {}
function Operations.width(frame,value) UF:SetFrameWidth(frame,value) end
function Operations.healthHeight(frame,value,d) UF:SetHealthHeight(frame,value,Settings[d.prefix.."-power-height"]) end
function Operations.healthColor(frame,value) UF:ApplyHealthAttributes(frame,value) end
function Operations.healthOrientation(frame,value) frame.Health:SetOrientation(value) end
function Operations.healthReverse(frame,value) UF:SetHealthReverseFill(frame,value) end
function Operations.powerEnabled(frame,value,d) UF:SetElementEnabled(frame,value,"Power"); frame:SetHeight(Settings[d.prefix.."-health-height"]+(value and Settings[d.prefix.."-power-height"]+3 or 2)) end
function Operations.powerHeight(frame,value,d) UF:SetPowerHeight(frame,value,Settings[d.prefix.."-health-height"]) end
function Operations.powerReverse(frame,value) UF:SetPowerReverseFill(frame,value) end
function Operations.powerColor(frame,value) UF:ApplyPowerAttributes(frame,value) end
function Operations.healthTexture(frame,value)
	local texture=Assets:GetTexture(value); frame.Health:SetStatusBarTexture(texture); frame.Health.bg:SetTexture(texture)
	if frame.HealBar then frame.HealBar:SetStatusBarTexture(texture) end
	if frame.AbsorbsBar then frame.AbsorbsBar:SetStatusBarTexture(texture) end
end
function Operations.powerTexture(frame,value)
	local texture=Assets:GetTexture(value); frame.Power:SetStatusBarTexture(texture); frame.Power.bg:SetTexture(texture)
end
function Operations.debuffs(frame,value) UF:SetElementEnabled(frame,value,"Debuffs") end
function Operations.role(frame,value) UF:SetElementEnabled(frame,value,"GroupRoleIndicator"); frame:UpdateAllElements("ForceUpdate") end
function Operations.highlight(frame,value) if value then frame.Highlight:Show() else frame.Highlight:Hide() end end

function UF:UpdateGroupFrames(descriptor, operation, value)
	local header = HydraUI.UnitFrames[descriptor.header]
	if header then self:ForEachHeaderChild(header, Operations[operation], value, descriptor) end
	if operation == "highlight" then self:ForEachHeaderChild(HydraUI.UnitFrames[descriptor.petHeader], Operations.highlight, value, descriptor) end
	if descriptor.afterUpdate then descriptor.afterUpdate(operation) end
end

local function SetTestFrame(frame, shown, pet)
	frame.unit = shown and (pet and UnitExists("pet") and "pet" or "player") or nil
	UnregisterUnitWatch(frame)
	if shown then RegisterUnitWatch(frame,true); frame:Show() else frame:Hide() end
end
local function UpdateTestChild(frame, shown, descriptor) SetTestFrame(frame,shown,descriptor.testingPets) end
function UF:ToggleGroupTest(descriptor)
	descriptor.testing = not descriptor.testing
	for _, key in ipairs({descriptor.header, descriptor.petHeader}) do
		local header = HydraUI.UnitFrames[key]
		if header then
			header:SetAttribute("isTesting",descriptor.testing)
			if header:GetAttribute("startingIndex") ~= descriptor.testStart then header:SetAttribute("startingIndex",descriptor.testStart) end
			descriptor.testingPets = key == descriptor.petHeader
			self:ForEachHeaderChild(header,UpdateTestChild,descriptor.testing,descriptor)
		end
	end
end

UF.GroupFrameOperations = Operations
