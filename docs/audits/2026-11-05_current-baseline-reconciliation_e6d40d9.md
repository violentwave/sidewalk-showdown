# Combat-Feel Audit — Current-Main Reconciliation

**Purpose:** reconcile the read-only audit at `d523ed0` with current main without
rewriting its historical claims. The original audit is preserved verbatim at
[`2026-11-05_combat-feel-production-readiness-audit_d523ed0.md`](2026-11-05_combat-feel-production-readiness-audit_d523ed0.md).

| Baseline | Value |
|---|---|
| Historical audit SHA | `d523ed0fe591d556c0051041a34838cb87857d67` |
| Current baseline SHA | `e6d40d9607a0f0e3fc4a3be23ed592dbd9d43eda` (`balance: whiff landing recovery and measured air-special tune`, PR #11) |
| Engine | Godot `4.7.2.stable.official.ed1daf0bf` |
| Worktree | Detached, clean worktree from current `origin/main`; no tracked probe instrumentation |
| Current GDD phase placement | §13 Phase 2 — Vertical Slice, in progress; see [`../PHASE_STATUS.md`](../PHASE_STATUS.md) |

The original audit describes what was read and reproduced at `d523ed0`; its
environment, probe outputs, severities, and conclusions are intentionally left
unchanged. This document records what the current-main probes and source review
show. It is not a balance approval or a gameplay change proposal.

## Fresh baseline suites

The isolated worktree was imported first with
`godot --headless --path game --import` (**exit 0**), then the committed suites
were run sequentially. The complete logs and exit manifest are under
[`current-baseline-e6d40d9/logs/`](current-baseline-e6d40d9/logs/).

| Command | Result | Process exit |
|---|---:|---:|
| `combat_test.gd` | 124 PASS, 0 FAIL | 0 |
| `round_flow_test.gd` | 30 PASS, 0 FAIL | 0 |
| `air_probe.gd` | metrics-only report | 0 |

These pass results do not adjudicate the uncovered audit findings below.

## Environment and probe setup

- Godot `4.7.2.stable.official.ed1daf0bf`, headless.
- A detached worktree at `/tmp/opencode/sidewalk-audit-current-e6d40d9`
  checked out `origin/main` at `e6d40d9`; the main working tree and every
  tracked game file stayed unchanged.
- Fresh import was run before the suites. The imported `.godot/` cache is
  ignored and not part of the baseline.
- Probe scripts lived outside the repository and drove the real `MatchRoot`/
  `FighterBase` code with `SceneTree` scripts. They are not shipped test code or
  gameplay instrumentation. Logs are copied into
  `current-baseline-e6d40d9/logs/`; process exit codes are in
  `probe_exit_codes.txt` (all 0).
- The committed suites were run as separate processes. PASS/FAIL counts come
  from the full logs; process exit codes were captured independently and are not
  derived from `grep`/`tail` pipeline status.

## Current-main finding reconciliation

Status terms: **reproduced** means this report's probe observed the behavior on
`e6d40d9`; **not reproduced** means the baseline did not exhibit the original
claim; **inconclusive** means the source was reviewed but the current runtime
behavior was not measured. B6 has the additional explicit disposition
**partially addressed** because PR #11 changed the original behavior.

### Expected vs observed

- **B1 — expected:** a repeat strike into a defenseless knockdown should not be
  able to sustain a loop; the defender should have agency or invulnerability.
  **Observed:** ten repeated crouch-heavy hits landed with Richard in
  `KNOCKDOWN` throughout, reducing 1000 → 486.25 HP. With Richard's input
  enabled and holding away, five more hits landed; `is_blocking()` was false in
  knockdown and the defender never left that state during the loop.
- **B2 — expected:** the audit left knockdown-throw policy open; the test
  expectation is that no-tech damage and tech behavior are measured separately.
  **Observed:** an unteched grab dealt 95 and re-entered knockdown; a second
  repeated grab also landed before this exact setup returned the defender to
  neutral. A buffered grab within the tech window produced `TECH` on both
  fighters with zero damage. The single/tech behavior is reproduced; a longer
  five-loop duration was not sustained here, so loop length is inconclusive.
- **B3 — expected:** distinguish input registration from buffer aging and do
  not assume every early press should survive arbitrary stun/recovery.
  **Observed:** polling is gated by `input_enabled`; buffers age during hitstop
  and stun even while `state_frame` is frozen. A near-actionable 3f hitstop
  survived; 6f did not. Near-end blockstun survived; beginning-of-stun presses
  aged out before action.
- **B4 — expected:** post-separation pushboxes should have zero overlap even at
  the stage bounds. **Observed:** all four left/right wall arrangements kept
  5px overlap after clamping.
- **B7 — expected:** the audit treats wake-up blocking as an owner/playtest
  decision, not a proven bug. **Observed:** frames 0–5 reject both strike and
  throw; frames 6–7 reject throws; the full wake-up window ignores held-back
  block; a frame-6 meaty dealt damage; a buffered attack did not act.
- **B10 — expected:** the eventual round winner should remain in `WIN` during
  the KO phase. **Observed:** the already-polled nonlethal reply moved P1 from
  `WIN` to `HITSTUN` during KO; the round still went to P1.
- **B5 — expected:** if air drift is intended, starting an air attack should not
  instantly zero horizontal momentum. **Observed:** source review still finds
  unconditional `velocity.x = 0`; this task did not rerun the current momentum
  probe, so the runtime result is inconclusive.
- **B6 — expected (original):** a mid-move landing should not silently discard
  the aerial move's remaining recovery. **Observed:** PR #11 now applies the
  authored whiff landing lockout, but touchdown mid-move still skips the whiff
  meter grant that a move finishing in air receives.
- **B8 — expected:** GDD §5.3/§5.6/§5.10 call for authored cancel rules,
  counter-hit handling and a 35% scaling floor. **Observed:** cancel routes are
  engine rules, no counter-hit/juggle implementation is present, and the code
  floors at 55%.
- **B9 — expected:** GDD §5.4 calls for separate hurt/hit/push boxes. **Observed:**
  `hurtbox_rect()` aliases `pushbox_rect()`; no separate throw/proximity box is
  evidenced.
- **B11 — expected:** the informational items require no change by themselves.
  **Observed:** no new blocker is established; some are already covered by
  existing tests, while the dormant stance fallback remains only a future
  validation candidate.

| Finding | Result on current main | Current-main evidence and phase relevance |
|---|---|---|
| **B1 — strike loop on knockdown** | **Reproduced** | `knockdown_probe.log`: Peggy crouch-heavy (8/3/18, knockdown) repeatedly hit a no-input Richard pinned at the right corner. Ten knockdowns landed; Richard remained in `KNOCKDOWN`, HP 1000→486.25. A second run with Richard's input enabled and holding away landed five more hits; `is_blocking()` stayed false in knockdown. GDD §5.10 says no infinite combos. GDD Phases 1/3/9: combat correctness and regression coverage. |
| **B2 — throw on knockdown** | **Reproduced; loop length inconclusive** | `knockdown_probe.log`: an unteched grab against `KNOCKDOWN` dealt Peggy's 95 damage and restarted knockdown; a second repeated grab also landed before the exact setup returned the defender to neutral, so the audit's longer five-loop duration was not sustained here. A grab buffered at age 2 inside the 7f tech window instead put both fighters in `TECH` with no damage. GDD §5.11 calls throw tech optional; it does not define throws during knockdown. Owner must decide whether to reject these throws or retain the techable knockdown throw. |
| **B3 — buffer aging through hitstop/stun** | **Reproduced** | `buffer_probe.log`: input-disabled polling made no buffer; enabled polling created an age-1 buffer. A fresh age-0 buffer consumed in a near-actionable attack survived 3 hitstop ticks but not 6. Near-end blockstun survived; a beginning-of-blockstun press aged through 12f stun + 6f hitstop (age 18) and did not start; beginning-of-18f blockstun and first heavy-recovery frame also expired before action. The age cases seed a fresh buffer to isolate aging from event scheduling. This establishes behavior, not a policy that arbitrary early presses must survive long stun/recovery. GDD Phases 1/3/9. |
| **B4 — corner separation overlap** | **Reproduced** | `corner_trade_probe.log`: with 10px initial pushbox overlap, all four P1/P2 at left/right wall arrangements retained 5px overlap after `_separate_pushboxes()` and clamping. GDD §5.4 and Phases 1/3/9. |
| **B5 — air-attack momentum loss** | **Inconclusive on current runtime** | `FighterBase._start_move()` still unconditionally sets `velocity.x = 0`; `_attack_logic()` then decelerates it. The original d523 probe reproduced the stop. PR #11 changed air-special frame data/hitbox/damage, not momentum. GDD §13 Phases 1/5/9; decide whether to restore drift or keep the stop-on-attack style before another feel change. |
| **B6 — landing discards aerial recovery** | **Not reproduced as originally stated; partially addressed** | PR #11 added `MoveData.landing_recovery`, whiff-only landing lockout (8f jump normals, 12f air specials), immediate move/hitbox clear, and coverage for landing phases, hit/block, hitstop, interruption, pause, and reset. `b6_meter_probe.log` shows the remaining gap: landing mid-move ended in `LAND` with meter 0 despite `meter_gain_whiff=1.5`, while a move that naturally completed in air awarded 1.5. `finish_move_whiff()` is still not called when touchdown interrupts the move. GDD §5.3/§5.8 and Phases 3/9. |
| **B7 — vulnerable wake-up tail cannot block or act** | **Reproduced** | `wakeup_probe.log`: frames 0–5 reject strikes and throws; frames 6–7 accept strikes but reject throws; frames 8–11 accept both. Holding away reports `is_blocking=false` throughout `WAKE_UP`. A frame-6 strike while holding back dealt 35 damage. A buffered light did not start an attack during wake-up. GDD §5.11 defers character-specific wake-up defense; decide whether wake-up blocking is desired. |
| **B8 — implicit cancels/combo limits and scaling mismatch** | **Reproduced by source review** | `_try_cancel()` hardcodes routes; `MoveData` has no cancel-list/window field; no juggle limit or counter-hit implementation was found. `_damage_scale()` floors at 55%, while GDD §5.10 specifies 35%. GDD Phase 3/9; decide whether the GDD floor or implementation is authoritative and whether to author cancel/juggle rules. |
| **B9 — hurtbox aliases pushbox** | **Reproduced by source review** | `FighterBase.hurtbox_rect()` returns `pushbox_rect()`. No separate throw/proximity box or hitbox/hurtbox editor workflow is evidenced. The audit classifies this as a capability gap, not a demonstrated wrong result. GDD §5.4 and Phase 3. |
| **B10 — post-KO nonlethal reply changes winner state** | **Reproduced** | `corner_trade_probe.log`: simultaneous active lights, P2 at 1 HP. P1's hit KO'd P2 and entered KO phase; P2's already-polled 45-damage reply changed P1 from `WIN` to `HITSTUN` at 955 HP. The round still awarded P1; after the KO flow P1 was IDLE. GDD Phases 1/3/9. |
| **B11 — informational observations** | **Inconclusive / informational** | The fresh committed suites pass their existing hitstop/wakeup/stance paths. The documented dormant stance fallback and other audit notes remain useful validation candidates, not new fixes claimed by this report. |

### B6 and the air-probe audit claims

The audit's probe critique is preserved as a statement about the old script at
`d523ed0`. On current main, PR #11 changed `air_probe.gd` to run both attacker
directions and call `MatchRoot._resolve_hits()` for sampled outcomes. It now
reports geometry candidates separately from resolver-confirmed hits/blocks,
hitstop, trade outcomes, and attacker actionability. The old statement that the
current probe disables all hit resolution is therefore **addressed for the
current script**.

The probe is still not a full live-match or exhaustive balance test: it sets the
match phase to `MATCH_END`, manually resets positions, and disables automatic
pushbox separation/timer/round transitions while invoking the real resolver
directly. It samples only distances `[0,20,40,60,80]`, a fixed subset of air-start
frames (8 Peggy / 7 Richard), and three trade offsets. Damage ratios are direct
single-hit data comparisons, not combo/follow-up simulations, and no human
playtest is represented. The earlier 260px whiff distance was stage-clamped; PR
#11 corrected it to 170px. Thus the probe limitations are **partially addressed**,
not erased. The missed reach and blocked-advantage targets are preserved in
`docs/PROPOSALS.md` §3 and `docs/KNOWN_ISSUES.md`.

## Limitations

- B1/B2 used a manually pinned corner and directly started/restarted moves with
  the defender's input disabled. This proves the loop and throw behavior in the
  real state machine, not that every possible human escape route or spacing is
  absent.
- B3's registration cases use the engine's `Input.action_press`; the aging cases
  seed a fresh buffer and call exact fighter ticks to avoid render/event
  scheduling noise. They establish current aging behavior, not a proposed policy
  for whether an early press should survive arbitrary long stun. No latency or
  real-keyboard timing was measured.
- B4 measures one separation call at an exact 10px overlap for each wall/player
  arrangement, not sustained corner pressure across many frames.
- B7 forces `WAKE_UP`/frames and holds back through action state; it does not
  reproduce the full knockdown-to-wake-up transition for a human. Whether this
  is a defect is intentionally left to owner/playtest judgment.
- B10 constructs a deliberate same-frame trade with one-hit lethal health; it
  does not enumerate every trade/KO permutation.
- B5 was source-reviewed but not rerun as a current runtime momentum probe.
  B8/B9 are source-confirmed because the original audit labels them that way;
  this task did not build a new runtime measurement for either.
- The B6 meter check directly places a fighter at touchdown and separately lets a
  move finish naturally in the air; it does not measure a full jump arc.
- The fresh committed suites passing only proves their covered assertions. It
  does not resolve any behavior outside those assertions.

## Audit roadmap mapped to existing GDD phases

The audit's Stage 1–6 labels remain audit-roadmap labels only. They do not
renumber the GDD's Phase 0–11.

| Audit roadmap stage | Findings / work | Existing GDD placement |
|---|---|---|
| Stage 1 — Correctness | B1/B2 knockdown hit policy; B4 corner separation | Phase 1 combat-integrity prerequisite; Phase 3 core collision/resolve systems; Phase 9 regression tests. |
| Stage 2 — Input feel | B3 buffer aging/punish buffering | Phase 1 “hits feel responsive”; Phase 3 input systems/remapping; Phase 9 input-latency tests. |
| Stage 3 — Air game decisions | B5 momentum, B6 landing recovery, B7 wake-up defense | Phase 3 move/state systems and Phase 9 tuning/verification. B6 is partial via PR #11; B5/B7 require owner/playtest decisions. |
| Stage 4 — Combat depth | B8 cancel windows, juggle/OTG, counter-hit, scaling | Phase 3 reusable combat systems; GDD §5.3/§5.6/§5.10; Phase 9 tests/balance. |
| Stage 5 — Presentation | Audio/SFX, VFX, animation, fuller METHtality | Phase 2 vertical-slice sample, Phase 4 art-direction lock, Phase 8 audio/UI/juice. |
| Stage 6 — Vertical-slice shell | Select/menu flow, controller support, training stub | Phase 2 plus §14 first-playable/vertical-slice gates; Phase 3 remapping/training; Phase 7 only for story routes. |

## Decisions and blockers to carry into `PHASE_STATUS.md`

- B2: whether throws should connect/tech on knockdown or be rejected.
- B5: stop horizontal momentum on air-attack start or restore drift.
- B7: whether to permit block during the vulnerable wake-up tail (human
  playtest/design decision).
- B8: choose the damage-scaling floor (GDD 35% vs code 55%) and authorize
  authored cancel/juggle/counter-hit scope.
- §14: controller support is a first-playable must-have; decide controller
  mapping/testing approach. Character select is a Phase 2 recommended mockup.
- Phase 2 recommended cast differs from the current Peggy/Richard pair; confirm
  whether the GDD recommendation is flexible.
- B1/B3/B4/B10 are correctness/feel risks to close or explicitly disposition
  before claiming the combat foundation is broadly verified.
- Online remains deferred, not a current phase blocker; the GDD marks it a v0.1
  non-goal (§2.4) and an open later decision (§16).

No code changes are made or authorized by this reconciliation.
