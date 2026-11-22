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
  (`reversal_rate`).
- **Combo offense (Phase 4, design §12)**: on a hit-confirm of its own
  attack, the CPU walks the AUTHORED cancel graph — it picks a window-open
  rule matching the outcome (HIT/BLOCK/COUNTER_HIT) at `string_rate`, up to
  `route_depth` continuation steps per combo, gated on reach, with a random
  choice among eligible edges so it never loops one combo. SPECIAL targets
  dial the flavor: forward-held = the launcher (`launcher_rate`), neutral =
  the stun special (`stun_rate`); a declined offer presses nothing.
- **Launcher strings and juggles**: a confirmed launcher arms the JUGGLE
  plan — jump toward on the first actionable frame (the held direction does
  the drift; no velocity injection), press the authored air light/heavy
  while the defender's point budget can pay, end on landing or a spent
  budget (`juggle_rate` gates chasing at all).
- **Stun-then-string**: at special reach the neutral special is the stun
  fish (`stun_rate`); once the stun lands, the string continues into the
  window through the same authored routes.
- **Clip Cancel**: a blocked move with meter resolves via the 25-meter
  recovery-only cancel (`clip_cancel_rate`) or an authored BLOCK-condition
  blockstring.
- **Breaker (defense, Phase 4)**: on entering hitstun the attempt arms
  behind the fairness reaction delay, then rolls `breaker_rate` gated by
  `breaker_ready()` and a worth-it rule — the free break always; a PAID
  break only at low health, cornered, or against a 60+ damage combo
  (measured off the fighter's own defender-side tracker). Never in
  blockstun. The engine enforces the once-per-combo rail and the 300-frame
  cooldown.
- **Stun shake-out**: mashes the authored direction past the authored
  minimum (`shake_rate`); being juggled holds the juggle-fall drift AWAY
  from the attacker.
- **Corner escape**: pinned at a stage wall with the opponent closing, jumps
  out (`corner_jump_rate`) — pass-through lets the jump-over cross to safety.
- **Never stuck**: an idle watchdog (`idle_limit`) forces action if the CPU
  has idled too long; the soak asserts no long mutual-idle stretches.

Fairness mistakes are built in: every reaction waits the delay, and each
opportunity rolls a level-tuned probability — the CPU sometimes simply fails
to block, anti-air, tech, punish, string, or break.

**Phase 4 combo status (2026-11-22):** the CPU now uses the full combo
system — authored route walking (blockstrings, macro-style chains, launcher
strings, stun-then-string), juggle chases within the point budget, Clip
Cancel on blocked moves, the breaker with per-difficulty rates and the
fairness reaction delay, stun shake-out, and juggle-fall drift. Everything
still goes through the human input path; the determinism and soak suites
verify it unchanged in contract (see §7 for the new checks).

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
| string_rate | 0.15 | 0.40 | 0.65 |
| route_depth | 1 | 2 | 3 |
| launcher_rate | 0.10 | 0.25 | 0.45 |
| stun_rate | 0.05 | 0.12 | 0.22 |
| juggle_rate | 0.10 | 0.35 | 0.60 |
| breaker_rate | 0.04 | 0.25 | 0.50 |
| clip_cancel_rate | 0.02 | 0.10 | 0.25 |
| shake_rate | 0.15 | 0.35 | 0.60 |

The Phase 4 knobs (COMBO_SYSTEM_DESIGN §12): `string_rate` is the chance to
continue a confirmed string through an authored cancel edge; `route_depth`
caps continuation steps per combo; `launcher_rate`/`stun_rate` dial the
special flavor (forward launcher vs neutral stun fish); `juggle_rate`
gates chasing a launched opponent; `breaker_rate` rolls the grab+special
break attempt after the reaction delay (free always, meter only when
worthwhile); `clip_cancel_rate` burns 25 meter out of a blocked move's
recovery; `shake_rate` mashes the stun shake-out past the authored minimum.

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
stages, two seeds — 8 full matches — asserting each ends inside the honest
limit (measured worst + ~25%), health/meter stay in bounds, no NaN, no
stuck states, no long mutual idle. It prints per-match frame counts, win
counts, and the average length for balance reading.

### Soak results (2026-11-22, the Phase 4 combo CPU)

CI soak (NORMAL, seeds 11/29, 8 matches): 3282–3896 frames, no stalls,
**Peggy 8–0 Richard** — limit reset to 5000 (cpu_test) and 4900
(combo_fuzz).

The bigger balance probe (report only, not in CI — 24 matches per level:
both pairings, both stages, 6 seeds each):

| Level | Win split (24 matches) | Worst / avg length |
|---|---|---|
| NORMAL | **Peggy 24 – Richard 0** | 4107 / 2752 frames |
| HARD | **Peggy 18 – Richard 6** | 9042 / 5380 frames |

Per-character usage over those 24 matches:

| Metric | Peggy (NORMAL) | Richard (NORMAL) | Peggy (HARD) | Richard (HARD) |
|---|---|---|---|---|
| Avg combo damage | 136.9 (388 combos) | 148.1 (216 combos) | 138.1 (384 combos) | 144.5 (334 combos) |
| Connected launchers | 110 | 86 | 188 | 166 |
| Stuns applied | 30 | 16 | 24 | 16 |
| Breakers fired | 32 | 50 | 42 | 48 |
| Clip Cancels | 48 | 28 | 44 | 34 |

**Reading:** Peggy's dominance is NOT the AI favoring her — both CPUs run
the same controller and the same knobs; there is no per-character AI code.
Richard's average combo is BIGGER (148 vs 137 at NORMAL), so when he wins
neutral he converts at least as well; he simply wins neutral half as often
(216 combos landed vs Peggy's 388). Peggy's faster pokes win the
interaction war, and the win split predates the combo CPU (the Phase 3
soak was already 8–0 after her 274 launcher fix). HARD narrows it to 18–6
because the higher block/anti-air rates suppress the jab war. This is a
character-balance finding (neutral speed), recorded in
`docs/KNOWN_ISSUES.md`; nothing was tuned in this pass.

## 7. Test coverage

`game/tests/cpu_test.gd` (41 checks, ~60 s, wired into CI):

1. **Legality** — no move starts out of hitstun; no EX with unpayable meter
   (meter pinned low); health/meter/position bounds hold under HARD pressure.
2. **Determinism** — same seed + same scripted human inputs → identical
   frame-by-frame state hash; a different seed → a different match.
3. **Save/restore** — a serialized mid-match AI state restores to the same
   continuation.
4. **Blocking order** — the frontal reactable-special ordering runs against
   a defense-only difficulty (all offense knobs zero) so the Phase 4 combo
   offense cannot crowd out the measured block; deterministic forced
   stale-facing cross-ups (grounded and airborne) verify blocking resolves
   from POSITIONS through the shared side helper, with HARD > EASY.
5. **Damage order** — HARD KOs a passive dummy faster than EASY.
6. **Combo order (Phase 4)** — a measured CPU (EASY vs HARD) sparring a
   fixed HARD partner: HARD banks more combo damage, connects more
   launchers, applies more stuns, fires more breakers, and Clip Cancels at
   least as often; a coverage check proves the window exercised all three.
7. **Combo legality under fire (Phase 4)** — HARD vs HARD with full meter:
   no breaker ever resolves from blockstun, no move starts out of hitstun,
   bounds hold — and the window provably exercised breaks, stuns, and
   launchers.
8. **Phase 4 determinism + mid-event restore** — a HARD CPU-vs-CPU match
   replays identically from the seed alone; AI-state snapshots taken
   mid-COMBO, mid-STUN, and mid-BREAK restore to identical continuations
   (covering the new combo_depth/break_armed/juggle_step state).
9. **AI-vs-AI soak** — 8 matches across both pairings, both stages, two
   seeds: every match ends inside the honest limit, all state in bounds,
   no long mutual idle.

Note on the harness: the suite steps the 60 Hz simulation manually for
speed, yielding one engine physics tick per step (tick rate briefly raised)
so `Input`'s just_pressed semantics match real play exactly.
