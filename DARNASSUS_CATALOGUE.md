# Initial Darnassus catalogue

Reviewed 2026-11-07. Map 1457 / AreaTable 1657 has 11 initial handoff/city records.
This covers incoming Teldrassil deliveries and useful follow-ups, not every city
class/profession quest. City percentages remain separate from forest percentages.
The active catalogue switches automatically when the map changes.

## Evidence and availability

[Zephras's city record](https://zephras.com/forever/enUS/zone/1657/) confirms map
and area IDs, but publishes no NPC sightings. The city reference points below
are explicitly player-observed ForeverDB positions. They are supporting records,
not new local verification; Rellian patrols. Live current-stage points override
reference positions. Static XP remains estimated because observed rewards and
cache base XP can differ. No guide route/prose or database dump is bundled.

| ID | Record / city handling | Source |
| --- | --- | --- |
| 922 | Incoming accepted-only Rellian delivery; reference38.4,21.4 | [Return sighting](https://foreverdb.net/quest/922-rellian-greenspyre), [Rellian position](https://foreverdb.net/quest/923-tumors). Return sightings vary slightly because he moves. |
| 935 | Incoming accepted-only Crown delivery; Fandral34.8,8.9 | [Observed record](https://foreverdb.net/quest/935-crown-of-the-earth). Reference minimum1 affects no speculative pickup; observed XP1100 is estimated. |
| 940 | Incoming accepted-only Teldrassil delivery to Fandral | [Observed record](https://foreverdb.net/quest/940-teldrassil). Reference base XP220 versus observed440; live reward takes precedence. |
| 98391 | Incoming accepted-only Sisterhood delivery; Aquinne29.1,45.6 | [Observed record](https://foreverdb.net/quest/98391-the-sisterhood-of-elune), [cache](https://zephras.com/forever/enUS/quest/98391/). No assumed priest-only gate. |
| 923 | Tumors pickup/return at Rellian after922; work in Teldrassil | [Observed chain and giver](https://foreverdb.net/quest/923-tumors). No forest objective copied onto the city map. |
| 2498 | Return to Denalan after923; city pickup, Teldrassil recipient | [Observed record](https://foreverdb.net/quest/2498-return-to-denalan). Recipient forest coordinates are deliberately absent from this city pack. |
| 2519 | Temple of the Moon after98391; Aquinne→A'moora36.4,86.1 | [Observed positions](https://foreverdb.net/quest/2519-the-temple-of-the-moon), [cache chain](https://zephras.com/forever/enUS/quest/2519/). Simple within-city delivery. |
| 2518 | Tears of the Moon after2519; work in Teldrassil, return A'moora | [Observed record](https://foreverdb.net/quest/2518-tears-of-the-moon), [cache](https://zephras.com/forever/enUS/quest/2518/). Predecessor may be a skippable breadcrumb; actual offer overrides conservative gate. |
| 2520 | Sathrah's Sacrifice after2518; city temple action | [Observed record](https://foreverdb.net/quest/2520-sathrahs-sacrifice), [cache](https://zephras.com/forever/enUS/quest/2520/). No guessed precise fountain interaction point. |
| 952 | Grove of the Ancients after940; Fandral pickup, Darkshore recipient | [Observed record](https://foreverdb.net/quest/952-grove-of-the-ancients). No Darkshore coordinates inserted into city. |
| 98067 | Eyes of the Sentinels; actual-offer-only | [Cache](https://zephras.com/forever/enUS/quest/98067/). Current giver/recipient positions unpublished, so no advance NPC pin. |

Incoming records never schedule acceptance in the wrong zone. Known city pickups
say Check availability and respect prerequisites/skips/capacity. Unknown work is
pickup-only until accepted. An observed offer supersedes conservative gates.

For an accepted stage on another map, the UI names that area when known and
waits for travel/current-zone data. It never projects a foreign objective and
return as if both happened inside the city. No portal route, loading transition,
fountain action or character movement is automated. Once the correct catalogue
is active, live stage/return data drives planning. Feedback includes destination
map IDs to distinguish handoffs from missing coordinates.

The main tracker shows version/build/current catalogue in both compact and
expanded layouts; expected label for this package is **v0.2.0 | build 8**.
Actual city rendering, coordinates, transitions and quest availability await
user playtesting after installation and reload.
