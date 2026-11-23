# Dev tool: capture the two METHtality cinematics at their key beats for the
# README (docs/FX_AND_METH_DESIGN.md §3). Poses a real MatchRoot on the engine
# clock, starts the confirmed finisher, and grabs the native 320x180 viewport
# at the storyboard's beats: the plank stomp (Walk the Plank, frame 95) and
# the belch ignition (Flaming Belch, frame 100).
#
# Captures go to /tmp/opencode/meth/ so nothing lands in the repo until the
# image is reviewed and copied deliberately.
#
# Usage:
#   DISPLAY=:0 godot --path game --resolution 1280x720 \
#       --script res://tools/meth_capture.gd -- <plank|belch>
extends SceneTree

const OUT := "/tmp/opencode/meth"
const ROSTER := preload("res://resources/match_roster.tres")
# Key beats per sequence (see meth_cinematic_driver.gd): the stomp mid-snap
# for Walk the Plank, the belch cone fully bloomed for Flaming Belch.
const BEAT_FRAME := {"plank": 95, "belch": 100}

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

func _prime(attacker, defender, attacker_is_p1: bool, frame_target: int) -> void:
	var floor_y: float = _scene.stage.floor_y
	if attacker_is_p1:
		attacker.position = Vector2(120.0, floor_y)
		defender.position = Vector2(150.0, floor_y)
		attacker.facing = 1
		defender.facing = -1
	else:
		attacker.position = Vector2(150.0, floor_y)
		defender.position = Vector2(120.0, floor_y)
		attacker.facing = -1
		defender.facing = 1
	attacker.reset_state()
	defender.reset_state()
	attacker.add_meter(attacker.max_meter)
	attacker.input_buffer["meth"] = 0
	# Run on the engine clock to the exact beat frame.
	while _scene.phase != _scene.Phase.METH_CINEMATIC:
		await physics_frame
	while _scene.meth_driver.frame < frame_target:
		await physics_frame

func _run() -> void:
	await process_frame
	# Skip the round intro: jump straight to FIGHT.
	while _scene.phase == _scene.Phase.INTRO:
		_scene.phase_frame = _scene.INTRO_FRAMES
		await physics_frame
	var frame_target: int = BEAT_FRAME.get(_mode, 95)
	if _mode == "belch":
		await _prime(_scene.p2, _scene.p1, false, frame_target)
	else:
		await _prime(_scene.p1, _scene.p2, true, frame_target)
	await _grab("meth_%s" % _mode)
	_scene.queue_free()
	quit(0)
