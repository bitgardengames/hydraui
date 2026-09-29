"""Static regression coverage for named unit-frame component specifications."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"
SHARED = (ROOT / "ComponentFactory.lua").read_text()


def body(name):
    start = SHARED.index(f"function UF:{name}")
    match = re.search(r"\nend\n", SHARED[start:])
    return SHARED[start:start + match.end()]


class ComponentConstructorCoverage(unittest.TestCase):
    def test_one_normalizer_applies_defaults_and_validates_required_fields(self):
        source = body("NormalizeComponentOptions")
        self.assertIn("ComponentDefaults[kind]", source)
        self.assertIn('type(options) == "table"', source)
        self.assertIn("requires size.width and size.height", source)
        self.assertIn("Castbar requires bar.texture", source)
        self.assertIn("Portrait requires style", source)

    def test_constructors_accept_options_and_normalize_them(self):
        for constructor, kind in (("CreatePortrait", "Portrait"),
                                  ("CreateCastbar", "Castbar"),
                                  ("CreateAuraContainer", "AuraContainer")):
            source = body(constructor)
            self.assertIn(f'function UF:{constructor}(frame, options)', source)
            self.assertIn(f'self:NormalizeComponentOptions("{kind}", options)', source)

    def test_castbar_and_aura_callers_use_named_groups(self):
        for module in ("Player", "Target", "Focus", "Boss"):
            source = (ROOT / f"{module}.lua").read_text()
            if "CreateCastbar" in source:
                self.assertRegex(source, r"CreateCastbar\((?:self|frame), \{")
                for group in ("size = {", "anchor = {", "bar = {", "background = {",
                              "text = {", "icon = {", "callbacks = {"):
                    self.assertIn(group, source)
        for module in ("Player", "Target", "Focus", "Boss", "Party", "Raid"):
            source = (ROOT / f"{module}.lua").read_text()
            self.assertRegex(source, r"CreateAuraContainer\([^,]+, \{")
            self.assertIn("size = {", source)
            self.assertIn("callbacks = {", source)

    def test_optional_client_behavior_remains_declarative(self):
        player = (ROOT / "Player.lua").read_text()
        target = (ROOT / "Target.lua").read_text()
        self.assertIn("safeZone = true", player)
        self.assertIn("showTradeSkills = true", player)
        self.assertIn('classColor = Settings["unitframes-player-cast-classcolor"]', player)
        self.assertNotIn("safeZone = true", target)
        self.assertIn("showTradeSkills = true", target)


if __name__ == "__main__":
    unittest.main()
