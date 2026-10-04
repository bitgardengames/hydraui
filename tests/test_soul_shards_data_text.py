"""Static coverage for the Soul Shards data text color."""
from pathlib import Path
import unittest


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/DataTexts/SoulShards.lua").read_text()


class SoulShardsDataTextCoverage(unittest.TestCase):
    def test_value_uses_configured_soul_shard_color(self):
        self.assertIn('Settings["color-soul-shards"], ShardCount', SOURCE)
        self.assertNotIn("HydraUI.ValueColor, ShardCount", SOURCE)


if __name__ == "__main__":
    unittest.main()
