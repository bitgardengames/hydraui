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
    def test_single_unit_styles_delegate_with_family_descriptors(self):
        for module, prefix in (("Player", "unitframes-player"),
                               ("Target", "unitframes-target"),
                               ("Focus", "unitframes-focus"),
                               ("TargetTarget", "unitframes-targettarget"),
                               ("Boss", "unitframes-boss"),
                               ("Pet", "unitframes-pet"),
                               ("PartyPets", "party-pets"),
                               ("RaidPets", "raid-pets")):
            with self.subTest(module=module):
                source = (ROOT / f"{module}.lua").read_text()
                self.assertIn(f'settingsPrefix = "{prefix}"', source)
                self.assertIn("UF:BuildSingleUnitFrame(self, unit,", source)
                self.assertNotIn("UF:CreateHealthBar(", source)
                self.assertNotIn("UF:CreatePowerBar(", source)

    def test_single_unit_builder_resolves_family_settings_and_optional_hooks(self):
        source = (ROOT / "ComponentFactory.lua").read_text()
        build = source[source.index("function UF:BuildSingleUnitFrame"):source.index("function UF:CreatePortrait")]
        self.assertIn('config.settingsPrefix .. suffix', source)
        for hook in ("portrait", "cast", "auras", "postBuild"):
            self.assertIn(f"config.{hook}", build)
        for field in ("HealthLeft", "HealthRight", "PowerLeft", "PowerRight",
                      "RaidTargetIndicator"):
            self.assertIn(field, build)

    def test_party_and_raid_use_the_shared_group_builder(self):
        shared = (ROOT / "GroupFrames.lua").read_text()
        self.assertIn("function UF:BuildGroupFrame", shared)
        for module, family in (("Party", "party"), ("Raid", "raid")):
            source = (ROOT / f"{module}.lua").read_text()
            self.assertRegex(source, rf'prefix\s*=\s*"{family}"')
            self.assertIn("UF:BuildGroupFrame(frame, unit,", source)

    def test_group_descriptors_keep_family_specific_options(self):
        party = (ROOT / "Party.lua").read_text()
        raid = (ROOT / "Raid.lua").read_text()
        self.assertIn('healthTextureKey = "PartyHealthTexture"', party)
        self.assertIn('mouseoverKey = "PartyEnableMouseover"', party)
        self.assertIn("PartyDebuffFilter", party)
        self.assertIn('healthTextureKey="RaidHealthTexture"', raid)
        self.assertIn('mouseoverKey="RaidEnableMouseover"', raid)
        self.assertIn("RaidDebuffFilter", raid)

    def test_group_updates_reuse_operation_and_header_iterator(self):
        shared = (ROOT / "GroupFrames.lua").read_text()
        update = re.search(r"function UF:UpdateGroupFrames(.*?)\nend", shared, re.S).group(0)
        self.assertIn("self:ForEachHeaderChild(header, Operations[operation], value, descriptor)", update)
        self.assertNotIn("function(", update)

    def test_pet_styles_map_their_own_family_settings_in_the_factory(self):
        factory = (ROOT / "ComponentFactory.lua").read_text()
        self.assertIn('FamilySetting(config, "-width")', factory)
        self.assertIn('FamilySetting(config, "-health-height")', factory)
        self.assertIn('FamilySetting(config, "-health-reverse")', factory)
        cases = (("PartyPets", "party-pets", "party"), ("RaidPets", "raid-pets", "raid"))
        for module, pet_prefix, parent_prefix in cases:
            with self.subTest(module=module):
                source = (ROOT / f"{module}.lua").read_text()
                self.assertIn(f'settingsPrefix = "{pet_prefix}"', source)
                self.assertNotIn("CreateHealAndAbsorbBars", source)
                self.assertNotIn(f'Settings["{parent_prefix}-width"]', source)
                self.assertNotIn(f'Settings["{parent_prefix}-health-height"]', source)
                self.assertNotIn(f'Settings["{parent_prefix}-health-reverse"]', source)

    def test_family_descriptors_declare_optional_components_and_client_branches(self):
        player = (ROOT / "Player.lua").read_text()
        boss = (ROOT / "Boss.lua").read_text()
        self.assertIn('powerEnabledKey = "unitframes-player-enable-power"', player)
        self.assertIn("HydraUI.IsMainline", player)
        self.assertIn("HydraUI.IsVanilla or HydraUI.IsTBC", player)
        self.assertIn("portrait = BuildPlayerComponents", player)
        self.assertIn("threat = false", boss)

    def test_live_health_texture_update_reaches_every_prediction_texture(self):
        shared = (ROOT / "ComponentFactory.lua").read_text()
        update = re.search(
            r"local function SetHeaderHealthTexture\(frame, resolvedTexture\)(.*?)"
            r"function UF:SetHeaderHealthTexture\(header, value\)(.*?)\nend",
            shared,
            re.S,
        ).group(0)
        for expression in (
            "frame.Health:SetStatusBarTexture(resolvedTexture)",
            "frame.Health.bg:SetTexture(resolvedTexture)",
            "frame.HealBar:SetStatusBarTexture(resolvedTexture)",
            "frame.AbsorbsBar:SetStatusBarTexture(resolvedTexture)",
        ):
            self.assertIn(expression, update)
        self.assertIn("self:ForEachHeaderChild(header, SetHeaderHealthTexture, texture)", update)
        self.assertNotIn("function(frame, resolvedTexture)", update)
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


class UnitFrameSpawnerCoverage(unittest.TestCase):
    def test_load_delegates_to_focused_spawners(self):
        source = (ROOT / "UnitFrames.lua").read_text()
        spawning = (ROOT / "Spawning.lua").read_text()
        for helper in ("SpawnSingletonFrames", "SpawnBossFrames", "SpawnPartyHeaders",
                       "SpawnRaidHeaders", "SpawnNameplates"):
            self.assertIn(f"function UF:{helper}", spawning)
            self.assertIn(f"self:{helper}()", source)

    def test_singleton_descriptors_are_self_describing(self):
        source = (ROOT / "Spawning.lua").read_text()
        block = source[source.index("local SingletonUnits"):source.index("UF.SingletonUnits")]
        for field in ("unit", "globalName", "enabled", "dimensions", "defaultAnchor"):
            self.assertIn(f"{field} =", block)
        self.assertIn("postSpawn =", block)

    def test_growth_and_header_helpers_cover_shared_inputs(self):
        source = (ROOT / "Spawning.lua").read_text()
        growth = re.search(r"function UF:GetGrowthOffsets.*?\nend", source, re.S).group()
        for point in ("LEFT", "RIGHT", "TOP", "BOTTOM"):
            self.assertIn(f'point == "{point}"', growth)
        attrs = re.search(r"function UF:BuildHeaderAttributes.*?\nend", source, re.S).group()
        for attribute in ("initial-width", "initial-height", "showSolo", "showPlayer",
                          "showParty", "showRaid", "point", "xOffset", "yOffset"):
            self.assertIn(f'"{attribute}"', attrs)
        self.assertGreaterEqual(source.count("self:GetGrowthOffsets("), 2)


class UnitFrameModuleBoundaryCoverage(unittest.TestCase):
    def test_client_manifests_load_the_unit_frame_bundle(self):
        addon_root = ROOT.parents[1]
        manifests = tuple(addon_root.glob("HydraUI_*.toc"))
        self.assertTrue(manifests)
        for manifest in manifests:
            with self.subTest(manifest=manifest.name):
                source = manifest.read_text()
                self.assertIn(r"Elements\UnitFrames\UnitFrames.xml", source)
                self.assertNotIn(r"Elements\UnitFrames\UnitFrames.lua", source)

    def test_manifest_loads_support_modules_before_coordinator(self):
        manifest = (ROOT / "UnitFrames.xml").read_text()
        coordinator = manifest.index('file="UnitFrames.lua"')
        for module in ("ComponentFactory", "AuraSupport", "CastSupport",
                       "TotemSupport", "Spawning"):
            self.assertLess(manifest.index(f'file="{module}.lua"'), coordinator)

    def test_public_apis_remain_installed_on_uf(self):
        expected = {
            "ComponentFactory.lua": ("CreateHealthBar", "CreatePowerBar", "CreatePortrait",
                                     "CreateCastbar", "CreateAuraContainer", "SetHealthTexture",
                                     "SetHealthHeight", "SetHealthReverseFill"),
            "AuraSupport.lua": ("PostCreateIcon", "PostUpdateIcon",
                                "PostCreateAuraWatchIcon"),
            "CastSupport.lua": ("PostCastStart", "PostCastStop", "PostCastFail"),
            "TotemSupport.lua": ("PostUpdateTotems",),
            "Spawning.lua": ("SpawnSingletonFrames", "SpawnBossFrames",
                             "BuildHeaderAttributes", "SpawnPartyHeaders",
                             "SpawnRaidHeaders", "SpawnNameplates"),
        }
        for filename, methods in expected.items():
            source = (ROOT / filename).read_text()
            for method in methods:
                self.assertRegex(source, rf"UF[.:]{method}\b")

    def test_coordinator_delegates_constructor_installation(self):
        source = (ROOT / "UnitFrames.lua").read_text()
        for module in ("ComponentFactory", "AuraSupport", "CastSupport",
                       "TotemSupport", "Spawning"):
            self.assertIn(f"ns.UnitFrame{module}(UF, Hider)", source)
