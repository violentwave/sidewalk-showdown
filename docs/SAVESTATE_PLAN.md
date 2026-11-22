# Save/Load State Plan — Sidewalk Showdown

**Version:** v0.2 (adds the AI state object)
**Date:** 2026-11-19
**Purpose:** Inventory of what a full match save/replay/rollback needs to
capture, and where it lives today.

## Current state (implemented)

`MatchRoot.serialize()` / `MatchRoot.load()` capture the whole match:

- Match flow: `phase`, `phase_frame`, `round_number`, `wins`, `timer_frames`,
  `ko_loser`, `ko_draw`, `ko_frame`, `sim_frame`, `timeout_ties`,
  `sudden_death`, `round_damage`.
- UI/flow flags: `pause_index`, `pause_menu_open`,
  `commentary_sample_shown`.
- Match rules: `p2_human`, `p2_cpu`, `p1_cpu`, `cpu_level`, `cpu_seed`,
  `fighters_can_pass_through`.
- Both fighters via `FighterBase.serialize()`: positions, velocities, state,
  state frames, health, meter, facing, buffers, stun/knockdown/wake-up
  timers, hitstop, combo/juggle counters, plus the Phase 1 combo state:
  the per-defender `ComboTracker` record (hits, total damage, move-id
  history, active flag), the dial-a-combo macro ring (active macro, step
  index, held steps, gap clock), the Clip Cancel budget flag, and the
  BLOCK/WHIFF outcome flags. Phase 2 adds the juggle point budget:
  `juggle_hits` and `juggle_points` (−1 = no active air budget) serialize
  with the fighter and restore exactly (mid-juggle round-trip pinned in
  `combo_test.gd`).
- **Stun state (Phase 3, 2026-11-21):** `stun_id`,
  `stun_frames_remaining`, `stun_window_applied`, `stun_min_frames`,
  `stun_shake_presses`, `stun_shake_per_press`, `stun_grant_immunity`,
  `stun_immunity_frames` — the whole stun window (post shake-out) and its
  granted immunity round-trip mid-stun (pinned in
  `stun_breaker_test.gd`). The tint is re-derived from the stun id through
  the authored `StunEffect` on load, so the dictionary stays plain data.
- **Breaker state (Phase 3, 2026-11-21):** `breaker_free_uses_left`
  (round-scoped, re-armed from `FighterData.breaker_free_per_round` in
  `begin_round`), `breaker_cooldown_frames`, `breaker_used_this_combo`,
  `breaker_invuln_frames`, and the separating push
  (`breaker_push_dir`, `breaker_push_self_px`,
  `breaker_push_other_px`, `breaker_push_frames`) — mid-break snapshots
  restore cooldown and invulnerability exactly (pinned in
  `stun_breaker_test.gd`).
- **Snapshot stability (2026-11-21):** every mutable container in
  `serialize()` (`wins`, `round_damage`, `move_ids`, `macro_pending`,
  `input_buffer`, `input_history`) is a DUPLICATE, so a snapshot held
  while the match keeps running is never mutated by the live game (the
  mid-juggle round-trip test caught the old by-reference aliases).

Covered by `game/tests/serialization_test.gd` (key inventory + round trip).

## AI state object (added 2026-11-19)

Each CPU controller (`game/scripts/ai/cpu_controller.gd`) serializes its
ENTIRE internal state as one flat dictionary under `cpu_p1` / `cpu_p2`:

- `seed`, `rng` (the controller's own LCG state),
- `plan`, `plan_frames` (current behavior plan),
- `react` (fairness reaction countdown),
- `idle` (watchdog counter),
- `held` (held-button bitmask, restored by re-issuing the actions),
- `last_opp_state`, `last_own_state`, `last_opp_grounded`
  (event-edge detection state).

A restored controller resumes an identical continuation — proven in
`game/tests/cpu_test.gd` (save/restore section): a mid-match snapshot +
restore reproduces the same per-frame state hashes as a straight-through
run of the same seed.

## Not yet saved (known gaps, deliberate)

- Stage presentation clocks (fire loop, cloud scroll, sign flicker): they
  use the visual-only RNG on purpose and are excluded so gameplay
  determinism never depends on them.
- HUD presentation state (timer/health displays re-derive from fighters on
  load).
- The Clip intro and menu flow: out of match scope.
- Rollback input history (per-frame P1/P2 input log for netcode): the
  serialization is designed to be per-frame snapshot-able, but no rollback
  buffer exists yet; the CPU's determinism guarantee (fixed seed + prior
  frame observability) is the precondition for it.
