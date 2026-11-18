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
- Blocking: back-hold relative to the **defender's facing at the moment of the
  hit**. Block is evaluated live in `receive_hit()` via `is_holding_back()`.
- Specials: `SPECIAL_FWD` / `SPECIAL_BACK` / `SPECIAL_DOWN` motions mirror with
  facing; the forward-EX punish route is a forward-held command relative to
  facing. Grab's forward/neutral selection is facing-relative too.

Cross-up consequence: a grounded defender in a neutral state auto-faces the
airborne attacker as they cross overhead, so the old back key is now *forward* —
a cross-up must be blocked by re-holding the key that is back on the new side.
If the defender is already in blockstun, facing is frozen, so the same held key
keeps blocking until the stun ends; the block direction never flips early.

## Knockback and throws

Hits, blocks, throws, and KO launches push the defender **positionally away
from the attacker** (`_direction_away_from()`), using the attacker's position at
the moment of the hit. At exactly equal x, the attacker's facing is the
tie-break. Tech pushes are positional too. This stays correct after a swap
without any special-casing.

## Crossover

- **Default (`fighters_can_pass_through = false`):** pushbox separation in
  `MatchRoot._separate_pushboxes()` runs only when **both** fighters are
  grounded. Airborne fighters pass through the grounded opponent's pushbox, so
  the classic jump-over works; on the ground the bodies still repel and a
  fighter cannot walk through the other. When a fighter lands overlapping the
  opponent, the first frame both are grounded separates them along x using the
  existing pushbox resolution (shared correction, corner transfer at the wall):
  no teleporting, at most one body-width of settling.
- **Walk-through (`fighters_can_pass_through = true`, exported on MatchRoot,
  shipped off):** Smash-style bodies. Grounded fighters walk straight through
  each other; silhouettes overlap instead of bumping. Combat is otherwise
  identical — hits, throws, and knockback still resolve positionally, so two
  fighters stacked on one spot push each other away on the next connection.
- **Equal x on separation:** the lower player slot is the left body (fixed
  rule, independent of node order), matching the overlay's equal-x label.
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
