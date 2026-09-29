"""Static architecture coverage for the WoW-only action-bar module."""
import re
from pathlib import Path

SOURCE = (Path(__file__).parents[1] / "HydraUI" / "Elements" / "ActionBars" / "ActionBars.lua").read_text()


def descriptor_block():
    return SOURCE[SOURCE.index("local ActionBarDescriptors"):SOURCE.index("AB.ActionBarDescriptors")]


def test_descriptors_expand_all_eight_bars_and_gui_sections():
    block = descriptor_block()
    assert [int(value) for value in re.findall(r"\{index = (\d)", block)] == list(range(1, 9))
    assert 'for _, descriptor in ipairs(ActionBarDescriptors) do' in SOURCE
    assert 'GUI:AddWidgets(Language["General"], Language[current.label]' in SOURCE
    assert not re.search(r"local UpdateBar[1-8]\s*=", SOURCE)


def test_version_specific_bars_have_availability_predicates():
    block = descriptor_block()
    for index, parent in ((6, "MultiBar5"), (7, "MultiBar6"), (8, "MultiBar7")):
        descriptor = next(line for line in block.splitlines() if f"{{index = {index}," in line)
        assert f"available = function() return {parent} ~= nil end" in descriptor
    assert "if not descriptor.available() then" in SOURCE


def test_region_visibility_uses_the_requested_region_for_every_created_bar():
    helper = SOURCE[SOURCE.index("function AB:SetButtonRegionVisibility"):SOURCE.index("function AB:UpdateButtonFont")]
    assert 'local region = bar[i][regionName]' in helper
    assert 'SetButtonRegionVisibility("HotKey", value)' in helper
    assert 'SetButtonRegionVisibility("Name", value)' in helper
    assert 'SetButtonRegionVisibility("Count", value)' in helper


def test_disabling_hover_removes_both_frame_scripts():
    helper = SOURCE[SOURCE.index("function AB:SetBarHover"):SOURCE.index("function AB:SetBarAlpha")]
    assert 'bar:SetScript("OnEnter", enabled and BarOnEnter or nil)' in helper
    assert 'bar:SetScript("OnLeave", enabled and BarOnLeave or nil)' in helper


def test_settings_keys_are_constructed_from_descriptor_prefix():
    assert 'local prefix = descriptor.settingsPrefix' in SOURCE
    for suffix in ("-enable", "-hover", "-button-size", "-button-gap", "-button-max", "-per-row", "-alpha"):
        assert f'prefix .. "{suffix}"' in SOURCE
