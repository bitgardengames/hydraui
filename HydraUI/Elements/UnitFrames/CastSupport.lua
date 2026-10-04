local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local Class, Colors

-- Select the spell-info adapter once.  The hot event path is shared by every
-- client and does not repeatedly inspect the project version.
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
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID = UnitChannelInfo(unit)
		if (issecretvalue(startTime) and not canaccessvalue(startTime)) or (issecretvalue(endTime) and not canaccessvalue(endTime)) then
			return
		end
		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID
	end
else
	CastingInfo = UnitCastingInfo
	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID = UnitChannelInfo(unit)
		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID
	end
end

local function Install(UF, Hider)
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

local function FinishCast(bar, failed)
	bar.casting,bar.channeling=nil,nil
	bar:SetScript("OnUpdate",nil)
	if failed then
		if bar.PostCastFail then
			bar:PostCastFail()
		end
	elseif bar.PostCastStop then
		bar:PostCastStop()
	end
	local hold=failed and (bar.timeToHold or 0) or 0
	if hold>0 then
		bar.holdUntil=GetTime()+hold else bar:Hide()
	end
end
local function CastOnUpdate(bar)
	local now=GetTime()
	if bar.holdUntil then if now>=bar.holdUntil then bar.holdUntil=nil
	bar:Hide() end return end
	local value=bar.channeling and (bar.endTime-now) or (now-bar.startTime)
	bar:SetValue(value)
	bar.Time:SetFormattedText("%.1f",math.max(0,bar.channeling and value or bar.duration-value))
end
local function StartCast(frame,event,unit)
	if unit~=frame.unit then
		return
	end
	local bar=frame.Castbar
	local channel=event:find("CHANNEL")~=nil or event:find("EMPOWER")~=nil
	local adapter=channel and ChannelInfo or CastingInfo
	local name,text,texture,startMS,endMS,isTradeSkill,castID,notInterruptible,spellID=adapter(unit)
	-- A forced refresh does not tell us which kind of spell is active. Try the
	-- channel adapter when the ordinary cast adapter has no result.
	if event=="ForceUpdate" and not name then
		channel=true
		name,text,texture,startMS,endMS,isTradeSkill,castID,notInterruptible,spellID=ChannelInfo(unit)
	end
	if not name or (isTradeSkill and not bar.showTradeSkills) then
		return FinishCast(bar)
	end
	bar.startTime,bar.endTime=startMS/1000,endMS/1000
	bar.duration=bar.endTime-bar.startTime
	bar.casting,bar.channeling=not channel,channel
	bar.castID,bar.spellID=castID,spellID
	bar.notInterruptible=notInterruptible
	bar:SetMinMaxValues(0,bar.duration)
	local now=GetTime()
	bar:SetValue(channel and math.max(0,bar.endTime-now) or math.max(0,now-bar.startTime))
	bar.Text:SetText(text or name)
	bar.Icon:SetTexture(texture)
	bar:SetScript("OnUpdate",CastOnUpdate)
	bar:Show()
	if bar.SafeZone and unit=="player" then local lag=select(4,GetNetStats())/1000
	bar.SafeZone:SetWidth(math.min(bar:GetWidth(),bar:GetWidth()*lag/bar.duration))
	bar.SafeZone:ClearAllPoints()
	bar.SafeZone:SetPoint(channel and "LEFT" or "RIGHT") end
	if bar.PostCastStart then
		bar:PostCastStart(unit)
	end
end
local function StopCast(frame,event,unit) if unit==frame.unit then FinishCast(frame.Castbar,event:find("FAILED") or event:find("INTERRUPTED")) end end
local function Interruptible(frame,event,unit) if unit==frame.unit then frame.Castbar.notInterruptible=event:find("NOT_INTERRUPTIBLE")~=nil
	if frame.Castbar.PostCastInterruptible then
		frame.Castbar:PostCastInterruptible(unit) end end
	end
local CastEvents={UNIT_SPELLCAST_START=StartCast,UNIT_SPELLCAST_CHANNEL_START=StartCast,UNIT_SPELLCAST_DELAYED=StartCast,UNIT_SPELLCAST_CHANNEL_UPDATE=StartCast,UNIT_SPELLCAST_STOP=StopCast,UNIT_SPELLCAST_CHANNEL_STOP=StopCast,UNIT_SPELLCAST_FAILED=StopCast,UNIT_SPELLCAST_INTERRUPTED=StopCast,UNIT_SPELLCAST_INTERRUPTIBLE=Interruptible,UNIT_SPELLCAST_NOT_INTERRUPTIBLE=Interruptible}
if HydraUI.IsMainline then
	CastEvents.UNIT_SPELLCAST_EMPOWER_START=StartCast
	CastEvents.UNIT_SPELLCAST_EMPOWER_UPDATE=StartCast
	CastEvents.UNIT_SPELLCAST_EMPOWER_STOP=StopCast
end
local function EnableCast(frame)
	local bar=frame.Castbar
	if not bar then
		return
	end
	bar.__owner=frame
	bar.ForceUpdate=function() StartCast(frame,"ForceUpdate",frame.unit) end
	for event,handler in pairs(CastEvents) do
		frame:RegisterEvent(event,handler)
	end
	if frame.unit=="player" and not frame.isNamePlate then
		if CastingBarFrame_SetUnit then
			CastingBarFrame_SetUnit(CastingBarFrame,nil)
			CastingBarFrame_SetUnit(PetCastingBarFrame,nil)
		elseif PlayerCastingBarFrame then
			PlayerCastingBarFrame:SetUnit(nil)
			if PetCastingBarFrame then
				PetCastingBarFrame:SetUnit(nil)
			end
		end
	end
	return true
end
ns.UnitFrameComponentHandlers.Castbar={update=function() end,enable=EnableCast,disable=function(frame) FinishCast(frame.Castbar) end}

end

ns.UnitFrameCastSupport = Install
