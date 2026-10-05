"""Static regression coverage for the quests data text tooltip."""
from pathlib import Path


SOURCE = (
    Path(__file__).parents[1] / "HydraUI" / "Elements" / "DataTexts" / "Quests.lua"
).read_text()


def test_quest_tooltip_supports_modern_and_legacy_log_apis():
    assert "GetQuestInfo = C_QuestLog.GetInfo" in SOURCE
    assert "GetQuestLogTitle(Index)" in SOURCE


def test_quest_tooltip_lists_only_quests_with_difficulty_colors():
    assert "elseif Info then" in SOURCE
    assert "GetQuestDifficultyColor(Info.level)" in SOURCE
    assert 'format("[%s] %s", Info.level, Info.title)' in SOURCE


def test_quest_tooltip_marks_completed_quests():
    assert "Info.isComplete == true or Info.isComplete == 1" in SOURCE
    assert 'format("|cFF00FF00%s|r", COMPLETE)' in SOURCE
    assert 'GameTooltip:AddDoubleLine(QuestText, table.concat(Status, ", ")' in SOURCE


def test_quest_tooltip_uses_zone_headers_instead_of_a_generic_title():
    assert "GameTooltip:AddLine(Label)" not in SOURCE
    assert "if Info and Info.isHeader then" in SOURCE
    assert "GameTooltip:AddLine(Header, 0.6, 0.6, 0.6)" in SOURCE


def test_quest_tooltip_separates_zone_groups_with_a_blank_line():
    assert "if HasQuest then" in SOURCE
    assert 'GameTooltip:AddLine(" ")' in SOURCE
    assert "HasQuest = true" in SOURCE


def test_quest_tooltip_marks_dungeon_quests():
    assert 'TRACKER_HEADER_DUNGEON or "Dungeon"' in SOURCE
    assert "C_QuestLog.GetQuestTagInfo" in SOURCE
    assert "TagInfo.tagID == DungeonQuestTagID" in SOURCE
    assert "GetQuestTags(Info.questID)" in SOURCE
    assert 'format("|cFF%s%s|r", DifficultyColor, DungeonLabel)' in SOURCE


def test_quest_tooltip_marks_elite_quests_when_tag_data_is_available():
    assert 'ELITE or "Elite"' in SOURCE
    assert "Enum.QuestTag.Elite or 1" in SOURCE
    assert "TagInfo.isElite or TagInfo.tagID == EliteQuestTagID" in SOURCE
    assert 'format("|cFF%s%s|r", DifficultyColor, EliteLabel)' in SOURCE


def test_quest_tooltip_hover_handlers_are_cleaned_up():
    assert 'self:SetScript("OnEnter", OnEnter)' in SOURCE
    assert 'self:SetScript("OnLeave", OnLeave)' in SOURCE
    assert 'self:SetScript("OnEnter", nil)' in SOURCE
    assert 'self:SetScript("OnLeave", nil)' in SOURCE
