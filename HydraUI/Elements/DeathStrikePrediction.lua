-- This is my death strike module from Legion, I need to rewrite it as an oUF plugin
local HydraUI, Language, Assets, Settings = select(2, ...):get()

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame.Elapsed = 0

local select = select
local max = math.max
local type = type
local floor = floor
local format = format
local GetTime = GetTime
local tinsert = tinsert
local tremove = tremove
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local VAMPIRIC_BLOOD = GetSpellInfo(55233)
local VampBloodMult = 1
local TotalHP
local HP
local SevenPercent
local AbsorbNum = 12
local UNHOLY = RUNETYPE_UNHOLY
local FROST = RUNETYPE_FROST
local DEATH = RUNETYPE_DEATH
local MyGUID = UnitGUID("player")
local FindAura = AuraUtil.FindAuraByName
local Timestamp, EventType, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags
local Amount, Overkill, Absorbed
local DmgTable
local DmgTaken = {}
local Tables = {}
local LogEvents = {["SWING_DAMAGE"] = 12, ["SPELL_DAMAGE"] = 15, ["SPELL_PERIODIC_DAMAGE"] = 15, ["RANGE_DAMAGE"] = 15, ["SPELL_ABSORBED"] = 1}
local _

local GetTable = function()
	local Table

	if Tables[1] then
		Table = tremove(Tables, 1)
	else
		Table = {}
	end

	return Table
end

-- Need to condense this, but don't want to use tables for each count
local CanDeathStrike = function()
	local Frost = 0
	local Unholy = 0
	local Death = 0

	if select(3, GetRuneCooldown(1)) then
		local Type = GetRuneType(1)

		if (Type == DEATH) then
			Death = Death + 1
		end
	end

	if select(3, GetRuneCooldown(2)) then
		local Type = GetRuneType(2)

		if (Type == DEATH) then
			Death = Death + 1
		end
	end

	if select(3, GetRuneCooldown(3)) then
		local Type = GetRuneType(3)

		if (Type == UNHOLY) then
			Unholy = Unholy + 1
		elseif (Type == DEATH) then
			Death = Death + 1
		end
	end

	if select(3, GetRuneCooldown(4)) then
		local Type = GetRuneType(4)

		if (Type == UNHOLY) then
			Unholy = Unholy + 1
		elseif (Type == DEATH) then
			Death = Death + 1
		end
	end

	if select(3, GetRuneCooldown(5)) then
		local Type = GetRuneType(5)

		if (Type == FROST) then
			Frost = Frost + 1
		elseif (Type == DEATH) then
			Death = Death + 1
		end
	end

	if select(3, GetRuneCooldown(6)) then
		local Type = GetRuneType(6)

		if (Type == FROST) then
			Frost = Frost + 1
		elseif (Type == DEATH) then
			Death = Death + 1
		end
	end

	if (Frost > 0 and Unholy > 0) or (Frost > 0 and Death > 0) or (Unholy > 0 and Death > 0) or (Death > 1) then
		return true
	end
end

local UpdateValue = function(self)
	if not CanDeathStrike() then
		self.DSBar:SetValue(0)
		self.DSBar:Hide()
		return
	end

	local Healing = 0 -- How much the strike will heal for
	local Limit = GetTime() - 5

	for i = #DmgTaken, 1, -1 do
		if (Limit > DmgTaken[i][1]) then
			tinsert(Tables, tremove(DmgTaken, i))
		else
			Healing = Healing + DmgTaken[i][2]
		end
	end

	TotalHP = UnitHealthMax("player")
	HP = UnitHealth("player")
	Healing = Healing * 0.2 * VampBloodMult
	SevenPercent = TotalHP * 0.07 -- Death Strike minimum value is 7% of your max health

	if (SevenPercent > Healing) then
		Healing = SevenPercent
	end

	self.DSBar:SetMinMaxValues(0, TotalHP)
	self.DSBar:SetValue(HP + Healing)
	self.DSBar:Show()
end

local OnUpdate = function(self, elapsed)
	self.Elapsed = self.Elapsed + elapsed

	if (self.Elapsed >= 0.2) then
		UpdateValue(self)

		self.Elapsed = 0
	end
end

function Frame:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:SetScript("OnUpdate", nil)
end

function Frame:PLAYER_REGEN_DISABLED()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RUNE_POWER_UPDATE("player")
	self:SetScript("OnUpdate", OnUpdate)
end

function Frame:COMBAT_LOG_EVENT_UNFILTERED(...)
	Timestamp, EventType, _, _, _, _, _, DestGUID = ...

	if (not LogEvents[EventType] or DestGUID ~= MyGUID) then
		return
	end

	if (EventType == "SPELL_ABSORBED") then
		if (type(select(12, ...)) == "number") then
			AbsorbNum = 15
		else
			AbsorbNum = 12
		end

		AbsorbGUID, _, _, _, _, _, _, AbsorbAmount = select(AbsorbNum, ...)

		if (AbsorbGUID == MyGUID) then
			DmgTable = GetTable()
			DmgTable[1] = GetTime()
			DmgTable[2] = AbsorbAmount

			tinsert(DmgTaken, DmgTable)
		end
	else
		DmgTable = GetTable()
		DmgTable[1] = GetTime()
		DmgTable[2] = select(LogEvents[EventType], ...)

		tinsert(DmgTaken, DmgTable)
	end

	UpdateValue(self)
end

function Frame:RUNE_POWER_UPDATE(unit)
	if (unit ~= "player") then
		return
	end

	if CanDeathStrike() then
		self.Ignore = false
	else
		self.Ignore = true
		self.DSBar:SetValue(0)
		self.DSBar:Hide()
	end
end

function Frame:PLAYER_TALENT_UPDATE()
	if (GetActiveTalentGroup() == 1) then -- Blood
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("RUNE_POWER_UPDATE")

		if (not self.DSBar) then
			local DSBar = CreateFrame("StatusBar", nil, HydraUI.UnitFrames["player"])
			DSBar:SetAllPoints(HydraUI.UnitFrames["player"].Health)
			DSBar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
			DSBar:SetStatusBarColor(0.6, 0.02, 0.8)
			DSBar:SetFrameLevel(HydraUI.UnitFrames["player"].Health:GetFrameLevel() - 1)
			DSBar:SetMinMaxValues(0, 1)
			DSBar:SetValue(0)
			DSBar:Hide()

			self.DSBar = DSBar
		end
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("RUNE_POWER_UPDATE")

		if self.DSBar then
			self.DSBar:SetValue(0)
			self.DSBar:Hide()
		end
	end
end

function Frame:PLAYER_ENTERING_WORLD()
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:PLAYER_TALENT_UPDATE()
end

function Frame:UNIT_AURA(unit)
	if (unit ~= "player") then
		return
	end

	if FindAura("player", VAMPIRIC_BLOOD, "HELPFUL") then
		VampBloodMult = 1.25 -- 25% increased healing
	else
		VampBloodMult = 1
	end
end

Frame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)