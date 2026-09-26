local HydraUI, Language, Assets, Settings = select(2, ...):get()

local Label = MAIL_LABEL

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Senders = {GetLatestThreeSenders()}
	local HasSender

	for Index = 1, 3 do
		local Sender = Senders[Index]

		if (Sender and Sender ~= "") then
			if (not HasSender) then
				GameTooltip:AddLine(HAVE_MAIL_FROM)
			end

			GameTooltip:AddLine(Sender, 1, 1, 1)
			HasSender = true
		end
	end

	if HasSender then
		GameTooltip:Show()
	elseif HasNewMail() then
		GameTooltip:AddLine(HAVE_MAIL)
		GameTooltip:Show()
	end
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, event)
	local One, Two, Three = GetLatestThreeSenders()
	local Result = 0

	if One then
		Result = Result + 1
	end

	if Two then
		Result = Result + 1
	end

	if Three then
		Result = Result + 1
	end

	if (HasNewMail() and Result == 0) then
		Result = Result + 1
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, HydraUI.ValueColor, Result)
end

local OnEnable = function(self)
	self:RegisterEvent("UPDATE_PENDING_MAIL")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update("player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UPDATE_PENDING_MAIL")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

HydraUI:AddDataText(Label, OnEnable, OnDisable, Update)