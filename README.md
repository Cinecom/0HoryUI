# HoryUI

A lightweight, premium-minimal combat HUD for **World of Warcraft 1.12 (vanilla / Turtle WoW)**, built specifically for the **Rogue** class. Calm out of combat, instantly readable in combat — flat 1px borders, near-black panels, one deep Horde-red accent ("Garnet").

## Requirements

| | |
|---|---|
| **Game client** | WoW 1.12.x (interface `11200`) |
| **Required** | [Nampower](https://github.com/pepopo978/nampower) **3.0.0+** — fast unit-field reads and cast events. HoryUI warns and degrades if it's missing. |
| **Recommended** | **SuperWoW** (unified cast events, mouseover, spell info) and **UnitXP_SP3** (distance / line-of-sight). Both are optional and feature-gated. |

## Features

- **Unit frames** — player + target + target-of-target: 2D portraits, health/power, class/reaction-coloured names, difficulty-coloured level, out-of-combat fade.
- **Rogue energy bar** with a sweeping tick line, and **combo points** (1–5 pips, green→red, finisher glow).
- **Castbars** — player + enemy (enemy casts tracked by GUID for interrupt timing).
- **Auras** — player buffs (timers + right-click cancel) and target buffs/debuffs with real time-left from cast events.
- **Range tracker**, **party/raid frames**, **weapon-poison** icons.
- **Chat** rework — persistent history, movable panel, URL copy, class-coloured names/tabs, timestamps.
- **Square minimap** with an addon-button tray, **XP/rep bar**, native **Character** and one-bag **Bags** rebuilds.
- A vendored standalone **pfUI skin engine** (`pfskin/`) for Blizzard window skins + nameplates, dormant while real pfUI is installed.

## Install

1. Copy the `HoryUI` folder into `Interface/AddOns/`.
2. Restart the client (the `.toc` is only scanned at launch).
3. Type `/hui` in-game to open settings; unlock to reposition panels.

## License

Personal project. The `pfskin/` directory is a vendored, renamed copy of [pfUI](https://github.com/shagu/pfUI)'s skin subsystem (MIT) so the skins run standalone.
