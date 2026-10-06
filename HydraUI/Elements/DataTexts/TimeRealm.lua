local HydraUI, Language, Assets, Settings = select(2, ...):get()

local gsub = gsub
local format = format
local GameTime_GetGameTime = GameTime_GetGameTime

local OnMouseUp = function(self, button)
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	if ToggleCalendar and button == "LeftButton" then
		ToggleCalendar()
	else
		TimeManager_Toggle()
	end
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local HomeLatency, WorldLatency = select(3, GetNetStats())
	local Framerate = floor(GetFramerate())
	local LocalTime = GameTime_GetLocalTime(true)

	GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_LOCALTIME, 1, 0.7, 0)
	GameTooltip:AddLine(LocalTime, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Latency:"], 1, 0.7, 0)
	GameTooltip:AddLine(format(Language["%s ms (home)"], HomeLatency), 1, 1, 1)
	GameTooltip:AddLine(format(Language["%s ms (world)"], WorldLatency), 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Framerate:"], 1, 0.7, 0)
	GameTooltip:AddLine(Framerate .. " " .. FPS_ABBR, 1, 1, 1)

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Time = GameTime_GetGameTime(true)

	Time = gsub(Time, "%a+", format("|cFF%s%s|r", HydraUI.ValueColor, "%1"))

	self.Text:SetText(Time)
end

local OnEnable = function(self)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)

	if self.Ticker then
		self.Ticker:Cancel()
	end

	self.Ticker = C_Timer.NewTicker(10, function()
		Update(self)
	end)

	Update(self)
end

local OnDisable = function(self)
	if self.Ticker then
		self.Ticker:Cancel()
		self.Ticker = nil
	end

	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)
	self.Text:SetText("")
end

HydraUI:AddDataText("Time - Realm", OnEnable, OnDisable, Update)
