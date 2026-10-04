"""Static coverage for client-specific Honor data text events."""
from pathlib import Path


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/DataTexts/Honor.lua").read_text()


def function_body(name):
    start = SOURCE.index(f"local {name} = function")
    next_function = SOURCE.find("\nlocal ", start + 10)
    return SOURCE[start:next_function if next_function >= 0 else None]


def test_honor_level_event_is_retail_only():
    retail_guard = "if HydraUI.IsMainline and not HydraUI.IsForever then"

    for function_name, event_call in (
        ("OnEnable", 'self:RegisterEvent("HONOR_LEVEL_UPDATE")'),
        ("OnDisable", 'self:UnregisterEvent("HONOR_LEVEL_UPDATE")'),
    ):
        body = function_body(function_name)
        assert retail_guard in body
        assert body.index(retail_guard) < body.index(event_call) < body.index("\tend", body.index(retail_guard))
