"""Static regression coverage for allocation-free unit-frame constructors."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"
FRAMES = ROOT / "Frames"
ELEMENTS = ROOT / "Elements"
SHARED = "\n".join(
    (ELEMENTS / name).read_text()
    for name in ("Common.lua", "SingleUnit.lua", "PortraitWidget.lua", "Castbar.lua",
                 "Auras.lua", "RaidTarget.lua", "Updates.lua")
)


def body(name):
    start = SHARED.index(f"function UF:{name}")
    match = re.search(r"\nend\n", SHARED[start:])
    return SHARED[start:start + match.end()]


class ComponentConstructorCoverage(unittest.TestCase):
    def test_range_driver_state_is_local_to_the_range_element(self):
        range_source = (ELEMENTS / "Range.lua").read_text()
        prediction_source = (ELEMENTS / "HealthPrediction.lua").read_text()

        self.assertIn(
            "local RangeEnabledFrames, RangeFrames, RangeTicker = {}, {}, nil",
            range_source,
        )
        self.assertNotIn("RangeFrames", prediction_source)
        self.assertNotIn("RangeTicker", prediction_source)

    def test_portrait_matches_ouf_availability_and_class_defaults(self):
        source = (ELEMENTS / "Portrait.lua").read_text()
        for behavior in (
            "UnitIsConnected(unit) and UnitIsVisible(unit)",
            "TalkToMeQuestionMark.m2",
            "portrait:SetCamDistanceScale(0.25)",
            "portrait:SetPortraitZoom(1)",
            'portrait:SetAtlas("classicon-" .. class)',
            "portrait:PostUpdate(unit, hasStateChanged)",
            'frame:RegisterEvent("PARTY_MEMBER_ENABLE",UpdatePortrait)',
        ):
            self.assertIn(behavior, source)

    def test_updater_resolves_each_singleton_once(self):
        source = SHARED[SHARED.index("function UF:CreateUnitUpdater"):]
        self.assertIn("local frame = HydraUI.UnitFrames[unit]", source)
        self.assertIn("update(self, frame, value, options)", source)
        self.assertNotIn("pairs(HydraUI.UnitFrames)", source)

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
        for path in ROOT.rglob("*.lua"):
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
            source = (FRAMES / f"{module}.lua").read_text()
            self.assertIn("CreateAuraContainer(frame,", source)
            self.assertNotRegex(source, r'CreateFrame\("Frame", frame:GetName\(\) \.\. "(?:Buffs|Debuffs)"')

    def test_nameplate_aura_frames_do_not_require_a_named_owner(self):
        source = (FRAMES / "NamePlates.lua").read_text()

        self.assertEqual(source.count('CreateFrame("Frame", nil, self)'), 3)
        self.assertNotIn('self:GetName() .. "Buffs"', source)
        self.assertNotIn('self:GetName() .. "Debuffs"', source)

    def test_optional_client_behavior_is_passed_directly(self):
        player = (FRAMES / "Player.lua").read_text()
        target = (FRAMES / "Target.lua").read_text()
        self.assertIn("true, true, 0.7, Settings[\"unitframes-player-cast-classcolor\"]", player)
        self.assertIn("nil, true, 0.3, Settings[\"unitframes-target-cast-classcolor\"]", target)

    def test_all_non_group_styles_have_one_factory_entry_point(self):
        for module in ("Player", "Target", "Focus", "Boss", "Pet",
                       "TargetTarget", "PartyPets", "RaidPets"):
            source = (FRAMES / f"{module}.lua").read_text()
            style = source[source.index("HydraUI.StyleFuncs["):]
            style = style[:style.index("\nend")]
            self.assertIn("UF:BuildSingleUnitFrame(self, unit,", style)


if __name__ == "__main__":
    unittest.main()
