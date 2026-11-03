# Sidewalk Showdown

Mature-rated 2D retro pixel-art arcade fighting game. A washed-up livestreamer
(Tripp Vlogs) turns sidewalk chaos into a rigged tournament — and 15 local
legends eventually turn on him.

**Engine:** Godot 4.x (in `game/`)
**Target:** PC first (Windows / Linux / macOS)
**Status:** Phase 1.5d — greybox combat prototype, audit-hardened
**License:** TBD — treat as all-rights-reserved until a LICENSE file is added.

## Quick start

```bash
godot --path game                     # play
godot --headless --path game --script res://tests/combat_test.gd      # combat tests
godot --headless --path game --script res://tests/round_flow_test.gd  # round flow tests
```

## Controls (Phase 1)

| Action | P1 (Peg Leg Peggy) | P2 (Whiskey Richard) |
|---|---|---|
| Move | A / D | ← / → (or Numpad 4 / 6) |
| Jump | W | ↑ (or Numpad 8) |
| Crouch | S | ↓ (or Numpad 2) |
| Light attack | J | Numpad 1 or `,` |
| Heavy attack | K | Numpad 3 or `.` |
| Special | L | Numpad 5 or `/` |
| Grab / throw | U | Numpad 7 or `;` |
| METHtality | I | Numpad 9 or `'` |
| Pause | Esc | Numpad 0 |

Both players share one keyboard: P1 is **WASD only**, and the arrow keys are
reserved for P2. P2 can move with either the arrows or Numpad 2/4/6/8. Regenerate
the input map with
`godot --headless --path game --script res://tools/setup_input.gd` if you change
the table above.

Specials are directional (GDD §4.4): neutral, forward (toward opponent), back,
down, and air. Block by holding away from the opponent — including during
blockstun — and hold down-away to crouch-block lows. Chip damage cannot KO: a
blocked hit always leaves the defender at 1 HP. `Enter` restarts after a match
ends.

Pause (Esc or Numpad 0) opens a menu either player can drive: W/S or the arrow
keys (Numpad 8/2) move the selection, and J, Numpad 1, or Enter picks
**RESUME**, **RESTART MATCH**, or **QUIT TO DESKTOP**. Pausing freezes the fight
mid-frame, so hitstun, health, and the round clock resume exactly where they
stopped.

Debug: **F1** boxes (on by default), **F2** frame state, **F3** input history,
**F4** slow motion.

Debug: **F1** boxes (on by default), **F2** frame state + frame advantage,
**F3** input history, **F4** slow motion, **F5** frame-step (advances one sim
frame per press while slow-mo is on), **F6** refill both fighters (full health
and meter at round positions, without restarting the round).

## Builds

`.github/workflows/export.yml` exports both desktop targets on every push to
`main` and on `v*` tags: a Linux x86_64 binary and a Windows x64 `.exe`, with the
PCK embedded so each artifact is a single runnable file. Grab them from the
**Artifacts** section of a run in the Actions tab — they are named
`sidewalk-showdown-linux-<short sha>` and `sidewalk-showdown-windows-<short sha>`.

Presets live in `game/export_presets.cfg` (`linux`, `windows`). Locally, with the
4.7.2 export templates installed:

```bash
godot --headless --path game --import
godot --headless --path game --export-release linux build/linux/sidewalk_showdown.x86_64
godot --headless --path game --export-release windows build/windows/sidewalk_showdown.exe
```

## Source of truth

| Doc | Purpose |
|---|---|
| `GAME_BIBLE.md` | Story/world canon (Tripp, roster, stages, METHtalities) |
| `GDD.md` | Design & production plan (combat systems, phases) |
| `CHARACTERS.md` | Roster bible (archetypes, rivals, data direction) |
| `docs/SIDEWALK_SHOWDOWN_NON_DEFINING_ASSET_PROMPTS.md` | 315 art-generation prompts |
| `docs/KNOWN_ISSUES.md` | Current prototype gaps |

**Canon locks:** Tripp Vlogs is the only boss and is NOT playable. Roster = 15
fighters. Every fighter has one unique METHtality. No real towns, brands, or
public figures (this is fictional "Sidewalk Florida").

## Repo layout

```text
game/            Godot 4.x project
  scenes/        match, fighters, stages, HUD
  scripts/       combat, match, ui, debug, stages
  resources/     fighters/*.tres (data-driven moves + stats)
  tests/         headless test suites
  tools/         data generators + screenshot harness
art/source/      Raw AI-generated asset prototypes (do not clean in place)
art/source/extras/   Non-canon / future-roster character art
art/exports/     Cleaned, snake_case, runtime-ready art
docs/            Supporting docs and archives
```

## Architecture rules (Phase 1 onward)

- **Simulation runs at fixed 60 Hz.** All frame data (startup/active/recovery,
  hitstun, blockstun, hitstop, buffer windows) is in simulation frames.
- **Fighters are data.** `resources/fighters/*.tres` define stats and moves;
  the engine never hard-codes a character. Regenerate via
  `godot --headless --path game --script res://tools/gen_fighter_data.gd`.
- **Separate combat boxes** (push/hurt/hit) computed from `MoveData`.
- Asset naming in `art/exports/`: lowercase snake_case
  (`spr_whiskey_richard_idle.png`, `stage_bus_stop_night_bg_far.png`).
- AI art pipeline: generate → save raw in `art/source/` → clean/pixel-fix →
  export into `art/exports/` only after review. Never edit `art/source/` files.

Current vertical slice: **Peg Leg Peggy** vs **Whiskey Richard** on
**The Bus Stop (Night)**.
