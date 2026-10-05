local HydraUI, Language, Assets, Settings = select(2, ...):get()

local select = select
local GetMaxNumQuestsCanAccept = C_QuestLog.GetMaxNumQuestsCanAccept
local GetQuestDifficultyColor = GetQuestDifficultyColor
local Label = QUESTS_LABEL

local GetNumQuests, GetQuestInfo

if HydraUI.IsMainline then
	GetNumQuests = C_QuestLog.GetNumQuestLogEntries
	GetQuestInfo = C_QuestLog.GetInfo
else
	GetNumQuests = GetNumQuestLogEntries
	GetQuestInfo = function(Index)
		local Title, Level, _, IsHeader, _, IsComplete = GetQuestLogTitle(Index)

		return {
			title = Title,
			level = Level,
			isHeader = IsHeader,
			isComplete = IsComplete,
		}
	end
end

local OnMouseUp = function()
	ToggleFrame(HydraUI.IsMainline and QuestMapFrame or QuestLogFrame)
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	GameTooltip:AddLine(Label)

	for Index = 1, GetNumQuests() do
		local Info = GetQuestInfo(Index)

		if Info and not Info.isHeader then
			local Color = GetQuestDifficultyColor(Info.level)
			local QuestText = format("[%s] %s", Info.level, Info.title)
			local IsComplete = Info.isComplete == true or Info.isComplete == 1

			if IsComplete then
				GameTooltip:AddDoubleLine(QuestText, COMPLETE, Color.r, Color.g, Color.b, 0, 1, 0)
			else
				GameTooltip:AddLine(QuestText, Color.r, Color.g, Color.b)
			end
		end
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s/%s|r", Settings["data-text-label-color"], Label, HydraUI.ValueColor, select(2, GetNumQuests()), GetMaxNumQuestsCanAccept())
end

local OnEnable = function(self)
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("QUEST_LOG_UPDATE")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

HydraUI:AddDataText("Quests", OnEnable, OnDisable, Update)
