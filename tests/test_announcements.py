from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "HydraUI/Elements/Announcements.lua").read_text(encoding="utf-8")


class AnnouncementEventCoverage(unittest.TestCase):
    def test_restricted_clients_skip_combat_log_registration(self):
        guard = "if HydraUI.IsForever or HydraUI.IsMidnight then"
        load = SOURCE.split("function Announcements:Load()", 1)[1]

        self.assertIn(guard, load)
        self.assertLess(load.index(guard), load.index('self:RegisterEvent("UNIT_PET")'))


if __name__ == "__main__":
    unittest.main()
