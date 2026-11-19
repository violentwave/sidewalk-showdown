# Side Switching — facing and crossover rules (2026-11-18)

Fighters are not side-locked. P1 still always spawns on the left and P2 on the
right, and every round resets to those spawns, but during a match either fighter
can end up on either screen side. The HUD stays fixed by player slot: P1's bars
are always on the left of the HUD, P2's on the right, wherever the fighters
stand. The rules below live in `fighter_base.gd` (facing) and
`match_root.gd` (pushboxes), and are regression-covered in
`game/tests/combat_test.gd` §48.

## Facing

- `facing` is **derived, never authored per phase**: every grounded neutral
  frame, a fighter faces the opponent's position. Turning states are IDLE,
  WALK_F, WALK_B, and CROUCH only (`FighterBase.can_auto_turn()`).
- Facing is **frozen everywhere else**: during an attack, hitstun, blockstun,
  knockdown, wake-up, tech, landing recovery, airborne states, KO, WIN — and
  during hitstop (the whole fighter tick early-returns there). A move can never
  flip mid-swing and a block direction can never flip mid-stun. Facing resumes
  on the **first neutral frame after landing or recovery**, because that frame
  re-enters a turning-allowed state.
- **Equal x keeps the current facing.** No randomness, no node order; both the
  tie-break and the freeze are required for rollback/replay determinism.
  `facing` is part of `serialize()`, so save-state is complete.

## Directional inputs

All directional logic is facing-relative; physical bindings and the pad policy
(P1 keyboard + mouse, P2 controller) are unchanged:

- Walking: the axis multiplied by `facing` decides WALK_F vs WALK_B and the
  walk speed. Pressing toward the opponent walks forward.
- Blocking: back-hold relative to the **attacker's side at the moment of the
  hit**, evaluated live in `receive_hit()` via
  `is_holding_away_from(attacker)` through the shared
  `FighterBase.relative_side()` helper — **not** the defender's facing. A
  cross-up that lands behind a defender whose facing is frozen (any stun, or
  the same frame as the cross) is blocked by holding the position axis that
  points away from the attacker now: holding the old back direction fails.
- Specials: `SPECIAL_FWD` / `SPECIAL_BACK` / `SPECIAL_DOWN` motions mirror with
  facing; the forward-EX punish route is a forward-held command relative to
  facing. Grab's forward/neutral selection is facing-relative too.

Cross-up consequence: a grounded defender in a neutral state auto-faces the
attacker, so while they are free to turn, "away from the attacker" and "back on
my facing" agree. The two disagree exactly when the defender cannot re-face —
stun states, or the attacker crossing on the impact frame itself — and that is
when the side helper, not facing, decides the block.

## Facing hysteresis

A fighter turns to face the opponent only once the opponent is more than
`FighterBase.facing_deadzone_px` (default **4 px**, exported, settable)
orthogonal of center away. Inside the band the current facing is kept, so two
fighters standing inside each other under pass-through cannot flicker left and
right every frame (`§49b`). Beyond the band the flip is immediate and lands on
the first neutral frame (`§49c`).

## Knockback and throws

Hits, blocks, throws, and KO launches push the defender **positionally away
from the attacker** (`FighterBase.direction_away_from()`), using the attacker's
position at the moment of the hit. At exactly equal x the defender is treated
as standing in front of the attacker, so the away direction **is the attacker's
facing**. Tech pushes are positional too, from the same helper. This stays
correct after a swap without any special-casing.

Throws connect only **in front of the thrower** and only within the authored
throw range (`FighterBase.is_in_front_of()`): at exactly equal x a throw counts
as in front and connects. A throw against someone behind the thrower whiffs
without consuming the active window, and cannot be tech'd (the side gate runs
before the tech gate in both `_poll_hit` and `receive_hit`).

## Crossover

- **Walk-through default (`fighters_can_pass_through = true`, exported on
  MatchRoot):** Smash-style bodies. Fighters do not collide at all — no
  pushbox separation on the ground or in the air, and no auto-shove when they
  overlap; silhouettes overlap instead of bumping. Combat is otherwise
  identical — hits, throws, and knockback still resolve positionally from the
  shared side helper, so two fighters stacked on one spot push each other away
  on the next connection.
- **Legacy mode (`fighters_can_pass_through = false`):** pushbox separation in
  `MatchRoot._separate_pushboxes()` runs when **both** fighters are grounded.
  Airborne fighters pass through the grounded opponent's pushbox, so the
  classic jump-over works either way; on the ground the bodies repel and a
  fighter cannot walk through the other. A fighter landing overlapping the
  opponent is separated on the first frame both are grounded along x (shared
  correction, corner transfer at the wall): no teleporting, at most one
  body-width of settling.
- **Equal x on separation:** the lower player slot is the left body (fixed
  rule, independent of node order), matching the overlay's equal-x label.

## Counter-hits, trades, and draw order

Counter hits and trades are **state facts**, never position or slot facts:
`MatchRoot._resolve_hits()` polls both fighters' moves first and applies them
together, and a counter is credited when the defender is in its own startup
while the exchange is not a trade. Neither depends on which fighter is P1.

Draw order when bodies overlap is deterministic (`MatchRoot._update_draw_order()`,
recomputed every frame from state alone): an attacker in active or recovery
frames draws above the other fighter; otherwise the fixed P1-under-P2 slot
order stands, so overlapping fighters never flicker. The HUD is unaffected.

## Walls, bounds, and state storage
- **Walls and bounds are unchanged.** A cornered fighter can be crossed over
  by a jump; the crossing fighter lands at the stage bound *beside* the
  cornered body and separation then pushes them apart rather than beyond the
  wall. Facing, spawns, camera (fixed viewport, none exists), frame data,
  damage, meter, and movement speeds are unchanged.

## Debug and capture

- The debug overlay prints `SIDE P1 L/R<arrow> / P2 R/L<arrow>` each frame so a
  swap is legible in captures; at equal x it labels the lower slot L.
- `godot --path game --resolution 1280x720 --script
  res://tools/readme_capture.gd -- swap` poses the mid-round moment with the
  fighters on swapped sides (same HUD, flipped art).

## Determinism

Facing derivation and all tie-breaks are pure functions of the two fighters'
positions and serialized state — no RNG, no delta, no node order, nothing
stored outside `FighterBase.serialize()` / `MatchRoot.serialize()`. The soak
test (§48k) plays a full random-match run on a test-local seeded RNG and
asserts termination with finite, in-bounds positions.
