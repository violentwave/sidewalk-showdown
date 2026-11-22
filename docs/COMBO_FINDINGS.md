# COMBO_FINDINGS.md

Fuzz results for the combo layer (cancel graph, macros, Clip Cancel,
data-driven scaling, and — since Phase 2 — the juggle point budget and
routes) across both characters, both stages, both sides, and pass-through
on. Suites: `game/tests/combo_fuzz_test.gd` + `game/tests/combo_test.gd`,
seeded test-local LCG (gameplay RNG untouched), headless Godot 4.7.2.

**Status on this branch: combo_fuzz 118 checks, 0 failure(s); combo_test
68 checks, 0 failure(s); stun_breaker 55 checks, 0 failure(s)** (combo_fuzz
was 78/42 before the Phase 2 juggle coverage and 110 before the Phase 3
stun/breaker fuzz).

## History: findings that drove changes

### 1. Determinism "seeds diverge" — reclassified: harness flake (PR #76 class), not a game bug
- Original symptom: two separate match builds produced different per-frame
  states ("first diff at 0"), reported as an ambiguous rule / seed setup.
- Root cause (same as the cpu_test flake fixed in PR #76): the engine was
  still ticking the manually-stepped match. `_build_match` only disabled
  match physics before `add_child`; Godot re-enables a scene root's physics
  processing on tree entry in some paths, so the engine ticked the match a
  wall-dependent 4–10 frames during the build awaits and mid-script.
- Fix: the PR #76 belt-and-braces build (disable pre-add, post-add, and
  re-assert after the ready awaits with an `assert(not is_physics_processing())`
  guard), phase-driven intro, buffer-injected scripted presses — the same
  harness contract as `cpu_test.gd` / `combo_test.gd`.
- Result: two independent builds now give byte-identical per-frame
  fingerprints; the suite deliberately does NOT reuse one match, and it
  passes 10/10. No game-code regression; the stage's visual RNG
  (`randomize()`-seeded, presentation-only) never enters any state hash or
  `serialize()` output.

### 2. Counter-hit unit check — test-side bug (fixed in this branch)
- The COUNTER_HIT unit block originally built the match with the sides
  swapped, so `p2` was Peggy (whose heavy has no counter rule) and the check
  failed spuriously. Rebuilt as PEGGY vs RICHARD so `p2` is Richard and the
  authored `rhlk` rule fires. Classification: test-side, not a game bug.

## Soak (CPU vs CPU, NORMAL, seeds 11/29, both pairings, both stages)

Phase 1 (main `83f9573`, before the juggle economics):

| Match | Frames | Verdict |
|---|---|---|
| P vs R seed 11 (both stages) | 4579 | clean KO win |
| P vs R seed 29 (both stages) | 11755 | legit: a two-round timeout war (~5940x2) resolved by the third round |
| R vs P seed 11 (both stages) | 4606 | clean KO win |
| R vs P seed 29 (both stages) | 5208 | clean KO win |

Phase 2 (after the point budget + landing-gated combo window; per-match
frame counts now print from the suite):

| Match | Frames | Verdict |
|---|---|---|
| P vs R seed 11 (both stages) | 3921 | clean KO win, shorter than Phase 1 |
| P vs R seed 29 (both stages) | 13928 | legit multi-round timeout war, still no stall |
| R vs P seed 11 (both stages) | 4606 | unchanged |
| R vs P seed 29 (both stages) | 10867 | legit, longer than Phase 1 |

- No stall anywhere: every match ends, no NaN or out-of-bounds, longest
  mutual-idle stretch far below the 240-frame watchdog.
- `SOAK_MAX_FRAMES` stays **15000**: the Phase 2 worst (13928) still fits,
  with ~8% headroom (the old ~25% margin is gone, so a further length
  regression will fail fast rather than hide).
- Win split at NORMAL: Phase 1 Richard 5 – Peggy 3; Phase 2 **Richard 4 –
  Peggy 4**; average match length 6537 → 8330 frames (launcher combos
  extend rounds).

## Phase 2 findings (juggle economics)

### 3. Snapshot aliasing — real serialization bug (fixed)
- The new mid-juggle save/restore check diverged: a restored
  `ComboTracker` had the right hits/total but an EMPTY move history, so
  the variety bonus diverged on the next hit.
- Root cause: `ComboTracker.serialize()` returned its own `move_ids`
  array by reference (and `FighterBase`/`MatchRoot` likewise returned
  `wins`, `round_damage`, `macro_pending`, `input_buffer`,
  `input_history`). A snapshot held while the match kept running was
  silently cleared by the live game.
- Fix: every mutable container in `serialize()` is now a duplicate;
  `load()` semantics unchanged. Classification: real bug, found by the
  new test before any savefile/replay consumer could hit it.

### 4. Combo window expired mid-air — real balance bug (fixed)
- The real-route probe showed EX launcher "routes" paying MORE than the
  authored in-combo damage (Peggy EX 265 vs 256.40; Richard EX 300 vs
  293.55): the 40-frame combo window expired while the defender was
  still airborne (hitstun ends, HITSTUN -> JUMP_FALL, state leaves the
  protected set), so the late jump-in landed as a fresh unscaled combo.
- Fix: the window is gated on landing (`grounded`); grounded behavior is
  byte-identical, and the tracker now covers the whole air combo as the
  Phase 2 spec requires.

### 5. Peggy's base launcher cannot juggle — data finding, not fixed here
- With human timing (the attacker may only jump from an actionable
  state), Peggy's base launcher (228y) connects NO air follow-up: the
  defender lands (~f30) before the attacker's hitstop + recovery clear
  (~f34). Her route needs EX (50 meter). Richard's base (260y) connects
  the full route. Proposed (NOT applied): Peggy base `knockback.y`
  228 → ~255. See COMBO_SYSTEM_DESIGN §15.1 for the measured route and
  balance tables.

## Coverage note

Route-search, cap, cross-up/side-switch, juggle-route, and juggle-fuzz
checks run on **both stages** (Gas-N-Go floor 158, Bus Stop floor 170) —
earlier versions only exercised Gas-N-Go. The seeded juggle fuzz covers
every launcher (base + EX), both characters, both sides, pass-through
on: every sequence terminates (the defender lands and can act), the
budget never leaves [-1, 5], air hits never exceed the two the 5-point
budget can pay, and nothing goes NaN or out of bounds.

## Skipped, feature not present

- ~~Stuns — not present (Phase 3).~~ **Covered since Phase 3 (2026-11-21):**
  the `_stuns_and_breakers` fuzz (both matchups, seeds 4004/5005) lands the
  authored stun through the real resolver, mashes shake-out presses, and
  presses the breaker pair on scripted frames — asserting the window stays
  in [0, 45], stun never survives going airborne, breaker counters stay in
  bounds (free ≥ 0, cooldown ≤ 300, invuln ≤ 20), every fresh break came
  from HITSTUN, the stun hit builds no meter, and the defender always
  recovers. `stun_breaker_test.gd` (55 checks) covers the deterministic
  rails end to end.
- ~~Breaker — not present (Phase 3); the rejection-point hook is placed.~~
  **Covered since Phase 3** (see above): the breaker resolves only in
  HITSTUN (never blockstun, never neutral), once per combo, cooldown-gated,
  and both fighters were fuzzed as the breaking side.
- CPU combo usage (strings/launchers/stuns/breakers as CPU behavior) — not
  merged (Phase 4); the CPU-vs-CPU soak still validates that matches end
  decisively with no stuck states. The CPU does not press breakers or
  shake out yet (owner-approved Phase 4 scope), which also keeps the
  Phase 3 soak deterministic.

## Soak history

- Phase 2 (juggle economics): 3921–13928 frames, avg 8330, limit 15000.
- **Phase 3 (2026-11-21, Peggy 274 launcher + Taser Belch 105→40):**
  3092–5007 frames over the same 8 matches (both stages produce identical
  lengths per seed — shared bounds/spawns), avg ~3935, worst 5007 — a
  normal multi-round match, no stalls (mutual idle always < 240). Limit
  reset worst + ~25%: **6500**.
- **Phase 4 (2026-11-22, the combo CPU):** 3282–3896 frames over the same 8
  matches, avg ~3630, no stalls. Limits reset worst + ~25%:
  **combo_fuzz 4900**, **cpu_test 5000** (the old generic 40000 anti-hang
  ceiling is retired). Win split at NORMAL: Peggy 8–0. The bigger balance
  probe (24 matches per level, 6 seeds): NORMAL Peggy 24–0, HARD Peggy
  18–6 — recorded as a CHARACTER-balance finding in KNOWN_ISSUES
  (identical AI code both sides; Richard's average combo is bigger, he
  just wins neutral half as often).

## Notes

- Fuzzing uses a test-local seeded LCG only; the gameplay CPU RNG is
  never touched.
- `juggle_probe.gd` (fast, deterministic) prices every budget-legal
  launcher route and the candidate ladder retunes;
  `juggle_route_probe.gd` brute-forces real-hitbox route timing with
  human-timing constraints (~7 min, not in CI).
