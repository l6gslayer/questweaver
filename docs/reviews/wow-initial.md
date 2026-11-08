# Independent initial review: WoW implementation quality

This fourth, separate reviewer inspected approved `main` source (`UI.lua`,
`Runtime.lua`, `Navigation.lua`, `Feedback.lua`) without reading the other
critiques or the proposed design. Evidence below is source behavior, not actual
Forever rendering, input delivery or API verification. P1 means probable loss
of a core interaction/data; P2 means a material reliability or compatibility
problem; P3 means polish or an efficiency opportunity.

| Severity | Weakness and baseline evidence | Impact | Highest-value improvement |
| --- | --- | --- | --- |
| P1 | Feedback's Clear button invokes `FeedbackAction("clear")` immediately (`UI.lua:155–157`); `Feedback.Clear` replaces the retained entries and export (`Feedback.lua:283–289`). No undo/confirmation exists. | One adjacent-button misclick loses the private playtest history. | Add an explicit confirmation/cancel state in the panel. Do not modify the saved ring until confirmation. Keep this independent from route settings. |
| P2 | Manual native waypoint creation, setting and supertracking calls are unprotected (`Runtime.lua:270–272`), whereas TomTom integration uses `pcall`. The manual entry guard only excludes item acceptance (`262–264`), rather than validating destination coordinates as `Navigation.Destination` does. | An optional client API exception can terminate the button handler; missing or invalid targets can fail before any useful message. | Validate with the shared destination helper, guard each optional call and provide a concise visible result/failure. Preserve explicit manual activation and owned TomTom behavior. |
| P2 | `SavePosition` divides possibly unavailable frame coordinates by parent dimensions (`UI.lua:48–50`); `Place` accepts any Lua number, including NaN/infinity, and does not reject nonpositive screen dimensions (`52–61`). | Corrupt/mid-layout coordinates can persist invalid anchors or break position recovery. | Require finite coordinates and positive parent bounds; retain the last good position on an unavailable measurement and recenter invalid saved positions. Test normalized and legacy positions. |
| P2 | Frames are always 360×190/500×640, while feedback is 620×500 (`UI.lua:70,136`); clamp-to-screen does not resize the frame. No size/display-change handler recalculates bounds. | At large UI scales or small effective viewport sizes, controls/content remain outside the reachable screen even though the frame is clamped. | Bound dimensions to the current effective screen, preserve a usable scroll viewport, and rerun layout on relevant size changes. Keep positions normalized and do not change global UI scale. |
| P2 | The current detail region is capped independently of its text (`UI.lua:213–215`), and heading/status sizes are fixed. Only the later route has a ScrollFrame. | Wrapping can hide action information or collide with the footer; overflow is not accessible in the gameplay layout. | Put all variable current content in a bounded scroll region and keep permanent controls outside it. Reset scroll when the action changes; clamp scroll when content shrinks. |
| P2 | Saving a feedback note clears its text but does not clear keyboard focus; the panel's Close handler only hides the frame, with no explicit focus cleanup (`UI.lua:148–150,158`). Escape only clears individual editor focus (`147,166`). | Keyboard input can remain captured during play or after a note action; actual hidden-editor behavior is client-dependent. | Clear editor focus after saving, on hiding and on explicit cancellation. Verify actual game keyboard behavior separately. |
| P2 | Auto's displayed state is only the saved preference, even when TomTom is unavailable (`UI.lua:184`). `Navigation.Status` then says manual waypoint is available even if only chat coordinates can be printed (`Navigation.lua:87–92`, `Runtime.lua:270–275`). | The controls imply working guidance despite missing dependencies or failed APIs. | Distinguish automatic preference from readiness, expose a readable unavailable/error state, and accurately describe the manual fallback without silently overwriting settings. |
| P3 | The top-level tracker enables mouse input across its complete rectangle (`UI.lua:83`), including unused padding. | A decorative overlay can swallow world clicks while the player is trying to interact through empty space. | Restrict mouse interception to intentional controls, the scroll viewport and the unlocked drag region. Verify wheel/drag behavior in the client. |
| P3 | Display version/build is parsed from the feedback capture tag (`UI.lua:179–180`). | A purely visual development build can look identical to the approved release, while changing the capture tag just to label UI conflates two identities. | Give the UI a distinct development identity/manifest version. Keep feedback history and schema intact; if its capture identity changes, retain old record labels. |
| P3 | Every ordinary UI refresh reconstructs all route text, measures its height and updates every widget (`UI.Render`; `Runtime.lua` one-second OnUpdate). The full route remains bounded, so this is not demonstrated performance failure. | Repeated formatting/layout work occurs even when only navigation status changes. | Avoid per-frame work and keep the existing bounded one-second cadence. Cache only if profiling warrants it; prioritize reliable layout over speculative optimization. |

## Priority and safeguards

Address protected feedback clearing, bounded readable regions and safe manual
waypoint handling first. Then harden position/display changes and focus cleanup,
followed by development identity and navigation wording. Keep the planner,
quest catalogues, automatic player-control restrictions, waypoint ownership and
SavedVariables migrations unchanged. A source review and stubbed regressions
cannot establish combat safety, native edit-box focus, font metrics or API
availability in the actual Forever build.
