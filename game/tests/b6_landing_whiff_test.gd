# Headless B6 landing-whiff test (rule superseded 2026-11-18).
# B6 once verified that touchdown mid-air (interrupting a whiffed air move)
# awarded the authored whiff meter via finish_move_whiff(). The meter economy
# changed to "landed hits only": whiffs earn nothing anywhere, so this suite
# now pins the superseding behavior — landing a whiffed air move awards 0
# meter, the move still clears, and recovery still runs to IDLE.
#   godot --headless --path game --script res://tests/b6_landing_whiff_test.gd
extends SceneTree

var scene: Node2D
var failures := 0

func _initialize() -> void:
	scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	root.add_child(scene)
	_run.call_deferred()

func _step(frames: int = 1) -> void:
	for _i in range(frames):
		await physics_frame

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _run() -> void:
	await _step(90) # INTRO_FRAMES (60) then into FIGHT; gives the round a moment to start

	var fighter: FighterBase = scene.p1
	var stage: Node2D = fighter.stage
	var floor_y: float = stage.floor_y
	var air_move: MoveData = fighter.data.find_move(MoveData.InputType.LIGHT, MoveData.Stance.AIR)

	_check("B6 setup: an air-stance light move exists", air_move != null and air_move.stance == MoveData.Stance.AIR,
		"air_move=" + str(air_move.id) if air_move != null else "no air move")

	if air_move == null:
		print("B6 skipped: no air move available")
		for _i in range(16):
			await process_frame
		print("\n%d failure(s)" % failures)
		quit(1 if failures > 0 else 0)
		return

	# Drop the fighter slightly below the floor in JUMP_FALL, holding an air move.
	# _landing_check only runs when position.y >= floor_y, so the early position
	# below the floor surface is what triggers the landing branch.
	fighter.grounded = false
	fighter.velocity = Vector2.ZERO
	fighter.position.y = floor_y + 10.0
	fighter.health = fighter.max_health
	fighter.meter = 0.0
	fighter.reset_state()
	fighter.grounded = false
	fighter._force_state(FighterBase.State.JUMP_FALL)

	fighter.current_move = air_move
	fighter.move_already_hit = false
	fighter.move_hit_confirmed = false
	print("B6: air_move=", air_move.id, " meter_gain_whiff=", air_move.meter_gain_whiff, " floor_y=", floor_y, " state=", int(fighter.state), " grounded=", fighter.grounded, " current_move=", fighter.current_move.id if fighter.current_move != null else "null", " move_already_hit=", "true" if fighter.move_already_hit else "false")

	var landed := false
	for _i in range(30):
		await _step(1)
		if fighter.grounded:
			landed = true
			break

	_check("B6: fighter lands mid-move", landed)

	_check("B6 superseded: landing a whiffed air move awards 0 meter",
		fighter.meter <= 0.01,
		"meter=" + str(fighter.meter) + " expected=0 (meter_gain_whiff=" + str(air_move.meter_gain_whiff) + " is no longer awarded)")

	_check("B6: move cleared on landing", fighter.current_move == null,
		"current_move=" + str(fighter.current_move.id) if fighter.current_move != null else "null")

	await _step(12) # let LAND recover to IDLE (landing_recovery_frames=8 for jump_light)
	_check("B6: fighter returns to IDLE after recovery", fighter.state == FighterBase.State.IDLE,
		"state=" + str(int(fighter.state)) + " state_frame=" + str(fighter.state_frame) + " landing_recovery_frames=" + str(fighter.landing_recovery_frames))

	for _i in range(16):
		await process_frame

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
