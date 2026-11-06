# Known Issues — Phase 2

GDD §13 Phase 1 greybox features and basic flow paths are implemented and tested,
but this is **not a blanket phase-exit sign-off**. The current-baseline audit
reproduced knockdown loops, buffer-aging, corner separation, and KO-order issues;
K1 now guards the knockdown strike loop, while the remaining findings are open.
“Hits feel responsive” also requires human playtesting. See
`docs/PHASE_STATUS.md` for the requirement/evidence distinction and
`docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md` for the
current-main reconciliation. Phase 2 adds throw tech, draw resolution, EX
specials and the METHtality engine core.

## Current-baseline reproduced defects

The external probes in the
[current-baseline report](audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md)
reproduced these on `e6d40d9`; the status of each is marked below. A baseline
finding is not considered fixed merely because an older suite passes.

- **Knockdown strike loop (B1) — fixed by K1.** The baseline probe showed a
  repeated crouch-heavy hitting a defender who
  remains in `KNOCKDOWN` with no agency. Ten hits reduced 1000 → 486.25 HP; a
  held-back-input run also landed five hits without a block. Current code now
  rejects non-METH strikes during knockdown and preserves the explicit METH-row
  exception; tests cover both outcomes. See PROPOSALS §6 and `PHASE_STATUS.md`.
- **Knockdown throws (B2) — fixed by D2/R1.** The baseline probe showed unteched
  grabs hitting a knocked-down defender for 95 damage and re-entering knockdown.
  Throws are now rejected during `KNOCKDOWN` before tech/damage resolution;
  normal throw damage remains 95/105. Regression tests cover both orientations.
- **Buffer aging through freeze/stun (B3) — hitstop portion fixed by D3/PR 4a.**
  All buffered action ages now freeze together during hitstop for at most one
  normal buffer window (5 frames); later hitstop frames age them normally.
  Blockstun aging was not changed, and policy 4b remains deferred to playtest.
- **Corner pushbox overlap (B4) — fixed.** The baseline left 5px overlap after
  clamping at either wall. Separation now transfers the pinned fighter's
  unapplied correction to the unpinned fighter; tests cover P1/P2 at left/right.
- **Un-blockable wake-up tail (B7).** Holding away cannot block during any
  `WAKE_UP` frame; a frame-6 meaty dealt 35 damage. This may be a deliberate
  style, so it is a playtest/owner decision rather than a proven bug.
- **Post-KO winner state (B10).** A nonlethal, already-polled trade reply moves
  the eventual winner from `WIN` to `HITSTUN` during the KO phase; the round
  result still goes to the correct winner. This is a cosmetic/state-order issue.

B5 (air momentum), B8 (implicit cancels/scaling), and B9 (hurt/push alias) remain
source-confirmed audit observations; B5 was not re-probed at this baseline.
B6 is partially addressed by the landing-recovery work: mid-move touchdown still
skips the whiff-meter gain that a move finishing in air receives. See the
reconciliation for the finding-by-finding dispositions.

## Decisions and open choices

- D2/R1 decision: throws cannot connect during `KNOCKDOWN`; implemented and
  regression-tested in PR 2.
- D3 selects hitstop-only buffer aging freeze capped at one normal buffer
  window, with all buffered actions frozen together; implemented and tested in
  PR 4a. Blockstun policy 4b remains deferred to playtest.
- Whether air attacks should preserve horizontal momentum or intentionally stop
  on attack (B5; needs a live probe and playtest).
- Whether wake-up should allow blocking in its vulnerable tail (B7; playtest).
- Damage-scaling floor: **decided (2026-11-06) as 55%**, matching the code; GDD
  §5.10's 35% entry is amended to 55%. 35% may be revisited only after a juggle
  limit exists.
- Command-grab techability: **decided (2026-11-06) as untechable**, with slow,
  punishable startup. The normal throw remains techable; throw-tech is not
  extended to command grabs.
- Authored combos and command grabs are not implemented. `docs/PROPOSALS.md`
  §§6–7 have approved direction; the correctness queue comes first. Command-grab
  techability and the already-occupied Peggy back-special / Richard
  forward-special slots still need explicit choices. Owner canon is shared
  controls, silhouette playability with animation deferred, and Peggy/Richard-
  only scope.
- Gamepad support and in-game input remapping are GDD §4.1/§4.6/§14
  requirements but are not implemented; the current input map is generated from
  a fixed keyboard table.
- METHtality currently uses a kill-confirm gate. GDD §5.9's final-round finish
  prompt and cinematic remain future design/implementation, not current behavior.
- The Phase 2 recommended cast differs from the implemented Peggy/Richard pair;
  confirm scope rather than treating the recommendation as silently changed.
  See `docs/PHASE_STATUS.md` for the phase evidence and gate status.

## What the current build contains

Engine and feel:

- KO landing, shared hitstop, blockstun blocking, jump rise/fall states,
  frame-locked gravity, P1/P2 input separation.
- Device-agnostic keyboard bindings (`device = -1`, which matches any device),
  covered by a real-key test that replays a physical keyboard event (device
  `16`). A concrete device stamp ties the map to the machine that generated it
  and silently kills controls on a keyboard that reports a different id.
- Silhouettes scale with fighter height, so the art matches its own hurtbox.
- Chip damage floors at 1 HP — a blocked hit can never KO.
- A same-frame trade lands both hits, and two KOs in the same frame resolve as a
  **dual-pip draw round** (Street Fighter convention): both fighters take a win,
  `DOUBLE K.O. / BOTH TAKE THE ROUND`, and the next round is played. A 2-2
  scoreline does not end the match — decisive rounds continue until one fighter
  wins a round outright (the HUD announces `DECISIVE ROUND`).
- The round clock holds while either fighter is in hitstop, and hits resolve
  before the timeout, so a hit on the clock's final frame counts and a KO there
  beats the timeout.
- A real pause menu (RESUME / RESTART MATCH / QUIT TO DESKTOP) driven by either
  player's up/down plus light attack or Enter. Toggling is keyed on menu open state
  so pause opens cleanly when paused under debug frame-step. Pausing alters no simulation
  state: hitstun frames, health and the clock resume exactly where they stopped.
- A grounded throw cannot grab an airborne defender. The brush does not consume
  the throw's active window, so the grab still lands if the defender touches down
  inside it.
- Wake-up invulnerability, data-driven: `FighterData.wakeup_invuln_frames` (6)
  rejects strikes and throws from the first wake-up frame,
  `wakeup_throw_invuln_frames` (8) holds throws off past that, and
  `wakeup_frames` (12) moved out of the hard-code into data. Reversal moves can
  author their own `MoveData.invuln_kind` / `invuln_start` / `invuln_end`. The
  gate lives in `_poll_hit()` ahead of the throw guard, so an invulnerable brush
  never consumes the active window: the first vulnerable frame is the frame that
  connects, which is what makes a meaty expressible.
- Throw tech (PROPOSALS §2), data-driven: `throw_tech_window` (7) frames of
  buffered grab break a throw, `throw_tech_recovery` (10) is spent by **both**
  fighters in a real `State.TECH` with a ~20 px push apart, and
  `throw_whiff_recovery` (22) replaces the grab's authored 16-frame recovery on a
  whiff. Tech consumes both grab buffers and emits `teched` (HUD flashes "TECH").
  A defender's own throw startup doubles as the tech input (single throw button);
  any light/heavy/special/meth buffered in the window locks the tech out, so
  mashing a second button loses to the throw. The airborne guard and wake-up
  throw invuln both run before tech, so they still win.
- Hype meter has a spender (PROPOSALS §5): hold **Heavy** with **Special** to
  use the EX variant of the neutral/forward special for 50 meter. `MoveData`
  gained `meter_cost` / `ex`; `FighterData.find_move()` skips EX rows and
  `find_ex_move()` returns them. Meter is paid in `_try_start_attack()` /
  `_try_cancel()` before the move starts, floors at 0, and a short bar falls back
  to the base special with no meter spent. Current economy (all defaults, no
  `.tres` overrides): +6 hit, +3 block, +1.5 whiff, +4 receive, max 100 — about
  one bar per round, two EX per bar.
- METHtality engine core (PROPOSALS §4), data-driven: buffered `p1_meth` /
  `p2_meth` fires only when the hype meter is **full**, the opponent is at or
  below `meth_health_threshold` (250 / 25%), the opponent is in hitstun or
  knockdown, and the opponent is not invulnerable (wake-up / reversal invuln
  rejects it). Meter drains fully on activation; the finisher starts from both
  the neutral starter and the hit-confirm cancel path. Phase-1 presentation: a
  30-frame hitstop freeze plus a `METHtality` HUD banner, then the normal KO flow
  awards the round. Vertical slice: **Walk the Plank** (Peggy) and
  **Flaming Belch** (Richard), each a distinct finisher row in `.tres`.
- Air landing recovery (PROPOSALS §3), data-driven: jump light/heavy whiffs lock
  LAND for 8f; air-special whiffs lock for 12f. The value is the total LAND
  duration, not additive to legacy recovery. Hit/blocked aerial moves retain the
  2f landing behavior; extended whiff recovery cannot block. Touchdown clears the
  move and hit flags immediately, while hitstop/pause freeze the countdown and
  hitstun/knockdown/KO landing semantics remain intact.

Debug overlay:

- F1 boxes, F2 frame state + frame advantage + the invulnerability countdown
  (`INV 4f` while the wake-up window covers strikes, `THROWINV 2f` for its
  throw-only tail, and a reversal's own authored frames in the same slot),
  F3 input history, F4 slow motion,
  F5 frame-step (one simulation frame per press, only while slow-mo is on and
  the pause menu is closed), F6 refill both fighters.
- The overlay mutes itself in headless runs, so it never draws or reads input
  during the suites.

## Input map

`game/tools/setup_input.gd` is the single source of truth for the `p1_*` /
`p2_*` actions. Do not hand-edit the `[input]` section of `project.godot`; change
the generator and regenerate:

```bash
godot --headless --path game --script res://tools/setup_input.gd
```

Every event is written with `device = -1` (matches any device). In Godot 4.7 a
new `InputEventKey` reports the local keyboard's concrete device id (`16` on the
dev machine), and the serializer writes whatever it holds; a concrete stamp
therefore makes the map depend on the machine that generated it. Physical
keyboard events observed through XTest carry device `16`, so
`game/tests/combat_test.gd` replays each mapped key with device `16` and fails if
any of them stops resolving.

Regeneration caveat: `ProjectSettings.save()` omits settings whose value equals
the engine default, and `physics/common/physics_ticks_per_second = 60` *is* the
default. Regenerating therefore deletes the explicit `[physics]` section. Re-add
that section by hand afterward — the simulation step comes from
`Engine.physics_ticks_per_second` via `FighterBase.delta_fixed()`.

## Deliberate gaps (next phases)

- **No animation.** Fighters are colored silhouettes; no sprite frames wired.
- **No audio or VFX.** No hit sparks, crowd, UI sounds, music.
- **No CPU AI.** Both fighters are human-controlled (GDD Phase 3 baseline).
- **METHtality presentation is minimal.** The rules, gate, spend and KO win are
  real, but the finisher is a single point-blank hit with a long freeze and a
  banner — no cinematic, camera, or choreography yet. The 25% threshold and 30f
  freeze are first-pass balance numbers, and a whiffed finisher still spends the
  full bar.
- **No dash/backdash.** GDD §5.2/§5.11 list them; neutral movement is walk-only.
- **No gamepad support or input-remap UI.** Current inputs are a generated
  keyboard table; GDD §4.1/§4.6/§14 require both.
- **No counter-hit, per-move cancel windows, or juggle limit.** Cancel routes
  are engine-coded; GDD §5.3/§5.6/§5.10 remain future work.
- **No command grabs.** The two existing fighters have only the ordinary
  grounded throw row. Proposed special-direction command grabs and their
  techability policy are documented in `docs/PROPOSALS.md` §7; Phase 3 owner
  approval is required before implementation.
- **No character/stage select.** Fixed matchup + Bus Stop (Night).
- **Debug overlay is dev-only.** Boxes, frame state, frame advantage, input
  history, slow motion, frame-step and refill exist; there is no AI state view
  (there is no AI yet) and no hitbox-invariant assertions.
- **Airborne throws remain rejected.** Throws stay grounded-only, unchanged.
- **No throw-tech follow-ups yet.** Punish Counter throws, delayed-throw
  pressure and shimmy baiting are design space, not implemented.

## Known edge cases and first-pass balance limits

These are measured or first-pass limits, not phase-exit validation.

- **Timeout ties**: equal health at time-out is a draw round with no pip. The
  first two ties just advance the round; the **third** tie starts a final
  **SUDDEN DEATH** round on a 30-second clock. In sudden death the first clean
  win ends the match; a tie (clock-out or double KO) is resolved deterministically
  instead of extending the match:
  1. higher remaining health,
  2. higher damage dealt during that round (chip counted),
  3. higher hype meter,
  4. P1 as the documented last resort.

  The last two fallbacks exist only for a perfectly mirrored round; the
  common double-KO-in-sudden-death case is decided by damage dealt. Any win in
  sudden death ends the match regardless of the pip count.
- **Throw damage tuned.** PROPOSALS §2 predicted that 120/130 throw damage was
  disproportionate once tech exists (outdamaging forward specials and standing heavies
  at 1.30–1.41x heavy whiff-punish risk). Measured via empirical probe and tuned in
  `gen_fighter_data.gd` to 95 for Peggy and 105 for Richard (9.5% / 10.5% max HP),
  bringing throw reward vs heavy whiff-punish risk to 1.12x (Peggy) and 1.05x
  (Richard) while keeping throws unblockable with hard knockdown advantage.
- **Air-special tuning remains a first pass.** Aerials remain `OVERHEAD`, so
  crouch-block alone does not stop jump-ins. In the measured sample, air-special
  reach fell from 133%/100% of jump-heavy starts to 67%/67%; the ≤60% target is
  missed because the coarse counts are discrete. Direct damage ratios versus
  crouch-heavy anti-airs are now 0.778/0.800 and whiff minima exceed 8f, but the
  blocked-advantage target is not met (median +4/+3, attacker recovers first).
  These are project hypotheses and small deterministic samples, not competitive
  balance claims; see `docs/PROPOSALS.md` §3.
- Frame data is provisional, derived from GDD §5.6–§5.10. It lives in
  `game/resources/fighters/*.tres` and can be regenerated with
  `game/tools/gen_fighter_data.gd` (which now also authors the EX rows and
  METHtality finishers).
- Damage scaling is per-defender combo count: 100/100/85/70/55% for hits
  1–2/3/4/5+, floor **55%**. This is the owner-decided floor (2026-11-06); GDD
  §5.10's 35% entry is amended to 55%. Chip damage never
  kills — a blocked hit floors the defender at 1 HP.
- HUD uses the default Godot font at pixel-safe sizes; the final pixel font
  arrives with UI art direction (GDD Phase 4).
- **Licensing is undecided.** Treat the repo as all-rights-reserved until a
  LICENSE is added. The three realistic options (all-rights-reserved + NOTICE,
  CC BY-NC 4.0 for content with separate code licensing, proprietary
  source-available) are compared in `docs/LICENSE_OPTIONS.md`; the owner chooses.

## Test coverage

- `game/tests/combat_test.gd` — **124 checks**: clean hits and damage-vs-data,
  block chip, low vs stand block, throw unblockability, jump arc, P2 bindings,
  blockstun blocking, shared hitstop, KO landing, real-key input-map resolution,
  the chip-cannot-KO floor, pause freezing fighters and opening the menu, menu
  navigation by both players, resume preserving mid-hitstun state, restart from
  the menu, debug frame-step (one frame per press, gated while the menu is
  open), the frame-advantage readout, the F6 refill, grounded throws whiffing on
  an airborne defender while the active throw window survives the brush, and
  wake-up invulnerability: a frame-1 meaty whiffs, the invulnerable brush
  survives to a frame-6 hit, strike and throw windows expire separately,
  `wakeup_frames` is read from data, the wake-up gate leaving the airborne-throw
  guard intact, the F2 invulnerability countdown (strike window, throw tail,
  reversal frames, empty when idle), hitstop freezing that countdown before
  it resumes, and throw tech: an in-window tech neutralizes both fighters with no
  damage and pushes them apart, a stale buffer does not tech, a mashed second
  button locks the tech out, a whiffed throw measures 22 frames of recovery, the
  airborne guard wins over tech, and wake-up throw invuln still rejects the throw
  before tech becomes possible, plus EX specials: special+heavy starts the EX
  row and deducts 50 meter, a short bar falls back to the base special without
  spending, EX data differs from base in damage/startup, `find_move()` skips EX
  rows, both fighters have neutral+forward EX rows, and spending floors at 0,
  plus METHtality: health/state/meter gates reject early, a legal trigger spends
  the whole bar and starts the finisher row, the HUD announces it, the opponent
  is KO'd, the round is awarded as a normal KO win, wake-up invuln blocks it, and
  the two fighters' finishers are distinct. Aerial landing tests cover startup,
  active, recovery and post-move falling touchdown; immediate hitbox/move clearing;
  whiff vs hit/block landing delay; pause and hitstop; anti-air interruption;
  un-blockable extended recovery vs legacy blockable LAND; reset/restart; P2 data;
  unchanged grounded attacks; and throw damage remaining 95/105.
- `game/tests/round_flow_test.gd` — **30 checks**: intro→fight, KO phase, round
  wins, timeout resolution, a simultaneous KO awarding a pip to both and the
  round advancing, a 2-2 scoreline continuing into a decisive round that ends on
  an outright win, reset clearing draw state, the first two timeout ties
  awarding no pip, the third tie starting a 30-second sudden-death round, a
  sudden-death tie resolving by damage dealt (with the announced tiebreak), the
  deterministic P1 fallback, a clean win in sudden death ending the match, the
  clock frozen during hitstop, and a hit on the timer's final frame counting.
- `game/tests/air_probe.gd` — metrics only, no assertions: both fighter
  directions; sampled geometry candidates vs resolver-confirmed reach/trade,
  direct damage ratios, hitstop, actual block advantage, and post-whiff
  actionability. Prints a report and exits 0 on success; `docs/PROPOSALS.md` §3
  documents the coarse grid, before/after metrics, and target limitations. Its
  numbers are informational measurements, not passing balance assertions.
- `.github/workflows/tests.yml` runs both suites plus the air probe on push, pull
  request and manual dispatch. They are separate jobs in one workflow; parallel
  execution does not make a job non-gating. A non-zero command or job failure in
  the air-probe job can still fail the workflow even though the script contains
  no assertions.
- `.github/workflows/export.yml` builds Linux/Windows artifacts on `main` and
  `v*` tags, can be dispatched by hand, and caches the export templates per
  Godot version.
