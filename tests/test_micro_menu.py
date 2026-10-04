"""Static regression coverage for the custom micro menu."""
from pathlib import Path
import unittest


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/ActionBars/MicroMenu.lua").read_text()


class MicroMenuCoverage(unittest.TestCase):
    def test_mists_micro_menu_includes_talent_button(self):
        """Mists exposes talents through a dedicated micro menu button."""
        mists_start = SOURCE.index("elseif HydraUI.IsMists then")
        mists_buttons = SOURCE[mists_start:SOURCE.index("\nelse", mists_start)]

        self.assertIn("TalentMicroButton", mists_buttons)

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

    def test_retail_panel_is_not_hidden(self):
        """Hidden retail buttons need coordinates during Blizzard OnHide callbacks."""
        visibility = SOURCE[SOURCE.index("function MicroButtons:UpdateVisibility()"):
                            SOURCE.index("function MicroButtons:UpdateMicroButtonsParent()")]

        self.assertIn("if HydraUI.IsMainline then", visibility)
        self.assertIn("self.Buttons[i]:EnableMouse(false)", visibility)
        self.assertNotIn('Settings["micro-buttons-show"]', SOURCE)


if __name__ == "__main__":
    unittest.main()
