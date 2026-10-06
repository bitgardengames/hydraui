local HydraUI, Language, Assets, Settings = select(2, ...):get()

local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	-- Location
	local ZoneText = GetRealZoneText()
	local SubZoneText = GetMinimapZoneText()
	local PVPType, IsFFA, Faction = GetZonePVPInfo()
	local Color = HydraUI.ZoneColors[PVPType or "other"]
	local Label

	if ZoneText ~= SubZoneText then
		Label = format("%s - %s", ZoneText, SubZoneText)
	else
		Label = ZoneText
	end

	GameTooltip:AddLine(Label, Color[1], Color[2], Color[3])

	if PVPType == "friendly" or PVPType == "hostile" then
		GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, Faction), Color[1], Color[2], Color[3])
	elseif PVPType == "sanctuary" then
		GameTooltip:AddLine(SANCTUARY_TERRITORY, Color[1], Color[2], Color[3])
	elseif IsFFA then
		GameTooltip:AddLine(FREE_FOR_ALL_TERRITORY, Color[1], Color[2], Color[3])
	else
		GameTooltip:AddLine(CONTESTED_TERRITORY, Color[1], Color[2], Color[3])
	end

	-- Coordinates
	local MapID = GetBestMapForUnit("player")

	if MapID then
		local Position = GetPlayerMapPosition(MapID, "player")

		if Position then
			local X, Y = Position:GetXY()

			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(Language["Coordinates"])
			GameTooltip:AddLine(format("%.2f, %.2f", X * 100, Y * 100), 1, 1, 1)
		end
	end

	self.TooltipShown = true

	GameTooltip:Show()
end

local OnLeave = function(self)
	GameTooltip:Hide()
	self.TooltipShown = false
end

local Update = function(self)
	local MapID = GetBestMapForUnit("player")
	local Position = MapID and GetPlayerMapPosition(MapID, "player")

	if Position then
		local X, Y = Position:GetXY()

		self.Text:SetFormattedText("|cFF%s%.2f|r, |cFF%s%.2f|r", HydraUI.ValueColor, X * 100, HydraUI.ValueColor, Y * 100)
	else
		self.Text:SetText("--, --")
	end

	if self.TooltipShown then
		GameTooltip:ClearLines()
		OnEnter(self)
	end
end

local OnEnable = function(self)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	if self.Ticker then
		self.Ticker:Cancel()
	end

	self.Ticker = C_Timer.NewTicker(0.5, function()
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
	self.TooltipShown = false

	self.Text:SetText("")
end

HydraUI:AddDataText("Coordinates", OnEnable, OnDisable, Update)
