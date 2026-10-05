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
        assert re.search(rf'(?:RegisterElement|Install)\("{name}"', sources)


def test_classic_power_timers_are_driven_without_the_reference_runtime():
    source = (ROOT / "Elements/PowerTimers.lua").read_text()
    assert 'UF:RegisterElement("ManaRegen", {' in source
    assert 'frame:RegisterEvent("UNIT_POWER_FREQUENT", UpdateMana)' in source
    assert 'element:SetScript("OnUpdate", ManaOnUpdate)' in source
    assert 'UF:RegisterElement("EnergyTick", {' in source


def test_power_timers_are_limited_to_supported_clients():
    elements = (ROOT / "Elements/PowerTimers.lua").read_text()
    player = (ROOT / "Frames/Player.lua").read_text()

    mana_guard = "HydraUI.IsMists or HydraUI.IsMainline"
    energy_guard = "HydraUI.IsVanilla or HydraUI.IsTBC"

    assert mana_guard in elements
    assert f"not ({mana_guard})" in player
    assert energy_guard in elements
    assert energy_guard in player


def test_player_resources_preserve_dynamic_ouf_behavior():
    source = (ROOT / "Frames/Player.lua").read_text()

    extended = (ROOT / "Elements/Extended.lua").read_text()

    assert 'GetUnitChargedPowerPoints("player")' in source
    assert 'segment.Charged:SetShown(charged[i] == true)' in source
    assert 'segment:SetScript("OnUpdate", ready and nil or UpdateRune)' in source
    assert 'segment:SetID(i)' in source
    assert 'type(unit) == "string" and unit ~= "player"' in source
    assert 'GetRuneType(segment:GetID())' in source
    assert 'segment:SetStatusBarColor(r, g, b)' in source
    assert 'frame:UnregisterEvent("RUNE_POWER_UPDATE", UpdatePlayerResources)' in source
    assert "if frame.ClassResource == element then" in extended


def test_player_resources_resolve_unit_frame_module_before_registration():
    source = (ROOT / "Frames/Player.lua").read_text()

    assert source.index('local UF = HydraUI:GetModule("Unit Frames")') < source.index(
        'UF:RegisterElement("PlayerResources", {'
    )


def test_totems_stop_timers_and_events_when_disabled():
    source = (ROOT / "Elements/TotemSupport.lua").read_text()

    assert 'frame:UnregisterEvent("PLAYER_TOTEM_UPDATE", UpdateTotems)' in source
    assert "activeTotemBars[bar] = nil" in source
    assert "totemUpdater:SetScript(\"OnUpdate\", nil)" in source


def test_native_element_modules_load_before_frames_are_spawned():
    manifest = (ROOT / "UnitFrames.xml").read_text()
    coordinator = manifest.index('file="UnitFrames.lua"')
    for module in ("Indicators", "Dispel", "AuraWatch", "PowerTimers"):
        assert manifest.index(f'file="Elements/{module}.lua"') < coordinator


def test_power_color_supports_pet_alternative_power_colors():
    source = (ROOT / "Elements/Power.lua").read_text()

    assert "local powerType, token, altR, altG, altB = UnitPowerType(unit)" in source
    assert "bar:GetAlternativeColor(unit, powerType, token, altR, altG, altB)" in source
    assert "r, g, b = altR, altG, altB" in source
    assert "color = frame.colors.power.MANA" in source


def test_pvp_indicator_honor_level_event_is_retail_only():
    source = (ROOT / "Elements/Indicators.lua").read_text()
    retail_guard = "if HydraUI.IsMainline and not HydraUI.IsForever then"
    event_registration = 'PvPIndicatorEvents[#PvPIndicatorEvents + 1] = {"HONOR_LEVEL_UPDATE", true}'

    assert retail_guard in source
    assert source.index(retail_guard) < source.index(event_registration) < source.index(
        "\nend", source.index(retail_guard)
    )


def test_range_fader_does_not_inspect_inaccessible_secret_results():
    source = (ROOT / "Elements/Range.lua").read_text()

    assert "HydraUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)" in source
    assert "if IsInaccessible(connected) then" in source
    assert "if IsInaccessible(inRange) then" in source
    assert "if IsInaccessible(checked) then" in source
    assert source.index("if IsInaccessible(checked) then") < source.index(
        "local outsideRange = connected and checked and not inRange"
    )


def test_range_driver_only_runs_while_enabled_frames_are_visible():
    source = (ROOT / "Elements/Range.lua").read_text()

    assert "C_Timer.NewTicker(0.2, UpdateRanges)" in source
    assert 'frame:HookScript("OnShow", RangeOnShow)' in source
    assert 'frame:HookScript("OnHide", RangeOnHide)' in source
    assert "if RangeTicker and not next(RangeFrames) then" in source
    assert "RangeTicker:Cancel()" in source
    assert "RangeTicker = nil" in source
    assert "if RangeEnabledFrames[frame] then" in source


def test_vanilla_health_predictions_are_driven_by_libhealcomm():
    source = (ROOT / "Elements/HealthPrediction.lua").read_text()

    assert 'HydraUI.IsVanilla and LibStub and LibStub("LibHealComm-4.0", true)' in source
    assert "HealComm:GetHealAmount(guid, HealComm.ALL_HEALS)" in source
    assert "HealComm:GetHealModifier(guid)" in source
    for callback in (
        "HealComm_HealStarted",
        "HealComm_HealUpdated",
        "HealComm_HealDelayed",
        "HealComm_HealStopped",
        "HealComm_ModifierChanged",
        "HealComm_GUIDDisappeared",
    ):
        assert f'HealComm.RegisterCallback(frame, "{callback}"' in source
        assert f'HealComm.UnregisterCallback(frame, "{callback}")' in source

    assert 'frame:RegisterEvent("PLAYER_TARGET_CHANGED", UpdatePrediction, true)' in source
    assert '"UNIT_HEALTH_FREQUENT"' in source
