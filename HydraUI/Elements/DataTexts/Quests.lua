local HydraUI, Language, Assets, Settings = select(2, ...):get()

local select = select
local GetMaxNumQuestsCanAccept = C_QuestLog.GetMaxNumQuestsCanAccept
local GetQuestTagInfo = C_QuestLog.GetQuestTagInfo
local GetQuestDifficultyColor = GetQuestDifficultyColor
local DungeonLabel = TRACKER_HEADER_DUNGEON or "Dungeon"
local DungeonQuestTag = QUEST_TAG_DUNGEON or (Enum and Enum.QuestTag and Enum.QuestTag.Dungeon)
local Label = QUESTS_LABEL

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

local OnMouseUp = function()
	ToggleFrame(HydraUI.IsMainline and QuestMapFrame or QuestLogFrame)
end

local IsDungeonQuest = function(QuestID)
	if not QuestID or not GetQuestTagInfo or not DungeonQuestTag then
		return false
	end

	local TagInfo = GetQuestTagInfo(QuestID)
	local TagID = type(TagInfo) == "table" and TagInfo.tagID or TagInfo

	return TagID == DungeonQuestTag
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local ZoneName
	local DisplayedZone

	for Index = 1, GetNumQuests() do
		local Info = GetQuestInfo(Index)

		if Info and Info.isHeader then
			ZoneName = Info.title
		elseif Info then
			if ZoneName and ZoneName ~= DisplayedZone then
				GameTooltip:AddLine(ZoneName, 0.6, 0.6, 0.6)
				DisplayedZone = ZoneName
			end

			local Color = GetQuestDifficultyColor(Info.level)
			local QuestText = format("[%s] %s", Info.level, Info.title)
			local IsComplete = Info.isComplete == true or Info.isComplete == 1
			local IsDungeon = IsDungeonQuest(Info.questID)
			local Status

			if IsDungeon and IsComplete then
				Status = format("%s, %s", DungeonLabel, COMPLETE)
			elseif IsDungeon then
				Status = DungeonLabel
			elseif IsComplete then
				Status = COMPLETE
			end

			if Status then
				GameTooltip:AddDoubleLine(QuestText, Status, Color.r, Color.g, Color.b, IsComplete and 0 or 0.6, IsComplete and 1 or 0.6, IsComplete and 0 or 0.6)
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
