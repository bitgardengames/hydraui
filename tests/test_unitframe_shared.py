"""Static regression coverage for shared unit-frame construction.

The settings are intentionally treated as distinct sentinels: assertions verify each
style passes its own family values into the constructors instead of inheriting a
parent frame's dimensions or reverse-fill setting.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames"
FRAMES = ROOT / "Frames"
ELEMENTS = ROOT / "Elements"
FACTORY = "\n".join(
    (ELEMENTS / name).read_text()
    for name in ("Common.lua", "SingleUnit.lua", "PortraitWidget.lua", "Castbar.lua",
                 "Auras.lua", "RaidTarget.lua", "Updates.lua")
)
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
    def test_nameplates_inherit_scale_from_blizzard_parent_once(self):
        source = (FRAMES / "NamePlates.lua").read_text()
        core = (ROOT / "Core.lua").read_text()
        constructor = core[
            core.index("function UnitFrames:CreateNamePlateButton"):
            core.index("function UnitFrames:SetNamePlateUnit")
        ]

        self.assertIn('self:SetScale(1)', source)
        self.assertNotIn('self:SetScale(UIParent:GetScale())', source)
        self.assertIn(
            "CreateNamePlateButton(base, unit, HydraUI.StyleFuncs.nameplate)",
            source,
        )
        self.assertIn('CreateFrame("Button", nil, parent)', constructor)

    def test_nameplate_scale_cvars_are_applied_after_login(self):
        source = (FRAMES / "NamePlates.lua").read_text()
        driver = source[source.index("function UF:CreateNamePlateDriver"):source.index("UF.NamePlateCallback =")]
        self.assertIn("if IsLoggedIn() then", driver)
        self.assertIn('driver:RegisterEvent("PLAYER_LOGIN")', driver)
        self.assertIn('if event == "PLAYER_LOGIN" then', driver)
        self.assertIn("ApplyCVars()", driver)

    def test_health_path_calls_color_update_without_ambiguous_syntax(self):
        shared = (ELEMENTS / "Health.lua").read_text()
        health_path = shared[shared.index("local function HealthPath"):shared.index("local function EnableHealth")]
        self.assertIn("local updateColor = bar.UpdateColor or HealthColor", health_path)
        self.assertIn("updateColor(frame, event, unit)", health_path)
        self.assertNotRegex(health_path, r"(?m)^\s*\(")

    def test_singleton_settings_use_shared_update_factory(self):
        shared = FACTORY
        self.assertIn("function UF:CreateUnitUpdater(unit, operation, options)", shared)
        for operation in ("Width", "HealthHeight", "PowerHeight", "HealthColor",
                          "PowerColor", "HealthReverse", "PowerReverse",
                          "HealthTexture", "PowerTexture", "AuraSize",
                          "AuraSpacing", "ElementEnabled"):
            self.assertIn(f"function UnitOperations.{operation}", shared)
        for module in ("Focus", "Pet", "TargetTarget", "Boss", "Target", "Player"):
            self.assertIn("UF:CreateUnitUpdater(", (FRAMES / f"{module}.lua").read_text())

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
                source = (FRAMES / f"{module}.lua").read_text()
                self.assertIn(f'settingsPrefix = "{prefix}"', source)
                self.assertIn("UF:BuildSingleUnitFrame(self, unit,", source)
                self.assertNotIn("UF:CreateHealthBar(", source)
                self.assertNotIn("UF:CreatePowerBar(", source)

    def test_single_unit_builder_resolves_family_settings_and_optional_hooks(self):
        single_unit = (ELEMENTS / "SingleUnit.lua").read_text()
        source = FACTORY
        build = source[source.index("function UF:BuildSingleUnitFrame"):source.index("function UF:CreatePortrait")]
        self.assertLess(single_unit.index("local SingleUnitText"),
                        single_unit.index("function UF:BuildSingleUnitFrame"))
        self.assertNotIn("SingleUnitText", (ELEMENTS / "Common.lua").read_text())
        self.assertIn('config.settingsPrefix .. suffix', source)
        for hook in ("portrait", "cast", "auras", "postBuild"):
            self.assertIn(f"config.{hook}", build)
        for field in ("HealthLeft", "HealthRight", "PowerLeft", "PowerRight",
                      "RaidTargetIndicator"):
            self.assertIn(field, build)

    def test_party_and_raid_use_the_shared_group_builder(self):
        shared = (FRAMES / "GroupFrames.lua").read_text()
        self.assertIn("function UF:BuildGroupFrame", shared)
        for module, family in (("Party", "party"), ("Raid", "raid")):
            source = (FRAMES / f"{module}.lua").read_text()
            self.assertRegex(source, rf'prefix\s*=\s*"{family}"')
            self.assertIn("UF:BuildGroupFrame(frame, unit,", source)

    def test_group_builder_delegates_complex_widgets_to_focused_helpers(self):
        shared = (FRAMES / "GroupFrames.lua").read_text()
        build = shared[shared.index("function UF:BuildGroupFrame"):shared.index("local Operations")]

        for helper in ("CreateDeadAnimation", "CreatePhaseIndicator",
                       "CreateDispelIndicator"):
            self.assertLess(shared.index(f"local function {helper}"),
                            shared.index("function UF:BuildGroupFrame"))
            self.assertIn(f"{helper}(", build)

        # Constructors whose return values are installed on the frame should not
        # create throwaway locals in this frequently used group-frame path.
        self.assertIn("UF:CreateHealAndAbsorbBars(", build)
        self.assertNotIn("local heal, absorbs =", build)
        self.assertIn("UF:CreateMouseoverHighlight(frame,", build)
        self.assertNotIn("local highlight =", build)

    def test_group_descriptors_keep_family_specific_options(self):
        cases = (
            ("Party", "PartyHealthTexture", "PartyEnableMouseover", "PartyDebuffFilter"),
            ("Raid", "RaidHealthTexture", "RaidEnableMouseover", "RaidDebuffFilter"),
        )

        for module, health_texture, mouseover, debuff_filter in cases:
            with self.subTest(module=module):
                source = (FRAMES / f"{module}.lua").read_text()
                self.assertRegex(source, rf'healthTextureKey\s*=\s*"{health_texture}"')
                self.assertRegex(source, rf'mouseoverKey\s*=\s*"{mouseover}"')
                self.assertIn(debuff_filter, source)

    def test_group_updates_reuse_operation_and_header_iterator(self):
        shared = (FRAMES / "GroupFrames.lua").read_text()
        update = re.search(r"function UF:UpdateGroupFrames(.*?)\nend", shared, re.S).group(0)
        self.assertIn("self:ForEachHeaderChild(header, Operations[operation], value, descriptor)", update)
        self.assertNotIn("function(", update)

    def test_secure_group_headers_register_and_drive_their_children(self):
        source = (ROOT / "Spawning.lua").read_text()
        initializer = source[
            source.index("local HEADER_INITIAL_CONFIG"):
            source.index("function UF:CreateGroupHeader")
        ]
        creator = source[
            source.index("function UF:CreateGroupHeader"):
            source.index("local function HeaderAttributes")
        ]

        self.assertIn("RegisterUnitWatch(self)", initializer)
        self.assertIn('Header:GetAttribute("showRaid")', initializer)
        self.assertIn('Header:GetAttribute("showParty")', initializer)
        self.assertIn('Header:GetAttribute("HydraUI-headerType") == "pet"', initializer)
        self.assertIn('Header:CallMethod("InitializeChild", self:GetName(), unit)', initializer)
        self.assertIn("SecureHandlerStateTemplate", creator)
        self.assertIn("SecureHandlerEnterLeaveTemplate", creator)
        self.assertIn('header:SetAttribute("HydraUI-headerType", petHeader and "pet" or "group")', creator)
        self.assertIn('child:GetAttribute("unit") or guessedUnit', creator)
        self.assertIn(
            'RegisterAttributeDriver(header, "state-visibility", condition)',
            creator,
        )
        self.assertNotIn('RegisterStateDriver(header, "visibility", condition)', creator)

    def test_pet_styles_map_their_own_family_settings_in_the_factory(self):
        factory = FACTORY
        self.assertIn('FamilySetting(config, "-width")', factory)
        self.assertIn('FamilySetting(config, "-health-height")', factory)
        self.assertIn('FamilySetting(config, "-health-reverse")', factory)
        cases = (("PartyPets", "party-pets", "party"), ("RaidPets", "raid-pets", "raid"))
        for module, pet_prefix, parent_prefix in cases:
            with self.subTest(module=module):
                source = (FRAMES / f"{module}.lua").read_text()
                self.assertIn(f'settingsPrefix = "{pet_prefix}"', source)
                self.assertNotIn("CreateHealAndAbsorbBars", source)
                self.assertNotIn(f'Settings["{parent_prefix}-width"]', source)
                self.assertNotIn(f'Settings["{parent_prefix}-health-height"]', source)
                self.assertNotIn(f'Settings["{parent_prefix}-health-reverse"]', source)

    def test_family_descriptors_declare_optional_components_and_client_branches(self):
        player = (FRAMES / "Player.lua").read_text()
        boss = (FRAMES / "Boss.lua").read_text()
        self.assertIn('powerEnabledKey = "unitframes-player-enable-power"', player)
        self.assertIn("HydraUI.IsMainline", player)
        self.assertIn("HydraUI.IsVanilla or HydraUI.IsTBC", player)
        self.assertIn("portrait = BuildPlayerComponents", player)
        self.assertIn("threat = false", boss)

    def test_live_health_texture_update_reaches_every_prediction_texture(self):
        shared = FACTORY
        update = re.search(r"function UF:SetHealthTexture\(.*?\nend", shared, re.S).group(0)
        for expression in (
            "frame.Health:SetStatusBarTexture(texture)",
            "frame.Health.bg:SetTexture(texture)",
            "frame.HealBar:SetStatusBarTexture(texture)",
            "frame.AbsorbsBar:SetStatusBarTexture(texture)",
        ):
            self.assertIn(expression, update)

        # Pet-frame textures are fixed to ui-widget-texture and expose no live
        # texture control, so their modules should not carry unreachable callbacks.
        for module in ("PartyPets", "RaidPets"):
            source = (FRAMES / f"{module}.lua").read_text()
            self.assertNotIn("SetHeaderHealthTexture", source)
            self.assertNotIn("UpdateHealthTexture", source)

    def test_debuff_only_frames_initialize_their_aura_container(self):
        source = (ELEMENTS / "AuraSupport.lua").read_text()
        enable = source[source.index("local function EnableAuras"):source.index("local function DisableAuras")]

        self.assertIn("EnableContainer(frame.Buffs)", enable)
        self.assertIn("EnableContainer(frame.Debuffs)", enable)
        self.assertIn("container.__owner = frame", enable)
        self.assertNotIn("ipairs({frame.Buffs, frame.Debuffs})", enable)


if __name__ == "__main__":
    unittest.main()


class UnitFrameSpawnerCoverage(unittest.TestCase):
    def test_frame_kinds_share_the_runtime_initializer(self):
        source = (ROOT / "Core.lua").read_text()
        initializer = source[
            source.index("local function PrepareFrame"):
            source.index("local function BuildElements")
        ]

        for state in ("_events", "_unitEvents", "_refreshers",
                      "_enabledElements"):
            self.assertIn(state, initializer)
        unit_initializer = source[
            source.index("local function InitializeUnitButton"):
            source.index("function UnitFrames:CreateUnitButton")
        ]
        self.assertIn("PrepareFrame(frame, unit, pollsUnit)", unit_initializer)

        for constructor in ("CreateUnitButton", "InitializeHeaderChild"):
            body = source[source.index(f"function UnitFrames:{constructor}"):]
            body = body[:body.index("\nend")]
            self.assertIn("InitializeUnitButton(frame, unit, builder,", body)

        nameplate = source[source.index("function UnitFrames:CreateNamePlateButton"):]
        nameplate = nameplate[:nameplate.index("\nend")]
        self.assertIn("PrepareFrame(frame, unit, false)", nameplate)

        self.assertNotIn("frame.__elements", source)
        self.assertIn("frame.Refresh = Refresh", initializer)

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

    def test_group_header_callback_exists_before_secure_children_can_spawn(self):
        source = (ROOT / "Spawning.lua").read_text()
        create_header = source[
            source.index("function UF:CreateGroupHeader"):
            source.index("local function HeaderAttributes")
        ]

        self.assertLess(
            create_header.index("header.InitializeChild ="),
            create_header.index('header:SetAttribute("initialConfigFunction"'),
        )
        self.assertLess(
            create_header.index("for index = 1, #attributes, 2 do"),
            create_header.index('header:SetAttribute("initialConfigFunction"'),
        )

    def test_spawners_hide_the_corresponding_blizzard_frames(self):
        source = (ROOT / "Spawning.lua").read_text()
        self.assertIn("function UF:DisableBlizzardUnitFrame(unit)", source)
        for frame in ("PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame"):
            self.assertIn(f"_G.{frame}", source)
        self.assertIn('self:DisableBlizzardUnitFrame("party")', source)
        self.assertIn('self:DisableBlizzardUnitFrame("boss")', source)

    def test_native_unit_events_do_not_register_an_empty_unit_token(self):
        source = (ROOT / "Core.lua").read_text()
        self.assertNotIn('otherUnit or ""', source)
        self.assertIn("self:UpdateTags(event)", source)


class UnitFrameModuleBoundaryCoverage(unittest.TestCase):
    def test_pet_range_settings_are_read_when_frames_are_built(self):
        for filename, style_name, prefix in (
            ("PartyPets.lua", "partypet", "party"),
            ("RaidPets.lua", "raidpet", "raid"),
        ):
            source = (FRAMES / filename).read_text()
            style_start = source.index(f'HydraUI.StyleFuncs["{style_name}"]')
            build_start = source.index("UF:BuildSingleUnitFrame", style_start)
            before_style = source[:style_start]
            style_setup = source[style_start:build_start]

            self.assertNotIn(f'Settings["{prefix}-in-range"]', before_style)
            self.assertNotIn(f'Settings["{prefix}-out-of-range"]', before_style)
            self.assertIn(f'Settings["{prefix}-in-range"] / 100', style_setup)
            self.assertIn(f'Settings["{prefix}-out-of-range"] / 100', style_setup)

    def test_style_dispatch_only_calls_registered_handlers(self):
        source = (ROOT / "UnitFrames.lua").read_text()
        style = source[source.index("local Style = function"):source.index("UF.Style = Style")]
        self.assertIn("if StyleFunc then", style)
        self.assertIn("StyleFunc(self, unit)", style)
        self.assertLess(style.index('find(unit, "raidpet")'), style.index('find(unit, "raid")'))
        self.assertNotRegex(
            style,
            r'HydraUI\.StyleFuncs\["(?:raid|raidpet|partypet|party|nameplate|boss)"\]'
            r'\(self, unit\)',
        )

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
        for module in ("Elements/AuraSupport", "Elements/CastSupport",
                       "Elements/TotemSupport", "Spawning"):
            self.assertLess(manifest.index(f'file="{module}.lua"'), coordinator)

    def test_public_apis_remain_installed_on_uf(self):
        expected = {
            ELEMENTS / "Common.lua": ("CreateHealthBar", "CreatePowerBar"),
            ELEMENTS / "PortraitWidget.lua": ("CreatePortrait",),
            ELEMENTS / "Castbar.lua": ("CreateCastbar",),
            ELEMENTS / "Auras.lua": ("CreateAuraContainer",),
            ELEMENTS / "Updates.lua": ("SetHealthTexture", "SetHealthHeight", "SetHealthReverseFill"),
            ELEMENTS / "AuraSupport.lua": ("PostCreateIcon", "PostUpdateIcon", "PostCreateAuraWatchIcon"),
            ELEMENTS / "CastSupport.lua": ("PostCastStart", "PostCastStop", "PostCastFail"),
            ELEMENTS / "TotemSupport.lua": ("PostUpdateTotems",),
            ROOT / "Spawning.lua": ("SpawnSingletonFrames", "SpawnBossFrames",
                                    "BuildHeaderAttributes", "SpawnPartyHeaders",
                                    "SpawnRaidHeaders", "SpawnNameplates"),
        }
        for path, methods in expected.items():
            source = path.read_text()
            for method in methods:
                self.assertRegex(source, rf"UF[.:]{method}\b")

    def test_elements_attach_directly_without_deferred_installers(self):
        coordinator = (ROOT / "UnitFrames.lua").read_text()
        sources = "\n".join(path.read_text() for path in ELEMENTS.glob("*.lua"))
        sources += (ROOT / "Spawning.lua").read_text()

        core = (ROOT / "Core.lua").read_text()
        self.assertIn('HydraUI:NewModule("Unit Frames")', core)
        self.assertNotIn("ns.UnitFrameModule", core + coordinator + sources)
        self.assertIn('HydraUI:GetModule("Unit Frames")', coordinator)
        for path in (ELEMENTS / "Common.lua", ELEMENTS / "PortraitWidget.lua",
                     ELEMENTS / "Castbar.lua", ELEMENTS / "Auras.lua",
                     ELEMENTS / "Updates.lua", ELEMENTS / "AuraSupport.lua",
                     ELEMENTS / "CastSupport.lua", ELEMENTS / "TotemSupport.lua",
                     ROOT / "Spawning.lua"):
            self.assertIn('HydraUI:GetModule("Unit Frames")', path.read_text())
        self.assertNotIn("UnitFrameElementInstallers", sources)
        self.assertNotIn("UnitFrameComponentFactory", coordinator + sources)
        for module in ("AuraSupport", "CastSupport", "TotemSupport", "Spawning"):
            self.assertNotIn(f"ns.UnitFrame{module}(UF, Hider)", coordinator)

class UnitFrameNamespaceBoundaryCoverage(unittest.TestCase):
    def test_native_runtime_does_not_use_addon_namespace_for_storage(self):
        sources = "\n".join(path.read_text() for path in ROOT.rglob("*.lua"))
        self.assertNotRegex(sources, r"\bns\.UnitFrame[A-Za-z0-9_]*\s*=")
        self.assertNotRegex(sources, r"\bNamespace\.UnitFrame[A-Za-z0-9_]*\s*=")

    def test_runtime_state_is_owned_by_unit_frame_module(self):
        core = (ROOT / "Core.lua").read_text()
        tags = (ROOT / "Tags.lua").read_text()
        self.assertIn('local UF = HydraUI:NewModule("Unit Frames")', core)
        self.assertIn("local elementHandlers, elementNames = {}, {}", core)
        self.assertIn("function UF:RegisterElement(name, lifecycle)", core)
        self.assertIn("UF.Hider = Hider", core)
        self.assertIn("function UF.Tag(", tags)
        self.assertIn("UF.TagEvents = Events", tags)

    def test_element_lifecycle_helpers_are_centralized(self):
        core = (ROOT / "Core.lua").read_text()
        sources = "\n".join(path.read_text() for path in ROOT.rglob("*.lua"))

        self.assertIn("function UF:CreateForceUpdate(element, update)", core)
        self.assertNotIn("local function Force(element, update)", sources)
        self.assertNotIn("ElementHandlers", sources)
