# Combo system suite. Phase 1: legacy pins, blocked/whiff cancel conditions,
# Clip Cancel, macros, data-driven scaling, caps, meter-in-combo, and combo
# state save/restore + determinism.
# Run: godot --headless --path game --script res://tests/combo_test.gd
#
# The simulation is stepped manually (mirroring the engine's physics
# priorities); each step yields one real engine physics tick so Input's
# just_pressed semantics match live play — same harness contract as
# cpu_test.gd (see docs/CPU_OPPONENT.md §7).
extends SceneTree

const PEGGY := "res://resources/fighters/peg_leg_peggy.tres"
const RICHARD := "res://resources/fighters/whiskey_richard.tres"
const GAS_N_GO := "res://resources/stages/gas_n_go.tres"
const BUS_STOP := "res://resources/stages/bus_stop_night.tres"

var failures := 0
var checks := 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _initialize() -> void:
	await _legacy_pins()
	# Sections below are enabled as Phase 1 lands:
	# await _scaling_data()
	# await _outcome_cancels()
	# await _clip_cancel()
	# await _macros()
	# await _caps_and_meter()
	# await _combo_state_save_restore()
	# await _determinism()
	# await _route_fuzz()
	print("combo_test: %d checks, %d failure(s)" % [checks, failures])
	quit(1 if failures > 0 else 0)

# ---------------- harness (same contract as cpu_test.gd) --------------------

func _build_match(p1_path: String, p2_path: String, stage_path: String) -> Node:
	var mroot: Node = load("res://scenes/match/MatchRoot.tscn").instantiate()
	mroot.selected_p1_data = load(p1_path)
	mroot.selected_p2_data = load(p2_path)
	mroot.selected_stage = load(stage_path)
	mroot.set_physics_process(false)
	root.add_child(mroot)
	await process_frame
	await process_frame
	mroot.p1.set_physics_process(false)
	mroot.p2.set_physics_process(false)
	mroot.p1.reset_state()
	mroot.p2.reset_state()
	return mroot

func _free_match(mroot: Node) -> void:
	Input.action_release("p1_light")
	Input.action_release("p1_heavy")
	Input.action_release("p1_special")
	Input.action_release("p1_grab")
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	mroot.queue_free()
	await process_frame
	await process_frame

func _step(mroot: Node, frames: int) -> void:
	var dt := 1.0 / 60.0
	for _i in frames:
		Engine.physics_ticks_per_second = 60000
		await physics_frame
		Engine.physics_ticks_per_second = 60
		mroot.p1._physics_process(dt)
		mroot.p2._physics_process(dt)
		mroot._physics_process(dt)

func _to_fight(mroot: Node) -> void:
	await _step(mroot, 61)

func _reset_pair(mroot: Node, p1_x: float, p2_x: float) -> void:
	var stage: Node = mroot.stage
	mroot.p1.position = Vector2(p1_x, stage.floor_y)
	mroot.p2.position = Vector2(p2_x, stage.floor_y)
	mroot.p1.velocity = Vector2.ZERO
	mroot.p2.velocity = Vector2.ZERO
	mroot.p1.facing = 1
	mroot.p2.facing = -1
	mroot.p1.health = 1000.0
	mroot.p2.health = 1000.0
	mroot.p1.meter = 0.0
	mroot.p2.meter = 0.0
	mroot.p1.reset_state()
	mroot.p2.reset_state()
	mroot.p1.input_enabled = true
	mroot.p2.input_enabled = true

# Scripted attack: press `action` on every frame for `frames` frames.
func _script_press(mroot: Node, action: String, frames: int) -> void:
	for _i in frames:
		Input.action_press(action)
		await _step(mroot, 1)
		Input.action_release(action)

# Scripted attack: one clean press, then wait for the hit to confirm.
# Returns false if the move ends without confirming (whiff/block/timeout).
func _press_and_confirm(mroot: Node, action: String, timeout: int = 40) -> bool:
	Input.action_press(action)
	await _step(mroot, 1)
	Input.action_release(action)
	for i in timeout:
		await _step(mroot, 1)
		if mroot.p1.move_hit_confirmed:
			return true
		if mroot.p1.state != FighterBase.State.ATTACK:
			return false
	return false

# Wait for both fighters to be back in a neutral state (no stun/attack).
func _wait_neutral(mroot: Node, max_frames: int = 90) -> void:
	for _i in max_frames:
		await _step(mroot, 1)
		if mroot.p1.state in [FighterBase.State.IDLE, FighterBase.State.WALK_F,
				FighterBase.State.WALK_B, FighterBase.State.CROUCH] \
				and mroot.p2.state in [FighterBase.State.IDLE,
					FighterBase.State.WALK_F, FighterBase.State.WALK_B,
					FighterBase.State.CROUCH]:
			return

# ---------------- 1. legacy pins: today's routes, damage, juggles ----------

func _legacy_pins() -> void:
	var mroot: Node = await _build_match(PEGGY, RICHARD, GAS_N_GO)
	await _to_fight(mroot)

	# Peggy L, L, H string on hit: exact legacy ladder damage.
	_reset_pair(mroot, 100.0, 145.0)
	_check("Peggy string opener lands (light hit-confirm)",
		await _press_and_confirm(mroot, "p1_light"))
	_check("Peggy chain light lands (second hit-confirm)",
		await _press_and_confirm(mroot, "p1_light"))
	_check("Peggy chain heavy lands (third hit-confirm)",
		await _press_and_confirm(mroot, "p1_heavy"))
	await _wait_neutral(mroot)
	_check("Peggy L,L,H legacy ladder damage pinned (142.25)",
		is_equal_approx(mroot.p2.health, 1000.0 - 142.25),
		"health=%.3f" % mroot.p2.health)

	# Richard L, L, H string on hit (his own match, Richard as P1).
	var rich_mroot: Node = await _build_match(RICHARD, PEGGY, GAS_N_GO)
	await _to_fight(rich_mroot)
	_reset_pair(rich_mroot, 100.0, 145.0)
	_check("Richard string opener lands (light hit-confirm)",
		await _press_and_confirm(rich_mroot, "p1_light"))
	_check("Richard chain light lands (second hit-confirm)",
		await _press_and_confirm(rich_mroot, "p1_light"))
	_check("Richard chain heavy lands (third hit-confirm)",
		await _press_and_confirm(rich_mroot, "p1_heavy"))
	await _wait_neutral(rich_mroot)
	_check("Richard L,L,H legacy ladder damage pinned (175.0)",
		is_equal_approx(rich_mroot.p2.health, 1000.0 - 175.0),
		"health=%.3f" % rich_mroot.p2.health)
	await _free_match(rich_mroot)

	# Heavy cancels into the special on hit (existing CANCEL rule).
	_reset_pair(mroot, 100.0, 145.0)
	_check("heavy hit-confirm lands before the cancel pin",
		await _press_and_confirm(mroot, "p1_heavy"))
	await _script_press(mroot, "p1_special", 6)
	var saw_special: bool = false
	for i in 20:
		await _step(mroot, 1)
		if mroot.p1.current_move != null and mroot.p1.current_move.input \
				in [MoveData.InputType.SPECIAL_NEUTRAL, MoveData.InputType.SPECIAL_FWD,
					MoveData.InputType.SPECIAL_DOWN, MoveData.InputType.SPECIAL_BACK]:
			saw_special = true
			break
		if mroot.p1.state != FighterBase.State.ATTACK \
				and mroot.p1.current_move == null:
			break
	_check("heavy hit-confirm cancels into the authored special",
		saw_special, "current move=%s" % str(mroot.p1.current_move))

	# Juggle pin: the forward special launches, and air hits beyond the flat
	# cap reject (each juggle attempt re-launches via the authored knockback).
	await _wait_neutral(mroot)
	_reset_pair(mroot, 100.0, 145.0)
	Input.action_press("p1_right") # forward-held special = peggy_forward
	await _step(mroot, 2)
	Input.action_press("p1_special")
	await _step(mroot, 1)
	Input.action_release("p1_special")
	for i in 40:
		await _step(mroot, 1)
		if mroot.p1.move_hit_confirmed or mroot.p1.state != FighterBase.State.ATTACK:
			break
	Input.action_release("p1_right")
	_check("peggy_forward launches the defender (authored knockback.y)",
		not mroot.p2.grounded and mroot.p2.velocity.y < 0.0,
		"grounded=%s vy=%.1f" % [str(mroot.p2.grounded), mroot.p2.velocity.y])
	var launcher: MoveData = mroot.p1.data.find_move(
		MoveData.InputType.SPECIAL_FWD, MoveData.Stance.STAND)
	var juggle_hits: int = 0
	var rejected: int = 0
	for i in 8:
		await _step(mroot, 6)
		if mroot.p2.grounded:
			break
		if mroot.p2.receive_hit(mroot.p1, launcher):
			juggle_hits += 1
		else:
			rejected += 1
	_check("juggle flat cap pins: at most 3 air hits land, further ones reject",
		juggle_hits == 3 and rejected >= 1,
		"landed=%d rejected=%d" % [juggle_hits, rejected])

	# Blocked hit: the attacker gains no meter, the defender none either.
	await _wait_neutral(mroot)
	_reset_pair(mroot, 100.0, 145.0)
	Input.action_press("p2_right") # defender holds away from the attacker
	await _step(mroot, 2)
	Input.action_press("p1_light")
	await _step(mroot, 1)
	Input.action_release("p1_light")
	for i in 40:
		await _step(mroot, 1)
		if mroot.p2.state == FighterBase.State.BLOCKSTUN:
			break
	Input.action_release("p2_right")
	await _wait_neutral(mroot)
	_check("a blocked hit resolves as a block and pays no meter to either side",
		mroot.p1.meter == 0.0 and mroot.p2.meter == 0.0,
		"p1 meter=%.1f p2 meter=%.1f" % [mroot.p1.meter, mroot.p2.meter])

	await _free_match(mroot)
