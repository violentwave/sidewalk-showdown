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

## 8. Integration status — authored idle loops (DONE); everything else pending

Integrated (uncommitted, branch `chore/pixelorama-idle-pipeline-setup`):

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
  squash rule; missing-art fallback; unchanged pushbox) — 260 checks green;
  `round_flow` 34, `character_select` 15, `the_clip` 23, all green.
- Rendered verification: windowed capture script
  `game/tests/idle_render_check.gd` (disposable, writes to /tmp) observed
  idle → walk → crouch → jump → attack → hit/block flash → idle, plus both
  facing directions, at gameplay scale against Bus Stop Night; captures under
  `/tmp/opencode/idle_check/`. The sheet artwork holds through every
  transition with no artwork swap, stacked sprites, size jump, or feet-anchor
  shift; both fighters read correctly with planted feet and nearest filtering.

Still placeholder and **procedural**: every non-idle animation (walk, crouch,
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