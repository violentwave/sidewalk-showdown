# Sidewalk Showdown

**A mature-rated 2D retro pixel-art arcade fighter about a washed-up livestreamer
who turns sidewalk chaos into a rigged tournament.**

[![tests](https://github.com/violentwave/sidewalk-showdown/actions/workflows/tests.yml/badge.svg)](https://github.com/violentwave/sidewalk-showdown/actions/workflows/tests.yml)
[![export](https://github.com/violentwave/sidewalk-showdown/actions/workflows/export.yml/badge.svg)](https://github.com/violentwave/sidewalk-showdown/actions/workflows/export.yml)

<p align="center">
  <img src="docs/assets/screenshot-match.png" alt="Peg Leg Peggy vs Whiskey Richard on the Bus Stop, mid-round HUD" width="860">
</p>

| The Clip — intro | Select mode | Choose your fighter |
|---|---|---|
| <img src="docs/assets/screenshot-the-clip.png" alt="The Clip comic intro, panel 1" width="280"> | <img src="docs/assets/screenshot-mode-select.png" alt="Mode select with 1 Player and 2 Players options" width="280"> | <img src="docs/assets/screenshot-character-select.png" alt="Character select with Peggy and Richard" width="280"> |

| Choose your stage | Gas-N-Go, mid-round | Bus Stop, mid-round |
|---|---|---|
| <img src="docs/assets/screenshot-stage-select.png" alt="Stage select with Gas-N-Go, Bus Stop, and Random cards" width="280"> | <img src="docs/assets/screenshot-gas-n-go.png" alt="Peg Leg Peggy vs Whiskey Richard in front of the Everglades Gas-N-Go" width="280"> | <img src="docs/assets/screenshot-bus-stop.png" alt="Peg Leg Peggy vs Whiskey Richard in front of the lit Bus Stop liquor store and shelter fire" width="280"> |

| | |
|---|---|
| **Engine** | Godot 4.7 (`game/`) |
| **Target** | PC first — Windows / Linux / macOS |
| **Status** | GDD Phase 2 — vertical slice, in progress ([`docs/PHASE_STATUS.md`](docs/PHASE_STATUS.md)) |
| **License** | TBD — treat as all-rights-reserved until a LICENSE file lands ([`docs/LICENSE_OPTIONS.md`](docs/LICENSE_OPTIONS.md)) |

## What's playable today

- **Combos, Phase 1** — light chains into lights/heavies and cancels into
  specials on hit; Peggy has a blockstring (light chains on block), both
  fighters have counter-hit extensions; dial `L, L, H` quickly for a macro
  (BENCH WARMER / LAST CALL); press **special + grab during your move's
  recovery to Clip Cancel** for 25 meter (once per combo). Damage scaling,
  repeat-move penalties, and variety bonuses are all data-tuned
  ([`docs/COMBO_SYSTEM_DESIGN.md`](docs/COMBO_SYSTEM_DESIGN.md)).

- **Stuns & the combo breaker, Phase 3** — each neutral special is a themed
  stun (Peggy's **Peg-Lock** freeze keeps her 95 damage; Richard's **Taser
  Belch** trades down to 40 for a 45-frame window): the stunned defender
  mashes **up** to shake out after the unshakeable minimum, and both sides
  get post-stun immunity. Getting comboed? Press **grab + special together**
  while in hitstun (strings or juggles) to break out: free once per round,
  40 meter after that, on a 5-second cooldown — the break shoves both
  fighters apart and even a corner-pinned defender escapes. Peggy's base
  launcher was retuned (228 → 274 knockback) so her authored juggle route
  connects with human timing
  ([`docs/COMBO_SYSTEM_DESIGN.md`](docs/COMBO_SYSTEM_DESIGN.md) §15).

- **The Clip** — a 15-panel comic intro that leads into mode select, with
  Space-only advancement and a complete skip path.
- **Solo and local versus** — pick `1 PLAYER`, choose the CPU difficulty
  (EASY / NORMAL / HARD), then pick both fighters and fight the CPU as P2, or
  `2 PLAYERS` for Peg Leg Peggy vs Whiskey Richard.
  After the fighters, a shared **stage select** offers Everglades Gas-N-Go, the
  Bus Stop, and a RANDOM card that resolves before the match. P1 uses
  keyboard + mouse; P2 uses a controller in versus. The CPU opponent is
  deterministic and plays by the exact same input rules as a human — see
  [`docs/CPU_OPPONENT.md`](docs/CPU_OPPONENT.md).
- **Two layered stages with ambience** — Gas-N-Go scrolls clouds, loops
  mosquitoes in the upper sky, and breathes/blinks a sunbathing gator; Bus Stop
  scrolls its own clouds, loops a four-frame shelter fire, and flickers the
  liquor sign. Ambient motion freezes with the pause menu and keeps running
  through hitstop ([`docs/STAGES.md`](docs/STAGES.md)).
- **Authored sprite animation** — both fighters play per-state and per-move
  clips from the owner's PixelLab batch: jumps, walks, guard, hit reactions,
  knockdown/wake-up, and all 16 attack rows per fighter
  ([`docs/PIXELORAMA_PIPELINE.md`](docs/PIXELORAMA_PIPELINE.md) §8–§9a).
- **Fighting-game systems** — 60 Hz deterministic simulation, frame data,
  blocking with chip that can't KO, hitstop, buffers, directional specials,
  EX spenders, throws and throw techs, launcher juggles on a point budget
  (5 points at launch; air normals cost 2, air specials 3), a METHtality
  finisher, and
  side switching: fighters auto-face each other and can walk through each
  other on the ground and in the air (the `fighters_can_pass_through` flag
  restores the legacy grounded pushbox) —
  [`docs/SIDE_SWITCHING.md`](docs/SIDE_SWITCHING.md).
- **Match structure** — rounds, timer, sudden death after repeated timeouts,
  KO flow, pause menu, and a text-only Tripp commentary sample.

Not in yet: input remapping, campaign, stage rotation/tournament order,
final audio/voice/VFX, and final art/cleaning for some clips. The solo CPU
opponent now uses the full combo system (authored route walking, juggles,
stuns, breaker, Clip Cancel — Phase 4's CPU half, 2026-11-22) but stays
deliberately simple — no fuzzy guard, no character-specific gameplans; it is a fair
sparring partner, not a tournament opponent. Online play is deferred beyond v0.1
per GDD §2.4/§16.

## Quick start

Requires **Godot 4.7.x** (the project reports `4.7.2`).

```bash
godot --path game                # play
godot --headless --path game --import   # first run: build the import cache

# test suites (all headless, all deterministic)
godot --headless --path game --script res://tests/combat_test.gd
godot --headless --path game --script res://tests/round_flow_test.gd
godot --headless --path game --script res://tests/character_select_test.gd
godot --headless --path game --script res://tests/locomotion_speed_test.gd
godot --headless --path game --script res://tests/stage_select_test.gd
godot --headless --path game --script res://tests/stage_floor_test.gd
godot --headless --path game --script res://tests/cpu_test.gd
godot --headless --path game --script res://tests/combo_test.gd
godot --headless --path game --script res://tests/combo_fuzz_test.gd
godot --headless --path game --script res://tests/stun_breaker_test.gd
godot --headless --path game --script res://tests/the_clip_test.gd
godot --headless --path game --script res://tests/serialization_test.gd
godot --headless --path game --script res://tests/b6_landing_whiff_test.gd
godot --headless --path game --script res://tests/ui_flow_test.gd
godot --headless --path game --script res://tests/settings_test.gd
godot --headless --path game --script res://tests/ui_assets_test.gd
godot --headless --path game --script res://tests/ui_typography_test.gd
```

Current suites: **combat 408 checks**, round flow 34, character select 54,
locomotion speed 7, stage select 94, stage floor 9, CPU opponent 41,
combo system 68, combo fuzz 118, stun & breaker 55, The Clip 23,
serialization 24, B6
landing-whiff 5, UI flow 52, settings 16, UI assets 4, UI typography 10
— all green in CI (`tests.yml`, every step under a `timeout-minutes`).
`tests/air_probe.gd` and `tests/juggle_probe.gd` print balance metrics and
assert nothing; `tests/juggle_route_probe.gd` brute-forces real-hitbox juggle
route timing (slow, not in CI).

## Controls

**P1 plays on keyboard + mouse; P2 plays on a controller.** Any connected pad
drives P2, using either the d-pad or the left stick to move. The pad layout is
GDD §4.2's: X light, Y heavy, B special, A grab, right shoulder for the
METHtality finisher.

The front-end flow (UI Phase 1 + the polish pass, see
`docs/UI_SCREENS.md` for the typography rules and
`docs/assets/ui/` for screenshots): boot shows a one-time **content
warning** (press confirm to continue — it never skips itself), then The
Clip, then the **title screen** (PRESS START), then the **main menu** —
Tripp's gas-station price board, centered over the Gas-N-Go night art
with its pole planted on the stage floor: VERSUS, TRAINING (coming
soon), SETTINGS, EXTRAS (coming soon) on the slats, and QUIT on a
button taped to the pole. Menus are set in the project's own Sidewalk
Marker pixel font with m5x7 body text; nothing is outlined or smoothed.
Menus run on the P1 keys below; a pad can confirm (A) and back (B) with
its face buttons. SETTINGS opens the settings overlay (video, audio,
gameplay, accessibility, stream tabs; saved to `user://settings.cfg`), and
QUIT asks "Leave the sidewalk?" with NO as the safe default.

![Content warning](docs/assets/ui/content_warning.png)
![Title](docs/assets/ui/title.png)
![Main menu](docs/assets/ui/main_menu.png)
![Settings](docs/assets/ui/settings_video.png)
![Pause](docs/assets/ui/pause.png)
![Quit confirm](docs/assets/ui/quit_confirm.png)

- **VERSUS** opens mode select on `1 PLAYER` (solo) with `2 PLAYERS` one
  keypress away (W/S or A/D to move, J or click to start; Backspace
  returns to the main menu):

- **1 PLAYER:** choose the CPU difficulty (EASY / NORMAL / HARD, W/S or A/D,
  J confirms, Backspace goes back), then P1 picks their fighter, confirms, and
  picks the opponent with the same keys. P2 is played by the CPU at the chosen
  difficulty. Backspace steps back one pick, then back to mode select.
- **2 PLAYERS:** each player confirms their own fighter (P1 with J/click, P2 with
  pad X). Backspace on the P1 keyboard returns to mode select.

After both fighters are confirmed, **stage select** opens with Gas-N-Go, Bus
Stop (Night), and RANDOM last. W/S, A/D, the d-pad, or the stick move the shared
cursor; J/click or pad X confirms; Backspace returns to character select with
the same matchup. RANDOM resolves to a real stage before the match starts. The
match then loads the chosen stage and starts the round.

| Action | P1 keyboard / mouse | P2 controller |
|---|---|---|
| Move | A / D | D-pad or left stick |
| Jump | W | D-pad up or stick up |
| Crouch | S | D-pad down or stick down |
| Light attack | J or left click | X |
| Heavy attack | K or right click | Y |
| Special | L or middle click | B |
| Grab / throw | U | A |
| METHtality | I | Right shoulder (RB/R1) |
| Pause | Esc | Start / Menu |

- **Block** by holding away from the opponent (down-away blocks lows), including
  during blockstun. Chip damage cannot KO — a blocked hit always leaves 1 HP.
- **EX specials:** hold Heavy while pressing Special to spend 50 meter on the
  stronger version; without meter the base special comes out for free. The
  meter builds **only when you land hits** (throws included): blocked hits,
  whiffs, and taking damage award nothing.
- **METHtality:** with a full meter, press METHtality to spend the whole bar.
  Current presentation is a freeze plus banner; the normal KO flow ends the round.
- **Specials are directional:** neutral, forward, back, down, and air (GDD §4.4).
- `Enter` restarts after a match ends. Pause menu drives with W/S, the d-pad or
  stick, or arrows; J, X, or Enter picks. Options are **Resume**, **Settings**
  (overlay above the paused match), **Restart Match**, **Back to Character
  Select**, **Main Menu**, and **Quit to Desktop** (through the
  "Leave the sidewalk?" confirm, which defaults to NO). Back to
  Character Select discards the in-progress match with no winner, keeps the
  current mode, and restores the matchup you were just playing.

Debug keys: **F1** boxes (on by default), **F2** frame state/advantage/invuln,
**F3** input history, **F4** slow motion, **F5** frame-step, **F6** refill both
fighters. The input map is generated, not hand-edited: change the tables in
`game/tools/setup_input.gd` and run
`godot --headless --path game --script res://tools/setup_input.gd`, then restore
the `[physics] 60 Hz` entry that `ProjectSettings.save()` drops (the tool says so).

## Builds

Pushing to `main` (or a `v*` tag) exports both desktop targets: a Linux x86_64
binary and a Windows x64 `.exe`, each with the PCK embedded as a single runnable
file. Grab them from the **Artifacts** section of an `export` run in the Actions
tab, named `sidewalk-showdown-linux-<sha>` / `sidewalk-showdown-windows-<sha>`
(kept 14 days).

Presets live in `game/export_presets.cfg` (`linux`, `windows`). Locally, with
Godot 4.7.2 export templates installed:

```bash
godot --headless --path game --import
godot --headless --path game --export-release linux build/linux/sidewalk_showdown.x86_64
godot --headless --path game --export-release windows build/windows/sidewalk_showdown.exe
```

> The repo is public, so Actions minutes and artifact storage are not billed.
> Both targets build and both artifacts upload successfully on every `main`
> push; the last verified run published a ~54 MB Linux binary and a ~64 MB
> Windows `.exe`. The workflow still downloads Godot's export templates per run
> instead of caching the ~1 GB bundle, which keeps each job independent of a
> stale cache at a cost of about a minute.

## Repository map

```text
game/                  Godot 4.x project
  scenes/              match, fighters, stages, menus, HUD
  scripts/             combat, match, ui, debug, stages, audio
  resources/           data resources: fighter stats/moves, stages, match roster
  tests/               headless suites + manual render/soak harnesses
  tools/               data generators, input setup, screenshot/README capture
  art/                 runtime art (idle sheets, authored clip libraries)
art/source/            raw owner-supplied batches (never cleaned in place)
  Characters/Animations/generated/full_animation_batch_01/
                       source sheets, prepared strips, per-clip manifests
art/tools/             reproducible prep scripts for the animation batches
art/exports/           cleaned, snake_case, runtime-ready static art
docs/                  supporting docs, audits, pipeline notes, screenshots
```

## Documentation

| Doc | What it covers |
|---|---|
| [`docs/PHASE_STATUS.md`](docs/PHASE_STATUS.md) | GDD phase requirements vs evidence, decisions, blockers |
| [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) | Prototype gaps, test inventory, known limitations |
| [`docs/PIXELORAMA_PIPELINE.md`](docs/PIXELORAMA_PIPELINE.md) | Idle-sheet + authored-clip pipeline for both fighters (§8–§9b) |
| [`docs/STAGES.md`](docs/STAGES.md) | Gas-N-Go layers/ambience, thumbnail regeneration, stage select, adding a stage |
| [`docs/PROPOSALS.md`](docs/PROPOSALS.md) | Combat system proposals and measured first passes |
| [`docs/ART_CREDITS.md`](docs/ART_CREDITS.md) | Art provenance, font licenses, all-rights-reserved notes |
| [`docs/MAIN_BRANCH_GUARD.md`](docs/MAIN_BRANCH_GUARD.md) | Why `main` only accepts squash-merged PRs |
| [`docs/audits/`](docs/audits) | Preserved historical audits and reconciliations |
| [`GAME_BIBLE.md`](GAME_BIBLE.md) | Story/world canon (Tripp, roster, stages, METHtalities) |
| [`GDD.md`](GDD.md) | Full design and production plan |
| [`CHARACTERS.md`](CHARACTERS.md) | Roster bible (archetypes, rivals, data direction) |

**Canon locks:** Tripp Vlogs is the only boss and is not playable. Roster = 15
fighters, one unique METHtality each. No real towns, brands, or public figures —
this is fictional "Sidewalk Florida".

## Architecture rules

- **Simulation is a fixed 60 Hz clock.** Frame data, hitstun, blockstun,
  hitstop, and buffer windows are all in simulation frames; presentation
  counters advance on the same clock so pause and hitstop freeze everything.
- **Fighters are data.** `game/resources/fighters/*.tres` define stats and
  moves; combat code never hard-codes per-fighter balance. Regenerate with
  `godot --headless --path game --script res://tools/gen_fighter_data.gd`.
- **Art is layered.** Source batches stay byte-for-byte untouched in
  `art/source/`; normalized strips and manifests are produced by
  `art/tools/prepare_*_batch.py`; runtime copies live in
  `game/art/characters/*/clips/`. Idle sheets remain the approved fallback for
  any gated or missing clip.
- **Presentation never changes gameplay.** Clip tables control which cel and
  cadence are shown; damage, timings, hitboxes, knockback, movement, collision,
  buffers, cancels, invulnerability, hitstop, and round rules stay in the sim.

## Contributing

`main` is squash-merge-only. Branch from `origin/main`, open a PR, wait for
`tests` to pass, then squash-merge
([`docs/MAIN_BRANCH_GUARD.md`](docs/MAIN_BRANCH_GUARD.md)). Keep gameplay data
changes separate from presentation-only changes, and run the headless suites
before pushing: `combat`, `round_flow`, `character_select`, `stage_select`,
`stage_floor`, `locomotion_speed`, `cpu`, `combo`, `the_clip`,
`serialization`, `b6_landing_whiff`, plus `combo_fuzz`, `stun_breaker`,
`ui_flow`, `settings`, and `ui_assets` (see `docs/PM_BRIEF.md` §5 for the
exact commands; every CI step has a `timeout-minutes`).
