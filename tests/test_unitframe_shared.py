"""Static regression coverage for shared unit-frame construction.

The settings are intentionally treated as distinct sentinels: assertions verify each
style passes its own family values into the constructors instead of inheriting a
parent frame's dimensions or reverse-fill setting.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"
STYLES = {
    "Player": "unitframes-player",
    "Target": "unitframes-target",
    "Focus": "unitframes-focus",
    "TargetTarget": "unitframes-targettarget",
    "Boss": "unitframes-boss",
    "Party": "party",
    "Raid": "raid",
    "PartyPets": "party-pets",
    "RaidPets": "raid-pets",
    "Pet": "unitframes-pet",
}


def constructor_block(source: str, constructor: str) -> str:
    marker = f"UF:{constructor}("
    start = source.find(marker)
    if start < 0:
        raise AssertionError(f"missing {constructor}")
    depth = 0
    quote = None
    escaped = False
    for index in range(start + len(marker) - 1, len(source)):
        char = source[index]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in "'\"":
            quote = char
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return source[start:index + 1]
    raise AssertionError(f"unterminated {constructor}")


class SharedUnitFrameCoverage(unittest.TestCase):
    def test_every_style_constructs_shared_health_with_its_own_dimensions(self):
        # Conceptually instantiate every registered style with unique family
        # sentinels by ensuring its constructor arguments retain that prefix.
        for module, prefix in STYLES.items():
            with self.subTest(module=module):
                source = (ROOT / f"{module}.lua").read_text()
                health = constructor_block(source, "CreateHealthBar")
                predictions = constructor_block(source, "CreateHealAndAbsorbBars")
                self.assertIn(f'Settings["{prefix}-health-height"]', health)
                self.assertIn(f'Settings["{prefix}-health-reverse"]', health)
                self.assertIn(f'Settings["{prefix}-width"]', predictions)
                self.assertIn(f'Settings["{prefix}-health-height"]', predictions)
                self.assertIn(f'Settings["{prefix}-health-reverse"]', predictions)

    def test_pet_styles_never_reach_into_parent_dimensions_or_fill(self):
        cases = (("PartyPets", "party-pets", "party"), ("RaidPets", "raid-pets", "raid"))
        for module, pet_prefix, parent_prefix in cases:
            with self.subTest(module=module):
                source = (ROOT / f"{module}.lua").read_text()
                predictions = constructor_block(source, "CreateHealAndAbsorbBars")
                self.assertIn(f'Settings["{pet_prefix}-width"]', predictions)
                self.assertIn(f'Settings["{pet_prefix}-health-height"]', predictions)
                self.assertIn(f'Settings["{pet_prefix}-health-reverse"]', predictions)
                self.assertNotIn(f'Settings["{parent_prefix}-width"]', predictions)
                self.assertNotIn(f'Settings["{parent_prefix}-health-height"]', predictions)
                self.assertNotIn(f'Settings["{parent_prefix}-health-reverse"]', predictions)

    def test_live_health_texture_update_reaches_every_prediction_texture(self):
        shared = (ROOT / "UnitFrames.lua").read_text()
        update = re.search(
            r"function UF:SetHeaderHealthTexture\(header, value\)(.*?)\nend",
            shared,
            re.S,
        ).group(1)
        for expression in (
            "frame.Health:SetStatusBarTexture(resolvedTexture)",
            "frame.Health.bg:SetTexture(resolvedTexture)",
            "frame.HealBar:SetStatusBarTexture(resolvedTexture)",
            "frame.AbsorbsBar:SetStatusBarTexture(resolvedTexture)",
        ):
            self.assertIn(expression, update)
        for module, unit in (("PartyPets", "partypet"), ("RaidPets", "raidpet")):
            source = (ROOT / f"{module}.lua").read_text()
            self.assertIn(
                f'UF:SetHeaderHealthTexture(HydraUI.UnitFrames["{unit}"], value)',
                source,
            )
        self.assertNotIn("GetTetxure", (ROOT / "PartyPets.lua").read_text())
        self.assertNotIn("Unit.Health.HealBar", (ROOT / "PartyPets.lua").read_text())


if __name__ == "__main__":
    unittest.main()
