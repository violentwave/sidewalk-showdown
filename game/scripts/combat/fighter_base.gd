# FighterBase — shared fighter controller. Simulation = fixed 60Hz physics ticks.
class_name FighterBase
extends CharacterBody2D

@onready var visual_root: Node2D = $VisualRoot
@onready var silhouette: Polygon2D = $VisualRoot/Silhouette
@onready var facing_marker: Polygon2D = $VisualRoot/FacingMarker

enum State {
	IDLE, WALK_F, WALK_B, CROUCH,
	JUMP_START, JUMP_RISE, JUMP_FALL, LAND,
	ATTACK, BLOCK_STAND, BLOCK_CROUCH,
	HITSTUN, BLOCKSTUN, KNOCKDOWN, WAKE_UP,
	TECH, GRAB, KO, WIN,
}

signal state_changed(new_state: State)
signal health_changed(value: float, max_value: float)
signal meter_changed(value: float, max_value: float)
signal combo_changed(count: int)
signal ko
signal teched
signal meth_started(move_name: String)
signal counter_hit_landed

# --- Identity (FighterData overrides these) ---
@export var player_index: int = 1
@export var data: FighterData
@export var body_color: Color = Color(0.95, 0.55, 0.15)
@export var walk_speed_fwd: float = 90.0
@export var walk_speed_back: float = 70.0
@export var jump_speed: float = 270.0
@export var gravity: float = 900.0
@export var body_width: float = 28.0
@export var body_height: float = 56.0

# Height of the Silhouette polygon in FighterBase.tscn. Visuals scale against
# this constant, not body_height, so each fighter's art matches its own hurtbox.
const SILHOUETTE_HEIGHT := 56.0
const DEFAULT_LANDING_FRAMES := 2
# GDD §5.6: a counter hit adds +2 frames of hitstop, shared like ordinary hitstop.
const COUNTER_HIT_HITSTOP := 2

# PROPOSALS §6 juggle policy. An airborne defender takes at most
# JUGGLE_HIT_CAP hits per combo; later strikes are rejected and stay live.
# The FIRST juggle hit keeps the authored launch arc exactly; every REPEAT
# juggle hit is scaled: horizontal pushback falls by JUGGLE_KNOCKBACK_SCALE per
# prior airborne hit, and gravity while carrying the airborne arc is multiplied
# by JUGGLE_GRAVITY_MULT once the juggle continues past the cap boundary (i.e.
# juggle_hits >= 2). These are documented engine policy, not hidden multipliers.
const JUGGLE_HIT_CAP := 3
const JUGGLE_GRAVITY_MULT := 1.25
const JUGGLE_KNOCKBACK_SCALE := 0.7

# --- Match context ---
var opponent: FighterBase
var stage: Node2D
var input_enabled := true

# --- Sim state ---
var state: State = State.IDLE
var state_frame := 0
var facing := 1
var grounded := true
var crouching := false
var health := 1000.0
var max_health := 1000.0
var meter := 0.0
var max_meter := 100.0
var hitstop_frames := 0
var hitstop_buffer_freeze_frames := 0

var current_move: MoveData
var move_hit_confirmed := false
var move_already_hit := false
# Set on the attacker when its current move's hit was a counter hit (GDD §5.6).
var move_counter_hit := false
var hitstun_frames := 0
var blockstun_frames := 0
var knockdown_frames := 0
var wakeup_frames := 0
var tech_frames := 0
var landing_recovery_frames := DEFAULT_LANDING_FRAMES

var combo_hits := 0
# Airborne hits this fighter has received in the current combo (PROPOSALS §6).
var juggle_hits := 0
var frames_since_hit := 0

# --- Input buffer ---
const BUFFER_NORMAL := 5
const BUFFER_SPECIAL := 7
const BUFFER_GRAB := 5
const BUFFER_METH := 7
const BUFFER_MAX_AGE := 20
var input_buffer: Dictionary = {}
var input_history: Array[String] = []

# Combo readability (GDD 10.3): silhouette-only feedback frames. Visual only -
# no simulation state changes. The countdown runs in _physics_process AFTER the
# hitstop early-return, so the flash is frozen for hitstop's duration.
const HIT_FLASH_FRAMES := 3
const BLOCK_FLASH_FRAMES := 2
var hit_flash_frames: int = 0
var block_flash_frames: int = 0

func _ready() -> void:
	silhouette.modulate = body_color
	facing_marker.modulate = body_color.lightened(0.35)
	if data:
		apply_data(data)
	state_changed.connect(_on_state_changed)
	_sync_visuals()

func apply_data(d: FighterData) -> void:
	data = d
	max_health = d.max_health
	health = d.max_health
	walk_speed_fwd = d.walk_speed_fwd
	walk_speed_back = d.walk_speed_back
	jump_speed = d.jump_speed
	body_width = d.body_width
	body_height = d.body_height
	body_color = d.body_color
	silhouette.modulate = body_color
	facing_marker.modulate = body_color.lightened(0.35)

func begin_round(spawn_pos: Vector2, opponent_x: float) -> void:
	position = spawn_pos
	velocity = Vector2.ZERO
	grounded = true
	crouching = false
	health = max_health
	meter = 0.0
	hitstop_frames = 0
	hitstop_buffer_freeze_frames = 0
	combo_hits = 0
	frames_since_hit = 0
	knockdown_frames = 0
	tech_frames = 0
	wakeup_frames = 0
	landing_recovery_frames = DEFAULT_LANDING_FRAMES
	current_move = null
	move_hit_confirmed = false
	move_already_hit = false
	input_buffer.clear()
	facing = 1 if opponent_x > spawn_pos.x else -1
	_force_state(State.IDLE)
	_emit_health()
	meter_changed.emit(meter, max_meter)
	combo_changed.emit(0)

func _physics_process(_delta: float) -> void:
	_poll_input()
	_tick_combo()

	if hitstop_frames > 0:
		hitstop_frames -= 1
		return

	# Flash countdown freezes during hitstop: it only runs past the early-return.
	if hit_flash_frames > 0 or block_flash_frames > 0:
		hit_flash_frames = maxi(hit_flash_frames - 1, 0)
		block_flash_frames = maxi(block_flash_frames - 1, 0)
		_update_silhouette_flash()

	state_frame += 1
	var axis := _axis("left", "right")
	var down := _down()

	match state:
		State.IDLE, State.WALK_F, State.WALK_B:
			_grounded_movement(axis, down)
		State.CROUCH:
			_crouch_logic(down)
		State.JUMP_START, State.JUMP_RISE, State.JUMP_FALL:
			_air_movement(axis)
		State.LAND:
			velocity.x = 0.0
			if state_frame >= landing_recovery_frames:
				_set_state(State.IDLE)
		State.ATTACK:
			_attack_logic()
		State.HITSTUN:
			_stun_logic(hitstun_frames)
		State.BLOCKSTUN:
			_stun_logic(blockstun_frames)
		State.KNOCKDOWN:
			_knockdown_logic()
		State.WAKE_UP:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta_fixed())
			if state_frame >= wakeup_frames:
				_set_state(State.IDLE)
		State.TECH:
			_stun_logic(tech_frames)
		State.KO:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta_fixed())

	_apply_gravity(delta_fixed())
	_integrate()
	if stage:
		clamp_to_stage()
		_landing_check(stage.floor_y)
	_sync_visuals()

# ---------------- Movement ----------------
func _grounded_movement(axis: float, down: bool) -> void:
	if _try_start_attack():
		return
	_update_facing()

	if _pressed("up"):
		velocity.y = -jump_speed
		grounded = false
		_set_state(State.JUMP_START)
		return
	if down:
		velocity.x = 0.0
		_set_state(State.CROUCH)
		return

	if axis == 0.0:
		velocity.x = 0.0
		_set_state(State.IDLE)
	else:
		var forward := signf(axis) == float(facing)
		velocity.x = axis * (walk_speed_fwd if forward else walk_speed_back)
		_set_state(State.WALK_F if forward else State.WALK_B)

func _crouch_logic(down: bool) -> void:
	if _try_start_attack():
		return
	velocity.x = 0.0
	if not down:
		_set_state(State.IDLE)

func _air_movement(axis: float) -> void:
	if _try_start_attack():
		return
	if input_enabled:
		velocity.x = axis * walk_speed_fwd
	# Advance the jump state so animation/blocking can read the arc.
	if state == State.JUMP_START and state_frame > 1:
		_set_state(State.JUMP_RISE if velocity.y < 0.0 else State.JUMP_FALL)
	elif state == State.JUMP_RISE and velocity.y >= 0.0:
		_set_state(State.JUMP_FALL)

func _attack_logic() -> void:
	if current_move == null:
		_set_state(State.IDLE)
		return
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta_fixed())

	if move_hit_confirmed:
		if _try_cancel():
			return
	if state_frame >= _move_total(current_move):
		if not move_already_hit:
			finish_move_whiff()
		if not grounded:
			_set_state(State.JUMP_FALL)
		else:
			_set_state(State.CROUCH if _down() else State.IDLE)

func _stun_logic(duration: int) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 350.0 * delta_fixed())
	if state_frame >= duration:
		if not grounded:
			_set_state(State.JUMP_FALL)
		else:
			_set_state(State.CROUCH if _down() else State.IDLE)

func _knockdown_logic() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta_fixed())
	if state_frame >= knockdown_frames:
		# Length is authored per fighter; invulnerability is a shorter, separate timer.
		wakeup_frames = data.wakeup_frames if data else 12
		_force_state(State.WAKE_UP)

func _apply_gravity(delta: float) -> void:
	if not grounded:
		# PROPOSALS §6: while an airborne defender carries the juggle arc past a
		# repeat air hit, gravity is multiplied so the arc returns to the floor.
		var mult := gravity * JUGGLE_GRAVITY_MULT \
			if juggle_hits >= 2 and state in [State.HITSTUN,	State.KNOCKDOWN] else gravity
		velocity.y += mult * delta

func _integrate() -> void:
	position += velocity * delta_fixed()

func delta_fixed() -> float:
	return 1.0 / Engine.physics_ticks_per_second

func _landing_check(floor_y: float) -> void:
	if position.y < floor_y:
		return
	position.y = floor_y
	velocity.y = 0.0
	if grounded:
		return
	grounded = true
	# Landing ends aerial attacks immediately. Only a still-running/finished air
	# move that has not connected earns its authored recovery; contact is the
	# reward, and interruption states keep their existing stun/KO behavior.
	var landing_move: MoveData = current_move
	var whiffed_air_move: bool = landing_move != null \
			and landing_move.stance == MoveData.Stance.AIR \
			and not move_already_hit \
			and state in [State.ATTACK, State.JUMP_START, State.JUMP_RISE, State.JUMP_FALL]
	landing_recovery_frames = DEFAULT_LANDING_FRAMES
	if whiffed_air_move and landing_move != null:
		landing_recovery_frames = landing_move.landing_recovery \
			if landing_move.landing_recovery > 0 else DEFAULT_LANDING_FRAMES
	current_move = null
	move_hit_confirmed = false
	move_already_hit = false
	match state:
		State.ATTACK, State.JUMP_START, State.JUMP_RISE, State.JUMP_FALL:
			_set_state(State.LAND)
		State.HITSTUN, State.KNOCKDOWN, State.KO:
			# stay in the stun; land into idle when frames run out
			pass
		_:
			_set_state(State.LAND)

# ---------------- Attacks ----------------
func _try_start_attack() -> bool:
	if data == null or not input_enabled:
		return false
	var stance := _current_stance()

	if _try_start_meth():
		return true

	if grounded and _consume("grab", BUFFER_GRAB):
		# PROPOSALS §7: the grab button selects by held direction. Forward
		# (axis in the facing direction) + grab starts the authored command
		# grab (UNTECHABLE); a neutral or back-held grab press starts the
		# techable normal throw. Tech itself stays direction-blind: any grab
		# buffer entry still techs an incoming throw, which one is selected is
		# decided only here, on the attacker's side.
		var command := data.find_command_grab()
		if command and _axis("left", "right") * float(facing) > 0.0:
			_start_move(command)
		else:
			var grab := data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
			if grab:
				_start_move(grab)
		return true

	if _consume("special", BUFFER_SPECIAL):
		if _try_start_special(stance):
			return true

	if _consume("light", BUFFER_NORMAL):
		var light := data.find_move(MoveData.InputType.LIGHT, stance)
		if light:
			_start_move(light)
			return true

	if _consume("heavy", BUFFER_NORMAL):
		var heavy := data.find_move(MoveData.InputType.HEAVY, stance)
		if heavy:
			_start_move(heavy)
			return true

	return false

# Authored cancel routes (PROPOSALS §6): the rules on current_move are evaluated
# in array order, counter-specific rules first, and the first one that starts a
# move wins. METHtality remains a global full-meter path before any rule.
func _try_cancel() -> bool:
	if current_move == null:
		return false
	# Buffered METHtality can also interrupt a confirmed attack; activation itself
	# requires only a full meter.
	if move_hit_confirmed and state_frame > current_move.startup and _try_start_meth():
		return true
	for counter_pass in [true, false]:
		for rule: CancelRule in current_move.cancels:
			if not _cancel_rule_matches(rule, counter_pass):
				continue
			if _run_cancel(rule):
				return true
	return false

func _cancel_rule_matches(rule: CancelRule, counter_pass: bool) -> bool:
	if not rule.window_open(state_frame):
		return false
	if rule.condition == CancelRule.Condition.COUNTER_HIT:
		return counter_pass and move_hit_confirmed and move_counter_hit
	if rule.condition == CancelRule.Condition.HIT:
		return not counter_pass and move_hit_confirmed
	return false

# Consumes the buffer exactly as the legacy routes did: a buffered input is spent
# even when no matching move exists, and the evaluation falls through to the next rule.
func _run_cancel(rule: CancelRule) -> bool:
	match rule.target:
		CancelRule.Target.SPECIAL:
			return _consume("special", BUFFER_SPECIAL) and _try_start_special(_current_stance())
		CancelRule.Target.EX:
			# Authored punish rule (PROPOSALS §6): the EX command shape on the
			# fighter's forward special — a special buffer AND a heavy buffer —
			# EX-is the forward special, paying meter_cost; when meter cannot
			# pay, the base forward special is the documented fallback.
			return _cancel_into_forward_ex()
		CancelRule.Target.LIGHT:
			return _cancel_into_normal(MoveData.InputType.LIGHT, "light")
		CancelRule.Target.HEAVY:
			return _cancel_into_normal(MoveData.InputType.HEAVY, "heavy")
	return false

func _cancel_into_normal(input: MoveData.InputType, action: String) -> bool:
	if not _consume(action, BUFFER_NORMAL):
		return false
	var move := data.find_move(input, _current_stance())
	if move == null:
		return false
	_start_move(move)
	return true

func _cancel_into_forward_ex() -> bool:
	# The punish route is a grounded, forward-held command (PROPOSALS §6). Any
	# other direction, or an airborne fighter, leaves the buffers untouched so
	# the legacy SPECIAL route resolves the input by its own direction rules.
	var stance := _current_stance()
	if stance == MoveData.Stance.AIR or _special_input(stance) != MoveData.InputType.SPECIAL_FWD:
		return false
	# The EX command shape is checked WITHOUT spending either buffer until the
	# full command is present: a lone special buffer must still reach the legacy
	# SPECIAL route below, and a lone heavy buffer must stay usable.
	if not (input_buffer.has("special") and input_buffer.has("heavy")):
		return false
	_consume("heavy", BUFFER_NORMAL)
	if not _consume("special", BUFFER_SPECIAL):
		return false
	var ex := data.find_ex_move(MoveData.InputType.SPECIAL_FWD, stance)
	if ex and spend_meter(ex.meter_cost):
		_start_move(ex)
		return true
	var base := data.find_move(MoveData.InputType.SPECIAL_FWD, stance)
	if base:
		_start_move(base)
		return true
	return false

# METHtality availability: a full meter and an authored finisher are the only
# requirements. Opponent health, state, and invulnerability do not gate the
# input; the finisher may whiff against an invulnerable target.
func can_meth() -> bool:
	if data == null or data.meth_move == null:
		return false
	if meter + 0.001 < max_meter:
		return false
	return true

# Consume a buffered meth input only on a legal trigger; a failed check leaves
# it to age out so it cannot fire later from a stale press.
func _try_start_meth() -> bool:
	if data == null or not input_enabled:
		return false
	if not input_buffer.has("meth") or input_buffer["meth"] > BUFFER_METH:
		return false
	if not can_meth():
		return false
	input_buffer.erase("meth")
	spend_meter(meter) # finisher drains the bar fully
	_start_move(data.meth_move)
	meth_started.emit(data.meth_name)
	return true

# Special starter shared by neutral startup and cancel windows. Holding heavy
# asks for the EX row: meter is spent only if the EX exists and can be paid for.
# Otherwise the base special comes out and the buffered special is not wasted.
func _try_start_special(stance: MoveData.Stance) -> bool:
	var input := _special_input(stance)
	if _pressed("heavy"):
		var ex := data.find_ex_move(input, stance)
		if ex and spend_meter(ex.meter_cost):
			_consume("heavy", BUFFER_NORMAL)
			_start_move(ex)
			return true
	var special := data.find_move(input, stance)
	if special:
		_start_move(special)
		return true
	return false

func _start_move(move: MoveData) -> void:
	current_move = move
	move_hit_confirmed = false
	move_already_hit = false
	move_counter_hit = false
	velocity.x = 0.0
	_force_state(State.ATTACK)

func _current_stance() -> MoveData.Stance:
	if not grounded:
		return MoveData.Stance.AIR
	if _down() or crouching:
		return MoveData.Stance.CROUCH
	return MoveData.Stance.STAND

func _special_input(stance: MoveData.Stance) -> MoveData.InputType:
	if stance == MoveData.Stance.AIR:
		return MoveData.InputType.SPECIAL_AIR
	if _down():
		return MoveData.InputType.SPECIAL_DOWN
	var axis := _axis("left", "right")
	if axis != 0.0 and signf(axis) == float(facing):
		return MoveData.InputType.SPECIAL_FWD
	if axis != 0.0:
		return MoveData.InputType.SPECIAL_BACK
	return MoveData.InputType.SPECIAL_NEUTRAL

func get_hitbox_rect() -> Rect2:
	if state != State.ATTACK or current_move == null:
		return Rect2()
	if not current_move.is_active_frame(state_frame):
		return Rect2()
	return current_move.hitbox_rect(position, facing)

func is_in_attack_startup() -> bool:
	return state == State.ATTACK and current_move != null \
		and state_frame < current_move.startup

func on_attack_connected(was_hit: bool) -> void:
	move_already_hit = true
	move_hit_confirmed = was_hit

# True when `move` must not connect with this fighter right now: K1/R1 knockdown
# protection, the §6 airborne juggle cap, the universal wake-up window (strike+
# throw, then a separately authored throw tail), or a reversal move's own invuln
# frames. Deliberately a
# query, not only a branch inside receive_hit(): _poll_hit() skips a protected
# defender before the move is returned, so the hitbox stays live and the first
# vulnerable frame is the one that connects.
func is_invulnerable_to(move: MoveData) -> bool:
	if move == null:
		return false
	if state == State.KNOCKDOWN:
		# R1: no throw, including a techable normal throw, connects during knockdown.
		if move.level == MoveData.Level.THROW:
			return true
		# K1: every strike except an authored METH row is rejected. This query is
		# checked before hit confirmation in MatchRoot, so rejected moves stay live.
		if not move.meth:
			return true
	# PROPOSALS §6 juggle cap: an airborne defender who has already taken
	# JUGGLE_HIT_CAP hits in this combo cannot be hit again. This query is checked
	# before hit confirmation in MatchRoot, so a rejected strike stays live.
	if not grounded and juggle_hits >= JUGGLE_HIT_CAP:
		return true
	if state == State.WAKE_UP:
		if state_frame < (data.wakeup_invuln_frames if data else 6):
			return true
		if move.level == MoveData.Level.THROW \
				and state_frame < (data.wakeup_throw_invuln_frames if data else 8):
			return true
	# current_move survives the move's final frame (attack logic returns to IDLE
	# without clearing it), so gate on ATTACK: otherwise the invuln window would
	# be re-read against the fresh IDLE state_frame and lingers after the move.
	if state == State.ATTACK and current_move != null \
			and current_move.invuln_kind != MoveData.Invuln.NONE:
		if state_frame >= current_move.invuln_start and state_frame < current_move.invuln_end:
			match current_move.invuln_kind:
				MoveData.Invuln.FULL:
					return true
				MoveData.Invuln.THROW:
					return move.level == MoveData.Level.THROW
				MoveData.Invuln.STRIKE:
					return move.level != MoveData.Level.THROW
	return false

func finish_move_whiff() -> void:
	if current_move:
		add_meter(current_move.meter_gain_whiff)

# Total frames of the move in play. Whiffed throws read FighterData's
# throw_whiff_recovery instead of the grab's authored recovery (PROPOSALS §2):
# the whiff must leave the thrower punishable by a light/heavy. A connected
# throw keeps its authored frames, and teching both clears current_move.
func _move_total(move: MoveData) -> int:
	if move == null:
		return 0
	if move.level == MoveData.Level.THROW and not move_already_hit and data:
		# PROPOSALS §7: a row-level whiff override (the command grabs) replaces
		# FighterData's throw_whiff_recovery for that row only.
		var whiff := move.whiff_recovery if move.whiff_recovery > 0 \
			else data.throw_whiff_recovery
		return move.startup + move.active + whiff
	return move.total_frames()

# ---------------- Damage ----------------
func is_holding_back() -> bool:
	if not input_enabled:
		return false
	var axis := _axis("left", "right")
	return axis != 0.0 and signf(axis) != float(facing)

func is_blocking() -> bool:
	if not grounded:
		return false
	# Authored extended LAND is a whiff-recovery commitment: unlike the legacy
	# 2-frame landing state, it cannot be cancelled into block by holding back.
	if state == State.LAND and landing_recovery_frames > DEFAULT_LANDING_FRAMES:
		return false
	# BLOCKSTUN is intentionally allowed: holding back must keep blocking
	# successive hits in a blockstring.
	if state in [State.ATTACK, State.HITSTUN, State.KNOCKDOWN, State.WAKE_UP, State.TECH, State.KO]:
		return false
	return is_holding_back()

func can_block(move: MoveData) -> bool:
	if move.level == MoveData.Level.THROW:
		return false
	var crouch_block := _down() or state == State.CROUCH
	if crouch_block:
		return move.level in [MoveData.Level.LOW, MoveData.Level.MID]
	return move.level in [MoveData.Level.OVERHEAD, MoveData.Level.MID]

# `counter` is decided by MatchRoot._resolve_hits(): the defender was in its own
# startup and the exchange was not a trade. Only an actual hit can be a counter.
func receive_hit(attacker: FighterBase, move: MoveData, counter := false) -> bool:
	if state == State.KO:
		juggle_hits = 0
		return false
	# Keep K1/R1 true for direct resolver/test callers too; MatchRoot normally
	# skips these contacts in _poll_hit() via is_invulnerable_to().
	if state == State.KNOCKDOWN:
		if move.level == MoveData.Level.THROW or not move.meth:
			return false

	if move.level == MoveData.Level.THROW:
		# Airborne defenders can't be thrown: the grab whiffs (bug-fix guard).
		if not grounded:
			return false
		# PROPOSALS §2: the tech check runs before damage and consumes both grab
		# buffers, so a defender who pressed grab in the window resolves the
		# exchange as a tech rather than as damage. PROPOSALS §7: command grabs
		# are UNTECHABLE by owner decision — the tech check is skipped for them
		# entirely; the normal throw remains the techable layer.
		if move.input != MoveData.InputType.COMMAND_GRAB and _can_tech():
			_start_tech(attacker)
			return false

	# PROPOSALS §6 juggle cap, mirrored for direct resolver/test callers; the
	# airborne-arc scaling below applies to hits 2..cap only.
	if not grounded and juggle_hits >= JUGGLE_HIT_CAP:
		return false

	if is_blocking() and can_block(move):
		# Chip damage is a pressure tool, never a kill: blocked hits floor at 1 HP.
		block_flash_frames = BLOCK_FLASH_FRAMES
		_update_silhouette_flash()
		health = maxf(1.0, health - move.block_damage)
		add_meter(move.meter_gain_receive)
		attacker.add_meter(move.meter_gain_block)
		blockstun_frames = move.blockstun
		hitstop_frames = maxi(hitstop_frames, move.hitstop)
		attacker.hitstop_frames = maxi(attacker.hitstop_frames, move.hitstop)
		velocity.x = float(attacker.facing) * move.block_pushback
		# §6 corner rule: a defender pinned against a stage bound cannot take
		# the blocked pushback; the displacement transfers to the attacker,
		# away from the defender, subject to the attacker's own bound.
		if _pinned_at_stage_wall(velocity.x):
			attacker.velocity.x = -float(attacker.facing) * move.block_pushback
			velocity.x = 0.0
		combo_hits = 0
		combo_changed.emit(0)
		_force_state(State.BLOCKSTUN)
		_emit_health()
		return false

	var scaled := move.damage * _damage_scale()
	health = maxf(0.0, health - scaled)
	combo_hits += 1
	frames_since_hit = 0
	combo_changed.emit(combo_hits)
	add_meter(move.meter_gain_receive)
	attacker.add_meter(move.meter_gain_hit)
	var stop := move.hitstop + (COUNTER_HIT_HITSTOP if counter else 0)
	hitstop_frames = maxi(hitstop_frames, stop)
	attacker.hitstop_frames = maxi(attacker.hitstop_frames, stop)
	attacker.move_counter_hit = counter
	if counter:
		attacker.counter_hit_landed.emit()

	hit_flash_frames = HIT_FLASH_FRAMES
	_update_silhouette_flash()
	var dir := 1.0 if position.x >= attacker.position.x else -1.0
	# PROPOSALS §6: repeated air hits return the arc to the floor. The first
	# airborne hit of a combo keeps the authored knockback; each repeat scales
	# horizontal pushback by JUGGLE_KNOCKBACK_SCALE per prior airborne hit.
	# `was_airborne` is captured before the launch below: an authored upward
	# knockback starts an airborne juggle, but the launcher itself is a grounded
	# hit and must not increment the airborne-hit counter.
	var was_airborne := not grounded
	var air_knockback_x := move.knockback.x
	if was_airborne and juggle_hits > 0:
		air_knockback_x *= pow(JUGGLE_KNOCKBACK_SCALE, float(juggle_hits))
	velocity = Vector2(dir * air_knockback_x, -move.knockback.y)
	# Authored launchers (PROPOSALS §6) are plain data: positive vertical
	# knockback takes the defender off the floor so gravity and the juggle rules
	# apply. This is not a per-move special case.
	if move.knockback.y > 0.0 and not move.knockdown:
		grounded = false
	_emit_health()

	if health <= 0.0:
		velocity = Vector2(dir * 130.0, -170.0)
		grounded = false # let gravity arc the loser back down to the stage
		_force_state(State.KO)
		juggle_hits = 0
		ko.emit()
		return true

	if was_airborne:
		juggle_hits += 1
	if move.knockdown:
		knockdown_frames = 30
		_force_state(State.KNOCKDOWN)
	else:
		hitstun_frames = move.hitstun
		_force_state(State.HITSTUN)
	return true

# PROPOSALS §2 — SF6-style tech gate against the existing input buffer:
#   - a grab buffered within data.throw_tech_window frames counts as a tech
#     input; because grab is also the throw button, a throw attempt of the
#     defender's own (ATTACK with a THROW move still in startup/active) counts
#     as the tech input too — the incoming throw breaks it first.
#   - committing to another button inside the window kills the tech (lockout),
#     which makes mash option-selects lose to the throw.
func _can_tech() -> bool:
	if data == null:
		return false
	var grab_live: bool = input_buffer.has("grab") \
			and input_buffer["grab"] <= data.throw_tech_window
	var own_throw := state == State.ATTACK and current_move != null \
			and current_move.level == MoveData.Level.THROW \
			and state_frame < current_move.startup + current_move.active
	if not grab_live and not own_throw:
		return false
	# Lockout: any other button pressed inside the window kills the tech.
	for action in ["light", "heavy", "special", "meth"]:
		if input_buffer.has(action) and input_buffer[action] <= data.throw_tech_window:
			return false
	# Already committed to a non-throw attack that hasn't left startup.
	if state == State.ATTACK and current_move != null \
			and current_move.level != MoveData.Level.THROW \
			and state_frame < current_move.startup:
		return false
	return true

# Tech resolves: no damage, no knockdown, both fighters consumed their buffered
# grab, pushed apart ~20px each, and both sit in TECH for throw_tech_recovery
# frames. current_move is cleared so the (already-connected) throw leaves no
# leftover state for hitbox or invuln queries.
func _start_tech(other: FighterBase) -> void:
	var dur := data.throw_tech_recovery if data else 10
	input_buffer.erase("grab")
	tech_frames = dur
	current_move = null
	_force_state(State.TECH)
	if other and other != self:
		other.input_buffer.erase("grab")
		other.tech_frames = dur
		other.current_move = null
		other._force_state(State.TECH)
	var dir := signf(position.x - other.position.x) if other else -float(facing)
	if dir == 0.0:
		dir = -float(facing)
	var push := dir * (20.0 / float(dur)) / delta_fixed()
	velocity = Vector2(push, 0.0)
	if other and other != self:
		other.velocity = Vector2(-push, 0.0)
	teched.emit()
	if other and other != self:
		other.teched.emit()

func _damage_scale() -> float:
	var hits := combo_hits + 1
	if hits <= 2:
		return 1.0
	elif hits == 3:
		return 0.85
	elif hits == 4:
		return 0.70
	elif hits >= 5:
		return 0.55
	return 1.0

func reset_state() -> void:
	_force_state(State.IDLE)
	velocity = Vector2.ZERO
	current_move = null
	move_hit_confirmed = false
	move_already_hit = false
	hitstop_frames = 0
	hitstop_buffer_freeze_frames = 0
	hitstun_frames = 0
	blockstun_frames = 0
	knockdown_frames = 0
	tech_frames = 0
	landing_recovery_frames = DEFAULT_LANDING_FRAMES
	combo_hits = 0
	juggle_hits = 0
	frames_since_hit = 0
	input_buffer.clear()
	grounded = true
	hit_flash_frames = 0
	block_flash_frames = 0
	_update_silhouette_flash()
	_sync_visuals()

func add_meter(amount: float) -> void:
	meter = clampf(meter + amount, 0.0, max_meter)
	meter_changed.emit(meter, max_meter)

# Pay for an EX move before it starts. Returns false (and spends nothing) when
# the bar is short, which makes the caller fall back to the base special.
func spend_meter(cost: float) -> bool:
	if cost <= 0.0:
		return true
	if meter + 0.001 < cost:
		return false
	meter = maxf(0.0, meter - cost)
	meter_changed.emit(meter, max_meter)
	return true

func _emit_health() -> void:
	health_changed.emit(health, max_health)

# ---------------- Input ----------------
func _poll_input() -> void:
	# D3/PR 4a: freeze all stored action ages together during hitstop, but only
	# for one normal buffer window. Long freezes therefore cannot preserve stale
	# inputs indefinitely. Blockstun aging remains unchanged (4b is deferred).
	var freeze_buffer_ages := false
	if hitstop_frames > 0:
		if hitstop_buffer_freeze_frames < BUFFER_NORMAL:
			hitstop_buffer_freeze_frames += 1
			freeze_buffer_ages = true
	else:
		hitstop_buffer_freeze_frames = 0
	if not input_enabled:
		return
	for action in ["light", "heavy", "special", "grab", "meth", "up"]:
		if Input.is_action_just_pressed("p%d_%s" % [player_index, action]):
			input_buffer[action] = 0
			input_history.append(action)
			if input_history.size() > 60:
				input_history.pop_front()
	if freeze_buffer_ages:
		return
	for key in input_buffer.keys():
		input_buffer[key] += 1
		if input_buffer[key] > BUFFER_MAX_AGE:
			input_buffer.erase(key)

func _consume(action: String, window: int) -> bool:
	if input_buffer.has(action) and input_buffer[action] <= window + 1:
		input_buffer.erase(action)
		return true
	return false

func _axis(left: String, right: String) -> float:
	if not input_enabled:
		return 0.0
	return Input.get_axis("p%d_%s" % [player_index, left], "p%d_%s" % [player_index, right])

func _pressed(action: String) -> bool:
	return input_enabled and Input.is_action_pressed("p%d_%s" % [player_index, action])

func _down() -> bool:
	return _pressed("down")

func _tick_combo() -> void:
	frames_since_hit += 1
	if combo_hits > 0 and frames_since_hit > 40 and state not in [State.HITSTUN, State.KNOCKDOWN]:
		# Combo end: the §6 juggle counter only resets with the combo.
		combo_hits = 0
		juggle_hits = 0
		combo_changed.emit(0)

# ---------------- Misc ----------------
func _update_facing() -> void:
	if opponent:
		facing = 1 if opponent.position.x >= position.x else -1

# True when this fighter stands at a stage bound and `v` pushes into it.
func _pinned_at_stage_wall(v: float) -> bool:
	if stage == null:
		return false
	if v < 0.0 and position.x <= stage.left_bound:
		return true
	return v > 0.0 and position.x >= stage.right_bound

func clamp_to_stage() -> void:
	if stage == null:
		return
	position.x = clampf(position.x, stage.left_bound, stage.right_bound)

func _pushbox_height() -> float:
	return body_height * (0.65 if (crouching or state == State.CROUCH) else 1.0)

func pushbox_rect() -> Rect2:
	var h := _pushbox_height()
	return Rect2(position.x - body_width * 0.5, position.y - h, body_width, h)

func hurtbox_rect() -> Rect2:
	return pushbox_rect()

func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
		state_changed.emit(new_state)

func _force_state(new_state: State) -> void:
	state = new_state
	state_frame = 0
	state_changed.emit(new_state)

func _update_silhouette_flash() -> void:
	# Hit flash is the strong white; block flash is a subtle lightening only.
	if hit_flash_frames > 0:
		silhouette.modulate = Color(1.0, 1.0, 1.0)
	elif block_flash_frames > 0:
		silhouette.modulate = body_color.lightened(0.35)
	else:
		silhouette.modulate = body_color

func _sync_visuals() -> void:
	var h := _pushbox_height()
	silhouette.scale.y = h / SILHOUETTE_HEIGHT
	facing_marker.position.x = facing * body_width * 0.5
	facing_marker.scale.x = facing
	facing_marker.position.y = -h + 8.0
	visual_root.position = Vector2.ZERO
	visual_root.rotation = 0.0
	visual_root.scale = Vector2.ONE
	_apply_state_animation()

func _apply_state_animation() -> void:
	# First-pass, render-only motion on the placeholder shapes. All animation is
	# attached to VisualRoot, so it never moves the fighter body or combat boxes.
	var is_peggy := data != null and data.id == "peg_leg_peggy"
	var frame := float(state_frame)
	match state:
		State.IDLE:
			var rate := 0.2 if is_peggy else 0.12
			var phase := frame * rate + (0.0 if is_peggy else 0.75)
			var breath := absf(sin(phase))
			visual_root.position.y = -breath * (1.2 if is_peggy else 0.75)
			visual_root.scale.x = 1.0 + breath * (0.016 if is_peggy else 0.008)
			visual_root.scale.y = 1.0 - breath * (0.012 if is_peggy else 0.006)
		State.WALK_F, State.WALK_B:
			var rate := 0.55 if is_peggy else 0.36
			var stride := sin(frame * rate)
			visual_root.position = Vector2(
				stride * (0.7 if is_peggy else 0.35),
				-absf(stride) * (2.0 if is_peggy else 1.2))
			visual_root.rotation = stride * (0.025 if is_peggy else 0.014)
			visual_root.scale.y = 1.0 + absf(cos(frame * rate)) * 0.025
		State.JUMP_START:
			visual_root.scale = Vector2(0.94, 1.1)
		State.JUMP_RISE:
			visual_root.scale = Vector2(0.96, 1.07)
			visual_root.rotation = -float(facing) * 0.025
		State.JUMP_FALL, State.LAND:
			visual_root.scale = Vector2(1.04, 0.95)
		State.ATTACK:
			var startup := float(current_move.startup) if current_move else 1.0
			if frame < startup:
				visual_root.scale = Vector2(0.9 if not is_peggy else 0.95, 1.06)
				visual_root.rotation = -float(facing) * (0.06 if not is_peggy else 0.035)
			else:
				visual_root.position.x = float(facing) * (4.0 if not is_peggy else 2.5)
				visual_root.scale = Vector2(1.05, 0.97)
				visual_root.rotation = float(facing) * (0.06 if not is_peggy else 0.04)
		State.HITSTUN:
			visual_root.position.x = -float(facing) * 2.0
			visual_root.rotation = -float(facing) * 0.055
			visual_root.scale.x = 0.94
		State.BLOCKSTUN:
			visual_root.position.x = -float(facing) * 1.0
			visual_root.rotation = -float(facing) * 0.025
		State.KNOCKDOWN, State.KO:
			var fall := clampf(frame / 5.0, 0.0, 1.0)
			fall = fall * fall * (3.0 - 2.0 * fall)
			visual_root.position = Vector2(-float(facing) * 3.0 * fall, -4.0 * fall)
			visual_root.rotation = -float(facing) * 1.1 * fall
			visual_root.scale.y = 1.0 - 0.08 * fall
		State.WAKE_UP:
			var stand_progress := clampf(frame / float(maxi(wakeup_frames, 1)), 0.0, 1.0)
			var fall := 1.0 - stand_progress
			visual_root.position = Vector2(-float(facing) * 3.0 * fall, -4.0 * fall)
			visual_root.rotation = -float(facing) * 1.1 * fall
		State.TECH:
			visual_root.scale = Vector2(0.92, 1.07)
		State.WIN:
			visual_root.position.y = -absf(sin(frame * 0.24)) * (2.4 if is_peggy else 1.5)

func _on_state_changed(new_state: State) -> void:
	if new_state == State.CROUCH:
		crouching = true
	elif new_state in [State.IDLE, State.WALK_F, State.WALK_B]:
		crouching = false
