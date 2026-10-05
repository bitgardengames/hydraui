local HydraUI, Language, Assets, Settings = select(2, ...):get()

local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local floor = floor
local select = select
local FPSLabel = Language["FPS"]
local MSLabel = Language["MS"]

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local HomeLatency, WorldLatency = select(3, GetNetStats())

	GameTooltip:AddLine(Language["Latency:"], 1, 0.7, 0)
	GameTooltip:AddLine(format(Language["%s ms (home)"], HomeLatency), 1, 1, 1)
	GameTooltip:AddLine(format(Language["%s ms (world)"], WorldLatency), 1, 1, 1)

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r |cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], FPSLabel, HydraUI.ValueColor, floor(GetFramerate()), Settings["data-text-label-color"], MSLabel, HydraUI.ValueColor, select(4, GetNetStats()))
end

local OnEnable = function(self)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self.Ticker = C_Timer.NewTicker(1, function()
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

	self.Text:SetText("")
end

HydraUI:AddDataText("System", OnEnable, OnDisable, Update)
