local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-player-width"] = 240
Defaults["unitframes-player-health-height"] = 32
Defaults["unitframes-player-health-reverse"] = false
Defaults["unitframes-player-health-color"] = "CLASS"
Defaults["unitframes-player-health-smooth"] = true
Defaults["unitframes-player-power-height"] = 15
Defaults["unitframes-player-power-reverse"] = false
Defaults["unitframes-player-power-color"] = "POWER"
Defaults["unitframes-player-power-smooth"] = true
Defaults["unitframes-player-health-left"] = "[LevelColor][Level][Plus][ColorStop] [Name(30)] [Resting]"
Defaults["unitframes-player-health-right"] = "[HealthPercent]"
Defaults["unitframes-player-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-player-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-player-enable-power"] = true
Defaults["unitframes-player-enable-resource"] = true
Defaults["unitframes-player-cast-width"] = 250
Defaults["unitframes-player-cast-height"] = 24
Defaults["unitframes-player-cast-classcolor"] = true
Defaults["unitframes-player-enable-castbar"] = true
Defaults["unitframes-show-mana-timer"] = true
Defaults["unitframes-show-energy-timer"] = true
Defaults["player-enable-portrait"] = false
Defaults["player-portrait-style"] = "3D"
Defaults["player-overlay-alpha"] = 30
Defaults["player-enable-pvp"] = true
Defaults["player-resource-height"] = 8
Defaults["player-move-resource"] = false
Defaults["player-move-power"] = false
Defaults["player-enable"] = true
Defaults.PlayerBuffSize = 28
Defaults.PlayerBuffSpacing = 2
Defaults.PlayerDebuffSize = 28
Defaults.PlayerDebuffSpacing = 2
Defaults.PlayerHealthTexture = "HydraUI 4"
Defaults.PlayerPowerTexture = "HydraUI 4"
Defaults.PlayerResourceTexture = "HydraUI 4"

-- Can do textures for health/power/castbar/player resources. That's only 4 settings, and only player needs the resources setting

local UF = HydraUI:GetModule("Unit Frames")

local function UpdatePlayerAuraAnchors(frame, resourceDetached)
	if not frame.Buffs or not frame.Debuffs then return end
	if resourceDetached == nil then resourceDetached = Settings["player-move-resource"] end
	local anchor = resourceDetached and frame or frame.AuraParent
	frame.Buffs:ClearAllPoints()
	frame.Debuffs:ClearAllPoints()
	if Settings["unitframes-show-player-buffs"] then
		frame.Buffs:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
		frame.Debuffs:SetPoint("BOTTOM", frame.Buffs, "TOP", 0, 2)
	else
		frame.Debuffs:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
	end
end

local function UpdatePlayerPowerLayout(frame, powerHeight, detached, healthHeight)
	if not frame.Power then return end
	powerHeight = powerHeight or Settings["unitframes-player-power-height"]
	healthHeight = healthHeight or Settings["unitframes-player-health-height"]
	if detached == nil then detached = Settings["player-move-power"] end
	frame.Power:ClearAllPoints()
	frame.Power:SetHeight(powerHeight)
	if detached then
		frame:SetHeight(healthHeight + 2)
		frame.Power:SetPoint("BOTTOMLEFT", frame.PowerAnchor, 1, 1)
		frame.Power:SetPoint("BOTTOMRIGHT", frame.PowerAnchor, -1, 1)
	else
		frame:SetHeight(healthHeight + powerHeight + 3)
		frame.Power:SetPoint("BOTTOMLEFT", frame, 1, 1)
		frame.Power:SetPoint("BOTTOMRIGHT", frame, -1, 1)
	end
end

local function UpdatePlayerResourceLayout(frame, resourceHeight, detached)
	resourceHeight = resourceHeight or Settings["player-resource-height"]
	if detached == nil then detached = Settings["player-move-resource"] end
	if frame.ClassResource then
		frame.ClassResource:SetHeight(resourceHeight)
		frame.ClassResource:SetDetached(detached)
	end
	UpdatePlayerAuraAnchors(frame, detached)
	if frame.ThreatIndicator then
		frame.ThreatIndicator:ClearAllPoints()
		local anchor = detached and frame or frame.AuraParent
		frame.ThreatIndicator:SetPoint("TOPLEFT", anchor, -1, 1)
		frame.ThreatIndicator:SetPoint("BOTTOMRIGHT", frame, 1, -1)
	end
end

-- Resource descriptions are module constants; spawning a frame only selects one.
local PlayerResourceDescriptors = {
	ROGUE = { field = "ComboPoints", count = HydraUI.IsMainline and 7 or 5, countProvider = function() return UnitPowerMax("player", Enum.PowerType.ComboPoints) end, color = function(i) return unpack(HydraUI.ComboPoints[i]) end, charged = HydraUI.IsMainline},
	DRUID = { field = "ComboPoints", count = 5, countProvider = function() return UnitPowerMax("player", Enum.PowerType.ComboPoints) end, color = function(i) return unpack(HydraUI.ComboPoints[i]) end, charged = HydraUI.IsMainline},
	DEATHKNIGHT = { field = "Runes", count = 6, colorSetting = "color-runes", runes = true},
	MONK = { field = "ClassPower", alias = "Chi", count = 6, colorSetting = "color-chi", stagger = true},
	EVOKER = { field = "ClassPower", alias = "Essence", count = 6, colorSetting = "color-essence"},
	WARLOCK = (HydraUI.IsMainline or HydraUI.IsCata or HydraUI.IsMists) and {field = "ClassPower", alias = "SoulShards", count = HydraUI.IsMainline and 5 or (HydraUI.IsMists and 4 or 3), colorSetting = "color-soul-shards"} or nil,
	MAGE = HydraUI.IsMainline and {field = "ClassPower", alias = "ArcaneCharges", count = 4, colorSetting = "color-arcane-charges"} or nil,
	PALADIN = (HydraUI.IsMainline or HydraUI.IsCata or HydraUI.IsMists) and {field = "ClassPower", alias = "HolyPower", count = 5, colorSetting = "color-holy-power"} or nil,
	SHAMAN = not HydraUI.IsMainline and {field = "Totems", count = 4, color = function(i) return unpack(HydraUI.TotemColors[i]) end, postUpdate = UF.PostUpdateTotems, totems = true} or nil,
}

local function BuildPlayerComponents(factory, self, unit)
	local Health = self.Health
	self.AuraParent = self
    -- Portrait
	factory:CreatePortrait(self,
		Settings["player-portrait-style"],
		Settings["player-portrait-style"] == "OVERLAY" and Settings["unitframes-player-width"] or 55,
		Settings["player-portrait-style"] == "OVERLAY" and Settings["unitframes-player-health-height"] or Settings["unitframes-player-health-height"] + Settings["unitframes-player-power-height"] + 1,
		Settings["player-portrait-style"] == "OVERLAY" and "CENTER" or "RIGHT",
		Settings["player-portrait-style"] == "OVERLAY" and Health or self,
		Settings["player-portrait-style"] == "OVERLAY" and "CENTER" or "LEFT",
		Settings["player-portrait-style"] == "OVERLAY" and 0 or -3, 0,
		Settings["player-portrait-style"] == "OVERLAY" and Settings["player-overlay-alpha"] / 100 or nil,
		Settings["Blank"], Settings["player-enable-portrait"])

	local Combat = Health:CreateTexture(nil, "OVERLAY")
	Combat:SetSize(20, 20)
	Combat:SetPoint("CENTER", Health)

    local Leader = Health:CreateTexture(nil, "OVERLAY")
    Leader:SetSize(16, 16)
    Leader:SetPoint("LEFT", Health, "TOPLEFT", 3, 0)
    Leader:SetTexture(Assets:GetTexture("Leader"))
    Leader:SetVertexColor(HydraUI:HexToRGB("FFEB3B"))
    Leader:Hide()

    -- PVP indicator
	local PvPIndicator = Health:CreateTexture(nil, "ARTWORK", nil, 1)

	if HydraUI.IsMainline then
		PvPIndicator:SetSize(30, 30)
		PvPIndicator:SetPoint("RIGHT", Health, "LEFT", -4, -2)

		PvPIndicator.Badge = Health:CreateTexture(nil, "ARTWORK")
		PvPIndicator.Badge:SetSize(50, 52)
		PvPIndicator.Badge:SetPoint("CENTER", PvPIndicator, "CENTER")
	else
		PvPIndicator:SetSize(32, 32)
		PvPIndicator:SetPoint("CENTER", Health, 5, -6)
	end

	local Power = self.Power
	if Power then
		local PowerAnchor = CreateFrame("Frame", "HydraUI Player Power", HydraUI.UIParent)
		PowerAnchor:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-power-height"])
		PowerAnchor:SetPoint("CENTER", HydraUI.UIParent, 0, -133)
		HydraUI:CreateMover(PowerAnchor)
		self.PowerAnchor = PowerAnchor
		UpdatePlayerPowerLayout(self)
		factory:CreateBackdrop(Power, "Blank", "BACKGROUND")
		-- Mana regen
		if (Settings["unitframes-show-mana-timer"] and not HydraUI.IsMainline) then
			local ManaTimer = CreateFrame("StatusBar", nil, Power)
			ManaTimer:SetAllPoints(Power)
			ManaTimer:SetStatusBarTexture(Assets:GetTexture(Settings.PlayerPowerTexture))
			ManaTimer:SetStatusBarColor(0, 0, 0, 0)
			ManaTimer:Hide()

			ManaTimer.Spark = ManaTimer:CreateTexture(nil, "ARTWORK")
			ManaTimer.Spark:SetSize(3, Settings["unitframes-player-power-height"])
			ManaTimer.Spark:SetPoint("LEFT", ManaTimer:GetStatusBarTexture(), "RIGHT", -1, 0)
			ManaTimer.Spark:SetTexture(Assets:GetTexture("Blank"))
			ManaTimer.Spark:SetVertexColor(1, 1, 1, 0.2)

			ManaTimer.Spark2 = ManaTimer:CreateTexture(nil, "ARTWORK")
			ManaTimer.Spark2:SetSize(1, Settings["unitframes-player-power-height"])
			ManaTimer.Spark2:SetPoint("CENTER", ManaTimer.Spark, 0, 0)
			ManaTimer.Spark2:SetTexture(Assets:GetTexture("Blank"))
			ManaTimer.Spark2:SetVertexColor(1, 1, 1, 0.8)

			self.ManaTimer = ManaTimer
		end

		-- Energy ticks
		if (Settings["unitframes-show-energy-timer"] and (HydraUI.IsVanilla or HydraUI.IsTBC)) then
			local EnergyTick = CreateFrame("StatusBar", nil, Power)
			EnergyTick:SetAllPoints(Power)
			EnergyTick:SetStatusBarTexture(Assets:GetTexture(Settings.PlayerPowerTexture))
			EnergyTick:SetStatusBarColor(0, 0, 0, 0)
			EnergyTick:Hide()

			EnergyTick.Spark = EnergyTick:CreateTexture(nil, "ARTWORK")
			EnergyTick.Spark:SetSize(3, Settings["unitframes-player-power-height"])
			EnergyTick.Spark:SetPoint("LEFT", EnergyTick:GetStatusBarTexture(), "RIGHT", -1, 0)
			EnergyTick.Spark:SetTexture(Assets:GetTexture("Blank"))
			EnergyTick.Spark:SetVertexColor(1, 1, 1, 0.2)

			EnergyTick.Spark2 = EnergyTick:CreateTexture(nil, "ARTWORK")
			EnergyTick.Spark2:SetSize(1, Settings["unitframes-player-power-height"])
			EnergyTick.Spark2:SetPoint("CENTER", EnergyTick.Spark, 0, 0)
			EnergyTick.Spark2:SetTexture(Assets:GetTexture("Blank"))
			EnergyTick.Spark2:SetVertexColor(1, 1, 1, 0.8)

			self.EnergyTick = EnergyTick
		end

		-- Power prediction
		if HydraUI.IsMainline then
			local MainBar = CreateFrame("StatusBar", nil, Power)
			MainBar:SetReverseFill(true)
			MainBar:SetPoint("TOPLEFT")
			MainBar:SetPoint("BOTTOMRIGHT")
			MainBar:SetStatusBarTexture(Assets:GetTexture(Settings.PlayerPowerTexture))
			MainBar:SetStatusBarColor(0.8, 0.1, 0.1)
			--MainBar:SetReverseFill(Settings["unitframes-player-power-reverse"])

			self.PowerPrediction = {
				mainBar = MainBar,
			}
		end

	end
    -- Castbar
	if Settings["unitframes-player-enable-castbar"] then
		local Anchor = CreateFrame("Frame", "HydraUI Casting Bar", self)
		Anchor:SetSize(Settings["unitframes-player-cast-width"], Settings["unitframes-player-cast-height"])
		factory:CreateCastbar(self, nil,
		Settings["unitframes-player-cast-width"] - Settings["unitframes-player-cast-height"] - 1, Settings["unitframes-player-cast-height"],
		"RIGHT", Anchor, "RIGHT", 0, 0, Settings["ui-widget-texture"], "Blank",
		-Settings["unitframes-player-cast-height"] - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, Settings["unitframes-player-cast-width"] * 0.7,
		Settings["unitframes-player-cast-height"], nil, nil, true, true, 0.7, Settings["unitframes-player-cast-classcolor"],
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
		self.CastAnchor = Anchor
	end

	if Settings["unitframes-player-enable-resource"] then
		local ResourceAnchor = CreateFrame("Frame", "HydraUI Class Resource", HydraUI.UIParent)
		ResourceAnchor:SetSize(Settings["unitframes-player-width"], Settings["player-resource-height"] + 2)
		ResourceAnchor:SetPoint("CENTER", HydraUI.UIParent, 0, -120)
		HydraUI:CreateMover(ResourceAnchor)

		local function SelectResourceDescriptor(class) return PlayerResourceDescriptors[class] end

		local function CreateResourceBar(frame, descriptor)
			if not descriptor then return end
			local resource = CreateFrame("Frame", frame:GetName() .. descriptor.field, frame, "BackdropTemplate")
			resource:SetBackdrop(HydraUI.Backdrop)
			resource:SetBackdropColor(0, 0, 0)
			resource:SetBackdropBorderColor(0, 0, 0)
			resource.Descriptor = descriptor
			resource.PostUpdate = descriptor.postUpdate
			resource.sortOrder = descriptor.runes and "asc" or nil

			local function Segment(bar, i)
				return descriptor.totems and bar[i].Bar or bar[i]
			end
			local function Count(bar)
				local count = descriptor.countProvider and descriptor.countProvider() or descriptor.count
				return math.max(1, math.min(count or descriptor.count, descriptor.count))
			end
			local function Anchor(bar, detached)
				bar:ClearAllPoints()
				bar:SetPoint(detached and "CENTER" or "BOTTOMLEFT", detached and ResourceAnchor or frame, detached and "CENTER" or "TOPLEFT", 0, detached and 0 or -1)
				if bar.Stagger then
					bar.Stagger:ClearAllPoints()
					bar.Stagger:SetPoint(detached and "CENTER" or "BOTTOMLEFT", detached and ResourceAnchor or frame, detached and "CENTER" or "TOPLEFT", detached and 0 or 1, 0)
				end
			end
			local NativeSetWidth, NativeSetHeight = resource.SetWidth, resource.SetHeight
			function resource:SetWidth(width)
				NativeSetWidth(self, width)
				local count = Count(self)
				local segmentWidth = (width / count) - 1
				for i = 1, descriptor.count do Segment(self, i):SetWidth(i == 1 and segmentWidth - 1 or segmentWidth) end
				if self.Stagger then self.Stagger:SetWidth(width - 2) end
			end
			function resource:SetHeight(height)
				NativeSetHeight(self, height + 2)
				for i = 1, descriptor.count do Segment(self, i):SetHeight(height) end
				if self.Stagger then self.Stagger:SetHeight(height) end
			end
			function resource:SetTexture(texture)
				texture = Assets:GetTexture(texture)
				for i = 1, descriptor.count do
					local segment = Segment(self, i)
					segment:SetStatusBarTexture(texture)
					segment.bg:SetTexture(texture)
					if segment.Charged then segment.Charged:SetTexture(texture) end
				end
				if self.Stagger then self.Stagger:SetStatusBarTexture(texture); self.Stagger.bg:SetTexture(texture) end
			end
			function resource:SetDetached(detached) Anchor(self, detached) end

			for i = 1, descriptor.count do
				local owner = resource
				if descriptor.totems then owner = CreateFrame("Button", nil, frame); resource[i] = owner end
				local segment = CreateFrame("StatusBar", frame:GetName() .. descriptor.field .. i, owner)
				if descriptor.totems then owner.Bar = segment; segment:EnableMouse(true); segment:SetID(i); segment:Hide() else resource[i] = segment end
				local r, g, b = descriptor.color and descriptor.color(i) or HydraUI:HexToRGB(Settings[descriptor.colorSetting])
				segment:SetStatusBarColor(r, g, b)
				segment.bg = resource:CreateTexture(nil, "BORDER")
				segment.bg:SetAllPoints(segment); segment.bg:SetVertexColor(r, g, b); segment.bg:SetAlpha(descriptor.runes and 0.2 or 0.3)
				if descriptor.charged then
					segment.Charged = segment:CreateTexture(nil, "ARTWORK"); segment.Charged:SetAllPoints()
					segment.Charged:SetVertexColor(HydraUI:HexToRGB(Settings["color-combo-charged"])); segment.Charged:Hide()
				end
				if descriptor.runes then
					segment.Duration = 0
					segment.Shine = segment:CreateTexture(nil, "ARTWORK"); segment.Shine:SetAllPoints(); segment.Shine:SetTexture(Assets:GetTexture("pHishTex28")); segment.Shine:SetVertexColor(0.8, 0.8, 0.8); segment.Shine:SetAlpha(0); segment.Shine:SetDrawLayer("ARTWORK", 7)
					segment.ReadyAnim = LibMotion:CreateAnimationGroup()
					segment.ReadyAnim.In = LibMotion:CreateAnimation(segment.Shine, "Fade"); segment.ReadyAnim.In:SetGroup(segment.ReadyAnim); segment.ReadyAnim.In:SetOrder(1); segment.ReadyAnim.In:SetEasing("in"); segment.ReadyAnim.In:SetDuration(0.2); segment.ReadyAnim.In:SetChange(0.5)
					segment.ReadyAnim.Out = LibMotion:CreateAnimation(segment.Shine, "Fade"); segment.ReadyAnim.Out:SetGroup(segment.ReadyAnim); segment.ReadyAnim.Out:SetOrder(2); segment.ReadyAnim.Out:SetEasing("out"); segment.ReadyAnim.Out:SetDuration(0.2); segment.ReadyAnim.Out:SetChange(0)
				end
				segment:SetPoint(i == 1 and "LEFT" or "TOPLEFT", i == 1 and resource or Segment(resource, i - 1), i == 1 and "LEFT" or "TOPRIGHT", i == 1 and 1 or 1, 0)
			end

			if descriptor.stagger then
				local stagger = CreateFrame("StatusBar", nil, frame); stagger:Hide()
				stagger.bg = stagger:CreateTexture(nil, "ARTWORK"); stagger.bg:SetAllPoints(); stagger.bg.multiplier = 0.3
				stagger.Backdrop = stagger:CreateTexture(nil, "BACKGROUND"); stagger.Backdrop:SetPoint("TOPLEFT", stagger, -1, 1); stagger.Backdrop:SetPoint("BOTTOMRIGHT", stagger, 1, -1); stagger.Backdrop:SetColorTexture(0, 0, 0)
				resource.Stagger, frame.Stagger = stagger, stagger
			end

			resource:SetWidth(Settings["unitframes-player-width"])
			resource:SetHeight(Settings["player-resource-height"])
			resource:SetTexture(Settings.PlayerResourceTexture)
			resource:SetDetached(Settings["player-move-resource"])
			frame[descriptor.field] = resource
			if descriptor.alias then frame[descriptor.alias] = resource end
			frame.ClassResource, frame.AuraParent = resource, resource
			return resource
		end

		CreateResourceBar(self, SelectResourceDescriptor(HydraUI.UserClass))
		self.ResourceAnchor = ResourceAnchor
	end
	-- Threat
	local Threat = CreateFrame("Frame", nil, self, "BackdropTemplate")

	if Settings["player-move-resource"] then
		Threat:SetPoint("TOPLEFT", -1, 1)
		Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	else
		Threat:SetPoint("TOPLEFT", self.AuraParent, -1, 1)
		Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	end

	Threat:SetBackdrop(HydraUI.Outline)
	Threat.PostUpdate = UF.ThreatPostUpdate

	self.ThreatIndicator = Threat

	-- Auras
	local Buffs = factory:CreateAuraContainer(self, self:GetName() .. "Buffs", nil, Settings["unitframes-player-width"], Settings.PlayerBuffSize,
		nil, nil, nil, 0, 0, Settings.PlayerBuffSize, Settings.PlayerBuffSpacing, 40,
		"BOTTOMLEFT", "ANCHOR_TOP", "RIGHT", "UP", UF.PostCreateIcon, UF.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(self, self:GetName() .. "Debuffs", nil, Settings["unitframes-player-width"], 28,
		nil, nil, nil, 0, 0, Settings.PlayerDebuffSize, Settings.PlayerDebuffSpacing, 16,
		"BOTTOMRIGHT", "ANCHOR_TOP", "LEFT", "UP", UF.PostCreateIcon, UF.PostUpdateIcon, nil, Settings["unitframes-only-player-debuffs"], nil)
	self.Buffs = Buffs
	self.Debuffs = Debuffs
	UpdatePlayerAuraAnchors(self)

	-- Resurrect
	local Resurrect = Health:CreateTexture(nil, "OVERLAY")
	Resurrect:SetSize(16, 16)
	Resurrect:SetPoint("CENTER", Health, 0, 0)
	Resurrect:Hide()

	self.CombatIndicator = Combat
	self.ResurrectIndicator = Resurrect
	self.LeaderIndicator = Leader
	self.PvPIndicator = PvPIndicator
	UpdatePlayerResourceLayout(self)
end

local PlayerFrameConfig = {
	settingsPrefix = "unitframes-player",
	threat = false,
	healthTextureKey = "PlayerHealthTexture",
	powerTextureKey = "PlayerPowerTexture",
	powerEnabledKey = "unitframes-player-enable-power",
	powerTags = true,
	raidTarget = true,
	portrait = BuildPlayerComponents,
}

HydraUI.StyleFuncs["player"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, PlayerFrameConfig)
end

local UpdateOnlyPlayerDebuffs = function(value)
	if HydraUI.UnitFrames["target"] then
		HydraUI.UnitFrames["target"].Debuffs.onlyShowPlayer = value
	end
end

local UpdatePlayerWidth = function(value)
	local Frame = HydraUI.UnitFrames["player"]
	if not Frame then return end
	UF:SetFrameWidth("player", value)
	Frame.Buffs:SetWidth(value)
	Frame.Debuffs:SetWidth(value)
	if Frame.ClassResource and not Settings["player-move-resource"] then Frame.ClassResource:SetWidth(value) end
end
local UpdatePlayerHealthHeight = function(value)
	local frame = HydraUI.UnitFrames["player"]
	if not frame then return end
	frame.Health:SetHeight(value)
	UpdatePlayerPowerLayout(frame, nil, nil, value)
end

local UpdatePlayerHealthFill = UF:CreateUnitUpdater("player", "HealthReverse")

local UpdatePlayerPowerHeight = function(value)
	local frame = HydraUI.UnitFrames["player"]
	if frame then UpdatePlayerPowerLayout(frame, value) end
end

local UpdatePlayerPowerFill = UF:CreateUnitUpdater("player", "PowerReverse")

local UpdatePlayerCastBarSize = function()
	if HydraUI.UnitFrames["player"].Castbar then
		HydraUI.UnitFrames["player"].Castbar:SetSize(Settings["unitframes-player-cast-width"], Settings["unitframes-player-cast-height"])
		HydraUI.UnitFrames["player"].Castbar.Icon:SetSize(Settings["unitframes-player-cast-height"], Settings["unitframes-player-cast-height"])
	end
end

local UpdateCastClassColor = function(value)
	if HydraUI.UnitFrames["player"].Castbar then
		HydraUI.UnitFrames["player"].Castbar.ClassColor = value
		HydraUI.UnitFrames["player"].Castbar:ForceUpdate()
	end
end

local UpdatePlayerHealthColor = UF:CreateUnitUpdater("player", "HealthColor")

local UpdatePlayerPowerColor = UF:CreateUnitUpdater("player", "PowerColor")

local UpdatePlayerEnablePortrait = function(value)
	local Frame = HydraUI.UnitFrames["player"]

	if Frame and Frame.Portrait then
		UF:SetElementEnabled("player", value, "Portrait")

		if Frame.Portrait.BG then
			if value then
				Frame.Portrait.BG:Show()
			else
				Frame.Portrait.BG:Hide()
			end
		end

		Frame.Portrait:ForceUpdate()
	end
end

local UpdateOverlayAlpha = function(value)
	if HydraUI.UnitFrames["player"] and Settings["player-portrait-style"] == "OVERLAY" then
		HydraUI.UnitFrames["player"].Portrait:SetAlpha(value / 100)
	end
end

local UpdatePlayerEnablePVPIndicator = function(value)
	if HydraUI.UnitFrames["player"] then
		if value then
			HydraUI.UnitFrames["player"]:EnableElement("PvPIndicator")
			HydraUI.UnitFrames["player"].PvPIndicator:ForceUpdate()
		else
			HydraUI.UnitFrames["player"]:DisableElement("PvPIndicator")
			HydraUI.UnitFrames["player"].PvPIndicator:Hide()
		end
	end
end

local UpdateResourceBarHeight = function(value)
	local Frame = HydraUI.UnitFrames["player"]
	if Frame then UpdatePlayerResourceLayout(Frame, value) end
end
local UpdateResourceTexture = function(value)
	local Frame = HydraUI.UnitFrames["player"]
	if Frame and Frame.ClassResource then Frame.ClassResource:SetTexture(value) end
end
local UpdateBuffSize = UF:CreateUnitUpdater("player", "AuraSize", {element = "Buffs", width = "unitframes-player-width"})

local UpdateBuffSpacing = UF:CreateUnitUpdater("player", "AuraSpacing", {element = "Buffs"})

local UpdateDebuffSize = UF:CreateUnitUpdater("player", "AuraSize", {element = "Debuffs", width = "unitframes-player-width"})

local UpdateDebuffSpacing = UF:CreateUnitUpdater("player", "AuraSpacing", {element = "Debuffs"})

local UpdateDisplayedAuras = function()
	local Player = HydraUI.UnitFrames["player"]
	if not Player then return end
	UpdatePlayerAuraAnchors(Player)

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
end

local UpdateResourcePosition = function(value)
	local frame = HydraUI.UnitFrames["player"]
	if not frame then return end
	UpdatePlayerResourceLayout(frame, nil, value)
end

local UpdatePowerBarPosition = function(value)
	local frame = HydraUI.UnitFrames["player"]
	if frame then UpdatePlayerPowerLayout(frame, nil, value) end
end

local UpdateHealthTexture = UF:CreateUnitUpdater("player", "HealthTexture")

local UpdatePowerTexture = function(value)
	local Frame = HydraUI.UnitFrames["player"]

	if Frame then
		UF:SetPowerTexture("player", value)

		local Texture = Assets:GetTexture(value)

		if Frame.ManaTimer then
			Frame.ManaTimer:SetStatusBarTexture(Texture)
		end

		if Frame.EnergyTick then
			Frame.EnergyTick:SetStatusBarTexture(Texture)
		end

		if Frame.PowerPrediction then
			Frame.PowerPrediction.mainBar:SetStatusBarTexture(Texture)
		end
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Player"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("player-enable", Settings["player-enable"], Language["Enable Player"], Language["Enable the player unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-player-width", Settings["unitframes-player-width"], 120, 320, 1, Language["Width"], Language["Set the width of the player unit frame"], UpdatePlayerWidth)
	left:CreateSwitch("player-enable-pvp", Settings["player-enable-pvp"], Language["Enable PVP Indicator"], Language["Display the PvP indicator"], UpdatePlayerEnablePVPIndicator)

	if (HydraUI.IsVanilla or HydraUI.IsTBC) then
		left:CreateSwitch("unitframes-show-mana-timer", Settings["unitframes-show-mana-timer"], Language["Enable Mana Regen Timer"], Language["Display the time until your full mana regeneration is active"], ReloadUI):RequiresReload(true)
		left:CreateSwitch("unitframes-show-energy-timer", Settings["unitframes-show-energy-timer"], Language["Enable Energy Timer"], Language["Display the time until your next energy tick on the power bar"], ReloadUI):RequiresReload(true)
	end

	left:CreateSwitch("player-enable-portrait", Settings["player-enable-portrait"], Language["Enable Portrait"], Language["Display the player unit portrait"], UpdatePlayerEnablePortrait)
	left:CreateDropdown("player-portrait-style", Settings["player-portrait-style"], {[Language["2D"]] = "2D", [Language["3D"]] = "3D", [Language["Overlay"]] = "OVERLAY"}, Language["Set Portrait Style"], Language["Set the style of the portrait"], ReloadUI):RequiresReload(true)
	left:CreateSlider("player-overlay-alpha", Settings["player-overlay-alpha"], 0, 100, 5, Language["Set Overlay Opacity"], Language["Set the opacity of the portrait overlay"], UpdateOverlayAlpha, nil, "%")

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-player-health-reverse", Settings["unitframes-player-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePlayerHealthFill)
	left:CreateSlider("unitframes-player-health-height", Settings["unitframes-player-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the player health bar", UpdatePlayerHealthHeight)
	left:CreateDropdown("unitframes-player-health-color", Settings["unitframes-player-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePlayerHealthColor)
	left:CreateInput("unitframes-player-health-left", Settings["unitframes-player-health-left"], Language["Left Health Text"], Language["Set the text on the left of the player health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-player-health-right", Settings["unitframes-player-health-right"], Language["Right Health Text"], Language["Set the text on the right of the player health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("PlayerHealthTexture", Settings.PlayerHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("unitframes-show-player-buffs", Settings["unitframes-show-player-buffs"], Language["Show Player Buffs"], Language["Show your auras above the player unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("PlayerBuffSize", Settings.PlayerBuffSize, 26, 50, 2, "Set Size", "Set the size of the auras", UpdateBuffSize)
	left:CreateSlider("PlayerBuffSpacing", Settings.PlayerBuffSpacing, -1, 4, 1, "Set Spacing", "Set the spacing between the auras", UpdateBuffSpacing)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSwitch("unitframes-show-player-debuffs", Settings["unitframes-show-player-debuffs"], Language["Show Player Debuffs"], Language["Show your debuff auras above the player unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("PlayerDebuffSize", Settings.PlayerDebuffSize, 26, 50, 2, "Set Size", "Set the size of the auras", UpdateDebuffSize)
	left:CreateSlider("PlayerDebuffSpacing", Settings.PlayerDebuffSpacing, -1, 4, 1, "Set Spacing", "Set the spacing between the auras", UpdateDebuffSpacing)

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-player-enable-power", Settings["unitframes-player-enable-power"], Language["Enable Power Bar"], Language["Enable the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-player-power-reverse", Settings["unitframes-player-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePlayerPowerFill)
	right:CreateSwitch("player-move-power", Settings["player-move-power"], Language["Detach Power"], Language["Detach the power bar from the unit frame"], UpdatePowerBarPosition)
	right:CreateSlider("unitframes-player-power-height", Settings["unitframes-player-power-height"], 2, 30, 1, "Power Bar Height", "Set the height of the player power bar", UpdatePlayerPowerHeight)
	right:CreateDropdown("unitframes-player-power-color", Settings["unitframes-player-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePlayerPowerColor)
	right:CreateInput("unitframes-player-power-left", Settings["unitframes-player-power-left"], Language["Left Power Text"], Language["Set the text on the left of the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateInput("unitframes-player-power-right", Settings["unitframes-player-power-right"], Language["Right Power Text"], Language["Set the text on the right of the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("PlayerPowerTexture", Settings.PlayerPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("unitframes-player-enable-castbar", Settings["unitframes-player-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the player cast bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-player-cast-classcolor", Settings["unitframes-player-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateCastClassColor)
	right:CreateSlider("unitframes-player-cast-width", Settings["unitframes-player-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of the player cast bar"], UpdatePlayerCastBarSize)
	right:CreateSlider("unitframes-player-cast-height", Settings["unitframes-player-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of the player cast bar"], UpdatePlayerCastBarSize)

	right:CreateHeader(Language["Class Resource"])
	right:CreateSwitch("unitframes-player-enable-resource", Settings["unitframes-player-enable-resource"], Language["Enable Resource Bar"], Language["Enable the player resource such as combo points, runes, etc."], ReloadUI):RequiresReload(true)
	right:CreateSwitch("player-move-resource", Settings["player-move-resource"], Language["Detach Class Bar"], Language["Detach the class resource from the unit frame, to be moved by the UI"], UpdateResourcePosition)
	right:CreateSlider("player-resource-height", Settings["player-resource-height"], 4, 30, 1, Language["Set Height"], Language["Set the height of the player resource bar"], UpdateResourceBarHeight)
	right:CreateDropdown("PlayerResourceTexture", Settings.PlayerResourceTexture, Assets:GetTextureList(), Language["Texture"], "", UpdateResourceTexture, "Texture")
end)
