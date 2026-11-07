# Validation record

## 0.2.0 — 2026-11-07

**91 tests passed** under an existing embedded Lua 5.1 runtime in a separate
headless process. All eight addon Lua sources compiled. No dependency was
installed to run these checks. Window tests simulate frame APIs; they do not
render the actual Forever UI or prove client compatibility.

Coverage includes:

- Pickup batches before departure; objective batches; nearby grouped turn-ins.
- Shared travel without double-counted quest XP, explicit shared combat sources,
  and a bound on how far one grouped stop can stretch.
- Separate mushroom/lily/spider tasks, partial progress, unmatched/localized
  objective text and incomplete quests with all known tasks done.
- Turn-in prerequisites enforced even when child quests are in the same trip.
- Timed deliveries, known log capacity, pins/skips, abandonment, changed progress,
  candidate determinism, forecast limits and state immutability.
- Whole-trip gear budgets, mode differences, known chain rewards and hysteresis.
- TomTom auto/manual modes, idempotent updates, grouped target changes, owned
  cleanup, hidden-window updates, loading/zone transitions, API failure handling,
  missing dependency, cave-label scope, instance replacement, saved auto preference
  and preservation of the manual native fallback.
- Visible movement/lock controls, minimizing/expanding, stable top-left position,
  legacy-position migration, offscreen reset, compact content, reload preferences
  and slash controls.
- Retained 0.1.0 baseline planner, gear/provider and modern/legacy API regressions.

A deterministic two-quest synthetic fixture uses less than **70% of the travel**
of separate out-and-back trips. This is a geometric regression scenario, not a
measured in-game speedup. Twenty complete Shadowglen forecasts took about
**0.14 seconds** total in this local test runtime; this is not an in-game FPS or
latency guarantee.

Manifest references, the public source privacy scan and ZIP integrity/layout
are checked by `python3 scripts/package.py`. A separate staged-file review checks
for the local username and credential-like assignments before committing.

GitHub Actions for 0.2.0 is pending branch publication. No PR to main is opened
until user playtesting is complete.

## Playtest checklist for 0.2.0 (pending)

1. Replace the 0.1.0 source with the 0.2.0 package, preserving SavedVariables.
   Confirm the tracker loads without Lua errors and existing preferences remain.
2. Drag its title, click Lock, verify it stays fixed, then click Unlock and move
   it again. Test in both expanded and compact layouts.
3. Click - to compact and + to expand. Position should remain at the same top-left
   corner, except for screen clamping. Check readability at your normal UI scale.
4. Use `/qw resetposition`. Toggle compact/lock, `/reload`, and confirm those
   preferences and the position survive. Close and reopen with `/qw`.
5. With multiple compatible quests available, confirm the first action lists
   nearby pickups before sending you away. Accept one at a time and watch the
   list update without requiring you to complete each quest separately.
6. With Webwood Venom and Iverron's Antidote both accepted, check grouped spider
   work. Verify mushroom/lily objectives disappear individually when finished.
   Check all new gathering coordinates against actual Forever spawns.
7. Complete a quest while another remains nearby. Confirm the route continues
   sensible nearby work or returns for a useful unlock, rather than automatically
   taking a separate hub trip for every quest.
8. Turn quests in individually; completed quests should disappear and follow-ups
   should become real pickup recommendations only after their prerequisites.
9. Test a skipped/pinned quest, Restore, and a quest abandoned outside the addon.
   Recommendations should reflect the actual quest log.
10. Test timed antidote delivery without optional detours. Check the warning
    against the actual Forever quest; the addon does not read a countdown.
11. Install/enable the matching TomTom version. Confirm Auto: On shows its arrow
    and distance, tracks the first outstanding grouped member and keeps working
    while the tracker is minimized or hidden. Check the cave/upstairs hints.
12. Accept/complete/skip/turn in quests. Check that the arrow updates once to the
    new target, not every second. Arriving alone must not complete a quest.
13. Set an unrelated TomTom waypoint, then toggle Auto off or leave Shadowglen.
    Confirm only QuestWeaver's marker is removed. Test loading transitions.
14. Test Auto off plus manual Waypoint, `/qw auto on|off`, saved preference across
    reload, and the status/manual fallback when TomTom is disabled. Verify that
    arrow visibility/style/scale remain under TomTom's own settings.
15. Check out-of-zone messaging, combat, event bursts, and movement near a route
    boundary. Report repeated direction reversals or perceptible stalls.

No 0.2.0 installation into the live AddOns directory, in-game rendering check,
quest run, combat test or SavedVariables persistence test has been performed
by the agent. The user reported using 0.1.0; this does not establish 0.2.0 behavior.

## Previous baseline

0.1.0 passed 30 Lua tests. GitHub Actions run 42410645167 passed syntax checks,
planner tests, privacy/package validation and artifact upload on the initial
main commit. The old planner is retained only in `tests/reference_planner.lua`
for regression comparisons and is not loaded by the 0.2.0 manifest.
