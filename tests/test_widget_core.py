"""Focused contract tests for pure widget normalization and persistence helpers."""
from pathlib import Path
import re

CORE = Path("HydraUI/Elements/GUI/WidgetCore.lua").read_text()
SLIDERS = Path("HydraUI/Elements/GUI/Sliders.lua").read_text()
GUI = Path("HydraUI/Elements/GUI/GUI.lua").read_text()
NAVIGATION = Path("HydraUI/Elements/GUI/Navigation.lua").read_text()
FRAME = Path("HydraUI/Elements/GUI/Frame.lua").read_text()


class Viewport:
    """Small executable model of the shared Lua RowViewport contract."""

    def __init__(self, rows, shown, render):
        self.rows = rows
        self.shown = shown
        self.render = render
        self.offset = 1
        self.scrollbar = 1

    def set_offset(self, offset):
        self.offset = dropdown_offset(offset, len(self.rows()), self.shown)
        self.scrollbar = self.offset
        for slot in range(self.shown):
            index = self.offset + slot - 1
            self.render(slot, self.rows()[index] if index < len(self.rows()) else None)


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
    assert "if not Core.ShouldPersist(id, widget) then" in CORE
    assert "\t\treturn false\n\tend" in CORE


def test_shared_viewport_supports_widget_and_navigation_sources():
    bound = []
    widgets = Viewport(lambda: ["w1", "w2", "w3"], 2, lambda slot, row: bound.append((slot, row)))
    navigation = Viewport(lambda: ["general", "profiles"], 1, lambda slot, row: bound.append((slot, row)))
    widgets.set_offset(2)
    navigation.set_offset(2)
    assert bound == [(0, "w2"), (1, "w3"), (0, "profiles")]


def test_shared_viewport_clamps_empty_data_and_synchronizes_scrollbar():
    rendered = []
    viewport = Viewport(lambda: [], 4, lambda slot, row: rendered.append(row))
    viewport.set_offset(99)
    assert viewport.offset == viewport.scrollbar == 1
    assert rendered == [None] * 4


def test_shared_viewport_reuses_visible_slots_while_scrolling():
    pool = [object(), object()]
    bindings = {}
    viewport = Viewport(lambda: list(range(6)), len(pool), lambda slot, row: bindings.__setitem__(pool[slot], row))
    viewport.set_offset(1)
    identities = set(bindings)
    viewport.set_offset(4)
    assert set(bindings) == identities
    assert list(bindings.values()) == [3, 4]


def test_lua_viewport_owns_rendering_scrollbar_and_mousewheel_contracts():
    assert "function RowViewport:GetRow" in GUI
    assert "function RowViewport:AttachMouseWheel" in GUI
    assert "function RowViewport:SyncScrollBar" in GUI
    assert "RenderRow = options.RenderRow" in GUI
    assert "SetSelectionOffset" not in NAVIGATION
    assert "WindowScrollBarOnValueChanged" not in FRAME


def test_lua_viewport_hides_rows_outside_a_replaced_collection_on_first_render():
    render_start = GUI.index("function RowViewport:Render")
    default_renderer = GUI[
        GUI.index("\telse\n\t\tif OldRows and OldFirst then", render_start) : GUI.index(
            "\n\t\tfor i = First, Last do", render_start
        )
    ]
    assert "if rowsChanged or (not OldRows) then" in default_renderer
    assert "for i = Last + 1, Count do Rows[i]:Hide() end" in default_renderer


def test_vertical_scroll_consumers_use_shared_controls_with_distinct_options():
    assert "local CreateVerticalScrollControls = function(Owner, Options)" in FRAME
    assert FRAME.count("CreateVerticalScrollControls(self, {") == 2

    window = FRAME[FRAME.index("local AddWindowScrollBar"):FRAME.index("local DisableScrolling")]
    assert 'TopAnchor = {"TOPRIGHT", GUI, -SPACING, -((SPACING * 2) + HEADER_HEIGHT - 1)}' in window
    assert 'BottomAnchor = {"BOTTOMRIGHT", GUI, -SPACING, SPACING}' in window
    assert "HighlightAlpha = SELECTED_HIGHLIGHT_ALPHA" in window
    assert "ProgressAlpha = SELECTED_HIGHLIGHT_ALPHA" in window
    assert "ScrollUp = function() self.RowViewport:ScrollBy(1) end" in window
    assert "ScrollDown = function() self.RowViewport:ScrollBy(-1) end" in window
    assert "WheelTarget = self" in window

    navigation = FRAME[FRAME.index("local CreateNavigationRegion"):FRAME.index("local CreateCloseControl")]
    assert 'TopAnchor = {"TOPLEFT", self.MenuParent, "TOPRIGHT", 2, 0}' in navigation
    assert 'BottomAnchor = {"BOTTOMLEFT", self.MenuParent, "BOTTOMRIGHT", 2, 0}' in navigation
    assert "HighlightAlpha = MOUSEOVER_HIGHLIGHT_ALPHA" in navigation
    assert "ProgressAlpha = SELECTED_HIGHLIGHT_ALPHA" in navigation
    assert "ScrollUp = function() self.SelectionViewport:ScrollBy(1) end" in navigation
    assert "ScrollDown = function() self.SelectionViewport:ScrollBy(-1) end" in navigation
    assert "WheelTarget = self.MenuParent" in navigation


def test_scroll_arrow_colors_are_updated_by_shared_function():
    assert "local UpdateScrollArrowColors = function(Owner, Offset, MaxOffset)" in FRAME
    assert "UpdateScrollArrowColors(Owner, Offset, Owner.MaxScroll)" in FRAME
    assert "UpdateScrollArrowColors(Owner, Offset, MaxOffset)" in FRAME
