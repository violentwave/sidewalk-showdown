# Dev tool: capture the two METHtality cinematics for README and review.
# Captures go to /tmp/opencode/meth/ so nothing lands in the repo until the
# image is reviewed and copied deliberately.
#
# Usage (needs DISPLAY=:0; the window renders at 1920x1080 = exact 6x of the
# native 320x180 canvas, so point-downsampling back is lossless):
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/meth_capture.gd -- <mode>
#
# Modes:
#   plank / belch      — single native 320x180 key-beat still
#                        (plank stomp f95, belch ignition f100), attacker
#                        on the LEFT for plank / RIGHT for belch (the README
#                        pair shows both facings).
#   *_strip            — 12 raw frames (f0..f198 step 18) of the sequence,
#                        attacker on the LEFT, for the review strips.
#   *_strip_mirrored   — same, attacker on the RIGHT near the right wall.
#
# The raw strip frames are assembled into the labeled 4x3 review sheets by
# the caller (see art/tools/meth_strip.sh).
extends SceneTree

const OUT := "/tmp/opencode/meth"
const ROSTER := preload("res://resources/match_roster.tres")
# Key beats per sequence (see meth_cinematic_driver.gd): the stomp mid-snap
# for Walk the Plank, the belch cone fully bloomed for Flaming Belch.
const BEAT_FRAME := {"plank": 95, "belch": 100}
const STRIP_STEP := 18
const STRIP_FRAMES := 12

var _mode := "plank"
var _scene: Node

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_mode = str(args[0])
	_scene = load("res://scenes/match/MatchRoot.tscn").instantiate()
	_scene.selected_stage = ROSTER.stages[0]
	root.add_child(_scene)
	_run.call_deferred()

func _grab(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, tag])
	print("saved ", tag)

# Attacker LEFT (x 120, victim at 150) or RIGHT near the right wall
# (attacker 250, victim 224 so the whole group exercises the wall clamp).
func _prime_pair(attacker, defender, attacker_left: bool) -> void:
	var floor_y: float = _scene.stage.floor_y
	if attacker_left:
		attacker.position = Vector2(120.0, floor_y)
		defender.position = Vector2(150.0, floor_y)
		attacker.facing = 1
		defender.facing = -1
	else:
		attacker.position = Vector2(250.0, floor_y)
		defender.position = Vector2(224.0, floor_y)
		attacker.facing = -1
		defender.facing = 1
	attacker.reset_state()
	defender.reset_state()
	attacker.add_meter(attacker.max_meter)
	attacker.input_buffer["meth"] = 0

func _await_sequence() -> void:
	while _scene.phase != _scene.Phase.METH_CINEMATIC:
		await physics_frame

func _run() -> void:
	await process_frame
	# Skip the round intro: jump straight to FIGHT.
	while _scene.phase == _scene.Phase.INTRO:
		_scene.phase_frame = _scene.INTRO_FRAMES
		await physics_frame

	var strip := _mode.contains("strip")
	var mirrored := _mode.contains("mirrored")
	var base := "belch" if _mode.begins_with("belch") or \
		_mode.begins_with("flaming") else "plank"

	if strip:
		# Flaming Belch needs Richard as the attacker; Walk the Plank needs
		# Peggy. Keep the victim the other fighter in both cases.
		var attacker = _scene.p1
		var defender = _scene.p2
		if base == "belch" and attacker.data.id != "whiskey_richard":
			attacker = _scene.p2
			defender = _scene.p1
		elif base == "plank" and attacker.data.id != "peg_leg_peggy":
			attacker = _scene.p2
			defender = _scene.p1
		_prime_pair(attacker, defender, not mirrored)
		await _await_sequence()
		for i in STRIP_FRAMES:
			var target: int = i * STRIP_STEP
			while _scene.meth_driver.frame < target:
				await physics_frame
			await _grab("strip_%s_%02d" % [_mode, i])
		# Let the sequence finish before freeing the scene.
		while _scene.phase == _scene.Phase.METH_CINEMATIC:
			await physics_frame
	else:
		# Key-beat stills: plank with the attacker LEFT, belch with the
		# attacker RIGHT (mirrored), so the README pair shows both facings.
		var frame_target: int = BEAT_FRAME.get(base, 95)
		if base == "plank":
			_prime_pair(_scene.p1, _scene.p2, true)
		else:
			_prime_pair(_scene.p2, _scene.p1, false)
		await _await_sequence()
		while _scene.meth_driver.frame < frame_target:
			await physics_frame
		await _grab("meth_%s" % base)
	_scene.queue_free()
	quit(0)
