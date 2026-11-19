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
var _reach_light: float = 0.0
var _reach_heavy: float = 0.0
var _reach_special: float = 0.0
var _reach_throw: float = 0.0
var _reach_meth: float = 0.0
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
	_reach_light = _reach_of(_light)
	_reach_heavy = _reach_of(_heavy)
	_reach_special = maxf(_reach_of(_special_fwd), _reach_of(_special_neutral))
	_reach_throw = maxf(_reach_of(_grab), _reach_of(_command_grab))
	_reach_meth = _reach_of(_meth)
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
			# Wake-up: roll the reversal exactly once, on the first frame.
			if fighter.state == FighterBase.State.WAKE_UP and _last_own_state \
					!= FighterBase.State.WAKE_UP and _randf() < difficulty.reversal_rate:
				_press(A_HEAVY, true)
		_last_own_state = fighter.state
		_last_opp_state = opponent.state
		return

	if fighter.state == FighterBase.State.ATTACK:
		# Pressure: with the move confirmed, an authored cancel may consume a
		# buffered button. Only a human-legal button is ever offered.
		_release_buttons()
		if fighter.move_hit_confirmed and opponent.state \
				in [FighterBase.State.HITSTUN, FighterBase.State.KNOCKDOWN] \
				and _dist() <= _reach_light + 8.0 and _randf() < difficulty.combo_rate:
			_press(A_LIGHT, true)
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

	# Special / EX at special reach.
	if dist <= _reach_special and _special_fwd != null:
		if _randf() < difficulty.special_rate:
			var want_ex: bool = fighter.meter >= 50.0 \
					and _randf() < difficulty.ex_rate
			if want_ex:
				_press(A_HEAVY, true) # the EX modifier hold
			_walk(signf(opponent.position.x - fighter.position.x))
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
	var bits: int = data.get("held", 0)
	for action in ACTIONS.size():
		_press(action, (bits >> action) & 1 == 1)
