# Implementation Proposals — Wake-up Invuln, Throw Tech, Air Special Balance

Status: **§1–§5 implemented or measured as a first pass.** §3 now includes
data-driven whiff landing recovery, air-special tuning, and before/after probe
results. Its thresholds are project hypotheses, not externally validated balance
rules. Each section documents the design, implementation, and what remains open.

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
authors reversal invincibility yet. The overlay's F2 readout now shows the
countdown (`INV 4f` / `THROWINV 2f`), and a test confirms the hitstop caveat
below — the window is counted in simulation frames, so hitstop stretches it in
wall-clock time.

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

## 2. Throw tech — implemented

As-built (Phase 2), in `FighterBase` + `FighterData`:

- `throw_tech_window = 7`, `throw_tech_recovery = 10`, `throw_whiff_recovery = 22`
  are data fields on `FighterData`. The grab `MoveData` keeps its authored
  `recovery = 16`; a **whiffed** throw reads `throw_whiff_recovery` instead, so a
  connected throw keeps its original frames.
- Tech detection runs inside `receive_hit()` on the `THROW` path, after the
  airborne guard, before damage. Both fighters go to a real `State.TECH` for
  `throw_tech_recovery` frames, are pushed ~20 px apart, keep all health, and emit
  `teched` (the HUD flashes "TECH" for 20 frames).
- Because grab is also the throw button, a defender's **own throw attempt**
  (ATTACK, THROW move still in startup/active) counts as the tech input: the
  incoming throw breaks the attempt instead of trading with it. This is the
  single-button equivalent of a dedicated tech input; without it, pressing grab
  in neutral would consume the buffer as your own throw startup and no tech could
  ever happen outside blockstun.
- Lockout is frame-based on `input_buffer` ages: any `light` / `heavy` /
  `special` / `meth` buffered within the 7-frame window kills the tech, and a
  non-throw attack still in startup also kills it. Mashing a second button loses
  to the throw.
- The debug overlay shows `TECH` via the normal state name (no lying
  `BLOCKSTUN`), and the frame-advantage readout uses the extended whiff total.

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
throws become a coin flip. (Implemented as `FighterData.throw_whiff_recovery`,
which overrides the grab's authored recovery only on a whiff.)

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
  pass. **Status: damage tuned** (95 Peggy / 105 Richard) based on empirical
  probe measurements vs heavy whiff-punish risk (1.12x Peggy / 1.05x Richard).
- **Input buffer semantics.** `_consume("grab", BUFFER_GRAB)` currently triggers
  the attacker's own throw. A defender mashing grab would both attempt a throw on
  wake-up and buffer a tech; the lockout rules need to be explicit about which
  wins (proposal: tech check happens first, consuming the buffer).
- **HUD.** No readout exists for TECH; without one, players cannot tell a tech
  from a dropped input.

---

## 3. Air special balance

### Baseline before this pass (measured from the data)

On the current-main baseline, both air specials had a larger hitbox and more
damage than jump heavy, with no authored landing recovery:

| Move | startup | active | recovery | damage | block_dmg | hitbox (w×h) | landing recovery | level |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Peggy `jump_heavy` | 7 | 3 | 13 | 80 | 5 | 36×24 | 0 (legacy 2f) | OVERHEAD |
| Peggy `peggy_air` | 10 | 4 | 16 | 90 | 5 | 38×26 | 0 (legacy 2f) | OVERHEAD |
| Richard `jump_heavy` | 7 | 3 | 13 | 90 | 5 | 36×24 | 0 (legacy 2f) | OVERHEAD |
| Richard `richard_air` | 10 | 4 | 16 | 100 | 5 | 38×26 | 0 (legacy 2f) | OVERHEAD |

Air specials cost 3 extra startup frames and 3 recovery frames but gained 10
damage and a larger hitbox. Two structural facts made that trade far better than
it looked:

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

### Landing-recovery rule (design locked before implementation)

`MoveData.landing_recovery` is the **total number of simulation frames spent in
the existing `LAND` state after a whiffed aerial move touches down**. It is not
added to the legacy landing delay. The new value applies only when the move's
stance is `AIR`, the fighter is still in the aerial move/jump state at touchdown,
and that move has not connected. It applies whether touchdown interrupts startup,
active frames, or aerial recovery. A blocked or cleanly hit aerial move uses the
existing 2-frame landing delay instead; this makes contact, rather than a whiff,
the reward. Ordinary jumps and grounded moves also retain the 2-frame delay.

Touchdown immediately cancels the aerial move: clear `current_move` and its hit
flags before entering `LAND`, so no hitbox can survive contact with the floor and
no startup/active frame is replayed. A move that has already finished its authored
airborne frames but is falling still carries its move data to touchdown and gets
the same whiff landing penalty. If an opponent interrupts the aerial move and the
fighter lands in hitstun, blockstun, knockdown, or KO, the existing interrupted
state wins; landing recovery is not layered over it. Hitstop freezes the simulation
before touchdown or during `LAND`, so the recovery countdown starts/continues only
on non-hitstop simulation frames. Authored whiff recovery is vulnerable and cannot
block; a hit interrupts it into ordinary hitstun/knockdown. The legacy 2-frame
`LAND` state (ordinary jumps, hits, or blocks) retains its current block behavior.
Buffered inputs may execute after `LAND` ends under the existing input buffer rules.

This is a prototype rule, not a claim about a genre-wide standard. It limits the
penalty to a whiff while preserving the reward for a hit or block. The data value
is authored per move and evaluated against measured time to actionability; the
current first-pass values and results are recorded below.

### Measurement methodology (headless harness)

The repo already has the right shape for this: `game/tests/combat_test.gd` is a
`SceneTree` script that instantiates `MatchRoot`, steps `await physics_frame`, and
reports `PASS`/`FAIL`. A balance probe is the same harness without assertions —
it prints a table. Proposed `game/tests/air_probe.gd`:

```gdscript
# For each fighter direction, move, sampled air-start frame, and spacing:
# record geometry candidate overlap separately from the resolved contact.
extends SceneTree
# ...
for attacker, defender in [(P1, P2), (P2, P1)]:
    for move in [jump_light, jump_heavy, air_special]:
        for start_frame in [1, 6, 11, 16, 21, 26, 31, 36] if start_frame < airtime:
            for dist in [0, 20, 40, 60, 80]:
                # reset, jump, start move; sample boxes, then call real resolver
                # record: geometry overlap, resolved outcome, hitstop, and state
```

**Metrics to emit per move (CSV-ish, one row per configuration):**

The current probe runs both attacker/defender directions on distances
`[0, 20, 40, 60, 80]` and candidate air-start frames `[1, 6, 11, 16, 21, 26,
31, 36]`, omitting candidates at/after each fighter's measured touchdown
(Peggy has eight valid starts; Richard has seven). Trade samples use start
offsets `[3, 9, 15]`. This is a coarse deterministic sample, not a full sweep or
a statistical balance study. The initial probe only
counted box overlaps and used a different block-start grid; those old numbers
must not be interpreted as resolved hits or block advantage.

The whiff sample uses 170px spacing from the probe's 110px start, keeping both
fighters within the stage bounds `[24, 296]`. The earlier 260px request placed the
defender at x=370, which was clamped to x=296 (an actual gap of 186px); its label
did not match the geometry and that result is superseded.

The updated reach/trade sample records the active hitbox/hurtbox overlap before
calling `MatchRoot._resolve_hits()`, then records the resolver's actual result
separately. The resolver is the production two-sided path: it considers fighter
state, invulnerability, block rules, prior contacts, shared hitstop, and moves
that are interrupted by an earlier hit. Later samples in the same trajectory
therefore reflect real interruptions rather than an independent no-reaction
geometry sweep. A “geometry candidate” remains only evidence of sampled box
overlap, not proof that damage was dealt.

The direct damage table is authored, unscaled, single-hit damage; it does not
simulate combo follow-ups. Anti-air ratios are reported against the defending
fighter's crouch heavy and neutral special separately, since those are different
comparison moves. Blocked advantage requires a real resolver-confirmed block and
measures both fighters to first actionable state, including shared hitstop and
landing. Its sign is `defender-actionable frames - attacker-actionable frames`:
positive means the attacker recovers first; negative means the attacker is
disadvantaged. The defender is held at the sample spacing to avoid walk drift.

Whiff recovery is the attacker-side simulation frames from its last sampled
active hitbox frame to becoming actionable. It follows the real state machine
through hitstop and landing, but is not proof that a specific opponent move can
punish at a practical spacing. Treat every output as measured finite samples,
not an externally validated balance rule.

1. **Reach envelope** — for each distance, how many of the valid sampled air-start
   frames produce a geometry candidate and how many resolve as actual hits. Wide
   envelope = more forgiving jump-in; report actual resolution separately.
2. **Direct damage ratios** — nominal single-hit air damage divided by jump-heavy,
   crouch-heavy anti-air, and neutral-special anti-air damage. These are not a
   simulated full arc or combo calculation; follow-ups and combo scaling need a
   separate measurement. Report which anti-air is the denominator.
3. **Trade chart** — sampled geometric overlaps and resolver outcomes between
   `{jump_light, jump_heavy, air_special}` × `{crouch_heavy, neutral_special}`.
   The actual result uses the production two-sided hit resolver, not just box
   overlap.
4. **Blocked advantage** — actual defender actionable frames minus attacker
   actionable frames after a resolver-confirmed block. Positive means attacker
   recovers first; negative means attacker is disadvantaged. Shared hitstop and
   landing rules are included.
5. **Whiff window** — frames from the last sampled active hitbox frame to the
   attacker's first actionable frame after a whiff, through landing recovery.

**Exploratory targets (project-specific hypotheses, not externally proven
balance rules):**

| Metric | Target |
|---|---|
| Air special reach envelope | ≤ 60 % of the jump heavy's connecting start frames |
| Damage ratio (air-in : anti-air) | ≤ 0.8 |
| Blocked jump-in advantage | ≤ −2 (attacker disadvantaged) |
| Whiffed air move recovery before actionable | ≥ 8 frames |

### First-pass implementation and measured result

The generator is the source of truth. It authors `landing_recovery = 8` on both
jump normals, and `landing_recovery = 12` on both air specials. The air-special
data changes are:

| Fighter | Baseline air special | First pass | Damage / jump heavy | Damage / opposing crouch heavy |
|---|---|---|---:|---:|
| Peggy | 10f / 4f, 90 damage, 38×26 | 12f / 2f, 70 damage, 34×22 | 0.875 | 0.778 |
| Richard | 10f / 4f, 100 damage, 38×26 | 12f / 2f, 60 damage, 34×22 | 0.667 | 0.800 |

Both keep 16f authored airborne recovery, 5 block damage, and 8f hitstop. EX,
METHtality, and throw values were not changed. Direct ratios against the
opponent's neutral special after tuning are 0.667 (Peggy) and 0.632 (Richard).
These are nominal single-hit ratios, not a combo or full-arc simulation.

| Attacker | Air-special resolved starts before → after | Jump-heavy resolved starts (unchanged) | Aggregate air / heavy |
|---|---|---|---:|
| Peggy | `[3,3,3,3,0]/8` → `[2,2,2,0,0]/8` | `[3,3,3,0,0]/8` | 12/9 → 6/9 (67%) |
| Richard | `[3,3,3,0,0]/7` → `[2,2,2,0,0]/7` | `[3,3,3,0,0]/7` | 9/9 → 6/9 (67%) |

Array positions are distances `[0,20,40,60,80]`. The reach target is ≤60%; the
measured 67% misses it narrowly. With only three connecting jump-heavy starts,
the next lower representable ratio is 33%, so forcing the cutoff would require
removing another sampled connection (or using a harsher one-frame attack). We
kept the two active frames and report the miss rather than tuning to a coarse
threshold. Peggy's baseline-only d=60 reach was removed.

| Attacker | Blocked advantage before → after (min/median/max) | Actual blocks | Whiff window before → after (min/median/max) | Whiff samples |
|---|---:|---:|---:|---:|
| Peggy | `1/4/9` → `2/4/6` | 3/8 → 2/8 | `3/12.5/25` → `15/25/35` | 6/8 → 5/8 |
| Richard | `0/3/8` → `1/3/5` | 3/7 → 2/7 | `3/11/21` → `16/23.5/31` | 5/7 → 4/7 |

The ≥8f whiff-recovery target is met by every measured first-pass whiff sample.
The ≤−2 blocked-advantage target is **not** met: both air specials remain
attacker-advantaged on the sampled blocks. This follows the documented whiff-only
rule (contact retains the legacy 2f landing delay); we did not add recovery to a
blocked move just to force the proposal number. Direct damage ratios against the
crouch-heavy comparison move meet 0.8, but full-arc follow-ups are not measured.

Targets are project hypotheses, not balance laws. Reach, anti-air, and block
results are small deterministic samples; playtesting is still needed. The trade
matrix is also limited to three start offsets and selected spacings, so it does
not establish a universal matchup result.

### Implementation interactions and remaining limits

- `_landing_check()` now captures the air move's whiff/contact result before
  clearing `current_move`; all active hitboxes are gone on touchdown. Existing
  `HITSTUN`/`KNOCKDOWN`/`KO` landings retain their state. The KO landing test and
  the full round-flow suite still pass.
- Landing recovery is a global rule for the two current fighters, with per-move
  data values. An extended whiff LAND cannot block; contact keeps legacy behavior.
- `air_probe.gd` reports box candidates separately from resolver-confirmed hits,
  blocks, hitstop, trade outcomes, and attacker actionability. Its whiff spacing
  is 170px, inside the stage bounds; the previous 260px spacing was clamped.
- No claim is made that these numbers are competitively final. The targets and
  coarse sample are not externally validated; retain the before/after results
  above when revising the design.

---

## 4. METHtality — engine core + vertical-slice finishers (implemented)

### Canon locks (do not bend)

- **One unique METHtality per fighter.** No shared finishers, no generic
  "super" lost in translation.
- **Tripp Vlogs is never playable** and therefore never gets a playable
  METHtality; his boss presentation is a separate problem.
- The 15-fighter roster keeps the canon names in `CHARACTERS.md`. The vertical
  slice implements the two playable fighters:
  - **Peg Leg Peggy — Walk the Plank** (homemade prosthetic / hardware-store
    revenge),
  - **Whiskey Richard — Flaming Belch** (whiskey fumes + absurd fire belch).

### Trigger (engine core)

The input already exists (`p1_meth` / `p2_meth`, buffered per action). A
METHtality starts only when **all** of these hold, checked on the frame the
buffered input is consumed:

1. the fighter's hype meter is **full** (`100/100`);
2. the opponent's health is **at or below** `FighterData.meth_health_threshold`
   (250 = 25%);
3. the opponent is in **hitstun or knockdown** (a real kill-confirm window, not
   neutral);
4. the opponent is **not invulnerable** to the finisher — this is what rejects
   wake-up invulnerability and reversal invuln frames.

The trigger is checked from both the neutral action starter
(`_try_start_attack`) and the hit-confirm cancel path (`_try_cancel`), so
"land a hit, press the button" works. The buffered input is only consumed on a
successful trigger; a failed check leaves it to age out normally.

On activation the meter **drains fully** (to 0), the finisher starts as a real
move, and `meth_started` fires for presentation. A whiffed finisher is possible
if the opponent recovers during startup — the meter is still spent.

### Data

- `MoveData.meth` marks the row as a finisher (never selected by ordinary
  lookups; it lives outside `moves`, referenced by
  `FighterData.meth_move`).
- `FighterData` gains `meth_name`, `meth_health_threshold`, `meth_move` — all in
  `resources/fighters/*.tres`, no engine literals.
- Both finishers are 1000 damage, 3f startup / 2f active, `knockdown`, and
  **30f hitstop** — enough damage to always finish an opponent already under the
  threshold, and the long freeze is the phase-1 "screen freeze".

### Presentation (phase 1 only)

- Extended hitstop (30f) on the connecting finisher = the freeze.
- HUD banner: `METHtality / WALK THE PLANK` (or `FLAMING BELCH`) for ~2 seconds.
- The normal KO flow is reused untouched: health hits 0 → `ko` → KO phase →
  pip → round/match end. No cinematic, no choreography, no unique camera.

This is deliberately the cheapest honest version: the rules, gating, spend and
win condition are real; the spectacle is a later phase.

### Tests

- above-threshold health blocks the trigger;
- a neutral (non-stunned) opponent blocks the trigger;
- a non-full meter blocks the trigger;
- a valid trigger spends the whole bar, starts the finisher row, and shows the
  banner;
- wake-up invulnerability blocks the trigger;
- the finisher ends the round as a normal KO win;
- the two vertical-slice fighters have distinct finisher data.

### What it would break / later work

- The METHtality is currently a single hit at point-blank range; longer
  cinematics will need a dedicated state and camera/anim systems that do not
  exist yet.
- AI and the CPU opponent must learn the same gate once AI exists.
- The threshold (25%) and 30f freeze are first-pass balance numbers; treat them
  as tunable data, not law.

---

## 5. Hype meter spenders — EX specials (implemented)

### Current meter economy (measured from the data)

There is nothing to spend meter on today, so the meter is a scoreboard. The
numbers, read from `MoveData` and verified as **not overridden** in either
`resources/fighters/*.tres`:

| Event | Gain | Notes |
|---|---|---|
| Attacker lands a hit | **+6** | `meter_gain_hit` default on every move |
| Attacker gets a hit blocked | **+3** | `meter_gain_block` |
| Attacker's move whiffs | **+1.5** | `meter_gain_whiff`, paid at the move's end |
| Defender is hit or blocks | **+4** | `meter_gain_receive` |

`max_meter = 100` (`FighterBase`), so a full bar is about **17 clean hits**, or a
typical round: roughly 10 hits landed and 10 taken per fighter gives 60 + 40 =
**one full bar per round**, before whiff income. That makes a 50-cost spender
land about twice per match — strong enough to matter, rare enough to read as a
moment.

### Design

- **EX = the special input while holding heavy.** There is no extra button on
  the 6-button-lite layout, so heavy (K / `.`) acts as the modifier: `L`, `L+K`,
  etc. The EX move is the same stance/direction special, strengthened.
- **`MoveData.meter_cost` + `MoveData.ex`.** EX variants are ordinary data rows:
  same `input` / `stance`, `ex = true`, `meter_cost = 50`. All tuning stays in
  `resources/fighters/*.tres`; the engine has no balance literals.
- **`FighterData.find_move()` never returns an EX row**; `find_ex_move()` does.
  A normal special press when the meter is short falls back to the base special
  (the input is never eaten) and leaves meter untouched.
- **Spending happens before the move starts** (`_try_start_attack` /
  `_try_cancel` via `spend_meter()`), clamps at 0, and cannot go negative.
- **Scope**: each vertical-slice fighter gets EX variants of the neutral and
  forward specials (4 rows total). Down/back/air specials keep their base
  versions until the air-balance pass; EX cancels are already wired because the
  special-cancel path shares the same starter.

### Tuning (50 meter each)

Peggy — faster, more damage, still the rushdown:

| Move | Startup | Active | Recovery | Damage | Block | Hitstop | Hitbox |
|---|---|---|---|---|---|---|---|
| `peggy_neutral` | 9 | 3 | 19 | 95 | 6 | 8 | 40×20 |
| `peggy_neutral_ex` | **7** | 3 | **17** | **120** | 7 | 10 | 44×20 |
| `peggy_forward` | 11 | 4 | 22 | 110 | 7 | 8 | 44×22 |
| `peggy_forward_ex` | **9** | 4 | **20** | **145** | 9 | 10 | 48×24 |

Richard — longer reach and bigger stun, still the counterpuncher:

| Move | Startup | Active | Recovery | Damage | Block | Hitstop | Hitbox |
|---|---|---|---|---|---|---|---|
| `richard_neutral` | 9 | 3 | 19 | 105 | 6 | 8 | 40×20 |
| `richard_neutral_ex` | **7** | 4 | **17** | **135** | 8 | 10 | 44×20 |
| `richard_forward` | 11 | 4 | 22 | 120 | 7 | 8 | 44×22 |
| `richard_forward_ex` | **9** | 4 | **20** | **150** | 9 | 10 | 48×24 |

Both EX rows keep/have `knockdown` on the forward variant, so the meter buys a
hard knockdown into the wake-up game rather than only raw damage. Every EX is
strictly better on damage and startup; the cost is paid up front, so a whiffed
EX is a real loss.

The air probe is unchanged by these rows (they are ground-only), which is the
intended outcome of the tuning pass: EX must not disturb the air-special
envelope tracked by PROPOSALS §3.

### Tests

- meter is deducted by `meter_cost` when the EX starts, and an EX move is
  actually the active move;
- insufficient meter starts the base special instead, meter unchanged;
- the EX row differs from the base row in damage and startup;
- spending exactly the remaining meter floors at 0;
- `find_move()` ignores EX rows (no accidental base-move regression).

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
