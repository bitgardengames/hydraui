"""Static coverage for the event-driven Guild data text."""
from pathlib import Path


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/DataTexts/Guild.lua").read_text()


def test_guild_data_text_does_not_poll_while_hovered():
    assert 'SetScript("OnUpdate"' not in SOURCE
    assert "local OnUpdate = function" not in SOURCE


def test_guild_events_refresh_an_open_tooltip():
    for event in (
        "GUILD_ROSTER_UPDATE",
        "GUILD_RANKS_UPDATE",
        "PLAYER_GUILD_UPDATE",
        "GUILD_MOTD",
    ):
        assert f'self:RegisterEvent("{event}")' in SOURCE

    assert "if self.TooltipShown then" in SOURCE
    assert "GameTooltip:ClearLines()" in SOURCE
    assert "OnEnter(self)" in SOURCE
