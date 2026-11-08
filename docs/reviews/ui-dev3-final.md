# Independent final review: UI dev 3

The reviewer inspected the planner and feedback changes without implementing
either production module. The reviewer authored `tests/stability_test.lua` and
independently ran the feedback tests authored by another contributor. Synthetic
fixtures and ignored local probes were used; no raw SavedVariables were executed,
no private quest snapshots were copied into public tests or this report, and no
game action or installation was performed by this reviewer.

## Planner stability

The previous bounded group is independently rebuilt from current quest records,
including records outside the sixteen-candidate shortlist, before score-based
retention is evaluated. This repairs the search omission that previously made a
valid near-best plan invisible to the existing 85% retention comparison.

The review verified canonical bounded identity parsing, current availability,
upfront quest-log capacity, and prerequisite projection only through resolved
members of the same group. Missing, skipped, done, failed, or unusable members
cannot be carried forward. Unknown stages do not manufacture chain completion.
Urgent deliveries and actually nearby ready returns still exit before elective
retention, while current pins retain priority. Including a validated prior group
in the fastest available score baseline is appropriate because that group is an
actual available choice, rather than an abandoned or unvalidated route.

Seven focused Lua 5.1 regressions passed. The controlled search-valley test uses
real route geometry/precedence with synthetic ranking scores: the old planner
fails because greedy insertion cannot discover the valid prior group, while the
fix keeps the same recommendation across twenty unchanged refreshes. Other cases
cover release beyond the existing margin, stale/invalid groups, capacity and
prerequisites, priority overrides, malformed identities and shortlist omissions.
The score fixture is deliberately synthetic and does not claim client timing.

## Feedback attribution and privacy

The new `recently_recommended` relation distinguishes short-lived historical
pickup evidence from a current-plan match. Actual planned pickups supply history;
an NPC offer alone does not. Immediate next/later matches take precedence.
Explicit event and snapshot-fallback paths use the same attribution rules.

History is transient, bounded to 128 quest IDs, limited to ten seconds and an
observation-count backstop, and invalidated on map/load/clear/reload/unavailable
clock boundaries. Skipped, done, failed and expired entries cannot provide recent
credit. Acceptance consumes its history. Stored evidence is numeric, sanitized,
and keeps source plan/location/settings plus age and prior relation; it adds no
character/account name, automatic quest prose or chat capture. Existing ring
entries, build tags and monotonic review sequence/session identifiers survive.

An initial review found that retaining a second full active-quest snapshot for
each attribution could inflate saved data despite the bounded text export.
Resolved: source evidence now strips redundant active/offered lists both when
cached and during sanitization. The event itself still retains its existing
bounded snapshot. The reviewer independently reran all 26 feedback tests after
that correction; all passed, including the maximum-evidence/export-bound test.

A final review also exercised a pickup after the eighth forecast step and raised
the truncated source-history issue for correction before installation. Resolved: caching now examines the bounded full 24-step route. Pickups beyond
the ordinary eight-step report context retain a sanitized matching-step excerpt
and the original source-step index, which is exported explicitly. The reviewer
verified this code and independently reran all 27 feedback tests, including
ninth- and twenty-fourth-step regressions. No unresolved actionable source issue
remains in the reviewed planner/attribution changes.

## Evidence limits

Local tests and source review do not establish actual Forever API delivery,
frame/input behavior, or disk persistence. The new capture tag distinguishes
these planner/attribution changes; old observations remain historical evidence,
not automatic training or proof of optimal travel. The lead agent's final
validation record is authoritative for the full post-review suite and install
readback. A focused client playtest should check unchanged-state route stability,
legitimate replanning after quest changes, recent pickup attribution following
NPC dialogue closure, loading/zone boundaries and saved feedback readback.
