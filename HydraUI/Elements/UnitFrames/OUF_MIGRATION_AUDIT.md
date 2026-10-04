# oUF migration audit

This document is the checked-in baseline for removing HydraUI's bundled oUF
runtime. It deliberately describes only dependencies used by HydraUI layouts;
the contents of `Elements/Libraries/oUF/` are the bundled reference
implementation and are not migration consumers.

## Direct consumers

| Consumer | Dependency | Migration step |
| --- | --- | --- |
| `UnitFrames.lua` | Resolves `ns.oUF` (with the legacy global fallback) and registers the `HydraUI` style. | **1 - runtime boundary** |
| `Spawning.lua` | Resolves the same runtime; spawns singleton/boss frames, secure party/raid and pet headers, and nameplates. Its four headers supply `oUF-initialConfigFunction`. | **2 - frame creation** |
| `Tags.lua` | Resolves the runtime and writes HydraUI tag functions and event strings into `oUF.Tags.Methods` and `oUF.Tags.Events`. | **3 - tags** |
| `NamePlates.lua` | Resolves the runtime for availability, and its layout uses frame methods and elements supplied by that runtime. | **4 - elements and updates** |
| `Colors.lua` | Reads `Namespace.oUF` and replaces the runtime's class, reaction, power, debuff, tapped, disconnected, and health color tables. | **1 - runtime boundary** |
| `HydraUI_Camelot.toc`, `HydraUI_Mainline.toc` | Load `Elements\\Libraries\\oUF\\oUF_Mainline.xml`. | **5 - packaging removal** |
| `HydraUI_Mists.toc` | Loads `Elements\\Libraries\\oUF\\oUF_Mists.xml`. | **5 - packaging removal** |
| `HydraUI_TBC.toc` | Loads `Elements\\Libraries\\oUF\\oUF_TBC.xml`. | **5 - packaging removal** |
| `HydraUI_Classic.toc` | Loads `Elements\\Libraries\\oUF\\oUF_Classic.xml`. | **5 - packaging removal** |

The ordered steps are intentional: introduce one runtime boundary and color
adapter first; replace frame construction second; move tag registration third;
port the attached elements and their update protocol fourth; then remove the
per-client bundled XML entries and reference implementation.

## Frame API surface

| API | HydraUI use | Migration step |
| --- | --- | --- |
| `Spawn` | Singleton frames from the descriptor table and `boss1` through `boss5` in `Spawning.lua`. | **2** |
| `SpawnHeader` | Party, party-pet, raid, and raid-pet secure headers in `Spawning.lua`. Preserve visibility, grouping, sorting, templates, and initial configuration attributes. | **2** |
| `SpawnNamePlates` | One driver registration using `UF.NamePlateCallback` and `UF.NamePlateCVars`. | **2** |
| `Tag` | Six nameplate text regions, shared unit-frame health/power regions, and group-frame health regions. | **3** |
| `EnableElement` / `DisableElement` | Runtime toggles for Portrait, PvPIndicator, Auras, TargetIndicator, Castbar, and the configurable component helpers. | **4** |
| `UpdateAllElements` | Full refresh after singleton, configurable component, and group-frame changes; HydraUI passes `"ForceUpdate"` as the event. | **4** |
| element `ForceUpdate` | Direct refreshes of Health, Power, Buffs/Debuffs/aura containers, Castbar, Portrait, and PvPIndicator. | **4** |

`RegisterStyle` and the `Tags.Events`/`Tags.Methods` registries are also direct
dependencies even though they are setup surfaces rather than frame APIs named
in the migration acceptance criteria.

## Attached element inventory

Only elements actually attached by HydraUI layouts are listed here. Helper
regions such as text, backgrounds, anchors, and the currently commented-out
nameplate `EliteIndicator` attachment are not dependencies.

| Family | Attached elements | Migration step |
| --- | --- | --- |
| Core bars | `Health`, `Power`; health prediction through `HealBar` and (on mainline) `AbsorbsBar`. | **4a - core state** |
| Presentation and range | `Portrait`, `Range`, `ThreatIndicator`, `RaidTargetIndicator`. | **4b - presentation** |
| Auras | `Buffs`, `Debuffs`, `AuraWatch`, `Dispel`. (`Auras` is the runtime toggle covering Buffs/Debuffs.) | **4c - aura state** |
| Casting and nameplates | `Castbar`, `TargetIndicator`. `EliteIndicator` is constructed but not attached, so it is explicitly excluded. | **4d - casting/nameplates** |
| Player resources | `ComboPoints`, `Runes`, `ClassPower` (aliased by the layout as `Chi`, `Essence`, `SoulShards`, `ArcaneCharges`, and `HolyPower`), `Totems`, and monk `Stagger`. | **4e - player resources** |
| Power timing/prediction | `PowerPrediction`, `ManaTimer`, `EnergyTick`. | **4f - power timing** |
| Player state indicators | `CombatIndicator`, `PvPIndicator`, `LeaderIndicator`, `ResurrectIndicator`. | **4g - player indicators** |
| Group indicators | `GroupRoleIndicator`, `AssistantIndicator`, `ReadyCheckIndicator`, `PhaseIndicator`, plus group uses of `LeaderIndicator`, `ResurrectIndicator`, and `RaidTargetIndicator`. | **4h - group indicators** |

## Regression policy

`tests/test_ouf_migration_boundary.py` scans runtime Lua/XML/TOC files outside
`Elements/Libraries/oUF/`. Its allowlist is the current migration debt, including
the harmless existing credit label. Any added `ns.oUF`/`Namespace.oUF` access,
bare or global `oUF` reference (and therefore any `oUF:` call), or `oUF-`
attribute changes the snapshot and fails the test. Removing a dependency also
fails until this audit and its snapshot are deliberately updated together.
