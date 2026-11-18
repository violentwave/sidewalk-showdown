# Stages: assets, ambience, and stage select

Two stages are wired into the shared roster: **Everglades Gas-N-Go** and
**Bus Stop (Night)**. The match builds whichever `StageData.scene` the
front-end passes in; adding a stage is a scene + resource + roster edit, not a
`MatchRoot` code change.

## Gas-N-Go

| Property | Value |
|---|---|
| Source art | `art/source/Stages/GasNGo/` (read-only) |
| Runtime art | `game/art/stages/gas_n_go/` |
| Native canvas | 320x180, drawn at scale **1.0** (no resampling) |
| Scene | `game/scenes/stages/gas_n_go.tscn` |
| Data | `game/resources/stages/gas_n_go.tres` |
| Floor / bounds | `floor_y = 158`, `left_bound = 24`, `right_bound = 296` |
| Spawns | P1 x = 110, P2 x = 210 |
| Selector thumbnail | `gas_n_go_thumbnail.png`, 80x45 |

### Draw order

Bottom to top in the stage scene:

1. `Sky` — 320x180 gradient, opaque.
2. `Clouds/CloudA` and `Clouds/CloudB` — the authored 640x44 strip, two copies.
3. `Foreground` — 320x180 storefront/dirt layer with a transparent sky.
4. `SignText` — 105x30 lettering placed on the blank sign board at (145, 12).
5. `Gator` — 81x18 sprite at (140, 158).
6. `Mosquitoes/Mosquito1` and `Mosquito2` — 24x26 sprites with `z_index = 10`.
7. `StageAnimation` — logic-only node, no drawing.

`MatchRoot` adds the fighters after the stage, so they draw above the sky,
clouds, foreground, sign, and gator. The mosquito layer's positive `z_index`
keeps the insects above the fighters while their anchors and sine loops stay in
the upper sky (bottom edge under y = 100), clear of the fight area.

### Ambient animation

`game/scripts/stages/stage_animation.gd` runs in `_process`, not the 60 Hz
simulation. The stage root is `PROCESS_MODE_PAUSABLE`, so the pause menu freezes
ambience; hitstop is not a tree pause, so it keeps playing during hitstop. It
never reads combat state, rotates or scales a sprite, or allocates per frame,
and every position is snapped to a whole pixel.

- **Clouds:** the shared 640 px offset advances at **5 px/s**, then wraps with
  `fposmod`. The two copies are 640 px apart, so no visible cloud teleports.
- **Mosquitoes:** wingbeat frames flip at **8 fps** (`0.125 s`). Each insect
  traces a small, independent sine loop around its upper-sky anchor.
- **Gator:** two breathing poses over a **one-second** cycle, plus a random f3
  blink. The blink waits a random 2.5–6 s, holds f3 for 0.12 s, then restores
  the current breath frame. Randomness is a visual-only `RandomNumberGenerator`;
  it is never shared with the deterministic fight simulation.
- **Debug freeze:** enable `freeze_ambient` on the `StageAnimation` node in the
  remote inspector to hold every layer on its current frame.

### Regenerating the runtime art

```bash
python3 art/tools/prepare_gas_n_go.py
godot --headless --path game --import
```

The prep script validates only sizes, opaque/binary alpha, and the per-layer
palette budget — never picture content. It copies the source layers at native
resolution and derives the 80x45 thumbnail with an exact 4x box downsample of
the 320x180 preview. Rerunning it from unchanged sources is deterministic.

The Bus Stop selector thumbnail is produced separately because the match shows
a scaled, tinted region of a 1024x1024 night painting:

```bash
python3 art/tools/prepare_bus_stop_thumbnail.py
godot --headless --path game --import
```

It crops the source region actually visible in the 320x180 viewport
(`x 0..1024`, `y 224..800`), applies the scene's `(0.55, 0.55, 0.62)` modulate,
box-downsamples to 320x180, then takes the same exact 4x box downsample to
80x45.

## Stage select

The front-end flow is:

```
The Clip → mode select → character select → stage select → match
```

`game/scenes/menus/StageSelect.tscn` reads `MatchRoster.stages` and appends
`RANDOM` as the **last** entry. It shows each stage's 80x45 thumbnail, name, and
description.

- **Input:** P1 or P2 actions move the shared cursor (A/D, D-pad, or stick);
  P1's J/click, P2's pad X, or `ui_confirm` confirms. Backspace on the keyboard
  returns to character select with the same fighters selected.
- **Back convention:** the stage screen is created deferred after character
  select and returns deferred, so the keypress that leaves one screen cannot
  immediately confirm or back out of the next.
- **Stable identity:** the flow stores `StageData.id` (`gas_n_go`,
  `bus_stop_night`), never a roster index. Returning from a match restores the
  last stage by id.
- **RANDOM:** resolved on the selector, before the match exists, with a
  non-gameplay `RandomNumberGenerator`. The concrete stage id is recorded in
  `Main.last_stage_id` (and `StageSelect.resolved_stage_id`) so the match,
  logs, and future replay metadata see the real stage rather than a sentinel.
- **Fallback:** a directly instantiated `MatchRoot` with no stage falls back to
  `roster.stages[0]`. If the roster cannot supply two fighters and a stage with
  a scene, `_resolve_selections()` returns false and `_ready()` stops without
  instantiating anything.

See `game/tests/stage_select_test.gd` for the selector, ambience, and invalid
roster coverage.

## Adding another stage

1. Export the layered 320x180 art into `game/art/stages/<stage_id>/` and derive
   an 80x45 thumbnail. If the source is a single large painting, document the
   visible crop and any in-scene tint, as the Bus Stop script does.
2. Create `game/scenes/stages/<stage_id>.tscn` with `stage.gd` on the root and
   set `floor_y`, `left_bound`, `right_bound`, `spawn_p1_x`, `spawn_p2_x`.
   Use native scale (1.0) for 320x180 art; do not rescale source.
3. Create `game/resources/stages/<stage_id>.tres` with a unique `id`, a
   `display_name`, a short `description`, the thumbnail, and the scene.
4. Append the `StageData` to `MatchRoster.stages` in
   `game/resources/match_roster.tres`. The selector and `MatchRoot` pick it up
   automatically; RANDOM remains last.
5. Add the scene to the headless checks if it has ambience or non-default
   arena geometry.
