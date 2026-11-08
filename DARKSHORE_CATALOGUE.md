# Initial Darkshore catalogue audit

Reviewed 2026-11-07. **28 records** on map 1439 / AreaTable 148: eight advance
pickup candidates with player-confirmed pickup locations, eighteen actual-offer
records, and two owned-item starters. Registration does not select the catalogue.
This is a useful initial subset, not exhaustive zone/class/profession coverage.

Facts were independently curated from the linked records. No quest prose,
leveling route, database dump, third-party code, Classic spawn arrays or scoring
tables are copied. Public sightings are supporting evidence, not local in-game
verification. Sources differ in coverage and sometimes use Classic fallback
fields: only explicitly observed positions support the initial advance pickups.

## Planning boundaries

Known pickups say **Check availability** until the client offers them. Most work
is pickup-only before acceptance; there are no invented objective farming pins
or chain unlocks from mere pickup. After acceptance, the live current-stage
location drives guidance. Missing current destinations remain quest-log notices.

Recorded minima and rewards are catalogue references, not assertions about every
character or build. ForeverDB reward amounts were observed at particular levels,
so every static XP value here stays estimated until client XP replaces it.
Unknown minima use an inert minimum 1 placeholder only on offer-only records.
Actual offers/accepted state remain authoritative subject to existing safeguards.

No static coordinates from Ashenvale, Ironforge, Stormwind or another map are
inserted into Darkshore. Foreign-zone delivery stages require a valid client
projection or later catalogue support. Escorts/defences and elite work stay
manual/offer-only. No item is automatically used and no quest is accepted for you.

## Advance pickup candidates

The first source in each row explicitly marks the cited pickup position as
**seen in Forever**. Numbers are factual references, not a copied route order.

| ID | Record / minimum | Pickup and known return | Evidence / prerequisite |
| --- | --- | --- | --- |
| 983 | Buzzbox827 /7 | Wizbang37.0,44.1 →box36.7,46.3 | [Observed record](https://foreverdb.net/quest/983-buzzbox-827), [Forever series](https://www.wowhead.com/forever/quest=983/buzzbox-827). Reward850 observed at12/13; no static crawler area is copied. |
| 1001 | Buzzbox411 /7 | box36.7,46.3 →box42.0,28.7 | [Observed record](https://foreverdb.net/quest/1001-buzzbox-411). Earlier983 is explicitly confirmed; observed reward1150. |
| 984 | How Big a Threat? /10 | Terenthis39.3,43.5, both ends | [Observed record](https://foreverdb.net/quest/984-how-big-a-threat). Reward750 is observed, not verified base XP. |
| 985 | How Big a Threat? /10 | Terenthis39.3,43.5, both ends | [Observed record](https://foreverdb.net/quest/985-how-big-a-threat). Earlier984 confirmed; reward975 observed. |
| 3524 | Washed Ashore /11 | Gwennyth36.6,45.6, both ends | [Observed record](https://foreverdb.net/quest/3524-washed-ashore). Reward675 observed; beach bones are an objective item, not a bag starter. |
| 4681 | Washed Ashore /11 | Gwennyth36.6,45.5–45.6 | [Observed record](https://foreverdb.net/quest/4681-washed-ashore). Earlier3524 confirmed; reward975 observed. Other beached-object prerequisites are marked Classic on this source and are not imported. |
| 4811 | The Red Crystal /12 | Glynda37.7,43.4, both ends | [Observed record](https://foreverdb.net/fr/quest/4811-the-red-crystal). Reward490 observed; live work point preferred. |
| 4813 | The Fragments Within /12 | crystal47.3,48.7 →Glynda | [Observed record](https://foreverdb.net/quest/4813-the-fragments-within). Earlier4812 confirmed; reward975 observed. Crystal is an object, not a dropped bag starter. |

## Conditional chain identities

| IDs | Handling | Evidence / remaining uncertainty |
| --- | --- | --- |
| 4812 | As Water Cascades after4811; actual offer | [Forever record/series](https://questing.wiki/wow-forever/quests/4812/), [reference coordinates](https://senseos.gg/wiki/wow-forever/quests/4812/as-water-cascades/). Current observed pickup details are incomplete; supplied tube is not a starter. |
| 1002 →1003 | Later Buzzboxes, after1001 | [Forever series983](https://www.wowhead.com/forever/quest=983/buzzbox-827). XP/minimum/positions were not independently established, so offer-only. |
| 954 →955 →956 →957 | Bashal'Aran | [Forever series954](https://www.wowhead.com/forever/quest=954/bashalaran). Minimum/XP and current positions remain unresolved; no Classic route is imported. |

## Current game-cache records

Zephras's [Darkshore inventory](https://zephras.com/forever/enUS/zone/148/) exposes
only twelve quest records and no NPC sightings at review. These entries use
individual game-cache level/minimum/XP facts, generally from build 1.60.1.70790
or its subsequently published 70862 record. Missing giver positions mean actual
offer-only, even when a Classic location is familiar.

| ID | Record | Level/minimum/XP | Evidence and limits |
| --- | --- | --- | --- |
| 2118 | Plagued Lands | 14/10/980 | [Cache](https://zephras.com/forever/enUS/quest/2118/). Capturing the bear requires manual quest-item use; no automation. |
| 2138 | Cleansing of the Infected | 16/10/1150 | [Cache](https://zephras.com/forever/enUS/quest/2138/). Explicit previous2118. |
| 2139 | Tharnariun's Hope | 18/10/1350 | [Cache](https://zephras.com/forever/enUS/quest/2139/). Narrative follows bear work but no explicit previous gate was established. |
| 5713 | One Shot. One Kill. | 15/10/1050 | [Cache](https://zephras.com/forever/enUS/quest/5713/). Defence event, then Ashenvale recipient; no foreign coordinates. |
| 97894 | Business in Auberdine | 17/13/0 | [Cache](https://zephras.com/forever/enUS/quest/97894/). Starts outside Darkshore; current handoff required. |
| 98042 | It's All Fun and Games Until... | 17/12/1250 | [Cache](https://zephras.com/forever/enUS/quest/98042/). Describes taking a page from Twilight Tome, not a verified bag starter. Peerless Eye is an objective item. |
| 97926 | Making Do | 17/13/630 | [Cache](https://zephras.com/forever/enUS/quest/97926/). Foreign predecessor Expanding Horizons remains outside this initial catalogue; actual offer required. |
| 2098 | Gyromast's Retrieval | 20/14/1550 | [Cache](https://zephras.com/forever/enUS/quest/2098/). Key fragments are objectives, not starters. |
| 2078 | Gyromast's Revenge | 20/14/1150 | [Cache](https://zephras.com/forever/enUS/quest/2078/). Explicit previous2098; Elite with additional risk. |
| 98013 | Swelling Forces | 20/12/1550 | [Cache](https://zephras.com/forever/enUS/quest/98013/). Naga work without a guessed objective area. |
| 98025 | WANTED: Jai'vhanel | 13/10/1150 | [Cache](https://zephras.com/forever/enUS/quest/98025/). Bounty object location unpublished; offered-only, not assumed Murkdeep Classic quest. |

## Owned-item starters

| Quest / starter | Handling | Evidence / uncertainty |
| --- | --- | --- |
| 98028 /279275 Clouded Water Globe | Manual owned-item acceptance, then Onu if current stage supports it | [Quest cache](https://zephras.com/forever/enUS/quest/98028/), [starter tooltip](https://zephras.com/forever/enUS/item/279275/). Level21/min17/base1650. Cache identifies the starter but publishes no drop source; do not promise a Baron spawn or drop rate. Onu43.5,76.3 is a [community coordinate reference](https://forever-xp.com/quests/zone/darkshore/), not a local sighting. |
| 968 /5352 Book: The Powers Below | Manual owned-item acceptance; recipient in Ironforge | [Starter tooltip](https://www.wowhead.com/forever/item=5352/book-the-powers-below), [quest/map reference](https://senseos.gg/wiki/wow-forever/quests/968/the-powers-below/). Level20/min10, XP unestablished here. No guaranteed drop/farming stop or imported Ironforge coordinate. |

This is not an exhaustive drop audit. Beached creatures/turtles, bounty boards,
Twilight Tome and Buzzboxes are object interactions, not automatically bag-item
starters. More Auberdine branches, Grove/Althalaxx chains, class/profession
conditions and Forever additions await evidence-qualified expansion.
