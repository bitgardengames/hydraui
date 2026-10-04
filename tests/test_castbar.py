"""Static regression coverage for client-specific cast-time handling."""
from pathlib import Path


SOURCE = (
    Path(__file__).parents[1]
    / "HydraUI/Elements/UnitFrames/CastSupport.lua"
).read_text()


def test_secret_cast_times_are_filtered_only_on_mainline():
    retail_start = SOURCE.index("if HydraUI.IsMainline then")
    classic_start = SOURCE.index("else", retail_start)
    retail_adapter = SOURCE[retail_start:classic_start]
    classic_adapter = SOURCE[classic_start:SOURCE.index("local function Install")]

    assert "UnitCastingInfo(unit)" in retail_adapter
    assert "UnitChannelInfo(unit)" in retail_adapter
    assert retail_adapter.count("issecretvalue(startTime)") == 2
    assert retail_adapter.count("issecretvalue(endTime)") == 2
    assert "issecretvalue" not in classic_adapter
    assert "canaccessvalue" not in classic_adapter
