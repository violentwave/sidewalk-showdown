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

## Adversarial pass 2 (2026-11-22, `combo_adversarial_test.gd`)

An INDEPENDENT audit of the Phase 1-3 combo layer by an agent that did not
build those features. Suite: `game/tests/combo_adversarial_test.gd`, run on
the #76 harness (copied from `stun_breaker_test.gd`), test-local seeded
LCG only, both characters as P1/P2, both stages, both sides, pass-through
on. Local runtime ~30 s; CI step timeout 5 min.

**RULINGS LANDED (2026-11-22, `fix/adversarial-rulings`):** the suite now
runs **102 checks, 0 failure(s)**. Pre-ruling on the then-main it ran 74
checks with 4 failures; after the #89 breaker-rail fix (A1) and before the
A2/A3 rulings it ran 74 checks with 2 failures. The owner ruled on all four
findings; every ruling is implemented and pinned by new checks:

- **A1 — FIXED by #89** (the once-per-combo breaker rail clears with each
  fresh combo opening). This suite's A1 checks pass on current main and
  stay as regression pins.
- **A2 — FIXED BY OWNER RULING:** the breaker pair now persists through
  HITSTOP like the tech window — a single grab+special press on the impact
  frame of a long-hitstop hit (EX launchers, 10f) fires the breaker once
  hitstop ends, if the breaker is otherwise legal. Implemented as a
  serialized `breaker_pair_frames` latch that hitstop freezes (like the
  stun counters) and that expires with the breaker's own input window once
  hitstop serves; consumed with the pair on a break or a refused Clip
  Cancel, so it can never fire twice or ghost past the window. The 5-frame
  hitstop buffer freeze is unchanged for every other input. The landed
  METHtality (hitstop 30) is a KNOCKDOWN, so it stays unbreakable by the
  "otherwise legal" qualifier — pinned as a no-ghost case.
- **A3 — FIXED BY OWNER RULING:** a Clip Cancel refused for lack of meter
  CONSUMES the buffered grab+special pair, so a punish in that window can
  no longer convert it into the (free) breaker — the safe-cancel/break
  option-select is ruled out. With meter the cancel resolves exactly as
  before (25 meter, recovery-only).
- **A4 — ACCEPTED AS INTENDED:** an immunity-blocked stun attempt still
  spends that combo's once-per-stun budget; the shortest immunity outlives
  the combo window, so the budget refreshes with the next combo. No change;
  recorded in the design doc as intended behavior.

### A1. The 40-meter extra breaks were unreachable — CONFIRMED BUG (worst) — FIXED

- **Claim broken:** design decision #1 — "free once per round + 40-meter
  extras, 5 s cooldown". As shipped, a defender gets **one break per round,
  total**: after any break (free or paid), no later combo can ever be
  broken again that round, regardless of meter.
- **Repro (both defenders; Richard P1 vs Peggy P2 and the swap, Gas-N-Go;
  no seed dependence):** set `breaker_free_uses_left = 0`, meter 100; land
  a stand heavy; press grab+special → paid break, meter 100 → 60. Let the
  combo end NATURALLY (90 idle frames; `combo_hits == 0`, tracker inactive),
  clear the 300-frame cooldown (the 5 s have lapsed), land a fresh heavy —
  the defender is in HITSTUN in a brand-new combo — press grab+special:
  **refused**, meter stays 60.
- **Root cause:** `_tick_combo()`'s combo-end branch resets `combo_hits`,
  the tracker, and the juggle counters, but NOT `breaker_used_this_combo`.
  The flag is described as combo-scoped ("once-per-combo rail", and
  `stun_breaker_test.gd` 4c/4d hand-set it to `false` to simulate a new
  combo, so no existing test ever exercised the natural reset). Only
  `begin_round()`/`reset_state()` clear it, i.e. once per ROUND.
  `breaker_ready()` mirrors the stuck flag, so the future HUD would also
  show "no break" for the rest of the round.
- **FIXED (PR #89, verified by this suite on current main):** the rail
  clears on each fresh combo OPENING (the defender's `combo_hits` was 0
  before the hit) — the site the original report proposed, moved to the
  opening because the break itself zeroes `combo_hits`, so a natural
  combo-end reset alone would never run. Same-combo rejection and the
  300-frame cooldown are unchanged; the suite's A1 checks now pass and
  stay as regression pins.

### A2. A single break press was silently eaten by a 10f-hitstop impact — RULE CONSEQUENCE, FIXED BY OWNER RULING

- **Claim broken:** the breaker is the designated defense during hitstun,
  yet a deliberate single press of grab+special on the exact impact frame
  of any 10-hitstop move (both EX launchers; METHtalities at 30 are worse)
  never fired: the pair aged out before hitstop served.
- **Repro (both defenders; e.g. Peggy P1 forward EX, hitstop 10, vs
  Richard; and the swap):** land the EX launcher, press the pair EXACTLY
  once on the impact frame, step 16: no break, no meter spent, `grab` age
  11 at the end. Heavies (hitstop 6) broke fine on the same single press.
- **Mechanism:** the pinned 5-frame hitstop buffer freeze covers only 5 of
  the 10 hitstop ticks; the remaining 5 ticks aged the pair past the
  4-frame breaker input window before the breaker check ever runs (it
  lives past the hitstop early-return). A player who MASHES re-presses
  during/after hitstop and breaks normally — only the single deliberate
  press was lost, which is precisely the input a composed player makes.
- **OWNER RULING (2026-11-22) — the pair persists through hitstop, like
  the tech window:** implemented as the serialized
  `breaker_pair_frames` latch — armed in `_poll_input` whenever both
  authored actions sit in the buffer fresh (either input path), frozen by
  hitstop exactly like the stun counters (it ticks only past the hitstop
  early-return), expiring with the breaker's own 4-frame window once
  hitstop serves, and consumed with the pair on a break or a
  meter-refused Clip Cancel — so it can never fire twice or ghost past
  the window. The 5-frame hitstop buffer freeze is unchanged for every
  other input. Pinned for hitstop 6 and 10 as positive cases (single press
  at impact breaks), for the METHtality's hitstop 30 as the negative
  no-ghost case (the landed finisher is a KNOCKDOWN — "otherwise legal"
  excludes it), plus an illegal-breaker expiry case — both characters
  defending, both P1/P2 slots, both stages.
- **Related measured quirk (not a check failure):** the 5-frame freeze
  budget is SHARED across consecutive hitstops — an attacker who just
  landed a hit has burned most of it, so their own buffered pair ages
  faster if they are punished in the same window.

### A3. Clip Cancel / breaker option-select — FIXED BY OWNER RULING

- The two utilities share one input pair (grab+special). With meter, the
  pair in your own recovery is a Clip Cancel (25). With NO meter the
  cancel used to be refused with the pair left buffered — punished in
  that same window, the pair auto-converted into the (free) BREAKER on the
  first hitstun frame: mashing grab+special during whiffed recoveries was
  a safe-cancel-if-unpunished / free-break-if-punished option-select.
- **OWNER RULING (2026-11-22) — refused means consumed:** a Clip Cancel
  refused for lack of meter now erases the buffered pair (and the A2
  latch), so the option-select is gone. With meter the cancel resolves
  exactly as before. Pinned for both characters, both P1/P2 slots, both
  stages: the refused pair is consumed, a punish in that window produces
  NO break, and the with-meter cancel still fires (25 meter, recovery
  ends actionable).

### A4. An immunity-blocked stun attempt still burns that combo's once-per-stun budget — ACCEPTED AS INTENDED

- A stun move that CONNECTS during post-stun immunity deals its (scaled)
  damage and records its move id, so a second attempt inside the SAME
  combo is once-per-combo rejected even after immunity expires mid-combo.
- Measured while pinning the immunity boundary (see 3c): at
  `stun_immunity_frames == 1` the stun is rejected (damage lands); the
  landing attempt then had to wait for the combo to end. The shortest
  immunity (Peggy 60f) outlives the 40-frame combo window, so in practice
  the budget refreshes with the next combo — impact is minor.
- **OWNER RULING (2026-11-22) — accept as-is:** intended behavior, also
  recorded in `COMBO_SYSTEM_DESIGN.md` §10.5. No change.

### Verified clean (the attack list that found nothing)

- Breaker: immediate re-hit blocked by the 20f invuln then a fresh hit
  lands; break fires on the EXACT cooldown-end frame; 0-meter/0-free
  refuses and spends nothing; break during a stun ends the window and
  grants immunity; mid-juggle break kills the record, blocks the next air
  hit, and the defender lands actionable; break at the budget-rejection
  frame (1 point left) fires; a KO'd defender cannot break; blockstun
  opens no break; a new round re-arms the free break (both matchups).
- Stun: stun→launcher→mid-air re-stun never double-stuns (immunity starts
  at consumption); ladder-floor scaling shrinks the window to 25f and hit
  13+ (zero damage) stuns nothing; counter-hit stuns open the full window;
  shake-out ignores presses before the authored minimum and shortens by 3
  at it; a waking-up fighter past the invuln tail can be stunned (pinned
  as intended behavior); a blocked stun move stuns nothing and pays no
  meter. All on BOTH stages and BOTH stun attackers.
- Combined loops (seeded LCG, 8 runs: both stages × both matchups × 2
  seeds, one variant starting with the defender pinned at the wall): every
  run terminates with both fighters actionable, all scalars bounded
  (health/meter/stun/immunity/invuln/juggle/550-cap), no frozen
  fingerprint, and EVERY defender break at the wall separated somebody
  (the corner-escape transfer works under fuzz).
- Determinism: serialize/restore at EVERY frame of a 58-frame stun and a
  24-frame break window (not just random points) replays identically —
  82 fresh builds, zero mismatches.
- P1/P2 swap symmetry: identical stun damage, window, break cost, free
  count, and separation for the mirrored slots.
- Meter: the stun hit pays the attacker 0; a paid break costs exactly 40
  (45 → 5); a 39-meter defender never pays a partial break and the meter
  never goes negative.

### Earlier findings — status after this pass

- #1 harness flake (PR #76 class): re-verified clean (this suite uses the
  same belt-and-braces build; the every-frame determinism runs are the
  strongest two-build check yet).
- #2 counter-hit unit check (test-side): still owned by `combo_fuzz_test`
  (118 green); not re-tested here.
- #3 snapshot aliasing: FIXED and re-verified — a snapshot held through a
  full stun + combo reset keeps its tracker contents, and the every-frame
  restores above all pass.
- #4 mid-air combo expiry: FIXED and re-verified — the combo window
  survives the whole airborne arc (EX launcher).
- #5 Peggy's base launcher: FIXED at 274 and re-verified through real
  hitboxes — the authored route pays exactly 221.40 at jump f34 / drift
  90 / air-light delay 7 (note: delay 7 is the BASE-arc timing; the EX
  arc's delay 14 does NOT connect for the base launcher).
- Soak history: owned by `combo_fuzz_test` (118 green, limit 6500); not
  re-measured by this pass.
