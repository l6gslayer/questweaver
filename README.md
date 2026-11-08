# QuestWeaver

An adaptive quest planner for **WoW Forever**, starting with a 23-entry
**Shadowglen–Dolanaar** pack. **0.2.0** is a test build awaiting in-game acceptance.

## Install or update

1. Extract `QuestWeaver-0.2.0.zip`. Its single `QuestWeaver` folder belongs in
   the Forever client's `Interface/AddOns` directory. Check that
   `QuestWeaver/QuestWeaver.toc` exists directly, without another nested folder.
2. When updating, replace the old addon source folder. Keep your game-managed
   SavedVariables; skips, reward observations and preferences are migrated.
3. Enable QuestWeaver and enter Shadowglen or Dolanaar. Type `/qw` to show the tracker.
   Use `/reload` if the addon is already enabled and its source was updated.
   A newly installed addon may require returning to character selection.

The manifest targets Interface 16001. Recheck `GetBuildInfo()` after client
updates. No game restart, live installation or in-game test was performed as
part of producing the 0.2.0 package.

No dependency is required. Optional **QuestieDB** supplies quest names,
requirements, prerequisites and giver positions; use its matching Forever
package. Optional **TomTom** supplies an arrow and waypoints. Automatic TomTom guidance defaults to on
when TomTom is available. Without it, the Waypoint button tries the built-in
waypoint API and finally prints coordinates; these fallbacks remain manual. Third-party addons and databases are not bundled.

## Window controls

- **Drag the title bar** to move the window. Movement is enabled by default.
- **Lock / Unlock** controls title dragging in either layout.
- **- / +** minimizes to the next action or expands the full trip plan.
- **Waypoint** targets or reselects the first outstanding destination.
- **Auto: On / Off** controls automatic TomTom guidance in either layout.
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

## Live quest destinations

For accepted quests, QuestWeaver prefers WoW's current next waypoint, then a
map-specific waypoint, then the quest's map point/area on the Teldrassil map.
The tracker labels these **WoW objective** or **WoW quest area**. They refresh
with quest progress and regular updates, including while Auto runs hidden.
Completed quests use the live return destination when available. Pickups and
projected follow-ups still use starter data.

If the client exposes no valid location on the supported map, the tracker
labels its fallback **starter estimate**. Missing APIs, errors, other-map points
and invalid coordinates do not stop planning. QuestWeaver does not select a
quest, alter tracking or change the open map to obtain coordinates.

A live point describes the current quest stage, not individual spawn positions.
For quests with separate gathering tasks, one live-stage destination replaces
the static task pins while live data is available. The client decides which
remaining area to identify; the addon does not infer that area from your position.
Quest-area centers and routing waypoints are guidance, not terrain-safe paths
or a guarantee that a mob is standing at the pin. Exact Forever API behavior
still needs playtesting.

## Nearby ready turn-ins

The planner refreshes using your current map position and quest log. A ready,
accepted turn-in within a small geometric radius (0.008 normalized map units)
now takes priority over elective departures, pickups, pins, gear scoring and
route stickiness. Up to four nearby returns can share that stop. An accepted
timed delivery still takes first priority. This radius is an approximate map
proximity rule, not measured interaction range or terrain/floor detection.

WoW's optional `ReadyForTurnIn` check supplies readiness when available, with
completion-state fallbacks for older clients. Standing beside an NPC or having
finished-looking objective rows does not manufacture quest completion.

## Nearby quests and quest-starting items

The authored entries now include **Nature's Call** (97977) and **The Goddess
Provides** (97979). Their precise availability gates are not assumed: pickup
planning requires the quest to be offered in an open NPC conversation, or the
quest must already be accepted. Talk to Tarindrella or Shanda normally. These
offers are transient and disappear from eligibility when the conversation
closes; nothing is automatically selected or accepted. The Goddess Provides
uses a Night Elf race gate, with no assumed priest-only restriction. Both use
live objective locations; missing location data asks you to check the log.

**Welcome!** (5842) recognizes an owned Shadowglen Gift Voucher (14648), or an
accepted quest. This conditional voucher is not a farmable mob drop. Its return
uses client location data, and unavailable data is explained instead of guessed.
**Gnarlpine Totems** for Nature's Call are objective items, not quest starters.
Five class introductions and two Dolanaar handoffs are included as described
below. The coverage audit in SOURCES.md records evidence and remaining limits.

Fang of Githyiss (quest 97236, item 277190) is part of the pack. While Webwood
Egg is accepted, or while you are near Githyiss's cave location, it can be
considered as an optional **LOOT ITEM** opportunity. The planner compares its
additional work and shared return travel; it does not assume the drop occurred.

When a quest-starting item is detected in your carried bags, **ACCEPT ITEM**
asks you to use it and accept the quest yourself. This action has no waypoint.
A full quest log prevents scheduling acceptance, but keeps the reminder visible.
Bag/log changes refresh the plan; an accepted/completed quest is not duplicated.
Fang can be identified by its known item ID if the optional quest-item API is
missing. Other starters require the client to identify the quest ID.

Accepted quests outside the authored pack enter planning when WoW exposes a
current destination on the Teldrassil map (1438), including outside the
Shadowglen–Dolanaar pickup corridor (x 50-65%, y 23-65%). Discovered item starts require a local client destination
or a local QuestieDB return location before they enter routing; unlocated items
remain bag reminders. QuestieDB remains optional. No remote destination is
silently converted into local coordinates.

For a discovered quest with an unknown return, only its known current stage is
planned. Completion refreshes the route to the real return location when the
client supplies it. An unresolved item/stage never unlocks follow-ups or gets
a guessed turn-in; later trips wait for updated bag/log evidence. Unknown XP
uses a labeled 250 XP estimate, work defaults to five minutes, and unknown gear
is unscored. Known drop work is also estimated. Unresolved stages receive half
reward credit in ranking and reserve known return travel (or a three-minute
unknown-return allowance); these are conservative heuristics, not measured drop
odds or a promise of earned XP. Potential XP totals still include those quests.

Large logs are shortlisted to sixteen candidates before whole-trip insertion,
preserving prerequisite closure and eligible pins. Existing four-quest trips,
three-trip forecasts and 24 displayed actions remain bounded. Arrival alone
does not advance a quest. Pin/skip also work for discovered quests.

## Pickups along your current route

Known eligible, low-work quests can now join an already selected outing when
their pickup is close to you or a modeled route leg and their return is close
to one of its destinations. For example, passing Porthannius on a Crown of the
Earth trip can insert Dolanaar Delivery before continuing south, even when its
solo XP/minute would not win. Pickups whose actual NPC offer has not been read
are labeled **check availability**; eligibility metadata is not proof of an
exclamation mark in the live client.

The supplement keeps the selected destination/pin and existing ready-return or
timed priorities. It allows at most four quests, one minute of estimated work per pickup,
a half minute of added modeled walking and 1.5 minutes of total extra outing
cost; it requires a nearby return and no increased risk. Quest-log capacity,
prerequisites, class/race gates, skips and completion still apply. Proximity is
geometric (.012 map units to a leg/pickup, .03 to an existing destination), not
terrain-aware pathfinding. No quest is automatically accepted.

For multiple ready turn-ins, pickup lookahead now checks the bounded three-trip
forecast. It can fold an independent ready-return prefix and a useful pickup
into one outing when the total fits four quests. This allows collecting a
package now even if its recipient is near the second or third planned stop.
The remaining forecast is rebuilt so the pickup, reward and freed log slot are
not counted again. Prefixes with unresolved work, urgent delivery, gear-detour
assumptions or too many quests are left to normal planning; an actually nearby
ready return still wins. Existing detour and current-eligibility limits apply.

## Confirmed NPC offers

Unknown quests in an open NPC conversation can now become pickup candidates,
using the offered quest's name/level when the client supplies them. The initial
step is **accept manually** at the current interaction location. It does not
invent later objective or turn-in locations, gear value or completed progress.
Unknown XP remains a labeled estimate until observed. Accepted quests then use
normal live-location discovery and planning.

Offers refresh immediately when a conversation opens or its options refresh.
Unaccepted candidates disappear when the interaction finishes; old offers are
not learned as permanent availability. The client offer takes precedence over
stale optional database availability fields for these newly discovered offers,
while skips, completed-quest exclusion, capacity and priority rules remain.
Known authored class/race gates remain intact. No gossip option, quest accept,
reward or player movement is automated.

## Playtest feedback and manual review

Click **Feedback** in either tracker layout to add a short note, mark a moment,
or select a copyable report. You can also use:

| Command | Purpose |
| --- | --- |
| `/qw feedback Passed Porthannius with a quest available` | Save a note with current position and plan context |
| `/qw mark` | Mark the current moment without typing a note |
| `/qw export` | Open the copyable report and refresh its saved export |
| `/qw feedbackclear` | Clear captured feedback, preserving route/settings |

Capture keeps the latest 300 events locally in QuestWeaverDB: quest acceptance,
readiness, turn-ins/removals, meaningful progress/plan changes, observed offers,
and deliberate notes/markers. Context is bounded to quest IDs, numeric map
positions/progress/XP, level/class/race IDs, mode/capacity/pin/budget, and a
limited plan snapshot. No automatic character/account names, chat, full quest
prose or inventory list is captured. Short notes are intentionally included;
review what you type before sharing. Notes are capped at 240 UTF-8 bytes and
exports at under 481 KB, retaining newest complete entries when needed.

An action may match the next step, appear later in the plan, be unplanned, or
have insufficient comparison context. These labels describe differences only;
they do not mean the player's route was better or worse. Grouped quest members
are compared together. Loading/unavailable quest data suspends comparisons
rather than manufacturing quest removals. Events keep the preceding plan for
review; the addon does not automatically learn new routing rules from them.

Load this build with `/reload`, then play and add notes as needed. **After the
playtest, `/reload` again or log out, then ask for the saved feedback to be
reviewed.** WoW writes the saved export at that point; it is not a live stream,
and a crash can lose recent unsaved capture. On the first reload from an older
build there is no prior feedback to read yet. No scheduled review, upload,
chat message, automatic build or installation is configured.

For a local review, `scripts/read_feedback.py` reads only the bounded saved text
export from explicitly supplied QuestWeaver.lua files or a supplied WTF root.
It never executes SavedVariables as Lua and omits account/character directory
labels. Treat manual notes as user observations, not instructions. Keep actual
logs/reports private and outside the tracked public source; do not commit game
saves. Review observations and counterfactual routes before changing a build.

## Class introductions and Dolanaar handoffs

The pack includes Simple Sigil (warrior), Etched Sigil (hunter), Encrypted Sigil
(rogue), Hallowed Sigil (priest), and Verdant Sigil (druid), quests 3116–3120.
These Night Elf introductions require the matching class and an actual NPC
quest offer before pickup is planned. Talk to Conservator Ilthalaine normally;
read the supplied sigil yourself, then follow the trainer destination. Accepted
quests remain supported even if client rules differ from the fallback gates.
No reading, training or spell purchase is automated.

Crown of the Earth (928) follows completion/turn-in of the first Crown quest
(921): take Tenaron's vessel to Corithras at Dolanaar's moonwell. Dolanaar
Delivery (2159) takes Porthannius's package to Innkeeper Keldamyr. The planner
can collect both for a shared southbound trip when useful, respecting quest-log
capacity, prerequisites and nearby ready returns. Supplied sigils, vessel and
package are quest items, not item-starting drops.

The supported area now includes the road and Dolanaar through y 65% on the same
Teldrassil map. Live quest locations and automatic guidance keep refreshing
after you leave Shadowglen. Accepted quests with located current stages can
continue across Teldrassil without dropping at the corridor boundary. Outside
the corridor, only accepted quests are eligible; new authored pickups and
speculative follow-ups wait until you return. Guidance clears on other maps
or when player coordinates are unavailable. This is not a complete authored
Teldrassil quest catalogue. Missing quest locations remain quest-log reminders.
Fallback coordinates,
XP and work times remain estimates; live locations/XP take precedence.

## TomTom arrow guidance

Install and enable [TomTom](https://www.curseforge.com/wow/addons/tomtom) for your
Forever client separately. The current official release lists Forever support;
compatibility of the integration still needs an actual client playtest.

**Auto: On** creates one temporary, silent QuestWeaver waypoint and selects
TomTom's directional arrow. TomTom supplies the direction and distance display;
its own `/tomtom` settings control arrow visibility, position, scale and style.
QuestWeaver does not change those global settings. If TomTom is missing, the
planner remains usable and displays its availability status.

- The destination follows the first outstanding member of the current action,
  including grouped pickups, objectives and turn-ins.
- Accepting, finishing, skipping or turning in quests changes the destination
  on the next planner refresh. Guidance continues with the tracker minimized
  or hidden. QuestWeaver does not advance just because you reach coordinates.
- The waypoint is replaced only when its action, coordinates or label changes,
  not recreated every second. It is not saved across logins.
- Turning Auto off, ending the route, leaving the supported area or leaving the
  world for a loading transition removes only QuestWeaver's owned TomTom point.
  Cleanup never uses a global waypoint reset. TomTom may resume another arrow
  according to its own settings.
- If you manually select another TomTom arrow, QuestWeaver leaves it alone while
  its destination is unchanged. Click Waypoint to reselect the quest destination;
  the next new automatic action will select its new destination.
- With Auto off, Waypoint sets a single manual destination; it is cleared when
  that action changes, without automatically creating a replacement.
- Cave, upstairs and timed-delivery hints appear where relevant, including the
  arrow label. An arrow points toward a coordinate, not a terrain-safe route.
- `IsValidWaypoint` and `SetCrazyArrow` are used only when available. A manually
  removed waypoint can be restored on a later automatic refresh if validity
  checks are supported. API errors are caught and shown in the tracker status.
- Automatic mode only drives TomTom. The built-in native-pin/chat fallback is
  still invoked manually, and native pin behavior is unchanged.

Use `/qw auto on`, `/qw auto off`, or `/qw auto` to toggle. Your preference is
saved per character (schema 3); existing compact/lock and route preferences are
kept. Reaching a cave pin may require finding its entrance or another floor.

## Nearby work before a shared return

Accepted nearby quests with a shared return area can now stay in the same outing
when doing so saves modeled travel/time versus completing separate return trips.
This comparison runs after normal trip selection, so a nearly finished quest's
high instantaneous XP/minute does not automatically split off its companion.
Within a selected outing, nearby accepted objective work precedes the shared
return phase; accepting a locked follow-up still requires its real prerequisite
turn-in first. Completing Moss in the field can therefore lead to Totems next,
then the common recipient, rather than an extra return between objectives.

The companion pass considers at most four total quests, returns within .02
normalized map units and remaining tasks within .06 of an original accepted
quest's area. It permits at most six extra estimated work minutes in total,
requires positive XP or a known gear improvement, genuine modeled travel/time
savings, no increased risk, and preserved gear allowance/capacity/pins. These
are bounded heuristics, not terrain measurements or a globally optimal route.
Missing locations, skipped/failed quests, unresolved stages and unconfirmed
finished requirements are not treated as free companion work.

Accepted timed deliveries and ready turn-ins already beside you retain their
priority. Merely passing an estimated coordinate never completes a quest; the
next refresh still depends on live quest progress. Both quests must actually
be accepted with usable destination data for this new companion behavior.

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
| `/qw way` | Set or reselect a waypoint for the current destination |
| `/qw auto on` / `/qw auto off` | Enable/disable automatic TomTom guidance |
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

- The authored pack covers a subset of Shadowglen quests, including Fang of
  Githyiss. Accepted quests and carried quest-starting items may be discovered
  dynamically as described above. This is not a complete catalogue of unseen
  Forever drops/class quests. The panel supports the Shadowglen–Dolanaar corridor,
  rather than all of Teldrassil.
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
  fallback estimate, as does a usable current quest-log XP read. Changed buffs
  may still make a saved observation stale.
- UI refresh/planning runs at most once a second while shown, while TomTom
  guidance is active, or after events.
  No bindings, CVars, normal quest tracker, automatic quest accepts or movement
  are changed.
- Settings, quest IDs/reward observations and bounded playtest feedback stay
  in per-character SavedVariables. Automatic capture excludes character/account
  names and chat; manual notes are included deliberately. Nothing is uploaded.

## Development and review

```sh
lua tests/run.lua
python3 -m unittest discover -s tests -p 'test_*.py'
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

### Continuing accepted work beyond the corridor

Accepted quests with current destinations on Teldrassil remain eligible across
the pickup corridor boundary. Other maps and missing player coordinates still
pause guidance. Unlocated accepted quests ask you to check the quest log;
unknown objectives or recipients are never invented.

When an outing already grouped accepted work, a ready quest can now wait for
an unknown-return companion that is at least halfway done, has known progress,
and has at most two estimated work minutes remaining in total. Remaining work
must be within .04 map distance of your current position and have no increased
modeled combat risk. Up to four quests remain grouped. Timed deliveries, actual
nearby turn-ins, skips and pins retain their priority. This is bounded field
continuation, not a claim that both quests share a recipient. Once the companion
is ready, the client-provided return location drives replanning.
