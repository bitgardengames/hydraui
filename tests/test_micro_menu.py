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

    def test_shared_micro_menu_moves_as_one_frame(self):
        """Edit Mode expects the layout buttons to remain children of MicroMenu."""
        parenting = SOURCE[SOURCE.index("function MicroButtons:UpdateMicroButtonsParent()"):
                           SOURCE.index("function MicroButtons:PositionButtons()")]

        self.assertIn("MicroMenu:SetParent(MicroButtons.Panel)", parenting)
        self.assertIn("MicroMenu:SetAllPoints(MicroButtons.Panel)", parenting)
        self.assertIn("else", parenting)

    def test_legacy_buttons_are_still_moved_to_the_custom_panel(self):
        self.assertIn("MicroButtons.Buttons[i]:SetParent(MicroButtons.Panel)", SOURCE)
        self.assertNotIn("self.Buttons[i]:SetParent(self.Panel)", SOURCE)

    def test_visible_buttons_are_never_cleared_as_a_batch(self):
        """Blizzard may run GetEdgeButton synchronously after an anchor changes."""
        collection = SOURCE.index("if Button:IsShown() then")
        positioning = SOURCE.index("for i = 1, NumButtons do")
        clear = SOURCE.index("Button:ClearAllPoints()", collection)

        self.assertGreater(clear, positioning)
        self.assertNotIn("self.Buttons[i]:ClearAllPoints()", SOURCE)

    def test_shared_micro_menu_panel_is_not_hidden(self):
        """Shared-layout clients need button coordinates during layout callbacks."""
        visibility = SOURCE[SOURCE.index("function MicroButtons:UpdateVisibility()"):
                            SOURCE.index("function MicroButtons:UpdateMicroButtonsParent()")]

        self.assertIn("if MicroMenu then", visibility)
        self.assertIn("self.Panel:Show()", visibility)
        self.assertIn("self.Buttons[i]:EnableMouse(false)", visibility)
        self.assertNotIn('Settings["micro-buttons-show"]', SOURCE)


if __name__ == "__main__":
    unittest.main()
