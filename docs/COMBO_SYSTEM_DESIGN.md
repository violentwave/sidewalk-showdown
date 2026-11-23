# Combo System Design — Sidewalk Showdown

**Version:** v0.3 — **Phases 1–4 implemented** (Phase 1 merged 2026-11-19;
Phase 4 HUD completed on `feat/combo-hud`, 2026-11-22)
**Status:** Phases 1–3 and both Phase 4 halves (combo HUD and CPU usage)
are shipped. The HUD is presentation-only and reads the existing tracker,
fighter state, and signals.
**Goal:** A Mortal Kombat-style combo system, made our own: dial-a-combo
macros, chain strings into specials, launchers and juggles, and themed
stuns — deterministic, data-driven, rollback/replay-ready, on the fixed
60 Hz sim.

**What Phase 1 changed in the engine (implemented vs designed):**
- BLOCK and WHIFF cancel conditions are live: the resolver reports
  `move_was_blocked` / `move_whiffed` on the attacker, `validate()`
  accepts both, and `_try_outcome_cancel()` evaluates them through the
  same starters as hit-confirm routes.
- `ComboTuning` (resources/combat/combo_tuning_default.tres) replaces the
  hardcoded ladder with the approved numbers as data; `ComboTracker`
  lives per defender, serializes with the fighter, and feeds scaling,
  repeat penalty, variety bonus, caps, and meter-in-combo.
- Clip Cancel (special+grab during recovery, 25 meter, once per combo) is
  implemented as designed.
- Macros: `MacroData` resources + a dial-ahead ring in FighterBase that
  replays held steps into the buffer after hit-confirms; dies on block,
  whiff, move end, or dial gap. BENCH WARMER / LAST CALL authored.
- Authored edges: Peggy light BLOCK chain + BLOCK special-cancel, Peggy
  heavy COUNTER_HIT EX, Richard heavy BLOCK special-cancel, Richard
  crouch_heavy COUNTER_HIT special.
- Not yet (per the phase plan): juggle points (flat cap still rules),
  stuns, breaker, combo HUD, CPU combo usage.

This doc has two halves: an audit of what the combat core does today
(§§1–7), and the design built on top of it (§§8–13). Everything proposed
reuses the engine's existing validation-first philosophy: no combo rule may
let a player do something the move data does not author.

---

# PART A — AUDIT: HOW COMBAT WORKS TODAY

## 1. Frame data and the fixed simulation

- Fixed 60 Hz. `FighterBase._physics_process` advances one state frame per
  tick; movement integrates via `delta_fixed() = 1/Engine.physics_ticks_per_second`
  (60). Hitstop freezes the whole exchange and does not burn the round clock
  (`MatchRoot` returns before `timer_frames -= 1`).
- One `MoveData` row is one attack. Fields: `id`, `input`
  (LIGHT/HEAVY/SPECIAL_{NEUTRAL,FWD,DOWN,BACK,AIR}/GRAB/COMMAND_GRAB),
  `stance` (STAND/CROUCH/AIR), `level` (MID/LOW/OVERHEAD/THROW), timing
  (`startup`/`active`/`recovery`), damage `damage` / `block_damage` (chip),
  `hitstun`/`blockstun`, `knockback` (x, and **positive y = launcher**, pure
  data), `knockdown`, `block_pushback` (parity 45 px/s), meter gains
  (`meter_gain_hit` 6 / `_block` 3 / `_whiff` 1.5 / `_receive` 4 — see §6
  for what is actually awarded), hitbox `hitbox_offset`/`hitbox_size`
  relative to feet along facing, `hitstop`, `landing_recovery`,
  invulnerability (`invuln_kind`/`invuln_start`/`invuln_end`), EX fields
  (`meter_cost`, `ex`), `whiff_recovery` (throws), and `cancels`.

## 2. Input path, buffer, and "motion detection"

- Inputs are per-player Godot actions `p<index>_<action>`:
  left/right/up/down/light/heavy/special/grab/meth. `_poll_input` records
  `just_pressed` button events into `input_buffer` with per-frame aging;
  windows: normal 5, special 7, grab and meth have their own. Held
  directions are read continuously; `up` is buffered like a button.
- There are **no motion inputs** (no quarter-circles): a "special" is
  direction+button resolved at consume time by `_special_input()` — air
  special if airborne, down special if crouching, forward/back by held axis
  relative to facing, else neutral. This is ideal for macros: a string is a
  short sequence of single presses, nothing to gesture-recognize.
- Grab: forward-held grab = command grab (untechable), otherwise the
  techable normal throw. EX = special buffer + heavy **held**. METH =
  buffered meth with a full bar.
- `input_history` (60 entries) exists for tooling; no engine logic reads it.

## 3. State machine, hitstun, knockdown, airborne hits

`State`: IDLE, WALK_F/B, CROUCH, JUMP_START/RISE/FALL, LAND, ATTACK,
BLOCK_STAND, BLOCK_CROUCH, HITSTUN, BLOCKSTUN, KNOCKDOWN, WAKE_UP, TECH,
GRAB, KO, WIN.

- **No air-hitstun state.** An airborne hit reuses HITSTUN while ungrounded;
  gravity and `_landing_check` bring the defender down; landing from an
  attack/jump state goes to LAND (2 frames default, `landing_recovery`
  authored for whiffed air moves only).
- **Knockdown:** 30 frames, then WAKE_UP (`wakeup_frames` 12) with universal
  invulnerability 6 and throw invulnerability 8. KNOCKDOWN rejects strikes
  (METH is the exception) and throws.
- **Juggles exist today (PROPOSALS §6, implemented + Phase 2 economics):** a
  launcher is any move with `knockback.y > 0` and `knockdown = false`, now
  also marked `MoveData.launcher`. The flat 3-hit cap is replaced by the
  **point budget** (decision #5): a grounded launcher hit grants the
  defender 5 points (`ComboTuning.juggle_points_start`); each air hit
  spends by type (normals 2, air specials 3); a hit the remaining points
  cannot pay is REJECTED and stays live (meaty-safe, like the old cap).
  An airborne defender with no active budget (`juggle_points == -1`, e.g. a
  voluntary jump-in) gets the standard grant on its first air hit, so
  jump-ins stay hittable and every air sequence is bounded. Repeat
  airborne hits scale: horizontal knockback ×0.7 per prior air hit,
  gravity ×1.25 once `juggle_hits >= 2`, air hitstun ×0.9 per air hit
  (floor 8). A launcher used as a juggle hit refreshes the arc but drains
  the budget — no re-launch loops. The launcher itself is a grounded hit
  and does not count. The BREAKER HOOK (decision #9, Phase 3) sits at the
  budget-rejection branch in `is_invulnerable_to`/`receive_hit`.
- Counter-hits: defender in own startup and not a trade → +2 hitstop,
  HUD flash, `move_counter_hit` gates COUNTER_HIT cancel rules.

## 4. The authored cancel system (the seed of the combo graph)

`CancelRule` on each move's `cancels` array:
`target` (LIGHT/HEAVY/SPECIAL/EX), `kind` (CHAIN/CANCEL), `condition`
(HIT/COUNTER_HIT — **BLOCK and WHIFF are declared but rejected by
`validate()` "until the resolver reports them"**), `from_frame`/`to_frame`
(inclusive window from move start).

Evaluation (`_try_cancel`, only when `move_hit_confirmed`):
1. METH full-meter interrupt first.
2. Counter-pass rules in array order, then non-counter rules.
3. `_run_cancel` consumes the matching buffer entry, then starts the target
   through the normal starters — CHAIN must target a normal, CANCEL must
   target a special/EX. The EX route is the special+heavy command shape,
   meter spent only if the EX row exists and can pay; the base special is
   the documented fallback.

Current wiring (both fighters; windows shown are inclusive frames):

| Move | Cancels authored |
|---|---|
| light (stand) | CHAIN→light, CHAIN→heavy, CANCEL→special, all HIT [4..12]/[5..15] |
| crouch_light | CHAIN→light, CHAIN→heavy, CANCEL→special, HIT |
| heavy (stand) | CANCEL→special, CANCEL→EX, HIT (Peggy [8..25], Richard [10..29]) |
| crouch_heavy | CANCEL→special, CANCEL→EX, HIT |
| jump_light | CHAIN→light, CHAIN→heavy, CANCEL→special, HIT |
| jump_heavy | CANCEL→special, CANCEL→EX (+ CHAIN→light), HIT |
| all specials, EX, grabs, METH | **none — specials are hard combo enders today** |

So: light→light→heavy→special strings are already legal on hit. There is no
blocked-string continuation (BLOCK condition reserved), no whiff-cancel,
no cancel out of specials, and no data-driven per-string identity.

## 5. Combo counter and damage scaling

- `combo_hits` lives on the **defender**; reset after 40 frames without a
  hit, on block, on knockdown recovery paths, and at round start. HUD shows
  "N HITS" for the attacker at ≥2.
- `_damage_scale()` is a hardcoded ladder on the hit count (1-indexed):
  hits 1–2 ×1.0, 3 ×0.85, 4 ×0.70, 5+ ×0.55. No repeat-move penalty, no
  variety bonus, not data-editable, and it does not touch meter.

## 6. Meter rules (landed-hits-only economy)

- The **only** award is `meter_gain_hit` (6.0 default) to the attacker on a
  landed hit — throws included. Blocked pays `meter_gain_block ×
  METER_GAIN_ON_BLOCK_SCALE` (0.0). Whiffs pay nothing (`meter_gain_whiff`
  is authored but never awarded). The defender never gains. `max_meter` 100.
- Spenders: EX rows cost 50 (special+heavy shape, per-move `meter_cost`);
  METH drains the bar fully. There is no other meter sink today — the
  Clip Cancel (§10.3) and breaker (§11) become the first defensive/utility
  sinks.

## 7. Throws, sides, corners, CPU, serialization

- Throws: 5f grab, tech window 7f from the defender's buffered grab (a grab
  of your own in startup also techs; any other button in the window kills
  the tech), tech pushes both apart 20 px for 10 frames. Command grabs
  (Peggy 14/3/24 whiff 24; Richard 16/3/26 whiff 26) are untechable,
  in-front-only (`is_in_front_of`), with authored whiff recovery.
- Side rules: `relative_side()`, `direction_away_from()`, `is_in_front_of()`
  decide block direction, knockback, pushback, and throw reach — position-
  based, correct under pass-through (default on) and cross-ups. Corner rule:
  blocked pushback the pinned defender cannot take transfers to the
  attacker.
- CPU (`game/scripts/ai/`): caches each fighter's light/heavy/special/
  grab/command/METH rows and their reaches at setup; feeds the same input
  path; its "combos" today are a `combo_rate` chance to offer a buffered
  light after its own hit-confirm — which only lands if an authored cancel
  rule allows it. It has no notion of strings, launchers, or stuns.
- Serialization: `MatchRoot.serialize()` captures match flow + both
  fighters (state, timers, buffers, combo/juggle counters) + CPU state
  (see `docs/SAVESTATE_PLAN.md`). Any new combo state must join these
  dictionaries and be frame-counted only — no clocks, no RNG beyond the
  CPU's seeded LCG.

## 8. Full move inventory (audited 2026-11-19)

Peggy (`peg_leg_peggy.tres`, walk 95/72, jump 285, wakeup 12, tech window 7,
throw whiff 22; METH "Walk the Plank" 3/2/24, dmg 1000, hitstop 30):

| Move | Role | S/A/R | Dmg (chip) | Hitstun/Blockstun | Knockback | Notes |
|---|---|---|---|---|---|---|
| light | normal | 3/2/7 | 35 (2) | 13/8 | 55, 0 | chains + special cancel |
| heavy | normal | 7/3/15 | 85 (5) | 18/12 | 90, 0 | special/EX cancel |
| crouch_light | normal (low) | 4/2/9 | 30 (2) | 12/8 | 45, 0 | chains + special cancel |
| crouch_heavy | normal (low) | 8/3/18 | 75 (4) | 16/12 | 70, 0 | special/EX cancel |
| jump_light | normal (OH) | 4/3/10 | 40 (3) | 14/9 | 50, 0 | landing rec 8 |
| jump_heavy | normal (OH) | 7/3/13 | 80 (5) | 18/11 | 80, 0 | landing rec 8 |
| peggy_neutral | special | 9/3/19 | 95 (6) | 20/13 | 110, 0 | **Peg-Lock stun** (Phase 3, 60f immunity) |
| **peggy_forward** | special | 11/4/22 | 110 (7) | 22/14 | 130, **274** | **launcher already** (raised 228→274, Phase 3) |
| peggy_down | special (low) | 10/3/20 | 90 (6) | 18/12 | 80, 0 | — |
| peggy_back | special | 8/3/18 | 85 (5) | 18/12 | 60, 0 | — |
| peggy_air | air special (OH) | 12/2/16 | 70 (5) | 18/12 | 90, 0 | landing rec 12 |
| grab | throw | 5/2/16 | 95 | tech window 7 | 100, 0 | techable |
| peggy_neutral_ex | EX | 7/3/17 | 120 (7) | 22/14 | 120, 0 | cost 50 |
| **peggy_forward_ex** | EX | 9/4/20 | 145 (9) | 24/15 | 150, **360** | **launcher, cost 50** |
| peggy_command_grab | command grab | 14/3/24 | 120 | untechable | 100, 0 | whiff rec 24 |
| peggy_meth | METHtality | 3/2/24 | 1000 | — | — | full-bar drain |

Richard (`whiskey_richard.tres`, same locomotion; METH "Flaming Belch"
3/2/24, dmg 1000, hitstop 30):

| Move | Role | S/A/R | Dmg (chip) | Hitstun/Blockstun | Knockback | Notes |
|---|---|---|---|---|---|---|
| light | normal | 4/2/9 | 45 (2) | 13/8 | 55, 0 | chains + special cancel |
| heavy | normal | 9/3/17 | 100 (5) | 18/12 | 90, 0 | special/EX cancel |
| crouch_light | normal (low) | 5/2/10 | 35 (2) | 12/8 | 45, 0 | chains + special cancel |
| crouch_heavy | normal (low) | 10/3/19 | 90 (5) | 16/12 | 70, 0 | special/EX cancel |
| jump_light | normal (OH) | 4/3/10 | 45 (3) | 14/9 | 50, 0 | landing rec 8 |
| jump_heavy | normal (OH) | 7/3/13 | 90 (5) | 18/11 | 80, 0 | + CHAIN→light |
| richard_neutral | special | 9/3/19 | **40** (6) | 20/13 | 110, 0 | **Taser Belch stun** (Phase 3, 105→40, 240f immunity) |
| **richard_forward** | special | 11/4/22 | 120 (7) | 22/14 | 130, **260** | **launcher already** |
| richard_down | special (low) | 10/3/20 | 95 (6) | 18/12 | 80, 0 | — |
| richard_back | special | 8/3/18 | 100 (5) | 18/12 | 60, 0 | — |
| richard_air | air special (OH) | 12/2/16 | 60 (5) | 18/12 | 90, 0 | landing rec 12 |
| grab | throw | 5/2/16 | 105 | tech window 7 | 100, 0 | techable |
| richard_neutral_ex | EX | 7/4/17 | 135 (8) | 24/14 | 120, 0 | cost 50 |
| **richard_forward_ex** | EX | 9/4/20 | 150 (9) | 26/15 | 160, **340** | **launcher, cost 50** |
| richard_command_grab | command grab | 16/3/26 | 140 | untechable | 100, 0 | whiff rec 26 |
| richard_meth | METHtality | 3/2/24 | 1000 | — | — | full-bar drain |

Cancel relationships today, as a graph: every light (stand/crouch/air)
chains into light/heavy and cancels into special; every heavy (stand/
crouch/air) cancels into special and EX (Richard's crouch_heavy has no
chain; his jump_heavy additionally chains light). **Nothing cancels out of
a special, throw, or METH.** Both fighters' forward specials are already
authored launchers.

---

# PART B — DESIGN

## 9. Data model (all `.tres`-editable)

### 9.1 Cancel graph = the existing `cancels` array, extended

The graph edge stays `CancelRule` on each `MoveData`, with the reserved
conditions unlocked and two new pieces of metadata:

```gdscript
# CancelRule gains:
@export var condition: Condition   # HIT, COUNTER_HIT, BLOCK, WHIFF (unlocked)
@export var meter_cost: float      # 0 for free routes; >0 = meter-burn route
@export var tag: StringName        # "" | "launcher" | "clip" | "string_end"
```

- **BLOCK** edges enable blockstrings (pressure that continues on block);
  the resolver already knows the outcome (`move_hit_confirmed` false +
  defender BLOCKSTUN) — it must record blocked contacts the way it records
  hits.
- **WHIFF** edges stay rare by policy (validation currently refuses them);
  they are the hook for punk-cancel-style routes later, not Phase 1.
- `tag` is metadata for tooling, the HUD, and the CPU — the engine itself
  keeps evaluating only target/kind/condition/window/meter_cost.
- Authoring stays in each fighter's `.tres`; no new graph file format, no
  engine rewrite. `validate()` flips BLOCK from "reserved" to "legal",
  keeps WHIFF behind an explicit owner opt-in.

### 9.2 Macro / string resources

```gdscript
# MacroData — one dial-a-combo. Added to FighterData as macros: Array[MacroData].
class_name MacroData extends Resource
@export var id: StringName
@export var display_name: String
# Steps the player dials (single presses, order matters):
@export var steps: Array[StringName]        # ["light","light","heavy"]
@export var max_gap_frames: int = 18       # dial-ahead cadence between presses
# The move each step must resolve into, and the cancel window it rides:
@export var route: Array[MacroRoute]        # step -> MoveData id (existing rows)
@export var on_block: bool = false         # default: macros die on block
```

A macro does **not** bypass validation: each step resolves through the
authored CHAIN/CANCEL edges of the current move. The macro tracker only
*stores and replays* the presses at the right cadence. If a hit does not
connect, the chain's HIT condition fails and the macro dies (§10.1).

### 9.3 Combo scaling, juggle, and stun parameters

```gdscript
# ComboTuning — one resource per fighter (FighterData.combo_tuning), with
# shared defaults authored once in a base .tres so both fighters stay in sync.
# IMPLEMENTED (Phase 1 + Phase 2) — see game/scripts/combat/combo_tuning.gd.
class_name ComboTuning extends Resource
# Scaling ladder (replaces the hardcoded _damage_scale()); the last entry
# is the floor for every later hit (there is no separate scaling_floor).
@export var scaling_curve: Array[float] = [1.0, 1.0, 0.85, 0.70, 0.55]
@export var repeat_penalty: float = 0.9      # per repeat of the same move id
@export var repeat_freebies: int = 1        # first reuse is free
@export var variety_bonus: float = 0.05      # last 3 move ids all distinct
@export var meter_gain_in_combo: float = 0.5 # multiply meter_gain_hit
@export var meter_gain_floor: float = 0.25
@export var combo_hit_cap: int = 12         # hard per-combo hit cap
@export var combo_damage_cap: float = 550.0 # hard per-combo damage cap
# Juggle economics (replaces the flat JUGGLE_HIT_CAP), IMPLEMENTED Phase 2:
@export var juggle_points_start: int = 5    # granted by a grounded launch
@export var juggle_cost_normal: int = 2     # any air hit except specials
@export var juggle_cost_air_special: int = 3
@export var air_hitstun_decay: float = 0.9  # per air hit, floored at 8f
# NOTE: no regen and no per-point gravity field shipped — points never
# regen mid-combo, and the gravity ramp is the Phase 1-era constant
# JUGGLE_GRAVITY_MULT (x1.25 from the second air hit), unchanged.
```

```gdscript
# StunEffect — subresource on a MoveData (MoveData.stun: StunEffect).
class_name StunEffect extends Resource
@export var id: StringName                  # "freeze", "taser", "belch_daze"
@export var display_name: String
@export var duration_frames: int = 45
@export var shake_input: StringName = "up"  # mash direction to shorten
@export var shake_frames_per_press: int = 3
@export var minimum_frames: int = 20        # cannot shake out before this
@export var immunity_frames: int = 240      # after the stun ends (4 s)
@export var once_per_combo: bool = true
@export var launcher_safe: bool = false     # can it stun an airborne target?
```

### 9.4 Breaker data

```gdscript
# FighterData gains:
@export var breaker_free_per_round: int = 1
@export var breaker_meter_cost: float = 40.0
@export var breaker_cooldown_frames: int = 300   # 5 s between breakers
@export var breaker_input: Array[StringName] = ["grab", "special"]  # pressed together
```

### 9.5 New serializable state (determinism)

All of it frame-counted, per fighter, joined to `FighterBase.serialize()`:

- **Combo tracker** (on the defender — where `combo_hits` already lives):
  move-id history ring (last 3 for the variety bonus + repeat counts), combo
  damage accumulated, hits counted against the cap, juggle points remaining,
  juggle points spent (gravity ramp), air hits taken (for hitstun decay).
- **Macro tracker** (on the attacker): current macro id, step index, frames
  since last dial press, stored ahead-presses (a small ring of
  {action, age}).
- **Stun state** (on the defender): active stun id, frames remaining,
  shake presses counted, immunity frames remaining, stuns-taken-this-combo.
- **Breaker state** (on the defender): free uses left this round, cooldown
  frames remaining, times used this combo.
- **Clip Cancel state** (on the attacker): uses left this combo.

No wall-clock, no engine RNG. The CPU continues to read only resolved
state, so none of this changes its determinism contract; the save/restore
test in `cpu_test.gd` extends to cover the new fields.

## 10. The four components

### 10.1 Dial-a-combos ("macros") — made ours

MK macros are memorized button strings. Ours:

- **A macro is a stored dial-ahead.** Press `L, L, H` quickly (within
  `max_gap_frames` between presses) and the tracker replays each press into
  the buffer exactly when the current move's cancel window opens. The player
  is always *ahead* of the animation, MK-style.
- **Macros continue only while hits connect.** Each step rides an authored
  HIT-condition edge. Block the first hit and the macro dies (unless the
  string's author explicitly adds a BLOCK edge — `on_block` defaults
  false). Whiff the first hit and nothing comes out at all.
- **Macros are character-specific identity, not hidden power**: each fighter
  ships 2 (one bread-and-butter, one corner/launcher route). The HUD shows
  the macro's `display_name` while it runs — flavor ("BENCH WARMER") rather
  than a moves-list secret.
- Anti-infinite: a macro's steps are ordinary moves, so the scaling ladder,
  repeat penalties, and hit cap all apply; a macro may not target itself.

### 10.2 Strings and cancels

- Phase 1 formalizes what the audit found: light chains and special/EX
  cancels already exist. New authored content: one 3–4 hit **blockstring**
  per fighter using a BLOCK edge (e.g. Peggy `L → cr.L → peggy_neutral`,
  where the special is -6 on block, safe pressure), and one
  counter-hit-only extension per fighter (COUNTER_HIT edge: punish reward).
- **Specials stop being dead ends on hit:** each fighter gets one authored
  CANCEL edge off their neutral special into their forward special (the
  launcher), HIT-condition, so `L, L, H → neutral → forward-launch` is a
  real 5-hit route into a juggle. This is the bridge between components 2
  and 3.

### 10.3 Clip Cancel (meter-burn cancel) — ours instead of MK's run cancel

- During your own move's **recovery only** (never active frames — no
  mid-move invincible dashes), spend **25 meter** to cancel to neutral.
  Uses the clip-art identity: a comic-panel "clip" flash over the fighter
  (reuse existing halftone/VFX assets from The Clip intro).
- One per combo. Serves both extension (recovery-cancel into a jump or a
  launcher attempt) and safety (make a blocked heavy actually safe).
- It is the first utility meter sink, which matters because the economy is
  landed-hits-only: meter currently only buys EX and METH.
- **Refusal rule (owner ruling 2026-11-22, adversarial A3):** a Clip
  Cancel refused for lack of meter CONSUMES the buffered grab+special
  pair. Left buffered, a punished attempt would auto-convert into the
  defender's (free) breaker on its first hitstun frame — the
  safe-cancel/break option-select is ruled out. With meter the cancel
  resolves exactly as before.

### 10.4 Launchers and juggles

- The audit found launchers already authored (forward specials and EX).
  The design keeps them pure data and adds economics: the defender's
  tracker starts each combo with `juggle_points_start` (5). Launcher costs
  nothing (it *grants* the state), each air normal costs 2, air specials 3;
  points do not regen mid-combo. This replaces the flat 3-hit cap with
  readable budgeting: a pure air-special juggle gets one, air-normal
  juggles get two, and the EX launcher's higher arc buys a richer route.
- **Air hitstun decays** ×0.9 per air hit (floor 8f) so late juggle hits
  cannot re-launch loops; **gravity ramps** ×1.25 from the second air hit
  (the Phase 1-era `JUGGLE_GRAVITY_MULT`, unchanged) and repeat-hit
  horizontal knockback decays ×0.7, so the arc visibly dies instead of a
  cap silently rejecting the next hit.
- Landing from a juggle keeps the existing LAND state; a defender who
  lands mid-combo keeps the combo alive for 40 frames (existing
  `frames_since_hit` rule) — no new okizeme rules needed for Phase 2.
  Phase 2 correction: the 40-frame window is now gated on **landing** —
  it cannot expire while the defender is still airborne (hitstun ending
  mid-air used to reset scaling and re-open a fresh unscaled jump-in);
  the tracker covers the whole air combo.
- **Implemented (2026-11-21):** the budget, the `MoveData.launcher` data
  flag, the authored §13 routes, and the neutral→forward launcher-string
  cancel edges are all live; measured route data is in §15.1. A breaker
  hook (decision #9) is placed at the budget-rejection branch for Phase 3.

### 10.5 Stuns (freeze, taser, and friends)

- One themed stun per fighter, **reusing an existing special with no new
  fighter animation**:
  - **Peggy — "Peg-Lock"** (freeze): `peggy_neutral`, HIT-condition, adds a
    `StunEffect` (45f). Ice-tint silhouette flash reuses the existing
    hit-flash tinting; new impact spark only.
  - **Richard — "Taser Belch"**: `richard_neutral` becomes the stun
    (damage reduced 105→40, the lost damage is the price of the window);
    crackle spark VFX, bottle-shake readback on the existing clip.
- **Fairness rails:** shake-out mashing shortens the stun (3f per press
  after the 20f minimum); post-stun immunity 4 s; once per combo; cannot
  stun an airborne target (`launcher_safe` false — no stun-into-juggle
  loops); the stun **does not itself build meter** for the attacker and its
  followup string starts at scaling step 3 (the stun is a window, not free
  damage).
- In-combo limit: a stunned defender's combo tracker does not reset during
  the stun, so anything inserted into the window pays the full scaling
  ladder, repeat penalties included.
- **Intended quirk (owner ruling 2026-11-22, adversarial A4):** a stun
  attempt that CONNECTS during post-stun immunity still records its move
  id, so a second attempt in the SAME combo is once-per-combo rejected
  even after immunity expires mid-combo. Accepted as-is: the shortest
  immunity (60f) outlives the combo window, so the budget refreshes with
  the next combo.

## 11. Combo breaker

The defender problem: meter builds only from landed hits, and a comboed
defender often has **zero** meter by construction.

| Option | Pros | Cons |
|---|---|---|
| A. Free once per round + extra breaks cost 40 meter | Always available when it matters; meter stays offensive-first; simple to read | A free resource must be tuned (cooldown) or it flattens pressure |
| B. Meter-cost-only | Pure economy symmetry | Deepens the rich-get-richer problem the landed-hits economy already has |
| C. No breaker, stricter scaling | Least code; scaling does the work | Long true strings feel uninteractive; CPU HARD becomes a blender |

**Recommendation: A.** One free breaker per round (input: grab+special
together during hitstun/juggle, not during blockstun — blocking is already
your defense there), then 40 meter each, 5 s cooldown, once per combo. On
break: both fighters pushed apart 30 px via the existing tech-separation
code path, attacker's combo dies, defender gets 20f of throw-style
invulnerability (reuse the wake-up invuln mechanism — no new invuln
system). The free use gives every player one honest "no" per round; the
meter cost keeps break-spam from replacing blocking.

**Input rule (owner ruling 2026-11-22, adversarial A2):** the breaker pair
persists through HITSTOP, like the tech window — a single grab+special
press on the impact frame of a long-hitstop hit (the EX launchers' 10f;
the METHtality's 30f is a knockdown, so it stays unbreakable by the
"otherwise legal" qualifier) still fires the breaker once hitstop ends.
Implemented as the serialized `breaker_pair_frames` latch: frozen by
hitstop like the stun counters, expiring with the breaker's own input
window once hitstop serves, consumed with the pair on a break or a
refused Clip Cancel — it can never fire twice or ghost past the window.
The 5-frame hitstop buffer freeze is unchanged for every other input.

**Meter gain inside combos (related):** keep `meter_gain_hit` but multiply
by 0.5 inside an active combo, floor 0.25 — so long combos still trend
toward the next EX but don't refund their own breaker mid-loop. The
*defender* still earns nothing; the breaker's free tier is the answer to
that, not defender meter.

**Interaction with pass-through / side-switching / cross-ups:** all
knockback, pushback, breaker separation, and stun shake-out use
`direction_away_from()`/`relative_side()`, so a combo that crosses over
mid-juggle resolves correctly on both sides of the defender. Breakers push
the defender *away from the attacker's current side* — no stale-facing
launch bugs, the same rule the cross-up blocking tests already pin.

## 12. CPU opponent impact

The AI reads data, never strings of code:

- **IMPLEMENTED (2026-11-22, Phase 4's CPU half).** `cpu_controller.gd`
  walks the authored `cancels` of its current move after a hit-confirm
  (replacing the blunt `combo_rate` light offer): on each confirm it picks a
  window-open rule matching the outcome (HIT/BLOCK/COUNTER_HIT) at
  `string_rate`, up to `route_depth` steps per combo, with a random choice
  among eligible edges for variety. SPECIAL targets dial the flavor —
  forward-held launcher (`launcher_rate`) or the neutral stun
  (`stun_rate`, stun-then-string); a declined offer presses nothing.
  Launcher usage arms the JUGGLE plan on a confirmed launcher: jump toward
  on the actionable frame, press the authored air normals while the
  defender's point budget can pay. Clip Cancel usage: a blocked move with
  meter resolves via the 25-meter recovery cancel
  (`clip_cancel_rate`) or an authored BLOCK-condition blockstring.
  Defense: the breaker attempt arms on hitstun entry behind the fairness
  reaction delay and rolls `breaker_rate`, gated by `breaker_ready()` and a
  worth-it rule (free always; meter only at low health, cornered, or a 60+
  damage combo); stun shake-out mashes the authored direction past the
  authored minimum (`shake_rate`); juggle-fall drift holds away from the
  attacker. Preblock already handled blockstrings.
- All of this is observable-state decisions with the existing seeded LCG —
  the determinism and save/restore tests extend unchanged (mid-combo,
  mid-stun, mid-break restores are pinned in `cpu_test.gd`). New
  `CpuDifficulty` knobs: `string_rate`, `route_depth`, `launcher_rate`,
  `stun_rate`, `juggle_rate`, `breaker_rate`, `clip_cancel_rate`,
  `shake_rate` — EASY low, HARD high, tuned in the existing `cpu_*.tres`
  (full table in `docs/CPU_OPPONENT.md`).
- Also shipped with this phase: the A1 fix from the adversarial pass — the
  breaker's once-per-combo rail now clears with each fresh combo opening,
  which is what makes the decision #1 meter extras (and this CPU's paid
  breaks) reachable at all.

## 13. Move list proposal

**Peggy** (rushdown trickster):

| Route | Moves | New? |
|---|---|---|
| Macro 1 "BENCH WARMER" | L → L → H → peggy_neutral | none (existing clips) |
| Macro 2 "PEG LEG SWEEP-IN" | cr.L → cr.H → peggy_down | none |
| Launcher string | L → H → peggy_neutral → (cancel, new edge) → peggy_forward launch | none |
| Launcher | peggy_forward (existing), peggy_forward_ex | none |
| Stun | peggy_neutral gains Peg-Lock StunEffect | impact spark only, no new animation |
| Juggle route | launch → jump_light (2 pts) → jump_heavy (2 pts) → land | none |
| Breaker/Clip Cancel | universal | clip flash VFX from The Clip assets |

**Richard** (counterpuncher):

| Route | Moves | New? |
|---|---|---|
| Macro 1 "LAST CALL" | L → L → H → richard_neutral (stun) | none |
| Macro 2 "STOOL Pigeon" | cr.L → cr.H → richard_down | none |
| Launcher string | H → richard_neutral → (new edge) → richard_forward launch | none |
| Launcher | richard_forward (existing), richard_forward_ex | none |
| Stun | richard_neutral becomes Taser Belch (dmg 105→40 + stun) | crackle spark only |
| Juggle route | launch → jump_heavy (2) → richard_air (3) | none |
| Breaker/Clip Cancel | universal | as above |

**New-move scoreboard: zero new fighter animations required.** New art is
limited to impact/VFX sparks (freeze tint, taser crackle, clip flash) and
HUD labels. If the owner later wants a dedicated anti-air launcher normal
per fighter (e.g. Peggy up-kick reusing jump_heavy's clip, Richard
uppercut reusing crouch_heavy's clip), those are flagged **clip-reuse,
2–3 new frames each** — proposed for Phase 2 backlog, not required.

**Phase 2 status (2026-11-21):** the launcher strings, launchers, and
juggle routes above are implemented and measured (§15.1); stuns, the
breaker, and the anti-air normals remain Phases 3/backlog. No new art was
needed for Phase 2.

## 14. Phase plan (each phase ships alone)

**Phase 1 — Cancel graph, strings, macros, scaling, tracker** (engine +
data):
- Unlock BLOCK conditions; author blockstrings + counter extensions; the
  neutral→forward special edges; `ComboTuning` resource replacing
  `_damage_scale()`; macro tracker + the four macros; Clip Cancel.
- Tests: scaling ladder/repeat/variety unit checks; macro continues on hit,
  dies on block/whiff; blockstring stays safe; Clip Cancel legality
  (recovery-only, meter pays, once per combo); serialization round-trip of
  the new tracker state; determinism hash suite extended.
- Shippable alone: strings and macros are immediately playable.

**Phase 2 — Launchers and juggles** (IMPLEMENTED 2026-11-21, see §15.1):
- Juggle points replace the flat cap; gravity ramp and air-hitstun decay
  unchanged; juggle routes authored (both fighters' forward/EX rows carry
  `launcher = true`; both neutral specials carry the launcher-string
  cancel edge); clip-reuse anti-air normals stay backlog (decision #10).
- Tests shipped: point budget granted/spent per hit type and rejected
  meaty-safe; no re-launch re-grant; decay and gravity ramp unchanged;
  authored routes priced exactly (both fighters, base + EX) with landing
  checks; seeded juggle fuzz over every launcher, both characters, both
  sides, both stages, pass-through on; determinism hash and mid-juggle
  MatchRoot serialize/restore; CPU soak re-measured (matches still end,
  worst 13928 frames, no stalls).

**Phase 3 — Stuns and breaker**:
- StunEffect on the two neutral specials; STUN behavior via a flag on
  HITSTUN (no new state machine state — the stun is hitstun with a data
  duration, shake-out, and immunity tag); breaker (recommended option A).
- Tests: stun duration/shake floor/immunity/once-per-combo; stun-into-
  juggle rejected while `launcher_safe` false; breaker input legality
  (not in blockstun), free-tier accounting, cooldown, separation and
  invuln reuse, CPU breaker determinism.

**Phase 4 — Combo HUD and CPU usage (IMPLEMENTED)**:
- HUD: attacker-side combo count/damage, base-ladder tint and gated scale
  tag, macro name flash, juggle-point pips, stun label/bar, breaker-ready
  pip, and BREAK!/CLIP CANCEL callouts. These read the existing tracker
  signals and public fighter state; see §15.3.
- CPU: §12 knobs wired into `cpu_*.tres`; soak re-run at HARD; difficulty
  ordering re-verified (HARD strings better than EASY).
- Tests: `hud_test.gd` (82 checks) and `ui_typography_test.gd` (46 checks)
  pin the HUD; CPU legality is unchanged and the soak remains covered.

## 15. Open decisions — RESOLVED (owner-approved 2026-11-20)

All eleven decisions are confirmed as follows; the defaults below are now
the spec of record for implementation. Phase 1 (this repo state) implements
the cancel graph, macros, data-driven scaling, and the combo tracker.

| # | Decision | Approved choice |
|---|---|---|
| 1 | Breaker model | **Free once per round + 40-meter extras, 5 s cooldown** (Phase 3) |
| 2 | Meter in combos | **×0.5, floored at 0.25** (implemented Phase 1) |
| 3 | Macro on block | **Dies** — macros continue only while hits connect (implemented Phase 1) |
| 4 | Scaling curve | **Keep 1.0/1.0/0.85/0.70/0.55**, retune after Phase 2 balance data (implemented Phase 1 as data) |
| 5 | Juggle budget | **Points: 5 start, normals 2, air specials 3** (implemented Phase 2) |
| 6 | Stun on airborne | **Never** — `launcher_safe = false` at schema level (Phase 3) |
| 7 | Stun damage | **Reduced** — Richard's stun special 105 → 40 (Phase 3) |
| 8 | Clip Cancel | **25 meter, recovery-only, once per combo** (implemented Phase 1) |
| 9 | Breaker during juggles | **Allowed, same input window** (Phase 3) |
| 10 | Anti-air launcher normals | **Backlog item**, not Phase 2 core |
| 11 | Doc home | **This doc is the umbrella**; PROPOSALS.md cross-referenced per phase |

### 15.1 Phase 2 implementation and balance data (2026-11-21)

**Implemented vs planned.** Shipped: the point budget in `ComboTuning`
(5 / 2 / 3), `MoveData.launcher` (pure data, both forward specials and
forward EX rows per fighter), the authored §13 routes, the
neutral→forward launcher-string cancel edges, `juggle_points`
serialization, the budget-rejection BREAKER HOOK, and the landing-gated
combo window (the tracker now covers the whole air combo). Not shipped
and not planned for Phase 2: stuns, the breaker itself, HUD juggle pips,
CPU combo usage (Phases 3–4), anti-air launcher normals (decision #10
backlog — clip-reuse candidates: Peggy up-kick reusing `jump_heavy`'s
clip, Richard uppercut reusing `crouch_heavy`'s clip, 2–3 new frames
each). Zero new art was required for Phase 2.

**Juggle numbers.** Launch grants 5 points; air normals cost 2, air
specials cost 3, so the budget buys at most two air hits (L+H = 4,
H+S = 5) — one fewer than the old flat 3-hit cap, by decision. Knockback
×0.7 per air hit, gravity ×1.25 from the second air hit, air hitstun
×0.9 floored at 8 — all unchanged from Phase 1. A launcher used as a
juggle hit drains (never re-grants), so no re-launch loop exists.

**Routes (both connect through the real resolver; damage includes the
launcher as hit 1 and pays the ladder + variety bonus on the third hit):**

| Fighter | Launcher | Route (cost) | Damage | Points left |
|---|---|---|---|---|
| Peggy | peggy_forward (110) | jump_light (2) + jump_heavy (2) | 221.40 | 1 |
| Peggy | peggy_forward_ex (145) | jump_light (2) + jump_heavy (2) | 256.40 | 1 |
| Richard | richard_forward (120) | jump_heavy (2) + richard_air (3) | 263.55 | 0 |
| Richard | richard_forward_ex (150) | jump_heavy (2) + richard_air (3) | 293.55 | 0 |

**Balance table (probe: `game/tests/juggle_probe.gd`, deterministic,
every budget-legal route priced through `receive_hit`; EX = base route
+35 Peggy / +30 Richard on the launcher hit).** Juggle length is 2 air
hits for every multi-hit route, 1 for single-hit routes.

| Fighter | Launcher | Best route | Max damage | Avg (11 legal routes) | Jab-only (12 lights) | L,L,H reference |
|---|---|---|---|---|---|---|
| Peggy | base 110 | H+H | 258.00 | 212.83 | 196.54 | 142.25 |
| Peggy | EX 145 | H+H | 293.00 | 247.83 | — | — |
| Richard | base 120 | H+H | 286.50 | 227.53 | 252.70 | 175.00 |
| Richard | EX 150 | H+H | 316.50 | 257.53 | — | — |

**Launcher vs jab (informs the jab-dominance issue, decision pending):**
Peggy's launcher routes clear her jab-only ceiling (max 258 vs 196.5,
+31%; authored route 221.4 vs 196.5, +13%), but Richard's *average*
launcher route (227.5) is below his jab-only ceiling (252.7) — only his
max (286.5, +13%) and EX routes beat jab mashing. A ladder-only retune
cannot fix this: every candidate below cuts jab-only damage MORE than
launcher-route max damage (jab strings pay the same ladder), so the gap
widens. Dethroning the jab needs a jab-specific decision (jab damage,
pushback, or the Phase 3 breaker/corner tools), which the owner has
deliberately deferred.

**Proposed ladder retunes (numbers only — NOT applied; decision #4 keeps
1.0/1.0/0.85/0.70/0.55 until the owner chooses):**

| Ladder | Peggy max / avg / jab | Richard max / avg / jab |
|---|---|---|
| keep 1.0/1.0/0.85/0.70/0.55 | 258.00 / 212.83 / 196.54 | 286.50 / 227.53 / 252.70 |
| A 1.0/1.0/0.80/0.65/0.50 | 254.00 / 210.47 / 186.29 | 282.00 / 225.05 / 239.51 |
| B 1.0/0.95/0.80/0.65/0.50 | 250.00 / 207.34 / 184.54 | 277.50 / 221.78 / 237.26 |
| C 1.0/1.0/0.75/0.60/0.45 | 250.00 / 208.11 / 176.03 | 277.50 / 222.58 / 226.32 |

Recommendation: keep the ladder for now; if launcher routes feel too
strong after playtests, prefer economics over the ladder (raise
`juggle_cost_normal` to 3 — one air hit — or lower launcher damage),
which touches only juggles and leaves jab strings alone. If the owner
instead wants shorter juggles AND weaker jab strings, candidate A is the
gentlest.

**Real-hitbox route check (`game/tests/juggle_route_probe.gd`, human
timing: the attacker may only jump from an actionable state, forward
drift allowed):**

| Fighter | Launcher | Verdict |
|---|---|---|
| Peggy | base 274y | **Full route connects** (jump f34–36, drift 90) — raised from 228 by the 2026-11-21 owner decision below; at 228 NO air follow-up connected (the defender lands ~f30 before the attacker is actionable ~f34, hitstop + recovery), and the §15.1 proposal of ~255 also does not connect at all. |
| Peggy | EX 360y | Full route connects in-combo (256.40), jump f34–40. |
| Richard | base 260y | Full route connects in-combo (263.55), jump f34–36 — the "one follow-up" asymmetry note in the docs is superseded: the budget route (H+S) fully connects. |
| Richard | EX 340y | Full route connects in-combo (293.55). |

**CPU-vs-CPU soak (NORMAL, seeds 11/29, both pairings, both stages).**
Before (main `83f9573`): lengths 4579/11755 (P vs R), 4606/5208 (R vs P),
Richard 5 – Peggy 3, avg 6537 frames. After Phase 2: lengths
3921/13928 (P vs R), 4606/10867 (R vs P), **Richard 4 – Peggy 4**, avg
8330 frames; worst 13928 still inside the 15000 ceiling (~8% headroom);
no stalls (mutual idle always < 240). Longer average = launcher combos
extend rounds; no stuck states. Phase 3 re-measures the soak (Peggy's 274
launcher and Richard's 40-damage stun special both change round pace); the
fresh worst-case + ~25% resets `SOAK_MAX_FRAMES`.

### 15.2 Phase 3 implementation (2026-11-21)

**Implemented vs planned.** Shipped on `feat/stun-breaker`: the
`StunEffect` resource (schema §9.3, `launcher_safe` false at schema level),
authored stuns on both neutral specials (Richard's Taser Belch 105 → 40 +
`taser_buzz` 240f immunity; Peggy's Peg-Lock keeps 95 damage + 60f immunity
per the owner call above), stun windows that ride the existing HITSTUN
state (no new states) and replace the move's authored hitstun, shake-out
mashing after the authored minimum, once-per-combo via the defender's
combo history, heavy-scaling shrinkage (a window that would fall below the
minimum does not stun at all), and the stun hit earning the attacker NO
meter while its follow-up string starts at scaling step 3. The breaker
(decisions #1/#9): free once per round + 40-meter extras, 300-frame
cooldown, once per combo, checked every frame in HITSTUN (grounded strings
and juggles; never blockstun), grab+special together in the buffer, 30 px
over 6 frames of separation through `direction_away_from()` with the
wall-pinned share transferring to the attacker (the corner-escape fix),
and a 20-frame invulnerability window gated in `is_invulnerable_to()`
exactly like the wake-up windows. HUD-facing readouts
(`breaker_ready()`, `breaker_free_remaining()`,
`breaker_cooldown_left()`, `stun_active()`, `stun_frames_left()`,
`stun_immunity_left()`) and signals (`stun_started`, `stun_ended`,
`breaker_used`) were exposed for the later Phase 4 HUD; Phase 3 itself shipped
no HUD elements. Impact "sparks" are the authored stun tint on the existing
silhouette/sprite flash path — no new art required. All new state is
serialized (`docs/SAVESTATE_PLAN.md`).

Not shipped and not planned for Phase 3: the combo HUD (Phase 4), CPU
usage of stuns/breakers (Phase 4: `stun_rate`/`breaker_rate`/shake-out
mashing), and jab-value changes (deferred until after this phase's
playtest, per the owner decision above).

### 15.3 Phase 4 HUD implementation (2026-11-22)

**Shipped in `game/scripts/ui/match_hud.gd` without changing combat or
MatchRoot gameplay.** `ComboTracker.changed(hits, total_damage)` is the
combo display source. The tracker remains on the defender; the HUD mirrors
the count, damage, scale tag, and juggle pips onto the opposite (attacker's)
side. Macro flashes remain on the macro user, stun and breaker readouts on
their fighter, and event callouts on the signal emitter.

The tint and `x0.70`-style tag show the **base `ComboTuning.scaling_curve`
tier for the latest hit**. They do not claim to include repeat-move or
variety modifiers: those depend on the move and there is no single
move-independent current multiplier to read. `gameplay.show_combo_damage`
gates both the damage total and scale tag. The combo damage/scale line yields
to a same-side callout, and the scale tag also clears over the central banner
to avoid label/art overlap.

Macro step 0 flashes for 45 sim frames; juggle pips show the defender's
remaining/spent budget; the stun bar follows `stun_frames_remaining`; breaker
pips distinguish free, affordable paid, and unavailable states from the
existing resource, meter, cooldown and once-per-combo fields. BREAK! and
CLIP CANCEL join the existing 30-frame one-at-a-time callout slot. All timers
use the HUD sim tick (paused and hitstop-frozen); readouts resync after load,
while transient flashes clear. The HUD holds no state in `serialize()`.

**Verification:** `hud_test.gd` has 82 checks; `ui_typography_test.gd` has 46.
Rendered captures are listed in `docs/UI_SCREENS.md`. The A2/A3/A4 owner
rulings in §11 and §10.3/§10.5 remain unchanged.

## 16. Risks in the current code (combo-readiness)

1. **`_damage_scale()` is hardcoded** on the defender's `combo_hits` —
   Phase 1 must swap it for `ComboTuning` without touching its call site
   semantics; low risk, well-covered by existing combat tests.
2. **No air-hitstun state.** Juggles reuse HITSTUN + `grounded=false`; the
   design deliberately does NOT add a state (stun is likewise a HITSTUN
   flag) because the state machine is the riskiest file in the codebase —
   every existing suite pins state transitions.
3. **The resolver does not record blocked contacts** on the attacker's
   move (`move_hit_confirmed` is hit-only) — BLOCK cancel conditions need
   one new boolean set in `receive_hit`'s block path (`move_was_blocked`),
   which must also join serialization.
4. **Macro input has no home yet.** The buffer is a flat per-action age
   map; the macro tracker slots beside it (a small ordered ring), but the
   dial-ahead cadence must respect the existing buffer windows so buffered
   inputs cannot fire twice.
5. **The CPU reads `combo_rate` bluntly** (offers a light after any
   hit-confirm); string-aware CPU must keep using only the input path and
   resolved state or the #66/#67 determinism guarantees break.
6. **Hitstop freezes buffer aging for at most 5 frames**
   (`hitstop_buffer_freeze_frames` cap) — long stun freezes must reuse the
   same bounded rule or buffered inputs could outlive the stun.
