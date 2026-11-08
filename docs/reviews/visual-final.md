# Independent final visual review

The reviewer did not implement the design. Reviewed current `UI.lua` and offline frame-trace previews for compact/expanded grouped work, feedback, long localized names, constrained viewport, zone handoff, and missing-location scenarios. Compared compact/expanded previews with the approved build-8 trace. These images use synthetic data and approximate fonts/templates; they are not actual WoW screenshots or proof of native rendering.

## Findings requiring resolution

1. **P2 — missing-location evidence fixture does not exercise the named state.** `after-missing-location.png` currently shows the same valid grouped destination (56.3, 45.6 / WoW objective) and enabled Waypoint as the ordinary grouped fixture. It cannot substantiate the missing-location claim. Correct the fixture and regenerate, or exclude that image from evidence. The source contains location-unavailable text and disables Waypoint using `Navigation.Destination`; that is a separate source observation.
2. **P3 — overflow needs a visible reading cue.** Expanded grouped preview clips the fourth member at the current-action viewport edge. Source provides native scrollbar and mouse-wheel behavior, so the content is reachable, but no explicit text cue explains overflow. A conditional short 'Scroll for more' hint would improve discoverability, especially since the independent current and route panes scroll separately. Native scrollbar visibility needs actual client playtesting; the simulator does not render it.

## Initial weaknesses addressed

- Current content is bounded by its own scroll pane; destination, status and buttons flow after the pane. Long localized text wraps without the baseline's independently anchored footer collision risk in inspected traces.
- The next-action heading, current quest names/progress, destination and navigation state occupy distinct regions. Technical quest IDs are removed from routine route text, and coordinates appear per stop.
- Build identity is explicit UI development identity, while zone has its own line. Neutral border and restrained gold action/route accents reduce competition with native button visuals.
- Compact mode exposes all grouped members through scrolling; expanded mode offers a separately bounded route forecast with numbered stops.
- Feedback has a labeled note field, local save acknowledgment, separate export action, and two-step history clear with cancel. The visible '240 bytes' wording was reported to the implementer and is already being replaced with ordinary player language.
- Layout and Hide controls now name their actions, and controls expose explanatory tooltips.

## Remaining limitations / tradeoffs

The new compact grouped trace is taller than build 8 (roughly 445 versus 250 logical pixels in the shown fixture). Its extra whitespace and larger type improve reading but increase screen occupancy; small-size and compact-mode playtesting should assess this tradeoff. Constrained screens automatically reduce the entire panel, which keeps controls onscreen but cannot guarantee comfortable text size. Expanded mode repeats the current stop in its full-route pane by design; the duplication preserves complete trip context at a vertical-space cost. Status wording such as 'TomTom next-action destination ready' remains wordy but is understandable and does not require API knowledge.

No further source-level visual blocker was identified beyond the evidence correction. Final acceptance still requires actual Forever font metrics, native button/scroll rendering, hover behavior and normal gameplay-scale readability. No installation or game action was performed by this reviewer.

## Resolution addendum

Re-inspected regenerated `after-missing-location.png`, `after-compact-grouped.png`, and `before-after-comparison.png` after the requested corrections. Both review findings are resolved within the offline evidence boundary:

- Missing-location preview now shows the unavailable quest-location notice, no destination coordinates, and a disabled Waypoint control. It no longer duplicates the valid grouped-route fixture.
- Overflow now has an explicit 'Scroll for all tasks and notices' cue. The expanded comparison also shows a separate 'Scroll for later stops' cue. Current content remains bounded above destination/navigation controls.
- Compact removes the redundant action eyebrow and caps current details at 116 logical pixels; the shown grouped frame is now approximately 382 pixels high rather than the earlier 445. It remains taller than the baseline's approximately 250-pixel example, an intentional readability/occupancy tradeoff for owner playtesting.
- Feedback comparison confirms the note label now says 'optional; keep it brief' without storage terminology.

No unresolved actionable visual finding remains in the inspected implementation and regenerated simulation states. Native rendering, real font metrics, scrollbar behavior and gameplay-scale acceptance remain unverified in Forever; these corrections do not establish live-client validation.
