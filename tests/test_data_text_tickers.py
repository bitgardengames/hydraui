from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DATA_TEXT_ROOT = REPOSITORY_ROOT / "HydraUI" / "Elements" / "DataTexts"
PERIODIC_DATA_TEXTS = (
    "CombatTime.lua",
    "Coordinates.lua",
    "System.lua",
    "TimeLocal.lua",
    "TimeRealm.lua",
)


def test_periodic_data_texts_do_not_poll_every_frame():
    for filename in PERIODIC_DATA_TEXTS:
        source = (DATA_TEXT_ROOT / filename).read_text()

        assert 'SetScript("OnUpdate"' not in source, filename
        assert "C_Timer.NewTicker(" in source, filename


def test_periodic_data_texts_cancel_their_tickers():
    for filename in PERIODIC_DATA_TEXTS:
        source = (DATA_TEXT_ROOT / filename).read_text()

        assert "self.Ticker:Cancel()" in source, filename
        assert "self.Ticker = nil" in source, filename
