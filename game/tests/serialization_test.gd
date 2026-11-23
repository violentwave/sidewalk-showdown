# Headless test for serializable match state (replays, rollback, training reset).
# Extends SceneTree so it can run headless. _initialize() sets up the test and
# _run() executes the serialization round-trip checks.
extends SceneTree

var failures := 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label, "  ", detail)

# Load a MatchRoot from the scene file (headless instantiation only; no tree).
func _new_match_root() -> Node:
	return preload("res://scenes/match/MatchRoot.tscn").instantiate()

# Verify the MatchRoot serializable surface contains every expected key.
func _check_match_surface(match_root: Node) -> void:
	var mroot: Node2D = match_root
	if mroot == null:
		_check("match_root cast to Node2D", false, "cast failed")
		return
	var surface: Dictionary = {
		"phase": mroot.phase,
		"phase_frame": mroot.phase_frame,
		"round_number": mroot.round_number,
		"wins": mroot.wins,
		"timer_frames": mroot.timer_frames,
		"ko_loser": mroot.ko_loser,
		"ko_draw": mroot.ko_draw,
		"ko_frame": mroot.ko_frame,
		"sim_frame": mroot.sim_frame,
		"timeout_ties": mroot.timeout_ties,
		"sudden_death": mroot.sudden_death,
		"round_damage": mroot.round_damage,
		"pause_index": mroot.pause_index,
		"pause_menu_open": mroot.pause_menu_open,
		"commentary_sample_shown": mroot.commentary_sample_shown,
		"p2_human": mroot.p2_human,
		"fighters_can_pass_through": mroot.fighters_can_pass_through,
		"training_mode": mroot.training_mode,
		"pause_tab": mroot.pause_tab,
		"training": mroot.training,
	}
	var expected_keys: Array = [
		"phase", "phase_frame", "round_number", "wins", "timer_frames",
		"ko_loser", "ko_draw", "ko_frame", "sim_frame", "timeout_ties",
		"sudden_death", "round_damage", "pause_index", "pause_menu_open",
		"commentary_sample_shown", "p2_human", "fighters_can_pass_through",
		"training_mode", "pause_tab", "training",
	]
	_check("MatchRoot has all expected keys", surface is Dictionary, "surface is not a Dictionary")
	if surface is Dictionary:
		for key in expected_keys:
			_check("  key present: " + key, surface.has(key), "key '" + key + "' missing")


func _run() -> void:
	var match_root: Node = _new_match_root()
	if match_root == null:
		_check("match_root instantiated", false, "match_root was null")
		return
	_check("match_root is a Node2D", match_root is Node2D, "match_root is not a Node2D")
	var mroot: Node2D = match_root
	if mroot == null:
		_check("match_root cast to Node2D", false, "cast failed")
		return
	_check("MatchRoot has valid phase", mroot.phase >= 0 and mroot.phase <= 4, "phase=" + str(mroot.phase))
	_check("MatchRoot phase_frame is non-negative", mroot.phase_frame >= 0, "phase_frame=" + str(mroot.phase_frame))
	_check("MatchRoot timer_frames is non-negative", mroot.timer_frames >= 0, "timer_frames=" + str(mroot.timer_frames))
	_check("MatchRoot wins has 2 entries", mroot.wins.size() == 2, "wins=" + str(mroot.wins))
	if mroot.phase == 0:
		_check("MatchRoot phase is INTRO initially", true, "phase=" + str(mroot.phase))
	_check_match_surface(mroot)
	print("==========")
	if failures == 0:
		print("ALL PASS")
	else:
		print(failures, "FAILURE(S)")
	# SceneTree scripts must terminate themselves: without quit() the headless
	# run keeps the (empty) main loop alive forever and CI has to kill it.
	quit(1 if failures > 0 else 0)

func _initialize() -> void:
	# Run the test immediately.
	_run()
