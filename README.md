# Sidewalk Showdown

Mature-rated 2D retro pixel-art arcade fighting game. A washed-up livestreamer
(Tripp Vlogs) turns sidewalk chaos into a rigged tournament — and 15 local
legends eventually turn on him.

**Engine:** Godot 4.x (in `game/`)
**Target:** PC first (Windows / Linux / macOS)
**Status:** GDD Phase 2 — Vertical Slice, in progress. See `docs/PHASE_STATUS.md`.
**License:** TBD — treat as all-rights-reserved until a LICENSE file is added.

**Current scope:** the 15-panel “The Clip” intro leads to Peggy vs Richard on Bus
Stop Night, a text-only two-player character-select mockup, owner-approved idle
sprite sheets plus authored per-state/per-move animation clips for both
fighters (from the owner's PixelLab animation batch; see
`docs/PIXELORAMA_PIPELINE.md` §8–§9a), local keyboard play,
HUD/timer/round flow, directional specials, EX spenders, a minimal METHtality
core, a temporary intro/menu song, and temporary match-loop music/combat/UI
sounds. Missing or partial: gamepad support, stage select, final animation
cleanup (gated walk/crouch JPEGs for Peggy, uniform-scale re-exports for
Richard, unmapped `stage_intro`/`throw_target`/`crouch_down`), final
audio/voice/VFX, CPU AI, campaign, and final art. Online play is deferred beyond
v0.1 per GDD §2.4/§16.

**Readiness and audits:** [`docs/PHASE_STATUS.md`](docs/PHASE_STATUS.md) records
GDD phase requirements versus evidence and owner decisions. The
[`current-baseline reconciliation`](docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md)
records reproduced audit findings at `e6d40d9`; the
[`original audit`](docs/audits/2026-11-05_combat-feel-production-readiness-audit_d523ed0.md)
is preserved at its historical `d523ed0` baseline.

## Quick start

```bash
godot --path game                     # play
godot --headless --path game --script res://tests/combat_test.gd      # combat tests
godot --headless --path game --script res://tests/round_flow_test.gd  # round flow tests
godot --headless --path game --script res://tests/character_select_test.gd # select tests
godot --headless --path game --script res://tests/the_clip_test.gd    # intro tests
```

At startup, a 15-panel comic intro runs before character select. **Space**
advances the current beat or panel (dense copy may take extra presses);
**Esc** skips it. The intro never advances on a timer. P1 uses
**A/D + J** and P2 uses **arrow keys + Numpad 1** to choose and confirm a fighter.
The match begins after both players confirm; either player may change a locked
selection by moving again. Panel copy and deprecated hold values are in
`game/data/story/the_clip.panels`; art slots are in
`docs/story/the_clip_art_manifest.md`. Intro font sources/licenses are recorded
in `docs/ART_CREDITS.md`.

## Controls (current build)

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
the table above. Gamepad bindings and the in-game remap UI are not implemented
yet; GDD §4.1/§4.6 and §14 list them as requirements for later gates.

**EX specials:** hold Heavy (K / `.`) while pressing Special to spend 50 hype
meter on the strengthened version (PROPOSALS §5). Without enough meter the base
special comes out and nothing is spent.

**METHtality:** with a full meter, press METHtality (I / `'`) to spend the whole
bar on the finisher (PROPOSALS §4). Opponent health, state, and invulnerability
do not block activation; the move can still whiff if it cannot connect. Current
presentation is a freeze plus a banner; the normal KO flow ends the round. The
GDD's final-round finish prompt/cinematic is future work.

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

Debug: **F1** boxes (on by default), **F2** frame state + frame advantage +
invulnerability countdown, **F3** input history, **F4** slow motion, **F5**
frame-step (advances one sim frame per press while slow-mo is on and the pause
menu is closed), **F6** refill both fighters (full health and meter at round
positions, without restarting the round).

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
| `docs/PHASE_STATUS.md` | GDD phase/readiness status, evidence, and blockers |
| `docs/PROPOSALS.md` | Combat designs and measured air-special / landing-recovery first pass |
| `docs/audits/` | Preserved historical audits and current-main reconciliations |
| `docs/LICENSE_OPTIONS.md` | License decision report: all-rights-reserved vs CC BY-NC vs source-available |
| `docs/MAIN_BRANCH_GUARD.md` | Main-branch tripwire behavior, landing procedure and limitations |

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
  the engine does not hard-code per-fighter balance. The current match still
  preloads the two slice fighters. Regenerate via
  `godot --headless --path game --script res://tools/gen_fighter_data.gd`.
- **Combat boxes:** hitboxes and pushboxes are computed from `MoveData`; the
  hurtbox currently aliases the pushbox. Separate hurt/throw/proximity boxes
  remain planned (GDD §5.4; audit B9).
- Asset naming in `art/exports/`: lowercase snake_case
  (`spr_whiskey_richard_idle.png`, `stage_bus_stop_night_bg_far.png`).
- AI art pipeline: generate → save raw in `art/source/` → clean/pixel-fix →
  export into `art/exports/` only after review. Never edit `art/source/` files.

Current vertical slice: **Peg Leg Peggy** vs **Whiskey Richard** on
**The Bus Stop (Night)**.
