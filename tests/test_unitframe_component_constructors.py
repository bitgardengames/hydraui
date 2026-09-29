"""Regression coverage for the explicit unit-frame component constructors.

These tests treat each style's configuration as mocked resolved input. They check
that constructors, rather than settings lookups, own the common child wiring.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"
SHARED = (ROOT / "UnitFrames.lua").read_text()


def body(name):
    start = SHARED.index(f"function UF:{name}")
    match = re.search(r"\nend\n", SHARED[start:])
    return SHARED[start:start + match.end()]


class ComponentConstructorCoverage(unittest.TestCase):
    def test_portrait_mock_preserves_anchor_and_optional_background(self):
        source = body("CreatePortrait")
        self.assertIn("config.relativeTo or frame", source)
        self.assertIn('config.style ~= "OVERLAY"', source)
        self.assertIn("portrait.BG = background", source)
        self.assertIn("frame.Portrait = portrait", source)
        for module, side, alpha in (("Player", 'point = Settings["player-portrait-style"] == "OVERLAY" and "CENTER" or "RIGHT"', 'Settings["player-overlay-alpha"] / 100'),
                                    ("Target", 'point = Settings["target-portrait-style"] == "OVERLAY" and "CENTER" or "LEFT"', 'Settings["target-overlay-alpha"] / 100')):
            mocked = (ROOT / f"{module}.lua").read_text()
            self.assertIn(side, mocked)
            self.assertIn(alpha, mocked)

    def test_castbar_mock_wires_ouf_callbacks_and_optional_latency(self):
        source = body("CreateCastbar")
        for field in ("Time", "Text", "Icon", "PostCastStart", "PostCastStop", "PostCastFail", "PostCastInterruptible"):
            self.assertIn(f"castbar.{field}", source)
        self.assertIn("if config.createSafeZone", source)
        player = (ROOT / "Player.lua").read_text()
        target = (ROOT / "Target.lua").read_text()
        self.assertIn("createSafeZone = true", player)
        self.assertNotIn("createSafeZone = true", target)
        self.assertIn("timeToHold = 0.7", player)
        self.assertIn("timeToHold = 0.3", target)

    def test_aura_mock_preserves_growth_callbacks_and_optional_flags(self):
        source = body("CreateAuraContainer")
        for expression in ('auras["growth-x"] = config.growthX', 'auras["growth-y"] = config.growthY',
                           "auras.PostCreateIcon = config.postCreateIcon", "auras.PostUpdateIcon = config.postUpdateIcon",
                           "auras.CustomFilter = config.customFilter", "auras.onlyShowPlayer = config.onlyShowPlayer",
                           "auras.showStealableBuffs = config.showStealableBuffs"):
            self.assertIn(expression, source)
        target = (ROOT / "Target.lua").read_text()
        self.assertIn('growthX = "LEFT", growthY = "UP"', target)
        self.assertIn("showStealableBuffs = true", target)
        for module in ("Player", "Target", "Focus", "Boss", "Party", "Raid"):
            self.assertIn("UF:CreateAuraContainer", (ROOT / f"{module}.lua").read_text())


if __name__ == "__main__":
    unittest.main()
