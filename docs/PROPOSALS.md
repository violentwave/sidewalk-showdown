# Implementation Proposals — Wake-up Invuln, Throw Tech, Air Special Balance

Status: **§1 implemented; §2 and §3 are still specification only.** Each section covers how mainstream
2D fighters handle the mechanic, a concrete design for this project's fixed-60 Hz
data-driven architecture, effort, and what it would break.

Engine facts these proposals assume (verified against `main` at the time of
writing, `aff988e`):

- Simulation is fixed 60 Hz; `FighterBase.delta_fixed()` returns
  `1.0 / Engine.physics_ticks_per_second`, and every timing in `MoveData` is in
  simulation frames.
- `MoveData` carries `startup / active / recovery / damage / block_damage /
  hitstun / blockstun / knockback / knockdown / hitstop / level / stance` plus
  `hitbox_offset` + `hitbox_size`; `is_active_frame(f)` is
  `f >= startup and f < startup + active`.
- `FighterBase` states: `IDLE, WALK_F, WALK_B, CROUCH, JUMP_START, JUMP_RISE,
  JUMP_FALL, LAND, ATTACK, BLOCK_STAND, BLOCK_CROUCH, HITSTUN, BLOCKSTUN,
  KNOCKDOWN, WAKE_UP, GRAB, KO, WIN`.
- `hurtbox_rect()` currently returns `pushbox_rect()` — one box, no separate
  hurtbox, no invulnerability concept anywhere.
- `receive_hit(attacker, move)` returns `true` for a hit and `false` for a block
  (and for a KO'd defender). `MatchRoot._detect_hits()` then calls
  `attacker.on_attack_connected(was_hit)`, which sets `move_already_hit = true`
  **on any contact, blocked or not**.
- Knockdown already exists: `move.knockdown` sets `knockdown_frames = 30`, and
  `_knockdown_logic()` transitions into `WAKE_UP` with `wakeup_frames = 12`
  (fixed, not data-driven).
- The throw is an ordinary `MoveData` with `level = THROW`, `startup 5`, `active 2`,
  `recovery 16`, `knockdown = true`, `block_damage = 0`. `can_block()` returns
  `false` for `THROW`, so throws currently ignore block entirely.
- Input is buffered per action with ages: `BUFFER_GRAB = 5`, `BUFFER_MAX_AGE = 20`.
  `input_history` keeps the last 60 action names.

---

## 1. Wake-up invulnerability — implemented

Status: **implemented**. The gate sits in `_poll_hit()` — the merged successor to
`_detect_hits()` — ahead of the airborne-throw guard, so an invulnerable brush
never sets `move_already_hit` and the first vulnerable frame is the one that lands.
Shipped defaults: `FighterData.wakeup_invuln_frames = 6`,
`wakeup_throw_invuln_frames = 8`, `wakeup_frames = 12`, plus per-move
`invuln_kind` / `invuln_start` / `invuln_end` on `MoveData`. Not done: no move
authors reversal invincibility yet, and the debug overlay does not show the invuln
countdown.

### How mainstream 2D fighters handle it

Two distinct schools, and the choice matters more than the frame count:

1. **No universal wake-up invulnerability — invincibility belongs to specific
   reversal moves.** This is the Street Fighter model. In SF6 you get a choice of
   wake-up timing (Normal Rise vs Back Rise) but no free invincibility; defence on
   knockdown comes from spending resources on an invincible reversal. Capcom's own
   2024 battle-change notes describe adding Drive Reversal on wake-up precisely
   because *"without an invincible attack, it proved difficult to deal with strong
   wake-up pressure"* — i.e. the game shipped with pressure that beat everything
   except character-specific reversals, and had to be patched.
2. **Short universal wake-up invulnerability** (usually a handful of frames,
   sometimes strike-only, sometimes with a separate longer throw-invuln window,
   as in the Guilty Gear / BlazBlue lineage). Everyone gets a few frames of safety;
   reversals are about *escaping*, not about *being hittable*.

Either way, the interaction that actually defines the knockdown game is the
**meaty**: an attack timed so its hitbox is active on the first frame the defender
is vulnerable, connecting on an early active frame. Because the hit lands early in
a multi-frame active window, the attacker finishes recovery before the defender
leaves hitstun — that is where knockdown pressure comes from. Meaty timing is
also why "wake-up invulnerability" and "reversal invincibility" must be separate
concepts: invincibility that outlasts the meaty window converts every knockdown
into a free escape, and invincibility that ends too early makes meaties
unbeatable.

### Recommendation for Sidewalk Showdown

**School 2, minimal version**: a short, data-driven universal wake-up window plus
per-move reversal invincibility. Short enough that meaties remain the core
knockdown mix-up, long enough that a knocked-down player is not simply forced to
guess between a meaty and a throw.

**Data model** (`MoveData`):

```gdscript
enum Invuln { NONE, STRIKE, THROW, FULL }

@export_group("Invulnerability")
@export var invuln_kind: Invuln = Invuln.NONE
@export var invuln_start: int = 0          # inclusive, frames from move start
@export var invuln_end: int = 0            # exclusive
```

**Data model** (`FighterData`):

```gdscript
@export var wakeup_invuln_frames: int = 8        # strike + throw, from WAKE_UP frame 0
@export var wakeup_throw_invuln_frames: int = 8  # separate so throws can go live earlier
```

`FighterBase._knockdown_logic()` stops hard-coding `wakeup_frames = 12` and reads
`data.wakeup_frames` (new field, default 12), so knockdown length stays authored
per character while invulnerability is a separate, shorter timer.

**Query**:

```gdscript
func is_invulnerable_to(move: MoveData) -> bool:
    if state == State.WAKE_UP and state_frame < data.wakeup_invuln_frames:
        return true
    if move.level == MoveData.Level.THROW \
            and state == State.WAKE_UP and state_frame < data.wakeup_throw_invuln_frames:
        return true
    if current_move != null and current_move.invuln_kind != MoveData.Invuln.NONE:
        if state_frame >= current_move.invuln_start and state_frame < current_move.invuln_end:
            if current_move.invuln_kind == MoveData.Invuln.FULL:
                return true
            if current_move.invuln_kind == MoveData.Invuln.THROW:
                return move.level == MoveData.Level.THROW
            return move.level != MoveData.Level.THROW   # STRIKE
    return false
```

**Where it must be checked — and this is the important part.** Do *not* fold it
into `receive_hit()` alone. `MatchRoot._detect_hits()` currently calls
`on_attack_connected()` on every contact, which sets `move_already_hit = true`.
If invulnerability is handled inside `receive_hit()`, a hitbox that brushes an
invulnerable defender consumes the move's entire active window and the meaty can
never connect when the window ends. Instead, `_detect_hits()` must skip the
defender before touching the attacker:

```gdscript
if defender.is_invulnerable_to(attacker.current_move):
    return                      # hitbox stays live; no move_already_hit
var was_hit := defender.receive_hit(attacker, attacker.current_move)
attacker.on_attack_connected(was_hit)
```

That single change is what makes meaty timing expressible: the active frames keep
overlapping, and the first frame the defender is vulnerable is the frame that
counts.

**Frame budget to aim for** (tuning proposals, not genre-quoted values):

| Window | Proposal | Why |
|---|---|---|
| `wakeup_invuln_frames` | 6–8 | shorter than WAKE_UP (12), so the last ~4 wake-up frames are meaty-able |
| `wakeup_throw_invuln_frames` | 6–8 | equal by default; raise to 10–12 if throw loops appear |
| Reversal `invuln_start/end` | 1–8 | the DP-style escape: invincible through startup, punishable in recovery |
| Knockdown total | 30 + 12 | unchanged; only the invulnerable slice changes |

**Interaction with meaties**: a meaty is legal exactly when the attacker can have
its hitbox active on frame `wakeup_invuln_frames`. With `active = 2–3` on most
normals and 60 Hz ticks, that window is roughly ±2 frames of input timing —
forgiving enough to learn, tight enough to be a skill.

**Interaction with throws**: throws must be rejected during wake-up. Separately,
`receive_hit()` should reject a `THROW` against a defender that is not `grounded`
— today a grounded grab's hitbox can catch a jumping opponent, because nothing
checks `defender.grounded` and `can_block()` only exempts throws. That is a bug
worth fixing in the same pass.

**Hitstop interaction**: `state_frame` does not advance during `hitstop_frames`,
so an 8-frame invulnerable window can last longer than 8 real frames if a hit lands
(normally impossible while invulnerable, but a trade can do it). Documented, not a
blocker.

### What it would break

- **Every current hit assumption.** `combat_test.gd` sets up hits from `IDLE`, so
  the suite should stay green, but any test or scenario that hits a fighter
  coming out of `KNOCKDOWN` will now whiff for the first 6–8 frames.
- **`move_already_hit` semantics.** Moving the check into `_detect_hits()` changes
  how "missed because of invulnerability" is accounted for; the whiff-meter path
  (`finish_move_whiff()`) will now award whiff meter on invulnerable brushes,
  which is arguably correct (the attack did whiff) but should be a deliberate call.
- **Balance sheet.** Reversals become mandatory knowledge; the current
  "any knockdown → free pressure" game becomes "knockdown → meaty / throw / bait
  reversal". That is the intended change, but it is a change.
- **HUD/debug.** The debug overlay's frame-state readout should show the invuln
  countdown, or nobody will be able to tell whether a whiff was the code or their
  timing.

**Effort:** ~1.5 days. Engine ~150 LOC (`is_invulnerable_to`, `_detect_hits`
ordering, two new data fields, one new `FighterData` field, `WAKE_UP` driven by
data), 4–6 new test cases (meaty hits on the first vulnerable frame; reversal
invincibility window start/end; throw rejected on wake-up; throw rejected vs
airborne), plus overlay text and docs.

---

## 2. Throw tech

### How mainstream 2D fighters handle it

Three separable ideas that are often conflated:

- **Tech / break**: the defender inputs throw within a window and the throw is
  cancelled — no damage, both players pushed apart, neutral-ish reset. Street
  Fighter's model; SF6 adds a **tech lockout**, where pressing a non-throw button
  in the window prevents teching, so mashing cannot option-select defence.
  Capcom's SF6 offense notes also tie throws to the Punish Counter system (a throw
  that punishes a whiffed/blocked move gets bonus damage and a hard knockdown) —
  i.e. the game explicitly rewards throwing a *committed* opponent over a neutral
  one.
- **Escape**: the defender uses a movement option (backdash, jump, invincible
  reversal) to leave the throw's range instead of breaking it. Different risk
  profile: an escape loses to a delayed throw or a shimmy, a tech loses to a
  shimmy-punish too but is much faster.
- **Whiff punish**: throws have real recovery, so a whiffed throw is punishable.
  This is the pressure valve that keeps throws honest — without it, throwing is
  free.

The design lesson: a tech window that is too wide turns throws into dead buttons;
too narrow and throws become unreactable. The usual shape is a short window
(roughly a tenth of a second, i.e. ~5–8 frames at 60 Hz) applied *before/at*
contact, not after it.

### Recommendation for Sidewalk Showdown

**Tech, with a lockout, measured against the existing input buffer.**

**Data model** (`FighterData`):

```gdscript
@export var throw_tech_window: int = 7      # frames of buffer age that count
@export var throw_tech_recovery: int = 10   # both fighters, after a successful tech
@export var throw_whiff_recovery: int = 22  # replaces grab's authored 16
```

**State**: add `TECH` to `FighterBase.State` so tech recovery is a real state with
its own frame count (reusing `BLOCKSTUN` would work but lies in the debug overlay
and in any future frame-advantage readout).

**Detection**, inside `receive_hit()` on the `THROW` path, before damage:

```gdscript
if move.level == MoveData.Level.THROW:
    if not defender.grounded:
        return false                                   # whiff on airborne (bug fix)
    if defender._can_tech():
        defender._start_tech(attacker, move)
        return false
```

```gdscript
func _can_tech() -> bool:
    if not input_buffer.has("grab"):
        return false
    if input_buffer["grab"] > data.throw_tech_window:
        return false
    # SF6-style lockout: committing to another button kills the tech.
    if state == State.ATTACK and state_frame < current_move.startup:
        return false
    for recent in input_history.slice(-data.throw_tech_window):
        if recent in ["light", "heavy", "special", "meth"]:
            return false
    return true
```

**On tech**: consume the buffered `grab`, deal no damage, no `knockdown`,
push both fighters apart (~40 px, i.e. `.position.x ± 20` facing-aware, then
`clamp_to_stage()`), set both to `State.TECH` with `throw_tech_recovery` (10)
frames, and emit a `teched` signal so the HUD can flash "TECH".

**Whiff**: the throw's authored `recovery` should rise from 16 to ~22 so a whiffed
throw is punishable by a light/heavy at typical ranges. This is the single number
that keeps the mechanic honest; without it, teching is the only counterplay and
throws become a coin flip.

**Verdict table this proposal encodes:**

| Situation | Result | Counterplay |
|---|---|---|
| Throw connects, defender input throw in window | Tech, both pushed apart, 10f recovery | delayed throw, shimmy |
| Throw connects, defender pressed a button in window | Throw lands (lockout) | — |
| Throw connects, defender did nothing | Throw lands, knockdown | — |
| Throw whiffs | 22f recovery | punish with any attack |
| Defender jumps / is airborne | Throw whiffs | — (no backdash exists yet) |
| Defender in blockstun, holding back | Throw still lands (throws ignore block, unchanged) | tech or reversal |

**Effort:** ~1 day. Engine ~80 LOC, one new state, three data fields, and
`_can_tech()` which is mostly wiring into the buffer that already exists. Tests:
tech within window, no tech outside window, lockout after a jab, whiff punish
window, throw vs airborne.

### What it would break

- **"Throw ignores block" test.** It still does; tech is a separate path, so the
  existing assertion should survive — but it must be re-checked, because the throw
  branch in `receive_hit()` gains new early-outs.
- **Throw hit-rate feel.** With a 7-frame tech window and 5-frame startup, an
  attentive defender will tech most raw throws. That is the point, but it means
  throws shift from "damage" to "pressure reset", which changes the value of the
  grab move's 120/130 damage. Expect a damage reduction on throws in the same
  pass.
- **Input buffer semantics.** `_consume("grab", BUFFER_GRAB)` currently triggers
  the attacker's own throw. A defender mashing grab would both attempt a throw on
  wake-up and buffer a tech; the lockout rules need to be explicit about which
  wins (proposal: tech check happens first, consuming the buffer).
- **HUD.** No readout exists for TECH; without one, players cannot tell a tech
  from a dropped input.

---

## 3. Air special balance

### Current state (measured from the data, not estimated)

Every fighter's air special is close to a strict upgrade over its jump heavy:

| Move | startup | active | recovery | damage | block_dmg | hitbox (w×h) | level |
|---|---|---|---|---|---|---|---|
| Peggy `jump_heavy` | 7 | 3 | 13 | 80 | 5 | 36×24 | OVERHEAD |
| Peggy `peggy_air` | 10 | 4 | 16 | 90 | 5 | 38×26 | OVERHEAD |
| Richard `jump_heavy` | 7 | 3 | 13 | 90 | 5 | 36×24 | OVERHEAD |
| Richard `richard_air` | 10 | 4 | 16 | 100 | 5 | 38×26 | OVERHEAD |

Air specials cost 3 extra startup frames and 3 recovery frames, and gain 10 damage
plus a slightly larger hitbox. Two structural facts make that trade far better
than it looks:

1. **Every jump attack is `OVERHEAD`.** `can_block()` only allows `LOW` and `MID`
   while crouch-blocking, so all jump-ins beat crouch block by construction.
2. **Landing cancels the move.** `_landing_check()` clears `current_move` and drops
   `ATTACK → LAND` (2 frames) on touchdown. Air moves therefore have *no* landing
   recovery — the authored 13–16 recovery frames only matter if the move finishes
   in the air, which at these speeds it usually does not. With `jump_speed` 285 and
   `gravity` 900, Peggy's jump lasts ~38 frames (apex ~19, ~45 px high), so an air
   special started near the apex finishes well before landing and a whiffed one
   costs only the 2-frame LAND.

Together: an overhead that beats crouch block, has a big hitbox, and is nearly
free on whiff. That is the balance gap, and it is not a damage-number problem —
it is a **risk** problem.

### How mainstream 2D fighters handle it

Jump-ins are balanced by cost, not by damage. The three levers used across the
genre:

- **Landing recovery.** Air normals/specials in Street Fighter have landing
  recovery when they whiff (the character is stuck in a landing animation);
  hitting or being blocked on the way down is what makes them safe. This is the
  main lever and the one we're missing.
- **Anti-air as the designated answer.** A crouching heavy or an anti-air special
  that beats jump-ins cleanly, usually for more damage than the jump-in itself.
  The genre rule of thumb is that a jump-in that gets anti-aired should cost the
  attacker more than a successful jump-in earns.
- **Arc commitment.** Air specials that change trajectory (dive kicks) trade
  mobility or recovery for reach, so they are readable.

### Measurement methodology (headless harness)

The repo already has the right shape for this: `game/tests/combat_test.gd` is a
`SceneTree` script that instantiates `MatchRoot`, steps `await physics_frame`, and
reports `PASS`/`FAIL`. A balance probe is the same harness without assertions —
it prints a table. Proposed `game/tests/air_probe.gd`:

```gdscript
# For each move, each air-start frame, each spacing: does it connect, when,
# and what does it leave behind?
extends SceneTree
# ...
for move in [jump_light, jump_heavy, air_special]:
    for start_frame in range(1, 39):        # jump lasts ~38f
        for dist in [0, 20, 40, 60, 80, 100, 120]:
            # reset, jump, start move at start_frame, step until land
            # record: first contact frame, hit/block, advantage on block,
            #         frames of vulnerability after landing
```

**Metrics to emit per move (CSV-ish, one row per configuration):**

1. **Reach envelope** — for each distance, how many of the 38 air-start frames
   connect. Wide envelope = forgiving jump-in. Target: an air special should
   connect from *fewer* start frames than the jump normal it competes with.
2. **Damage per arc** — damage of the jump-in, plus the guaranteed follow-up if
   any (using the existing 100/100/85/70/55 % scaling, floor 55 %), divided by the
   damage the defender's anti-air deals. Target ratio: air-to-anti-air ≤ 0.8.
3. **Trade chart** — first-to-hit matrix between {jump_light, jump_heavy,
   air_special} × {crouch_heavy, neutral_special} at each distance and start
   frame, using `get_hitbox_rect()` vs `hurtbox_rect()` overlap (this is exactly
   what `_detect_hits()` does, so the probe is measuring the real thing).
4. **Blocked advantage** — `attacker frames remaining after landing` minus
   `defender blockstun remaining`. The overlay's frame-advantage readout (landing
   in a parallel branch) uses the same arithmetic, so the numbers will agree.
5. **Whiff punish window** — frames between the hitbox going inactive and the
   attacker being actionable again. Today this is ~2 (LAND) for anything that
   touches down mid-move.

**Acceptance thresholds to propose (pending a tuning pass, no data changes
without sign-off):**

| Metric | Target |
|---|---|
| Air special reach envelope | ≤ 60 % of the jump heavy's connecting start frames |
| Damage ratio (air-in : anti-air) | ≤ 0.8 |
| Blocked jump-in advantage | ≤ −2 (attacker disadvantaged) |
| Whiffed air move recovery before actionable | ≥ 8 frames |

The first two are measurable today; the last two need the landing-recovery and
frame-advantage work first, which is why the probe should come before any numbers
move.

### What it would break

- **`_landing_check()` semantics.** Adding landing recovery means `_landing_check`
  must distinguish "landed mid-move" from "landed in `HITSTUN`/`KO`", and
  `current_move` must survive touchdown long enough to be read. That touches the
  KO-landing test (`KO loser lands on stage`), which currently relies on the move
  being cleared and the state staying `KO`. Expect to re-verify it.
- **All fighters equally.** Air specials exist on both characters; changing
  landing recovery is a global feel change (jump-ins become riskier for
  everyone), not a per-character tweak.
- **Round flow tests.** No interaction expected (they use grounded attacks), but
  the KO test's 60-frame window should be re-checked if LAND grows.
- **Data files.** Tuning `resources/fighters/*.tres` is out of scope for an
  engineering pass; per the project's working rules those numbers need an explicit
  request. This document proposes the *measurement*, not the new values.

**Effort:** probe ~6–8 h (it is a stripped-down copy of the combat test loop), one
tuning pass ~1–2 days once landing recovery exists, and the landing-recovery
feature itself ~0.5 day (new `MoveData.landing_recovery`, `_landing_check` branch,
one test).

---

## Suggested order

1. **Air probe first** — it is additive, touches no gameplay, and produces the
   numbers needed to argue about everything else.
2. **Wake-up invulnerability** — the largest player-facing change; do it after
   the probe so meaty windows can be measured rather than guessed.
3. **Throw tech** — smallest engine diff, but it only makes sense once wake-up
   invulnerability exists (otherwise wake-up throws stay untechable and the tech
   window mostly covers neutral throws).

## Sources consulted

- Capcom, *Street Fighter 6 Adjustment Summary* (2024-05) — the Drive Reversal on
  wake-up change and its stated rationale:
  https://www.streetfighter.com/6/buckler/assets/images/battle_change/pdf/en/202405ver.pdf
- Infil, *The Fighting Game Glossary* — definitions of meaty, reversal and
  anti-air: https://glossary.infil.net/?t=Meaty%7Cmeaty
- SuperCombo wiki, *Street Fighter 6 / Defense* and */ Offense* — Normal Rise vs
  Back Rise wake-ups, Punish Counter throws, tech lockouts. Both pages are behind
  an anti-bot wall (Anubis), so only search snippets were readable; the SF6
  mechanics cited above are corroborated by the Capcom PDF where it matters.
- In-repo: `game/scripts/combat/fighter_base.gd`, `move_data.gd`, `fighter_data.gd`,
  `game/resources/fighters/*.tres`, `game/tests/combat_test.gd`.
