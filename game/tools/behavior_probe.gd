# Combined behavior probe — a headless, non-CI verification tool for the
# cross-feature invariants that individual suites don't span end to end:
# meter economy (landed hits only), pass-through spacing, cross-up blocking,
# walk-speed parity, and both stages' pinned floor lines.
# Not a test suite (it lives outside tests.yml); it prints PASS/FAIL and
# exits nonzero on failure so it can be run ad hoc:
#   godot --headless --path game --script res://tools/behavior_probe.gd
extends SceneTree

var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var stage
var floor_y: float = 0.0
var checks := 0
var failures := 0


func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	scene.selected_stage = load("res://resources/stages/bus_stop_night.tres")
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	await _step(5)
	p1 = scene.p1
	p2 = scene.p2
	stage = scene.selected_stage
	await _step(60) # let the round flow reach FIGHT so the stage exists
	floor_y = scene.stage.floor_y

	# -- Blocked contact pays nobody ---------------------------------------
	scene._start_fight()
	_reset_fighters(110.0, 150.0)
	await _step(3)  # let the held-away block state settle, as combat_test does
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	Input.action_press("p1_left")  # p2 stands to p1's right: away = p1_left
	await _step(3)  # let the held-away block state settle, as combat_test does
	p1.receive_hit(p2, light)  # blocked: p1 holds away from p2
	await _step(3)
	Input.action_release("p1_left")
	_check(p2.meter == 0.0,
		"blocked contact pays the defender nothing (meter %s)" % p2.meter)
	_check(p1.state == FighterBase.State.BLOCKSTUN or p1.health > 990.0,
		"blocked contact resolved as a block with chip (hp %s, state %s)"
		% [p1.health, p1.state])

	# -- Meter builds on landed hits only ---------------------------------
	_reset_fighters(100.0, 122.0)
	p1.meter = 0.0
	p2.meter = 0.0
	p1.receive_hit(p2, light)
	_check(absf(p2.meter - light.meter_gain_hit) < 0.01,
		"landed hit awards meter_gain_hit=%.1f (attacker meter %.1f)"
		% [light.meter_gain_hit, p2.meter])
	_check(p1.meter == 0.0, "the defender gains nothing when hit (meter %s)" % p1.meter)
	_reset_fighters(100.0, 320.0) # way out of range: the move whiffs
	p1.meter = 0.0
	p1._start_move(light)
	for i in light.startup + light.active + light.recovery + 3:
		await _step(1)
	_check(p1.meter == 0.0, "a whiffed move earns 0 meter (meter %s)" % p1.meter)
	_check(p1.state == FighterBase.State.IDLE, "the whiff resolves to idle (state %s)"
		% FighterBase.State.keys()[p1.state])

	# -- Fighters can overlap and pass through ----------------------------
	_reset_fighters(158.0, 162.0)  # overlapping, inside the walkable band
	await _step(30)
	_check(p1.state != FighterBase.State.HITSTUN and p1.health == 1000.0,
		"overlapping fighters idle without contact damage (state %s)" % p1.state)
	Input.action_press("p1_right")
	await _step(60)
	Input.action_release("p1_right")
	_check(p1.position.x > 175.0,
		"p1 walks out through the overlap (x %.1f)" % p1.position.x)
	_check(signf(p1.position.x - p2.position.x) > 0.0 and p1.facing == -1,
		"crossed to the far side and auto-turned (p1 %.1f p2 %.1f facing %d)"
		% [p1.position.x, p2.position.x, p1.facing])

	# -- Overlapped facing is stable (hysteresis, 120 frames) -------------
	_reset_fighters(158.0, 162.0) # 4 px apart: inside the default deadzone
	var p1_face: int = p1.facing
	var p2_face: int = p2.facing
	var flickered := false
	for i in 120:
		await _step(1)
		if p1.facing != p1_face or p2.facing != p2_face:
			flickered = true
			break
	_check(not flickered,
		"120 overlapped frames flip neither facing (p1 %d p2 %d)" % [p1.facing, p2.facing])

	# -- Cross-up block rule: the attacker's position decides -------------
	# p2 stands on p1's LEFT facing right into p1; after the auto-turn p1
	# faces LEFT, so the legacy-facing back key (p1_right) is ALSO the key
	# pointing away from the attacker. The rule under test: away-from-
	# ATTACKER decides the block axis, not the defender's own facing.
	_reset_fighters(160.0, 138.0)
	p2.facing = 1
	await _step(10)  # p1 auto-turns: attacker at 138 is to its left
	Input.action_press("p1_right")  # away from the attacker -> blocks
	await _step(2)
	p2._start_move(light)
	await _step(45)
	_check(p1.health > 990.0 and not p2.move_hit_confirmed,
		"cross-up blocked with the attacker-away key (hp %s, confirmed %s)"
		% [p1.health, p2.move_hit_confirmed])
	Input.action_release("p1_right")

	_reset_fighters(160.0, 138.0)
	p2.facing = 1
	await _step(10)  # p1 auto-turns to face its attacker on the left
	Input.action_press("p1_left")  # toward the attacker -> does not block
	await _step(2)
	p2._start_move(light)
	await _step(45)
	_check(p1.health < 990.0 and p2.move_hit_confirmed,
		"holding toward the attacker does not block (hp %s, confirmed %s)"
		% [p1.health, p2.move_hit_confirmed])
	Input.action_release("p1_left")

	# -- Walk-speed parity -------------------------------------------------
	# Both fighters walk FORWARD (toward the opponent): p1 starts on the
	# right facing left, p2 on the left facing right.
	_reset_fighters(220.0, 100.0)
	var x0: float = p1.position.x
	Input.action_press("p1_left")
	await _step(60)
	Input.action_release("p1_left")
	_check(p1.state == FighterBase.State.WALK_F, "p1 walks forward (state %s)"
		% FighterBase.State.keys()[p1.state])
	var p1_speed: float = (x0 - p1.position.x) / 60.0
	_reset_fighters(220.0, 100.0)
	p2.input_enabled = true
	var x1: float = p2.position.x
	Input.action_press("p2_right")
	await _step(60)
	Input.action_release("p2_right")
	_check(p2.state == FighterBase.State.WALK_F, "p2 walks forward (state %s)"
		% FighterBase.State.keys()[p2.state])
	var p2_speed: float = (p2.position.x - x1) / 60.0
	_check(absf(p1_speed - p2_speed) < 0.05,
		"forward walk speeds match (%.2f vs %.2f px/frame)" % [p1_speed, p2_speed])
	# Backward parity on the same footing: both walk away from the opponent.
	_reset_fighters(220.0, 100.0)
	p2.input_enabled = true
	var x2: float = p1.position.x
	Input.action_press("p1_right")
	await _step(60)
	Input.action_release("p1_right")
	var p1_back: float = (p1.position.x - x2) / 60.0
	_reset_fighters(220.0, 100.0)
	p2.input_enabled = true
	var x3: float = p2.position.x
	Input.action_press("p2_left")
	await _step(60)
	Input.action_release("p2_left")
	var p2_back: float = (x3 - p2.position.x) / 60.0
	_check(absf(p1_back - p2_back) < 0.05,
		"backward walk speeds match (%.2f vs %.2f px/frame)" % [p1_back, p2_back])
	_check(absf(p1_speed - 95.0 / 60.0) < 0.05 and absf(p1_back - 72.0 / 60.0) < 0.05,
		"measured speeds pin the authored values (fwd %.2f vs 1.58, back %.2f vs 1.20)"
		% [p1_speed, p1_back])

	# -- Stage floors pin to their measured art values ---------------------
	_check(is_equal_approx(floor_y, 170.0), "Bus Stop floor_y is 170 (got %s)" % floor_y)
	_check(absf(p1.position.y - floor_y) < 2.0,
		"fighters stand on the floor line (y %.1f vs %.1f)" % [p1.position.y, floor_y])
	var gas_scene: Node = (load("res://scenes/stages/gas_n_go.tscn") as PackedScene).instantiate()
	var gas_floor: float = gas_scene.floor_y
	gas_scene.free()
	_check(is_equal_approx(gas_floor, 158.0), "Gas-N-Go floor_y is 158 (got %s)" % gas_floor)

	print("BEHAVIOR_PROBE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _step(frames: int = 1) -> void:
	for i in frames:
		await physics_frame


func _reset_fighters(p1_x: float, p2_x: float) -> void:
	p1.position = Vector2(p1_x, floor_y)
	p2.position = Vector2(p2_x, floor_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.health = 1000.0
	p2.health = 1000.0
	p2.meter = 0.0
	p1.meter = 0.0
	p1.reset_state()
	p2.reset_state()
	p1.input_enabled = true
	p2.input_enabled = false


func _check(condition: bool, label: String, detail: String = "") -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)
