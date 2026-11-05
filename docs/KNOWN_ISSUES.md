# Known Issues — Phase 2

Exit criteria from GDD §13 Phase 1: two boxes can fight, hits feel responsive,
blocking works, round flow works, match can end/restart. **All met.** Phase 2 adds
throw tech, draw resolution, EX specials and the METHtality engine core.

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
  player's up/down plus light attack or Enter. Pausing alters no simulation
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
- **No character/stage select.** Fixed matchup + Bus Stop (Night).
- **Debug overlay is dev-only.** Boxes, frame state, frame advantage, input
  history, slow motion, frame-step and refill exist; there is no AI state view
  (there is no AI yet) and no hitbox-invariant assertions.
- **Airborne throws remain rejected.** Throws stay grounded-only, unchanged.
- **No throw-tech follow-ups yet.** Punish Counter throws, delayed-throw
  pressure and shimmy baiting are design space, not implemented.

## Known edge cases

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
- **Throw damage is awaiting a tuning decision.** PROPOSALS §2 predicted that
  120/130 throw damage becomes too strong once tech exists; the numbers were left
  unchanged on purpose. Revisit after tech gets play data (tech rate vs whiff
  punish rate); candidate direction is 90–100 for Peggy and 100–110 for Richard.
- **Air specials are unbalanced.** Landing cancels a move, so air moves have no
  landing recovery, and every jump attack is an `OVERHEAD` that a crouching
  block cannot stop. Measurement methodology and targets are in
  `docs/PROPOSALS.md`; do not tune `resources/fighters/*.tres` without sign-off.
- Frame data is provisional, derived from GDD §5.6–§5.10. It lives in
  `game/resources/fighters/*.tres` and can be regenerated with
  `game/tools/gen_fighter_data.gd` (which now also authors the EX rows and
  METHtality finishers).
- Damage scaling is per-defender combo count: 100/100/85/70/55% for hits
  1–2/3/4/5+, floor **55%**. Chip damage never kills — a blocked hit floors the
  defender at 1 HP.
- HUD uses the default Godot font at pixel-safe sizes; the final pixel font
  arrives with UI art direction (GDD Phase 4).
- **Licensing is undecided.** Treat the repo as all-rights-reserved until a
  LICENSE is added. The three realistic options (all-rights-reserved + NOTICE,
  CC BY-NC 4.0 for content with separate code licensing, proprietary
  source-available) are compared in `docs/LICENSE_OPTIONS.md`; the owner chooses.

## Test coverage

- `game/tests/combat_test.gd` — **97 checks**: clean hits and damage-vs-data,
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
  the two fighters' finishers are distinct.
- `game/tests/round_flow_test.gd` — **30 checks**: intro→fight, KO phase, round
  wins, timeout resolution, a simultaneous KO awarding a pip to both and the
  round advancing, a 2-2 scoreline continuing into a decisive round that ends on
  an outright win, reset clearing draw state, the first two timeout ties
  awarding no pip, the third tie starting a 30-second sudden-death round, a
  sudden-death tie resolving by damage dealt (with the announced tiebreak), the
  deterministic P1 fallback, a clean win in sudden death ending the match, the
  clock frozen during hitstop, and a hit on the timer's final frame counting.
- `game/tests/air_probe.gd` — metrics only, no assertions: air reach envelope,
  damage per arc, first-to-hit trade matrix, blocked advantage and the
  whiff-punish window. Prints a report and always exits 0, so it can never fail a
  suite; `docs/PROPOSALS.md` §3 holds the methodology and targets.
- `.github/workflows/tests.yml` runs both suites plus the air probe on push, pull
  request and manual dispatch.
- `.github/workflows/export.yml` builds Linux/Windows artifacts on `main` and
  `v*` tags, can be dispatched by hand, and caches the export templates per
  Godot version.
