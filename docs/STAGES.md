# Stages: assets, ambience, and stage select

Two stages are wired into the shared roster: **Everglades Gas-N-Go** and
**Bus Stop**. The match builds whichever `StageData.scene` the front-end passes
in; adding a stage is a scene + resource + roster edit, not a `MatchRoot` code
change.

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

## Bus Stop

The old 1024x1024 night painting, its `0.3125` scale, and its night modulate are
gone from the stage. Bus Stop is now the same kind of native 320x180 layered
scene as Gas-N-Go.

| Property | Value |
|---|---|
| Source art | `art/source/Stages/BusStop/` (read-only; `bus_stop_layout.json` is the source of truth) |
| Runtime art | `game/art/stages/bus_stop/` |
| Native canvas | 320x180, drawn at scale **1.0** (no resampling) |
| Scene | `game/scenes/stages/bus_stop_night.tscn` |
| Data | `game/resources/stages/bus_stop_night.tres` |
| Stable id | `bus_stop_night` (unchanged; saved selections depend on it) |
| Display name | `Bus Stop` |
| Floor / bounds | `floor_y = 170`, `left_bound = 24`, `right_bound = 296` |
| Spawns | P1 x = 110, P2 x = 210 |
| Selector thumbnail | `game/art/stages/bus_stop/thumbnail.png`, 80x45 |

The sidewalk art covers rows 148-180, but the art's contact line is *not* the
strip's top edge: the shelter posts bottom out at about row 171, the liquor
sign's pole base at about row 172, and the bench legs at about row 173. So
Bus Stop runs `floor_y = 170` — fighters' feet rest on the sidewalk at the same
level where the shelter's posts, the sign pole, and the bench meet the ground.
Gas-N-Go keeps its own `floor_y = 158` because its storefront/dirt contact sits
higher; floor_y is per-stage art measurement, not a shared convention. Bounds
and spawns are the same authored values as Gas-N-Go, so spacing and camera
framing stay consistent between the stages.

### Choosing floor_y

Never copy floor_y from another stage. Choose it per stage:

1. Measure where the art's objects actually meet the ground on the **foreground
   layer**: the bottom rows of sign poles, shelter posts, bench legs, and
   storefront bases (Bus Stop's contact line is rows 168-173; its walkable
   sidewalk band starts at row 148).
2. Remember the fighters' sprite origin is their feet (`FighterBase.IDLE_ANCHOR`
   maps the in-sheet feet pixel onto the origin), so `floor_y` is the feet row.
3. Pick the value that puts the feet exactly on that contact line (Bus Stop:
   170), verify with a 320x180 capture (see `docs/assets/bus-stop-floor-*.png`),
   and pin it in `game/tests/stage_floor_test.gd`, which guards every roster
   stage's floor_y against its measured walkable band.

### Draw order

Bottom to top in the stage scene:

1. `Sky` — 320x180 opaque sky.
2. `Clouds/CloudA` and `Clouds/CloudB` — the authored 640x40 transparent strip
   at y = 6, two copies 640 px apart.
3. `Foreground` — 320x180 street scene with a transparent sky.
4. `Fire` — 74x55 animated flame at (166, 103), same `z_index` as the
   foreground so fighters always draw in front of it.
5. `LiquorSign` — 49x13 lit/dead overlay at (6, 91) on top of the painted sign.
6. `StageAnimation` — logic-only node, no drawing.

`Fire` is deliberately in the foreground's z-band rather than a raised layer.
Fighters render after the whole stage, so they stay in front of the bright
flame. If the fire hurts readability on a particular display, the stage root
exposes `fire_modulate` (Color, default white); lower it to dim the flame
without editing the texture.

### Ambient animation

Both stages share `game/scripts/stages/stage_animation.gd`. It is data-light and
optional-node based: each scene animates only the nodes it actually contains.
The script runs in `_process`, not the 60 Hz simulation. The stage root is
`PROCESS_MODE_PAUSABLE`, so the pause menu freezes ambience; hitstop is not a
tree pause, so it keeps playing during hitstop. It never reads combat state,
rotates or scales a sprite, or allocates per frame, and every position is
snapped to a whole pixel.

- **Clouds (both stages):** the shared 640 px offset advances at **5 px/s**, then
  wraps with `fposmod`. The two copies are 640 px apart, so no visible cloud
  teleports. Bus Stop places the strip at y = 6; Gas-N-Go at y = 4.
- **Fire (Bus Stop):** four frames loop at **8 fps**. Each full loop re-rolls a
  small `fire_jitter_ratio` timing wobble from the visual-only RNG, so the
  flame never ticks like a metronome. Frames are texture swaps only.
- **Liquor sign (Bus Stop):** the lit frame holds for a random 3-7 s, then drops
  to the dead frame for 1-3 ambient frames (0.125 s each) before relighting.
  The base foreground keeps its painted sign; the overlay replaces it.
- **Mosquitoes (Gas-N-Go):** wingbeat frames flip at **8 fps** (`0.125 s`). Each
  insect traces a small, independent sine loop around its upper-sky anchor.
- **Gator (Gas-N-Go):** two breathing poses over a **one-second** cycle, plus a
  random f3 blink. The blink waits a random 2.5-6 s, holds f3 for 0.12 s, then
  restores the current breath frame.
- **Debug freeze:** enable `freeze_ambient` on the `StageAnimation` node in the
  remote inspector to hold every layer on its current frame.

All randomness here is a visual-only `RandomNumberGenerator`; it is never
shared with the deterministic fight simulation or replays.

### Regenerating the runtime art

```bash
python3 art/tools/prepare_gas_n_go.py
python3 art/tools/prepare_bus_stop.py
godot --headless --path game --import
```

Both prep scripts validate only sizes, opaque/binary alpha, frame counts, and
the per-layer palette budget — never picture content. They copy the source
layers at native resolution. The Gas-N-Go script derives its 80x45 thumbnail
with an exact 4x box downsample of the 320x180 preview. The Bus Stop script
composes `Sky` over `Foreground`, then takes the same exact 4x box downsample to
80x45; the menu card therefore shows the stage's actual base view without the
animated fire/sign overlays. It also checks `bus_stop_layout.json` for the
cloud/fire/sign positions and the four fire frames, and writes nine runtime
layers plus the thumbnail. Rerunning either script from unchanged sources is
deterministic.

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

See `game/tests/stage_select_test.gd` for the selector, both stages' ambience,
and invalid-roster coverage.

## Adding another stage

1. Export the layered 320x180 art into `game/art/stages/<stage_id>/` at native
   resolution and derive an 80x45 thumbnail with an exact 4x box downsample.
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
