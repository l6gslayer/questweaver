# Independent final review: UI dev 2

Reviewed the follow-up implementation and offline `single-live` and `options`
frame-trace renders. The reviewer did not implement UI.lua or the design;
the reviewer authored interaction regressions after independently examining the
dragging lifecycle and objective-display boundaries. No game action or live
addon installation was performed by this reviewer. No private screenshot or
objective text was copied into the tests or report.

## Findings and disposition

- **Dragging:** ordinary rendering, direct placement and direct layout return
  while dragging. Geometry does not resize, rescale or reanchor during the
  refresh. Release stops movement and saves its final location before applying
  deferred content; hiding also stops movement and saves position. Regressions
  exercise both normal and enlarged scale, an updated plan during movement and
  hiding before release. The source-level cause of the reported jump is addressed.
- **Objective display:** live unfinished objective text and counts precede rows
  explicitly marked done by the client. Already supplied counts are not appended
  again. Static multi-task quests conservatively match their known task token;
  an unmatched objective retains the quest-log fallback. Non-numeric, non-finite
  and negative counts do not format-crash. Rendering does not change readiness,
  progress, planner completion or the objective payload.
- **Information hierarchy:** a single current quest has its own headline rather
  than a generic larger instruction. The forecast omits that current stop,
  preserving later projected returns. The inspected synthetic live-objective
  screen shows actionable counts and explicit done text without repeated catalogue
  warnings. Singular quest grammar is corrected.
- **Warnings and safeguards:** the three exact generic catalogue boilerplates
  become a short availability reminder only for an unobserved pickup. Accepted
  work and projected returns do not inherit that reminder. Custom safety/manual
  notes remain available; no catalogue metadata was edited.
- **Controls and overflow:** secondary movement, sizing, mode and route-choice
  controls are behind Options in both layouts. Opening/closing Options does not
  alter planner preferences, position or navigation preference. Current and route
  scrollbars are conditionally shown when overflow exists; all long details
  remain reachable through scrolling. Waypoint, Auto and Feedback stay visible.

No unresolved actionable source or simulated-layout issue was identified in
this follow-up review. The full isolated Lua 5.1 suite passed **297 tests**,
including compilation of all thirteen addon sources and eight added regression
cases. Existing assertions were updated for the development identity, relocated
item instruction and intentionally hidden secondary controls.

## Evidence limits

The source regressions and offline renders do not prove actual Forever dragging,
font metrics, native scrollbar visibility or input behavior. The supplied live
UI-dev-1 screenshot informed the lead agent's problem list; the inspected dev2
renders use synthetic names, data, fonts and template approximations. After the
separately authorized installation, manual playtesting should check a drag held
through several refresh intervals, release/hide recovery, live objective counts,
Options discoverability and scrolling at normal/global UI scales. Planner,
feedback persistence and TomTom ownership remain outside this presentation fix.
