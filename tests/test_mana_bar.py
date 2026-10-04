"""Regression coverage for client-specific mana-bar events."""
from pathlib import Path
import unittest


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/ManaBar.lua").read_text()


class ManaBarEventCoverage(unittest.TestCase):
    def test_mists_uses_supported_specialization_event(self):
        self.assertIn(
            'HydraUI.IsMists and "PLAYER_SPECIALIZATION_CHANGED" or "ACTIVE_TALENT_GROUP_CHANGED"',
            SOURCE,
        )
        self.assertIn("self:RegisterEvent(TalentGroupEvent)", SOURCE)
        self.assertIn(
            "ManaBar.PLAYER_SPECIALIZATION_CHANGED = ManaBar.ACTIVE_TALENT_GROUP_CHANGED",
            SOURCE,
        )


if __name__ == "__main__":
    unittest.main()
