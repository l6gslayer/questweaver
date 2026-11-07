# Research and data boundaries

Reviewed 2026-11-07. External source descriptions are evidence about their own
projects, not proof of QuestWeaver compatibility in a particular game build.

- [QuestieDB public API](https://github.com/Questie/QuestieDB/blob/master/docs/api.md):
  optional runtime `QuestDB.Get` and NPC/object spawn lookup contract.
- [QuestieDB quest schema](https://github.com/Questie/QuestieDB/blob/master/src/meta/questMeta.lua):
  requirement and prerequisite field meanings.
- [QuestieDB releases](https://github.com/Questie/QuestieDB/releases): matching
  Forever data package; install separately. QuestieDB is GPLv3; it is neither
  vendored nor redistributed in this MIT-licensed project.
- [Questie](https://github.com/Questie/Questie): quest-helper UI reference.
- [RestedXP](https://github.com/RestedXP/RXPGuides): guide-player research.
- [Guidelime](https://github.com/max-ri/Guidelime): modular guide research.
- [Questworthy](https://www.curseforge.com/wow/addons/questworthy): conceptual
  reference for explained XP/time/risk and gear-aware routing. No source or
  authored routes were copied.
- [Pawn](https://www.curseforge.com/wow/addons/pawn): stat-weight comparison
  reference; not bundled or integrated.

Starter quest IDs/names identify in-game content. Coordinates, XP and timing
constants in `Shadowglen.lua` are explicitly unverified estimates, authored as
a small starter baseline, not extracted from a paid guide. Confirm them in
Forever before treating this as a dependable speed-leveling route.
