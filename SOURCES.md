# Research and data boundaries

Reviewed 2026-11-07. External source descriptions are evidence about their own
projects, not proof of QuestWeaver compatibility in a particular game build.

- [TomTom official project](https://www.curseforge.com/wow/addons/tomtom) and
  [v4.4.1 release](https://www.curseforge.com/wow/addons/tomtom/files/9493883):
  current Forever support listing and navigation capabilities. Install separately.
  The official Source tab lists a CurseForge Git repository; its source could
  not be retrieved in this environment.
- [Historical TomTom author-documentation mirror](https://github.com/Pjort/TomTom/blob/master/README.md)
  and its TomTom.lua implementation: the AddWaypoint/RemoveWaypoint options
  contract (`crazy`, `cleardistance`, `persistent`, `source`) and ownership UID.
  This is historical supporting evidence, not an exact v4.4.1/Forever reference.
  Optional methods are checked at runtime and API calls are protected. No
  third-party code or assets are copied or bundled.

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
