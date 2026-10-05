local HydraUI, Language, Assets, Settings = select(2, ...):get()

local select = select
local GetMaxNumQuestsCanAccept = C_QuestLog.GetMaxNumQuestsCanAccept
local GetQuestDifficultyColor = GetQuestDifficultyColor
local Label = QUESTS_LABEL
local DungeonLabel = TRACKER_HEADER_DUNGEON or "Dungeon"
local DungeonQuestTagID = Enum and Enum.QuestTag and Enum.QuestTag.Dungeon or 81
local GetQuestTagInfo = C_QuestLog.GetQuestTagInfo or GetQuestTagInfo

local GetNumQuests, GetQuestInfo

if HydraUI.IsMainline then
	GetNumQuests = C_QuestLog.GetNumQuestLogEntries
	GetQuestInfo = C_QuestLog.GetInfo
else
	GetNumQuests = GetNumQuestLogEntries
	GetQuestInfo = function(Index)
		local Title, Level, _, IsHeader, _, IsComplete, _, QuestID = GetQuestLogTitle(Index)

		return {
			title = Title,
			level = Level,
			isHeader = IsHeader,
			isComplete = IsComplete,
			questID = QuestID,
		}
	end
end

local IsDungeonQuest = function(QuestID)
	if not GetQuestTagInfo or not QuestID then
		return false
	end

	local TagInfo = GetQuestTagInfo(QuestID)

	if type(TagInfo) == "table" then
		return TagInfo.tagID == DungeonQuestTagID
	end

	return TagInfo == DungeonQuestTagID
end

local OnMouseUp = function()
	ToggleFrame(HydraUI.IsMainline and QuestMapFrame or QuestLogFrame)
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Header

	for Index = 1, GetNumQuests() do
		local Info = GetQuestInfo(Index)

		if Info and Info.isHeader then
			Header = Info.title
		elseif Info then
			if Header then
				GameTooltip:AddLine(Header, 0.6, 0.6, 0.6)
				Header = nil
			end

			local Color = GetQuestDifficultyColor(Info.level)
			local QuestText = format("[%s] %s", Info.level, Info.title)
			local IsComplete = Info.isComplete == true or Info.isComplete == 1
			local IsDungeon = IsDungeonQuest(Info.questID)
			local Status

			if IsComplete then
				Status = IsDungeon and format("%s, %s", DungeonLabel, COMPLETE) or COMPLETE
			elseif IsDungeon then
				Status = DungeonLabel
			end

			if Status then
				local StatusRed = IsComplete and 0 or 0.6
				local StatusGreen = IsComplete and 1 or 0.6
				local StatusBlue = IsComplete and 0 or 0.6

				GameTooltip:AddDoubleLine(QuestText, Status, Color.r, Color.g, Color.b, StatusRed, StatusGreen, StatusBlue)
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
