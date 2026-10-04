"""Static regression coverage for client-specific cast-time handling."""
from pathlib import Path


SOURCE = (
    Path(__file__).parents[1]
    / "HydraUI/Elements/UnitFrames/Elements/CastSupport.lua"
).read_text()


def test_secret_cast_times_are_filtered_only_on_mainline():
    retail_start = SOURCE.index("if HydraUI.IsMainline then")
    classic_start = SOURCE.index("else", retail_start)
    retail_adapter = SOURCE[retail_start:classic_start]
    classic_adapter = SOURCE[classic_start:SOURCE.index("local UF = HydraUI:GetModule")]

    assert "UnitCastingInfo(unit)" in retail_adapter
    assert "UnitChannelInfo(unit)" in retail_adapter
    assert retail_adapter.count("issecretvalue(startTime)") == 2
    assert retail_adapter.count("issecretvalue(endTime)") == 2
    assert "issecretvalue" not in classic_adapter
    assert "canaccessvalue" not in classic_adapter


def test_castbar_refreshes_channels_and_tracks_empowered_casts():
    assert "local function ReadCast(unit)" in SOURCE
    assert "GetUnitEmpowerHoldAtMaxTime(unit)" in SOURCE
    assert "bar.empowering" in SOURCE
    for event in (
        "UNIT_SPELLCAST_EMPOWER_START",
        "UNIT_SPELLCAST_EMPOWER_UPDATE",
        "UNIT_SPELLCAST_EMPOWER_STOP",
    ):
        assert event in SOURCE


def test_castbar_updates_delays_and_hides_at_completion():
    assert "local function UpdateCast" in SOURCE
    assert "bar.delay=(bar.delay or 0)+math.max(0,delta)" in SOURCE
    assert "bar.duration >= bar.max" in SOURCE
    assert "bar.duration <= 0" in SOURCE
    assert "bar:Hide()" in SOURCE


def test_castbar_uses_classic_cast_provider_when_required():
    assert 'LibStub("LibClassicCasterino", true)' in SOURCE
    assert "LibCC.RegisterCallback" in SOURCE
    assert "LibCC.UnregisterCallback" in SOURCE


def test_player_castbar_replaces_the_blizzard_castbar():
    assert "CastingBarFrame_SetUnit(CastingBarFrame,nil)" in SOURCE
    assert "PlayerCastingBarFrame:SetUnit(nil)" in SOURCE
