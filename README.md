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

Debug: **F1** boxes (on by default), **F2** frame state, **F3** input history,
**F4** slow motion.

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
