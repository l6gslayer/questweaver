# Changelog

## 0.2.0 — Shadowglen trip planning

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
