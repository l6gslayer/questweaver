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

### Installation and initial user playtest — 2026-11-07

The existing 0.2.0 package, including Navigation.lua, was installed into the
Forever addon folder after a verified full backup of the previous addon.
All 14 installed release files were byte-compared with the ZIP successfully,
including a subsequent readback. SavedVariables and other addons were untouched.
The agent did not restart the game or run an in-game reload command.

The user subsequently reported that the build is working. Their screenshot
shows the compact tracker, Auto: On, a ready navigation status and a TomTom
arrow for The Balance of Nature. A subsequent filesystem inspection found
TomTom v4.4.1-release with Interface 16001 among its declared targets. This
establishes initial user-reported operation and visible rendering, not completion
of the checklist above. Persistence, cleanup, combat and full quest progression
remain unverified.

The screenshot also exposes an outstanding objective-waypoint accuracy issue:
the tracker targets 57.9, 41.2 while Mangy Nightsabers remain and the other mob
objective is complete. Source inspection confirms quest 457 has one fixed,
unverified objective point and no per-mob tasks. The planner therefore retains
the same point regardless of which mob objective remains. Navigation passes
that point directly to TomTom. QuestieDB integration currently updates quest
givers/metadata, not objective spawn locations. A corrected spawn area needs
Forever evidence; no replacement coordinate has been inferred from the player's
position or the quest-area marker. Gameplay code and package remain unchanged
by this documentation update.

## Previous baseline

0.1.0 passed 30 Lua tests. GitHub Actions run 42410645167 passed syntax checks,
planner tests, privacy/package validation and artifact upload on the initial
main commit. The old planner is retained only in `tests/reference_planner.lua`
for regression comparisons and is not loaded by the 0.2.0 manifest.

## 0.2.0 current quest destinations — 2026-11-07

**100 tests passed** under the existing embedded Lua 5.1 runtime, including
compilation of all eight addon sources. Nine new cases cover waypoint priority,
map-specific coordinate spaces, quest-area fallback, absent/failing APIs,
invalid/foreign coordinates, live destination changes reaching navigation,
no duplicate gathering pins or seed mutation, completed return points, fallback
estimates, and snapshot refresh/map-query count. Existing planner, UI and
navigation ownership regressions also pass.

The implementation now reads current quest locations through guarded optional
APIs rather than substituting guessed spawn coordinates. It labels live points
and estimates in the tracker. The earlier waypoint investigation above describes
the previous package. This updated build still requires a Forever playtest:
reload, check The Balance of Nature against the blue area, confirm a live source
label, then finish an objective and check the destination refresh. If it says
starter estimate, the client did not expose valid location data via these reads.
Test completion/return and a multi-objective gathering quest too. A quest-area
point is not an individual mob spawn or an objective-indexed location.

## 0.2.0 nearby quests and item-start discovery — 2026-11-07

**125 tests passed** under the existing embedded Lua 5.1 runtime, with all eight
addon sources compiled. New regressions cover modern/legacy bag discovery,
known item fallback, accepted/active/completed suppression, uncached/missing
APIs, bounded carried-bag scans, bag removal, log XP/title/level reads, Fang's
loot/accept/return stages, shared egg outing and Aldrassil returns, full-log
reminders, local/remote filtering, seed deduplication, missing return/XP/gear,
no fake completion/unlocks, discovered pinning, manual-only acceptance without
waypoints, compact/expanded rendering, and prerequisite-safe shortlisting.
A synthetic 40-local-quest plan took about 0.03 seconds in the test runtime,
not an in-game timing guarantee. Existing navigation ownership tests remain.

Playtest pending: after reload, inspect an unaccepted Fang in bags (if still
available), manually accept it, then confirm it joins the Aldrassil return.
With Webwood Egg active, check the optional Githyiss loot opportunity; if already
turned in, Fang should stay absent. Test another nearby accepted quest outside
the authored pack, a detected item-start quest, bag item removal, full-log
reminder, skip/pin and progression to its live return. Remote/unlocated quests
must not gain fabricated local waypoints. Unlocated starters should explain
that the bag item needs manual inspection. No full catalogue of unseen drops
is implied. New discovery/API behavior requires actual Forever validation.

## 0.2.0 nearby ready returns and coverage audit — 2026-11-07

**142 tests passed** under the existing embedded Lua 5.1 runtime; all eight Lua
addon sources compiled. The 17 new tests cover a nearby completed Fang versus
farther high-value/pinned/previous plans, grouped actual returns, timed delivery
precedence, movement across the near radius, no completion inferred from
proximity/objective rows, failed/skipped/done exclusions, freed quest-log slots,
discovered return coordinates, deterministic four-return bounds, offer-only
pickups, live Nature's Call area and completion, missing-location notices,
Night Elf/all-class gating, owned-only voucher behavior, readiness fallback,
and clearing offers after a conversation closes.

Source inspection shows the planner already samples current position; the
reproduced fault was missing nearby-ready-return priority in trip selection.
The user report does not establish which readiness API values the live client
returned. The new guarded ReadyForTurnIn read addresses that additional boundary
without assuming that item acceptance or proximity completes a quest.

Playtest pending: reload beside Gilshalan with Fang accepted and ready, and
confirm TURN IN precedes a farther pickup. Turn it in, move away, and confirm
planning resumes from your current position. Check another ready local return,
open Tarindrella/Shanda's conversation for newly offered quests, manually accept,
and verify live objectives/returns. A voucher must never create an unowned loot
suggestion. Class introductions remain accepted-discovery coverage; outbound
Dolanaar trips remain separate. No new in-game or persistence test is claimed.

## 0.2.0 class introductions and Dolanaar handoffs — 2026-11-07

**149 tests passed** under the existing embedded Lua 5.1 runtime; all eight addon
Lua files compiled. Seven new cases cover each class/race/offer gate, accepted
trainer routes and completion, Crown handoff prerequisite order, shared delivery
travel with pickup precedence, full-log handoff constraints, dynamic quest/live
return discovery in Dolanaar, and a simulated runtime/TomTom transition beyond
the old Shadowglen bound with cleanup outside the new supported corridor.
Existing nearby-return/timed priority and ownership tests still pass.

Playtest pending: talk to Ilthalaine with the appropriate Night Elf class and
confirm only its offered sigil is recommended; accept/read manually, then check
the correct trainer. After Crown 921, take 928 and/or Dolanaar Delivery; verify
pickup/return destinations, shared trip logic, and arrow refresh on the road
and inside Dolanaar. Accept a local Dolanaar quest and check dynamic discovery.
Return priority beside recipients should still work. This is not a complete
Dolanaar quest pack, and all fallback positions/work/XP need Forever checking.
No in-game playtest or automated character action was performed by the agent.
