# UI/UX development pass

This records the original UI dev 1 pass. See [UI dev 2 corrections](UI_DEV_2.md)
for the later user screenshot review and dragging/presentation fixes.

2026-11-07. Branch: `codex/ui-ux-pass`, based on clean main `593f879`.
Approved release remains 0.2.0/build 8, integrated through PR #1 at `7eafd03`.
This branch is **0.2.0-ui-dev.1**, visibly **v0.2.0 | UI dev 1**. It is a local
review build, not an approved replacement or a new published release.

## Independent critiques

Four distinct reviewers completed their initial reviews before being given the
other findings or a proposed design:

- [Visual design](reviews/visual-initial.md): fixed text regions can collide;
  repeated headings and metadata weaken hierarchy; feedback lacks clear states.
- [Gameplay usability](reviews/gameplay-initial.md): long/grouped content can
  hide instructions; task labels lose parent quest identity; destructive clear
  is immediate; navigation availability and skip scope are ambiguous.
- [Accessibility/scaling](reviews/accessibility-initial.md): small body fonts,
  fixed dimensions, clipped status text, short control labels and lack of a
  saved size control make information harder to reach.
- [WoW implementation quality](reviews/wow-initial.md): optional manual waypoint
  APIs can throw, saved positions need finite guards, UI identity is coupled to
  capture version, and scrolling/focus/feedback need explicit lifecycle checks.

An additional [implementation critique](reviews/implementation-initial.md) was
performed by the visual reviewer. It is supplementary, not counted as a fifth
independent identity. All initial reviews were source-based. None establishes
actual client compatibility.

## Reference research and principles

Public primary project pages and screenshots were inspected on 2026-11-07.
These are established projects with substantial use, not a ranked endorsement.
Their release listings do not prove QuestWeaver integration or Forever behavior.
No source code, artwork, textures or complete layout was copied.

| Reference | Observed principle | Application here |
| --- | --- | --- |
| [Kaliel's Tracker project](https://www.curseforge.com/wow/addons/kaliels-tracker), [gallery](https://www.curseforge.com/wow/addons/kaliels-tracker/gallery) | Quest titles stand above subordinate objectives; explicit section headers; project documents bounded height and scrolling. | Retain parent names alongside task labels, order stops visibly, bound variable content and expose overflow. No action buttons or tracking integrations imported. |
| [Syling Tracker project](https://www.curseforge.com/wow/addons/sylingtracker), [gallery](https://www.curseforge.com/wow/addons/sylingtracker/gallery), [primary repository](https://github.com/Skamer/Syling-Tracker) | Screenshots separate quest groups and objectives into readable blocks; project describes automatic scrolling when content exceeds tracker height. | Use spacing and named actions to separate groups; make all current tasks accessible without expanding the window indefinitely. No framework dependency or item automation added. |
| [ElvUI project](https://tukui.org/elvui), [default layout screenshot](https://tukui.org/images/screenshots/default/Default-ClassicTheme-TankDPS.jpg), [primary repository](https://github.com/tukui-org/ElvUI) | Repeated dark surfaces, restrained borders and aligned frame edges create consistency across dense information. | Use a neutral near-opaque panel, consistent insets and native controls; let typography and explicit action labels provide hierarchy. No full UI replacement or global skinning. |

## Direction considered and chosen

1. **Parchment journal:** strong fantasy identity, but textures and decorative
   framing consume room and complicate consistent contrast. Rejected for this pass.
2. **Minimal floating overlay:** low clutter, but legibility depends on the scene
   and grouping/status controls need another home. Rejected for reliable reading.
3. **Restrained native dark panel:** chosen. Warm-white body text, readable native
   fonts (minimum 13 logical points), gold action/forecast headings, neutral border,
   consistent spacing, explicit labels and progressive disclosure through scrolling.

The immediate action is separate from the details and full forecast. Compact
mode omits the redundant NEXT eyebrow and caps its task viewport to limit world
occlusion; all members remain scrollable. Expanded mode retains the current stop
and a complete numbered route, including projected trips. This intentionally
repeats current-trip context, with a space cost. Native buttons remain familiar;
no custom artwork is needed.

## Implemented behavior

- Compact/expanded trackers use flowing measured text with bounded current and
  route scroll areas. Destination, navigation status and primary controls sit
  outside task overflow. A conditional scroll cue makes hidden detail explicit.
- Parent quest titles remain attached to distinct task labels and known progress.
  All members, notices and quest hints are reachable. Group headings distinguish
  pickups, objectives, returns, bag acceptance and optional drop opportunities.
- Quest IDs and repeated per-member coordinates are removed from normal route
  text. Coordinates appear once per stop. Estimated totals remain labeled.
- Version/development identity and zone context have separate space. Named
  Details/Compact/Hide controls and tooltips explain recovery and slash commands.
- Lock/Unlock retains title-only movement. Blank panel space is click-through;
  scrolling and intentional controls receive input. Position migration is kept,
  normalized coordinates account for addon scale, and invalid numbers recover.
- Size cycles 80–130% as a new optional saved `uiScale` preference. Effective
  scale fits measured content to available UIParent space without modifying global
  UI settings. Feedback separately fits the screen and can be moved by its title;
  it also refits while open when the tracker is hidden and TomTom is absent.
- Missing TomTom displays Auto: unavailable while retaining the saved preference.
  Waypoint is disabled for invalid/absent destinations and item acceptance. Manual
  native fallback validates the destination, guards optional APIs and acknowledges
  a pin or coordinates. Automatic TomTom ownership logic is unchanged.
- Loading, waiting, unavailable-area and empty plans have explicit status headings;
  unresolved quests and zone handoffs retain their existing notices without fake
  coordinates or completion. No route stage is advanced by the UI.
- Feedback has labeled short-note entry, local save/mark confirmation, separate
  export selection, two-step clear/cancel and focus release on close. Draft notes
  survive closing. Export edits do not change stored feedback. Existing private
  feedback schema, sequence counters, ring and disk-save policy are preserved.

Planner algorithms, catalogues, readiness, route ordering, saved skip/pin/mode/
profile/budget/Auto preferences and TomTom-owned waypoint behavior are unchanged.
Reset choices deliberately keeps the prior restore semantics (clear skips and
pin), now described by its tooltip. A grouped Skip names its one affected quest
in a tooltip and never abandons anything. Feedback capture tag remains
`0.2.0-route-feedback-8`, identifying the unchanged planner/capture implementation;
the UI development version is separately visible in the tracker and manifest.

## Before/after evidence

One read-only screenshot of the running approved build-8 compact tracker was
observed. It showed duplicated single-quest text and a fixed blank heading gap.
No click, game command, character action, restart or installation occurred.
The private game screenshot was not saved into the public repository.

[Preview reproduction guide](../scripts/UI_PREVIEW.md) describes the frame-trace
harness. It executes baseline/current UI.lua with synthetic data and serializes
actual text, anchors, dimensions, colors and visibility for an offline renderer.
Ignored `build/ui-preview/` contains before/after PNGs, per-panel crops and a
comparison image. The baseline is `593f879`. Fifteen fixtures cover grouped work,
pickups/returns, item acceptance, long synthetic localized text, missing locations,
missing TomTom, loading, empty plans, zone handoff, feedback and an 800×600 viewport.
The invalid-target fixture is a defensive test; the baseline can error and that
failure is labeled, not fabricated as a successful screen. Missing-location
notices beside a valid plan are distinguished from a plan with no destination.

These previews are **offline simulations, not game screenshots**. Font metrics,
button art, native scrollbars, z-order, hit testing and scaling are approximated.
They support source geometry/content review, not a claim of actual client rendering.
Images and traces remain ignored and are excluded from public commits/packages.

## Final independent review and resolution

- [Visual final](reviews/visual-final.md): reviewer did not implement design.
  Missing-location evidence corrected; explicit overflow hint added; compact
  footprint reduced following the review. Final regeneration includes these fixes.
- [Gameplay final](reviews/gameplay-final.md): reviewer authored the synthetic
  harness but not the UI. Export wheel bug identified and fixed with regression.
- [Accessibility final](reviews/accessibility-final.md): reviewer authored tests
  but not the design. Technical byte-count copy replaced with ordinary wording.
- [WoW final](reviews/wow-final.md): reviewer did not implement layouts, but
  implemented the separately scoped guarded native fallback after its blind review.
  Lead review checked validation, pcall boundaries, no-op item/empty behavior,
  transient acknowledgment and preservation of manual-only navigation.

Other final findings resolved: malformed saved scale click, final measured-height
fitting, stale manual acknowledgment, hidden-tracker feedback refitting and
accidental export editing. The consolidated test result in VALIDATION.md supersedes
intermediate counts in the review records. No actionable source finding remains
open; the following limitations require actual client playtesting.

## Limitations and short playtest checklist

No new UI is installed. After a separately authorized installation:

1. Confirm **v0.2.0 | UI dev 1**; check both layouts at normal and enlarged size,
   small window/global UI scale, long quest names and four-member objective stops.
   Scroll all details and forecasts; destination/buttons must stay readable.
2. Drag the unlocked title, lock it, switch layout/size, hide/show, and reload.
   Confirm reachable position and retained preferences; use `/qw resetposition`
   if necessary. Check world clicks outside interactive regions.
3. Accept and turn in quests manually. Check grouped pickups/objectives/returns,
   individual task progress, timed warnings, missing locations, loading, empty
   plans and supported/unsupported zone handoffs. Compare ordering with build 8.
4. Check Auto on/off and manual Waypoint with/without TomTom. Existing unrelated
   TomTom points/profile/manual arrow choices must survive; errors should leave
   a useful status. Never infer quest completion from arrival.
5. Save a Unicode note/blank marker; verify confirmation and clear/cancel. Select
   and copy a long export; wheel-scroll it, close/reopen the draft, and ensure
   typing focus returns to gameplay. Resize while feedback alone is open.
6. Reload/log out, then request manual saved-feedback readback. Verify original
   preferences/history remain. Keep screenshots and exports private.

Actual native font wrapping, CJK glyph coverage, button/scroll hit targets,
combat/focus/click-through, global UI scaling and SavedVariables persistence are
unverified. Automatic fitting may make text too small on unusually small screens;
the new panel is not a full localization or keyboard-navigation implementation.
No accessibility compliance certification or terrain-safe navigation is claimed.
