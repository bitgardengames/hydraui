"""Static regression coverage for the custom micro menu."""
from pathlib import Path
import unittest


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/ActionBars/MicroMenu.lua").read_text()


class MicroMenuCoverage(unittest.TestCase):
    def test_retail_micro_menu_remains_in_blizzard_container(self):
        """Edit Mode expects MicroMenu to retain its Blizzard-owned parent."""
        self.assertNotIn("MicroMenu:SetParent", SOURCE)

    def test_buttons_are_still_moved_to_the_custom_panel(self):
        self.assertIn("self.Buttons[i]:SetParent(self.Panel)", SOURCE)
        self.assertIn("MicroButtons.Buttons[i]:SetParent(MicroButtons.Panel)", SOURCE)

    def test_visible_buttons_are_never_cleared_as_a_batch(self):
        """Blizzard may run GetEdgeButton synchronously after an anchor changes."""
        collection = SOURCE.index("if Button:IsShown() then")
        positioning = SOURCE.index("for i = 1, NumButtons do")
        clear = SOURCE.index("Button:ClearAllPoints()", collection)

        self.assertGreater(clear, positioning)
        self.assertNotIn("self.Buttons[i]:ClearAllPoints()", SOURCE)


if __name__ == "__main__":
    unittest.main()
