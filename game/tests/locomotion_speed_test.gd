# Headless locomotion test: Richard's and Peggy's walk speeds must match.
# Run: godot --headless --path game --script res://tests/locomotion_speed_test.gd
extends SceneTree

var failures := 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

func _initialize() -> void:
	# Load the two .tres resources directly (no FighterBase dependency needed
	# beyond the class_name type used to type the loaded resources).
	var peg := ResourceLoader.load("res://resources/fighters/peg_leg_peggy.tres") as FighterData
	var rich := ResourceLoader.load("res://resources/fighters/whiskey_richard.tres") as FighterData

	# Equality of locomotive data (already confirmed against the .tres diff).
	_check("Richard walk_speed_fwd == Peggy (95.0)", rich.walk_speed_fwd == peg.walk_speed_fwd)
	_check("Richard walk_speed_fwd == 95.0", rich.walk_speed_fwd == 95.0)

	_check("Richard walk_speed_back == Peggy (72.0)", rich.walk_speed_back == peg.walk_speed_back)
	_check("Richard walk_speed_back == 72.0", rich.walk_speed_back == 72.0)

	_check("Richard jump_speed == Peggy (285.0)", rich.jump_speed == peg.jump_speed)
	_check("Richard jump_speed == 285.0", rich.jump_speed == 285.0)

	# Fixed-length walk from the same start covers the same distance over the
	# same number of frames for both fighters (distance = speed * frames).
	var frames := 120
	var d_peg := peg.walk_speed_fwd * frames
	var d_rich := rich.walk_speed_fwd * frames
	_check("fixed walk (120f) covers equal distance", d_peg == d_rich)

	print("locomotion_speed_test: ", failures, " failure(s)")
	if failures == 0:
		quit(0)
	else:
		quit(1)
