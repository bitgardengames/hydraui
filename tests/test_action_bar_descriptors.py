"""Static regression coverage for descriptor-driven action bars."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/ActionBars"
SOURCE = (ROOT / "StandardBars.lua").read_text() + (ROOT / "Settings.lua").read_text() + (ROOT / "ActionBars.lua").read_text()


class ActionBarDescriptorCoverage(unittest.TestCase):
    def test_descriptors_cover_all_bars_and_creation_is_shared(self):
        block = SOURCE[SOURCE.index("local ActionBarDescriptors"):SOURCE.index("AB.ActionBarDescriptors")]
        self.assertEqual(8, len(re.findall(r'index = [1-8], field = "Bar[1-8]"', block)))
        for token in ("parent =", "prefix =", "anchor =", "available =", "securePaging = true"):
            self.assertIn(token, block)
        self.assertIn("function AB:CreateActionBar(descriptor)", SOURCE)
        self.assertNotRegex(SOURCE, r"function AB:CreateBar[1-8]\(")

    def test_missing_optional_bars_are_skipped(self):
        self.assertIn("if not descriptor.available() then", SOURCE)
        for parent in ("MultiBar5", "MultiBar6", "MultiBar7"):
            self.assertIn(f"return {parent} ~= nil", SOURCE)
        self.assertIn("if bar and descriptor.securePaging then", SOURCE)

    def test_creation_movers_and_callbacks_use_collections(self):
        self.assertGreaterEqual(SOURCE.count("for _, descriptor in ipairs(ActionBarDescriptors) do"), 1)
        self.assertIn("for _, bar in ipairs(self.Bars or {}) do", SOURCE)
        self.assertIn("CreateBarLayoutCallback(descriptor)", SOURCE)
        self.assertIn("CreateBarEnableCallback(descriptor)", SOURCE)
        for index in range(1, 9):
            self.assertIn(f"UpdateBar[{index}]", SOURCE)
            self.assertIn(f"UpdateEnableBar[{index}]", SOURCE)

    def test_each_text_setting_uses_correct_region_and_alpha(self):
        expected = (
            ('UpdateShowHotKey', '"HotKey", value and 1 or 0, true'),
            ('UpdateShowMacroName', '"Name", value and 1 or 0, false'),
            ('UpdateShowCount', '"Count", value and 1 or 0, false'),
        )
        for callback, invocation in expected:
            self.assertRegex(SOURCE, rf"local {callback} = function\(value\).*{re.escape(invocation)}")
        self.assertIn("local region = bar[i][regionName]", SOURCE)
        self.assertIn("region:SetAlpha(alpha)", SOURCE)


if __name__ == "__main__":
    unittest.main()
