# Offline UI frame previews

This harness executes the real `UI.lua` against a small synthetic frame API and
serializes text, anchors, dimensions, visibility and colors. The Pillow renderer
uses those traces rather than a separately authored layout. It never loads the
game, Runtime, SavedVariables, private feedback, account data or character data.
All generated material stays under ignored `build/ui-preview/`.

With Lua 5.1 and Python/Pillow available, from the repository root:

```sh
mkdir -p build/ui-preview
git show 593f879:QuestWeaver/UI.lua > build/ui-preview/baseline.lua
lua -e 'QW_PREVIEW_SOURCE="build/ui-preview/baseline.lua"; QW_PREVIEW_OUTPUT="build/ui-preview/before.json"; dofile("scripts/ui_preview.lua")'
lua -e 'QW_PREVIEW_SOURCE="QuestWeaver/UI.lua"; QW_PREVIEW_OUTPUT="build/ui-preview/after.json"; dofile("scripts/ui_preview.lua")'
python3 scripts/render_ui_preview.py build/ui-preview/before.json
python3 scripts/render_ui_preview.py build/ui-preview/after.json
```

The implementation session used an existing embedded Lua 5.1 runtime and an
isolated Pillow installation. These are execution-environment substitutions,
not dependencies added to the addon.

The fifteen fixtures cover compact/expanded grouped objectives, grouped pickups
and returns, item acceptance, four-member
stops, multiple objectives, synthetic German/French long names, timed warnings,
a missing-location-only plan, a notice for another quest while the current
destination remains valid, a defensive invalid-target state, absent TomTom,
world loading, no eligible plan,
a cross-zone handoff notice, local feedback and an 800×600 viewport.

Standalone PNGs retain the viewport. Contact sheets crop to the panels for
comparison. Panel crops are also saved separately. Rendering `after.json` after
`before.json` produces `before-after-comparison.png` for compact, expanded and
feedback states. The baseline source is the approved main commit preceding this
branch. After traces should be regenerated after UI changes.

The defensive invalid-target fixture is deliberately outside normal planner
output. The baseline throws while formatting its destination; that error is
preserved visibly in the evidence and console. The new UI can display the
unavailable-location state without throwing. An expected baseline error must
not be confused with a successful baseline render for that fixture.

## Evidence limits

These are **offline simulations, not game screenshots**. Fonts and wrapping,
Blizzard templates, textures, z-order, scrolling, focus, clamping and inherited
scaling are approximated. The harness provides evidence of actual source text,
visibility, anchors and assigned dimensions under synthetic data. It cannot
establish Forever rendering, correct client API support, combat behavior,
mouse/keyboard behavior or SavedVariables persistence. In particular, UI scale
must still be checked in the actual client; the small-viewport fixture checks
available layout space, not a faithful UI-scale implementation.
