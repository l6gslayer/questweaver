# Independent final review: accessibility and scaling

Reviewer authored the initial accessibility critique and interaction regressions,
but did not implement the UI design. Reviewed current `UI.lua`, simulated
interaction results and offline rendered long/localized, constrained-viewport and
feedback states. Images were generated from actual UI frame traces with synthetic
data. They are not WoW screenshots and do not establish Forever compatibility.

## Outcome

No remaining high-severity accessibility defect was identified in this review.
The major initial source-level risks have concrete resolutions:

- Every current-stop member, parent quest/task label and notice is retained inside
  a bounded scroll region. Destination and timed warning are outside that region.
  The next action and permanent controls no longer depend on truncating a member
  list. Long grouped fixtures demonstrate overflow and wheel access.
- Body text uses normal native font roles with explicit near-white color, while
  short action headings, context and destination form a clear reading hierarchy.
  Meaning remains in text: loading, unavailable navigation and warnings do not
  depend on hue.
- Named Details/Compact and Hide controls replace ambiguous single glyphs. Button
  height increases to 28, with tooltips and slash-command alternatives for core
  tracker operations. Title dragging remains restricted by the saved lock state.
- Requested tracker size is bounded, malformed values recover, and final frame
  fitting uses actual assigned height. Saved finite normalized coordinates and
  screen clamping remain in use. The constrained-screen simulation verifies that
  the effective frame dimensions fit available UIParent space.
- Feedback has a visible note label, local saved acknowledgment, export separation,
  an explicit clear confirmation/cancel flow, draft preservation and focus release
  on close. Long exports wheel-scroll the actual report child. Display edits do
  not mutate the stored report.

The full Lua 5.1 suite passed at **284 tests** when this reviewer ran it, including
new meaningful interaction cases for these behaviors. Existing item-stage and
build-label assertions were adapted to the new information location rather than
removed. No planner code, game save, installed addon or game action was involved.

## Actionable polish finding

P3: the feedback label initially exposed “240 bytes,” an implementation unit that
is particularly confusing for Unicode notes. Requested replacement with plain
language such as “Your note (optional; keep it brief).” This is a copy-only change;
retain the existing safe persistence bounds. Track its final resolution in the
main implementation report.

## Remaining limitations and playtest requirements

1. Actual font metrics, wrapping, native scrollbar appearance and click-through
   behavior require Forever inspection. The offline previews approximate fonts,
   templates, z-order and clipping. In particular, the screenshot renderer does
   not prove that a native scrollbar thumb or keyboard copy operation works.
2. Automatically shrinking a large tracker to a constrained effective screen can
   reduce text and targets below a player's preferred readable size. The saved
   requested size remains visible, while fitting can make the actual result
   smaller. On a small screen, compact mode is the preferred playtest alternative;
   there is no claim of a minimum physical text or target size.
3. Long synthetic German/French titles were exercised, but the addon itself is
   not localized. Translated button labels, right-to-left text, CJK font fallback,
   narration and comprehensive keyboard-only navigation are not implemented or
   verified by this pass. Do not claim accessibility compliance.
4. Feedback panel movement and scaling need real-client input checks, including
   opening it on a constrained screen, moving it, changing global UI scale and
   closing it while an edit box has focus. Reload persistence is represented by
   tests rather than an observed game session.

Suggested focused playtest: read a four-member stop at preferred global UI scale;
wheel through all details and confirm the destination stays visible; enlarge the
tracker and switch layouts near screen edges; inspect loading/missing-location/
missing-TomTom states; save a short Unicode note, cancel a clear, copy an export,
and close/reopen without losing an unfinished draft. Preserve existing settings
and perform any game reload only under the maintainer's control.
