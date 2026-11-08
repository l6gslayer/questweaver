# Changelog

## 0.2.0 — Shadowglen trip planning

- Automatic optional TomTom arrow guidance for the next outstanding action,
  with Auto: On/Off in both layouts and `/qw auto on|off`.
- One temporary waypoint updated only when the destination changes; owned-point
  cleanup on route end, leaving the supported area, loading transitions or turning
  automation off. Hidden/compact tracking continues. Manual fallback remains.
- Cave, upstairs and timed-delivery navigation hints; arriving at a waypoint
  does not complete quests. External TomTom waypoints/settings are preserved.

- Movable by default; visible Lock/Unlock and minimize/expand controls.
- Compact next-action tracker with grouped quest progress and a waypoint button.
- Normalized saved position, legacy-position migration and reset-position command.
- Persistent compact/locked preferences; existing skips, rewards and settings kept.
- Complete-trip scoring: collect compatible quests before leaving a hub, work
  nearby objectives together, and combine nearby turn-ins.
- Split Iverron's Antidote into mushroom, lily and spider tasks; resolve live
  English objective progress conservatively without declaring unknown tasks done.
- Shared travel counted per actual modeled leg; combat time reduced only for
  explicit shared-source tasks. XP credited once per quest per projected trip.
- Bounded gear-chain lookahead and whole-trip gear allowance comparison.
- Accepted timed delivery prioritized without elective detours; known quest-log
  capacity respected; modest route hysteresis reduces direction changes.
- Expanded regression tests and a repeatable synthetic travel comparison.

This is a test build awaiting in-game acceptance. Objective coordinates, work
estimates, static timing flags and travel geometry still require Forever testing.

## 0.1.0 — Initial alpha

- Original 12-quest Shadowglen pack, single-action scoring, learned reward stat
  comparisons, optional QuestieDB/TomTom integration and basic tracker.
- 30 Lua tests and initial GitHub Actions validation passed.

### 0.2.0 objective-location follow-up

- Prefer guarded WoW current quest waypoint/map-area data for accepted quests;
  use live return points after completion and retain labeled starter estimates
  when location data is unavailable.
- Show destination provenance in both tracker layouts. Live quest stages do
  not duplicate static gathering-task pins or change the player's tracked quest.

### 0.2.0 nearby quest and item-start follow-up

- Add Fang of Githyiss as an optional cave outing, bag acceptance and Aldrassil
  delivery; combine accepted returns with Webwood Egg when useful.
- Discover carried quest-starting items through guarded modern/legacy bag APIs,
  plus accepted quests with live Shadowglen destinations. Show unlocated bag
  items as reminders and keep acceptance/manual item use under player control.
- Support current-stage trips when the eventual return is unknown; do not
  fabricate turn-ins or unlock chains from unresolved stages. Label unknown XP,
  reserve conservative return cost, and bound large-log candidate evaluation.

### 0.2.0 Shadowglen audit and nearby return correction

- Prioritize observed ready turn-ins beside the current player position before
  elective departures, pins and previous-route stickiness. Group up to four;
  accepted timed deliveries keep first priority.
- Read guarded WoW ready-for-turn-in state, falling back to completion flags.
- Add Nature's Call and The Goddess Provides using actual NPC-offer/accepted
  evidence and live objective destinations, plus owned-voucher/accepted Welcome!.
- Record class-introduction and outbound Dolanaar coverage boundaries in SOURCES.

### 0.2.0 class introductions and Dolanaar handoffs

- Add five Night Elf class introductions with class/race gates and actual NPC
  offer evidence, plus full accepted routes to the individual trainers.
- Add Crown of the Earth 928 after 921 and Dolanaar Delivery 2159; evaluate
  shared southbound pickup/return trips with existing capacity/priority rules.
- Extend runtime, discovery and automatic guidance bounds down the road into
  Dolanaar (map 1438, x 50–65%, y 23–65%). Broader Dolanaar pickup coverage
  remains outside this authored pack; accepted local quests can join trips.

### 0.2.0 shared-return batching correction

- Keep nearby accepted objective work before its shared return instead of
  greedily returning between objectives.
- Add useful accepted companions by combined-versus-separate trip cost, so
  partial progress and solo XP/minute do not split Moss/Totem-style outings.
- Preserve ready nearby turn-ins, urgent deliveries, prerequisites, pins, gear
  allowance and capacity; bound companion work/risk/travel and four-quest size.

### 0.2.0 on-route pickups and local playtest feedback

- Add eligible low-work pickups along selected outings, preserving destination,
  ready/timed priority, capacity, gates and bounded extra travel/work. Porthannius
  can be suggested before continuing an existing Dolanaar trip.
- Add local bounded quest/plan observations and neutral deviation classification,
  grouped-plan awareness, manual notes/markers and a feedback/export panel.
- Save the copyable export on reload/logout for user-initiated review. Add a
  safe local reader that never executes saved Lua or exposes directory labels.
- Avoid false capture during unavailable log/loading data and keep the preceding
  recommendation with inferred actions. No automatic learning, scheduled review,
  network upload, quest acceptance or player movement is introduced.

### 0.2.0 multi-stop pickup and confirmed-offer correction

- Look ahead through up to three independent ready-return trips to collect a
  useful pickup before passing it, within the existing four-quest/detour bounds.
  Reforecast remaining work without duplicate pickup, XP or completion credit.
- Discover unknown quests offered by the current NPC as manual pickup-only
  candidates; use client names/levels, refresh immediately, and discard closed
  offers rather than fabricating future quest data or permanent availability.
- Preserve prior capture entries and counters; new observations use capture tag
  0.2.0-route-feedback-2 so subsequent manual reviews identify this build.

### 0.2.0 accepted-quest continuity and field continuation

- Continue accepted current-stage quests across the authored corridor boundary
  on Teldrassil. Keep unaccepted pickups within the corridor and pause on other
  maps or unavailable player positions.
- Retain accepted dynamic quests whose live objective/return moves beyond the
  corridor; unknown locations remain reminders rather than guessed waypoints.
- Before an elective return, finish bounded nearby unknown-return work already
  grouped in the previous outing. Require known progress, at least half done,
  at most two remaining work minutes and existing urgency/proximity/pin safeguards.
- Capture tag is now 0.2.0-route-feedback-3; existing saved history is preserved.

### 0.2.0 direct quest-offer discovery

- Recognize QUEST_DETAIL offers even without a greeting/gossip list, refresh
  immediately and capture the offered quest before manual acceptance.
- Clear direct offers on acceptance, dialog closure, progress/rewards, new
  greeting or leaving the world; keep observed and accepted stages distinct.
- Preserve normal pickup safeguards; use no hard-coded availability for quest 489.
- Capture tag 0.2.0-route-feedback-4 preserves earlier history and counters.

### 0.2.0 confirmed offers and retained outings

- Allow actual open quest offers across Teldrassil, including outside the authored
  corridor. Treat them as manual pickup-only stages; unseen pickups stay bounded.
- Retain accepted quests sharing current work through singleton replans and UI
  reloads using bounded numeric outing context. Prune stale/removed/skipped work.
- Finish nearby retained work before elective returns with up to six estimated
  work minutes, preserving urgent/nearby-return/pin and risk safeguards. Unknown
  recipients remain unknown until observed.
- Capture tag is 0.2.0-route-feedback-5; existing feedback is preserved.

### 0.2.0 expanded Teldrassil catalogue

- Expand from 23 to 79 records, adding independently sourced ordinary chains,
  Forever additions, conditional Camping/profession records and object pickups.
- Plan known pickups ahead of interaction across Teldrassil, respecting recorded
  prerequisites and labeling unconfirmed availability. Unknown work remains
  pickup-only until accepted; conditional/insufficient records stay offer-only.
- Add owned Moss-twined Heart support and uncertain nearby rare advisory; keep
  object-supplied fruit/fronds separate from bag starters. Preserve Forever's
  Oracle intermediary chain and avoid city-coordinate mixups.
- Preserve catalogue prerequisites against incomplete/conflicting optional
  metadata and use actual client offers/stages when available.
- Include CATALOGUE.md audit in the package. Capture tag 0.2.0-route-feedback-6;
  existing feedback remains preserved. This build has not been installed.

### 0.2.0 zone catalogues and initial Darkshore coverage

- Register separate Teldrassil/Darkshore catalogues and automatically select the
  supported current map before reading quest locations. Keep zone NPC database
  coordinates separate and read prerequisites completed in other zones.
- Add 28 Darkshore records with an evidence audit: eight advance pickup candidates,
  eighteen conditional offer-only records and two owned-item starters.
- Clear previous-zone routing/outing/owned waypoint context, preserve the first
  current-zone interaction and prevent stale offers returning after unsupported
  travel. Recognize carried starter IDs across catalogues without ambiguous
  item-only guesses.
- Keep version 0.2.0 and bump capture tag to 0.2.0-route-feedback-7. Rebuilt package
  is ready for requested installation; no game files were changed by this work.
