from pathlib import Path


ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"


def test_native_runtime_exposes_every_bundled_element_family():
    sources = "\n".join(path.read_text() for path in (ROOT / "Elements").glob("*.lua"))
    expected = {
        "AdditionalPower", "AlternativePower", "AssistantIndicator", "AuraWatch",
        "Auras", "Castbar", "ClassPower", "CombatIndicator", "ComboPoints",
        "Dispel", "EliteIndicator", "EnergyTick", "GroupRoleIndicator",
        "Happiness", "HealComm", "HealPrediction", "Health", "HolyPower",
        "LeaderIndicator", "ManaRegen", "PhaseIndicator", "Portrait", "Power",
        "PowerPrediction", "PvPClassificationIndicator", "PvPIndicator",
        "QuestIndicator", "RaidRoleIndicator", "RaidTargetIndicator", "Range",
        "ReadyCheckIndicator", "RestingIndicator", "ResurrectIndicator", "Runes",
        "Smooth", "SoulShards", "Stagger", "SummonIndicator", "TargetIndicator",
        "ThreatIndicator", "Totems",
    }

    for name in expected:
        assert any(token in sources for token in (
            f'RegisterElement("{name}"', f'Install("{name}"',
            f'Resource("{name}"', f'Points("{name}"',
            f'TextureIndicator("{name}"',
        )), name


def test_smoothing_is_loaded_and_defaults_health_and_power_on():
    manifest = (ROOT / "UnitFrames.xml").read_text()
    smooth = (ROOT / "Elements/Smooth.lua").read_text()

    assert 'file="Elements/Smooth.lua"' in manifest
    assert "frame.Health.Smooth ~= false" in smooth
    assert "frame.Power.Smooth ~= false" in smooth
    assert "issecretvalue(value)" in smooth
