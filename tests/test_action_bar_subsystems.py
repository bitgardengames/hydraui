"""Mock and static regression coverage for focused action-bar subsystems."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1]
ACTION_BARS = ROOT / "HydraUI/Elements/ActionBars"
CORE = (ACTION_BARS / "ActionBars.lua").read_text()
MANIFEST = (ACTION_BARS / "ActionBars.xml").read_text()


class MockSubsystem:
    def __init__(self, name, available, calls):
        self.name = name
        self.available = available
        self.calls = calls

    def IsAvailable(self):
        return self.available

    def Load(self):
        self.calls.append(self.name)


def resolve_and_load(subsystems):
    """Python mock of the deliberately tiny Lua subsystem contract."""
    supported = [subsystem for subsystem in subsystems if subsystem.IsAvailable()]
    for subsystem in supported:
        subsystem.Load()
    return supported


class ActionBarSubsystemCoverage(unittest.TestCase):
    def test_availability_filters_unsupported_subsystems_once(self):
        calls = []
        systems = [MockSubsystem("standard", True, calls), MockSubsystem("pet", False, calls)]
        supported = resolve_and_load(systems)
        self.assertEqual([systems[0]], supported)
        self.assertEqual(["standard"], calls)

    def test_load_order_is_registration_order(self):
        calls = []
        systems = [MockSubsystem(name, True, calls) for name in ("standard", "pet", "extra", "totem")]
        resolve_and_load(systems)
        self.assertEqual(["standard", "pet", "extra", "totem"], calls)
        registration_order = re.findall(r'<Script file="([^"]+)"', MANIFEST)
        self.assertEqual(
            ["ActionBars.lua", "StandardBars.lua", "PetStanceBars.lua", "ExtraFlyout.lua", "LegacyTotem.lua", "Settings.lua"],
            registration_order,
        )

    def test_each_optional_module_has_small_contract(self):
        for filename in ("StandardBars.lua", "PetStanceBars.lua", "ExtraFlyout.lua", "LegacyTotem.lua"):
            source = (ACTION_BARS / filename).read_text()
            self.assertRegex(source, r"function \w+:IsAvailable\(\)")
            self.assertRegex(source, r"function \w+:Load\(\)")
            self.assertEqual(1, source.count("AB:RegisterSubsystem("))
        self.assertIn("self.SupportedSubsystems = supported", CORE)

    def test_legacy_hooks_are_registered_once(self):
        source = (ACTION_BARS / "LegacyTotem.lua").read_text()
        for hook in (
            "MultiCastSummonSpellButton_Update",
            "MultiCastRecallSpellButton_Update",
            "MultiCastFlyoutFrame_LoadSlotSpells",
        ):
            self.assertEqual(1, source.count(f'hooksecurefunc("{hook}"'))

    def test_toc_manifests_were_not_refactored(self):
        for toc in (ROOT / "HydraUI").glob("*.toc"):
            self.assertIn(r"Elements\ActionBars\ActionBars.lua", toc.read_text())


if __name__ == "__main__":
    unittest.main()
