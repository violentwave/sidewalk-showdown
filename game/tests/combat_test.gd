# Headless Phase 1 combat test. Run:
#   godot --headless --path game --script res://tests/combat_test.gd
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


func _reset_fighters(p1_x: float, p2_x: float) -> void:
	p1.position = Vector2(p1_x, 150)
	p2.position = Vector2(p2_x, 150)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1
	p1.health = 1000.0
	p2.health = 1000.0
	p1.combo_hits = 0
	p2.combo_hits = 0
	p1.reset_state()
	p2.reset_state()


func _run() -> void:
	await _step(65) # let round intro finish
	p1 = scene.p1
	p2 = scene.p2
	_check("fighters spawned", p1 != null and p2 != null)
	_check("match reaches FIGHT phase", scene.phase == 1, "phase=%d" % scene.phase)

	# --- 1. clean hit ---
	_reset_fighters(100, 120)
	await _step(2)
	var light: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.STAND)
	p1._start_move(light)
	await _step(light.total_frames() + 4)
	_check("light hit deals damage", p2.health < 1000.0, "hp=%.1f" % p2.health)
	_check("light damage matches data", is_equal_approx(p2.health, 1000.0 - light.damage), "hp=%.1f" % p2.health)
	_check("attacker gains meter", p1.meter > 0.0, "meter=%.1f" % p1.meter)

	# --- 2. block chip damage ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right") # p2 faces left, right = away
	await _step(3)
	p1._start_move(light)
	await _step(light.total_frames() + 4)
	_check("blocked hit only chips", is_equal_approx(p2.health, 1000.0 - light.block_damage), "hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 3. low hits standing blocker ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right") # standing block
	await _step(3)
	var low: MoveData = p1.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.CROUCH)
	p1._start_move(low)
	await _step(low.total_frames() + 4)
	_check("low attack beats stand block", is_equal_approx(p2.health, 1000.0 - low.damage), "hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 4. throw is unblockable ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right")
	await _step(3)
	var grab: MoveData = p1.data.find_move(MoveData.InputType.GRAB, MoveData.Stance.STAND)
	p1._start_move(grab)
	await _step(grab.total_frames() + 4)
	_check("throw ignores block", is_equal_approx(p2.health, 1000.0 - grab.damage), "hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 5. jump input works ---
	_reset_fighters(100, 200)
	Input.action_press("p1_up")
	await _step(1)
	Input.action_release("p1_up")
	await _step(6)
	_check("jump leaves the ground", p1.position.y < 150.0, "y=%.1f" % p1.position.y)
	await _step(40)

	# --- 6. P2 input map ---
	_reset_fighters(100, 200)
	Input.action_press("p2_left")
	await _step(6)
	Input.action_release("p2_left")
	_check("P2 moves with own keys", p2.position.x < 200.0, "x=%.1f" % p2.position.x)
	await _step(2)
	Input.action_press("p2_light")
	await _step(2)
	Input.action_release("p2_light")
	_check("P2 attacks with own keys", p2.state == FighterBase.State.ATTACK, "state=%d" % p2.state)
	await _step(30)

	# --- 7. blockstun still blocks ---
	_reset_fighters(100, 120)
	Input.action_press("p2_right") # p2 faces left, right = away
	await _step(3)
	p2.receive_hit(p1, light)
	p2.hitstop_frames = 0
	p2.receive_hit(p1, light)
	_check("blockstun keeps blocking", is_equal_approx(p2.health, 1000.0 - light.block_damage * 2.0),
		"hp=%.1f" % p2.health)
	Input.action_release("p2_right")

	# --- 8. attacker shares hitstop ---
	_reset_fighters(100, 120)
	p1._start_move(light)
	var hit_frames := 0
	while p2.health >= 1000.0 and hit_frames < 30:
		await _step(1)
		hit_frames += 1
	_check("attacker freezes on hit", p1.hitstop_frames > 0 and p2.hitstop_frames > 0,
		"p1=%d p2=%d" % [p1.hitstop_frames, p2.hitstop_frames])
	await _step(20)

	# --- 9. jump arc advances through rise and fall ---
	_reset_fighters(100, 200)
	Input.action_press("p1_up")
	await _step(1)
	Input.action_release("p1_up")
	var saw_rise := false
	var saw_fall := false
	for i in 60:
		await _step(1)
		if p1.state == FighterBase.State.JUMP_RISE:
			saw_rise = true
		if p1.state == FighterBase.State.JUMP_FALL:
			saw_fall = true
			break
	_check("jump transitions rise -> fall", saw_rise and saw_fall,
		"rise=%s fall=%s state=%d" % [saw_rise, saw_fall, p1.state])
	await _step(40)

	# --- 10. KO loser lands and stays KO (last: ends the round) ---
	_reset_fighters(100, 120)
	p2.health = 1.0
	p1._start_move(light)
	await _step(60)
	_check("KO loser lands on stage", is_equal_approx(p2.position.y, 150.0) and p2.grounded,
		"y=%.1f grounded=%s" % [p2.position.y, p2.grounded])
	_check("KO state persists after landing", p2.state == FighterBase.State.KO,
		"state=%d" % p2.state)

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
