"""Static regression coverage for descriptor-driven action bars."""
from pathlib import Path
import re
import unittest

ACTION_BAR_DIR = Path(__file__).parents[1] / "HydraUI/Elements/ActionBars"
ACTION_BAR_MODULES = ("ActionBars.lua", "Buttons.lua", "Bars.lua", "TotemBar.lua")
SOURCE = "\n".join((ACTION_BAR_DIR / module).read_text() for module in ACTION_BAR_MODULES)


class ActionBarDescriptorCoverage(unittest.TestCase):
    def test_descriptors_cover_defaults_creation_and_ui_metadata(self):
        block = SOURCE[SOURCE.index("local ActionBarDescriptors"):SOURCE.index("AB.ActionBarDescriptors")]
        self.assertEqual(8, len(re.findall(r'index = [1-8], field = "Bar[1-8]"', block)))
        for token in ("parent =", "prefix =", "anchor =", "available =", "label =", "defaultPerRow =", "hasButtonMax =", "securePaging = true"):
            self.assertIn(token, block)
        self.assertEqual(3, len(re.findall(r"defaultPerRow = 12(?:,| })", block)))
        self.assertEqual(5, len(re.findall(r"defaultPerRow = 1(?:,| })", block)))
        self.assertIn('Defaults[key .. "-per-row"] = descriptor.defaultPerRow', SOURCE)
        self.assertIn('Defaults[key .. "-button-max"] = 12', SOURCE)
        self.assertNotRegex(SOURCE, r'Defaults\["ab-bar[1-8]-')

    def test_settings_live_with_their_implementations(self):
        self.assertFalse((ACTION_BAR_DIR / "Settings.lua").exists())
        self.assertIn('CreateSwitch("ab-enable"', (ACTION_BAR_DIR / "ActionBars.lua").read_text())
        self.assertIn('CreateSwitch("ab-show-hotkey"', (ACTION_BAR_DIR / "Buttons.lua").read_text())
        self.assertIn('local function AddActionBarWidgets', (ACTION_BAR_DIR / "Bars.lua").read_text())
        self.assertIn('CreateSwitch("ab-totem-enable"', (ACTION_BAR_DIR / "TotemBar.lua").read_text())

    def test_implementation_is_split_into_focused_modules(self):
        for module in ACTION_BAR_MODULES:
            source = (ACTION_BAR_DIR / module).read_text()
            self.assertLess(len(source.splitlines()), 800, module)

        for toc in (Path(__file__).parents[1] / "HydraUI").glob("HydraUI_*.toc"):
            source = toc.read_text()
            positions = [source.index("Elements\\ActionBars\\" + module) for module in ACTION_BAR_MODULES]
            self.assertEqual(sorted(positions), positions, toc.name)

    def test_missing_optional_bars_are_skipped_everywhere(self):
        self.assertIn("if not descriptor.available() then", SOURCE)
        for parent in ("MultiBar5", "MultiBar6", "MultiBar7"):
            self.assertIn(f"return {parent} ~= nil", SOURCE)
        self.assertIn("if bar and descriptor.securePaging then", SOURCE)
        self.assertRegex(
            SOURCE,
            r"if not descriptor\.available\(\) then\s+return\s+end",
        )

    def test_callbacks_and_widgets_are_generated(self):
        self.assertGreaterEqual(SOURCE.count("for _, descriptor in ipairs(ActionBarDescriptors) do"), 4)
        for factory in ("CreateBarLayoutCallback", "CreateBarEnableCallback", "CreateBarHoverCallback", "CreateBarAlphaCallback"):
            self.assertIn(factory + "(descriptor)", SOURCE)
        self.assertIn("local function AddActionBarWidgets(descriptor)", SOURCE)
        self.assertIn("AddActionBarWidgets(descriptor)", SOURCE)
        self.assertNotRegex(SOURCE, r"UpdateBar[1-8](Hover|Alpha)")
        self.assertNotRegex(SOURCE, r'Language\["Bar [1-8]"\].*Language\["Action Bars"\], function')

    def test_hover_is_shared_symmetric_and_honors_max_alpha(self):
        start = SOURCE.index("local function SetBarHover")
        block = SOURCE[start:SOURCE.index("local function SetBarAlpha", start)]
        self.assertIn('bar:SetScript("OnEnter", enabled and BarOnEnter or nil)', block)
        self.assertIn('bar:SetScript("OnLeave", enabled and BarOnLeave or nil)', block)
        self.assertIn("bar.ShouldFade = enabled", block)
        self.assertIn("bar.MaxAlpha / 100", block)
        self.assertIn("SetDrawBling(not enabled)", block)

    def test_fonts_iterate_created_and_auxiliary_bars(self):
        block = SOURCE[SOURCE.index("local UpdateActionBarFont"):SOURCE.index("local function SetBarHover")]
        self.assertIn("for _, bar in ipairs(AB.Bars or {}) do", block)
        self.assertIn('{ "PetBar", "StanceBar" }', block)
        self.assertNotRegex(block, r"AB\.Bar[1-8]\[")

    def test_each_text_setting_uses_correct_region_and_alpha(self):
        expected = (
            ('UpdateShowHotKey', '"HotKey", value and 1 or 0, true'),
            ('UpdateShowMacroName', '"Name", value and 1 or 0, false'),
            ('UpdateShowCount', '"Count", value and 1 or 0, false'),
        )
        for callback, invocation in expected:
            self.assertRegex(
                SOURCE,
                rf"(?s)local {callback} = function\(value\).*?{re.escape(invocation)}.*?end",
            )
        self.assertIn("local region = bar[i][regionName]", SOURCE)
        self.assertIn("region:SetAlpha(alpha)", SOURCE)

    def test_styling_does_not_show_stale_action_icons(self):
        source = (ACTION_BAR_DIR / "Buttons.lua").read_text()
        start = source.index("function AB:StyleActionButton")
        block = source[start:source.index("function AB:StylePetActionButton", start)]

        self.assertIn("local Icon = button.Icon or button.icon", block)
        self.assertNotIn("Icon:Show()", block)
        self.assertIn("if button.action and not HasAction(button.action) then", block)
        self.assertIn("Icon:Hide()", block)


if __name__ == "__main__":
    unittest.main()
