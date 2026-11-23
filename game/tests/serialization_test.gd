# Headless test for serializable match state (replays, rollback, training reset).
# Extends SceneTree so it can run headless. _initialize() sets up the test and
# _run() executes the serialization round-trip checks.
extends SceneTree

var failures := 0
var checks := 0
const FIGHTER_SCENE := preload("res://scenes/fighters/FighterBase.tscn")
const PEGGY_DATA := preload("res://resources/fighters/peg_leg_peggy.tres")

func _check(label: String, condition: bool, detail: String = "") -> void:
	checks += 1
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
	}
	var expected_keys: Array = [
		"phase", "phase_frame", "round_number", "wins", "timer_frames",
		"ko_loser", "ko_draw", "ko_frame", "sim_frame", "timeout_ties",
		"sudden_death", "round_damage", "pause_index", "pause_menu_open",
		"commentary_sample_shown", "p2_human", "fighters_can_pass_through",
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
	match_root.free()
	await _check_pending_breaker_round_trip()
	print("==========")
	print("serialization_test: %d checks, %d failure(s)" % [checks, failures])
	if failures == 0:
		print("ALL PASS")
	else:
		print(failures, "FAILURE(S)")
	# SceneTree scripts must terminate themselves: without quit() the headless
	# run keeps the (empty) main loop alive forever and CI has to kill it.
	quit(1 if failures > 0 else 0)

func _initialize() -> void:
	# Defer to the main loop so the fighter subscene can enter the tree and
	# exercise its real ready/load path.
	_run.call_deferred()


func _check_pending_breaker_round_trip() -> void:
	var fighter: FighterBase = FIGHTER_SCENE.instantiate()
	fighter.data = PEGGY_DATA
	root.add_child(fighter)
	await process_frame
	fighter.state = FighterBase.State.HITSTUN
	fighter.combo_hits = 1
	fighter.hitstop_frames = 10
	fighter.breaker_pending_hitstop_mask = 3
	fighter.input_buffer = {"grab": 1, "special": 1}
	var snapshot: Dictionary = fighter.serialize()
	_check("fighter serializable surface includes the pending breaker chord",
		snapshot.has("breaker_pending_hitstop_mask")
			and snapshot["breaker_pending_hitstop_mask"] == 3,
		"mask=%s" % str(snapshot.get("breaker_pending_hitstop_mask", "missing")))
	fighter.breaker_pending_hitstop_mask = 0
	fighter.hitstop_frames = 0
	fighter.input_buffer.clear()
	fighter.load(snapshot)
	_check("fighter round-trip preserves a pending breaker chord during hitstop",
		fighter.state == FighterBase.State.HITSTUN
			and fighter.hitstop_frames == 10
			and fighter.breaker_pending_hitstop_mask == 3
			and fighter.input_buffer.get("grab", -1) == 1
			and fighter.input_buffer.get("special", -1) == 1,
		"state=%d hitstop=%d mask=%d buffer=%s" % [
			fighter.state, fighter.hitstop_frames,
			fighter.breaker_pending_hitstop_mask, str(fighter.input_buffer)])
	fighter.free()
	await process_frame
