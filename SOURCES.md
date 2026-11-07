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

## Shadowglen coverage audit — 2026-11-07

This bounded audit compared the 13 existing entries with Forever quest/zone and
item records. Generic zone inventories are not exhaustive: some omit Forever
additions or categorize local quests under Teldrassil, race or class instead.
No licensed quest dataset, guide text or authored leveling route was copied.

| Quest / item | Evidence and handling |
| --- | --- |
| Nature's Call 97977 | [Observed quest cache record](https://zephras.com/forever/enUS/quest/97977/): Tarindrella start/return near 57.7,45.1, four Gnarlpine Totems, base 250 XP. Added with actual NPC-offer/accepted evidence. |
| Nature's Call objective area | [Community observations](https://foreverdb.net/quest/97977-natures-call) and [location listing](https://www.60.tools/quests/97977-natures-call) differ on area and prerequisite metadata. No objective coordinate or exact prerequisite is hard-coded; live client destination required. Totem 279082 is an objective item, not a starter. |
| The Goddess Provides 97979 | [Observed quest record](https://zephras.com/forever/enUS/quest/97979/) and [Forever listing](https://www.60.tools/quests/97979-the-goddess-provides): Shanda near 59.2,40.5, base 40 XP, Elune's Light/Shadowmeld. Added for observed offers/accepted quests, with Night Elf gating and no assumed priest restriction. |
| Welcome! 5842 / voucher 14648 | [Quest](https://www.60.tools/quests/5842-welcome) and [item](https://www.60.tools/items/14648-shadowglen-gift-voucher) records describe the conditional Collector's Edition voucher. Owned-item/accepted evidence only; no farming or entitlement assumption. Client return location required. |
| Class introductions 3116-3120 | Simple, Etched, Encrypted, Hallowed and Verdant Sigils were missing at audit time and are now included with observed-offer/class/race gates. [Forever index](https://www.oraclenewsnetwork.com/quests) lists them separately. Their inherited prerequisite metadata is not asserted as a live Forever fact; actual offers and accepted state provide availability evidence. |
| Crown of the Earth 928 / Dolanaar Delivery 2159 | [Crown](https://www.60.tools/quests/928-crown-of-the-earth) and [Delivery](https://www.60.tools/quests/2159-dolanaar-delivery) leave Shadowglen for Dolanaar. Originally recorded as exit-trip scope; now explicitly included with the requested corridor expansion. |

Fang of Githyiss remains the substantiated ordinary local mob-drop quest in this
audit. Failure to find another is not proof that none exists in the live client.
Community records are supporting evidence, not this project's in-game tests.

The [Blizzard-generated quest API documentation mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)
documents `ReadyForTurnIn(questID)`. The [gossip API mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/GossipInfoDocumentation.lua)
documents available quest rows used for guarded NPC-offer reads. These mirrors
are not an exact Forever build reference. No selection or acceptance API is used.

## Class introductions and Dolanaar extension — 2026-11-07

- Class introduction records: [Simple Sigil 3116](https://www.60.tools/quests/3116-simple-sigil),
  [Etched Sigil 3117](https://www.60.tools/quests/3117-etched-sigil),
  [Encrypted Sigil 3118](https://www.60.tools/quests/3118-encrypted-sigil),
  [Hallowed Sigil 3119](https://questing.wiki/wow-forever/quests/3119/),
  [Verdant Sigil 3120](https://www.60.tools/quests/3120-verdant-sigil).
  Supporting listings give Ilthalaine near 58.7,44.3, class-specific trainers
  in/around Aldrassil, and level-1 / 40-XP baselines. Parts of these listings
  inherit Classic details, so pickup requires a real NPC offer rather than an
  asserted prerequisite 456. Matching class/race fallback gates do not override
  an already accepted quest. No guide route or dataset is copied.
- [Crown of the Earth 928](https://www.60.tools/quests/928-crown-of-the-earth):
  fallback Tenaron 59.1,39.5 to Corithras 56.1,61.7, following quest 921, base
  225 XP. [Dolanaar Delivery 2159](https://www.60.tools/quests/2159-dolanaar-delivery):
  fallback Porthannius 61.2,47.6 to Innkeeper Keldamyr 55.6,59.8, base 110 XP.
  These are supporting metadata, not new measurements in the actual client.
  Live location and XP reads take precedence; estimates remain labeled.
- Supplied sigils, vessel and delivery package are not starter items; the new
  entries intentionally have no itemStartID. Expanded map bounds are a product
  scope decision for this test build, not evidence of terrain-safe routing.
