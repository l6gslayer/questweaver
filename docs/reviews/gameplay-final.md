# Independent final gameplay usability review

The initial gameplay reviewer did not implement the design. Final inspection
covered current UI and manual-waypoint code, synthetic frame-trace previews,
and the interaction regression additions. This review does not establish live
Forever rendering, keyboard/mouse delivery, combat behavior or persistence.

## Actionable finding resolved

**Medium: feedback export wheel handler measured the replaced placeholder.**
The shared scroll helper originally closed over its initial one-unit child;
ShowFeedback subsequently replaced that child with the export EditBox. Its
wheel range therefore remained zero even for a long report. Reported during
final review. The implementation now explicitly sets `contentChild` to the
active export, and the wheel callback measures that object. The final source
inspection confirms that correction. Client wheel behavior still needs playtest.

## Initial findings reassessed

- Current details now have a scrollable viewport instead of a silently bounded
  text block. All grouped members remain available. Quest names precede task
  labels when they differ; task progress stays adjacent. Timed warnings and
  destination information sit outside the overflowing detail region.
- The immediate action and ordered route have explicit labels. Numeric quest
  IDs and repeated member coordinates no longer dominate ordinary reading.
- Compact/Details/Hide controls are named, with tooltips and command recovery.
  Grouped skip scope is named in a tooltip; Reset choices explicitly explains
  restoring skips and clearing the pin rather than changing those semantics.
- Missing TomTom now labels automatic guidance unavailable while preserving
  its saved preference. Manual waypoint attempts acknowledge map-pin or
  coordinate fallback. Optional API exceptions are handled without raw errors.
- Loading and waiting headlines are distinct; zone-handoff and missing-location
  reminders remain available. Empty scope still does not claim every possible
  quest is complete.
- Feedback entry has a visible save acknowledgment and privacy/persistence
  instructions. Clear history requires confirmation with a Cancel action;
  copy/export is visually separate from saving a note.
- The expanded route has more useful reading area. The 800×600 synthetic
  viewport fits the new panel using adaptive scaling; the baseline 640-high
  frame overflowed this viewport in the simulation.

## Inspected evidence

The offline harness executes baseline/current `UI.lua`, serializes actual
anchors, dimensions, colors, text and visibility, then renders approximate
PNG evidence. Reviewed compact/grouped, long German/French names with a timed
warning, small viewport and feedback panel outputs directly. The complete
fifteen-fixture set also covers grouped pickups/returns, item acceptance,
missing-location-only plans, another quest's missing-location notice, defensive
invalid targets, missing TomTom, loading, empty and zone-handoff states. Generated
material remains ignored and uses synthetic data only. See
`scripts/UI_PREVIEW.md` for reproduction and evidence limits.

Final regeneration: all fifteen after fixtures executed without UI errors. The
baseline's deliberately invalid-target fixture throws during numeric destination
formatting; its error is labeled in the evidence rather than represented as a
successful render. The final compact panel shows a scroll cue outside its task
viewport. The missing-location-only state and invalid-target state have disabled
Waypoint controls. The compact/expanded/feedback comparison image was inspected
after regeneration. These checks remain offline source-driven simulations.

## Remaining limitations / playtest priorities

- The native scrollbar graphics, actual font metrics, focus and mouse-wheel
  behavior are approximated, not verified by PNG generation.
- Confirm long-detail overflow is discoverably scrollable in both layouts;
  the normal native scrollbar should make this apparent in the client.
- Check the tracker at the player's normal global UI scale and reduced screen
  space; automatic fitting trades physical text size for keeping controls onscreen.
- The ordinary interface remains English. Synthetic long translated quest
  names test wrapping only, not complete addon localization.
- Verify manual fallback acknowledgment, feedback save/copy/confirmation,
  title dragging and reload persistence after a separately authorized install.

No unresolved actionable gameplay defect was identified in the inspected final
source beyond these client-validation limitations. Planner ordering, quest data,
player actions and private feedback schema were outside this review's edit scope.
