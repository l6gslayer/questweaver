# QuestWeaver contributor instructions

- Public repository: never add machine-specific absolute paths, personal names,
  email addresses, credentials, account/character identifiers, game saves, logs,
  screenshots, or copied parent-workspace instructions.
- Lua 5.1 compatibility. Keep the planner independent of game globals.
- Keep addon files inside `QuestWeaver/`, matching `QuestWeaver.toc`.
- Run `lua tests/run.lua` and `python3 scripts/package.py` before release.
- QuestWeaver targets WoW Forever. Verify optional APIs in the actual client;
  mocked tests do not establish in-game compatibility.
- Do not install into a live game or restart it without a relevant user request.
- Starter coordinates, XP, timings and travel estimates are unverified baselines.
  Do not present them as measured, terrain-aware, or globally optimal.
- Do not vendor QuestieDB or other third-party datasets without reviewing licenses.
- Preserve player control: never automatically abandon quests, select rewards,
  equip gear, alter bindings, or move the character.
