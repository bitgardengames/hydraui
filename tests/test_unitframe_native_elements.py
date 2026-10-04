from pathlib import Path
import re


ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"


def test_every_layout_element_has_a_native_handler():
    sources = "\n".join(path.read_text() for path in (ROOT / "Elements").glob("*.lua"))
    expected = {
        "AssistantIndicator", "AuraWatch", "CombatIndicator", "Dispel",
        "EnergyTick", "GroupRoleIndicator", "LeaderIndicator", "ManaRegen",
        "PhaseIndicator", "PowerPrediction", "PvPIndicator",
        "ReadyCheckIndicator", "ResurrectIndicator", "TargetIndicator",
    }
    for name in expected:
        assert re.search(rf"(?:Handlers\.|Install\(\")({name})(?:\s*=|\")", sources)


def test_classic_power_timers_are_driven_without_the_reference_runtime():
    source = (ROOT / "Elements/PowerTimers.lua").read_text()
    assert 'Handlers.ManaRegen=' in source
    assert 'frame:RegisterEvent("UNIT_POWER_FREQUENT",UpdateMana)' in source
    assert 'element:SetScript("OnUpdate", ManaOnUpdate)' in source
    assert 'Handlers.EnergyTick=' in source


def test_native_element_modules_load_before_frames_are_spawned():
    manifest = (ROOT / "UnitFrames.xml").read_text()
    coordinator = manifest.index('file="UnitFrames.lua"')
    for module in ("Indicators", "Dispel", "AuraWatch", "PowerTimers"):
        assert manifest.index(f'file="Elements/{module}.lua"') < coordinator
