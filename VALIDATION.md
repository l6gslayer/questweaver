# Validation record

Version 0.1.0, 2026-11-07.

## Automated and package checks

- Lua planner/adapter regression suite: **30 tests passed** using an existing
  embedded Lua 5.1 runtime in a separate headless process. No standalone Lua
  command was available; no dependencies were installed to run these checks.
- All six addon Lua files compiled successfully under that Lua 5.1 runtime.
- Manifest references, privacy scan and ZIP integrity/layout: run with
  `python3 scripts/package.py`; the release package is created only if these pass.
- GitHub Actions workflow: prepared for Lua 5.1 tests and packaging; not run
  until the repository is published and a workflow run completes.

The regression run caught and fixed an action-target fallback that could point
a pickup at an objective when its giver coordinate was absent. These are mocked
logic/adapter tests, not a test of game rendering or actual client APIs.

## In-game acceptance checklist (all pending)

- Cold login and `/reload` load without Lua errors on the current Forever build.
- The window is readable at normal UI scale, scrolls and remembers its position.
- Out-of-zone and out-of-pack messages suppress invalid routing.
- At level 1, available pickups match actual Shadowglen quest givers.
- Each objective's progress updates; finishing changes DO to TURN IN.
- Turning in updates prerequisites and unlocks the correct next quest.
- Skipping, restoring, pinning and abandoning a quest produce sensible plans.
- Confirm all 12 starter IDs, locations, levels, XP rewards and chain edges.
- Check cave entrance/ramp warnings and replace inaccurate target coordinates.
- Opening quest offer/reward windows captures actual XP/reward IDs.
- Cached/missing item data never shows an invented upgrade.
- Role profiles, level restrictions, armor usability and weapon-loadout handling
  do not recommend unusable items.
- Waypoint button works with/without TomTom and only acts when requested.
- Combat and item/quest event bursts do not cause errors or noticeable stalls.
- Settings survive logout/login; separate characters do not share skips/pins.

No successful game installation, client startup, quest run, combat test or
SavedVariables persistence test is claimed by this record.
