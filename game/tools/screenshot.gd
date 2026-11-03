# Dev tool: boots the main scene, waits N frames, saves a screenshot, quits.
# Usage: godot --path game --script res://tools/screenshot.gd -- <out.png> [frames]
extends SceneTree

var _frames := 0
var _target_frames := 30
var _out := "/tmp/opencode/shot.png"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_target_frames = int(args[1])
	root.add_child(load("res://scenes/match/MatchRoot.tscn").instantiate())

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= _target_frames:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("saved ", _out, " ", img.get_width(), "x", img.get_height())
		return true
	return false
