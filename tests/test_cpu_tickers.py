from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
ELEMENTS_ROOT = REPOSITORY_ROOT / "HydraUI" / "Elements"


def test_guild_roster_refresh_uses_a_hover_scoped_ticker():
    source = (ELEMENTS_ROOT / "DataTexts" / "Guild.lua").read_text()

    assert 'SetScript("OnUpdate"' not in source
    assert "C_Timer.NewTicker(10, GuildRoster)" in source
    assert "self.RosterTicker:Cancel()" in source
    assert "self.RosterTicker = nil" in source


def test_range_checks_use_one_shared_cancellable_ticker():
    source = (ELEMENTS_ROOT / "UnitFrames" / "Elements" / "Range.lua").read_text()

    assert 'SetScript("OnUpdate"' not in source
    assert "C_Timer.NewTicker(0.2, UpdateRanges)" in source
    assert "RangeTicker:Cancel()" in source
    assert "RangeTicker = nil" in source
