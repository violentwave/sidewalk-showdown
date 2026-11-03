# Headless Phase 1 round-flow test. Run:
#   godot --headless --path game --script res://tests/round_flow_test.gd
extends SceneTree

var scene: Node2D
var p1: FighterBase
var p2: FighterBase
var failures := 0


func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _step(frames: int = 1) -> void:
	for i in frames:
		await physics_frame


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)


func _place_for_ko() -> void:
	p1.position = Vector2(120, 150)
	p2.position = Vector2(146, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p2.health = 1.0
	p2.reset_state()
	p1.reset_state()


func _run() -> void:
	await _step(65)
	p1 = scene.p1
	p2 = scene.p2
	_check("intro -> fight", scene.phase == 1 and scene.round_number == 1, "phase=%d" % scene.phase)

	# --- Round 1: KO ---
	_place_for_ko()
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	await _step(20)
	_check("KO phase entered", scene.phase == 2, "phase=%d" % scene.phase)
	await _step(105)
	_check("p1 awarded round win", scene.wins[0] == 1, str(scene.wins))
	_check("round end phase", scene.phase == 3, "phase=%d" % scene.phase)

	# --- Round 2: timeout ---
	await _step(95)
	_check("round 2 starts", scene.round_number == 2 and scene.phase == 0, "round=%d phase=%d" % [scene.round_number, scene.phase])
	await _step(65)
	_check("round 2 fighting", scene.phase == 1, "phase=%d" % scene.phase)
	p1.health = 500.0
	p2.health = 800.0
	scene.timer_frames = 3
	await _step(5)
	_check("timeout awards higher health", scene.wins[1] == 1, str(scene.wins))

	# --- Round 3: match point ---
	await _step(95)
	await _step(65)
	_place_for_ko()
	p1._start_move(light)
	await _step(20)
	await _step(105)
	_check("match ends at two wins", scene.phase == 4 and scene.wins[0] == 2, "phase=%d wins=%s" % [scene.phase, str(scene.wins)])

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
