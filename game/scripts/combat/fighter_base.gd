# FighterBase — shared fighter controller.
# Phase 1: movement, jump, crouch, facing, state machine skeleton.
# Simulation runs on fixed 60Hz physics ticks; frame counters are sim frames.
class_name FighterBase
extends CharacterBody2D

enum State {
	IDLE, WALK_F, WALK_B, CROUCH,
	JUMP_START, JUMP_RISE, JUMP_FALL, LAND,
	ATTACK, BLOCK_STAND, BLOCK_CROUCH,
	HITSTUN, BLOCKSTUN, KNOCKDOWN, WAKE_UP,
	GRAB, KO, WIN,
}

# --- Identity / tuning (data resources arrive in commit 2) ---
@export var player_index: int = 1
@export var body_color: Color = Color(0.95, 0.55, 0.15)
@export var walk_speed_fwd: float = 90.0
@export var walk_speed_back: float = 70.0
@export var jump_speed: float = 270.0
@export var gravity: float = 900.0
@export var body_width: float = 28.0
@export var body_height: float = 56.0

# --- Match context, set by MatchRoot ---
var opponent: FighterBase
var stage: Node2D
var input_enabled := true

# --- Sim state ---
var state: State = State.IDLE
var state_frame := 0
var facing := 1
var grounded := true
var crouching := false
var health := 1000
var max_health := 1000
var meter := 0.0
var hitstop_frames := 0

signal state_changed(new_state: State)

func _ready() -> void:
	$Silhouette.modulate = body_color
	$FacingMarker.modulate = body_color.lightened(0.35)
	state_changed.connect(_on_state_changed)

func begin_round(spawn_pos: Vector2, opponent_x: float) -> void:
	position = spawn_pos
	velocity = Vector2.ZERO
	grounded = true
	crouching = false
	health = max_health
	meter = 0.0
	hitstop_frames = 0
	facing = 1 if opponent_x > spawn_pos.x else -1
	_set_state(State.IDLE)
	_sync_visuals()

func _physics_process(delta: float) -> void:
	if hitstop_frames > 0:
		hitstop_frames -= 1
		return

	state_frame += 1
	var axis := _axis("left", "right")
	var down := _down()

	match state:
		State.IDLE, State.WALK_F, State.WALK_B:
			_grounded_movement(axis, down)
		State.CROUCH:
			_crouch_logic(axis)
		State.JUMP_START, State.JUMP_RISE, State.JUMP_FALL:
			_air_movement(axis, delta)
		State.LAND:
			velocity.x = 0.0
			if state_frame >= 2:
				_set_state(State.IDLE)

	_apply_gravity(delta)
	_integrate()
	if stage:
		clamp_to_stage()
		_landing_check(stage.floor_y)
	_sync_visuals()

# --- Movement ---
func _grounded_movement(axis: float, down: bool) -> void:
	if not input_enabled:
		axis = 0.0
		down = false

	_update_facing()

	if _pressed("up") and input_enabled:
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

func _crouch_logic(axis: float) -> void:
	velocity.x = 0.0
	if not _down() or not input_enabled:
		_set_state(State.IDLE)

func _air_movement(axis: float, _delta: float) -> void:
	if input_enabled:
		velocity.x = axis * walk_speed_fwd

func _apply_gravity(delta: float) -> void:
	if not grounded:
		velocity.y += gravity * delta

func _integrate() -> void:
	position += velocity * delta_fixed()

func delta_fixed() -> float:
	return 1.0 / Engine.physics_ticks_per_second

func _landing_check(floor_y: float) -> void:
	if position.y >= floor_y:
		position.y = floor_y
		velocity.y = 0.0
		if not grounded:
			grounded = true
			_set_state(State.LAND)

# --- Helpers ---
func _axis(left: String, right: String) -> float:
	if not input_enabled:
		return 0.0
	return Input.get_axis("p%d_%s" % [player_index, left], "p%d_%s" % [player_index, right])

func _pressed(action: String) -> bool:
	return input_enabled and Input.is_action_pressed("p%d_%s" % [player_index, action])

func _down() -> bool:
	return _pressed("down")

func _update_facing() -> void:
	if opponent:
		facing = 1 if opponent.position.x >= position.x else -1

func clamp_to_stage() -> void:
	if stage:
		position.x = clampf(position.x, stage.left_bound, stage.right_bound)

func pushbox_rect() -> Rect2:
	var h := body_height
	if crouching or state == State.CROUCH:
		h = body_height * 0.65
	return Rect2(position.x - body_width * 0.5, position.y - h, body_width, h)

func hurtbox_rect() -> Rect2:
	var h := body_height
	if crouching or state == State.CROUCH:
		h = body_height * 0.65
	return Rect2(position.x - body_width * 0.5, position.y - h, body_width, h)

func _set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_frame = 0
		state_changed.emit(new_state)

func _sync_visuals() -> void:
	var h := body_height
	if state == State.CROUCH or crouching:
		h = body_height * 0.65
	$Silhouette.scale.y = h / body_height
	$FacingMarker.position.x = facing * body_width * 0.5
	$FacingMarker.scale.x = facing

func _on_state_changed(new_state: State) -> void:
	if new_state == State.CROUCH:
		crouching = true
	elif new_state in [State.IDLE, State.WALK_F, State.WALK_B]:
		crouching = false
