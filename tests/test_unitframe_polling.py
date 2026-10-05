from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
CORE_SOURCE = REPOSITORY_ROOT / "HydraUI" / "Elements" / "UnitFrames" / "Core.lua"


def test_eventless_units_use_a_throttled_ticker_instead_of_frame_updates():
    source = CORE_SOURCE.read_text()

    assert 'frame:SetScript("OnUpdate", PollEventless)' not in source
    assert "C_Timer.NewTicker(0.5" in source
    assert 'frame:SetScript("OnShow", StartEventlessPolling)' in source
    assert "frame._pollsUnit and frame:IsShown()" in source


def test_eventless_polling_stops_while_frames_are_hidden_or_disabled():
    source = CORE_SOURCE.read_text()

    assert 'frame:SetScript("OnHide", StopEventlessPolling)' in source
    assert "self._pollTicker:Cancel()" in source
    assert "self._pollTicker = nil" in source
    assert "UnregisterUnitWatch(self)\n\tStopEventlessPolling(self)" in source
