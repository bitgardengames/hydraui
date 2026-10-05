local addon, ns = ...
local HydraUI, _, _, Settings = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local Class, Colors

-- Select the spell-info adapter once.  The hot event path is shared by every client and does not repeatedly inspect the project version.
local CastingInfo, ChannelInfo
if HydraUI.IsMainline then
	CastingInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,castID,notInterruptible,spellID = UnitCastingInfo(unit)

		if (issecretvalue(startTime) and not canaccessvalue(startTime)) or (issecretvalue(endTime) and not canaccessvalue(endTime)) then
			return
		end

		return name,text,texture,startTime,endTime,isTradeSkill,castID,notInterruptible,spellID
	end

	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID,isEmpowered,numStages = UnitChannelInfo(unit)

		if (issecretvalue(startTime) and not canaccessvalue(startTime)) or (issecretvalue(endTime) and not canaccessvalue(endTime)) then
			return
		end

		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID,isEmpowered,numStages
	end
else
	CastingInfo = UnitCastingInfo
	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID,isEmpowered,numStages = UnitChannelInfo(unit)

		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID,isEmpowered,numStages
	end
end

local UF = HydraUI:GetModule("Unit Frames")
UF.PostCastStart = function(self, unit)
	if self.notInterruptible then
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
	elseif self.ClassColor and UnitIsPlayer(self.__owner.unit) then
		_, Class = UnitClass(self.__owner.unit)

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
	elseif self.ClassColor and UnitIsPlayer(self.__owner.unit) then
		_, Class = UnitClass(self.__owner.unit)

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

local FALLBACK_ICON = 136243
local FAILED = _G.FAILED or "Failed"
local INTERRUPTED = _G.INTERRUPTED or "Interrupted"
local LibCC = (HydraUI.IsVanilla or HydraUI.IsTBC) and LibStub and LibStub("LibClassicCasterino", true)

if LibCC then
	CastingInfo = function(unit)
		return LibCC:UnitCastingInfo(unit)
	end
	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID = LibCC:UnitChannelInfo(unit)
		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID
	end
end

local function ResetCast(bar)
	bar.castID = nil
	bar.casting = nil
	bar.channeling = nil
	bar.empowering = nil
	bar.notInterruptible = nil
	bar.spellID = nil
end

local function SameCast(bar, castID, spellID)
	return bar:IsShown() and (not castID or not bar.castID or bar.castID == castID) and (not spellID or not bar.spellID or bar.spellID == spellID)
end

local function FinishCast(bar, failed, unit, spellID)
	if not bar:IsShown() then
		ResetCast(bar)

		return
	end
	if failed then
		if bar.Text then
			bar.Text:SetText(failed == "FAILED" and FAILED or INTERRUPTED)
		end

		if bar.Spark then
			bar.Spark:Hide()
		end

		bar.holdTime = bar.timeToHold or 0
		bar:SetValue(bar.max or 0)
		ResetCast(bar)

		if bar.PostCastFail then
			bar:PostCastFail(unit, spellID)
		end

		if bar.holdTime == 0 then
			bar:Hide()
		end
	else
		ResetCast(bar)
		bar.holdTime = 0

		if bar.PostCastStop then
			bar:PostCastStop(unit, spellID)
		end

		bar:Hide()
	end
end

local function CastOnUpdate(bar, elapsed)
	if bar.casting or bar.channeling or bar.empowering then
		local increasing = bar.casting or bar.empowering

		bar.duration = bar.duration + (increasing and elapsed or -elapsed)

		if (increasing and bar.duration >= bar.max) or (bar.channeling and bar.duration <= 0) then
			local spellID = bar.spellID
			ResetCast(bar)
			bar:Hide()

			if bar.PostCastStop then
				bar:PostCastStop(bar.__owner.unit, spellID)
			end

			return
		end
		if bar.Time then
			if bar.delay and bar.delay ~= 0 then
				bar.Time:SetFormattedText("%.1f|cffff0000%s%.2f|r", bar.duration, increasing and "+" or "-", bar.delay)
			else
				bar.Time:SetFormattedText("%.1f", bar.duration)
			end
		end

		bar:SetValue(bar.duration)
	elseif bar.holdTime and bar.holdTime > 0 then
		bar.holdTime = bar.holdTime - elapsed

		if bar.holdTime <= 0 then
			bar:Hide()
		end
	end
end

local function ReadCast(unit)
	local name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID = CastingInfo(unit)

	if name then
		return name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, false, false
	end

	local numStages

	name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, _, numStages = ChannelInfo(unit)

	return name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, true, numStages and numStages > 0
end

local function StartCast(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local bar = frame.Castbar
	local name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, channel, empower = ReadCast(unit)

	if not name or (isTradeSkill and not bar.showTradeSkills) then
		ResetCast(bar)
		bar:Hide()

		return
	end

	if empower and GetUnitEmpowerHoldAtMaxTime then
		endMS = endMS + GetUnitEmpowerHoldAtMaxTime(unit)
	end

	bar.startTime, bar.endTime = startMS / 1000, endMS / 1000
	bar.max = bar.endTime - bar.startTime
	bar.casting, bar.channeling, bar.empowering = not channel, channel and not empower, empower
	bar.duration = bar.channeling and (bar.endTime - GetTime()) or (GetTime() - bar.startTime)
	bar.delay, bar.holdTime = 0, 0
	bar.castID, bar.spellID = castID, spellID
	bar.notInterruptible = notInterruptible
	bar:SetMinMaxValues(0, bar.max)
	bar:SetValue(bar.duration)

	if bar.Text then
		bar.Text:SetText(text ~= "" and text or name)
	end

	if bar.Time then
		bar.Time:SetText()
	end

	if bar.Icon then
		bar.Icon:SetTexture(texture or FALLBACK_ICON)
	end

	if bar.Shield then
		bar.Shield:SetShown(notInterruptible)
	end

	if bar.Spark then
		bar.Spark:Show()
	end

	bar:Show()

	if bar.SafeZone and unit == "player" and bar.max > 0 then
		local horizontal = bar:GetOrientation() == "HORIZONTAL"
		local ratio = math.min(1, (select(4, GetNetStats()) / 1000) / bar.max)

		bar.SafeZone:ClearAllPoints()
		bar.SafeZone:SetPoint(horizontal and "TOP" or "LEFT")
		bar.SafeZone:SetPoint(horizontal and "BOTTOM" or "RIGHT")

		local reverse = bar:GetReverseFill()

		if bar.channeling then
			bar.SafeZone:SetPoint(reverse and (horizontal and "RIGHT" or "TOP") or (horizontal and "LEFT" or "BOTTOM"))
		else
			bar.SafeZone:SetPoint(reverse and (horizontal and "LEFT" or "BOTTOM") or (horizontal and "RIGHT" or "TOP"))
		end

		local setSize = horizontal and bar.SafeZone.SetWidth or bar.SafeZone.SetHeight
		local getSize = horizontal and bar.GetWidth or bar.GetHeight
		setSize(bar.SafeZone, getSize(bar) * ratio)
	end

	if bar.PostCastStart then
		bar:PostCastStart(unit)
	end
end

local function UpdateCast(frame, event, unit, castID, spellID)
	if unit ~= frame.unit or not SameCast(frame.Castbar, castID, spellID) then
		return
	end

	local bar = frame.Castbar
	local name, _, _, startMS, endMS

	if event == "UNIT_SPELLCAST_DELAYED" then
		name, _, _, startMS, endMS = CastingInfo(unit)
	else
		name, _, _, startMS, endMS = ChannelInfo(unit)
	end

	if not name then
		return
	end

	if bar.empowering and GetUnitEmpowerHoldAtMaxTime then
		endMS = endMS + GetUnitEmpowerHoldAtMaxTime(unit)
	end

	local startTime, endTime = startMS / 1000, endMS / 1000
	local delta

	if bar.channeling then
		delta = bar.startTime - startTime
		bar.duration = endTime - GetTime()
	else
		delta = startTime - bar.startTime
		bar.duration = GetTime() - startTime
	end

	bar.delay = (bar.delay or 0) + math.max(0, delta)
	bar.startTime, bar.endTime, bar.max = startTime, endTime, endTime - startTime
	bar:SetMinMaxValues(0, bar.max)
	bar:SetValue(bar.duration)

	if bar.PostCastUpdate then
		bar:PostCastUpdate(unit)
	end
end

local function StopCast(frame, event, unit, castID, spellID)
	local bar = frame.Castbar

	if unit ~= frame.unit or not SameCast(bar, castID, spellID) then
		return
	end

	local failed = event == "UNIT_SPELLCAST_FAILED" and "FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" and "INTERRUPTED"

	FinishCast(bar, failed, unit, spellID)
end

local function Interruptible(frame, event, unit)
	local bar = frame.Castbar

	if unit ~= frame.unit or not bar:IsShown() then
		return
	end

	bar.notInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"

	if bar.Shield then
		bar.Shield:SetShown(bar.notInterruptible)
	end

	if bar.PostCastInterruptible then
		bar:PostCastInterruptible(unit)
	end
end

local CastEvents = {
	UNIT_SPELLCAST_START = StartCast,
	UNIT_SPELLCAST_CHANNEL_START = StartCast,
	UNIT_SPELLCAST_DELAYED = UpdateCast,
	UNIT_SPELLCAST_CHANNEL_UPDATE = UpdateCast,
	UNIT_SPELLCAST_STOP = StopCast,
	UNIT_SPELLCAST_CHANNEL_STOP = StopCast,
	UNIT_SPELLCAST_FAILED = StopCast,
	UNIT_SPELLCAST_INTERRUPTED = StopCast,
	UNIT_SPELLCAST_INTERRUPTIBLE = Interruptible,
	UNIT_SPELLCAST_NOT_INTERRUPTIBLE = Interruptible,
}

if HydraUI.IsMainline then
	CastEvents.UNIT_SPELLCAST_EMPOWER_START = StartCast
	CastEvents.UNIT_SPELLCAST_EMPOWER_UPDATE = UpdateCast
	CastEvents.UNIT_SPELLCAST_EMPOWER_STOP = StopCast
end

local function EnableCast(frame)
	local bar = frame.Castbar

	if not bar then
		return
	end

	bar.__owner = frame
	bar.ForceUpdate = function()
		StartCast(frame, "ForceUpdate", frame.unit)
	end

	bar:SetScript("OnUpdate", bar.OnUpdate or CastOnUpdate)

	bar:Hide()

	if LibCC then
		bar.__classicCallback = function(event, ...)
			local handler = CastEvents[event]

			if handler then
				handler(frame, event, ...)
			end
		end

		for event in pairs(CastEvents) do
			LibCC.RegisterCallback(frame, event, bar.__classicCallback)
		end
	else
		for event, handler in pairs(CastEvents) do
			frame:RegisterEvent(event, handler)
		end
	end
	if frame.unit == "player" and not frame.isNamePlate then
		if CastingBarFrame_SetUnit then
			CastingBarFrame_SetUnit(CastingBarFrame,nil)
			CastingBarFrame_SetUnit(PetCastingBarFrame, nil)
		elseif PlayerCastingBarFrame then
			PlayerCastingBarFrame:SetUnit(nil)

			if PetCastingBarFrame then
				PetCastingBarFrame:SetUnit(nil)
			end
		end
	end

	return true
end

local function DisableCast(frame)
	local bar = frame.Castbar

	ResetCast(bar)
	bar:SetScript("OnUpdate", nil)
	bar:Hide()

	if LibCC then
		for event in pairs(CastEvents) do
			LibCC.UnregisterCallback(frame,event)
		end
	else
		for event, handler in pairs(CastEvents) do
			frame:UnregisterEvent(event, handler)
		end
	end
end

UF.ElementHandlers.Castbar = {
	-- Cast events drive this element directly; full frame refreshes need no work.
	update = function()
	end,
	enable = EnableCast,
	disable = DisableCast,
}