local addon, ns = ...
local HydraUI = ns:get()

local GetTime = GetTime

local UF = HydraUI:GetModule("Unit Frames")
local activeTotemBars = {}
local totemUpdater = CreateFrame("Frame")

totemUpdater:Hide()

local function TotemOnUpdate(self)
	local currentTime = GetTime()

	for bar in pairs(activeTotemBars) do
		local timeLeft = bar.Duration - (currentTime - bar.Start)

		bar:SetValue(timeLeft)

		if timeLeft < 0 then
			activeTotemBars[bar] = nil
			bar:Hide()
		end
	end

	if not next(activeTotemBars) then
		self:SetScript("OnUpdate", nil)
		self:Hide()
	end
end

UF.PostUpdateTotems = function(self, slot, haveTotem, name, startTime, duration, icon)
	local segment = self[slot]
	if not segment or not segment.Bar then
		return
	end

	local bar = segment.Bar
	if haveTotem and startTime and duration > 0 then
		bar:SetMinMaxValues(0, duration)
		bar:SetValue(duration - (GetTime() - startTime))
		bar.Duration = duration
		bar.Start = startTime
		bar:Show()
		activeTotemBars[bar] = true

		if not totemUpdater:GetScript("OnUpdate") then
			totemUpdater:SetScript("OnUpdate", TotemOnUpdate)
			totemUpdater:Show()
		end
	else
		activeTotemBars[bar] = nil
		bar:Hide()
	end

	if not next(activeTotemBars) then
		totemUpdater:SetScript("OnUpdate", nil)
		totemUpdater:Hide()
	end
end

local function UpdateTotems(frame)
	local totems = frame.Totems
	if not totems then
		return
	end

	for slot = 1, #totems do
		local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
		if totems.PostUpdate then
			totems:PostUpdate(slot, haveTotem, name, startTime, duration, icon)
		end
	end
end

local function EnableTotems(frame)
	if not frame.Totems then
		return
	end
	frame.Totems.__owner = frame
	frame.Totems.ForceUpdate = function()
		UpdateTotems(frame)
	end
	frame:RegisterEvent("PLAYER_TOTEM_UPDATE", UpdateTotems, true)
	return true
end

local function DisableTotems(frame)
	frame:UnregisterEvent("PLAYER_TOTEM_UPDATE", UpdateTotems)
	for i = 1, #frame.Totems do
		local bar = frame.Totems[i].Bar
		if bar then
			activeTotemBars[bar] = nil
			bar:Hide()
		end
		frame.Totems[i]:Hide()
	end
	if not next(activeTotemBars) then
		totemUpdater:SetScript("OnUpdate", nil)
		totemUpdater:Hide()
	end
end

UF.ElementHandlers.Totems = {
	update = UpdateTotems,
	enable = EnableTotems,
	disable = DisableTotems,
}
