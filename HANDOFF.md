# QuestWeaver handoff

Updated 2026-11-07. Read this alongside `AGENTS.md`, `README.md` and
`VALIDATION.md`. Machine-specific installation details are deliberately kept
in the parent workspace's local instructions, not this public repository.

## Goal and current state

Build an adaptive quest planner for WoW Forever, beginning with Shadowglen.
The user requested efficient XP, worthwhile gear, multiple quests per outing,
an easily movable/minimizable tracker, and TomTom direction-arrow guidance.

- Active branch: `feature/0.2.0-trip-planning`.
- Main/base: `f343cf4` (published 0.1.0 alpha).
- Trip-planning/UI implementation: `1966290`.
- Latest addon implementation: current feature-branch multi-stop pickup/confirmed-offer follow-up
  (extends `18e628d` automatic TomTom integration).
- Version remains **0.2.0**, a test build, not a merged release.
- Public remote: `https://github.com/l6gslayer/questweaver`.
- Source: nested `QuestWeaver/` directory; nine Lua files plus its manifest.
- Installable artifact: `dist/QuestWeaver-0.2.0.zip`, one addon folder at root.
- Settings: `QuestWeaverDB`, per-character SavedVariables, schema 3.

The user wants to **playtest before a PR to main**. No PR is open; do not merge
or delete the feature branch without an explicit request. The last branch push
attempt failed DNS in the previous agent session. Inspect current remote state
before claiming publication; preserve generic commit author/committer metadata.

## Implemented behavior

- `Core.lua`: shared copy, distance, travel and eligibility helpers.
- `Trips.lua`: bounded whole-trip scoring; at most four quests per trip and
  three projected trips/24 displayed actions. Groups nearby pickups, objective
  work and returns; follow-ups may join the same trip only after their required
  projected turn-ins. Shared travel counts once; combat savings require explicit
  shared-source metadata. Handles known log capacity, timed delivery, pin/skip,
  partial progress, gear-chain lookahead and modest route hysteresis.
- `Shadowglen.lua`: 23 entries, including conditional NPC-offer/voucher quests; separate mushroom/lily/spider tasks for
  Iverron's Antidote, conservative English-token progress matching, and relevant
  cave/upstairs/timed-delivery hints.
- `Provider.lua` / `Gear.lua`: optional QuestieDB metadata and learned reward
  stat comparisons. Unknown rewards remain unknown. Gear scores are rough stat
  weights, not DPS predictions. No Pawn integration.
- `Runtime.lua`: quest snapshots, guarded APIs/events, one-second updates,
  SavedVariables migration, slash commands and navigation lifecycle.
- `UI.lua`: title dragging enabled by default, visible Lock/Unlock and -/+
  controls, compact current-action view, expanded trip list, normalized saved
  position, reset-position command, waypoint and Auto controls in both layouts.
- `Navigation.lua`: optional TomTom integration. Auto defaults on when available;
  creates one temporary/silent owned waypoint with arrow selection, advances as
  the planner's first outstanding destination changes, and works while the
  tracker is hidden. Reaching coordinates does not complete quests. Removes
  only its owned point on route end, leaving the area, loading or Auto off.
  Does not modify TomTom's profile or remove unrelated points. A manually selected
  arrow is left alone while the quest destination is unchanged; Waypoint reselects
  QuestWeaver's arrow. Native pin/chat fallback remains manual.

Useful commands: `/qw`, `/qw minimize`, `/qw expand`, `/qw lock`, `/qw unlock`,
`/qw resetposition`, `/qw auto on`, `/qw auto off`, `/qw way`. See README for
profiles, modes, gear budgets, pins and skips.

## Verification and important limits

- **239 tests passed** under an existing embedded Lua 5.1 runtime; all nine
  addon Lua sources compiled. Tests include planner, provider/gear, runtime,
  simulated window behavior and TomTom API spies/failure handling.
- Package integrity, single-folder layout, manifest references and two public
  source privacy checks passed for the TomTom build.
- Initial 0.1.0 main GitHub Actions run `42410645167` passed. Feature-build CI
  has not been verified; do not describe local tests as GitHub Actions results.
- The user reported using the addon and said it was looking good. This is
  informal user feedback, not a recorded verification of all features.
- **TomTom integration has not been tested in the live client.** No TomTom
  dependency installation was performed by the agent. Check availability first;
  do not silently install/alter third-party addons.
- Quest coordinates, XP/work estimates, static timed flags and geometric travel
  remain unverified Forever baselines. No terrain pathfinding, measured kill XP,
  rested XP, spawn competition or personal pace learning is implemented.
- English task tokens may not match localized/changed objective text. Unknown
  tasks remain unresolved and ask the player to check the quest log.
- TomTom's official current release listing includes Forever; the implementation
  contract was inspected in historical authored documentation/source mirrored on
  GitHub. Exact current-version compatibility is unverified; see SOURCES.md.
- Mocked frame tests are not screenshots or proof of actual in-game layout.

## Current follow-up — installation complete, waypoint investigation

The authorized 0.2.0 installation completed on 2026-11-07 after a verified
backup; all 14 release files matched the ZIP. The user reports it is working,
and supplied a screenshot showing the compact tracker and TomTom guidance.
TomTom v4.4.1-release was subsequently found installed. See VALIDATION.md for
evidence boundaries. The installation instructions below are historical context.

The objective-location follow-up is implemented: Runtime reads optional WoW
next-waypoint, map-specific waypoint and matching quest map points; Provider
uses the current live quest stage for accepted quests and live return points
when complete. Static gathering tasks remain the fallback when live data is
missing. UI labels live objectives/areas versus starter estimates. No new
coordinates were guessed from screenshots. All 100 Lua 5.1 tests passed.
The rebuilt 0.2.0 needs user playtesting against the blue quest area; API data
availability/accuracy is still unverified in Forever. See README and VALIDATION.
No PR, merge or push is authorized.

## Nearby quest and item-start follow-up

Fang of Githyiss is now a known cave-drop opportunity (quest 97236/item 277190),
a manual bag-acceptance action, and an Aldrassil delivery once accepted. Runtime
reads carried-bag starters and accepted quest titles/levels/current XP. Provider
adds local accepted quests and local item starters outside the pack. Unlocated
items remain reminders; unknown returns stay current-stage-only without fake
completion or chain unlocks. QuestieDB can supply local return metadata; unknown
gear stays unscored and unknown XP/work remain labeled estimates. Whole-trip
insertion shortlists at most sixteen candidates with prerequisite closure.
See README for exact evidence/fallback boundaries and VALIDATION for the new
125-test result and user checklist. The rebuilt package was installed after a verified backup; all fourteen release
files matched the ZIP. In-game discovery remains unverified;
no PR, merge or push is authorized. Preserve the feature branch and main.

## Shadowglen audit and nearby return follow-up

The user reported accepted Fang being skipped for a farther pickup while beside
the recipient. Current-position sampling already existed; trip selection now
prioritizes observed ready nearby returns before elective departures, pins and
hysteresis, retaining accepted timed delivery precedence. Runtime reads optional
ReadyForTurnIn with completion fallback; proximity alone never proves readiness.

Added Nature's Call 97977 and The Goddess Provides 97979 with actual open-NPC
quest-offer/accepted evidence and live objective positions. Welcome! 5842 uses
owned voucher 14648 or accepted evidence only. The pack now has sixteen entries.
Class intro pickups and outbound Dolanaar trips are recorded scope gaps; no
additional ordinary drop quest was substantiated by this bounded audit. See
SOURCES.md for the evidence table and uncertainty. All 142 tests passed; actual
Forever priority/readiness/new-offer behavior remains pending user playtesting.
No PR, merge or push is authorized. Keep the feature branch and main unchanged.

## Class introductions and Dolanaar extension

The user explicitly requested and authorized this 0.2.0 update/install. Five
class introductions 3116–3120 now have matching class/race and actual-offer
pickup gates, with accepted routes to individual trainers. Crown 928 follows
921, and Dolanaar Delivery 2159 can share the trip south. They use NPC-provided
items, not item-started quest modeling. Live locations/XP override estimates.

Pack bounds now cover map 1438, x 50–65%, y 23–65%; Runtime and discovery use
Core.IsLocal consistently so guidance remains active along the road/at Dolanaar.
This does not author every Dolanaar quest; accepted corridor quests can join.
149 tests passed, including simulated extended-area navigation. Actual Forever
class gates, destinations, road routing and Dolanaar behavior need playtesting.
Stay on feature/0.2.0-trip-planning. No PR, merge or push is authorized.

## Shared-return batching correction

The user confirmed Moss and Nature's Call were both accepted. Investigation
reproduced solo-XP/minute selection rejecting the companion and greedy ordering
returning between the two objectives even in a forced combined trip. Trips.lua
now holds nearby accepted work ahead of a shared return and supplements the
chosen trip using combined-versus-separate completion savings. It is bounded
by six added work minutes, four quests, .02 return/.06 objective proximity,
known destinations, no risk increase and preserved gear/capacity/pin rules.
Actual near-ready turn-ins and urgent deliveries retain priority. No estimated
spawn coordinate or shared combat savings were added. All 162 tests passed.
The user authorized rebuilding/installing 0.2.0 for playtesting; no PR, merge or
push is authorized. Keep feature/0.2.0-trip-planning and preserve main.

## On-route pickups and manual feedback review

The user reported passing Porthannius without a Delivery recommendation. A
fixture reproduced ready Crown/pinned prior trip excluding the real 110-XP
Delivery. Trips now inserts eligible low-work pickups close to selected route
legs, with the pickup before that leg, a nearby return and bounded extra cost.
Availability inferred only from metadata is labeled check availability.

New Feedback.lua records a bounded local 300-event ring, numeric quest/plan
context and neutral next/later/unplanned/unknown relations. Feedback controls
exist in compact/expanded layouts; `/qw feedback <note>`, `/qw mark`, `/qw export`
and `/qw feedbackclear` are available. Reports use capture tag
`0.2.0-route-feedback-1`; bump that tag for later planner/capture changes.
Automatic capture has no character/account names, chat or full quest prose;
manual notes are explicit user-provided reference text. Never publish actual
saved logs, notes, reports or raw game saves.

The user chose MANUAL reviews: after loading the new build, play, reload/logout,
and ask for review. No schedule is authorized/created. Runtime writes the
bounded feedbackReport export on PLAYER_LOGOUT. `scripts/read_feedback.py`
extracts only that export from supplied files/WTF root without executing Lua,
using neutral source labels. Local target details belong in parent AGENTS.md.
193 Lua tests and 17 Python tests passed; a synthetic actual Lua report roundtrip
through the safe reader also passed. All nine addon sources compiled. Actual
Forever event/UI/persistence behavior still needs user testing. The previous
installed build has no feedback export; the first reload loads
capture, and a later reload after playing saves reviewable data. Treat reported
deviations as hypotheses to compare, not automatic planner training or approval
for new builds. Stay on the feature branch; no PR, merge or push is authorized.

## Multi-stop pickup and confirmed-offer correction

User authorized fixing the two gaps found in the first manual feedback review,
rebuilding and installing 0.2.0. Trips now examines up to three forecast trips
and folds a snapshot-accepted ready-return prefix plus an eligible pickup only
when it fits the existing four-quest/detour bounds. It then reforecasts without
duplicate pickup/XP/completion credit. This is bounded ready-return lookahead,
not speculative planning through unknown objective work.

Provider now discovers unknown current NPC offers as manual pickup-only stages.
Runtime reads transient names/levels, refreshes immediately on NPC opening/
options refresh and clears eligibility when the interaction ends. Live offers
outweigh stale optional metadata for these new candidates; skips, done status,
capacity and actual ready/timed priorities still apply. Accepted quests enter
normal live planning. No future objective/return is guessed before acceptance.

All 210 Lua and 17 Python tests passed; all nine Lua sources compiled. Capture
tag is now 0.2.0-route-feedback-2, retaining existing history and counters. User
feedback reviews remain manual after play/reload. Actual in-game behavior still
needs playtesting. Stay on feature/0.2.0-trip-planning; no PR, merge or push.

## Immediate next task: install for user playtesting

The user **explicitly authorized copying the latest build into the existing
Forever AddOns folder**. The prior session failed on its first destination write
with Operation not permitted because the target was outside its writable roots.
It verified the live files were unchanged after the failed copy. This was an
agent-session access limitation, not evidence of bad macOS folder permissions.

The existing installed addon was observed to be a pre-TomTom 0.2.0 build without
`Navigation.lua`. A backup was made at
`dist/install-backups/QuestWeaver-before-tomtom.zip` (ignored by Git). Treat this
as a dated observation: the user may have installed manually since then.

For the next local session with the appropriate access:

1. Read the parent workspace's local instructions for the exact Forever target.
   Inspect Git status and current installed contents before modifying anything.
2. Verify the ZIP includes `Navigation.lua` and that every manifest-listed source
   matches the current feature-branch source. Rebuild only if needed.
3. Back up any differing installed files under ignored `dist/install-backups/`.
   Preserve earlier backups; do not delete or overwrite an unrelated addon.
4. Copy/extract only QuestWeaver into the Forever AddOns directory. Avoid an
   extra nested folder. Preserve all game-managed SavedVariables and other addons.
   Do not close/restart WoW or run game commands on the user's behalf.
5. Byte-compare every installed release file against the package, then report
   exactly what was installed. Installation verification is not in-game testing.
6. Check whether a matching TomTom installation is present and report the result.
   Ask for a separate instruction if dependency installation is needed.
7. Tell the user to reload the UI as appropriate and test Auto guidance, compact
   movement, grouped quest steps, progress updates and owned-waypoint cleanup.
   The detailed checklist is in VALIDATION.md.

## Environment and publishing notes

- There was no standalone `lua`/`luajit` command in the previous session.
  The tests ran using the Lua 5.1 runtime embedded in an existing VLC installation,
  in a separate headless process, without changing VLC settings or game files.
  The parent workspace notes contain local details. Prefer a standard Lua 5.1
  interpreter when available; the documented invocation is `lua tests/run.lua`.
- `python3 scripts/package.py` builds the release ZIP and checks its declared
  public source set. `HANDOFF.md` is repository documentation, not an addon file;
  separately inspect it and any new public files for privacy before publishing.
- Previous terminal Git/HTTP operations failed DNS. Connected GitHub tools could
  read the repository. Escalation was disabled by that session's policy; repeated
  requests did not fix access. Recheck the next session's actual capabilities.
- The user did not have the permissions menu suggested in the desktop app.
  Do not assume a specific permission UI exists. A local CLI session can use
  `--add-dir` to grant access to the particular installed addon directory.
- Never publish the parent workspace or copy its local instructions, absolute
  home paths, credentials, saved game data or personal identifiers into this repo.

## Accepted-quest continuity and bounded field continuation

User authorized rebuilding/installing 0.2.0 on the feature branch after the
second manual feedback review. Accepted quests with valid current destinations
continue across the corridor on map 1438; unaccepted pickups remain corridor
limited. Runtime pauses on other maps/unavailable positions. Missing destinations
remain quest-log notices, and no current-stage return is invented.

Early-return investigation found unknown-recipient companions excluded by the
shared-return guard. Trips now preserves already grouped accepted nearby work
before an elective return if progress is known and at least half complete,
remaining total work <=2 estimated minutes, targets within .04 map distance and
no increased modeled combat risk. Existing timed/near-ready/pin safeguards and
four-quest bound remain. Unknown returns never earn completion/chain unlocks.

220 Lua tests and 17 Python reader tests passed; all nine Lua sources compiled.
Capture tag is 0.2.0-route-feedback-3, retaining history/counters. Actual boundary
continuity and field-continuation behavior need user playtesting. No PR, merge
or push authorized; preserve main and feature/0.2.0-trip-planning.

The authorized installation completed after inspecting the existing addon and
verifying a backup. All 15 installed release files match the rebuilt ZIP;
no nested addon folder. SavedVariables and other addons were left untouched,
TomTom is present. No game restart/reload or character action was performed.
User should reload to load this build, then play and reload again before review.

## Direct quest-offer discovery follow-up

User authorized investigation/correction of missed pickup 489 and installing an
updated 0.2.0. Review establishes acceptance without a captured available offer;
the exact live interaction sequence is unknown. Runtime had no offer-discovery
path for QUEST_DETAIL without greeting/gossip. It now reads the displayed quest
ID/title and optional level, refreshes immediately and feeds the existing manual
pickup stage. No hard-coded quest 489 availability or invented future work.

Direct offers clear on acceptance, quest closure, progress/rewards, new greeting
or leaving the world. Gossip-to-detail close ordering preserves the open detail
offer. Optional read failures degrade without aborting immediate refresh;
reward capture is protected. Offered IDs now participate in completion reads.
Existing pickup limits/priority, accepted continuity and field continuation stay
in place. Capture tag 0.2.0-route-feedback-4 retains history and counters.

228 Lua tests and 17 Python reader tests passed; all nine sources compiled.
Actual Forever direct-dialog behavior needs playtesting. Stay on feature branch;
no PR, merge or push. Latest feedback review cursor 147, not reset by this build.

Authorized installation completed after verified backup. All 15 installed
release files match the latest ZIP; SavedVariables and other addons untouched,
TomTom present and no nested directory. Reload to load this build, then play
and reload again before feedback review. No game action was performed.

## Confirmed offers outside the corridor and retained outing context

User authorized these two follow-ups and updated 0.2.0 installation. Provider
now allows actual same-map open offers beyond the authored corridor, including
known pack quests, as manual pickup-only actions at the interaction position.
Unseen pickups and speculative future work remain blocked there. Existing class/
race, skip/done/capacity and urgent/nearby-return safeguards remain.

Trips.RetainOuting records at most four accepted IDs that share the first current
DO step, plus a map/area center. Runtime saves this numeric per-character context
and reloads it through validation. Singleton replans preserve it; removals, skips,
failures, map changes and distance beyond .12 prune/clear it. Retained companions
within .06 current map distance can finish before elective returns with <=6 total
estimated work minutes, known progress and no increased modeled combat risk.
Unknown recipients never get fabricated completion/turn-ins/chain unlocks.
The old previous-trip fallback retains its narrower half-done/two-minute bounds.

All 239 Lua tests passed, all nine sources compiled and 17 reader tests passed.
Capture tag 0.2.0-route-feedback-5 preserves history; last review cursor 211.
Actual new pickup/outing/reload behavior needs playtesting. Stay on feature
branch; main unchanged, no PR/merge/push.

Authorized installation completed after inspection and verified backup; all 15
installed release files match the rebuilt ZIP. SavedVariables and other addons
untouched; TomTom present; no nested directory. Reload to load this build, play,
and reload again to save new observations. No game action was performed.
