local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local GetTime = GetTime

local function Install(UF, Hider)
local ActiveTotemBars = {}
local TotemUpdater = CreateFrame("Frame")

TotemUpdater:Hide()

local TotemOnUpdate = function(self)
	local CurrentTime = GetTime()

	for Bar in pairs(ActiveTotemBars) do
		local Time = Bar.Duration - (CurrentTime - Bar.Start)

		Bar:SetValue(Time)

		if Time < 0 then
			ActiveTotemBars[Bar] = nil
			Bar:Hide()
		end
	end

	if not next(ActiveTotemBars) then
		self:SetScript("OnUpdate", nil)
		self:Hide()
	end
end

UF.PostUpdateTotems = function(self, slot, havetotem, name, start, duration, icon)
	if not self[slot] then
		return
	end

	if start and duration > 0 then
		local Bar = self[slot].Bar

		if not Bar then
			return
		end

		Bar:SetMinMaxValues(0, duration)
		Bar:SetValue(duration - (GetTime() - start))
		Bar.Duration = duration
		Bar.Start = start
		Bar:Show()
		ActiveTotemBars[Bar] = true

		if not TotemUpdater:GetScript("OnUpdate") then
			TotemUpdater:SetScript("OnUpdate", TotemOnUpdate)
			TotemUpdater:Show()
		end
	else
		local Bar = self[slot].Bar

		ActiveTotemBars[Bar] = nil

		if not next(ActiveTotemBars) then
			TotemUpdater:SetScript("OnUpdate", nil)
			TotemUpdater:Hide()
		end

		Bar:Hide()
	end
end

local function UpdateTotems(frame)
	local totems=frame.Totems
	if not totems then
		return
	end
	for slot=1,#totems do local have,name,start,duration,icon=GetTotemInfo(slot)
	if totems.PostUpdate then
		totems:PostUpdate(slot,have,name,start,duration,icon) end
	end
end
local function EnableTotems(frame)
	if not frame.Totems then
		return
	end
	frame.Totems.__owner=frame
	frame.Totems.ForceUpdate=function() UpdateTotems(frame) end
	frame:RegisterEvent("PLAYER_TOTEM_UPDATE",UpdateTotems,true)
	return true
end
ns.UnitFrameComponentHandlers.Totems={update=UpdateTotems,enable=EnableTotems,disable=function(frame) for i=1,#frame.Totems do frame.Totems[i]:Hide() end end}

end

ns.UnitFrameTotemSupport = Install
