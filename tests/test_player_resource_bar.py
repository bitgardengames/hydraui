"""Static/mocked coverage for Player's class-resource component."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames/Frames/Player.lua").read_text()


def function_body(name):
    start = SOURCE.index(f"local {name} = function")
    next_function = SOURCE.find("\nlocal ", start + 10)
    return SOURCE[start:next_function if next_function >= 0 else None]


class PlayerResourceDescriptorCoverage(unittest.TestCase):
    def test_descriptor_matrix_covers_supported_class_clients(self):
        # Unconditional descriptors cover every client on which the class exists.
        for class_name, field, count in (
            ("ROGUE", "ComboPoints", 7),
            ("DRUID", "ComboPoints", 5),
            ("DEATHKNIGHT", "Runes", 6),
            ("MONK", "ClassPower", 6),
            ("EVOKER", "ClassPower", 6),
        ):
            self.assertRegex(SOURCE, rf'{class_name} = {{ field = "{field}".*count = .*{count}')

        # Version-gated combinations follow the class-power reference. Numeric
        # resources continue to use the ordinary player Power bar.
        for expression in (
            'WARLOCK = (HydraUI.IsMainline or HydraUI.IsCata or HydraUI.IsMists)',
            'MAGE = (HydraUI.IsMainline or HydraUI.IsMists)',
            'PALADIN = (HydraUI.IsMainline or HydraUI.IsCata or HydraUI.IsMists)',
            'PRIEST = HydraUI.IsMists',
            'SHAMAN = (HydraUI.IsWrath or HydraUI.IsMists or HydraUI.IsMainline)',
        ):
            self.assertIn(expression, SOURCE)
        self.assertLess(SOURCE.index("local PlayerResourceDescriptors"),
                        SOURCE.index("local function BuildPlayerComponents"))

    def test_descriptors_capture_ouf_and_exceptional_behavior(self):
        for token in ('field = "ComboPoints"', 'field = "Runes"', 'field = "Totems"',
                      'alias = "SoulShards"', 'alias = "ArcaneCharges"',
                      'alias = "Chi"', 'alias = "HolyPower"', 'alias = "Essence"',
                      'alias = "ShadowOrbs"', 'alias = "MaelstromWeapon"',
                      "countProvider = function()", "color = function(i)",
                      "postUpdate = UF.PostUpdateTotems", "charged = HydraUI.IsMainline",
                      "runes = true", "stagger = true", "totems = true"):
            self.assertIn(token, SOURCE)
        self.assertNotIn("ArcanePower", SOURCE)

    def test_resource_visibility_and_values_follow_runtime_state(self):
        for token in (
            '"PLAYER_SPECIALIZATION_CHANGED"',
            '"UNIT_AURA"', "descriptor.active()", "resource:SetShown(active)",
            "descriptor.currentProvider", "descriptor.maximumProvider",
            "UnitPowerDisplayMod", "current - i + 1",
        ):
            self.assertIn(token, SOURCE)
        self.assertNotIn('"ACTIVE_TALENT_GROUP_CHANGED"', SOURCE)
        self.assertNotIn('"PLAYER_TALENT_UPDATE"', SOURCE)
        self.assertIn("PlayerAuraStacks({[53817] = true, [344179] = true})", SOURCE)
        self.assertIn("PlayerSpecializationIs(263, 2)", SOURCE)

    def test_hidden_resources_do_not_leave_an_aura_gap(self):
        update_start = SOURCE.index("local function UpdatePlayerResources")
        update_end = SOURCE.index("\nlocal function EnablePlayerResources", update_start)
        update_body = SOURCE[update_start:update_end]
        anchors_start = SOURCE.index("UpdatePlayerResourceAnchors = function")
        anchors_end = SOURCE.index("\nlocal function UpdatePlayerPowerLayout", anchors_start)
        anchors_body = SOURCE[anchors_start:anchors_end]

        self.assertGreaterEqual(update_body.count("UpdatePlayerResourceAnchors(frame)"), 3)
        helper_start = SOURCE.index("local function GetPlayerResourceAnchor")
        helper_end = SOURCE.index("\nlocal function UpdatePlayerAuraAnchors", helper_start)
        helper_body = SOURCE[helper_start:helper_end]
        self.assertIn("resource:IsShown()", helper_body)
        self.assertIn("not resourceDetached and resource or frame", helper_body)
        # The helper declaration plus the aura and threat call sites.
        self.assertEqual(SOURCE.count("GetPlayerResourceAnchor(frame, resourceDetached)"), 3)
        self.assertIn("UpdatePlayerAuraAnchors(frame, resourceDetached)", anchors_body)

        # Visibility is not exclusively controlled by resource power events:
        # disabling an element and native providers may show/hide it directly.
        # Both transitions must therefore refresh the aura anchors as well.
        self.assertIn('resource:HookScript("OnShow"', SOURCE)
        self.assertIn('resource:HookScript("OnHide"', SOURCE)
        hooks_start = SOURCE.index('resource:HookScript("OnShow"')
        hooks_end = SOURCE.index("return resource", hooks_start)
        visibility_hooks = SOURCE[hooks_start:hooks_end]
        self.assertEqual(visibility_hooks.count("UpdatePlayerResourceAnchors(frame)"), 2)

    def test_component_has_stable_update_interface(self):
        for method in ("SetWidth", "SetHeight", "SetTexture", "SetDetached"):
            self.assertIn(f"function resource:{method}", SOURCE)
        self.assertIn("frame.ClassResource, frame.AuraParent = resource, resource", SOURCE)

    def test_resource_color_preserves_all_return_values(self):
        self.assertIn("local function GetSegmentColor(index)", SOURCE)
        self.assertIn("return descriptor.color(index)", SOURCE)
        self.assertIn("return HydraUI:HexToRGB(Settings[descriptor.colorSetting])", SOURCE)
        self.assertIn("local r, g, b = GetSegmentColor(i)", SOURCE)
        self.assertNotIn("descriptor.color and descriptor.color(i) or", SOURCE)

    def test_resource_updates_reapply_configured_colors(self):
        start = SOURCE.index("local function UpdatePlayerResources")
        body = SOURCE[start:SOURCE.index("\nlocal function EnablePlayerResources", start)]
        self.assertIn("if descriptor.colorSetting then", body)
        self.assertIn("HydraUI:HexToRGB(Settings[descriptor.colorSetting])", body)
        self.assertIn("segment:SetStatusBarColor(r, g, b)", body)
        self.assertIn("segment.bg:SetVertexColor(r, g, b)", body)

    def test_settings_updates_only_use_canonical_component(self):
        for name, call in (
            ("UpdatePlayerWidth", "Frame.ClassResource:SetWidth(value)"),
            ("UpdateResourceBarHeight", "UpdatePlayerResourceLayout(Frame, value)"),
            ("UpdateResourceTexture", "Frame.ClassResource:SetTexture(value)"),
            ("UpdateResourcePosition", "UpdatePlayerResourceLayout(frame, nil, value)"),
        ):
            body = function_body(name)
            self.assertIn(call, body)
            for legacy in ("ComboPoints", "SoulShards", "ArcaneCharges", "Chi", "Runes", "HolyPower", "Totems", "Essence"):
                self.assertNotIn(f"Frame.{legacy}", body)

    def test_resource_and_power_layouts_are_single_sources_of_anchors(self):
        self.assertIn("local function UpdatePlayerAuraAnchors(frame, resourceDetached)", SOURCE)
        self.assertIn("local function UpdatePlayerPowerLayout(frame, powerHeight, detached, healthHeight)", SOURCE)
        self.assertIn("local function UpdatePlayerResourceLayout(frame, resourceHeight, detached)", SOURCE)
        self.assertGreaterEqual(SOURCE.count("UpdatePlayerAuraAnchors("), 4)
        self.assertGreaterEqual(SOURCE.count("UpdatePlayerPowerLayout("), 3)
        self.assertGreaterEqual(SOURCE.count("UpdatePlayerResourceLayout("), 4)


if __name__ == "__main__":
    unittest.main()
