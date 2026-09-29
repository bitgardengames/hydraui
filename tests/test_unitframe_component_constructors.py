"""Regression coverage for the positional unit-frame component constructors."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"
SHARED = (ROOT / "UnitFrames.lua").read_text()
CONSTRUCTORS = (
    "CreateBackdrop", "CreateThreatIndicator", "CreateHealthBar",
    "CreateHealAndAbsorbBars", "CreatePowerBar", "CreateMouseoverHighlight",
    "CreateFontString", "CreatePortrait", "CreateCastbar",
    "CreateAuraContainer", "CreateRaidTargetIndicator",
)
STYLE_MODULES = (
    "Player", "Target", "Focus", "TargetTarget", "Pet", "Boss", "Party",
    "Raid", "PartyPets", "RaidPets",
)


def body(name):
    start = SHARED.index(f"function UF:{name}")
    match = re.search(r"\nend\n", SHARED[start:])
    return SHARED[start:start + match.end()]


def calls(source, name):
    """Return complete calls using balanced parentheses, including multiline calls."""
    marker = f"UF:{name}("
    result = []
    offset = 0
    while (start := source.find(marker, offset)) >= 0:
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
                    result.append(source[start:index + 1])
                    offset = index + 1
                    break
        else:
            raise AssertionError(f"unterminated {name} call")
    return result


class ComponentConstructorCoverage(unittest.TestCase):
    def test_portrait_preserves_anchor_and_optional_background(self):
        source = body("CreatePortrait")
        self.assertIn("relativeTo or frame", source)
        self.assertIn('style ~= "OVERLAY"', source)
        self.assertIn("portrait.BG = background", source)
        self.assertIn("frame.Portrait = portrait", source)
        for module, side, alpha in (
            ("Player", 'Settings["player-portrait-style"] == "OVERLAY" and "CENTER" or "RIGHT"', 'Settings["player-overlay-alpha"] / 100'),
            ("Target", 'Settings["target-portrait-style"] == "OVERLAY" and "CENTER" or "LEFT"', 'Settings["target-overlay-alpha"] / 100'),
        ):
            mocked = (ROOT / f"{module}.lua").read_text()
            portrait = calls(mocked, "CreatePortrait")[0]
            self.assertIn(side, portrait)
            self.assertIn(alpha, portrait)

    def test_castbar_wires_ouf_callbacks_and_optional_latency(self):
        source = body("CreateCastbar")
        for field in ("Time", "Text", "Icon", "PostCastStart", "PostCastStop", "PostCastFail", "PostCastInterruptible"):
            self.assertIn(f"castbar.{field}", source)
        self.assertIn("if createSafeZone", source)
        player = calls((ROOT / "Player.lua").read_text(), "CreateCastbar")[0]
        target = calls((ROOT / "Target.lua").read_text(), "CreateCastbar")[0]
        self.assertIn("\n\t\t\ttrue,\n\t\t\ttrue,\n\t\t\t0.7,", player)
        self.assertIn("\n\t\t\tnil,\n\t\t\ttrue,\n\t\t\t0.3,", target)
        for callback in ("UF.PostCastStart", "UF.PostCastStop", "UF.PostCastFail", "UF.PostCastInterruptible"):
            self.assertIn(callback, player)
            self.assertIn(callback, target)

    def test_aura_preserves_growth_callbacks_and_optional_flags(self):
        source = body("CreateAuraContainer")
        for expression in ('auras["growth-x"] = growthX', 'auras["growth-y"] = growthY',
                           "auras.PostCreateIcon = postCreateIcon", "auras.PostUpdateIcon = postUpdateIcon",
                           "auras.CustomFilter = customFilter", "auras.onlyShowPlayer = onlyShowPlayer",
                           "auras.showStealableBuffs = showStealableBuffs"):
            self.assertIn(expression, source)
        target = (ROOT / "Target.lua").read_text()
        target_calls = "\n".join(calls(target, "CreateAuraContainer"))
        self.assertIn('"LEFT",\n\t\t"UP"', target_calls)
        self.assertIn("true", target_calls)
        for module in ("Player", "Target", "Focus", "Boss", "Party", "Raid"):
            self.assertTrue(calls((ROOT / f"{module}.lua").read_text(), "CreateAuraContainer"))

    def test_constructor_calls_never_pass_table_literals(self):
        for module in STYLE_MODULES:
            source = (ROOT / f"{module}.lua").read_text()
            for constructor in CONSTRUCTORS:
                for call in calls(source, constructor):
                    with self.subTest(module=module, constructor=constructor):
                        self.assertNotIn("{", call)
                        self.assertNotIn("}", call)

    def test_castbar_coordinates_are_scalar_arguments(self):
        shared = body("CreateCastbar")
        self.assertNotIn("unpack", shared)
        self.assertIn("backgroundTopLeftX or -1, backgroundTopLeftY or 1", shared)
        self.assertIn("backgroundBottomRightX or 1, backgroundBottomRightY or -1", shared)
        for module in ("Player", "Target", "Focus", "Boss"):
            for call in calls((ROOT / f"{module}.lua").read_text(), "CreateCastbar"):
                self.assertNotRegex(call, r"background(?:TopLeft|BottomRight)\s*=\s*\{")


if __name__ == "__main__":
    unittest.main()
