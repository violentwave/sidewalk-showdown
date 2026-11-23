# TrainingController — the training-mode rules and dummy driver (GDD 6.4).
#
# One node per training match, owned by MatchRoot, ticking at physics
# priority -100 (before the fighters) exactly like CpuController: it reads
# only completed-frame state and issues the dummy's inputs through the human
# input path (Input.action_press / action_release on the dummy's own
# p<index>_* actions), so the dummy can never do anything a human could not.
# Versus and solo never create this node; every rule below is training-only.
#
# Determinism: no global RNG, no wall clock, no delta. The RANDOM block mode
# rolls its own seeded LCG (recorded in serialize(), like the CPU's), the
# dummy CPU reuses MatchRoot's recorded cpu_seed, and the record/playback
# slot is a plain frame-indexed bit array.
class_name TrainingController
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
const BIT_COUNT := 9
# Recording frame word: bits 0..8 = held actions, bit 9 = facing sign
# (1 when the dummy faced right when the frame was captured).
const FACING_BIT := 9
const RECORD_MAX_FRAMES := 600  # 10 s at 60 Hz
const DEFAULT_TRAINING_SEED := 0x54524149  # "TRAI", fixed and serialized

enum Dummy { STAND, CROUCH, JUMP, CPU_EASY, CPU_NORMAL, CPU_HARD }
enum Block { NONE, ALL, AFTER_HIT, RANDOM }
enum Toggle { OFF, ON }
enum MeterMode { NORMAL, FULL }
enum HealthMode { REFILL, HOLD }
enum ResetPos { MIDSCREEN, LEFT_CORNER, RIGHT_CORNER }

# Menu labels (single source of truth for the HUD's training tab).
const DUMMY_LABELS := ["STAND", "CROUCH", "JUMP",
	"CPU EASY", "CPU NORMAL", "CPU HARD"]
const BLOCK_LABELS := ["NONE", "ALL", "AFTER HIT", "RANDOM"]
const TOGGLE_LABELS := ["OFF", "ON"]
const METER_LABELS := ["NORMAL", "FULL"]
const HEALTH_LABELS := ["REFILL", "HOLD"]
const POSITION_LABELS := ["MIDSCREEN", "L CORNER", "R CORNER"]

var match_root: Node
var p1: FighterBase
var p2: FighterBase

# --- options (serialized) ---------------------------------------------------
var dummy := Dummy.STAND
var block := Block.NONE
var tech := Toggle.ON
var breaker := Toggle.OFF
var shakeout := Toggle.ON
var meter_mode := MeterMode.NORMAL
var health_mode := HealthMode.REFILL
var reset_pos := ResetPos.MIDSCREEN
var hitboxes := Toggle.OFF
# --- state (serialized) -----------------------------------------------------
var rng_state := 1
var after_hit_armed := false
var recording: Array[int] = []
var record_active := false
var playback_active := false
var play_index := 0
# --- transient (rebuilt from the above) -------------------------------------
var _held_bits := 0
var _seed_value := DEFAULT_TRAINING_SEED
var _tick := 0
# Per-fighter previous-frame snapshot for edge detection.
var _prev_state := [-1, -1]
var _prev_state_frame := [-1, -1]
var _prev_health := [0.0, 0.0]
var _prev_combo_active := [false, false]
var _prev_combo_hits := [0, 0]
# Readout of the last connecting move (presentation; never serialized).
var last_hit_damage := 0.0
var last_advantage := 0
var last_startup := 0
var last_move_id := ""
var last_kind := ""

# Tests drive the simulation manually and call manual_tick() themselves.
var manual_mode := false


func setup(root: Node) -> void:
	match_root = root
	p1 = match_root.p1
	p2 = match_root.p2
	# Training never samples the global RNG. If the match has no recorded CPU
	# seed, pin this deterministic default into MatchRoot's serializable field.
	if match_root.cpu_seed == 0:
		match_root.cpu_seed = DEFAULT_TRAINING_SEED
	_seed_value = match_root.cpu_seed
	rng_state = _seed_value ^ 0x5EEDBA11
	for f: FighterBase in [p1, p2]:
		f.training_min_health = 1.0
	_apply_options()


func _physics_process(_delta: float) -> void:
	if manual_mode:
		return
	tick()


func manual_tick() -> void:
	tick()


func tick() -> void:
	if p1 == null or p2 == null or match_root == null:
		return
	# Training timers, random block rolls, and recording all ride the same
	# completed sim frames as the fighters. Hitstop is a frozen frame, so it
	# must not age this controller or sample a second dummy input.
	if p1.hitstop_frames > 0 or p2.hitstop_frames > 0:
		return
	if match_root.phase != match_root.Phase.FIGHT:
		if _held_bits != 0:
			_release_all()
		return
	_tick += 1
	_maintain_fighters()
	_capture_last_hit()
	_drive_dummy()
	_snapshot_frame()


# ---------------- maintenance (training rules) ------------------------------

# Health/meter/breaker upkeep, all read from completed-frame state and applied
# before the fighters tick, so they see the maintained values this frame.
func _maintain_fighters() -> void:
	for side in 2:
		var f: FighterBase = p1 if side == 0 else p2
		# Health refill: the fighter's own RECEIVING combo just ended.
		if health_mode == HealthMode.REFILL and _prev_combo_active[side] \
				and not f.combo_tracker.active:
			f.health = f.max_health
			f.health_changed.emit(f.health, f.max_health)
		# Meter option: always full, both fighters.
		if meter_mode == MeterMode.FULL and f.meter < f.max_meter:
			f.meter = f.max_meter
			f.meter_changed.emit(f.meter, f.max_meter)
		# Breaker uses never run out (the free tier; cooldowns and the
		# once-per-combo rail are combat rules and stay).
		if f.data != null \
				and f.breaker_free_uses_left < f.data.breaker_free_per_round:
			f.breaker_free_uses_left = f.data.breaker_free_per_round


# Frame advantage / damage / startup of the last move that CONNECTED, captured
# on the stun-state entry exactly like DebugOverlay's live advantage readout:
# defender's fresh stun minus the attacker's remaining recovery.
func _capture_last_hit() -> void:
	for pair in [[p1, p2, 0, 1], [p2, p1, 1, 0]]:
		var attacker: FighterBase = pair[0]
		var defender: FighterBase = pair[1]
		var a_side: int = pair[2]
		var d_side: int = pair[3]
		var stun_state := defender.state == FighterBase.State.HITSTUN \
			or defender.state == FighterBase.State.BLOCKSTUN
		var new_hit: bool = defender.combo_tracker.hits > _prev_combo_hits[d_side]
		var state_reset: bool = defender.state != _prev_state[d_side] \
			or defender.state_frame < _prev_state_frame[d_side]
		if not stun_state or not (new_hit or state_reset):
			continue
		if attacker.state != FighterBase.State.ATTACK \
				or attacker.current_move == null:
			continue
		var on_hit := defender.state == FighterBase.State.HITSTUN
		var stun := defender.hitstun_frames if on_hit \
			else defender.blockstun_frames
		var recovery: int = maxi(0,
			attacker._move_total(attacker.current_move) - attacker.state_frame)
		last_hit_damage = maxf(0.0, _prev_health[d_side] - defender.health)
		last_advantage = stun - recovery
		last_startup = attacker.current_move.startup
		last_move_id = String(attacker.current_move.id)
		# Owner playtest fix 2026-11-23: "DMG" reads as damage; "HIT" was
		# ambiguous next to the HUD's hit terminology.
		last_kind = "DMG" if on_hit else "BLK"
		# AFTER FIRST HIT arms on a real hit on the dummy (chip does not).
		if block == Block.AFTER_HIT and not after_hit_armed \
				and d_side == 1 and on_hit:
			after_hit_armed = true


func _snapshot_frame() -> void:
	for side in 2:
		var f: FighterBase = p1 if side == 0 else p2
		_prev_state[side] = f.state
		_prev_state_frame[side] = f.state_frame
		_prev_health[side] = f.health
		_prev_combo_active[side] = f.combo_tracker.active
		_prev_combo_hits[side] = f.combo_tracker.hits


# ---------------- dummy driving ----------------------------------------------

func _drive_dummy() -> void:
	# Recording: the trainer drives the dummy through the p2 pad; capture only.
	if record_active:
		if _held_bits != 0:
			_release_all()
		_capture_recording_frame()
		return
	# CPU dummy: CpuController drives; this controller never touches inputs.
	if _is_cpu_dummy():
		if _held_bits != 0:
			_release_all()
		return
	if playback_active:
		_apply_playback_frame()
		return
	_apply_desired(_desired_dummy_bits())


func _desired_dummy_bits() -> int:
	var bits := 0
	var foe := p1
	var me := p2
	var stun_active := me.stun_active()
	# Shake-out: a fresh buffered press every other tick (the buffer edge
	# only registers on a press, and the stun tick consumes it).
	if stun_active:
		if shakeout == Toggle.ON and _tick % 2 == 0:
			bits |= 1 << A_UP
		return bits
	# Throw tech: the trainer's throw is in startup within range — press
	# grab. The dummy's own throw attempt IS the tech input (the engine's
	# own_throw rule): the incoming throw breaks it first and techs.
	if tech == Toggle.ON and foe.state == FighterBase.State.ATTACK \
			and foe.current_move != null \
			and foe.current_move.level == MoveData.Level.THROW \
			and foe.state_frame \
				< foe.current_move.startup + foe.current_move.active \
			and absf(foe.position.x - me.position.x) < 80.0:
		bits |= 1 << A_GRAB
		return bits
	# Breaker: press grab+special the moment hitstun begins.
	if breaker == Toggle.ON and me.state == FighterBase.State.HITSTUN:
		bits |= (1 << A_GRAB) | (1 << A_SPECIAL)
		return bits
	# Stance.
	match dummy:
		Dummy.CROUCH:
			bits |= 1 << A_DOWN
		Dummy.JUMP:
			bits |= 1 << A_UP
	# Blocking on top of the stance (never airborne — JUMP ignores block).
	if dummy == Dummy.STAND or dummy == Dummy.CROUCH:
		var hold_back := false
		match block:
			Block.ALL:
				hold_back = true
			Block.AFTER_HIT:
				hold_back = after_hit_armed
			Block.RANDOM:
				hold_back = _randf() < 0.5
		if hold_back:
			var away: float = FighterBase.direction_away_from(foe, me)
			if away > 0.0:
				bits |= 1 << A_RIGHT
			elif away < 0.0:
				bits |= 1 << A_LEFT
	return bits


# Issue the desired held set through the human input path, edges only. The
# belief reconciles with the live Input state first: anything else that
# touched the dummy's actions (the trainer's pad during a recording, a
# restored snapshot, a fresh match build) must never leave the controller
# pressing or releasing against a stale belief.
func _apply_desired(bits: int) -> void:
	_sync_held_bits()
	for action in BIT_COUNT:
		_press(action, (bits >> action) & 1 == 1)


func _press(action: int, held: bool) -> void:
	var was: bool = (_held_bits >> action) & 1 == 1
	if held == was:
		return
	if held:
		Input.action_press(_dummy_action(action))
		_held_bits |= 1 << action
	else:
		Input.action_release(_dummy_action(action))
		_held_bits &= ~(1 << action)


func _dummy_action(action: int) -> String:
	return "p%d_%s" % [p2.player_index, ACTIONS[action]]


func _release_all() -> void:
	# Unconditional: a hard release must clear the real Input state even if
	# the belief had drifted (external presses, restores, mode switches).
	for action in BIT_COUNT:
		Input.action_release(_dummy_action(action))
	_held_bits = 0


# True when the given action is currently held on the Input singleton.
func _sync_held_bits() -> void:
	for action in BIT_COUNT:
		var actual: bool = Input.is_action_pressed(_dummy_action(action))
		var believed: bool = (_held_bits >> action) & 1 == 1
		if actual != believed:
			if actual:
				_held_bits |= 1 << action
			else:
				_held_bits &= ~(1 << action)


func _is_cpu_dummy() -> bool:
	return dummy >= Dummy.CPU_EASY


func _randf() -> float:
	rng_state = (rng_state * 1664525 + 1013904223) & 0xFFFFFFFF
	return float(rng_state) / 4294967296.0


# ---------------- record / playback ------------------------------------------

func toggle_recording() -> void:
	if record_active:
		record_active = false
		_release_all()
		return
	playback_active = false
	_release_all()
	recording.clear()
	record_active = true


func toggle_playback() -> void:
	if playback_active:
		playback_active = false
		_release_all()
		return
	if recording.is_empty():
		return
	record_active = false
	_release_all()
	playback_active = true
	play_index = 0


func _capture_recording_frame() -> void:
	var word := 0
	for action in BIT_COUNT:
		if Input.is_action_pressed(_dummy_action(action)):
			word |= 1 << action
	if p2.facing > 0:
		word |= 1 << FACING_BIT
	recording.append(word)
	if recording.size() >= RECORD_MAX_FRAMES:
		record_active = false
		_release_all()


func _apply_playback_frame() -> void:
	var word: int = recording[play_index]
	var mirrored: bool = ((word >> FACING_BIT) & 1 == 1) != (p2.facing > 0)
	var bits := word & ((1 << BIT_COUNT) - 1)
	if mirrored:
		var left: bool = (bits >> A_LEFT) & 1 == 1
		var right: bool = (bits >> A_RIGHT) & 1 == 1
		if left != right:
			bits = (bits & ~((1 << A_LEFT) | (1 << A_RIGHT)))
			if left:
				bits |= 1 << A_RIGHT
			if right:
				bits |= 1 << A_LEFT
	_apply_desired(bits)
	play_index = (play_index + 1) % recording.size()


# ---------------- position reset ---------------------------------------------

func reset_positions() -> void:
	if match_root == null or match_root.stage == null:
		return
	var st: Node2D = match_root.stage
	var floor_y: float = st.floor_y
	var p1_x: float
	var p2_x: float
	match reset_pos:
		ResetPos.MIDSCREEN:
			p1_x = st.spawn_p1_x
			p2_x = st.spawn_p2_x
		ResetPos.LEFT_CORNER:
			p2_x = st.left_bound + 16.0
			p1_x = st.left_bound + 60.0
		ResetPos.RIGHT_CORNER:
			p2_x = st.right_bound - 16.0
			p1_x = st.right_bound - 60.0
	_release_all()
	after_hit_armed = false
	record_active = false
	playback_active = false
	play_index = 0
	p1.begin_round(Vector2(p1_x, floor_y), p2_x)
	p2.begin_round(Vector2(p2_x, floor_y), p1_x)
	# Training reset is a fresh practice start: restore both resources even
	# when Meter is in NORMAL mode.
	p1.add_meter(p1.max_meter)
	p2.add_meter(p2.max_meter)
	p1.training_min_health = 1.0
	p2.training_min_health = 1.0
	p1.health_changed.emit(p1.health, p1.max_health)
	p2.health_changed.emit(p2.health, p2.max_health)
	# begin_round restores each side to the stage's correct spawn/facing.
	if match_root.cpu_p2 != null and _is_cpu_dummy():
		match_root.cpu_p2._release_all()
	last_hit_damage = 0.0
	last_advantage = 0
	last_startup = 0
	last_move_id = ""
	last_kind = ""
	_snapshot_frame()


# ---------------- options ----------------------------------------------------

# Called on setup, on load, and whenever a menu row changes a value.
func apply_options() -> void:
	_apply_options()


func _apply_options() -> void:
	if match_root == null:
		return
	_release_all()
	# CPU dummy lifecycle: one CpuController for the dummy when the stance
	# asks for it, recorded through MatchRoot's existing cpu_p2 slot (and
	# therefore serialized with the match).
	if _is_cpu_dummy():
		record_active = false
		playback_active = false
		var level: int = dummy - Dummy.CPU_EASY
		match_root.ensure_training_cpu(level, _seed_value)
	else:
		match_root.clear_training_cpu()
	if match_root.debug_overlay != null:
		match_root.debug_overlay.show_boxes = hitboxes == Toggle.ON
	if meter_mode == MeterMode.FULL:
		for f: FighterBase in [p1, p2]:
			if f.meter < f.max_meter:
				f.meter = f.max_meter
				f.meter_changed.emit(f.meter, f.max_meter)


func option_value(row: int) -> int:
	match row:
		0:
			return dummy
		1:
			return block
		2:
			return tech
		3:
			return breaker
		4:
			return shakeout
		5:
			return meter_mode
		6:
			return health_mode
		7:
			return reset_pos
		8:
			return hitboxes
	return 0


func set_option_value(row: int, value: int) -> void:
	match row:
		0:
			dummy = value
		1:
			block = value
		2:
			tech = value
		3:
			breaker = value
		4:
			shakeout = value
		5:
			meter_mode = value
		6:
			health_mode = value
		7:
			reset_pos = value
		8:
			hitboxes = value
	_apply_options()


func option_value_count(row: int) -> int:
	match row:
		0:
			return DUMMY_LABELS.size()
		1:
			return BLOCK_LABELS.size()
		2, 3, 4, 8:
			return TOGGLE_LABELS.size()
		5:
			return METER_LABELS.size()
		6:
			return HEALTH_LABELS.size()
		7:
			return POSITION_LABELS.size()
	return 1


func option_value_label(row: int) -> String:
	var value := option_value(row)
	match row:
		0:
			return DUMMY_LABELS[value]
		1:
			return BLOCK_LABELS[value]
		2, 3, 4, 8:
			return TOGGLE_LABELS[value]
		5:
			return METER_LABELS[value]
		6:
			return HEALTH_LABELS[value]
		7:
			return POSITION_LABELS[value]
	return ""


func _exit_tree() -> void:
	_release_all()


# ---------------- save/restore -----------------------------------------------

# Everything the training rules own: options, the dummy bookkeeping, the
# record slot, and the RANDOM block LCG. The readout is presentation and is
# deliberately excluded. MatchRoot embeds this under "training".
func serialize() -> Dictionary:
	return {
		"dummy": dummy,
		"block": block,
		"tech": tech,
		"breaker": breaker,
		"shakeout": shakeout,
		"meter": meter_mode,
		"health": health_mode,
		"position": reset_pos,
		"hitboxes": hitboxes,
		"seed": _seed_value,
		"rng": rng_state,
		"tick": _tick,
		"after_hit": after_hit_armed,
		"recording": recording.duplicate(),
		"record_active": record_active,
		"playback_active": playback_active,
		"play_index": play_index,
		"last_hit_damage": last_hit_damage,
		"last_advantage": last_advantage,
		"last_startup": last_startup,
		"last_move_id": last_move_id,
		"last_kind": last_kind,
	}


func load_state(data: Dictionary) -> void:
	dummy = int(data.get("dummy", Dummy.STAND))
	block = int(data.get("block", Block.NONE))
	tech = int(data.get("tech", Toggle.ON))
	breaker = int(data.get("breaker", Toggle.OFF))
	shakeout = int(data.get("shakeout", Toggle.ON))
	meter_mode = int(data.get("meter", MeterMode.NORMAL))
	health_mode = int(data.get("health", HealthMode.REFILL))
	reset_pos = int(data.get("position", ResetPos.MIDSCREEN))
	hitboxes = int(data.get("hitboxes", Toggle.OFF))
	_seed_value = int(data.get("seed", _seed_value))
	rng_state = int(data.get("rng", rng_state))
	_tick = int(data.get("tick", _tick))
	after_hit_armed = bool(data.get("after_hit", false))
	recording.clear()
	for word in data.get("recording", []):
		recording.append(int(word))
	record_active = bool(data.get("record_active", false))
	playback_active = bool(data.get("playback_active", false))
	play_index = int(data.get("play_index", 0))
	last_hit_damage = float(data.get("last_hit_damage", 0.0))
	last_advantage = int(data.get("last_advantage", 0))
	last_startup = int(data.get("last_startup", 0))
	last_move_id = str(data.get("last_move_id", ""))
	last_kind = str(data.get("last_kind", ""))
	_apply_options()
	for f: FighterBase in [p1, p2]:
		f.training_min_health = 1.0
	_release_all()
	_snapshot_frame()
