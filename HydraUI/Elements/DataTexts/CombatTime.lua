local HydraUI, Language, Assets, Settings = select(2, ...):get()

local format = format
local date = date
local GetTime = GetTime

local SecondsToTime = function(seconds)
	return format("%s:%s", date("%M", seconds), date("%S", seconds))
end

local UpdateElapsed = function(self)
	self.Text:SetText(SecondsToTime(GetTime() - self.CombatStart))
end

local Update = function(self, event)
	if event == "PLAYER_REGEN_DISABLED" then
		self.CombatStart = GetTime()
		self.Ticker = C_Timer.NewTicker(1, function()
			UpdateElapsed(self)
		end)
		self.Text:SetText(SecondsToTime(0))
		self.Text:SetTextColor(HydraUI:HexToRGB(HydraUI.ValueColor))
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.Ticker then
			self.Ticker:Cancel()
			self.Ticker = nil
		end

		self.Text:SetTextColor(1, 1, 1)
	end
end

local OnEnable = function(self)
	self.CombatStart = GetTime()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", Update)

	self.Text:SetText(SecondsToTime(0))
end

local OnDisable = function(self)
	if self.Ticker then
		self.Ticker:Cancel()
		self.Ticker = nil
	end

	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", nil)
	self.CombatStart = nil

	self.Text:SetText("")
end

HydraUI:AddDataText("Combat Time", OnEnable, OnDisable, Update)
