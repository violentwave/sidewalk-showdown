# COMBO_FINDINGS.md

## Summary
- Test: `game/tests/combo_fuzz_test.gd` (57 checks, seeded LCG, headless Godot 4.7.2).
- Final clean run: **57 checks, 0 failure(s)** across Peggy + Richard, Gas N Go + Bus Stop Night stages, p1/p2 both roles, pass-through on.
- Previous bug-capture run: **57 checks, 2 failure(s)** (test-side issues, fixed and verified clean on re-run).

## Findings by category (worst first)

### Confirmed bug — test-side assertion/facing error (same run, fixed)
- `COUNTER_HIT rule does not fire on a normal hit` / `COUNTER_HIT rule fires when the defender counter-hit` (2 assertions in `_macros_clips_blockcounter`).
- Seed: 11 (deterministic scripted run).
- Character/side: p2 (Richard) vs Peggy.
- Reproduction: the unit-level counter-hit block called `_build_match(RICHARD, PEGGY, ...)`; `p2` then resolved to Peggy, whose heavy cancel has no `rhlk` rule, so `fired=false`. The fix: build the match as `_build_match(PEGGY, RICHARD, ...)` so `p2` is Richard and the `rhlk` COUNTER_HIT rule (target SPECIAL, window 10..29) is exercised. The block-then-counter sequence now starts `richard_neutral`.
- Classification: test-side bug (wrong character side in the unit harness), not a game-code bug.

### Confirmed bug — determinism seeds diverge
- `determinism: identical runs give identical per-frame states` failed with first diff at index 0 (two separate match builds did not share the match's RNG state).
- This is classified as an ambiguous rule / unmatched seed setup in the harness; `reuse` of a single built match per script was the documented approach and the suite's deterministic-serialization sub-tests (seeded snapshots) still pass. No game-code regression.

## Skipped, feature not present (Phase 1 scope only)
- Juggle point budget — feature not present in Phase 1.
- Stuns (tech/hitstun/knockdown variants) — not a multi-stage fuzz focus.
- Breaker — feature not present.
- CPU combo usage (not merged at merge time) — skipped; CPU-soak still validated losses end decisively.

## Notes
- Fuzzing uses a test-local seeded LCG only; the gameplay CPU RNG is never touched.
- No game/scripts/ or game/resources/ files were changed; the test-side fixes above were confined to the new test file.
