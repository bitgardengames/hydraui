# HydraUI

HydraUI is a complete interface replacement for World of Warcraft. It provides a consistent visual style for action bars, unit frames, chat, the minimap, tooltips, and other common interface elements.

## Project layout

| Path | Purpose |
| --- | --- |
| `HydraUI/Elements/` | HydraUI features, shared tools, defaults, and initialization code. |
| `HydraUI/Elements/ActionBars/` | Action bars, key bindings, the micro menu, and bag slots. |
| `HydraUI/Elements/Chat/` | Chat windows, history, links, and frame behavior. |
| `HydraUI/Elements/DataTexts/` | Small status displays such as durability, gold, latency, and time. |
| `HydraUI/Elements/GUI/` | Settings-window controls and navigation. |
| `HydraUI/Elements/Languages/` | Translations for supported locales. English text is used as each translation key and as the fallback. |
| `HydraUI/Elements/UnitFrames/` | Player, target, party, raid, boss, pet, and nameplate frames. |
| `HydraUI/Elements/Libraries/` | Third-party libraries. Keep these files unchanged when making project-wide style updates. |
| `tests/` | Python contract tests for critical Lua behavior. |
| `HydraUI/HydraUI_*.toc` | Add-on manifests for each supported game client. |

## Development

1. Clone the repository into the game's `Interface/AddOns` directory.
2. Select the manifest that matches the client you want to test.
3. Launch the game and enable HydraUI from the add-on list.
4. Open the settings window with `/hui`.

Run the contract tests from the repository root:

```sh
pytest -q
```

## Writing conventions

User-facing text should be brief, direct, and consistent:

- Use title case for labels and sentence case for descriptions.
- Prefer active instructions such as “Set the width” or “Display the tooltip.”
- Use **add-on**, **minimap**, **nameplate**, and **PvP** consistently.
- Use **hover** for pointer interactions and reserve **mouseover** for option labels or game API terminology.
- Write plural possessives and contractions correctly; do not use apostrophes to form plurals.
- End questions with a question mark. Descriptions generally do not need a period.

English phrases also serve as localization keys. When changing one, update the matching key in every file under `HydraUI/Elements/Languages/` so existing translations remain connected.

## Code conventions

- Use tabs for Lua indentation and spaces around operators and argument separators.
- Write control-flow conditions directly; unlike function calls, they do not need parentheses.
- Keep one statement per line. Expand conditionals and functions across multiple lines instead of compressing them.
- Give local values descriptive names, especially when a callback receives several related objects.
- Separate setup phases with blank lines so frame construction and update paths can be scanned quickly.
- Keep third-party code under `HydraUI/Elements/Libraries/` unchanged.

## License

HydraUI is distributed under the terms in [`HydraUI/All Rights Reserved.txt`](HydraUI/All%20Rights%20Reserved.txt).
