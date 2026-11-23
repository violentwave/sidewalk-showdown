# Known Issues — Phase 2

GDD §13 Phase 1 greybox features and core flow are implemented and verified by
the current combat and round-flow suites. The known B1–B4 and B10 runtime defects
have fixes and regression coverage; B7 is an explicit owner-approved behavior.
This is technical verification, not a human feel/playtest sign-off. See
`docs/PHASE_STATUS.md` for current phase evidence and
`docs/audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md` for the
historical baseline findings. Phase 2 adds throw tech, draw resolution, EX
specials, and the METHtality engine core.

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
  Blockstun aging was not changed. Owner decision (2026-11-07): blockstun
  buffering 4b remains DEFERRED (S4 documented); punishes feel responsive.
- **Corner pushbox overlap (B4) — fixed.** The baseline left 5px overlap after
  clamping at either wall. Separation now transfers the pinned fighter's
  unapplied correction to the unpinned fighter; tests cover P1/P2 at left/right.
- **Un-blockable wake-up tail (B7) - owner decision (2026-11-07): KEEP.** The
  no-block wake-up tail (W2) is intentional; the meaty-or-invuln game stands,
  and holding away cannot block during `WAKE_UP`.
- **Post-KO winner state (B10) - repaired.** A nonlethal, already-polled trade
  reply used to move the eventual winner from `WIN` to `HITSTUN` during the KO
  phase. `MatchRoot._resolve_hits()` now forces the winner back to `WIN` after
  hit resolution in the KO phase, unless the exchange is a true double KO
  (`ko_draw`); the winner's nonlethal reply damage is retained. The regression
  drives a scripted trade in `round_flow_test.gd` and fails against the
  un-repaired resolver (verified).

B5 (air momentum), B8 (implicit-scaling, partially addressed by authored
cancel routes in PR 2), and B9 (hurt/push alias) remain
source-confirmed audit observations; B5 was not re-probed at this baseline.
B6 (landing discards whiff meter) — **OBSOLETE (2026-11-18), superseded by the
meter-economy change.** The fix (PR #57, commit `03f55b7`) was real for the old
rules: finish_move_whiff() in _landing_check() restored the dropped
meter_gain_whiff. But the meter economy was then changed to "landed hits only" —
whiffs award nothing anywhere, aerial or grounded — so a discarded whiff meter
no longer exists to be dropped. `b6_landing_whiff_test.gd` now pins the
superseding behavior (landing a whiffed air move awards 0 meter, the move
still clears, and landing recovery still runs to IDLE) and gates CI
(added 2026-11-20 with the test-reliability pass).

## Decisions and open choices

- D2/R1 decision: throws cannot connect during `KNOCKDOWN`; implemented and
  regression-tested in PR 2.
- D3 selects hitstop-only buffer aging freeze capped at one normal buffer
  window, with all buffered actions frozen together; implemented and tested in
  PR 4a. Blockstun policy 4b remains deferred to playtest.
- Air attacks intentionally stop on attack (B5, M2): **KEEP** per owner
  decision (2026-11-07); airborne grab rejection confirmed correct.
- Wake-up does not allow blocking in its vulnerable tail (B7, W2): **KEEP**
  per owner decision (2026-11-07); the meaty-or-invuln game stands.
- Damage-scaling floor: **decided (2026-11-06) as 55%**, matching the code; GDD
  §5.10's 35% entry is amended to 55%. 35% may be revisited only after a juggle
  limit exists.
- Command-grab techability: **decided (2026-11-06) as untechable**, with slow,
  punishable startup. The normal throw remains techable; throw-tech is not
  extended to command grabs.
- Authored combos and command grabs are implemented for Peggy and Richard.
  Command-grab values remain provisional for the later-roster pass; the
  forward-special/EX launcher category and grounded-only EX cancel are recorded
  owner decisions. Owner canon is shared controls, silhouette playability, and
  Peggy/Richard-only vertical-slice scope. Per owner direction (2026-11-12), an
  initial procedural silhouette-animation pass is underway; authored sprite
  frames remain deferred.
- Gamepad support is implemented (2026-11-16): P1 uses keyboard + mouse and P2
  uses a controller, per owner direction. In-game input remapping is still a GDD
  §4.1/§4.6/§14 requirement and is not implemented; the input map is generated
  from a fixed table in `game/tools/setup_input.gd`.
- METHtality activation requires full meter only; opponent health, state, and
  invulnerability do not gate starting the finisher. GDD §5.9's final-round
  finish prompt and cinematic remain future design/implementation.
- The official vertical-slice cast is Peggy and Richard. Burnout Bubba and
  Raccoon Randy remain later-roster canon; see `GDD.md` §13.

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
- A real pause menu (RESUME / SETTINGS / RESTART MATCH / BACK TO CHARACTER
  SELECT / MAIN MENU / QUIT TO DESKTOP, UI Phase 1) driven by either player's
  up/down plus light attack or Enter. SETTINGS and QUIT open overlays above
  the still-paused match (defaulting to NO on quit); MAIN MENU exits to the
  Phase 1 hub.
  Back to character select discards the in-progress match with no winner and
  keeps the mode and matchup; restart re-rolls the match. Toggling is keyed on
  menu open state so pause opens cleanly when paused under debug frame-step.
  Pausing alters no simulation state: hitstun frames, health and the clock
  resume exactly where they stopped.
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
  to the base special with no meter spent. Current economy (2026-11-18,
  all defaults, no `.tres` overrides): the attacker earns `meter_gain_hit` (6.0)
  **only when a hit lands** — throws and command grabs included, one award per
  connection; blocked hits pay `meter_gain_block` ×
  `FighterBase.METER_GAIN_ON_BLOCK_SCALE` (scale default **0.0**, so blocked,
  whiffed, and received-nothing hits award 0; `meter_gain_whiff` and
  `meter_gain_receive` stay authored data but are never awarded). Max 100.
- METHtality engine core (PROPOSALS §4), data-driven: buffered `p1_meth` /
  `p2_meth` fires when the hype meter is **full**, regardless of opponent health,
  state, or invulnerability. Meter drains fully on activation; the finisher
  starts from both the neutral starter and the hit-confirm cancel path. Phase-1
  presentation: a
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

**Device policy (owner decision, 2026-11-16):** P1 is keyboard + mouse only; P2
is controller only.

- `p1_*` gets `InputEventKey` bindings plus mouse alternates for light (left
  click), heavy (right click), and special (middle click). No joypad events.
- `p2_*` gets only `InputEventJoypadButton` / `InputEventJoypadMotion` events:
  d-pad or left stick to move, X light, Y heavy, B special, A grab, right
  shoulder METHtality, Start pause (GDD §4.2). Any arrow/numpad binding from the
  old shared keyboard map was removed. `ui_confirm`/`ui_back` keep their keyboard
  events and gain pad south/east.
- Joypad events use `device = -1`, so whichever pad is connected drives P2
  regardless of port. Two-player local play is therefore keyboard/mouse vs pad.

Every keyboard event is written with `device = -1` (matches any device). In Godot
4.7 a new `InputEventKey` reports the local keyboard's concrete device id (`16`
on the dev machine), and the serializer writes whatever it holds; a concrete
stamp therefore makes the map depend on the machine that generated it. Physical
keyboard events observed through XTest carry device `16`, so
`game/tests/combat_test.gd` replays each mapped key with device `16`, each pad
event with device `0`, and each mouse event with device `-1`, and fails if any of
them stops resolving. It also asserts that P2 has no keyboard/mouse bindings and
P1 has no controller bindings.

Regeneration caveat: `ProjectSettings.save()` omits settings whose value equals
the engine default, and `physics/common/physics_ticks_per_second = 60` *is* the
default. Regenerating therefore deletes the explicit `[physics]` section. Re-add
that section by hand afterward — the simulation step comes from
`Engine.physics_ticks_per_second` via `FighterBase.delta_fixed()`.

## Deliberate gaps (next phases)

- **Authored sprite animation status (updated 2026-11-16).** Both fighters now
  play the owner's full-animation-batch clips. Peggy: 16 attack moves and 18
  core states (see `docs/PIXELORAMA_PIPELINE.md` §8 and
  `game/scripts/combat/peggy_clip_library.gd`). Richard: all 16 moves and 21
  core states, plus side-facing walks and crouch-hold (see §9 and
  `game/scripts/combat/richard_clip_library.gd`); `crouch_down` now plays as a
  presentation-only crouch-entry transient (§9b), so all 39 of his enabled clips
  are mapped without adding a simulation state. The idle loops and the
  static cel-0 fallback remain exactly as approved. **Gated off pending owner
  review:** Peggy's `walk_forward` / `walk_backward` / `crouch_down` clips
  (front-facing JPEGs that clash with the side-view presentation) and
  `stage_intro`; `throw_target` is prepared but unmapped. Richard's
  `stage_intro` and `throw_target` are likewise unmapped, and his draft sheets
  are drawn at different art scales, so every clip stores a measured `h_ref`
  (47–81) instead of a uniform 74. Six action sheets whose bandana was
  occluded (`forward`, `forward_ex`, `jump_light`, `jump_heavy`, `meth`, `air`)
  were recalibrated on 2026-11-15 from head height and now render at the idle
  body height instead of 15–48 % larger. The same pass fixed frozen walk
  cycles, a landing cel playing mid-air, landing cel order, the skipped jump
  launch pose, and dead guard poses (see `docs/PIXELORAMA_PIPELINE.md` §9a).
  Combat boxes, timings, and gameplay are unchanged everywhere. The facing-flip
  side-swap question (Peggy's peg leg / Richard's bottle) is still deferred, and
  final/cleaned exports are still wanted for the JPEG-derived Peggy clips
  (`walk_forward`, `walk_backward`, `crouch_down`, `crouch_hold`) and for any
  Richard sheet the owner re-exports at a uniform scale.
  Live-input glitches reported on 2026-11-13 were traced to the prep step, not
  the renderer: pitch-line slicing chopped limbs, bounding-box centring made
  the body lurch, and pose-height `h_ref` estimates shrank `jump_fall`/`land`/
  `hitstun_*` by 8–24 %. Peggy's prep now cuts at minimum-coverage columns,
  anchors on the planted foot, and normalizes scale from hat width. Richard's
  overlapping figures use component segmentation with touch-splitting and
  orphan-sliver cleanup; all 40 prepared sheets were re-verified one-body-per-
  cel. A 3,000-frame real-input soak is clean for each fighter. The round-end
  "duplicate fighter" was a round reset plus a bystander painted into
  `BusStopNight.png`, not a sprite bug.
- **Temporary audio only; no final VFX/mix.** Intro/menu and fight MP3 tracks plus
  basic hit/block/UI/round/KO/METHtality cues are wired; confirm MP3 usage rights
  before public release. Tripp voice, crowd, hit sparks, screen shake,
  spatial/priority mixing, and the full GDD §12 SFX list remain.
- **CPU depth is v0.1-level.** The solo P2 is now a real CPU opponent with
  three difficulty levels ([`docs/CPU_OPPONENT.md`](CPU_OPPONENT.md)), and
  since Phase 4 (2026-11-22) it uses the full combo system — authored
  route walking, launcher strings with juggle chases, stun-then-string,
  Clip Cancel, the breaker, stun shake-out, and juggle-fall drift — but its
  toolkit is still deliberately simple: no fuzzy guard logic, no spacing
  neutral-game, no character-specific gameplans, and difficulty is
  data-tuned rates rather than distinct strategies. It plays a fair,
  readable match; it is not a tournament opponent.
- **CPU-side balance finding (2026-11-22, Phase 4 soak):** the CPU-vs-CPU
  soak is **Peggy 24–0 Richard at NORMAL and 18–6 at HARD** (24 matches per
  level: both pairings, both stages, 6 seeds). This is a CHARACTER-balance
  problem, not AI bias: both CPUs run identical controller code and knobs;
  Richard's average combo is BIGGER (148.1 vs 136.9 at NORMAL), so he
  converts fine — he wins neutral half as often (216 combos landed vs
  Peggy's 388; her faster pokes win the interaction war), and the split
  predates the combo CPU (Phase 3's soak was already 8–0). HARD narrows it
  (better blocking suppresses the jab war). Candidate data levers, all
  `.tres`, none applied: Richard's stand-light startup (5f) toward Peggy's
  (3f) parity, or a Richard walk-speed bump. Owner decision pending; jab
  values untouched per the standing decision.
- **Combo depth is Phases 1–3 plus CPU usage.** Blockstrings,
  counter-hit extensions, dial-a-combo macros (BENCH WARMER / LAST CALL),
  the Clip Cancel, data-driven scaling with repeat/variety/caps, the
  juggle point budget with authored launcher routes, stuns, the breaker,
  AND CPU usage of all of it are in
  ([`COMBO_SYSTEM_DESIGN.md`](COMBO_SYSTEM_DESIGN.md) §§9–12, 15.1) — but
  there is no combo HUD readout yet (Phase 4's remaining half; the tracker
  readouts and signals are exposed for it).
- **METHtality presentation is minimal.** The trigger, spend and KO win are
  real, but the finisher is a single point-blank hit with a long freeze and a
  banner — no cinematic, camera, or choreography yet. The 30f freeze is a
  first-pass balance value, and a whiffed finisher still spends the full bar.
- **No dash/backdash.** GDD §5.2/§5.11 list them; neutral movement is walk-only.
- **No input-remap UI.** Gamepad play is implemented (P1 keyboard + mouse, P2
  controller), but in-game remapping is still a GDD §4.1/§4.6/§14 requirement.
- **Launcher category (owner decision, 2026-11-07; implemented; Peggy base
  retuned 2026-11-21).** The forward
  special and its EX variant launch for both fighters with authored vertical
  knockback (base **274** Peggy — raised from 228 by the Phase 3 owner call
  so her authored route connects / 260 Richard; EX 360 / 340); crouch
  heavies remain hard knockdowns; EX cancel is grounded-only as ratified policy.
  Measured limits (PROPOSALS §6 launcher table + Phase 2/3 route probes,
  2026-11-21): under the point budget, **Richard's 260 base launcher
  connects the full two-hit route** (jump_heavy + richard_air, 263.55),
  and **Peggy's 274 base launcher connects her authored route**
  (jump_light + jump_heavy, 221.40, jump f34–36 — Richard-grade human
  timing; at 228 and even at the once-proposed 255 nothing connected).
  Both EX rows (360 / 340) connect their routes. The rows are marked
  `MoveData.launcher` (pure data).
- **Jump-in follow-up has a measured spacing window.** PR B's sweep shows the
  chained `jump_light` connects at horizontal gaps 20-44 px with a 10-30 px
  launch height; at 0 px height the buffered grounded light connects at 20-44 px
  (Peggy) / 20-36 px (Richard `jump_heavy`). Outside that window the follow-up
  drops. The former #22 test only asserted the cancel started; it now asserts
  the follow-up hit CONNECTS at 20 px / 28 px for both starters and fighters.
  Owner decision (2026-11-07): **KEEP** the 20-44 px window; no widening.
- **Per-move cancel windows and juggle economics are data.** Cancel windows
  are authored data (`CancelRule` resources, PR 2); the §6 juggle rules are
  implemented and, since the juggle-economics PR, use the point budget
  (5 start / normals 2 / air specials 3, `ComboTuning`; launcher rows carry
  `MoveData.launcher`). Counter-hit
  detection and +2f hitstop are implemented (PROPOSALS §6, PR 1); counter-
  specific cancel routes exist in the engine and take precedence but no authored
  route sets a `COUNTER_HIT` condition yet.
- **Command grabs are authored (PROPOSALS §7, PR 6).** Forward+grab starts an
  UNTECHABLE THROW-level command grab for each fighter; the normal throw remains
  techable. Owner decision (2026-11-07): these values are provisional first-pass
  numbers and the reward/whiff-punish ratios (0.80 Peggy / 0.97 Richard) are
  informational; owner decision (2026-11-07): confirmed provisional, revisit in
  Phase 9.
- **Stage select is a single shared pick.** Both players choose one stage from
  the current two-stage roster, with RANDOM last; there is no rotation,
  tournament order, or per-stage music assignment yet.
- **Debug overlay is dev-only.** Boxes, frame state, frame advantage, input
  history, slow motion, frame-step and refill exist; there is no AI state view
  (the CPU is deterministic and data-tuned, but the overlay does not surface
  its plan/RNG) and no hitbox-invariant assertions.
- **Airborne throws remain rejected.** Throws stay grounded-only, unchanged.
- **No throw-tech follow-ups yet.** Punish Counter throws, delayed-throw
  pressure and shimmy baiting are design space, not implemented.

## Known edge cases and first-pass balance limits

**Local-run gotcha (environment, not a bug — observed 2026-11-21):** if a
physical controller is connected to the dev machine (a DualSense was), its
resting stick noise streams real joypad events. Any action whose input map
includes a JoypadMotion event on a noisy axis gets its virtual
`Input.action_press` state recomputed and cleared on the next engine tick —
observed as `p2_down` (axis 1, rest value ~0.012) clearing instantly, which
fails combat_test's crouch-hold check locally even on a clean checkout. CI
has no controllers and is unaffected. Power the pad off (or center/hold the
stick) for local suite runs; `p1_*` actions are keyboard/mouse-only and
immune, and X-axis actions are immune when the stick rests at exactly 0.

These are measured or first-pass limits, not phase-exit validation.

**Owner-reported playtest issues (2026-11-20; Phase 2 juggle economics
landed 2026-11-21 — data recorded, no balance fixes applied yet):**

- **The jab (J / stand light) is too strong relative to every other attack** —
  it near-dominates the kit. Owner wants it toned down or the other attacks
  compensated. Candidate levers, all data (`.tres`): light damage/hitstun,
  heavy/EX reward, or meter gain per move. **Phase 2 data (design §15.1):**
  launcher routes max at 258/286.5 base and 293/316.5 EX vs jab-only ceilings
  196.5 (Peggy) / 252.7 (Richard) — Richard's AVERAGE launcher route (227.5)
  is still below his jab ceiling, and every candidate ladder retune cuts
  jab damage MORE than launcher damage, so the ladder alone cannot dethrone
  the jab. A jab-specific decision is still pending (owner).
- **A fighter backed into a corner by an advancing opponent gets stuck** —
  they cannot break the opponent's string or move. **FIXED (2026-11-21,
  combo Phase 3): the combo breaker shipped.** Grab+special together while
  in hitstun (grounded strings AND juggles) breaks out: free once per round,
  40-meter extras, 5-second cooldown, once per combo. The break separates
  both fighters 30 px over 6 frames through the shared side helper, and a
  WALL-PINNED defender's pushback share transfers to the attacker, so the
  cornered defender escapes with 20 frames of invulnerability (pinned in
  `stun_breaker_test.gd` §5b). Keep this entry for the playtest: the fix is
  verified by suites, not yet by human feel.
- **Some move animations still scale incorrectly** — characters appear
  bigger/smaller during certain moves. The 2026-11-15 calibration pass fixed
  the worst `h_ref` drift, but owner review still sees outliers; needs a
  fresh rendered pass over the remaining move clips (the
  `*_clip_render_check` harnesses are the tool). **Phase 2 effect:** none —
  the juggle routes reuse existing clips (zero new art), so no new scaling
  cases were introduced; the existing outliers are untouched.

**Measured/engine limits:**

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
- **Side switching (2026-11-18) — deliberate behavior, not a defect.** Fighters
  auto-face the opponent in grounded neutral states and can cross over by
  jumping: pushbox separation now runs only when both fighters are grounded.
  Edge cases are specified in `docs/SIDE_SWITCHING.md`: equal-x tie-breaks are
  deterministic and node-order-free (keep the current facing; lower player
  slot is the left body on separation); facing stays frozen through blockstun,
  and block side reads the attacker's position through the shared
  `relative_side()` helper, so a cross-up needs the new away key held while
  the old one fails; a jump over a wall-cornered fighter lands at the bound
  beside them and settles by the normal separation rather than leaving the
  arena. The `fighters_can_pass_through` walk-through flag ships ON by
  default; setting it false restores the legacy grounded pushbox.
- **Licensing is undecided.** Treat the repo as all-rights-reserved until a
  LICENSE is added. The three realistic options (all-rights-reserved + NOTICE,
  CC BY-NC 4.0 for content with separate code licensing, proprietary
  source-available) are compared in `docs/LICENSE_OPTIONS.md`; the owner chooses.

## Test coverage

- `game/tests/combat_test.gd` — **408 checks**: distinct Peggy/Richard sheet
  artwork in walk states, the authored idle sheet (selection, visibility, cel
  cadence, wrap, hitstop/pause freeze, re-entry reset, facing pivot, and the
  missing-art fallback), unchanged combat boxes, clean hits and
  damage-vs-data,
  block chip, low vs stand block, throw unblockability, jump arc, P2 bindings,
  blockstun blocking, shared hitstop, KO landing, real-key input-map resolution,
  the chip-cannot-KO floor, pause freezing fighters and opening the menu, menu
  navigation by both players, resume preserving mid-hitstun state, restart from
  the menu, the four-option menu and its character-select return request,
  debug frame-step (one frame per press, gated while the menu is
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
  plus METHtality: a non-full meter rejects activation; full meter starts the
  finisher against a healthy neutral or wake-up-invulnerable target, spends the
  whole bar, shows the banner, and the KO is awarded through normal round flow;
  the two fighters' finishers are distinct. Aerial landing tests cover startup,
  active, recovery and post-move falling touchdown; immediate hitbox/move clearing;
  whiff vs hit/block landing delay; pause and hitstop; anti-air interruption;
  un-blockable extended recovery vs legacy blockable LAND; reset/restart; P2 data;
  unchanged grounded attacks; and throw damage remaining 95/105. Authored-clip
  coverage now asserts both libraries' integrity (cel geometry, distinct enabled
  textures), 16/16 move mapping per fighter including `richard_*` rows, gated
  optional clips, Richard's live walks/crouch-hold/crouch-entry transient, exact
  light/heavy/meth phase boundaries, end-to-end display with procedural
  transforms suppressed and `h_ref` scaling, hitstop freeze, repeat-attack
  reset, hitstun interruption, walk-cycle wrapping, jump-fall cel selection,
  landing cel order, wall/crouch guard poses (Richard), jump/landing order
  (Peggy), the crouch-entry transient deferring the guard pose, and a shared
  state+move coverage sweep for both fighters.
- `game/tests/round_flow_test.gd` — **34 checks**: intro→fight, first-fight
  Tripp commentary sample, KO phase, round
  wins, timeout resolution, a simultaneous KO awarding a pip to both and the
  round advancing, a 2-2 scoreline continuing into a decisive round that ends on
  an outright win, reset clearing draw state, the first two timeout ties
  awarding no pip, the third tie starting a 30-second sudden-death round, a
  sudden-death tie resolving by damage dealt (with the announced tiebreak), the
  deterministic P1 fallback, a clean win in sudden death ending the match, the
  clock frozen during hitstop, and a hit on the timer's final frame counting.
- `game/tests/character_select_test.gd` — **55 checks**: intro MP3 playback on
  The Clip and character select, mode select defaulting to 1 PLAYER and moving
  to 2 PLAYERS, Backspace back-out, default selections,
  independent P1/P2 movement/confirmation, unlock-on-move, the solo two-pick
  flow (opponent cursor hidden until P1 locks, pad input ignored, Backspace
  undoes a pick), P2 staying input-disabled in solo while versus enables both,
  both stages in the roster, fighter confirmations opening stage select,
  keyboard/controller stage movement and confirmation, the solo hand-off,
  selected fighter data reaching the match on the chosen stage, pause-menu
  return to select (match torn down, solo/mode and matchup restored, music
  switched back), stage restore on re-confirm, a fresh match from the restored
  screen, temporary music/SFX playback, and impact/block cue routing.
- `game/tests/stage_select_test.gd` — **94 checks**: stable stage ids,
  descriptions, scenes, and 80x45 thumbnails; RANDOM last; restore by stage id;
  wrap-around and controller navigation; Backspace back-out; RANDOM resolving to
  a recorded concrete roster stage; both stage thumbnails shown; Gas-N-Go arena
  geometry, pause mode, layer order and native scales; mosquitoes above fighters
  but clear of the fight; cloud speed/wrap, 8 fps wingbeat, gator breath/blink,
  debug freeze, and pixel snapping; Bus Stop's unchanged id and new display
  name, arena geometry, layer order/positions/native sizes, fire in the
  foreground z-band, four 8 fps fire frames with jitter, lit/dead sign frames,
  random dropout and relight, freeze, and pixel snapping; MatchRoot's
  `roster.stages[0]` fallback and its safe stop on an empty roster or a stage
  with no scene.
- `game/tests/stage_floor_test.gd` — **9 checks**: every roster stage's
  `floor_y` sits inside its measured walkable ground band and is pinned to the
  art-verified contact value (Gas-N-Go 158, Bus Stop 170), with bounds and
  spawns coherent around it. The pins exist because floor_y must match where
  the stage art's objects meet the ground, not a shared convention (see the
  "Choosing floor_y" section of `docs/STAGES.md`).
- `game/tests/locomotion_speed_test.gd` — **7 checks**: Richard's
  locomotion parity with Peggy — both walk directions match and pin the
  authored values (95 forward, 72 back), jump speed matches with 285 pinned,
  and a fixed-length walk covers the same distance.
- `game/tests/the_clip_test.gd` — **23 checks**: installed art slots, lossless
  split text, panel-10 art visibility/aspect fit, deprecated hold values/copy,
  owner-script canon guards, panel ordering, boot-to-intro, Space-only
  beat/panel advancement, complete Space-only handoff, Esc skips from panels
  1/8/15, explicit bundled comic fonts, and monospaced livestream chat.
- `game/tests/cpu_test.gd` — **41 checks**: CPU legality (no move out of
  hitstun, no unpayable EX), same-seed determinism with scripted human
  inputs, mid-match AI-state save/restore plus mid-COMBO/mid-STUN/mid-BREAK
  restores, HARD-over-EASY defense ordering (frontal + forced stale-facing
  cross-ups), damage ordering, combo ordering (damage, launchers, stuns,
  breakers, Clip Cancels), combo legality under full-pressure fire (no
  breaker from blockstun), and an 8-match AI-vs-AI soak (both pairings, both
  stages, two seeds) asserting every match ends inside the honest limit
  with no stuck states (`docs/CPU_OPPONENT.md`).
- `game/tests/combo_test.gd` — **68 checks**: legacy pins (exact ladder
  damage, cancel routes, authored launch, juggle budget, block economy),
  scaling arithmetic (repeat/variety/air decay), BLOCK/WHIFF outcome
  conditions, Clip Cancel legality/cost/budget, macro dial continue-on-hit
  and die-on-block, combo caps and meter-in-combo, Phase 2 juggle
  economics (5/2/3 data pins, launch grant, spend by type, meaty-safe
  rejection, no re-launch re-grant, decay/gravity unchanged, budget reset),
  the four authored routes priced exactly with landing checks, mid-juggle
  MatchRoot save/restore with per-frame hash comparison, mid-combo
  save/restore, scripted-dial determinism, and a seeded route fuzz
  (`docs/COMBO_SYSTEM_DESIGN.md`).
- `game/tests/serialization_test.gd` — **24 checks**: the MatchRoot
  serializable surface carries every expected key and round-trips cleanly;
  exits 0/1 like the other suites.
- `game/tests/b6_landing_whiff_test.gd` — **5 checks**: the superseded B6
  rule pinned to the current meter economy — landing a whiffed air move
  awards 0 meter, the move clears, and landing recovery runs to IDLE.
- `game/tests/ui_flow_test.gd` — **52 checks** (UI Phase 1 + polish):
  router push/pop/replace/clear semantics, every forward and back path of
  the warning -> Clip -> title -> main-menu -> versus flow, the deferred
  confirm-leak guard, pause -> settings -> back to pause, MAIN MENU from
  pause, the quit confirm over a paused match, greyed slats refusing
  confirm, QuitConfirm defaulting to NO, the press-required content
  warning (no auto-advance, 30-frame boot guard), the chat-free main
  menu, wrap order, and the 1-second title pulse.
- `game/tests/settings_test.gd` — **16 checks** (UI Phase 1): defaults on a
  missing file, version fill-in of missing keys, round-trip save/load,
  opening never saving, reset applying and saving, and default audio
  settings keeping every bus at 0 dB. Runs against a scratch config file so
  the player's `user://settings.cfg` is untouched.
- `game/tests/ui_assets_test.gd` — **4 checks** (UI Phase 1): compiles
  `art/tools/prepare_ui.gd` and re-runs its size table in verify-only mode
  (manifest and test cannot drift), plus a byte-identity check of every
  `game/art/ui/` copy against its approved source.
- `game/tests/ui_typography_test.gd` — **42 checks** (2026-11-21 polish, extended by the PR #86 review fixes, the PR A select screens, the PR B match wrap, and the UI Phase 2 HUD):
  every label in the ten UI surfaces (nine screens + the pause menu)
  uses Sidewalk Marker at 10 or m5x7 at 16 with every glyph present, carries
  no theme outline or shadow, sits at an integer position, and is never
  scaled; labels on cardboard (ui_panel/ui_button) lie fully inside their
  container and use the dark inks (#2A2418/#7A6A48/#1C160D); over-stage-art
  lettering uses the outlined marker; the pause panel sizes itself to its
  longest item plus 8 px padding each side.
- `game/tests/select_screens_test.gd` — **24 checks** (PR A, 2026-11-22; extended by the PM review fix-ups):
  the Mode and Difficulty choices are unchanged (names, order, defaults,
  emits, back paths); the difficulty rows draw 1/2/3 ink tally marks; the
  rap sheet shows the focused fighter's roster name and owner-editable
  booking details; cursors are per-player scribbles in the side accents
  and solo hides P2's until lock; RANDOM starts covered; the focused
  ticket lifts 2 px with a yellow frame; concrete stages hand off
  immediately; the RANDOM scratch-off holds the hand-off for its full
  18 frames and then hands off the stage the RNG picked with its own
  thumbnail revealed.
- `game/tests/results_flow_test.gd` — **20 checks** (PR B, 2026-11-22): the
  VS busts slide in over 12 integer steps and land at their marks (P2
  flipped); the 20-frame VS skip guard; the full 150-frame duration;
  Results appears at match end above the frozen (paused) match with the
  real winner and rounds tally; serialize() is identical while Results is
  up; the 30-frame Results input guard; REMATCH routes through the VS
  bumper and keeps fighters and stage; CHARACTER SELECT / STAGE SELECT /
  MAIN MENU all route correctly and unpause.
- `game/tests/hud_test.gd` — **47 checks** (UI Phase 2, 2026-11-22; runs
  against a scratch settings.cfg): portrait states (normal, hurt under
  25%, ko after the round, refill restores); health fills and the
  20-sim-frame combo ghost drain; the HUD tick frozen while paused; pip
  sprites; timer digit-strip cells and the dirty-yellow under-10 tint;
  meter width, the METH-pink READY state and the 15-frame skull
  alternation; banner sprites per message with the text fallback,
  subtitle and stamp timing; attacker-side callouts for 30 sim frames;
  the combo counter with its gated damage total; commentary
  full/minimal/off and hide_tripp_text; reduce_flashing and
  high_contrast_hud; the serialize/load resync; and serialize()
  identical with the HUD bound and unbound.
- UI Phase 2 deferred, recorded here so they are not lost: **win-type
  pip letters (K/T/M/D)** need a per-round win-type history MatchRoot
  does not keep — a sim-side decision (the approved letter art waits on
  it); `hud_banner_time` has no call site today (timeouts announce
  DRAW / TAKES THE ROUND); the ∞ timer digit is unused (no infinite
  clock); `screen_shake` and `hold_to_confirm_meth` have no HUD-side
  hook; the `stun_started`/`stun_ended`/`breaker_used`/
  `meth_started`/`clip_cancelled`/`macro_step_replayed` fighter signals
  are not displayed yet (stun/breaker HUD cues are combo Phase 4+
  work).
- `game/tests/combo_fuzz_test.gd` — **118 checks**: seeded fuzz over the
  combo layer — route search and 12-hit/550-damage caps on BOTH
  stages, infinite-loop and corner-carry termination, macros (clean dial,
  slow dial, dies-on-block), COUNTER_HIT edge gating, Clip Cancel
  legality/budget, two-build determinism with identical per-frame hashes,
  mid-combo serialize/restore, cross-up and side-switch on both stages,
  Phase 2 juggle budget/route pins and a seeded juggle fuzz over every
  launcher (base + EX), both characters, both sides, both stages,
  pass-through on, **Phase 3 stun/breaker fuzz (both matchups: bounded
  windows, legal break states, no stun meter, clean recovery)**, and an
  8-match CPU-vs-CPU soak with an honest 6500-frame limit measured from
  real lengths (3092–5007 after the Phase 3 retunes; see
  `docs/COMBO_FINDINGS.md`).
- `game/tests/stun_breaker_test.gd` — **55 checks** (combo Phase 3): stun
  window/shake-out/immunity/once-per-combo rails, step-3 scaling on the
  follow-up string, blocked and airborne rails, the hitstop buffer-freeze
  bounds, the full breaker economy (free per round, 40-meter extras,
  5-second cooldown, once per combo, blockstun/neutral rejection), juggle
  breaks, the wall-pinned corner escape, mid-stun and mid-break
  serialize/restore, and a two-run determinism hash.
- `game/tests/combo_adversarial_test.gd` — **102 checks** (adversarial
  pass 2, in CI): an INDEPENDENT audit of the combo layer — breaker abuse
  (re-hit, cooldown-edge, 0-meter, stun, juggle, budget-rejection, KO,
  blockstun, hitstop, round transition, new-combo meter break), the
  shared grab+special pair, stun edges, seeded combined-loop fuzz,
  every-frame serialize/restore, P1/P2 symmetry, and meter accounting;
  plus the 2026-11-22 owner-ruling matrix (A2: the pair bridges hitstop —
  single presses break at hitstop 6 and 10, the METHtality's 30 stays
  unbreakable and leaves no ghost; A3: a meter-refused Clip Cancel
  consumes the pair and never converts on punish; with meter the cancel
  still fires) on both stages, both characters, both P1/P2 slots. The
  findings and rulings are recorded in
  `docs/COMBO_FINDINGS.md` ("Adversarial pass 2").
- Rendered/live verification harnesses (not run by CI; require a display
  because they read back the framebuffer, so they are manual review tools):
  `richard_clip_render_check.gd` (27 captures) and
  `peggy_clip_render_check.gd` (23) write contact sheets to
  `/tmp/opencode/`; `jump_block_render_check.gd` captures 18 ordered
  jump/landing/walk/guard poses; `jump_block_trace.gd` drives real input and
  prints state/cel/scale per frame; `attack_scale_check.gd` compares the six
  recalibrated attacks against an idle reference; `richard_live_soak.gd` and
  `peggy_live_soak.gd` run 3,000 real-Input frames each and assert the art
  stays centred; `richard_jump_check.gd` / `peggy_jump_check.gd` trace an input
  jump for scale pops. These are disposable review tools, not pass/fail gates.
- `game/tests/air_probe.gd` — metrics only, no assertions: both fighter
  directions; sampled geometry candidates vs resolver-confirmed reach/trade,
  direct damage ratios, hitstop, actual block advantage, and post-whiff
  actionability. Prints a report and exits 0 on success; `docs/PROPOSALS.md` §3
  documents the coarse grid, before/after metrics, and target limitations. Its
  numbers are informational measurements, not passing balance assertions.
- `.github/workflows/tests.yml` runs the twenty headless suites — combat,
  round-flow, mode/character-select, stage-select/ambience, stage-floor-guard,
  locomotion-speed, CPU opponent, combo system, combo fuzz, stun & breaker,
  The Clip intro,
  serialization, B6 landing-whiff, UI flow, settings, UI assets,
  UI typography, select screens, results flow, and the match HUD — plus
  the air probe on push, pull
  the air probe on push, pull
  request and manual
  dispatch, every step under a `timeout-minutes` so a hang fails fast.
  They are separate jobs in one workflow; parallel
  execution does not make a job non-gating. A non-zero command or job failure in
  the air-probe job can still fail the workflow even though the script contains
  no assertions.
- `.github/workflows/export.yml` builds Linux/Windows artifacts on `main` and
  `v*` tags, can be dispatched by hand, cancels superseded runs on the same
  ref, caches nothing large, and keeps artifacts for 14 days. Godot's
  ~1.27 GB engine+templates bundle is downloaded per run (~1 min) rather than
  cached.
- **Resolved 2026-11-16: Actions budget and artifact uploads.** The repository
  was private and the free plan's included Actions minutes were exhausted, so
  jobs were not started at all (`The job was not started because an Actions
  budget is preventing further use`). Artifact uploads had been rejected with
  `Failed to CreateArtifact: Artifact storage quota has been hit` since #42,
  including a 40-byte probe, which pointed at the same account-level limit
  rather than artifact size or repository contents. Making the repository
  public fixed both: all jobs start, and the next `main` export published both
  platform artifacts. Recorded here so a future private fork is not surprised
  by the same failure. The upload step stays fatal on failure, so a missing
  deliverable is still visible.
- `game/tools/readme_capture.gd` is a display-only helper that captures the
  menu and match screens used in `README.md` (mode select, intro panel,
  character select, posed match) plus a solo-select review variant to
  `/tmp/opencode/readme/`. Reviewed images are copied into `docs/assets/`
  deliberately; the tool never writes into the repo.
