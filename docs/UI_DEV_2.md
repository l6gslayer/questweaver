# UI dev 2: playtest corrections

This is a local follow-up on `codex/ui-ux-pass`. Approved release 0.2.0/build 8
remains unchanged. UI development version: `0.2.0-ui-dev.2`; visible label:
**v0.2.0 | UI dev 2**. The maintainer authorized fixing the reported drag jump
and screenshot-reviewed presentation issues, then backing up and updating only
QuestWeaver for playtesting. No push, PR, merge, publication or game input is
part of this authorization.

## Evidence and changes

A user-supplied in-game screenshot established actual UI dev 1 rendering in the
expanded layout. The private image was not copied into public source. It showed
a generic action heading above a less prominent quest name/aggregate percentage,
repeated current-stop information and catalogue warnings, many equal-weight
buttons, unnecessary-looking scroll controls, and singular/plural inconsistency.
The screenshot is not evidence of every client interaction or of the drag itself.

The reported drag jump has a reproduced source mechanism: normal one-second
refresh called `ClearAllPoints` twice between simulated drag start and release.
Dev 2 records drag state and defers **all** main-frame rendering/layout/placement
while moving. Planning, feedback observation and owned navigation still refresh.
On release, it stops movement, saves the real final position before applying the
latest layout, then renders current state. Hiding during a drag also ends movement
and saves position. No saved route/setting/feedback migration or reset is added.

The UI now:

- Uses an explicit action label and the single quest's actual name as the main
  heading. Grouped stops retain parent quest/task association and scrolling.
- Displays existing live objective descriptions and numeric counts, putting
  unfinished rows before explicitly finished ones. It does not guess a kill verb,
  alter objective matching, or infer quest readiness from counts. Static task
  displays keep conservative existing text matching; missing rows retain known
  percentage or a quest-log reminder.
- Shows the current stop once. The expanded forecast begins with the next stop,
  including projected returns and later outings. All current notices and custom
  safety/instruction notes remain reachable above.
- Suppresses the three exact generic catalogue boilerplates on objectives and
  returns; uncertain pickups retain a brief availability reminder. Custom elite,
  escort, manual-item, temple and navigation instructions remain intact.
- Groups movement, size, mode, skip and reset controls under **Options** in both
  layouts. Waypoint, Auto, Feedback and layout/hide remain directly available.
  Existing semantics/preferences are preserved; opening Options changes no routing.
- Uses a smaller expanded panel, shorter navigation status, singular/plural quest
  labels, and no repeated normal-view provenance. Estimates remain labeled;
  location source is available in the Waypoint tooltip. Optional native scrollbars
  are hidden when their own pane has no overflow; overflowing panes retain a
  visible scroll hint and wheel access.

## Verification and independence

Interaction regressions cover refresh during dragging at normal/enlarged scale,
drop-position ordering, hide cleanup, live objective counts/finished states,
malformed rows, task matching, unknown progress, nonduplicated forecast, note
scope, and Options state preservation. See the current VALIDATION.md result.
An independent reviewer reviewed the implementation and contributed the focused
interaction tests; the reviewer did not implement the UI changes.

Seventeen offline before/after fixtures compare UI dev 1 with dev 2, including
single-quest live rows and the open Options tray. Evidence is ignored under
`build/ui-dev2/`, with image generation from actual executed frame traces.
These are synthetic simulations, not new in-game screenshots. Native font metrics,
button/scroll rendering, physical drag behavior and actual persistence remain
client playtests. No private screenshot or raw SavedVariables is in the fixtures.

## Focused playtest after installation

1. Reload manually and confirm **v0.2.0 | UI dev 2**. Drag slowly for several
   seconds across multiple planner refreshes; release, wait, and repeat at another
   size and in both layouts. It should follow the pointer without snapping back.
2. Check an accepted multi-objective quest: remaining descriptions/counts should
   match the quest log; explicitly completed rows must be distinct. Verify grouped
   quests and unknown objectives without invented completion or instructions.
3. Expand: current work should appear once, with its turn-in and other stops in
   the forecast. Accepted objectives/returns should not say check pickup availability.
4. Open Options, test Lock/Unlock, Size and mode/skip/reset deliberately, then close
   Options. Check current notices, custom safety hints, feedback and owned waypoint
   continuity. Confirm no scrollbar where the pane fits and usable scrolling when
   it overflows. Reload later to check position/settings/feedback persistence.

The user performs these game actions. File installation/readback alone does not
establish successful dragging, visual acceptance or persistence in Forever.
