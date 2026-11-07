# QuestWeaver

An adaptive quest planner for **WoW Forever**, starting with a 12-quest
**Shadowglen** pack. **0.2.0** is a test build awaiting in-game acceptance.

## Install or update

1. Extract `QuestWeaver-0.2.0.zip`. Its single `QuestWeaver` folder belongs in
   the Forever client's `Interface/AddOns` directory. Check that
   `QuestWeaver/QuestWeaver.toc` exists directly, without another nested folder.
2. When updating, replace the old addon source folder. Keep your game-managed
   SavedVariables; skips, reward observations and preferences are migrated.
3. Enable QuestWeaver and enter Shadowglen. Type `/qw` to show the tracker.
   Use `/reload` if the addon is already enabled and its source was updated.
   A newly installed addon may require returning to character selection.

The manifest targets Interface 16001. Recheck `GetBuildInfo()` after client
updates. No game restart, live installation or in-game test was performed as
part of producing the 0.2.0 package.

No dependency is required. Optional **QuestieDB** supplies quest names,
requirements, prerequisites and giver positions; use its matching Forever
package. Optional **TomTom** supplies waypoints. Otherwise QuestWeaver tries the
built-in waypoint API and finally prints coordinates. Waypoints act only when
requested. Third-party addons and databases are not bundled.

## Window controls

- **Drag the title bar** to move the window. Movement is enabled by default.
- **Lock / Unlock** controls title dragging in either layout.
- **- / +** minimizes to the next action or expands the full trip plan.
- **Waypoint** targets the first outstanding destination in the current action.
- **x** hides the window; `/qw` brings it back in its saved layout.
- `/qw resetposition` recenters an offscreen window.

Position, compact/expanded state and lock preference survive reloads through
per-character SavedVariables. Legacy 0.1.0 pixel positions are accepted, then
saved as normalized coordinates when moved or the layout is toggled. Both
layouts remain clamped to the screen.

Compact mode shows only the current action, its member quests/objectives,
available live progress, destination and waypoint control. Expand to see all
members when a stop contains more than three. Unknown progress says **check
quest log**, rather than pretending an unmatched objective is complete.

## How trips work

The planner evaluates complete trips through currently eligible quests:

1. **Collect compatible quests** at the hub before leaving when combining them
   improves estimated quest XP per minute.
2. **Work objective areas together**, including individual gathering areas.
3. **Return and turn in** nearby completed quests together when the route fits.

Each modeled leg contributes travel once. Combat work is reduced only when
pack tasks explicitly identify the same creature source. Being near another
quest does not by itself reduce the estimated kills or gathering work.

A bounded greedy search starts with each eligible quest and tests inserting
up to three others, for at most four quests per trip. It forecasts up to three
trips and 24 displayed actions. Follow-up quests may be inserted in the same trip, but their pickups stay
blocked until the required projected turn-ins. The first instruction reflects current state; the rest assumes you
perform the preceding work. Replanning follows real accepts, progress,
turn-ins, skips, equipment changes and movement.

The expanded view shows the current trip, its total estimated time/quest XP,
and subsequent projected trips. Adjacent pickups, objective work and returns
are grouped. A grouped waypoint points at the first member; accepting or
completing that member lets the next refresh advance to the next destination.

Useful exceptions:

- A nearby turn-in can happen early instead of forcing a complete hub loop.
- The starter pack's timed antidote delivery, once accepted, takes priority
  over elective detours and pins. Its timer is not read; the warning is based
  on the pack's unverified timed-quest flag.
- Quest-log capacity is respected when the client supplies its maximum. The
  planner conservatively requires room for planned pickups up front.
- Previous trips are retained within 15% of the best priority, and small
  destination changes receive hysteresis to avoid repeated direction changes.
- **Skip first quest** removes only the first quest of a grouped action from
  recommendations. It never abandons quests. Restore clears skips and pins.

## XP and gear modes

| Mode | Priority |
| --- | --- |
| Balanced (default) | Estimated quest XP/time with bounded gear preference |
| Fastest XP | Estimated quest XP/time without gear bonuses |
| Gear focused | Stronger gear preference within the same allowance |

Rewards are learned when their offer/reward window is opened. Unknown rewards
remain unknown. Known rewards are compared to current equipment using rough
melee, ranged, caster, healer or tank stat weights. Choose a profile explicitly
for your leveling role, especially on hybrid classes.

A known stat-score improvement of at least 10% may favor a trip if its estimated
extra time fits your allowance (default 10 minutes, range 0-30). The comparison
uses the **whole candidate trip**, plus estimated future work for a known reward
up to three simple prerequisite links ahead. The comparator is the best current
XP/time trip, which may contain a different set of quests. This is a local
heuristic, not a guarantee of total route detour or globally optimal leveling.
Pins override elective scoring but never prerequisites, skips or accepted timed
quests. The addon never chooses rewards or equips gear for you.

The gear percentage is a basic **stat-score** change, not a DPS/healing/survival
prediction. Weapon damage/speed, procs, set bonuses, custom Forever stats and
complete dual-wield loadouts are not modeled. Replacing a two-handed loadout
with one-handed items remains unscored. There is no Pawn integration.

## Commands

| Command | Action |
| --- | --- |
| `/qw` or `/qw show` | Show the tracker in its saved layout |
| `/qw hide` | Hide it |
| `/qw minimize` or `/qw compact` | Show the next action only |
| `/qw expand` | Show the full trip plan |
| `/qw lock` / `/qw unlock` | Disable/enable title dragging |
| `/qw resetposition` | Recenter the window |
| `/qw way` | Set a waypoint for the current destination |
| `/qw mode balanced` / `xp` / `gear` | Set routing mode |
| `/qw profile melee` / `ranged` / `caster` / `healer` / `tank` | Set stat weights |
| `/qw budget 10` | Set gear allowance in minutes |
| `/qw pin 916` | Prioritize an eligible quest |
| `/qw unpin` | Clear the pin |
| `/qw skip 916` / `/qw unskip 916` | Exclude/restore a quest |
| `/qw restore` | Clear skips and pin |

Pin/skip/unskip without an ID uses the first quest of the next action. Expanded
steps include IDs to support targeting a different member.

## Limits and data quality

- The pack covers a subset of Shadowglen's Classic starter chains, not all
  Forever additions or class quests. It does not infer availability of quests
  outside the pack. The panel is scoped to Shadowglen, not all Teldrassil.
- Starter objective coordinates, XP baselines and work times are **unverified
  estimates**. QuestieDB can replace selected metadata and giver positions,
  but not these objective areas. No paid routes or third-party datasets are
  copied or redistributed.
- Travel uses scaled geometric distance and a conservative multiplier. It does
  not understand walkable terrain, transport, building floors or cave paths.
  Cave/upstairs warnings remain visible in the expanded view.
- Mushroom/lily/spider task matching currently uses English objective tokens.
  Unmatched/localized data stays unresolved until the client confirms quest
  completion. If all known tasks are done but the client says incomplete, the
  tracker asks you to check remaining requirements instead of claiming a turn-in.
- XP is credited once per quest in the trip estimate. Kill XP, rested bonuses,
  spawn competition, measured drop rates and personal combat pace are not
  modeled. A same-level XP observation from the quest window replaces the
  fallback estimate; changed buffs may still make that observation stale.
- UI refresh/planning runs at most once a second while shown or after events.
  No bindings, CVars, normal quest tracker, automatic quest accepts or movement
  are changed.
- Settings, quest IDs and reward IDs/XP stay in per-character SavedVariables.
  The addon records no character/account names and sends nothing over a network.

## Development and review

```sh
lua tests/run.lua
python3 scripts/package.py
```

Lua 5.1/LuaJIT is required for the test suite. Tests cover planner and runtime
logic plus simulated window behavior; UI stubs are not actual game rendering.
The frozen 0.1.0 planner lives only in `tests/reference_planner.lua` for baseline
regressions and is not shipped in the addon.

The package script checks the public source set, privacy signatures, manifest
references and single-folder ZIP integrity, producing `dist/QuestWeaver-0.2.0.zip`.
GitHub Actions repeats Lua syntax checks, tests and packaging when the branch is
pushed. Generated packages, logs, local settings and game saves are ignored.

0.2.0 is developed on a feature branch. It is ready for user playtesting before
opening a PR to `main`. See [VALIDATION.md](VALIDATION.md) for the test record and
playtest checklist, [CHANGELOG.md](CHANGELOG.md) for changes and
[SOURCES.md](SOURCES.md) for research boundaries.
