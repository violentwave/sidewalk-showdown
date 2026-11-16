# Pixelorama animation pipeline — setup and verification

Status: **setup verified; first authored batch (idle) integrated into gameplay;
all other character animations are still placeholders.**
Branch of record for this document: `chore/pixelorama-idle-pipeline-setup`.

## 1. Installation (verified)

- Editor: **Pixelorama v1.2.4-stable** (MIT, FOSS), installed manually by the
  owner via **Flatpak** from Flathub. Do not reinstall.
- Application ID: `com.orama_interactive.Pixelorama`
- Ref: `app/com.orama_interactive.Pixelorama/x86_64/stable`
- Flatpak commit: `5d39805ffc0c8e784677c277d0174ffe741d6617986a69b7fd21ab43cb3bc259`
  ("Update to v1.2.4 (#54)", 2026-11-03)
- Runtime: `org.freedesktop.Platform/x86_64/26.08`
- Installed size: 108.3 MB (system installation, `--system` remote: flathub)
- Graphical launch: confirmed working by the owner, and re-observed from the CLI
  session (window `WM_NAME` = `untitled - Pixelorama v1.2.4-stable`,
  `WM_CLASS` = `Godot_Engine`, `Pixelorama`) on the XWayland display.
- Sandbox permissions (unchanged; no overrides granted):
  `shared=ipc; sockets=pulseaudio,x11; devices=dri; filesystems=home`.
  Verified inside the sandbox: repo files readable, `~/.cache` writable. The
  `filesystems=home` grant is what makes the project directory accessible; no
  broader filesystem access was requested or needed.

## 2. Verified headless CLI round trip

All commands below were executed against a **disposable test project** in
`~/.cache/sidewalk-showdown-pixelorama-test/` (kept out of the repo).

### What the CLI can and cannot do

Per Pixelorama v1.2.4's documented CLI (`--help` and
`src/Main.gd :: CLI.args_list`), the CLI can **open/export/print existing
projects only**. It cannot create projects, cannot draw, and cannot add frames.
`.pxo` creation and pixel editing happen either in the GUI or programmatically
(see §3).

### Invocation notes

- **Absolute paths are required** for input files. Relative paths are resolved
  against the sandbox executable directory (`/app/bin`) and silently skipped —
  a relative-path invocation returned a default 64×64, 1-frame project with no
  error message. Or pass `rel-dir=<dir>` to set the resolution directory.
- Flatpak system options go before `--`, Pixelorama user options after it.

### Verified commands

```sh
PXO=/home/lch/.cache/sidewalk-showdown-pixelorama-test/output/cli_test.pxo
OUT=/home/lch/.cache/sidewalk-showdown-pixelorama-test/cliout

# Inspect
flatpak run com.orama_interactive.Pixelorama --headless --quit -- "$PXO" --size --framecount
# -> (96, 80) / 2   (test project: 96x80 canvas, 2 frames)

# Export spritesheet + full project JSON metadata
flatpak run com.orama_interactive.Pixelorama --headless --quit -- "$PXO" \
  -e -s -o "$OUT/sheet.png" --json -f 1-2 -d 0
```

Verified results:

- `sheet.png`: 192×80 RGBA (2 × 96×80 cells in one row), transparent gaps,
  opaque pixel content in both cells.
- `cli_test.json`: full project dump — `size_x/size_y`, per-frame `duration`
  (0.15 s preserved), `tags` (`idle`, from/to 1-based frame range), `layers`
  (names preserved), `fps`.
- Exit behavior: the export honors `-d {0,1,2}` (forward/backward/ping-pong),
  `-f` frame ranges (1-based), and `--scale` (integer upscale).
- Spritesheet layout: default orientation is one frame per column with
  `lines_count=1` → a single horizontal row in frame order; the layout is
  deterministic and matches the manifest contract below.

## 3. `.pxo` authoring workflow (verified)

A `.pxo` (v8, Pixelorama ≥ 1.0) is a ZIP archive:

| Entry | Content |
|---|---|
| `data.json` | project dictionary (`pxo_version: 8`, size, layers, frames/cels, tags, durations, export profile) |
| `mimetype` | `application/x-pixelorama` |
| `preview.png` | thumbnail of the current frame (optional on load) |
| `image_data/frames/<f>/layer_<l>` | raw RGBA8 pixel data per cel (`w*h*4` bytes) |
| `image_data/frames/<f>/indices_layer_<l>` | only for indexed color mode (omit for RGBA) |

Verified by authoring a test project programmatically with Python (`zipfile`)
and having Pixelorama v1.2.4 open it headlessly with the correct size, frame
count, tag, and per-frame durations (see §2). Format details read from the
v1.2.4 source (`src/Classes/Project.gd :: serialize/deserialize`,
`src/Autoload/OpenSave.gd :: save_pxo_file/open_pxo_file`).

Consequences for our pipeline:

- The **owner edits in the GUI and saves native `.pxo` files** — those remain
  the source of truth for art review.
- Programmatic `.pxo` writing is available for assembling AI-drafted frame
  images into editable projects the owner can then open and polish in the GUI.
- CLI export (§2) produces review sheets and machine-readable metadata.

## 4. Proposed production conventions

- Authoring projects:
  `art/source/Characters/Animations/<fighter_id>.pxo`
  — **template projects already created and verified** for
  `peg_leg_peggy.pxo` and `whiskey_richard.pxo`: 96×80 canvas, 4 idle frames at
  0.15 s, `idle` tag on frames 1–4, layer `IdleArt` for authoring plus a locked,
  hidden `Reference` layer carrying the scaled fighter cutout at the shared
  baseline (verified: reference bottom edge on the baseline, center x ≈ 48;
  headless round trip confirmed 96×80 / 4 frames / durations / tag; export of
  the visible layers only — the hidden reference contributes nothing to the
  exported sheet, keeping guides out of review exports).
- Canvas/cells: start at **96×80 transparent cells**, right-facing, shared feet
  baseline with anchor **(48, 78)** — to be validated against the fighters'
  actual cutout bounds before the first batch is accepted; report rather than
  force a distorted fit.
- One animation tag per gameplay animation (tag `from`/`to` are 1-based frame
  numbers). Per-frame durations in seconds carry the timing; tags + durations
  survive `.pxo` round trips (verified) and are included in `--json` output.
- Review exports (never wired into the game):
  `art/review/<batch>/…` + `animations.json` describing sheet layout, frame
  rectangles, animation name, per-frame durations, loop flag, canvas size, and
  anchor.
- Guide layers (silhouette reference, baseline, attack-reach markers) live in
  the `.pxo` as layers and are excluded from export.
- Lettering, backgrounds, and watermark-free discipline apply to exported
  frames.

## 5. Fighter animation inventory (mapping target)

Each fighter's MoveData (`game/resources/fighters/*.tres`: 6 normals, 5
specials, 2 grabs, 2 EX, 1 finisher, shared METH row = 15 move rows) must map to
Pixelorama tags whose per-frame display durations reproduce the existing
startup/active/recovery timing in frames at 60 FPS. No MoveData or gameplay
timing changes are permitted; animation authoring only mirrors them. The full
tag inventory (~34 per fighter) is enumerated during the first production
batch; this batch is idle-only.

## 6. Generation-tool status (blocker)

- Image generation was retried after the earlier outage with distinct models:
  - `opencode/gpt-image-2.5-sunburst` → **failed: "Insufficient balance"**
    (service requires a paid top-up at opencode.ai/console; spending owner
    money is not permitted without approval).
  - `google/gemini-nano-banana-2.1` → **failed: "unavailable for this
    connection"**.
  - `google/gemini-3.1-flash-lite-image` → **failed: "unavailable for this
    connection"**.
- Reference images ARE supported by these tools (image inputs are accepted and
  were supplied); the blocker is service availability/billing, not capability.
- No local AI stack was installed, no accounts changed, and no reference art
  was uploaded to any new service.

## 7. Owner-facing next steps

1. Generation blocker: all three available image models failed (billing /
   connection, see §6). The owner then produced and approved the idle packs
   locally under `art/source/Characters/Animations/generated/…_idle_review/`;
   their provenance is AI-generated drafts cleaned and reviewed by the owner —
   **no provider license is claimed and the source assets are not CC0**;
   usage rights follow the same owner-supplied-asset policy as the rest of
   the project.

## 8a. Integration status — authored idle loops (DONE, superseded by §8)

Integrated and merged in PR #43 (the authored-idle pass later superseded by the
full clip batches in §8/§9):

- Native sources: the approved four cels were assembled into
  `art/source/Characters/Animations/peg_leg_peggy.pxo` /
  `whiskey_richard.pxo` (IdleArt layer cels now full-canvas 96×80, 0.15 s per
  frame, `idle` tag frames 1–4; hidden locked `Reference` layer preserved).
  Verified by headless reopen (96×80 / 4 frames) and CLI sheet export; the
  exported Richard sheet is pixel-identical to the approved pack and Peggy's
  differs only in cleared alpha-0 halo pixels (opaque content identical).
- Runtime sheets: `game/art/characters/peg_leg_peggy/spr_peg_leg_peggy_idle.png`
  and `game/art/characters/whiskey_richard/spr_whiskey_richard_idle.png`
  (copies of the approved 384×80 sheets; no previews/ZIPs in runtime dirs).
- `FighterBase.tscn`: new `VisualRoot/IdleSprite` (Sprite2D, hframes=4,
  nearest filter, uncentered).
- `fighter_base.gd`: the approved sheet is the fighter's artwork everywhere —
  the four-cel loop plays in `State.IDLE`, and **cel 0 shows as the static
  artwork in every other placeholder state** (walk, crouch, jumps, attacks,
  block/reactions, knockdown, wake-up, KO, win), replacing the clashing legacy
  cutout during normal play. Procedural `VisualRoot` motion for those states
  is unchanged, the idle loop does not play outside IDLE, and hit/block
  flashes modulate the sheet art the same way they modulated the cutout. The
  cutout/silhouette path remains as the emergency fallback when the idle
  sheet is missing or invalid. Exactly one character-art visual is visible at
  a time; the sheet uses one scale (measured visible height →
  `SILHOUETTE_HEIGHT`), the (48, 78) feet anchor, nearest filtering, and
  `flip_h` facing for all states, so transitions never swap artwork, stack
  sprites, jump size, or shift ground placement. Cel timing derives from
  `state_frame` at 9 ticks per cel (0.15 s at 60 Hz sim; 36-tick loop), so
  hitstop and match pause freeze it and idle re-entry restarts at cel 0. The
  old whole-body idle bob is disabled while the authored idle is active, and
  `VisualRoot` transforms are reset every sync, so feet never drift.
- No MoveData, collision, hitstop, input, or state-rule changes.
- Tests: `combat_test.gd` extended (sheet artwork in IDLE and static cel 0 in
  non-idle states with identical scale/anchor; 9-tick cadence and wrap; no
  per-tick restart; hitstop/pause freeze; re-entry reset; facing pivot; crouch
  squash rule; missing-art fallback; unchanged pushbox) — the suite stood at
  260 checks at that time;
  `round_flow` 34, `character_select` 15, `the_clip` 23, all green.
- Rendered verification: windowed capture script
  `game/tests/idle_render_check.gd` (disposable, writes to /tmp) observed
  idle → walk → crouch → jump → attack → hit/block flash → idle, plus both
  facing directions, at gameplay scale against Bus Stop Night; captures under
  `/tmp/opencode/idle_check/`. The sheet artwork holds through every
  transition with no artwork swap, stacked sprites, size jump, or feet-anchor
  shift; both fighters read correctly with planted feet and nearest filtering.

Still placeholder and **procedural**: (historical, superseded by §8 — Peggy's
non-idle states now play authored clips) every non-idle animation (walk, crouch,
jumps, attacks, block/reactions, knockdown, wake-up, KO, win) now uses cel 0
of the approved idle sheet as its static artwork with the existing procedural
`VisualRoot` motion — the artwork is consistent with the approved idle
sprites, but the non-idle states are not yet authored animations. The owner
decision on facing-flip consequences (peg leg / bottle hand swap sides) is
still deferred.
2. Owner decision still deferred: whether flipping right-facing art for
   left-facing play is acceptable given Peggy's peg leg and Richard's bottle
   would swap apparent sides, or whether dedicated left-facing art is wanted.
3. Standing-light attacks, AnimatedSprite2D runtime integration, and the
   remaining inventory follow after owner review of the idle batch.

## 8. Integration status — Peggy's full-animation batch (DONE, merged in PR #44)

Landed on `main` via PR #44; the owner reviewed the batch before merge.
§8's idle behavior is unchanged; Richard's visuals were untouched while only
Peggy was wired (superseded by §9 below, which adds Richard's own table).
The shared jump/landing/guard playback fixes in §9a apply to Peggy as well and
are regression-covered; her tables, gated clips, and approved fallbacks are
otherwise unchanged.

Inventory: the owner's local PixelLab download is **40 files** (36 PNG +
4 JPEG) under `art/source/Characters/Animations/generated/full_animation_batch_01/peggy/`,
byte-for-byte preserved. All 40 map to 40 clip keys (22 core states, 16 attack
moves, 2 optional: `stage_intro`, `throw_target`). Coverage by status:

- **Integrated + enabled (34)**: 16 attack moves (all MoveData rows in
  `peg_leg_peggy.tres` map 1:1), jumps (start/rise/fall), land, block/blockstun
  (stand+crouch), hitstun (stand+crouch+air), knockdown, wake-up, throw tech,
  ko_air, ko_ground, crouch_hold, crouch_up transient, win.
- **Prepared but gated OFF (4, owner review)**: `walk_forward`,
  `walk_backward`, `crouch_down` (front-facing JPEGs that clash with the
  side-view fighter), `stage_intro` (no runtime hook).
- **Prepared but unmapped (2, optional)**: `throw_target` (no paired throw
  cinematic).

Pipeline (`art/tools/prepare_peggy_batch.py`, reproducible):

- Cuts each sheet into cels at the **minimum-coverage column/row** nearest the
  even pitch, not by snapping to empty columns: the draft strips are AI sheets
  whose figures cross the pitch lines, and hard pitch cuts chopped arms/feet
  (seen in `forward`/`light`). Per-row baselines for the two multi-row JPEG
  sheets. Frame counts were verified visually per sheet before slicing.
- Every frame is pasted **whole** (never cropped) into a symmetric cel and
  aligned by its **planted-foot centroid** (`foot_anchor_x`, bottom ~10 % band)
  plus its row baseline. Cel width is `2 * anchor_x + 2`, so `flip_h` mirrors
  the body around the same root; the root lands on the fighter origin, which
  keeps the body still when an attack extends a limb. No per-cel bounding-box
  centring (that made the fighter appear to lurch between frames).
- The 4 opaque JPEGs get exterior-connected flood-fill masking of the painted
  checkerboard on **derived copies only** (interior whites — eyes/teeth/hat
  stripe — are never reached). No global keying.
- **No pixel-art resampling.** Each clip records a root anchor and `h_ref`
  (source px equal to the 74 px standing reference). Runtime scale =
  `_idle_art_scale * 74 / h_ref`, so clip standing figures exactly match the
  approved idle art on screen. `h_ref` is normally 74: hat-width measurement
  (a pose-independent scale cue vs the idle sheet) shows all PNG sheets share
  the idle art scale. `h_ref` differs only where the sheet itself is drawn
  larger (`block_stand`/`blockstun_stand`, ~1.5×) or comes from an opaque JPEG
  whose scale must be estimated (`crouch_hold`). Pose-height estimates for
  `jump_fall`/`land`/`hitstun_*`/`block_crouch`/`win` were wrong (poses are
  foreshortened) and made those clips pop 8–24 % smaller mid-move; they now
  use 74 and a regression check enforces the band.
- Outputs `peggy_prepared/` (normalized sheets + `peggy_clips_manifest.json`
  + contact sheet); runtime copies in
  `game/art/characters/peg_leg_peggy/clips/` (40 PNGs).

Runtime (`game/scripts/combat/peggy_clip_library.gd`, new; `fighter_base.gd`):

- Data-driven `CLIPS` table (generated from the manifest) + `MOVE_CLIPS` +
  `STATE_CLIPS` + cadence tables. `has_clips()` is true only for Peggy.
- `_resolve_visual_clip()` / `_clip_frame()` / `_display_clip()`: playback is a
  pure function of the sim clock — state/move entry restarts, hitstop and pause
  freeze, one-shots fit authored durations and clamp to the final cel, holds
  loop, grounded KO holds its final pose. Attack cels map proportionally onto
  authored startup/active/recovery (zero-length phases get 0 cels; impact poses
  land on active frames).
- Authored clips disable the procedural `VisualRoot` transforms (no
  double-animation); flashes, EX tint, facing flip, and the gameplay pushbox
  squash are unchanged. Missing/gated clips fall back to the approved static
  cel-0 artwork, never to the legacy cutout.
- Crouch-exit plays the authored `crouch_up` transient (3 cels × 5 ticks).

Limitation to note honestly: no native `.pxo` projects were built for this
batch; the delivered assets are derived PNGs + manifest + reproducible script.

Defects flagged in the manifest (`flags` per clip): `block_stand` /
`blockstun_stand` are drawn ~1.5× at source and normalized via their own
`h_ref`; `crouch_hold` comes from an opaque JPEG whose standing height is
estimated; `ko_ground` final pose is a hunched collapse, not flat-on-ground.
All other enabled clips share the idle 74 px art scale.

Tests: `combat_test.gd` extended to **301 checks, 0 failures** (clip library
integrity, move mapping, gated clips, scale consistency / no size popping,
exact attack phase boundaries for light/heavy/meth, repeat-attack reset, hitstop
freeze, hitstun stand/crouch/air context, crouch loop, knockdown fit, KO
air/ground hold, walk-gate fallback, Richard unchanged at that point, round reset);
`round_flow` 34, `character_select` 15, `the_clip` 23, all green. Live-input
soak (`peggy_live_soak.gd`, 3,000 real-`Input` frames) reported 0 failures with
the art centred within 0.75 px of the fighter. Real-input jump check
(`peggy_jump_check.gd`, jump action is `p1_up`) shows a constant 0.718 scale
through start → rise → fall → land → idle.

Rendered verification: `game/tests/peggy_clip_render_check.gd` (disposable)
captured 23 states/facings to `/tmp/opencode/peggy_clip_check/` (+
`contact_sheet.png`). Verified good: crouch, attacks, specials, blockstun,
facing-left, KO, win, scale consistency, and the Richard regression. Note: an
apparent "duplicate Peggy" in late captures was investigated and is **not** a
renderer bug — it is a stage-background bystander plus the round-end reset
respawning fighters when the scripted attacks legitimately KO'd Richard mid
capture sequence (KO capture artifacts of the disposable script only).



## 9. Integration status — Whiskey Richard's full-animation batch (DONE, merged in PR #44)

Landed on `main` via PR #44 alongside Peggy's batch.
Peggy's §8 integration is unchanged (same library, table, and tests); Richard
gets his own generated table and dispatch. No gameplay data was touched.

Inventory: the owner's local download is **40 PNG files** (true alpha, no JPEG)
under `art/source/Characters/Animations/generated/full_animation_batch_01/richard/`,
byte-for-byte preserved. All 40 map to the same 40 clip keys as Peggy (22 core
states, 16 attack moves, 2 optional). Coverage by status:

- **Integrated + enabled (39)**: 16 attack moves (all 16 MoveData rows in
  `whiskey_richard.tres` map 1:1), jumps (start/rise/fall), land, block/blockstun
  (stand+crouch), hitstun (stand+crouch+air), knockdown, wake-up, throw tech,
  ko_air, ko_ground, crouch_hold, crouch_up transient, win, **plus** walks and
  `crouch_down` (side-facing PNGs, so they are live for Richard where Peggy's
  front-facing JPEGs are gated). Since 2026-11-16 `crouch_down` plays as the
  crouch-entry transient: the crouch transition stays instantaneous in the
  simulation and the clip is presentation only.
- **Prepared but gated OFF (2)**: `stage_intro` (no runtime hook),
  `throw_target` (no paired throw cinematic).

Pipeline (`art/tools/prepare_richard_batch.py`, reproducible; shared
slicing/masking/anchoring helpers still live in `prepare_peggy_batch.py`):

- Richard's draft strips are spaced unevenly and several figures overlap, so
  the pitch/ min-coverage slicer used for Peggy mis-assigned whole limbs
  (detached arm/boot cels in `grab`, `down`, `neutral_ex`, etc.). Richard uses
  **8-connected component segmentation** instead: each figure is one component
  (32 of 40 sheets), touching figures are split at the thinnest central column
  and tiny orphan slivers are dropped (`light`, `grab`, `down`, `command_grab`,
  `crouch_light`, `forward_ex`, `neutral_ex`), and the lone stray speck in
  `ko_ground` is removed. All 40 prepared sheets were re-verified to have one
  body per cel with no sub-18%-area islands.
- Cels still paste whole, aligned by planted-foot centroid + row baseline, with
  a symmetric cel (`2 * anchor_x + 2`) so `flip_h` mirrors around the same root.
  No pixel-art resampling.
- **Per-sheet art scale.** Unlike Peggy's sheets, Richard's are drawn at visibly
  different scales. `h_ref` is measured per sheet from the rigid bandana (max
  connected red-area vs the approved idle sheet, whose red area is 269 px), not
  snapped to 74. Measured `h_ref` range is 47–81 (`meth` 56, `down` 50,
  `crouch_heavy` 57, `neutral` 58, `light` 74, `land` 81, `walk_forward` 78).
  Runtime scale is still `_idle_art_scale * 74 / h_ref`. This is the main
  honesty caveat: the source sheets are not internally scale-consistent, so the
  manifest stores a measured scale per clip rather than claiming a single
  global scale. Six action sheets (`forward`, `forward_ex`, `jump_light`,
  `jump_heavy`, `meth`, `air`) had their `h_ref` recalibrated on 2026-11-15 from
  foot-to-head height rather than red area: the bandana is often occluded or
  angled in those poses, so the red-area estimate made them render 15–48 %
  taller than idle. Head-height calibration puts each of them within ~1 % of
  the idle on-screen body height (see §9a).
- Outputs `richard_prepared/` (40 normalized PNGs + `richard_clips_manifest.json`);
  runtime copies in `game/art/characters/whiskey_richard/clips/` (40 PNGs).
  No contact sheet is generated for Richard (the per-cel integrity check is the
  review artifact; rendered captures cover the visual pass).

Runtime (`game/scripts/combat/richard_clip_library.gd`, new; `fighter_base.gd`):

- Same generated-table shape as Peggy: `CLIPS` + `MOVE_CLIPS` (Richard's
  `richard_*` ids) + `STATE_CLIPS` + cadence. `has_clips()` is true only for
  Richard.
- `fighter_base.gd` now holds `var _clip_lib: GDScript` resolved by
  `_clip_library_for(id)` (Peggy, Richard, otherwise null) and routes every
  resolve/frame/scale call through it, so Peggy's call sites are unchanged in
  behavior and any future fighter without a table keeps the approved fallback.
- Playback, phase mapping, hitstop/pause freeze, one-shot/loop handling, KO
  hold, and procedural-transform suppression are shared with Peggy and
  unchanged; the only per-fighter data is the table.

Tests: `combat_test.gd` extended to **337 checks, 0 failures**. New Richard
coverage: library integrity (cel geometry, 39 distinct enabled textures),
all-16 move mapping incl. `richard_*` targets, gated optional clips, live
walk/crouch-hold/crouch-entry, exact light/heavy/meth phase boundaries,
end-to-end attack display + no procedural transforms + h_ref scale, hitstop
freeze, repeat-attack reset, hitstun interruption, both-fighter state+move
coverage, and the §9a playback regressions (walk wrapping, jump-fall cel,
landing order, guard poses, Peggy's jump/land order) plus the §9b crouch-entry
transient. The earlier "Peggy and Richard animate
differently" walk check now asserts Richard plays his authored `walk_forward`
while Peggy keeps the gated idle fallback. `round_flow` 34,
`character_select` 15, `the_clip` 23, all green.

Rendered/live verification: `richard_clip_render_check.gd` captured 27
states/facings to `/tmp/opencode/richard_clip_check/` (+ contact sheet);
`richard_live_soak.gd` ran **3,000 real-Input frames, 0 failures** (p2 art
centred within ~1.1 px); `richard_jump_check.gd` traced a real `p2_up` jump:
`jump_start`/`jump_rise` at the idle 0.718 scale and `jump_fall` at 0.748
(its measured `h_ref` 71, inside the same ±5 band) with no mid-move pop.

## 9a. Animation polish — jump, landing, guard, attack scale (2026-11-15)

Presentation-only pass fixing the glitches reported after the first Richard
integration. No damage, timing, hitbox, knockback, movement, collision, buffer,
cancel, invuln, hitstop, or round logic was touched; every change is either a
cel selection, a cel cadence, or an `h_ref` scale value.

- **Walking froze on its last cel.** The generic state fallback clamped the
  frame index (`state_frame / 6`, clamped to `n - 1`), so holding a direction
  played the first six cels and then held the final pose. Walks now use their
  own loop cadence (`LOOP_CEL_TICKS.walk_f/walk_b = 6`) and wrap, so the cycle
  keeps ticking for as long as the direction is held. Peggy's walk clips are
  still gated, so her approved fallback is unchanged.
- **The jump-fall sheet ended on a landing crouch.** Played during the descent,
  that cel read as Richard standing on invisible ground and then teleporting
  down. `jump_fall` now plays only its airborne cel (`PLAY_CELS.jump_fall =
  [0]`) for the whole fall.
- **Landing played its cels in the wrong order.** The draft strip is
  upright-then-absorb; the two-frame LAND state therefore popped back to
  standing before crouching. `PLAY_CELS.land = [1, 2]` plays absorb then
  recover. Peggy's sheets have the same ordering, so the shared fix applies to
  both fighters.
- **Jump start skipped its launch pose.** Two cels advanced every three ticks
  across a two-frame state, so cel 1 never appeared. `jump_start` now advances
  one cel per tick, showing crouch then extension.
- **Blocking had no guard pose.** `BLOCK_STAND`/`BLOCK_CROUCH` were never
  entered by the simulation, so the authored guard clips were dead and holding
  back only showed the (previously frozen) walk. The renderer now substitutes
  the authored guard while holding back and stationary (pinned against a wall)
  or crouch-blocking, and it shows the stand guard for the one-frame IDLE
  hand-off after blockstun. Retreating still plays the walk cycle; blocking,
  chip, pushback, and blockstun are untouched. `GUARD_POSE` is a per-library
  flag; both current fighters enable it.
- **Six attacks rendered much larger than idle.** See §9's art-scale bullet:
  `forward` (+35 %), `forward_ex` (+48 %), `jump_heavy` (+39 %), `jump_light`
  (+15 %), `air` (+22 %), and `meth` (+20 %) were rescaled from head height so
  each renders at the idle on-screen body height. `forward`/`forward_ex` now
  sit next to the idle/light/heavy captures at the same size.

Verification: `combat_test.gd` grew from 326 to 333 checks at the time of that
pass (7 new: walk wrap, jump-fall
cel hold, landing cel order, wall guard, crouch guard, plus Peggy's jump-fall
and landing order), all green. New rendered harnesses
`jump_block_render_check.gd` (18 ordered poses) and `attack_scale_check.gd`
(six attacks against an idle reference) were reviewed at 1280×720;
`jump_block_trace.gd` drove real input and recorded the pre-fix symptoms
(frozen walk, airborne landing cel) plus the fixed playback. Both 3,000-frame
live-input soaks stayed clean after the change.

Known limitations to state honestly: `stage_intro`/`throw_target` are
intentionally unmapped (the latter needs a throw cinematic); source sheets
carry per-sheet art scales (measured, not uniform; the six worst action outliers
were recalibrated in §9a, but a uniform re-export is still the cleaner fix);
and no native `.pxo` projects exist for this batch (derived PNGs + manifest +
reproducible script).

## 9b. Crouch-entry transient (2026-11-16)

Presentation-only follow-up. `crouch_down` was the last enabled-but-unmapped
Richard clip; the game has no separate crouch-entry state because crouch is
instantaneous, so mapping it as a state would have changed timing. Instead the
existing stand-up transient mechanism was generalised:

- `FighterBase` now resolves the transient by key (`_transient_clip_key` →
  `state_clip(key)`) instead of hard-coding `crouch_up_transient`. This also
  fixes a latent bug: any transient other than stand-up would have displayed the
  stand-up clip.
- Each library declares `TRANSIENTS` (key → per-cel cadence) and maps
  `crouch_down_transient` → `crouch_down`; duration is cel count × cadence.
- Entry to `CROUCH` starts `crouch_down_transient`; a crouch that ends in IDLE
  still starts `crouch_up_transient`. A gated transient (Peggy's front-facing
  crouch-down art) falls through to normal state resolution rather than flashing
  the idle sheet.
- The guard pose takes over once the entry transient expires, so crouch-block
  still shows the authored guard.

No simulation state, frame timing, hurtbox, buffer, or collision value changed;
the crouch hurtbox is still the 0.65 pushbox from the first crouch frame.
Verification: `combat_test.gd` is at **337 checks, 0 failures**, including a new
3-check crouch-entry group and an assertion that the entry transient defers the
guard pose. `round_flow` 34, `character_select` 18, `the_clip` 23 all green.
