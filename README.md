# QuestWeaver

An adaptive quest planner for **WoW Forever**, starting with a 12-quest
**Shadowglen** pack in the Night Elf starting area. Version 0.1.0 is an alpha;
it has not been tested inside the game.

## Install

1. Unzip the release. Copy its single `QuestWeaver` folder into your **Forever**
   client's `Interface/AddOns` directory. The result must contain
   `QuestWeaver/QuestWeaver.toc` directly.
2. Enable QuestWeaver in the character selection AddOns list. The manifest
   targets Interface 16001; confirm the interface version with `GetBuildInfo()`
   if the client has updated.
3. Enter Shadowglen and type `/qw`. The panel becomes active within the starter
   area of Teldrassil. Other zones intentionally show an out-of-scope message.

No dependency is required. **QuestieDB** is optional for current quest names,
requirements, prerequisites and giver positions. **TomTom** is optional for a
waypoint arrow. When available, the built-in waypoint API is the fallback;
otherwise coordinates are printed to chat. A waypoint is set only on request.
QuestieDB should be the matching Forever package. It is not bundled.

## What it does

- Replans from your current position, level, accepted quests, objective counts,
  completed quests, equipment, and preferences.
- Produces up to 12 actions: pickup, objectives, turn-in, then newly unlocked
  quests. Only the first action is current; subsequent actions are projections
  assuming the preceding actions are completed.
- Scores estimated quest XP per minute through the turn-in, with bounded
  preference for overlapping accepted objectives and quests unlocking a chain.
- Looks up to three simple prerequisite links ahead for learned gear rewards,
  including the estimated future work in the gear allowance calculation.
- Offers **Balanced** (default), **Fastest XP**, and **Gear focused** modes.
- Allows a 0-30 minute gear allowance, default 10. It compares estimated time to
  reward against the fastest current candidate; this is a local heuristic, not
  a guarantee about the total route's detour or globally fastest leveling.
- Explains each step and permits pinning/skipping. Failed quests are excluded.

## Gear advice

Rewards are learned when you open a quest's offer/reward window. The addon
stores only reward item IDs, observed quest XP and the level of that observation.
It recalculates a basic **stat score** against your currently equipped gear using
the selected role profile. Cached XP is used only at the same character level.
For unknown rewards it explicitly says the gear is not yet known. Early quests
can therefore have no gear-aware routing until their rewards have been seen.

An improvement of at least 10% in this simple score may receive a bounded
priority bonus within your detour allowance. This percentage is **not** a DPS,
healing or survival increase. Default profiles are rough leveling weights;
choose your profile explicitly, especially for hybrid classes. Effects, procs,
set bonuses, weapon damage/speed, dual-wield loadouts and custom Forever stats
are not modeled. Weapon swaps that require replacing a two-handed loadout with
one-handed items are left unscored. There is no Pawn integration in this alpha.
No rewards are chosen or items equipped automatically.

## Commands

| Command | Action |
| --- | --- |
| `/qw` or `/qw show` | Open the planner |
| `/qw hide` | Close it |
| `/qw mode balanced` | Favor XP with bounded gear detours |
| `/qw mode xp` | Use XP/time scoring without gear bonuses |
| `/qw mode gear` | Stronger gear preference within the allowance |
| `/qw profile melee` | Set melee weights |
| `/qw profile ranged` | Set ranged weights |
| `/qw profile caster` | Set caster weights |
| `/qw profile healer` | Set healer weights |
| `/qw profile tank` | Set tank weights |
| `/qw budget 10` | Set gear allowance in minutes (0-30) |
| `/qw pin 916` | Prioritize this quest when eligible |
| `/qw unpin` | Clear the pin |
| `/qw skip 916` | Stop recommending this quest; does not abandon it |
| `/qw unskip 916` | Restore this quest |
| `/qw restore` | Clear all skips and the pin |
| `/qw way` | Place a waypoint for the current next action |
| `/qw unlock` / `/qw lock` | Enable/disable title-bar dragging |

Skip/pin without an ID applies to the next recommended quest. The panel also
has mode, waypoint, skip-next and restore buttons. Preferences and position
are SavedVariables **per character**; no character/account names are recorded
by the addon. WoW itself stores per-character files in its own directories.
Nothing is sent over the network.

## Scope and uncertainty

- The pack is an original approximation of the Classic Shadowglen starter
  chains. It is **not a verified Forever route**. Added/changed Forever quests
  and class quests are outside this first pack. A missing recommendation does
  not prove no quest is available.
- QuestieDB can replace names, prerequisites and giver positions, but objective
  locations, XP baselines and timings remain starter estimates. No quest or
  route dataset is copied or shipped from another addon.
- Travel is scaled geometric distance with a conservative multiplier. It does
  not understand mountains, cave entrances, buildings, transport or walkable
  terrain. Cave and upstairs steps have warnings. The addon never moves you.
- Objective groups are treated as one area per quest; multiple distant
  objectives are not separately routed. Kill XP, rested XP, spawn competition,
  drop rates and your personal combat pace are not yet modeled.
- Time-to-reward is recomputed for each action; summing the displayed estimates
  would double-count future quest work. Treat them as per-candidate estimates.
- The manifest/API choices need actual Forever-client validation, including
  startup, cold login, reload, combat, quest updates and SavedVariables.
- The planner refreshes at most once per second while visible or after an
  event. It does not change the normal quest tracker, bindings or CVars.

## Development and validation

From the repository root, using Lua 5.1 (or LuaJIT):

```sh
lua tests/run.lua
python3 scripts/package.py
```

The package script validates manifest references, scans the publishable file
set for common private information, and creates `dist/QuestWeaver-0.1.0.zip`
with one addon folder at its root. Source code, tests, docs, workflow and build
script belong in Git; generated ZIPs, saves and local settings do not.

See [VALIDATION.md](VALIDATION.md) for actual checks performed and a playtest
checklist. See [SOURCES.md](SOURCES.md) for research references.
