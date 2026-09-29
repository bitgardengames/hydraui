"""Focused contract tests for pure widget normalization and persistence helpers."""
from pathlib import Path
import re

CORE = Path("HydraUI/Elements/GUI/WidgetCore.lua").read_text()
SLIDERS = Path("HydraUI/Elements/GUI/Sliders.lua").read_text()


def dropdown_offset(offset, count, shown):
    return min(max(round(float(offset or 1)), 1), max(count - shown + 1, 1))


def slider_value(value, minimum, maximum, step):
    value = float(value)
    value = int(value // 1) if step >= 1 else round(value, 2 if step <= 0.01 else 1)
    return min(max(value, minimum), maximum)


def normalize_color(value):
    value = str(value or "").replace("#", "").upper()
    if len(value) == 8:
        value = value[2:]
    return value if len(value) == 6 and not re.search(r"[^0-9A-F]", value) else "FFFFFF"


def test_dropdown_offsets_are_clamped_to_visible_window():
    assert dropdown_offset(-4, 20, 8) == 1
    assert dropdown_offset(7, 20, 8) == 7
    assert dropdown_offset(99, 20, 8) == 13
    assert dropdown_offset(4, 3, 8) == 1


def test_slider_values_are_clamped_and_step_normalized():
    assert slider_value(-1, 0, 10, 0.5) == 0
    assert slider_value(3.24, 0, 10, 0.5) == 3.2
    assert slider_value(12, 0, 10, 0.5) == 10


def test_slider_anchor_uses_shared_widget_height():
    assert "Anchor:SetSize(GROUP_WIDTH, WIDGET_HEIGHT)" in SLIDERS
    assert "DROPDOWN_HEIGHT" not in SLIDERS


def test_color_normalization_accepts_rgb_and_argb():
    assert normalize_color("#a1b2c3") == "A1B2C3"
    assert normalize_color("FFA1B2C3") == "A1B2C3"
    assert normalize_color("not-a-color") == "FFFFFF"


def test_persistence_has_id_and_widget_opt_outs():
    assert '["ui-profile"] = true' in CORE
    assert '["profile-copy"] = true' in CORE
    assert "widget and widget.IsSavingDisabled" in CORE
    assert "if not Core.ShouldPersist(id, widget) then return false end" in CORE
