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

## Current quest location API follow-up

- [Blizzard-generated quest log API documentation mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua):
  signatures for `GetNextWaypoint(questID)` returning map/x/y,
  `GetNextWaypointForMap(questID, uiMapID)` returning x/y, and
  `GetQuestsOnMap(uiMapID)`. The live branch is supporting documentation, not an
  exact Forever build reference. All reads are optional and protected.
- The locally installed TomTom v4.4.1-release `modules/poi.lua` independently
  uses next-waypoint reads followed by quest map positions. Inspected as local
  compatibility evidence only; no third-party implementation was copied.

## Nearby quests and item starts

- [Blizzard-generated container API documentation mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua):
  modern `C_Container.GetContainerItemQuestInfo` returns `ItemQuestInfo` with
  questID/isActive, alongside bag slot-count/item identity reads. A guarded
  legacy tuple fallback is supported; exact Forever behavior needs playtesting.
- [Fang of Githyiss quest record](https://zephras.com/forever/enUS/quest/97236/)
  and [item record](https://zephras.com/forever/enUS/item/277190/): community
  observations/game-file records identify quest 97236, item 277190, base level
  5 / 450 XP and Gilshalan's turn-in. These are supporting evidence, not local
  client verification. The user's cave-drop report independently confirms the
  item-started quest and Aldrassil return in their playtest.
- [Forever quest location listing](https://www.60.tools/quests/97236-fang-of-githyiss):
  Githyiss cave source 56.6, 26.3 and Gilshalan return near 57.8, 41.6. Starter
  locations and time estimates remain approximate; live client data takes
  precedence. No third-party database/code is bundled.
