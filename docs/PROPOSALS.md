# Implementation Proposals — Combat Systems and Balance

Implementation status on `main` at `0d3cdfd` (after the first three correctness PRs):

| Section | Implemented now | Future / still open |
|---|---|---|
| §1 Wake-up invulnerability | Data-driven wake-up strike/throw windows, per-move reversal invuln fields, overlay countdown, tests | No current move authors reversal invulnerability; no character-specific wake-up defense |
| §2 Throw tech | 7f tech window, lockout, both-fighter `TECH`, 22f whiff recovery, tuned 95/105 damage | Punish Counter throws, delayed-throw pressure, shimmy baiting |
| §3 Air special balance | Whiff-only landing recovery (8f normals / 12f specials), first-pass air-special data, two-direction probe | Reach/blocked-advantage targets still missed; probe is coarse and informational; no full-arc/combo simulation or competitive validation |
| §4 METHtality | Meter/full-health-state kill-confirm gate, meter drain, finisher data, freeze/banner, KO flow | GDD §5.9 final-round finish prompt, cinematic/camera/choreography, fuller presentation |
| §5 Hype meter | EX specials at 50 meter, data-driven variants, fallback/floor tests | Combo extensions, defensive burst, super, other future spenders |
| §6 Authored combos | Existing hit-confirm routes and 55% scaling floor | Direction approved; data-authored cancel windows, counter-hit, juggle/OTG policy, route data and combo-arc measurement are not implemented |
| §7 Grappling expansion | Grounded, techable normal throws and existing throw rules | Direction approved; Peggy/Richard command-grab special rows and their tech policy are not implemented; detailed choices remain open |

Only the “Implemented now” cells are current behavior. The remainder are design
proposals or known gaps, not shipped claims. See
[`PHASE_STATUS.md`](PHASE_STATUS.md) for phase gates and the
[current-baseline reconciliation](audits/2026-11-05_current-baseline-reconciliation_e6d40d9.md)
for reproduced issues. Air-probe output is informational measurement, not a
passing balance assertion.

### Shared canon and scope for §§6–7

> Combos are control-uniform across all fighters: every fighter shares the same
> input taxonomy (light/heavy x stand/crouch/air, five special directions, grab,
> EX, METH). Character identity comes from authored data and later animation,
> never from different control schemes.
>
> Animations are out of scope: the combo and grab systems must be fully playable
> on the current silhouette fighters. Animation wiring is a later art phase and
> must not be a dependency.
>
> Scope is Peggy and Richard only.

These are approved owner decisions. §§6–7 are approved design directions, not an
implementation authorization. Current controls and silhouette presentation stay
the baseline; no animation, art, new roster, or control-scheme work is a
dependency.

### Owner decisions — correctness queue

The following owner decisions are recorded verbatim. They determine the
correctness work that precedes authored combos and grappling implementation:

> - D1: K1 — knockdown rejects all strikes except MoveData.meth rows;
>   can_meth() keeps the knockdown path. The exception must be documented
>   and tested both ways (METH triggers on knockdown and spends meter;
>   non-METH strikes whiff).
> - D2: R1 — throws cannot connect during KNOCKDOWN.
> - D3: PR 4a only — bounded hitstop buffer freeze capped at one normal
>   buffer window, all buffered actions (including grab and its lockout)
>   frozen together. Blockstun policy (4b) is deferred to playtest.

Implementation status is tracked in `docs/PHASE_STATUS.md`; D1/K1 and D2/R1
are implemented. PR 3 implements corner-separation remainder transfer with
four wall-arrangement regressions. D3/PR 4a is implemented as hitstop-only
buffer-age freeze capped at one normal window; blockstun policy 4b remains
deferred to playtest.

Engine facts these proposals assumed at original writing (verified against
`main` at `aff988e`):

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

## 3. Air special balance — first pass implemented; targets open

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
measured 67% misses it narrowly. At each of d=0/20/40, the sample has 3 jump-heavy
starts and 2 air-special starts. In aggregate, one fewer air-special sample would
put the total at 5/9 (56%), but that would be a one-hit change in this small grid.
We kept the two active frames and report the miss rather than tuning to that
single-sample cutoff or a harsher one-frame attack. Peggy's baseline-only d=60
reach was removed.

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

## 4. METHtality — engine core implemented; finish presentation future

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

## 6. Authored Combo System — proposal (Phase 3; direction approved, implementation pending)

### Goal and data shape

Replace the hard-coded routes in `FighterBase._try_cancel()` with per-move
authored rules. A rule should identify:

| Field | Meaning |
|---|---|
| `target_move_id` or `target_category` | One move, or a category such as normal, special, EX, or METHtality |
| `target_input` / `target_stance` (when needed) | Resolve a category using the same buffered input and stance lookup as today; for example, distinguish light-normal from heavy-normal without changing controls |
| `from_frame`, `to_frame` | Inclusive start and exclusive end of the source move's legal cancel window, in simulation frames from move start |
| `condition` | `HIT`, `BLOCK`, `COUNTER_HIT`, or `WHIFF`; only a result actually observed for the current move can qualify |
| `kind` | `CHAIN` for normal-to-normal routes; `CANCEL` for routes into special, EX, or METHtality |

An illustrative resource shape (not a code change or final schema):

```text
cancel_rules:
  - target_category: NORMAL
    from_frame: 3
    to_frame: 10
    condition: HIT
    kind: CHAIN
  - target_category: SPECIAL
    from_frame: 3
    to_frame: 10
    condition: HIT
    kind: CANCEL
```

Frame endpoints and target resolution need one documented convention. Validate
that target IDs exist, categories resolve unambiguously, and overlapping rules
cannot select different moves nondeterministically. `BLOCK`, `COUNTER_HIT`, and
`WHIFF` become available conditions only when the resolver reports those outcomes;
they must not be inferred from a generic contact flag. In particular, a blocked
move is not a hit-confirm under current behavior. A broad normal category must
still resolve the player's buffered light/heavy and current stance using the
existing lookup policy; it must not pick an arbitrary row.

### Behavior-preserving migration

The first data-authored state is a migration, not a balance pass. For both
Peggy and Richard, capture the current behavior exactly before considering new
routes:

- After a confirmed hit, a light-input move can chain to the current-stance light
  or heavy, or cancel to the current-stance special.
- After a confirmed hit, a heavy-input move can cancel to the current-stance
  special; it cannot chain to another normal.
- These windows are currently implicit: `_attack_logic()` checks after
  `state_frame > current_move.startup` until the move ends. The migration must
  encode the same effective frames, buffering, stance lookup, and EX selection.
- Current route outcomes are hit-only. Do not add block, counter-hit, or whiff
  cancels in the parity migration. Preserve all other current move behavior.
- Preserve the global METHtality kill-confirm gate: buffered METH is checked
  separately after a hit-confirm from any move and from the neutral starter; it
  still requires full meter, the health threshold, a hitstun/knockdown target,
  and a target not invulnerable to the finisher. A METH category/rule must not
  bypass these checks or narrow the existing global gate accidentally.
- Compare before/after route reachability for every generated Peggy/Richard move
  and input buffer timing. Only after this parity state passes may additional
  authored routes be proposed and tuned.

`CHAIN` versus `CANCEL` is descriptive and testable: a chain changes from one
normal to another normal; a cancel interrupts the source move into a special,
EX, or the separately gated METHtality. EX remains selected by the existing
special-plus-heavy input and costs its authored meter amount. Do not make a
special/EX route free or let an invalid target consume the input.

### Counter-hit definition and feedback

GDD §5.6 specifies **+2 frames of hitstop** for a counter-hit but does not yet
define its detection window. Recommended operational definition for owner
approval: a strike that resolves while the defender is in the startup portion of
an attack, and interrupts that attack, is a counter-hit. A hit on recovery, a
trade where both attacks resolve, or a hit on a non-attacking state is not one.
Record the result at hit resolution before changing the defender's state; apply
the move's authored hitstop plus 2 simulation frames once, shared by both
fighters as ordinary hitstop is today.

Expose an explicit counter-hit result/signal to the HUD and show the GDD §10.3
counter-hit indicator alongside the existing combo feedback. Keep the result
available to cancel evaluation: a `COUNTER_HIT` rule is legal only on that
resolved result; an ordinary `HIT` rule must not require counter-hit. Define
whether a counter-hit also satisfies an ordinary HIT rule (recommend yes, with a
counter-hit-specific rule taking precedence) to avoid overlapping-rule ambiguity.
No HUD animation or art is a prerequisite; a text indicator works on silhouettes.

**Implementation status (PR 1, implemented):** `MatchRoot._resolve_hits()` polls
both hits before applying either. A counter is granted only when the defender
`is_in_attack_startup()` and the opposing poll is null (no trade). `receive_hit()`
receives `counter`, adds `FighterBase.COUNTER_HIT_HITSTOP` (+2) to the shared
hitstop once, sets `attacker.move_counter_hit`, and emits `counter_hit_landed`,
which the HUD shows as `COUNTER HIT`. Precedence, to be applied by the cancel
rules in PR 2: a counter hit also satisfies an ordinary `HIT` rule; a
`COUNTER_HIT`-specific rule takes precedence over `HIT` when both match. Blocked
strikes are never counters, because a fighter in startup cannot block.

**Implementation status (PR 2, implemented):** `MoveData` gained a typed
`cancels: Array[CancelRule]` array and `CancelRule` (target LIGHT/HEAVY/SPECIAL,
kind CHAIN/CANCEL, condition HIT/COUNTER_HIT, inclusive `from_frame..to_frame`
window measured from move start). `FighterBase._try_cancel()` METHtality gate is
unchanged but now explicit (`move_hit_confirmed and state_frame > startup`);
rules are evaluated in array order in two passes — first `COUNTER_HIT` rules
(matching when `move_counter_hit` is set), then ordinary `HIT` rules (which a
counter hit also satisfies, per precedence above). `BLOCK` and `WHIFF`
conditions are reserved and rejected by `CancelRule.validate()` until the
resolver reports those outcomes. The legacy engine-coded routes were migrated to
authored data on all 12 light rows and 2 heavy rows per fighter: window
`startup+1 .. total_frames` (unchanged), light targets special-then-light-then-
heavy, heavy targets special-only — behavior exactly preserved, with a
generator-parity diff confirming every frame/damage/id line identical before
and after regeneration. Buffered inputs are still consumed (and lost) when no
matching move exists.

### Blocking interactions and blockstring safety

#### Current behavior measured in the real simulation

The authored `MoveData.knockback` is **not** used when a strike is blocked. I
verified this in a headless Godot 4.7.2 run of the actual `MatchRoot` scene,
testing Peggy and Richard as the attacker in turn at mid-stage, with blocked and
unblocked light, heavy, neutral-special, and forward-special rows. The defender
held back for the block case. I measured absolute horizontal displacement from
resolved contact through 20 subsequent physics frames, including hitstop and
the actual stun-state deceleration:

| Move | Authored hit `knockback.x` (px/s) | Block displacement / 20 frames | Hit displacement / 20 frames |
|---|---:|---:|---:|
| `light` | 55 | 2.53 px | 3.88 px |
| `heavy` | 90 | 2.53 px | 10.79 px |
| `peggy_neutral` | 110 | 2.53 px | 14.42 px |
| `peggy_forward` | 130 | 2.53 px | 20.58 px |

These are controlled mid-stage samples, not universal spacing or corner results.
Both attacker orientations produced the same displacement magnitudes. The real
resolver applies the move's authored horizontal knockback on hit; on block it
instead assigns a fixed `attacker.facing * 45 px/s` horizontal velocity to the
defender, then blockstun decelerates it. Thus blocked moves currently share the
same small push regardless of authored hit knockback. There is no per-move
block-pushback field. This finding is from simulation; the source path is
`FighterBase.receive_hit()`.

#### Proposed rules

- Add an authored block-pushback value in simulation units/second, separate from
  hit `knockback`. For the parity migration, author **45 px/s** on every current
  strike row to preserve the measured fixed impulse. Recommend **45 px/s as the
  initial minimum** for non-throw blocked strikes; later rows may use more after
  route testing, but a row may not silently fall below the floor. The floor is
  the assigned velocity, not a promise of a fixed pixel displacement: hitstop,
  blockstun duration, deceleration, and walls affect realized movement.
- At a corner, never push the defender through the stage bound. Clamp the
  defender at the wall and transfer the remaining separation displacement to
  the attacker, away from the defender, subject to the attacker's own stage
  bound. Then run pushbox separation; no wall crossing or residual overlap is
  accepted as a “safe” blockstring. Test both left/right corners and both player
  orientations. The existing B4 corner-separation defect must be resolved or
  explicitly accounted for before claiming this exit.

**Implementation status (PR 5, implemented):** `MoveData` gained an authored
`block_pushback` (px/s) in the `On hit` group: the generator writes a flat
**45.0** on every strike row (normals, specials, EX rows, and each
`meth_move`), throws author **0.0** because they are never blocked.
`FighterBase.receive_hit()`'s blocked path now assigns
`attacker.facing * move.block_pushback` — the engine no longer carries the
constant. Corner rule: when the blocked defender stands at a stage bound and
the authored pushback would shove it through the wall, the unapplied
displacement transfers to the attacker (equal magnitude, away from the
defender), and the defender's velocity is pinned to 0; pushbox separation runs
afterwards as before (no wall crossing, no residual penetration). Verified with
20 new combat checks: the 45-px/s parity matrix (both fighters, throws = 0),
data-driven displacement (a 60-px/s authored row measures 60, not 45), and both
corner walls showing pinning plus the measured attacker displacement.
- The behavior-preserving cancel migration remains **hit-only**. A blocked move
  does not continue its route unless a separate `condition: BLOCK` rule is
  explicitly authored and approved. For each such rule, author the next move,
  blockstun and pushback, and whether a gap exists; the defender must be able to
  block the next hit or use an available challenge/escape if its timing permits.
- Evaluate blocked advantage for the **whole blockstring**, not by labeling an
  early normal safe in isolation. Measure from the final block in the authored
  route to each fighter's first actionable frame, including shared hitstop,
  each move's blockstun, pushback, landing, and the actual cancel timing. Keep
  the existing sign convention from §3: `defender actionable - attacker
  actionable` (positive means the attacker recovers first). Apply a chosen
  blocked-advantage target to the route endpoint; an intermediate `BLOCK`
  cancel does not erase the defender's chance to act during a gap. No general
  grounded-blockstring target is currently specified. The exploratory ≤−2
  target remains specifically a blocked jump-in hypothesis, not a universal
  requirement; obtain owner approval before setting broader numeric targets.

#### Blocked variants for the candidate routes

The initial data-authored parity state adds no block cancels, so the following
are the explicit blocked variants for the §6 examples. At every listed block,
the route stops in the parity state. The defender exits blockstun on the
resolver-determined first actionable frame and can guard, jump, throw, or
challenge with a normal if legal; measure whether the attacker is still
recovering and punishable rather than assuming the answer from hit knockback.
If a future `BLOCK` rule continues the route, add that continuation and its
endpoint advantage to the authored route data and tests.

| Fighter / route | Blocked variant and defender response |
|---|---|
| Peggy — jump-in starter | `jump_heavy` blocked: no `light` link/cancel in parity; block the landing interaction, then take the first actionable guard/jump/challenge option. Measure landing recovery and punishability. |
| Peggy — grounded chain | `light` blocked: no `heavy` follow-up in parity; blockstun ends, then the defender can guard or challenge/escape at its first actionable frame. |
| Peggy — punish | `heavy` blocked: no `peggy_forward_ex` in parity; the defender gets the measured blockstun/pushback response. Any future block-cancel into EX must specify its own endpoint safety and gap. |
| Richard — jump-in starter | `jump_heavy` blocked: no `light` link/cancel in parity; block the landing interaction, then take the first actionable guard/jump/challenge option. Measure landing recovery and punishability. |
| Richard — grounded chain | `light` blocked: no `heavy` follow-up in parity; blockstun ends, then the defender can guard or challenge/escape at its first actionable frame. |
| Richard — punish | `heavy` blocked: no `richard_forward_ex` in parity; the defender gets the measured blockstun/pushback response. Any future block-cancel into EX must specify its own endpoint safety and gap. |

### Juggle, OTG, and knockdown protection

> **Owner decisions (2026-11-07, verbatim):**
>
> - Launcher category: the forward special (and its EX variant) is the launcher
>   for BOTH fighters, as a uniform per-fighter category rule. Launchers are
>   authored per-move vertical knockback data, never an engine special-case.
>   Crouch heavies remain hard knockdowns.
> - EX cancel is grounded-only: ratified policy, not a temporary restriction.
> - Command-grab values (120/14/3/24 Peggy, 140/16/3/26 Richard, knockdown 30f,
>   meter 6-8/1.5/4) are provisional first-pass numbers; the reward-to-whiff-
>   punish metric (0.80/0.97) is informational. Revisit in the Phase 9 balance
>   pass after playtest.

> **Owner decisions (2026-11-07, playtest outcomes, verbatim):**
>
> - B5 air momentum: KEEP current stop-on-attack behavior (M2). Airborne
>   grab rejection confirmed correct.
> - B7 wake-up blocking: KEEP current no-block wake-up tail (W2); the
>   meaty-or-invuln game stands.
> - 4b blockstun buffering: DEFERRED (S4 documented). Punishes feel
>   responsive to the owner.
> - Jump-in connect window (20-44 px): KEEP; no widening.
> - Command-grab values: confirmed provisional; revisit in Phase 9.
> - Richard base launcher vertical knockback: 260 (one juggle follow-up).
>   This is intentional asymmetry: Peggy runs the full 3-hit route,
>   Richard gets shorter/heavier juggles with EX unlocking depth.

Proposed bounded rule set, with numeric tuning to be confirmed by the owner:
- Track whether a combo has put the defender into an airborne juggle and count
  successful hits against that airborne defender per combo. Start with a
  proposed cap of **3 airborne hits**; once reached, later strikes do not extend
  the juggle. The counter resets only when the combo ends, not on a move change.
- Scale repeated air hits with increased gravity and/or reduced horizontal
  pushback so the arc returns to the floor and corner carry cannot grow without
  bound. Record the chosen per-hit scaling in move/combo data or one clearly
  documented policy; do not stack hidden engine multipliers.
- OTG means a hit against a grounded `KNOCKDOWN` target. The owner’s K1/R1
  decisions are boundaries: **K1: knockdown rejects strikes except METH rows**;
  **R1: throws are rejected during knockdown**. Therefore no ordinary OTG strike
  or command grab may be added by this proposal. A METH row remains subject to
  the existing global METHtality gate and invulnerability check; it is not a
  general OTG exception for other move rows.
- Knockdown protection must be resolved before ordinary hit confirmation so a
  rejected strike does not consume its active window. Airborne juggle hits and
  grounded knockdown protection are distinct cases. Throws remain grounded-only
  and rejected against a knocked-down target under R1.

The suggested three-hit cap, gravity/pushback policy, and exact combo-reset rule
are proposal parameters, not implemented limits. Validate them through full
simulation and playtest before tuning damage around them.

**Implementation status (PR 3, implemented):** `FighterBase` now tracks
`juggle_hits` per defender — successful hits against a not-grounded defender in
the current combo. Cap `JUGGLE_HIT_CAP = 3`: an airborne defender at the cap is
rejected in `is_invulnerable_to()` (before hit confirmation, so the rejected
strike keeps its active window live) and mirrored in `receive_hit()` for direct
callers. The first airborne hit of a combo keeps the authored launch arc
exactly; each repeat airborne hit scales horizontal knockback by
`JUGGLE_KNOCKBACK_SCALE = 0.7` per prior airborne hit, and airborne hitstun
gravity is multiplied by `JUGGLE_GRAVITY_MULT = 1.25` once `juggle_hits >= 2`.
The counter is documented engine policy (not hidden multipliers) and resets
only with the combo (`_tick_combo()`, KO, and `reset_state()`), never on move
change; grounded K1/R1 knockdown protection is unchanged and remains a distinct
case. These constants are playtest-tunable as described above.

### Peggy and Richard route examples

These are candidate authored routes for data/arc validation, not claims that all
links currently connect at every spacing. Existing move IDs are shown where
known; routes must remain playable with the current silhouette fighters.

**Implementation status (PR 4, implemented):** both fighters' six route shapes
are authored data (generator `game/tools/gen_fighter_data.gd`, applied to the
`.tres`): the heavy input rows carry a `Target.EX` cancel ordered before the
legacy `SPECIAL` cancel, and `jump_heavy` carries an extra `Target.LIGHT`
`CHAIN` rule for the jump-in starter. EX semantics follow the existing EX
command shape: both a special buffer AND a heavy buffer are required and are
checked WITHOUT spending either buffer until the full command is present, so a
lone special buffer still reaches the legacy `SPECIAL` route and a lone heavy
buffer stays usable; when meter cannot pay, the base forward special is the
documented fallback with meter unchanged. **Fix (PR 4a):** the punish EX
rule fires only on a grounded, forward-held command (`_special_input()` is
`SPECIAL_FWD`); any other direction, or an airborne fighter, leaves the buffers
untouched so the legacy `SPECIAL` route resolves the input by its own direction
rules. The base-forward fallback therefore never replaces a neutral or back
special. The orange counter-hit precedence
from PR 1 is unchanged. Route outcomes are verified end to end through the real
resolver for both fighters (jump-in starter chains into `jump_light`, grounded
light chains into heavy, punish EX confirms in at the meter cost, blocked
variants keep parity), with blocked-route endpoints measured from the defended
blockstun rather than assumed.

| Fighter | Route | Illustrative route data | Explicit blocked variant |
|---|---|---|---|
| Peggy | Jump-in starter | `jump_heavy` (landed starter) → `light` (`HIT`, `CHAIN`) → `peggy_neutral` (`HIT`, `CANCEL`) | `jump_heavy` blocked: no follow-up in parity; defender's first actionable guard/jump/challenge and attacker landing recovery must be measured. |
| Peggy | Grounded chain | `light` → `heavy` (`HIT`, `CHAIN`) → `peggy_neutral` (`HIT`, `CANCEL`) | `light` blocked: chain stops in parity; defender can act at its first actionable frame. |
| Peggy | Punish | `heavy` (punish hit) → `peggy_forward_ex` (`HIT`, `CANCEL`, pay 50 meter); base-special fallback follows existing EX rules | `heavy` blocked: no EX follow-up in parity; any future block-cancel must declare its gap and endpoint safety. |
| Richard | Jump-in starter | `jump_heavy` (landed starter) → `light` (`HIT`, `CHAIN`) → `richard_neutral` (`HIT`, `CANCEL`) | `jump_heavy` blocked: no follow-up in parity; defender's first actionable guard/jump/challenge and attacker landing recovery must be measured. |
| Richard | Grounded chain | `light` → `heavy` (`HIT`, `CHAIN`) → `richard_forward` (`HIT`, `CANCEL`) | `light` blocked: chain stops in parity; defender can act at its first actionable frame. |
| Richard | Punish | `heavy` (punish hit) → `richard_forward_ex` (`HIT`, `CANCEL`, pay 50 meter); base-special fallback follows existing EX rules | `heavy` blocked: no EX follow-up in parity; any future block-cancel must declare its gap and endpoint safety. |

For each rule the eventual resource data supplies the chosen frame window. The
first migration rules must reproduce legacy windows exactly; any additional
windows/routes in these examples are a separate owner-approved expansion. Test
reachability at practical spacing and ensure the jump-in routes are links after
landing, not animation-timed assumptions.

### Scaling decision and measurement

The current code implements hit scaling `100/100/85/70/55%` for hits 1–2/3/4/5+
with a **55% floor**.

> **Owner decision (2026-11-06, documentation only):** keep the implemented
> **55% floor**. GDD §5.10's 35% minimum is amended to 55% so the GDD matches the
> engine. The 35% value may be revisited only after a juggle limit exists. No
> code, resource, or test change is part of this decision.

Extend the air-probe plan after the route simulator exists. In addition to
single-hit direct damage, simulate sampled jump arcs with authored follow-ups,
cancel windows, hitstop, knockback/gravity, landing, juggle cap, and per-hit
scaling. Report route reachability, total and scaled damage, hit count, combo
duration, air/ground transitions, and ending state, separating geometry
candidates from resolver-confirmed hits. Use deterministic start frames and
spacing in both fighter directions; retain current single-hit metrics and label
the new output as measured samples, not balance assertions.

### Tests and exit criteria

- Legal and illegal target IDs/categories; boundary tests for inclusive start /
  exclusive end frames; buffered input still starts only in legal windows.
- Legacy Peggy/Richard routes match the pre-migration route matrix exactly:
  light→light/heavy/special and heavy→special on hit only; no new block/whiff
  cancels. Test EX affordability/fallback and METH gate parity separately.
- `CHAIN` only permits normal-to-normal and `CANCEL` only permits its authored
  special/EX/METH target class. Illegal routes do not consume meter or inputs.
- Counter-hit startup interruption gets exactly +2 hitstop and HUD feedback;
  recovery hits and trades do not. Counter-hit and ordinary-hit cancel
  precedence is deterministic.
- Block-pushback parity is 45 px/s on blocked strikes and is independent of hit
  `knockback`; hit tests still use the authored hit value. Verify the authored
  minimum on every blocked strike, including low/high/special routes.
- Corner block tests on both walls transfer blocked defender displacement to
  the attacker without crossing stage bounds or leaving residual pushbox
  overlap. Include the B4 separation fix/behavior in the acceptance evidence.
- Every route's blocked variant matches its data: no continuation without an
  authored `BLOCK` rule; when one is authored, test gaps, blockstun, pushback,
  defender challenge/escape, and whole-route blocked advantage against the
  approved target. Do not infer safety from hit knockback or the first move's
  advantage alone.
- Juggle count reaches, then rejects, the selected cap; combo reset, gravity /
  pushback scaling, K1 knockdown protection, R1 throw rejection, and the global
  METH gate each have positive/negative regression cases. No route can loop
  indefinitely or create an infinite grounded/airborne reset.
- Per-fighter route-data integrity: all referenced IDs/categories resolve in
  Peggy and Richard generator output; regeneration is deterministic and preserves
  the authored rules.
- Existing combat and round-flow suites pass, with new integration tests for
  each route; air-probe output includes simulated combo arcs without converting
  informational metrics into assertions.

**Dependencies:** owner approval of rule schema, counter-hit definition, juggle
cap/scaling, and the scaling floor. Migration/parity should precede added routes;
animation work is explicitly not a dependency. Rollback can revert the data
authored rules while leaving unrelated move data intact.

---

**Combo-arc measurements (PR 7, updated by the launcher PR; informational;
`game/tests/air_probe.gd`).** Each route runs through the real `MatchRoot`
resolver at 28 px spacing against an idle, non-blocking, non-DI defender. The
attacker pairs a cancel attempt only after a confirmed hit past startup, and
holds the forward/heavy keys only for that attempt. These are finite samples of
the current code and data, not balance targets and not assertions.

| Route | Peggy (measured) | Richard (measured) |
|---|---|---|
| grounded light > heavy > special | 3/3, 200.8, [35,85,81] scale [1,1,0.85] | 3/3, 234.2, [45,100,89] scale [1,1,0.85] |
| grounded heavy > fwd EX, 100 meter | 2/2, 230, [85,145] | 2/2, 250, [100,150] |
| grounded heavy > fwd, 0 meter | 2/2, 195, [85,110] | 2/2, 220, [100,120] |
| grounded heavy > neutral, 100 meter | 2/2, 180, [85,95] | 2/2, 205, [100,105] |
| air juggle: light chain x4 (hits) | 1/5 | 1/5 |

**Launcher measurements (this PR).** With the owner-decided launcher category
implemented, the same probe reports (`LAUNCHERS` section):

| Fighter | Row | kb(x,y) | Launched | Airtime (frames) | Peak (px) | Airborne hits | Per-hit scale | Max juggle | Cap rejected | Block advantage |
|---|---|---|---|---|---|---|---|---|---|---|
| Peggy | fwd special | (130, 228) | yes | 46 | 27.0 | 1 | [1.00] | 1 | n/a | -11 |
| Peggy | fwd EX | (150, 360) | yes | 112 | 69.0 | 3 | [1.00, 1.00, 0.85] | 3 | yes | -8 |
| Richard | fwd special | (130, 200) | yes | 34 | 20.6 | 0 | [] | 0 | n/a | -11 |
| Richard | fwd EX | (160, 340) | yes | 76 | 61.4 | 2 | [1.00, 1.00] | 2 | no | -8 |

**Jump-in spacing sweep (PR B, informational; `air_probe.gd` "JUMP-IN SPACING
SWEEP").** Grid: horizontal gap 20-100 px (11 samples) x launch height 0/10/20/30
px, both starters (`jump_light`, `jump_heavy`), both build directions, both
follow-up mechanisms (mid-air `jump_light` cancel, and a light buffered around
landing that becomes the grounded light). The follow-up must CONNECT (damage),
not merely start.

| Fighter | Starter | Mode | Height 0 px | Height 10-30 px |
|---|---|---|---|---|
| Peggy | jump_light | chain | none | 20-44 px (`jump_light`) |
| Peggy | jump_light | buffer | 20-44 px (ground light) | 20-44 px (`jump_light`) |
| Peggy | jump_heavy | chain | none | 20-44 px (`jump_light`) |
| Peggy | jump_heavy | buffer | 20-36 px (ground light) | 20-44 px (`jump_light`) |
| Richard | jump_light | chain | none | 20-44 px at 10-20 px height; none at 30 px (starter misses) |
| Richard | jump_light | buffer | 20-44 px (ground light) | 20-44 px at 10-20 px; none at 30 px |
| Richard | jump_heavy | chain | none | 20-44 px (`jump_light`) |
| Richard | jump_heavy | buffer | 20-36 px (ground light) | 20-44 px (`jump_light`) |

The valid window is therefore **20-44 px horizontal gap at a 10-30 px launch
height** for the mid-air follow-up, and **20-44 px (Peggy) / 20-36 px (Richard
`jump_heavy`) at 0 px height** for the landing-buffer grounded light. This is
documented next to the generator's `jump_heavy` chain rule and enforced by the
corrected combat test at 20 px height / 28 px gap, which asserts the follow-up
hit connects for both starters and both fighters. Outside the window the
follow-up drops; widening it would need an owner decision (hitbox depth, active
window, or landing-recovery changes).

What these measurements show:

- **The launchers work as authored data.** Both fighters' forward specials and
  forward EX rows lift the defender off the floor; the COMBO ARCS `def-air`
  column now shows real airborne time on the forward-special routes (Peggy 57/38,
  Richard 55/34), where it was 0 before.
- **The cap is reachable and enforced on a real route for Peggy's EX.** The
  grounded follow-up (walk in, light > heavy > forward-special) lands three
  airborne hits, the third at the 85% step, and a further strike through the real
  hit path is rejected at the cap. Peggy's base launcher connects one airborne
  follow-up before landing.
- **Richard's base launcher does not connect a follow-up at 80%.** His 30-frame
  recovery plus walk speed consumes the ~34-frame base arc; the measured
  threshold for a Richard base follow-up is a taller launch (about 260 for one
  hit, 340 for the full three-hit route), which is outside the owner's "near
  80%" value. His EX launcher reaches two airborne hits. Making the cap
  reachable for Richard on his base launcher needs an owner decision (raise his
  base vertical, or change his recovery/air drift), not an unauthorised value
  change here.
- **Both launchers are punishable on block** (defender actionable 8-11 frames
  before the attacker; the block advantage is negative).
- **Scaling is measured, and the 85% third-hit step fires** in both the grounded
  chain and Peggy's EX juggle. The 55%-floor step is still not reached by any
  authored route.
- **The jump-in follow-up still does not connect at 28 px** (unchanged from PR 7;
  the spacing sweep is the next measurement, not a data change).

## 7. Grappling Expansion — proposal (Phase 3; direction approved, implementation pending)

### Scope and command-grab direction

Add one command grab for each current playable fighter, authored as a
`MoveData` throw-level special on an existing special direction. Recommended
mapping: **Richard forward + special** and **Peggy back + special**. This keeps
the shared input taxonomy; fighter identity is in data, not a fighter-specific
control scheme. Both grabs must work with the current silhouettes and no
animation dependency.

There is an important data-selection decision before authoring: Richard's
forward-special (`richard_forward`) and Peggy's back-special (`peggy_back`) rows
already exist. `FighterData.find_move()` returns the first matching input/stance,
so adding a duplicate row would be ambiguous and might make the command grab
unreachable. Owner approval must choose whether each existing move is replaced/
reclassified as the command grab, or another currently available special
direction is selected and its existing role resolved. Do not silently add a
duplicate input/stance row or change the controls. The generator must remain the
source of truth for whichever approved choice is made.

### Authored properties and counterplay

Each command-grab row should author:

| Property | Rule to record |
|---|---|
| Damage | Per-fighter damage; do not inherit normal-throw damage without a balance decision |
| Startup | Deliberately slower than the normal throw if untechable is selected, leaving a readable interruption/avoidance window |
| Active window | Explicit active simulation frames |
| Whiff recovery | Explicit and punishable; define whether the existing ordinary throw-whiff override applies or a command-grab-specific value is added |
| Hit level | `THROW`; unblockable by stand/crouch block as existing throws are |
| Knockdown | Explicit knockdown flag and resulting state/duration policy; must respect R1 against an already-knocked-down defender |
| Meter gain | Explicit hit/whiff/receive values using the existing meter economy; no implicit bonus |

> **Owner decision (2026-11-06, documentation only):** command grabs are
> **UNTECHABLE**, balanced by slow, punishable startup. The normal throw remains
> the techable mind-game layer. The existing throw-tech system is not extended to
> command grabs.

The design choice is **techable vs. untechable** (decided above: untechable):

- **Recommended: untechable command grabs with slower startup.** This is the
  traditional trade: sacrifice speed and give the defender time to interrupt,
  jump, or leave range in exchange for no throw-tech escape on contact.
- **Alternative: techable.** Use the existing normal-throw tech window
  (`throw_tech_window`, currently 7 frames) and lockout behavior unless the owner
  explicitly approves a distinct window. A buffered grab within the window
  breaks the command grab; a lockout button input prevents that tech, just as for
  normal throws.

Under the recommended untechable option, a buffered grab does not enter `TECH`
against the command grab and lockout does not convert its hit into a tech. This
does not make the move unavoidable: startup, spacing, jumping/airborne state,
and recovery remain counterplay. Existing normal throws remain techable and
their window/lockout must not change. Owner approval is required before either
techability policy is implemented.

### Existing-rule interactions

- **R1 — knockdown:** reject all throws, including command grabs, against a
  defender in `KNOCKDOWN`; command-grab data cannot opt out.
- **Wake-up throw invulnerability:** respect the current data-driven throw
  invulnerability window. A command grab must not bypass `is_invulnerable_to()`.
- **K1 — knockdown strikes:** this policy concerns strikes, not a command-grab
  loophole. A throw-level command grab remains rejected by R1 during knockdown;
  METH rows keep their separate explicit exception and global gate.
- **Airborne defenders:** retain the existing grounded-only throw rejection;
  command grabs whiff on airborne defenders and a brush must not consume the
  active window if that is the shared ordinary-throw rule.
- **EX meter:** no EX command grab is assumed in this proposal. If separately
  approved, it must be a normal EX data variant, use the existing EX input and
  authored meter cost (currently 50), and never become a free command-grab
  shortcut. Base command grabs must not spend EX meter.
- **METHtality gate:** command-grab damage/knockdown must not trigger or bypass
  the finisher. METH remains governed by full meter, health threshold,
  hitstun/knockdown state, and invulnerability; the current global kill-confirm
  path is preserved. Do not make command-grab contact an alternate METH gate.
- Throws remain unblockable because they are `THROW`, not because command grabs
  get a special block exception.

### Explicitly deferred

- Air grabs.
- Multi-throw variants, follow-up trees, and command-grab EX variants.
- Grappler-archetype kits for the wider roster; that is Phase 5 design/content
  work, not this Peggy/Richard Phase 3 proposal.
- Animation and art wiring; silhouette playability is the acceptance baseline.

### Tests and exit criteria

- Each approved row resolves as a throw-level `MoveData` and connects against a
  grounded, vulnerable defender; holding stand or crouch block does not block it.
- It whiffs against an airborne defender under the existing rule, without
  consuming the active window where the common throw resolver preserves that
  behavior; wake-up throw invulnerability still rejects it.
- R1 rejects the command grab against `KNOCKDOWN`; K1 does not accidentally
  reinterpret a throw as a strike, and the METH exception/gate remain unchanged.
- Techable option: tech inside/outside the selected window, lockout, both-fighter
  `TECH`, and no damage. Untechable option: grab input does not tech it, no
  `TECH` state is entered, and normal throws still tech exactly as before.
- Whiff recovery is punishable and authored; damage, knockdown, and meter gains
  match the selected rows. EX meter is unchanged unless a separate variant is
  approved.
- Peggy and Richard each have one unambiguous command-grab row in
  `gen_fighter_data.gd`; regenerate resources and verify rows and approved
  properties persist. No duplicate input/stance lookup ambiguity.
- Existing throw tech, airborne rejection, wake-up invulnerability, combo,
  METHtality, combat, and round-flow tests remain green.

**Dependencies:** owner decision on direction-slot replacement/alternative and
techability, plus approved per-grab values. This proposal does not authorize code
or resource changes. Roll back the two authored rows independently if they
regress ordinary throw behavior; never remove or alter the shared normal-throw
rules as a shortcut.

**Implementation status (PR 6, implemented):** owner-approved selection is
**forward + grab**, not the replaced back/forward special slots. Each fighter
keeps all five normal specials and the normal throw. Pressing grab with the
forward direction held (`_axis * facing > 0`) starts the authored
`COMMAND_GRAB` row (`MoveData.InputType.COMMAND_GRAB`, `THROW` level); a neutral
or back-held grab press starts the techable normal throw as before. Tech stays
direction-blind: any grab buffer still techs an incoming throw, and the command
grab is skipped by the tech check (`receive_hit()`), making it UNTECHABLE.
Values (owner first pass): Peggy 120 damage, 14f startup, 3f active, 24f whiff
recovery (`MoveData.whiff_recovery`, row-only override); Richard 140 damage,
16f startup, 3f active, 26f whiff recovery. Both: meter 6/8 on hit, 1.5 on
whiff, 4 received; 30f knockdown (intentional: bigger damage and shorter
okizeme than the 42f normal-throw knockdown); THROW level, unblockable, no EX
variant. R1, wake-up throw invulnerability, and airborne rejection are shared
guards and still apply. Informational metric (not asserted): reward versus
the defender's best single-hit punish is 0.80 for Peggy (120/150) and 0.97 for
Richard (140/145).

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
