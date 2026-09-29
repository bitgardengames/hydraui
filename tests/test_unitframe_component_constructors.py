"""Static regression coverage for allocation-free unit-frame constructors."""
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
    def test_component_constructors_take_direct_inputs(self):
        expected = {
            "CreatePortrait": "frame, style, width, height, point, relativeTo",
            "CreateCastbar": "frame, name, width, height, point, relativeTo",
            "CreateAuraContainer": "frame, name, parent, width, height, point, relativeTo",
        }
        for constructor, signature in expected.items():
            source = body(constructor)
            self.assertIn(f"function UF:{constructor}({signature}", source)
            self.assertNotIn("options", source)
            self.assertNotIn("NormalizeComponentOptions", source)

    def test_all_component_callers_avoid_option_tables(self):
        constructors = ("CreatePortrait", "CreateCastbar", "CreateAuraContainer")
        for path in ROOT.glob("*.lua"):
            source = path.read_text()
            for constructor in constructors:
                self.assertNotRegex(source, rf"{constructor}\([^)]*,\s*\{{")
        self.assertNotIn("NormalizeComponentOptions", SHARED)
        self.assertNotIn("ComponentDefaults", SHARED)

    def test_frequently_created_bars_use_direct_inputs(self):
        expected_signatures = {
            "CreateHealthBar": "frame, height, texture, reverseFill, orientation",
            "CreateHealAndAbsorbBars": "frame, health, width, height, texture, reverseFill, createAbsorb",
            "CreatePowerBar": "frame, height, texture, reverseFill",
        }
        for constructor, signature in expected_signatures.items():
            source = body(constructor)
            self.assertIn(f"function UF:{constructor}({signature}", source)

    def test_small_unit_auras_still_use_the_shared_constructor(self):
        for module in ("Pet", "TargetTarget"):
            source = (ROOT / f"{module}.lua").read_text()
            self.assertIn("CreateAuraContainer(frame,", source)
            self.assertNotRegex(source, r'CreateFrame\("Frame", frame:GetName\(\) \.\. "(?:Buffs|Debuffs)"')

    def test_optional_client_behavior_is_passed_directly(self):
        player = (ROOT / "Player.lua").read_text()
        target = (ROOT / "Target.lua").read_text()
        self.assertIn("true, true, 0.7, Settings[\"unitframes-player-cast-classcolor\"]", player)
        self.assertIn("nil, true, 0.3, Settings[\"unitframes-target-cast-classcolor\"]", target)

    def test_all_non_group_styles_have_one_factory_entry_point(self):
        for module in ("Player", "Target", "Focus", "Boss", "Pet",
                       "TargetTarget", "PartyPets", "RaidPets"):
            source = (ROOT / f"{module}.lua").read_text()
            style = source[source.index("HydraUI.StyleFuncs["):]
            style = style[:style.index("\nend")]
            self.assertIn("UF:BuildSingleUnitFrame(self, unit,", style)


if __name__ == "__main__":
    unittest.main()
