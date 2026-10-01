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


if __name__ == "__main__":
    unittest.main()
