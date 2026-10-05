"""Static regression coverage for the quests data text tooltip."""
from pathlib import Path


SOURCE = (
    Path(__file__).parents[1] / "HydraUI" / "Elements" / "DataTexts" / "Quests.lua"
).read_text()


def test_quest_tooltip_supports_modern_and_legacy_log_apis():
    assert "GetQuestInfo = C_QuestLog.GetInfo" in SOURCE
    assert "GetQuestLogTitle(Index)" in SOURCE


def test_quest_tooltip_lists_only_quests_with_difficulty_colors():
    assert "if Info and Info.isHeader then" in SOURCE
    assert "GetQuestDifficultyColor(Info.level)" in SOURCE
    assert 'format("[%s] %s", Info.level, Info.title)' in SOURCE


def test_quest_tooltip_groups_quests_under_grey_zone_headers():
    assert "ZoneName = Info.title" in SOURCE
    assert "GameTooltip:AddLine(ZoneName, 0.6, 0.6, 0.6)" in SOURCE
    assert "GameTooltip:AddLine(Label)" not in SOURCE


def test_quest_tooltip_marks_completed_quests():
    assert "Info.isComplete == true or Info.isComplete == 1" in SOURCE
    assert "Status = COMPLETE" in SOURCE


def test_quest_tooltip_marks_dungeon_quests():
    assert 'local DungeonLabel = TRACKER_HEADER_DUNGEON or "Dungeon"' in SOURCE
    assert "local IsDungeon = IsDungeonQuest(Info.questID)" in SOURCE
    assert 'Status = format("%s, %s", DungeonLabel, COMPLETE)' in SOURCE


def test_quest_tooltip_hover_handlers_are_cleaned_up():
    assert 'self:SetScript("OnEnter", OnEnter)' in SOURCE
    assert 'self:SetScript("OnLeave", OnLeave)' in SOURCE
    assert 'self:SetScript("OnEnter", nil)' in SOURCE
    assert 'self:SetScript("OnLeave", nil)' in SOURCE
