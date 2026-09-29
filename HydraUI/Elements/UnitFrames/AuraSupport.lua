local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local function Install(UF, Hider)
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

end

ns.UnitFrameAuraSupport = Install
