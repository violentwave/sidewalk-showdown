# CpuController — a deterministic CPU opponent for one fighter.
#
# The CPU never touches FighterBase internals: every tick it decides a set of
# held directions/buttons and issues them through the exact human input path
# (Input.action_press / action_release on the fighter's own p<index>_<action>
# names), so it cannot do anything a human could not — no skipped startup, no
# unpayable meter spend, no moves out of hitstun. Move validation, buffers,
# blocking, throw techs and cancel rules all stay in the engine.
#
# Determinism (rollback/replay requirement):
#   * reads only observable, already-resolved state: it ticks with
#     process_physics_priority -100, before the fighters and MatchRoot run, so
#     everything it sees belongs to the completed previous simulation frame;
#   * owns a small seeded LCG — no global RNG, no wall clock, no delta;
#   * the whole internal state (RNG seed/state, timers, plan, held buttons)
#     lives in this one node and serializes to a small dictionary.
#
# Fairness: every reaction to an observed event waits
# CpuDifficulty.reaction_delay_frames, and each opportunity rolls the tuned
# rates, so the CPU sometimes simply fails to block, anti-air or tech.
class_name CpuController
extends Node

const ACTIONS := ["left", "right", "up", "down",
	"light", "heavy", "special", "grab", "meth"]
const A_LEFT := 0
const A_RIGHT := 1
const A_UP := 2
const A_DOWN := 3
const A_LIGHT := 4
const A_HEAVY := 5
const A_SPECIAL := 6
const A_GRAB := 7
const A_METH := 8

enum Plan {
	NONE,
	APPROACH,
	RETREAT,
	BLOCK,
	POKE,
	THROW,
	ANTI_AIR,
	CORNER_JUMP,
	JUMP_IN,
	# Phase 4 (§12): chasing a launched opponent with the authored juggle
	# route (jump toward, air normals while the point budget can pay).
	JUGGLE,
}

var fighter: FighterBase
var opponent: FighterBase
var match_root: Node
var difficulty: CpuDifficulty

# --- serializable AI state -------------------------------------------------
var seed_value: int = 1
var rng_state: int = 1
var plan: Plan = Plan.NONE
var plan_frames: int = 0
var react_frames: int = 0
var idle_frames: int = 0
var _held_bits: int = 0
var _last_opp_state: int = -1
# Phase 4 combo state (§12): authored-route steps spent in the opponent's
# current combo, the scheduled breaker attempt (armed on hitstun entry,
# fires after the reaction delay), and the juggle-chase step.
var combo_depth: int = 0
var break_armed: int = 0
var juggle_step: int = 0
# ---------------------------------------------------------------------------

var _actions: PackedStringArray = []
# Cached move data (set once in setup; no per-frame lookups or allocations).
var _light: MoveData
var _heavy: MoveData
var _special_fwd: MoveData
var _special_neutral: MoveData
var _grab: MoveData
var _command_grab: MoveData
var _meth: MoveData
var _air_light: MoveData
var _reach_light: float = 0.0
var _reach_heavy: float = 0.0
var _reach_special: float = 0.0
var _reach_throw: float = 0.0
var _reach_meth: float = 0.0
var _reach_air: float = 0.0
# Opponent's standing light reach, for pre-blocking distance.
var _opp_reach_light: float = 40.0
# Tests drive the simulation manually and call manual_tick() themselves.
var manual_mode := false

func setup(who: FighterBase, foe: FighterBase, match: Node,
		tuning: CpuDifficulty, seed: int) -> void:
	fighter = who
	opponent = foe
	match_root = match
	difficulty = tuning
	seed_value = seed if seed != 0 else 1
	rng_state = seed_value
	plan = Plan.NONE
	plan_frames = 0
	react_frames = 0
	idle_frames = 0
	_held_bits = 0
	_last_opp_state = -1
	combo_depth = 0
	break_armed = 0
	juggle_step = 0
	for action in ACTIONS:
		_actions.append("p%d_%s" % [fighter.player_index, action])
	_cache_move_data()

func _cache_move_data() -> void:
	var data: FighterData = fighter.data
	_light = data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	_heavy = data.find_move(MoveData.InputType.HEAVY, MoveData.Stance.STAND)
	_special_fwd = data.find_move(MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	_special_neutral = data.find_move(MoveData.InputType.SPECIAL_NEUTRAL, MoveData.Stance.STAND)
	_grab = data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	_command_grab = data.find_command_grab()
	_meth = data.meth_move
	_air_light = data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)
	_reach_light = _reach_of(_light)
	_reach_heavy = _reach_of(_heavy)
	_reach_special = maxf(_reach_of(_special_fwd), _reach_of(_special_neutral))
	_reach_throw = maxf(_reach_of(_grab), _reach_of(_command_grab))
	_reach_meth = _reach_of(_meth)
	_reach_air = _reach_of(_air_light)
	var opp_light: MoveData = opponent.data.find_move(
		MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	_opp_reach_light = _reach_of(opp_light)

static func _reach_of(move: MoveData) -> float:
	if move == null:
		return 0.0
	# Hitbox center distance from the feet along the facing axis, plus half
	# the hurtbox depth so "in reach" means the boxes can touch.
	return move.hitbox_offset.x + move.hitbox_size.x * 0.5 + 6.0

func _physics_process(_delta: float) -> void:
	if manual_mode:
		return
	_tick()

# Tests call this when they step the simulation manually. Same order the
# engine uses: CPU first, then the fighters, then MatchRoot.
func manual_tick() -> void:
	_tick()

func _exit_tree() -> void:
	_release_all()

func _tick() -> void:
	if fighter == null or not is_instance_valid(fighter) \
			or opponent == null or not is_instance_valid(opponent):
		return
	if not fighter.input_enabled \
			or match_root.phase != match_root.Phase.FIGHT:
		if _held_bits != 0:
			_release_all()
		# No stale reactions across round boundaries.
		react_frames = 0
		plan = Plan.NONE
		plan_frames = 0
		_last_opp_state = opponent.state
		return

	# Throw tech: the window is short, so roll it every tick while grabbed.
	if fighter.state == FighterBase.State.GRAB:
		if _randf() < difficulty.tech_rate:
			_press(A_GRAB, true)
		else:
			_press(A_GRAB, false)
		return

	# Route depth is per combo: the opponent's combo record (defender-side)
	# dying means the string is over.
	if opponent.combo_hits == 0:
		combo_depth = 0

	# While committed to a stun or a move of our own, keep holding a block
	# direction through blockstrings and stop pressing buttons; buffered
	# cancels are authored engine rules and stay available to it.
	if fighter.state in [FighterBase.State.HITSTUN, FighterBase.State.BLOCKSTUN,
			FighterBase.State.KNOCKDOWN, FighterBase.State.WAKE_UP,
			FighterBase.State.TECH, FighterBase.State.LAND]:
		if fighter.state == FighterBase.State.BLOCKSTUN and plan == Plan.BLOCK:
			_hold_block()
		else:
			_release_buttons()
			# Phase 4 defense (§12). The breaker is grab+special in HITSTUN —
			# never blockstun (blocking is already the defense there, and
			# the BLOCKSTUN case is handled above as a hold-block).
			if fighter.state == FighterBase.State.HITSTUN:
				if _last_own_state != FighterBase.State.HITSTUN:
					# Entering hitstun (a new combo opportunity): arm the
					# attempt, which fires after the fairness delay.
					break_armed = difficulty.reaction_delay_frames + 1
				if not fighter.grounded:
					# Juggle-fall drift: hold away from the attacker so we
					# land out of follow-up reach (legal input, §12).
					_walk(-signf(opponent.position.x - fighter.position.x))
				elif break_armed > 0:
					break_armed -= 1
					if break_armed == 0 and fighter.breaker_ready() \
							and _worth_breaking() \
							and _randf() < difficulty.breaker_rate:
						_press(A_GRAB, true)
						_press(A_SPECIAL, true)
				# Stun shake-out: mash the authored direction once the
				# unshakeable minimum has elapsed.
				if fighter.stun_id != &"" and fighter.stun_window_applied \
						- fighter.stun_frames_remaining >= fighter.stun_min_frames \
						and _randf() < difficulty.shake_rate:
					_press(A_UP, true)
			# Wake-up: roll the reversal exactly once, on the first frame.
			if fighter.state == FighterBase.State.WAKE_UP and _last_own_state \
					!= FighterBase.State.WAKE_UP and _randf() < difficulty.reversal_rate:
				_press(A_HEAVY, true)
		_last_own_state = fighter.state
		_last_opp_state = opponent.state
		return

	if fighter.state == FighterBase.State.ATTACK:
		# Phase 4 offense (§12): walk the AUTHORED cancel graph instead of
		# offering one blunt light. Only human-legal buttons are ever
		# offered; the engine validates windows, stances, and meter.
		_release_buttons()
		if fighter.current_move != null:
			var confirmed: bool = fighter.move_hit_confirmed \
					and opponent.state in [FighterBase.State.HITSTUN,
						FighterBase.State.KNOCKDOWN]
			if confirmed:
				if fighter.current_move.launcher and not opponent.grounded:
					# Our launcher connected: chase the authored juggle
					# route within the point budget (difficulty-scaled).
					if _randf() < difficulty.juggle_rate:
						plan = Plan.JUGGLE
						juggle_step = 0
				else:
					_continue_route(CancelRule.Condition.HIT)
			elif fighter.move_was_blocked:
				_blocked_route()
		_last_own_state = fighter.state
		_last_opp_state = opponent.state
		return
	_last_own_state = fighter.state

	# Neutral decisions are per-tick taps: clear last tick's buttons so
	# nothing stays buffered beyond the decision that wanted it.
	_release_buttons()
	_decide()
	_last_opp_state = opponent.state

# ---------------- decision (neutral and threat handling) --------------------

func _decide() -> void:
	var dist: float = _dist()
	var threat: bool = _threat_active()
	var opp_airborne: bool = not opponent.grounded

	# A new opponent attack begins: start the fairness delay once.
	if opponent.state == FighterBase.State.ATTACK \
			and _last_opp_state != FighterBase.State.ATTACK:
		react_frames = difficulty.reaction_delay_frames

	# A jump-in that will land near us: react with the same delay.
	if opp_airborne and _last_opp_grounded and dist < 130.0:
		react_frames = maxi(react_frames, difficulty.reaction_delay_frames)
	_last_opp_grounded = opponent.grounded

	if react_frames > 0:
		react_frames -= 1
		_press(A_LIGHT, false)
		_press(A_HEAVY, false)
		_press(A_SPECIAL, false)
		_press(A_GRAB, false)
		if plan == Plan.BLOCK:
			_hold_block()
		else:
			_walk(signf(opponent.position.x - fighter.position.x))
		return

	# Reaction window open and the threat is real: block or anti-air.
	if threat:
		plan = Plan.BLOCK
		plan_frames = 6
		if opp_airborne and dist < 130.0:
			if _randf() < difficulty.anti_air_rate:
				plan = Plan.ANTI_AIR
				plan_frames = 4
				_press(A_HEAVY, true)
				return
		if _randf() < difficulty.block_rate:
			_hold_block()
		else:
			# The deliberate mistake: freeze up and eat it.
			_release_buttons()
		return
	if plan == Plan.BLOCK and plan_frames > 0:
		# Keep holding the block a moment past the threat; direction_away
		# recomputes every tick so pass-throughs and cross-ups are handled.
		plan_frames -= 1
		_hold_block()
		if plan_frames == 0:
			plan = Plan.NONE
		return

	# Phase 4 offense (§12): the juggle chase. Our launcher connected and
	# the roll said chase: jump toward (real input — the held direction does
	# the drift, no velocity injection) and press the authored air normals
	# while the defender's point budget can still pay for them.
	if plan == Plan.JUGGLE:
		if opponent.grounded or opponent.juggle_points < 2 \
				or opponent.juggle_hits >= 2:
			plan = Plan.NONE
			juggle_step = 0
		elif juggle_step == 0:
			# This branch only runs outside ATTACK, so we are actionable:
			# jump now, holding toward for the drift.
			_walk(signf(opponent.position.x - fighter.position.x))
			_press(A_UP, true)
			juggle_step = 1
		elif fighter.grounded:
			# JUMP_START (or we landed without connecting): keep the
			# direction held and re-offer the jump while the arc is live.
			_walk(signf(opponent.position.x - fighter.position.x))
			_press(A_UP, true)
		elif _dist() <= _reach_air + 8.0 \
				and opponent.position.y >= fighter.position.y - 20.0:
			# In air-move reach with the defender at hittable height: press
			# the authored route — light first, heavy after it connects.
			_walk(signf(opponent.position.x - fighter.position.x))
			if _randf() < difficulty.juggle_rate + 0.3:
				if opponent.juggle_hits == 0:
					_press(A_LIGHT, true)
				else:
					_press(A_HEAVY, true)
		else:
			_walk(signf(opponent.position.x - fighter.position.x))
		return
	plan = Plan.NONE

	# Punish: opponent stuck in hitstun or knockdown recovery inside reach.
	if opponent.state in [FighterBase.State.HITSTUN, FighterBase.State.KNOCKDOWN,
			FighterBase.State.WAKE_UP, FighterBase.State.LAND] \
			and dist <= _reach_light + 10.0:
		if _randf() < difficulty.combo_rate:
			_press(A_HEAVY, true)
			return

	# METHtality: full meter AND the finisher can actually land from here.
	# Prefer it as a punish (opponent stuck in stun) — a whiffed finisher
	# burns the bar for nothing, so raw neutral activations stay rare.
	if fighter.can_meth() and dist <= _reach_meth:
		var punish: bool = opponent.state in [FighterBase.State.HITSTUN,
			FighterBase.State.KNOCKDOWN, FighterBase.State.WAKE_UP,
			FighterBase.State.BLOCKSTUN, FighterBase.State.LAND]
		if (punish and _randf() < difficulty.meth_rate) \
				or (not punish and _randf() < difficulty.meth_rate * 0.1):
			_press(A_METH, true)
			return

	# Throw the turtle: opponent standing block at close range.
	if dist <= _reach_throw and opponent.grounded \
			and (opponent.state == FighterBase.State.BLOCKSTUN
				or opponent.is_blocking(fighter)):
		if _randf() < difficulty.throw_rate:
			if _command_grab != null and _randf() < 0.5:
				_walk(signf(opponent.position.x - fighter.position.x))
			else:
				_walk(0.0)
			_press(A_GRAB, true)
			return

	# Neutral anti-air: the opponent is airborne and drifting in.
	if opp_airborne and not opponent_is_attacking() and dist < 110.0:
		if _randf() < difficulty.anti_air_rate:
			_press(A_HEAVY, true)
			return

	# Corner escape: pinned at a wall with the opponent closing in front.
	if fighter._pinned_at_stage_wall(signf(opponent.position.x
			- fighter.position.x)) and dist < 90.0:
		if _randf() < difficulty.corner_jump_rate:
			plan = Plan.CORNER_JUMP
			plan_frames = 3
			_walk(signf(opponent.position.x - fighter.position.x))
			_press(A_UP, true)
			return

	# Spacing: too close for comfort, back off a beat.
	if dist < _reach_light * 0.6 and _randf() < difficulty.retreat_rate:
		_walk(-signf(opponent.position.x - fighter.position.x))
		return

	# Pre-block: standing inside the opponent's poke reach with no threat
	# observed yet — the defensive habit that catches unreactable jabs.
	if dist <= _opp_reach_light and _randf() < difficulty.preblock_rate:
		plan = Plan.BLOCK
		plan_frames = 12
		_hold_block()
		return

	# Special / EX at special reach. The direction dials the flavor (§12):
	# neutral = the stun special (stun-then-string), forward = the
	# launcher; EX stays the forward-held meter route.
	if dist <= _reach_special and _special_fwd != null:
		if _randf() < difficulty.special_rate:
			var want_ex: bool = fighter.meter >= 50.0 \
					and _randf() < difficulty.ex_rate
			var toward: float = signf(opponent.position.x - fighter.position.x)
			if want_ex:
				_press(A_HEAVY, true) # the EX modifier hold
				_walk(toward)
			elif _randf() < difficulty.stun_rate:
				_walk(0.0) # neutral: the stun special
			elif _randf() < difficulty.launcher_rate:
				_walk(toward) # forward: the launcher
			else:
				return
			_press(A_SPECIAL, true)
			return

	# Poke inside light reach.
	if dist <= _reach_light:
		if _randf() < difficulty.poke_rate:
			if _randf() < difficulty.heavy_mix:
				_press(A_HEAVY, true)
			else:
				_press(A_LIGHT, true)
			return

	# Nothing else: approach. Pass-through is on, so walking forward is
	# always legal; the watchdog guarantees we never idle forever.
	_walk(signf(opponent.position.x - fighter.position.x))
	if fighter.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
			FighterBase.State.WALK_B, FighterBase.State.CROUCH]:
		idle_frames += 1
		if idle_frames > difficulty.idle_limit:
			idle_frames = 0
			if dist <= _reach_heavy:
				_press(A_HEAVY, true)
			else:
				_walk(signf(opponent.position.x - fighter.position.x))
	else:
		idle_frames = 0

# ---------------- helpers --------------------

func _dist() -> float:
	return absf(fighter.position.x - opponent.position.x)

# Phase 4 offense (§12): continue the string through the AUTHORED cancel
# graph of the current move. The CPU only ever offers a button; the engine
# validates the window, stance, and outcome before consuming it, so an
# illegal cancel is impossible by construction.
func _continue_route(cond: int) -> void:
	if combo_depth >= difficulty.route_depth:
		return
	# A buffered press out of string range would just whiff: gate on reach
	# for grounded strings (juggle hits are handled by the JUGGLE plan).
	if opponent.grounded and _dist() > _reach_light + 10.0:
		return
	if _randf() >= difficulty.string_rate:
		return
	var rule: CancelRule = _pick_cancel_rule(cond)
	if rule == null:
		return
	combo_depth += 1
	_press_route(rule.target)

# Pick among the authored cancel edges of the current move that match the
# outcome and are window-open right now. Random choice = route variety.
func _pick_cancel_rule(cond: int) -> CancelRule:
	if fighter.current_move == null:
		return null
	var frame: int = fighter.state_frame
	var eligible: Array = []
	for rule: CancelRule in fighter.current_move.cancels:
		if not rule.window_open(frame):
			continue
		if rule.condition == cond:
			eligible.append(rule)
		elif cond == CancelRule.Condition.HIT \
				and rule.condition == CancelRule.Condition.COUNTER_HIT \
				and fighter.move_counter_hit:
			eligible.append(rule)
	if eligible.is_empty():
		return null
	var idx: int = int(_randf() * float(eligible.size()))
	return eligible[mini(idx, eligible.size() - 1)]

# Offer the button for one authored cancel target. For SPECIAL targets the
# direction is the flavor dial (§12): forward-held = the launcher, neutral =
# the stun special (stun-then-string). Both flavors are difficulty-gated; if
# neither rolls in, the offer is declined (no button pressed) — a declined
# special never stuns by accident, because pressing the neutral special IS
# the stun move. EX is the authored forward-held punish.
func _press_route(target: int) -> bool:
	var toward: float = signf(opponent.position.x - fighter.position.x)
	match target:
		CancelRule.Target.LIGHT:
			_walk(0.0)
			_press(A_LIGHT, true)
		CancelRule.Target.HEAVY:
			_walk(0.0)
			_press(A_HEAVY, true)
		CancelRule.Target.SPECIAL:
			var roll := _randf()
			if roll < difficulty.launcher_rate:
				_walk(toward) # forward: the launcher
			elif roll < difficulty.launcher_rate + difficulty.stun_rate:
				_walk(0.0) # neutral: the stun special
			else:
				return false # declined: neither flavor rolled in
			_press(A_SPECIAL, true)
		CancelRule.Target.EX:
			# The authored EX punish shape: the engine pays meter_cost or
			# falls back to the base forward special.
			_walk(toward)
			_press(A_HEAVY, true)
			_press(A_SPECIAL, true)
	return true

# Safety on a blocked move (§12): burn 25 meter to Clip Cancel out of the
# recovery (decision #8), or keep pressure with an authored BLOCK-condition
# blockstring.
func _blocked_route() -> void:
	if fighter.current_move == null:
		return
	var in_recovery: bool = fighter.state_frame \
			>= fighter.current_move.startup + fighter.current_move.active
	if in_recovery and fighter.meter >= FighterBase.CLIP_CANCEL_COST \
			and _randf() < difficulty.clip_cancel_rate:
		_press(A_GRAB, true)
		_press(A_SPECIAL, true)
		return
	_continue_route(CancelRule.Condition.BLOCK)

# Phase 4 defense (§12): is a PAID break worth the meter here? The free
# break is always worth it; meter breaks only when the stakes are real —
# low health, cornered, or a long combo already paid into. The combo damage
# gauge is the fighter's OWN defender-side tracker (hits THIS fighter took).
func _worth_breaking() -> bool:
	if fighter.breaker_free_uses_left > 0:
		return true
	if fighter.meter < 40.0:
		return false
	if fighter.health <= fighter.max_health * 0.25:
		return true
	if fighter._pinned_at_stage_wall(signf(opponent.position.x
			- fighter.position.x)):
		return true
	return fighter.combo_tracker.total_damage >= 60.0

func _threat_active() -> bool:
	if opponent.state != FighterBase.State.ATTACK \
			or opponent.current_move == null:
		return false
	# The whole move is a threat while it can still hit: startup and active.
	return opponent.state_frame \
		< opponent.current_move.startup + opponent.current_move.active

func opponent_is_attacking() -> bool:
	return opponent.state == FighterBase.State.ATTACK \
		and opponent.current_move != null

# Hold AWAY from the opponent with the shared side helper, so blocking is
# correct against cross-ups and after a pass-through.
func _hold_block() -> void:
	var away: float = FighterBase.direction_away_from(opponent, fighter)
	if away > 0.0:
		_press(A_LEFT, false)
		_press(A_RIGHT, true)
	elif away < 0.0:
		_press(A_LEFT, true)
		_press(A_RIGHT, false)
	else:
		_press(A_LEFT, false)
		_press(A_RIGHT, false)
	_press(A_DOWN, false)
	plan = Plan.BLOCK

# Walk toward (+1) / away (-1) / stand still (0), keeping only one direction
# held at a time; crouch and jump stay released.
func _walk(dir: float) -> void:
	_press(A_LEFT, dir < 0.0)
	_press(A_RIGHT, dir > 0.0)
	_press(A_DOWN, false)
	_press(A_UP, false)

func _press(action: int, held: bool) -> void:
	var was: bool = (_held_bits >> action) & 1
	if held == was:
		return
	if held:
		Input.action_press(_actions[action])
		_held_bits |= 1 << action
	else:
		Input.action_release(_actions[action])
		_held_bits &= ~(1 << action)

func _release_buttons() -> void:
	_press(A_LIGHT, false)
	_press(A_HEAVY, false)
	_press(A_SPECIAL, false)
	_press(A_GRAB, false)
	_press(A_METH, false)
	_press(A_UP, false)
	_press(A_DOWN, false)

func _release_all() -> void:
	for action in ACTIONS.size():
		_press(action, false)

# Own LCG (deterministic, no global state): 32-bit, period 2^32.
func _randf() -> float:
	rng_state = (rng_state * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(rng_state) / 4294967296.0

var _last_own_state: int = -1
var _last_opp_grounded: bool = true

# ---------------- save/restore --------------------

# Small, flat, and stable: the whole AI state for replays and rollback.
func serialize() -> Dictionary:
	return {
		"seed": seed_value,
		"rng": rng_state,
		"plan": plan,
		"plan_frames": plan_frames,
		"react": react_frames,
		"idle": idle_frames,
		"held": _held_bits,
		"last_opp_state": _last_opp_state,
		"last_own_state": _last_own_state,
		"last_opp_grounded": _last_opp_grounded,
		"combo_depth": combo_depth,
		"break_armed": break_armed,
		"juggle_step": juggle_step,
	}

func load_state(data: Dictionary) -> void:
	seed_value = data.get("seed", seed_value)
	rng_state = data.get("rng", rng_state)
	plan = data.get("plan", Plan.NONE) as Plan
	plan_frames = data.get("plan_frames", 0)
	react_frames = data.get("react", 0)
	idle_frames = data.get("idle", 0)
	_last_opp_state = data.get("last_opp_state", -1)
	_last_own_state = data.get("last_own_state", -1)
	_last_opp_grounded = data.get("last_opp_grounded", true)
	combo_depth = data.get("combo_depth", 0)
	break_armed = data.get("break_armed", 0)
	juggle_step = data.get("juggle_step", 0)
	var bits: int = data.get("held", 0)
	for action in ACTIONS.size():
		_press(action, (bits >> action) & 1 == 1)
