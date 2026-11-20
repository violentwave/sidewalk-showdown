# FighterBase — shared fighter controller. Simulation = fixed 60Hz physics ticks.
class_name FighterBase
extends CharacterBody2D

@onready var visual_root: Node2D = $VisualRoot
@onready var silhouette: Polygon2D = $VisualRoot/Silhouette
@onready var facing_marker: Polygon2D = $VisualRoot/FacingMarker
@onready var character_sprite: Sprite2D = $VisualRoot/CharacterSprite
@onready var idle_sprite: Sprite2D = $VisualRoot/IdleSprite

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
# COMBO_SYSTEM_DESIGN §10.3: emitted when a Clip Cancel resolves, for the
# future HUD flash.
signal clip_cancelled

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
const CHARACTER_SPRITE_PATHS := {
	"peg_leg_peggy": "res://art/characters/peg_leg_peggy/spr_peg_leg_peggy_cutout.png",
	"whiskey_richard": "res://art/characters/whiskey_richard/spr_whiskey_richard_cutout.png",
}
# Owner-approved four-cel idle loops (Pixelorama pipeline, 0.15 s per cel).
# Shown ONLY in State.IDLE; every other state keeps the cutout/silhouette path.
const IDLE_SHEET_PATHS := {
	"peg_leg_peggy": "res://art/characters/peg_leg_peggy/spr_peg_leg_peggy_idle.png",
	"whiskey_richard": "res://art/characters/whiskey_richard/spr_whiskey_richard_idle.png",
}
const IDLE_CELLS := 4
const IDLE_CEL_DURATION := 0.15
# In-sheet feet anchor (pixel) shared by both approved sheets' manifests.
const IDLE_ANCHOR := Vector2(48, 78)
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

# Meter economy (2026-11-18): the Hype Meter is earned ONLY when an attack
# actually lands on the opponent — `meter_gain_hit` on every connecting hit
# (throws included). Blocked hits pay the attacker `meter_gain_block` times
# this scale, 0.0 by default ("meta builds only when hits land"), so a single
# edit here retunes blocked-hit income without touching MoveData. There is no
# whiff gain and no defender-side gain at all.
static var METER_GAIN_ON_BLOCK_SCALE := 0.0

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
# COMBO_SYSTEM_DESIGN §9.1 outcome flags: the resolver reports what the move
# actually did, so BLOCK/WHIFF-condition cancel routes can be authored. Both
# are cleared on every _start_move() and serialized.
var move_was_blocked := false
var move_whiffed := false
var hitstun_frames := 0
var blockstun_frames := 0
var knockdown_frames := 0
var wakeup_frames := 0
var tech_frames := 0
var landing_recovery_frames := DEFAULT_LANDING_FRAMES

var combo_hits := 0
# Clip Cancel budget (§10.3): the opponent's combo going inactive means a
# new offensive sequence may begin, so the attacker's clip returns.
var clip_cancel_used := false

# Macro (dial-a-combo) state — COMBO_SYSTEM_DESIGN §10.1, decision #3.
# The player dials a fast button sequence; the first press is a real input
# that starts the opener through the normal path, and the remaining steps
# are HELD here (with their own gap clock) and replayed into the input
# buffer exactly when the current move's cancel window opens after a hit
# confirm. No new states, no validation bypass: every replay resolves
# through the authored CHAIN/CANCEL rules like any human press.
# Serialized with the fighter; ages under the same hitstop freeze as the
# input buffer so nothing outlives the 5-frame cap.
var macro_active: StringName = &""
var macro_next_press: int = 0
var macro_pending: Array[StringName] = []
var macro_gap_frames: int = 999
var macro_replayed_this_move := false
# Public, for a later HUD: fires when a held step is replayed into the buffer.
signal macro_step_replayed(macro_name: String, step_index: int)
# COMBO_SYSTEM_DESIGN §9.5: the defender-side combo record. combo_hits stays
# in lockstep for HUD compatibility; the tracker is the source of truth for
# scaling, repeat/variety, caps, and save/restore.
var combo_tracker := ComboTracker.new()
# Airborne hits this fighter has received in the current combo (PROPOSALS §6).
var juggle_hits := 0
var frames_since_hit := 0

# --- Input buffer ---
const BUFFER_NORMAL := 5
const BUFFER_SPECIAL := 7
# COMBO_SYSTEM_DESIGN decision #8: the Clip Cancel meter burn.
const CLIP_CANCEL_COST := 25.0
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
var _character_art_scale := 0.0
# Authored idle loop state (see IDLE_SHEET_PATHS). Kept separate from the
# cutout path so the existing fallback stays intact when idle art is absent.
var _idle_art_scale := 0.0
var _idle_art_valid := false
var _idle_ticks_per_cel := 1
var _idle_sheet_tex: Texture2D

# Authored presentation clips (Peggy + Richard; see PeggyClipLibrary /
# RichardClipLibrary). Playback is a pure function of the simulation clock
# (state_frame / authored durations / the two counters below), so hitstop and
# match pause freeze it automatically, and every state/move entry restarts the
# clip deterministically.
var _clip_lib: GDScript = null
var _clip_library_valid := false
var _clip_cache: Dictionary = {}
var _active_clip: Dictionary = {}
var _transient_clip_key := ""
var _transient_clip_tick := 0
var _ko_grounded_frame := 0
# Previous sim state, captured by _set_state/_force_state before the state
# change lands, so _on_state_changed can detect crouch-exit transitions.
var _prev_state: State = State.IDLE

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
	_configure_character_sprite()

func _configure_character_sprite() -> void:
	var sprite_path := str(CHARACTER_SPRITE_PATHS.get(data.id, ""))
	if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
		character_sprite.texture = null
		character_sprite.visible = false
		silhouette.visible = true
		facing_marker.visible = true
		_character_art_scale = 0.0
		return
	character_sprite.texture = load(sprite_path) as Texture2D
	if character_sprite.texture == null:
		character_sprite.visible = false
		silhouette.visible = true
		facing_marker.visible = true
		_character_art_scale = 0.0
		return
	_character_art_scale = SILHOUETTE_HEIGHT / character_sprite.texture.get_height()
	character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	character_sprite.modulate = Color.WHITE
	character_sprite.visible = true
	silhouette.visible = false
	facing_marker.visible = false
	_configure_idle_sprite()

# Loads the fighter's authored idle sheet (if any) and validates it. Any
# failure leaves _idle_art_valid false and the existing cutout/silhouette
# fallback fully in charge - missing idle art must never hide the fighter.
func _configure_idle_sprite() -> void:
	_idle_art_valid = false
	_idle_art_scale = 0.0
	_idle_ticks_per_cel = maxi(roundi(IDLE_CEL_DURATION * Engine.physics_ticks_per_second), 1)
	if data == null or _character_art_scale <= 0.0:
		idle_sprite.visible = false
		idle_sprite.texture = null
		return
	var sheet_path := str(IDLE_SHEET_PATHS.get(data.id, ""))
	if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
		idle_sprite.visible = false
		idle_sprite.texture = null
		return
	var sheet := load(sheet_path) as Texture2D
	if sheet == null \
			or sheet.get_width() != 96 * IDLE_CELLS or sheet.get_height() != 80:
		idle_sprite.visible = false
		idle_sprite.texture = null
		return
	idle_sprite.texture = sheet
	idle_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	idle_sprite.hframes = IDLE_CELLS
	idle_sprite.centered = false
	_idle_sheet_tex = sheet
	# Map the in-sheet feet anchor onto the fighter origin (ground contact),
	# keeping the node's local x centered on the anchor so flip_h pivots the
	# art around the planted feet instead of drifting them.
	idle_sprite.offset = Vector2(-IDLE_ANCHOR.x, -IDLE_ANCHOR.y)
	idle_sprite.position = Vector2.ZERO
	# Measure the visible (opaque) bounds across all cels. Scale maps the
	# visible character height - not the padded cell height - into the same
	# SILHOUETTE_HEIGHT band the cutout path uses, so the established fighter
	# height and ground contact are preserved.
	var image := idle_sprite.texture.get_image()
	if image == null or image.is_empty():
		idle_sprite.texture = null
		return
	if image.is_compressed() and image.decompress() != OK:
		idle_sprite.texture = null
		return
	var top := int(IDLE_ANCHOR.y)
	var cel_start := Vector2i(0, 0)
	for cel in IDLE_CELLS:
		cel_start = Vector2i(cel * 96, 0)
		var used := Rect2i(0, 0, 0, 0)
		for y in range(0, 80):
			for x in range(cel_start.x, cel_start.x + 96):
				if image.get_pixel(x, y).a > 0.0:
					used = used.expand(Vector2i(x, y))
		if used.size == Vector2i.ZERO:
			idle_sprite.texture = null
			return
		top = mini(top, used.position.y)
	var visible_height := int(IDLE_ANCHOR.y) - top
	if visible_height <= 0:
		idle_sprite.texture = null
		return
	_idle_art_scale = SILHOUETTE_HEIGHT / float(visible_height)
	_idle_art_valid = true
	# Authored presentation clips piggyback on the same sprite node and only
	# activate for fighters with a clip set (Peggy, Richard). A failure here
	# leaves the fighter on the idle-loop/cutout path untouched.
	_clip_lib = _clip_library_for(data.id)
	_clip_library_valid = _clip_lib != null and _clip_lib.has_clips(data.id)
	_clip_cache.clear()
	_active_clip = {}
	_transient_clip_key = ""
	_transient_clip_tick = 0

# Returns the generated clip table for a fighter, or null when that fighter
# has no authored presentation set (they keep the approved fallback path).
func _clip_library_for(fighter_id: String) -> GDScript:
	match fighter_id:
		"peg_leg_peggy":
			return PeggyClipLibrary
		"whiskey_richard":
			return RichardClipLibrary
	return null

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
	combo_tracker.reset()
	clip_cancel_used = false
	_macro_clear()
	frames_since_hit = 0
	knockdown_frames = 0
	tech_frames = 0
	wakeup_frames = 0
	landing_recovery_frames = DEFAULT_LANDING_FRAMES
	current_move = null
	move_hit_confirmed = false
	move_already_hit = false
	input_buffer.clear()
	_active_clip = {}
	_transient_clip_key = ""
	_transient_clip_tick = 0
	_ko_grounded_frame = 0
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

	# Presentation-only counters (authored clips). Both advance on the sim
	# clock past the hitstop early-return, so hitstop and pause freeze them.
	if _transient_clip_key != "":
		_transient_clip_tick += 1
		if _transient_clip_tick > _transient_clip_duration():
			_transient_clip_key = ""
	if state == State.KO:
		_ko_grounded_frame = _ko_grounded_frame + 1 if grounded else 0

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
	_update_facing()
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

	# A whiff becomes knowable only once the active window has closed without
	# any contact: until then the move can still hit, so WHIFF rules must not
	# fire early. One flag, set once per move.
	if not move_already_hit and state_frame \
			>= current_move.startup + current_move.active:
		move_whiffed = true

	if move_hit_confirmed:
		# Macro replay first (§10.1): the held step enters the buffer so the
		# authored route below can consume it like any human press.
		if macro_active != &"" and _macro_window_open():
			_macro_replay_into_buffer()
		if _try_cancel():
			return
	elif move_was_blocked or move_whiffed:
		# Decision #3: a macro dies on block (and on whiff). The attacker
		# reads the outcome flags set by the resolver.
		if move_was_blocked or move_whiffed:
			_macro_clear()
		# COMBO_SYSTEM_DESIGN §9.1: BLOCK/WHIFF-condition routes evaluated on
		# the outcome the resolver already reported. Same starter, same buffer,
		# same validation as hit-confirm cancels.
		if _try_outcome_cancel():
			return
	# Clip Cancel (§10.3, decision #8): meter-burn out of recovery, after any
	# authored route had its chance. Universal, not per-move data — the cost
	# and limits are the approved decisions.
	if _try_clip_cancel():
		return
	if state_frame >= _move_total(current_move):
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
		_:
			pass  # Landing ends aerial attacks; all other states keep current state.

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

# COMBO_SYSTEM_DESIGN §9.1: BLOCK/WHIFF routes for the non-hit outcome. The
# counter pass is meaningless here (a blocked or whiffed move cannot counter),
# so evaluation is a single ordered pass. Whiff requires the active window to
# be over (the flag is only set then), which the window bounds control anyway.
func _try_outcome_cancel() -> bool:
	if current_move == null or not input_enabled:
		return false
	for rule: CancelRule in current_move.cancels:
		if not rule.window_open(state_frame):
			continue
		if rule.condition == CancelRule.Condition.BLOCK and move_was_blocked:
			if _run_cancel(rule):
				return true
		elif rule.condition == CancelRule.Condition.WHIFF and move_whiffed:
			if _run_cancel(rule):
				return true
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

# Clip Cancel (COMBO_SYSTEM_DESIGN §10.3, decision #8): spend 25 meter to
# cancel out of the CURRENT move's recovery to neutral. Recovery-only —
# never during startup or active frames. Input shape: special + grab
# buffered together (the same two-button style as the EX modifier). Once
# per combo. It is the first utility meter sink in the landed-hits
# economy: make a blocked heavy safe, or shortcut recovery into pressure.
func _try_clip_cancel() -> bool:
	if current_move == null or state != State.ATTACK or not input_enabled:
		return false
	if clip_cancel_used:
		return false
	# Recovery-only: past the authored active window.
	if state_frame < current_move.startup + current_move.active:
		return false
	if not (input_buffer.has("special") and input_buffer.has("grab")):
		return false
	if meter + 0.001 < CLIP_CANCEL_COST:
		return false
	_consume("special", BUFFER_SPECIAL)
	_consume("grab", BUFFER_GRAB)
	spend_meter(CLIP_CANCEL_COST)
	clip_cancel_used = true
	current_move = null
	move_hit_confirmed = false
	move_already_hit = false
	move_was_blocked = false
	move_whiffed = false
	velocity.x = 0.0
	_force_state(State.JUMP_FALL if not grounded else State.IDLE)
	clip_cancelled.emit()
	return true

func _start_move(move: MoveData) -> void:
	current_move = move
	move_hit_confirmed = false
	move_already_hit = false
	move_counter_hit = false
	move_was_blocked = false
	move_whiffed = false
	macro_replayed_this_move = false
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

# Whiffs earn nothing (2026-11-18 meter economy): meter_gain_whiff stays
# authored data on MoveData but is never awarded anywhere, so the B6
# landing-whiff repair that once awarded it here is obsolete by design.

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
# Back-hold for blocking is measured against the ATTACKER's side at the
# moment of impact (direction_away_from), never against the defender's own
# facing: a cross-up that lands behind the defender is blocked by holding the
# other way, regardless of which way the defender is currently facing. With
# no attacker supplied this falls back to the opponent.
func is_holding_away_from(attacker: FighterBase = null) -> bool:
	if not input_enabled:
		return false
	var other := attacker if attacker != null else opponent
	if other == null:
		return false
	var axis := _axis("left", "right")
	return axis != 0.0 and signf(axis) == FighterBase.direction_away_from(other, self)

func is_blocking(attacker: FighterBase = null) -> bool:
	if not grounded:
		return false
	# Authored extended LAND is a whiff-recovery commitment: unlike the legacy
	# 2-frame landing state, it cannot be cancelled into block by holding back.
	if state == State.LAND and landing_recovery_frames > DEFAULT_LANDING_FRAMES:
		return false
	# BLOCKSTUN is intentionally allowed: holding away must keep blocking
	# successive hits in a blockstring, measured against each attacker's side.
	if state in [State.ATTACK, State.HITSTUN, State.KNOCKDOWN, State.WAKE_UP, State.TECH, State.KO]:
		return false
	return is_holding_away_from(attacker)

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
		# Rule F: a throw connects only in front of the thrower (equal x
		# counts as in front). Behind the thrower it whiffs outright — and a
		# whiff cannot be tech'd, so this check runs before the tech gate.
		if not is_in_front_of(attacker, self):
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
		# Meter is earned only by landed hits: a blocked hit pays the attacker
		# meter_gain_block * METER_GAIN_ON_BLOCK_SCALE (0.0 by default), and the
		# defender gains nothing for blocking or being blocked against.
		# The resolver reports the blocked contact on the attacker (§9.1):
		# BLOCK-condition cancel routes read this, exactly as hit-confirm
		# routes read move_hit_confirmed.
		attacker.move_was_blocked = true
		attacker.add_meter(move.meter_gain_block * METER_GAIN_ON_BLOCK_SCALE)
		blockstun_frames = move.blockstun
		hitstop_frames = maxi(hitstop_frames, move.hitstop)
		attacker.hitstop_frames = maxi(attacker.hitstop_frames, move.hitstop)
		var block_dir := FighterBase.direction_away_from(attacker, self)
		velocity.x = block_dir * move.block_pushback
		# §6 corner rule: a defender pinned against a stage bound cannot take
		# the blocked pushback; the displacement transfers to the attacker,
		# away from the defender, subject to the attacker's own bound.
		if _pinned_at_stage_wall(velocity.x):
			attacker.velocity.x = -block_dir * move.block_pushback
			velocity.x = 0.0
		combo_hits = 0
		combo_tracker.reset()
		combo_changed.emit(0)
		_force_state(State.BLOCKSTUN)
		_emit_health()
		return false

	# COMBO_SYSTEM_DESIGN §9.3: damage is data. The scale is the defender's
	# tuning ladder x repeat penalty x variety bonus (capped at 1.0), then the
	# per-combo damage cap clamps the remaining budget; past the hit cap a hit
	# still connects but pays nothing.
	var scaled := _combo_damage_for(move)
	health = maxf(0.0, health - scaled)
	combo_hits += 1
	frames_since_hit = 0
	combo_tracker.record(move.id, scaled)
	combo_changed.emit(combo_hits)
	# The clean-hit award: the only place meter is earned (attacker, landed
	# hit, per connecting move — throws included). The defender gains nothing.
	# Decision #2: from the second hit of a combo on, the award is scaled
	# (x0.5 by default, floored) so long strings trend toward the next EX
	# without refunding their own extension.
	attacker.add_meter(move.meter_gain_hit * _combo_meter_multiplier())
	var stop := move.hitstop + (COUNTER_HIT_HITSTOP if counter else 0)
	hitstop_frames = maxi(hitstop_frames, stop)
	attacker.hitstop_frames = maxi(attacker.hitstop_frames, stop)
	attacker.move_counter_hit = counter
	if counter:
		attacker.counter_hit_landed.emit()

	hit_flash_frames = HIT_FLASH_FRAMES
	_update_silhouette_flash()
	var dir := FighterBase.direction_away_from(attacker, self)
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
		var stun: int = move.hitstun
		# COMBO_SYSTEM_DESIGN §9.3: air hitstun decays per air hit taken, so
		# late juggle hits cannot re-launch loops; floored at the tuning value.
		if was_airborne:
			var t: ComboTuning = _combo_tuning()
			stun = maxi(t.air_hitstun_floor, int(round(move.hitstun
				* pow(t.air_hitstun_decay, float(juggle_hits)))))
		hitstun_frames = stun
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
	# Separate the tech pair away from the attacker through the shared side
	# helper: positions decide, and at exactly equal x the defender (standing
	# in front of the attacker) is pushed out the attacker's facing.
	var dir := direction_away_from(other, self) if other else -float(facing)
	var push := dir * (20.0 / float(dur)) / delta_fixed()
	velocity = Vector2(push, 0.0)
	if other and other != self:
		other.velocity = Vector2(-push, 0.0)
	teched.emit()
	if other and other != self:
		other.teched.emit()

# The per-hit damage through the defender's ComboTuning and ComboTracker
# record: ladder by hit position, repeat-move penalty beyond the freebies,
# variety bonus for three distinct moves in a row, all capped at 1.0; the
# per-combo damage cap clamps the remaining budget; the hit cap zeroes
# damage past combo_hit_cap. Replaces the legacy hardcoded ladder with the
# identical numbers as data (decision #4).
func _combo_damage_for(move: MoveData) -> float:
	# METHtalities are full-meter finishers, not combo parts: no scaling, no
	# caps. The cap exists to bound authored strings; a finisher that leaves
	# the opponent alive would be a design bug (and combat_test pins the KO).
	if move.meth:
		return move.damage
	var t: ComboTuning = _combo_tuning()
	var hit_index: int = combo_hits + 1
	var scale: float = t.ladder_for(hit_index)
	var used: int = combo_tracker.count_of(move.id)
	if used > t.repeat_freebies:
		scale *= pow(t.repeat_penalty, float(used - t.repeat_freebies))
	if combo_tracker.last_three_distinct(move.id):
		scale = minf(scale * (1.0 + t.variety_bonus), 1.0)
	var dmg: float = move.damage * scale
	if hit_index > t.combo_hit_cap:
		return 0.0
	return clampf(dmg, 0.0, maxf(0.0, t.combo_damage_cap - combo_tracker.total_damage))

# Decision #2: full award on the combo opener, x0.5 from the second hit on,
# the multiplier itself never below the floor. Called after the combo_hits
# increment, so the opener is combo_hits == 1 and the ladder position of
# this hit is combo_hits itself.
func _combo_meter_multiplier() -> float:
	var t: ComboTuning = _combo_tuning()
	if combo_hits <= 1:
		return 1.0
	return maxf(t.meter_gain_floor,
		t.meter_gain_in_combo * t.ladder_for(combo_hits))

func _combo_tuning() -> ComboTuning:
	if data != null and data.combo_tuning != null:
		return data.combo_tuning
	return _default_combo_tuning

# ---------------- Macros (dial-a-combos, §10.1) --------------------

# Called from _poll_input for every freshly pressed action. A press that
# extends (or starts) an authored macro sequence is captured here; the
# press itself still enters the normal input buffer exactly as any human
# press would.
func _macro_on_press(action: String) -> void:
	if data == null or data.macros.is_empty():
		return
	if macro_active == &"":
		for macro: MacroData in data.macros:
			if macro.steps.size() >= 2 and StringName(action) == macro.steps[0]:
				macro_active = macro.id
				macro_next_press = 1
				macro_gap_frames = 0
				return
	else:
		for macro: MacroData in data.macros:
			if macro.id == macro_active:
				if macro_next_press < macro.steps.size() \
						and StringName(action) == macro.steps[macro_next_press] \
						and macro_pending.size() < macro.steps.size():
					macro_pending.append(macro.steps[macro_next_press])
					macro_next_press += 1
					macro_gap_frames = 0
				return

# Ages the dial-ahead ring under the same hitstop freeze as the input
# buffer, so held steps can never outlive the buffered-input window rules.
func _macro_tick_ages(frozen: bool) -> void:
	if macro_active == &"":
		return
	if frozen:
		return
	macro_gap_frames += 1
	for macro: MacroData in data.macros:
		if macro.id == macro_active:
			if macro_gap_frames > macro.max_gap_frames:
				_macro_clear()
			return

# A dial press was captured; the only way it becomes gameplay is a later
# replay into the buffer after a hit confirm inside the authored cancel
# window. One replay per move.
func _macro_replay_into_buffer() -> void:
	if macro_pending.is_empty() or macro_replayed_this_move:
		return
	macro_replayed_this_move = true
	var action: StringName = macro_pending.pop_front()
	input_buffer[action] = 0
	var display := ""
	for macro: MacroData in data.macros:
		if macro.id == macro_active:
			display = macro.display_name
			break
	macro_step_replayed.emit(display, macro_next_press - macro_pending.size() - 1)
	if macro_pending.is_empty():
		_macro_clear()

func _macro_clear() -> void:
	macro_active = &""
	macro_next_press = 0
	macro_pending.clear()
	macro_gap_frames = 999

# True when any authored cancel window of the current move is open — the
# replay target. Macros ride authored routes only.
func _macro_window_open() -> bool:
	if current_move == null:
		return false
	for rule: CancelRule in current_move.cancels:
		if rule.window_open(state_frame):
			return true
	return false

# Shared fallback so a fighter without an authored .tres still uses the
# approved defaults rather than engine literals.
static var _default_combo_tuning := ComboTuning.new()

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
	combo_tracker.reset()
	clip_cancel_used = false
	_macro_clear()
	juggle_hits = 0
	frames_since_hit = 0
	input_buffer.clear()
	grounded = true
	hit_flash_frames = 0
	block_flash_frames = 0
	# Presentation-clip playback state is fully reset with the match.
	_active_clip = {}
	_transient_clip_key = ""
	_transient_clip_tick = 0
	_ko_grounded_frame = 0
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
			# Macro dial capture: a fresh press can start or extend an
			# authored sequence (§10.1). The press itself stays in the buffer.
			_macro_on_press(action)
	if freeze_buffer_ages:
		_macro_tick_ages(true)
		return
	_macro_tick_ages(false)
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
	# Clip Cancel budget (§10.3): the opponent's combo going inactive means a
	# new offensive sequence may begin, so the attacker's clip returns.
	if opponent != null and clip_cancel_used and not opponent.combo_tracker.active:
		clip_cancel_used = false
	if combo_hits > 0 and frames_since_hit > 40 and state not in [State.HITSTUN, State.KNOCKDOWN]:
		# Combo end: the §6 juggle counter only resets with the combo.
		combo_hits = 0
		combo_tracker.reset()
		juggle_hits = 0
		combo_changed.emit(0)

# ---------------- Misc ----------------
# Facing is derived from the opponent's position, never stored per player. It
# may only change in a grounded neutral state: idle, walking, or crouching.
# Attacks, stun, knockdown, wake-up, tech, landing recovery, and airborne states
# freeze it so a move cannot flip halfway through; the flip lands on the first
# neutral frame. A deadzone with hysteresis (see facing_deadzone_px below)
# keeps two fighters standing inside each other from flickering left and
# right every frame: inside the band the current facing is kept.
func can_auto_turn() -> bool:
	return grounded and state in [State.IDLE, State.WALK_F, State.WALK_B,
		State.CROUCH]

# How far past the opponent's center (px) a fighter must be before it turns.
# Symmetric band = hysteresis: once facing right, a fighter keeps facing right
# until the opponent is more than this far to the left. Set to 0 for the
# deadzone-free legacy behavior.
@export var facing_deadzone_px := 4.0

func _update_facing() -> void:
	if opponent == null or not can_auto_turn():
		return
	var delta := opponent.position.x - position.x
	if absf(delta) <= facing_deadzone_px:
		return
	facing = 1 if delta > 0.0 else -1

# ====================== shared side helper ======================
# relative_side() is the ONE side primitive; every system that needs to know
# where the attacker stands relative to the defender (block axis, knockback,
# pushback, throw side, tech separation) derives from it. Positions decide;
# at exactly equal x the defender is treated as standing in front of the
# attacker, which makes the attacker's relative side the negation of its
# facing. Deterministic: no RNG, no per-frame delta, no node/player order.
# Returns +1 when the attacker stands to the defender's right, -1 when to
# the defender's left.
static func relative_side(attacker: FighterBase, defender: FighterBase) -> float:
	if attacker == null or defender == null:
		return 0.0
	if attacker.position.x > defender.position.x:
		return 1.0
	if attacker.position.x < defender.position.x:
		return -1.0
	return -float(attacker.facing)

# Direction the defender moves to get away from the attacker (+1 right,
# -1 left). At equal x this is the attacker's facing: the defender, standing
# in front of the attacker, is pushed out the front.
static func direction_away_from(attacker: FighterBase, defender: FighterBase) -> float:
	return -relative_side(attacker, defender)

# True when `target` stands in front of `attacker` (on the side `attacker`
# faces). At exactly equal x the target counts as in front.
static func is_in_front_of(attacker: FighterBase, target: FighterBase) -> bool:
	if attacker == null or target == null:
		return false
	return target.position.x == attacker.position.x \
		or relative_side(target, attacker) == float(attacker.facing)

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

# Serialize the full fighter state. Non-serializable internals (scene nodes,
# opponent reference, audio components, visual clip cache) are intentionally
# excluded. current_move references the authored MoveData resource; the
# reference is preserved so the move definition (hitboxes, frames, etc.) stays
# intact.
func serialize() -> Dictionary:
	var data := {
		"state": state,
		"state_frame": state_frame,
		"facing": facing,
		"grounded": grounded,
		"crouching": crouching,
		"health": health,
		"max_health": max_health,
		"meter": meter,
		"max_meter": max_meter,
		"hitstop_frames": hitstop_frames,
		"hitstop_buffer_freeze_frames": hitstop_buffer_freeze_frames,
		"current_move": current_move,
		"move_hit_confirmed": move_hit_confirmed,
		"move_already_hit": move_already_hit,
		"move_counter_hit": move_counter_hit,
		"move_was_blocked": move_was_blocked,
		"move_whiffed": move_whiffed,
		"hitstun_frames": hitstun_frames,
		"blockstun_frames": blockstun_frames,
		"knockdown_frames": knockdown_frames,
		"wakeup_frames": wakeup_frames,
		"tech_frames": tech_frames,
		"landing_recovery_frames": landing_recovery_frames,
		"combo_hits": combo_hits,
		"combo_tracker": combo_tracker.serialize(),
		"clip_cancel_used": clip_cancel_used,
		"macro_active": String(macro_active),
		"macro_next_press": macro_next_press,
		"macro_pending": macro_pending,
		"macro_gap_frames": macro_gap_frames,
		"macro_replayed_this_move": macro_replayed_this_move,
		"juggle_hits": juggle_hits,
		"frames_since_hit": frames_since_hit,
		"input_buffer": input_buffer,
		"input_history": input_history,
	}
	return data

# Load the fighter state from a dictionary produced by serialize().
func load(data: Dictionary) -> void:
	state = data["state"]
	state_frame = data["state_frame"]
	facing = data["facing"]
	grounded = data["grounded"]
	crouching = data["crouching"]
	health = data["health"]
	max_health = data["max_health"]
	meter = data["meter"]
	max_meter = data["max_meter"]
	hitstop_frames = data["hitstop_frames"]
	hitstop_buffer_freeze_frames = data["hitstop_buffer_freeze_frames"]
	current_move = data["current_move"]
	move_hit_confirmed = data["move_hit_confirmed"]
	move_already_hit = data["move_already_hit"]
	move_counter_hit = data["move_counter_hit"]
	move_was_blocked = data.get("move_was_blocked", false)
	move_whiffed = data.get("move_whiffed", false)
	hitstun_frames = data["hitstun_frames"]
	blockstun_frames = data["blockstun_frames"]
	knockdown_frames = data["knockdown_frames"]
	wakeup_frames = data["wakeup_frames"]
	tech_frames = data["tech_frames"]
	landing_recovery_frames = data["landing_recovery_frames"]
	combo_hits = data["combo_hits"]
	juggle_hits = data["juggle_hits"]
	if typeof(data.get("combo_tracker")) == TYPE_DICTIONARY:
		combo_tracker.load_state(data["combo_tracker"])
	clip_cancel_used = data.get("clip_cancel_used", false)
	macro_active = StringName(data.get("macro_active", ""))
	macro_next_press = data.get("macro_next_press", 0)
	macro_pending.clear()
	for entry in data.get("macro_pending", []):
		macro_pending.append(StringName(entry))
	macro_gap_frames = data.get("macro_gap_frames", 999)
	macro_replayed_this_move = data.get("macro_replayed_this_move", false)
	frames_since_hit = data["frames_since_hit"]
	input_buffer = data["input_buffer"]
	input_history = data["input_history"]

func _pushbox_height() -> float:
	return body_height * (0.65 if (crouching or state == State.CROUCH) else 1.0)

func pushbox_rect() -> Rect2:
	var h := _pushbox_height()
	return Rect2(position.x - body_width * 0.5, position.y - h, body_width, h)

func hurtbox_rect() -> Rect2:
	return pushbox_rect()

func _set_state(new_state: State) -> void:
	if new_state != state:
		_prev_state = state
		state = new_state
		state_frame = 0
		state_changed.emit(new_state)

func _force_state(new_state: State) -> void:
	_prev_state = state
	state = new_state
	state_frame = 0
	state_changed.emit(new_state)

func _update_silhouette_flash() -> void:
	# Hit flash is the strong white; block flash is a subtle lightening only.
	# The authored sheet art takes the same modulate as the legacy cutout so
	# hit/block feedback stays visible no matter which artwork is showing.
	if hit_flash_frames > 0:
		silhouette.modulate = Color(1.0, 1.0, 1.0)
		character_sprite.modulate = Color(1.35, 1.35, 1.35)
		idle_sprite.modulate = Color(1.35, 1.35, 1.35)
	elif block_flash_frames > 0:
		silhouette.modulate = body_color.lightened(0.35)
		character_sprite.modulate = Color(1.12, 1.12, 1.12)
		idle_sprite.modulate = Color(1.12, 1.12, 1.12)
	else:
		silhouette.modulate = body_color
		character_sprite.modulate = Color.WHITE
		idle_sprite.modulate = Color.WHITE

func _sync_visuals() -> void:
	var h := _pushbox_height()
	silhouette.scale.y = h / SILHOUETTE_HEIGHT
	if character_sprite.visible and character_sprite.texture:
		var height_scale := h / SILHOUETTE_HEIGHT
		character_sprite.scale = Vector2(_character_art_scale,
			_character_art_scale * height_scale)
		character_sprite.position = Vector2(0.0, -h * 0.5)
		character_sprite.flip_h = facing < 0
	facing_marker.position.x = facing * body_width * 0.5
	facing_marker.scale.x = facing
	facing_marker.position.y = -h + 8.0
	visual_root.position = Vector2.ZERO
	visual_root.rotation = 0.0
	visual_root.scale = Vector2.ONE
	_update_idle_display()
	_apply_state_animation()

# Exactly one character-art visual is visible at a time. The authored sheet
# shows the four-cel loop in State.IDLE, and cel 0 as static artwork in every
# other state that has no authored clip, so the fighter never swaps back to the
# clashing legacy cutout. For fighters with a clip set (Peggy) the matching
# authored clip plays instead; any missing/gated clip falls back to that same
# static cel-0 artwork. The cutout/silhouette path below remains the emergency
# fallback when the idle sheet is missing or invalid.
func _update_idle_display() -> void:
	var sheet_active := _idle_art_valid and _character_art_scale > 0.0
	idle_sprite.visible = sheet_active
	character_sprite.visible = not sheet_active and _character_art_scale > 0.0
	if not sheet_active:
		return
	_active_clip = _resolve_visual_clip() if _clip_library_valid else {}
	if not _active_clip.is_empty():
		_display_clip(_active_clip)
		return
	_display_idle_art()

# Renders the approved idle sheet: the loop in IDLE, cel 0 elsewhere.
func _display_idle_art() -> void:
	if state == State.IDLE:
		# Idle cel timing lives on the simulation clock: state_frame only
		# advances past the hitstop early-return, so hitstop and match pause
		# freeze the loop, and _set_state(IDLE) resetting state_frame to 0
		# restarts at cel 0.
		idle_sprite.frame = (state_frame / _idle_ticks_per_cel) % IDLE_CELLS
	else:
		# Static first cel for every non-idle placeholder state: same scale,
		# anchor, filtering, and facing as the loop, so transitions never
		# change character size, ground placement, or artwork.
		idle_sprite.frame = 0
	# Restore the idle sheet's geometry; a previous clip display may have
	# swapped texture, cel count, or anchor.
	if idle_sprite.texture != _idle_sheet_tex:
		idle_sprite.texture = _idle_sheet_tex
		idle_sprite.hframes = IDLE_CELLS
		idle_sprite.offset = Vector2(-IDLE_ANCHOR.x, -IDLE_ANCHOR.y)
	var height_scale := _pushbox_height() / SILHOUETTE_HEIGHT
	idle_sprite.scale = Vector2(_idle_art_scale, _idle_art_scale * height_scale)
	idle_sprite.flip_h = facing < 0

# ---------------- Authored presentation clips ----------------
# Selects the authored clip for the current simulation state. Pure lookup on
# sim state — no timers — so playback restarts on every state/move entry
# (including repeated use of the same attack) and survives determinism.
func _resolve_visual_clip() -> Dictionary:
	if not _clip_library_valid:
		return {}
	if _transient_clip_key != "":
		var transient: Dictionary = _clip_lib.state_clip(_transient_clip_key)
		# A gated transient (e.g. Peggy's crouch-down art) falls through to the
		# normal state resolution instead of flashing the idle sheet.
		if not transient.is_empty():
			return transient
	# Authored guard presentation: holding back while stationary (pinned against
	# a wall) or crouch-blocking shows the guard pose instead of a frozen walk
	# cel. This is presentation only — blocking, movement, and pushback are
	# decided by the simulation exactly as before.
	if bool(_clip_lib.GUARD_POSE) and grounded and is_holding_away_from() \
			and state in [State.IDLE, State.WALK_B, State.CROUCH]:
		if _down() or state == State.CROUCH:
			return _clip_lib.state_clip("block_crouch")
		if state == State.IDLE or _pinned_at_stage_wall(velocity.x):
			return _clip_lib.state_clip("block_stand")
	match state:
		State.ATTACK:
			if current_move == null:
				return {}
			return _clip_lib.move_clip(current_move.id)
		State.WALK_F:
			return _clip_lib.state_clip("walk_f")
		State.WALK_B:
			return _clip_lib.state_clip("walk_b")
		State.CROUCH:
			return _clip_lib.state_clip("crouch")
		State.JUMP_START:
			return _clip_lib.state_clip("jump_start")
		State.JUMP_RISE:
			return _clip_lib.state_clip("jump_rise")
		State.JUMP_FALL:
			return _clip_lib.state_clip("jump_fall")
		State.LAND:
			return _clip_lib.state_clip("land")
		State.BLOCK_STAND:
			return _clip_lib.state_clip("block_stand")
		State.BLOCK_CROUCH:
			return _clip_lib.state_clip("block_crouch")
		State.HITSTUN:
			if not grounded:
				return _clip_lib.state_clip("hitstun_air")
			return _clip_lib.state_clip(
				"hitstun_crouch" if (crouching or _down()) else "hitstun_stand")
		State.BLOCKSTUN:
			return _clip_lib.state_clip(
				"blockstun_crouch" if (crouching or _down()) else "blockstun_stand")
		State.KNOCKDOWN:
			return _clip_lib.state_clip("knockdown")
		State.WAKE_UP:
			return _clip_lib.state_clip("wake_up")
		State.TECH:
			return _clip_lib.state_clip("tech")
		State.KO:
			return _clip_lib.state_clip("ko_air" if not grounded else "ko_ground")
		State.WIN:
			return _clip_lib.state_clip("win")
		_:
			return {}

# Length of the active transient one-shot in sim ticks: the clip's authored cel
# count times the library's per-cel cadence. Purely a presentation counter, so a
# transient never outlives its art and never delays a state transition.
func _transient_clip_duration() -> int:
	var tclip: Dictionary = _clip_lib.state_clip(_transient_clip_key)
	if tclip.is_empty():
		return 12
	var ticks := int(_clip_lib.TRANSIENTS.get(_transient_clip_key, {}).get("ticks", 6))
	return maxi(int(tclip.frames), 1) * maxi(ticks, 1)

func _clip_texture(clip: Dictionary) -> Texture2D:
	var path := str(clip.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex == null or tex.get_width() % int(clip.frames) != 0 or tex.get_height() <= 0:
		return null
	return tex

# Frames advance strictly on the simulation clock. One-shots are fitted to
# their authored state durations and clamp to the final cel; they never delay
# gameplay, and grounded KO holds its last (downed) pose instead of looping.
# A clip may declare an explicit cel order (`cels`) when its draft strip is
# authored in a different pose order than the state expects; gameplay timing
# still comes from the state counters.
func _clip_frame(clip: Dictionary) -> int:
	var count := _clip_cel_count(clip)
	if state == State.ATTACK and current_move != null:
		return _attack_clip_frame(current_move, count)
	var idx := count - 1
	match state:
		State.LAND:
			idx = _fitted_frame(count, landing_recovery_frames)
		State.KNOCKDOWN:
			idx = _fitted_frame(count, knockdown_frames)
		State.WAKE_UP:
			idx = _fitted_frame(count, wakeup_frames)
		State.TECH:
			idx = _fitted_frame(count, tech_frames)
		State.HITSTUN:
			idx = _fitted_frame(count, hitstun_frames)
		State.BLOCKSTUN:
			idx = _fitted_frame(count, blockstun_frames)
		State.KO:
			if not grounded:
				idx = mini(state_frame / _clip_lib.ONESHOT_CEL_TICKS["ko_air"], count - 1)
			else:
				idx = mini(_ko_grounded_frame / _clip_lib.ONESHOT_CEL_TICKS["ko_ground"], count - 1)
		State.JUMP_START:
			idx = mini(state_frame / _clip_lib.ONESHOT_CEL_TICKS["jump_start"], count - 1)
		State.JUMP_RISE:
			idx = mini(state_frame / _clip_lib.ONESHOT_CEL_TICKS["jump_rise"], count - 1)
		State.JUMP_FALL:
			idx = mini(state_frame / _clip_lib.ONESHOT_CEL_TICKS["jump_fall"], count - 1)
		State.WALK_F, State.WALK_B:
			# Locomotion loops: a clamped walk used to freeze on its last cel and
			# read as a slider. Wrapping keeps the cycle moving for as long as the
			# direction is held.
			var walk_key := "walk_f" if state == State.WALK_F else "walk_b"
			var walk_ticks := int(_clip_lib.LOOP_CEL_TICKS.get(walk_key, 6))
			idx = (state_frame / walk_ticks) % count
		State.CROUCH, State.WIN, State.BLOCK_STAND, State.BLOCK_CROUCH:
			var key := "crouch"
			if state == State.WIN:
				key = "win"
			elif state in [State.BLOCK_STAND, State.BLOCK_CROUCH]:
				key = "block_stand"
			var ticks := int(_clip_lib.LOOP_CEL_TICKS.get(key, 8))
			idx = (state_frame / ticks) % count
		_:
			idx = mini(state_frame / 6, count - 1)
	return _cel_for(clip, idx)

# Number of cels the renderer plays for a clip. Normally the sheet's cel count;
# an explicit `cels` order can play fewer cels (e.g. hold only the airborne cel).
func _clip_cel_count(clip: Dictionary) -> int:
	var cels: Array = clip.get("cels", [])
	return int(clip.frames) if cels.is_empty() else cels.size()

# Maps a playback index onto the clip's authored cel index.
func _cel_for(clip: Dictionary, index: int) -> int:
	var cels: Array = clip.get("cels", [])
	if cels.is_empty():
		return index
	return int(cels[clampi(index, 0, cels.size() - 1)])

# Evenly distributes n cels across `duration` sim ticks (duration <= 0 clamps
# to cel 0). Pure integer math; never adds simulation ticks.
func _fitted_frame(n: int, duration: int) -> int:
	if n <= 1:
		return 0
	var span := maxi(duration, 1)
	return clampi(n * state_frame / span, 0, n - 1)

# Attack cels map onto the authored startup/active/recovery phases. Cel counts
# are allocated proportionally (ceil for nonzero phases, 0 for zero-length
# phases), and the within-phase cel is floor-divided across the phase length,
# so impact poses land on the actual active frames.
func _attack_clip_frame(move: MoveData, n: int) -> int:
	var s := move.startup
	var a := move.active
	var r := move.recovery
	var total := maxi(s + a + r, 1)
	var n_s := maxi(1, roundi(n * float(s) / total)) if s > 0 else 0
	var n_a := maxi(1, roundi(n * float(a) / total)) if a > 0 else 0
	var n_r := maxi(1, roundi(n * float(r) / total)) if r > 0 else 0
	while n_s + n_a + n_r > n:
		if n_r > n_a and n_r > n_s:
			n_r -= 1
		elif n_s > n_a:
			n_s -= 1
		elif n_r > 1:
			n_r -= 1
		elif n_s > 1:
			n_s -= 1
		elif n_a > 1:
			n_a -= 1
		else:
			break
	if state_frame < s:
		return mini(n_s * state_frame / maxi(s, 1), maxi(n_s - 1, 0))
	if state_frame < s + a and n_a > 0:
		var off := state_frame - s
		return n_s + mini(n_a * off / maxi(a, 1), n_a - 1)
	var off_r := state_frame - (s + a)
	return mini(n_s + n_a + n_r * off_r / maxi(r, 1), maxi(n - 1, 0))

# Shows an authored clip on the shared art sprite. Scale derives from the
# idle sheet's own scale so a clip's standing figure is exactly as tall on
# screen as the idle artwork's standing figure (no size jump between the
# loop, the static fallback, and any authored clip); the art already carries
# the pose, so no procedural squash is applied on top.
func _display_clip(clip: Dictionary) -> void:
	var tex := _clip_texture(clip)
	if tex == null:
		# Missing/invalid clip: fall back to the idle sheet path below.
		_active_clip = {}
		_display_idle_art()
		return
	if idle_sprite.texture != tex:
		idle_sprite.texture = tex
		idle_sprite.hframes = int(clip.frames)
		idle_sprite.vframes = 1
		idle_sprite.offset = -Vector2(clip.anchor)
	idle_sprite.frame = _clip_frame(clip)
	var s: float = _idle_art_scale * float(_clip_lib.STANDING_REFERENCE_H_REF) / float(clip.h_ref)
	idle_sprite.scale = Vector2(s, s)
	idle_sprite.flip_h = facing < 0

func _apply_state_animation() -> void:
	# Authored clips carry their own pose and timing: when one is displaying,
	# the obsolete procedural bob/squash/pose transforms stay off so the two
	# animations can never double up. Hit/block flashes, EX tint, facing flip,
	# and camera effects are untouched (they modulate, not transform).
	if not _active_clip.is_empty():
		return
	# First-pass, render-only motion on the placeholder shapes. All animation is
	# attached to VisualRoot, so it never moves the fighter body or combat boxes.
	var is_peggy := data != null and data.id == "peg_leg_peggy"
	var frame := float(state_frame)
	match state:
		State.IDLE:
			# Authored idle art replaces the old whole-body breathing bob: with
			# the sheet active the loop itself carries the motion, so VisualRoot
			# stays at rest and the feet never drift.
			if _idle_art_valid:
				return
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
	var was_crouch := _prev_state == State.CROUCH
	if new_state == State.CROUCH:
		crouching = true
	elif new_state in [State.IDLE, State.WALK_F, State.WALK_B]:
		crouching = false
	# Presentation-clip bookkeeping: authored entry/exit transients play on the
	# crouch transition; every other entry clears any transient, and KO restarts
	# its grounded counter. These keys are presentation only — crouch is still
	# instantaneous in the simulation.
	if _clip_library_valid:
		if new_state == State.CROUCH:
			_transient_clip_key = "crouch_down_transient"
			_transient_clip_tick = 0
		elif was_crouch and new_state == State.IDLE:
			_transient_clip_key = "crouch_up_transient"
			_transient_clip_tick = 0
		else:
			_transient_clip_key = ""
			_transient_clip_tick = 0
		if new_state == State.KO:
			_ko_grounded_frame = 0
