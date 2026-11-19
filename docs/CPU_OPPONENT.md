# CPU Opponent — Sidewalk Showdown

**Version:** v0.1
**Date:** 2026-11-19
**Purpose:** How the solo CPU opponent works: architecture, behaviors,
difficulty tuning, determinism, and how to run AI-vs-AI soak tests.

## 1. Architecture — same input path as a human

The CPU never touches `FighterBase` internals. Every simulation tick it
decides a set of held directions/buttons and issues them with
`Input.action_press` / `Input.action_release` on its fighter's own
`p<index>_<action>` names — the exact actions a keyboard or controller press
produces. Everything downstream is the human pipeline: `_poll_input`
buffering, move validation, blocking, throw techs, cancel rules, meter
spends. The CPU therefore cannot do anything a human could not:

- no skipped startup, no moves out of hitstun (impossible by construction —
  `game/tests/cpu_test.gd` pins this),
- no EX without paying `meter_cost` (the engine refuses it; pinned by test),
- no METHtality without a full bar.

The hook in `MatchRoot` is small: `p2_cpu` (solo), `p1_cpu` (debug AI-vs-AI),
`cpu_level`, and `cpu_seed`. `_setup_cpus()` attaches one
`game/scripts/ai/cpu_controller.gd` per CPU-controlled fighter with
`process_physics_priority = -100`, so each controller ticks **before** the
fighters poll input and **after** the previous frame fully resolved. It
reads only observable, completed-frame state — never node order, never the
human's button presses, never wall-clock time, never `delta`.

## 2. Determinism (rollback/replay requirement)

- The controller owns a small seeded 32-bit LCG (`rng_state`). No global RNG,
  no `delta`, no time, no node iteration order affects decisions.
- The seed is chosen once before gameplay: `MatchRoot.cpu_seed` (0 = drawn
  from the engine RNG at match start and recorded via `serialize()`), and
  recorded so a replay can pin it.
- The entire internal state — seed, RNG state, plan, plan frames, reaction
  countdown, idle watchdog, held buttons, last-observed states — is one flat
  dictionary via `serialize()` / `load_state()`, wired into
`MatchRoot.serialize()` (see `docs/SAVESTATE_PLAN.md`).
- `cpu_test.gd` proves: same seed + same scripted human inputs → identical
  per-frame state hash; different seed → different match; a mid-match
  save/restore of the AI state reproduces the same continuation.

## 3. Behaviors

All ranges come from the fighter's own `MoveData` hitboxes (light/heavy/
special/throw/METHtality reach), never magic numbers.

- **Approach and spacing**: walks toward the opponent when outside poke
  range; occasionally backs off when crowded (level-tuned `retreat_rate`).
- **Poke/attack**: inside light reach, taps light or heavy (`poke_rate`,
  `heavy_mix`); uses specials at special reach (`special_rate`) and takes
  the EX route when meter allows (`ex_rate`).
- **Blocking**: reacts to an observed attack startup after a fairness delay
  (`reaction_delay_frames`), then holds AWAY from the attacker using the
  shared `FighterBase.direction_away_from()` helper — correct against
  cross-ups and after a pass-through, by construction. A pre-block instinct
  (`preblock_rate`) covers unreactable jabs, the way real players do.
- **Anti-air**: reacts to an observed jump-in with a standing heavy
  (`anti_air_rate`) or blocks.
- **Throws**: throws an opponent that keeps blocking at close range
  (`throw_rate`); grabs forward for the command grab when authored.
- **Throw techs**: while grabbed, rolls `tech_rate` every tick inside the
  tech window.
- **METHtality**: only when the bar is full AND the finisher can reach —
  preferred as a punish, rare as a raw neutral activation.
- **Punish/pressure**: presses an attack when the opponent is in hitstun or
  getting up inside reach (`combo_rate`); wake-up reversal roll
  (`reversal_rate`); during its own confirmed attack it offers buffered
  buttons that only fire through authored cancel rules.
- **Corner escape**: pinned at a stage wall with the opponent closing, jumps
  out (`corner_jump_rate`) — pass-through lets the jump-over cross to safety.
- **Never stuck**: an idle watchdog (`idle_limit`) forces action if the CPU
  has idled too long; the soak asserts no long mutual-idle stretches.

Fairness mistakes are built in: every reaction waits the delay, and each
opportunity rolls a level-tuned probability — the CPU sometimes simply fails
to block, anti-air, tech, or punish.

## 4. Difficulty tuning (data, not code)

`game/scripts/ai/cpu_difficulty.gd` defines the knobs;
edit `game/resources/ai/cpu_easy.tres`, `cpu_normal.tres`, `cpu_hard.tres`.

| Knob | EASY | NORMAL | HARD |
|---|---|---|---|
| reaction_delay_frames | 22 | 14 | 8 |
| block_rate | 0.35 | 0.65 | 0.90 |
| anti_air_rate | 0.20 | 0.50 | 0.80 |
| tech_rate | 0.15 | 0.40 | 0.70 |
| throw_rate | 0.08 | 0.20 | 0.35 |
| poke_rate | 0.30 | 0.50 | 0.70 |
| heavy_mix | 0.20 | 0.35 | 0.50 |
| special_rate | 0.04 | 0.10 | 0.18 |
| ex_rate | 0.15 | 0.40 | 0.70 |
| meth_rate | 0.50 | 0.70 | 0.90 |
| combo_rate | 0.20 | 0.45 | 0.70 |
| reversal_rate | 0.10 | 0.30 | 0.55 |
| corner_jump_rate | 0.20 | 0.35 | 0.50 |
| preblock_rate | 0.003 | 0.010 | 0.025 |
| retreat_rate | 0.15 | 0.10 | 0.05 |
| idle_limit | 90 | 60 | 40 |

## 5. Menu flow

Solo (`1 PLAYER`) now goes **mode select → difficulty select → character
select**. The difficulty screen uses the existing text-menu style and input
conventions (A/D or W/S move, J or click confirm, Backspace back), defaults
to NORMAL, and the choice is remembered across matches like the other flow
choices. P1 remains the human and still picks both fighters in solo.

## 6. Debug AI-vs-AI

`MatchRoot.p1_cpu = true` plus `p2_cpu = true` makes both fighters
CPU-controlled — used by the soak test to run whole matches headless and by
balance capture (the debug overlay already prints side/facing). To watch a
full CPU match:

```sh
godot --path game   # no CLI flag; set via a small script or the test harness
```

or headless via the suite:

```sh
godot --headless --path game --script res://tests/cpu_test.gd
```

The soak section runs every character pairing (both P1/P2 orderings), both
stages, two seeds — 8 full matches — asserting each ends, health/meter stay
in bounds, no NaN, no stuck states, no long mutual idle, and a sane average
match length. It also prints win counts per character and average match
length for balance reading.

## 7. Test coverage

`game/tests/cpu_test.gd` (27 checks, ~25 s, wired into CI):

1. **Legality** — no move starts out of hitstun; no EX with unpayable meter
   (meter pinned low); health/meter/position bounds hold under HARD pressure.
2. **Determinism** — same seed + same scripted human inputs → identical
   frame-by-frame state hash; a different seed → a different match.
3. **Save/restore** — a serialized mid-match AI state restores to the same
   continuation.
4. **Blocking order** — against frontal, pass-through, and jump-over
   cross-up attacks (fixed seed, fixed positions), HARD defends more than
   EASY.
5. **Damage order** — HARD KOs a passive dummy faster than EASY.
6. **AI-vs-AI soak** — 8 matches across both pairings, both stages, two
   seeds: every match ends, all state in bounds, no long mutual idle.

Note on the harness: the suite steps the 60 Hz simulation manually for
speed, yielding one engine physics tick per step (tick rate briefly raised)
so `Input`'s just_pressed semantics match real play exactly.
