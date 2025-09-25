local HydraUI, Language, Assets, Settings = select(2, ...):get()

local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local floor = floor
local format = format
local FPSLabel = Language["FPS"]
local MSLabel = Language["MS"]

local OnEnter = function(self)
	self:SetTooltip()

        local _, _, HomeLatency, WorldLatency = GetNetStats()

        GameTooltip:AddLine(Language["Latency:"], 1, 0.7, 0)
        GameTooltip:AddLine(format(Language["%s ms (home)"], HomeLatency), 1, 1, 1)
        GameTooltip:AddLine(format(Language["%s ms (world)"], WorldLatency), 1, 1, 1)

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, elapsed)
	self.Elapsed = self.Elapsed + elapsed

        if (self.Elapsed > 1) then
                local fps = floor(GetFramerate())
                local _, _, _, worldLatency = GetNetStats()

                if (fps ~= self.LastFPS) or (worldLatency ~= self.LastLatency) then
                        self.LastFPS = fps
                        self.LastLatency = worldLatency

                        self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r |cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], FPSLabel, HydraUI.ValueColor, fps, Settings["data-text-label-color"], MSLabel, HydraUI.ValueColor, worldLatency)
                end

                self.Elapsed = 0
        end
end

local OnEnable = function(self)
        self:SetScript("OnUpdate", Update)
        self:SetScript("OnEnter", OnEnter)
        self:SetScript("OnLeave", OnLeave)

        self.Elapsed = 0
        self.LastFPS = nil
        self.LastLatency = nil

        self:Update(2)
end

local OnDisable = function(self)
        self:SetScript("OnUpdate", nil)
        self:SetScript("OnEnter", nil)
        self:SetScript("OnLeave", nil)

        self.Elapsed = 0
        self.LastFPS = nil
        self.LastLatency = nil

        self.Text:SetText("")
end

HydraUI:AddDataText("System", OnEnable, OnDisable, Update)
