# COMBO_FINDINGS.md

Fuzz results for the Phase 1 combo layer (cancel graph, macros, Clip
Cancel, data-driven scaling) across both characters, both stages, and
pass-through on. Suite: `game/tests/combo_fuzz_test.gd`, seeded test-local
LCG (gameplay RNG untouched), headless Godot 4.7.2.

**Status on this branch: 78 checks, 0 failure(s)** — verified 10/10
consecutive identical runs (~50 s each, within the ~90 s CI budget).

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

| Match | Frames | Verdict |
|---|---|---|
| P vs R seed 11 (both stages) | 4579 | clean KO win |
| P vs R seed 29 (both stages) | 11755 | legit: a two-round timeout war (~5940x2) resolved by the third round |
| R vs P seed 11 (both stages) | 4606 | clean KO win |
| R vs P seed 29 (both stages) | 5208 | clean KO win |

- No stall anywhere: every match ends, no NaN or out-of-bounds, longest
  mutual-idle stretch far below the 240-frame watchdog.
- `SOAK_MAX_FRAMES` is now the measured worst plus ~25% margin:
  **15000** (was 40000, a blunt ceiling). A regression that stalls past it
  fails fast instead of hiding under a four-times-too-big limit.
- Win split at NORMAL: Richard 5, Peggy 3.

## Coverage note

Route-search, cap, and cross-up/side-switch checks run on **both stages**
(Gas-N-Go floor 158, Bus Stop floor 170) — earlier versions only exercised
Gas-N-Go.

## Skipped, feature not present

- Juggle point budget — not present in Phase 1 (Phase 2 will add it).
- Stuns — not present (Phase 3).
- Breaker — not present (Phase 3).
- CPU combo usage (strings/launchers/stuns as CPU behavior) — not merged at
  merge time (Phase 4); the CPU-vs-CPU soak still validates that matches
  end decisively with no stuck states.

## Notes

- Fuzzing uses a test-local seeded LCG only; the gameplay CPU RNG is never
  touched. No game/scripts/ or game/resources/ files were changed by this
  suite or its repairs.
